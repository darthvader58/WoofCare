"""Backfill Firestore privacy fields used by the WoofCare app.

Run from the server directory:

    python migrate_privacy_fields.py firebase-credentials.json
    python migrate_privacy_fields.py firebase-credentials.json --apply

The default mode is a dry run. Use --apply to write changes.
"""

from __future__ import annotations

import argparse
import math
import random
from datetime import datetime, timedelta, timezone
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore

FUZZ_RADIUS_METERS = 300
EXACT_LOCATION_COLLECTION = "report_locations"
EXACT_PUBLIC_LOCATION_FIELDS = (
    "latitude",
    "longitude",
    "exactLatitude",
    "exactLongitude",
    "exactLocation",
    "exactCoordinates",
    "geoPoint",
)


def init_firestore(credentials_path: str) -> firestore.Client:
    if not firebase_admin._apps:
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred)
    return firestore.client()


def queue_update(
    ref: firestore.DocumentReference,
    updates: dict[str, Any],
    apply_changes: bool,
) -> bool:
    if not updates:
        return False

    print(f"{'UPDATE' if apply_changes else 'DRY-RUN'} {ref.path}: {updates}")
    if apply_changes:
        ref.update(updates)
    return True


def queue_set(
    ref: firestore.DocumentReference,
    data: dict[str, Any],
    apply_changes: bool,
    *,
    merge: bool = True,
) -> bool:
    if not data:
        return False

    print(f"{'SET' if apply_changes else 'DRY-RUN SET'} {ref.path}: {data}")
    if apply_changes:
        ref.set(data, merge=merge)
    return True


def as_float(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return None


def fuzz_coordinate(value: float) -> float:
    return value


def build_fuzzed_location(latitude: float, longitude: float) -> dict[str, Any]:
    source = random.SystemRandom()
    angle = source.random() * 2 * math.pi
    distance = math.sqrt(source.random()) * FUZZ_RADIUS_METERS
    latitude_offset = (distance * math.cos(angle)) / 111_320
    longitude_meters = 111_320 * abs(math.cos(math.radians(latitude)))
    longitude_offset = 0 if longitude_meters == 0 else (
        distance * math.sin(angle)
    ) / longitude_meters
    fuzzed_latitude = latitude + latitude_offset
    fuzzed_longitude = longitude + longitude_offset

    return {
        "latitude": fuzz_coordinate(fuzzed_latitude),
        "longitude": fuzz_coordinate(fuzzed_longitude),
        "precisionMeters": FUZZ_RADIUS_METERS,
        "method": "random_radius_v1",
        "source": "server_migration",
    }


def fuzzed_location_matches(
    current: Any,
    expected: dict[str, Any],
) -> bool:
    if not isinstance(current, dict):
        return False

    return (
        as_float(current.get("latitude")) == expected["latitude"]
        and as_float(current.get("longitude")) == expected["longitude"]
        and current.get("precisionMeters") == expected["precisionMeters"]
        and current.get("method") == expected["method"]
    )


def backfill_users(
    db: firestore.Client,
    apply_changes: bool,
) -> int:
    changed = 0
    for doc in db.collection("users").stream():
        data = doc.to_dict() or {}
        updates: dict[str, Any] = {}

        if "shareProfile" not in data:
            updates["shareProfile"] = True

        if "verified" not in data:
            updates["verified"] = False

        changed += queue_update(doc.reference, updates, apply_changes)

    return changed


def backfill_reports(
    db: firestore.Client,
    apply_changes: bool,
) -> int:
    changed = 0
    for doc in db.collection("reports").stream():
        data = doc.to_dict() or {}
        updates: dict[str, Any] = {}
        is_anonymous = data.get("isAnonymous") is True

        if "isAnonymous" not in data:
            updates["isAnonymous"] = False
            is_anonymous = False

        if "shareReporterPhone" not in data:
            updates["shareReporterPhone"] = False

        if "reporterName" not in data and data.get("name"):
            updates["reporterName"] = data["name"]

        if "reporterEmail" not in data:
            updates["reporterEmail"] = data.get("email")

        if is_anonymous or updates.get("shareReporterPhone") is False:
            updates["reporterPhone"] = None
        elif "reporterPhone" not in data:
            updates["reporterPhone"] = data.get("phone")

        exact_ref = db.collection(EXACT_LOCATION_COLLECTION).document(doc.id)
        exact_doc = exact_ref.get()
        exact_data = exact_doc.to_dict() if exact_doc.exists else {}

        exact_latitude = as_float(exact_data.get("latitude"))
        exact_longitude = as_float(exact_data.get("longitude"))
        public_latitude = as_float(data.get("latitude"))
        public_longitude = as_float(data.get("longitude"))
        current_fuzzed_latitude = as_float(data.get("fuzzedLatitude"))
        current_fuzzed_longitude = as_float(data.get("fuzzedLongitude"))

        if exact_latitude is None or exact_longitude is None:
            exact_latitude = public_latitude
            exact_longitude = public_longitude

        if exact_latitude is not None and exact_longitude is not None:
            reporter_uid = data.get("userID")
            exact_payload = {
                "reportId": doc.id,
                "reporterId": str(reporter_uid) if reporter_uid else "",
                "latitude": exact_latitude,
                "longitude": exact_longitude,
                "source": "legacy_reports_latitude_longitude",
                "createdAt": data.get("timestamp") or firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }

            if not exact_doc.exists:
                changed += queue_set(exact_ref, exact_payload, apply_changes)
            else:
                exact_updates = {
                    key: value
                    for key, value in exact_payload.items()
                    if key in ("reportId", "reporterId")
                    and exact_data.get(key) != value
                }
                changed += queue_set(exact_ref, exact_updates, apply_changes)

            if current_fuzzed_latitude is not None and current_fuzzed_longitude is not None:
                fuzzed_location = {
                    "latitude": current_fuzzed_latitude,
                    "longitude": current_fuzzed_longitude,
                    "precisionMeters": data.get(
                        "locationPrivacyRadiusMeters", FUZZ_RADIUS_METERS
                    ),
                    "method": data.get("locationPrivacyMethod", "random_radius_v1"),
                    "source": data.get("locationPrivacySource", "existing"),
                }
            else:
                fuzzed_location = build_fuzzed_location(exact_latitude, exact_longitude)

            if not fuzzed_location_matches(data.get("fuzzedLocation"), fuzzed_location):
                updates["fuzzedLocation"] = fuzzed_location

            if data.get("locationPrivacyVersion") != 1:
                updates["locationPrivacyVersion"] = 1

            if data.get("locationPrivacy") != "fuzzed":
                updates["locationPrivacy"] = "fuzzed"

            if data.get("locationPrivacyRadiusMeters") != FUZZ_RADIUS_METERS:
                updates["locationPrivacyRadiusMeters"] = FUZZ_RADIUS_METERS

            if current_fuzzed_latitude is None:
                updates["fuzzedLatitude"] = fuzzed_location["latitude"]

            if current_fuzzed_longitude is None:
                updates["fuzzedLongitude"] = fuzzed_location["longitude"]

            if data.get("hasExactLocation") is not True:
                updates["hasExactLocation"] = True

        for field in EXACT_PUBLIC_LOCATION_FIELDS:
            if field in data:
                updates[field] = firestore.DELETE_FIELD

        changed += queue_update(doc.reference, updates, apply_changes)

    return changed


def backfill_conversations(
    db: firestore.Client,
    apply_changes: bool,
) -> int:
    changed = 0
    default_expiry = datetime.now(timezone.utc) + timedelta(hours=48)

    for doc in db.collection("conversations").stream():
        data = doc.to_dict() or {}
        updates: dict[str, Any] = {}

        if data.get("isReportChat") is not True:
            continue

        anonymous_reporter = data.get("anonymousReporter") is True
        if "anonymousReporter" not in data:
            anonymous_reporter = data.get("reporterDisplayName") == "Anonymous Reporter"
            updates["anonymousReporter"] = anonymous_reporter

        if "requesterProfileShared" not in data:
            updates["requesterProfileShared"] = True

        if anonymous_reporter and "expiresAt" not in data:
            updates["expiresAt"] = default_expiry

        changed += queue_update(doc.reference, updates, apply_changes)

    return changed


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Backfill WoofCare Firestore privacy fields."
    )
    parser.add_argument("credentials", help="Path to Firebase service account JSON")
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write changes. Omit this flag to preview changes only.",
    )
    args = parser.parse_args()

    db = init_firestore(args.credentials)

    changed = {
        "users": backfill_users(db, args.apply),
        "reports": backfill_reports(db, args.apply),
        "conversations": backfill_conversations(db, args.apply),
    }

    print(f"Summary: {changed}")
    if not args.apply:
        print("No changes were written. Re-run with --apply to update Firestore.")


if __name__ == "__main__":
    main()
