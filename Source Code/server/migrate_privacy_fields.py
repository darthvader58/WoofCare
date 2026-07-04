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


# Legacy individual roles -> new individual role vocabulary.
INDIVIDUAL_ROLE_REMAP = {
    "Animal Lover": "General Animal Lover",
    "NGO Representative": "NGO Worker",
    "Looking to Adopt": "Animal Lover Willing to Adopt",
    "Veterinarian": "Vet",
    "Dog Feeder": "Dog Feeder",
}

# Legacy organization types -> new organization type vocabulary. Legacy
# "Adoption Center"/"Feeding Group" orgs have no direct new-org equivalent
# (adoption/feeding are now individual concerns) and are left untouched with
# a warning so a human can decide how to reclassify them.
ORGANIZATION_TYPE_REMAP = {
    "Animal Shelter": "Rescue Shelter",
    "Rescue NGO": "NGO",
    "Veterinary Clinic": "Vet Clinic",
}


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

        # Taxonomy: legacy "member" (or missing) -> "individual".
        account_type = data.get("accountType")
        if account_type in (None, "member"):
            account_type = "individual"
            updates["accountType"] = "individual"

        is_organization = account_type == "organization"

        # Location visibility: individuals private, organizations public.
        expected_visibility = "public" if is_organization else "private"
        if data.get("locationVisibility") != expected_visibility:
            updates["locationVisibility"] = expected_visibility

        # Role vocabulary remap (best-effort, only clear 1:1 cases).
        role = data.get("role")
        if isinstance(role, str) and role:
            if is_organization:
                new_role = ORGANIZATION_TYPE_REMAP.get(role)
                if new_role and new_role != role:
                    updates["role"] = new_role
                    updates["organizationType"] = new_role
                elif new_role is None:
                    print(
                        f"WARNING {doc.reference.path}: org type {role!r} has no "
                        "new-vocabulary mapping; leaving as-is for manual review"
                    )
            else:
                new_role = INDIVIDUAL_ROLE_REMAP.get(role)
                if new_role and new_role != role:
                    updates["role"] = new_role
                elif new_role is None:
                    print(
                        f"WARNING {doc.reference.path}: individual role {role!r} has "
                        "no new-vocabulary mapping; leaving as-is for manual review"
                    )

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

        if is_anonymous:
            # Anonymous reports must not carry reporter identity in the
            # public doc, no matter what legacy fields exist.
            if data.get("reporterName") is not None:
                updates["reporterName"] = None
            if data.get("reporterEmail") is not None:
                updates["reporterEmail"] = None
            if data.get("reporterPhone") is not None:
                updates["reporterPhone"] = None
        else:
            if "reporterName" not in data and data.get("name"):
                updates["reporterName"] = data["name"]

            if "reporterEmail" not in data:
                updates["reporterEmail"] = data.get("email")

            if data.get("shareReporterPhone") is True:
                if "reporterPhone" not in data:
                    updates["reporterPhone"] = data.get("phone")
            elif data.get("reporterPhone") is not None or "reporterPhone" not in data:
                updates["reporterPhone"] = None

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


def build_user_name_index(db: firestore.Client) -> dict[str, str]:
    """Map display names to uids for legacy conversations that only stored names."""
    index: dict[str, str] = {}
    for doc in db.collection("users").stream():
        name = (doc.to_dict() or {}).get("name")
        if isinstance(name, str) and name and name not in index:
            index[name] = doc.id
    return index


def backfill_conversation_messages(
    doc_ref: firestore.DocumentReference,
    data: dict[str, Any],
    name_index: dict[str, str],
    apply_changes: bool,
) -> int:
    """Stamp senderId on legacy messages and mask hidden-identity sender names."""
    reporter_uid = data.get("reporterUserId")
    requester_uid = data.get("requesterUserId")
    reporter_name = data.get("reporterName")
    requester_name = data.get("requesterName")
    anonymous_reporter = data.get("anonymousReporter") is True
    requester_shared = data.get("requesterProfileShared") is not False

    changed = 0
    for message in doc_ref.collection("messages").stream():
        message_data = message.to_dict() or {}
        updates: dict[str, Any] = {}

        sender = message_data.get("sender")
        sender_id = message_data.get("senderId")
        if not sender_id and isinstance(sender, str):
            if reporter_name and sender == reporter_name:
                sender_id = reporter_uid
            elif requester_name and sender == requester_name:
                sender_id = requester_uid
            else:
                sender_id = name_index.get(sender)
            if sender_id:
                updates["senderId"] = sender_id

        if (
            anonymous_reporter
            and reporter_uid
            and sender_id == reporter_uid
            and sender != "Anonymous Reporter"
        ):
            updates["sender"] = "Anonymous Reporter"
        elif (
            not requester_shared
            and requester_uid
            and sender_id == requester_uid
            and sender != "Anonymous User"
        ):
            updates["sender"] = "Anonymous User"

        changed += queue_update(message.reference, updates, apply_changes)

    return changed


def backfill_conversations(
    db: firestore.Client,
    apply_changes: bool,
) -> int:
    changed = 0
    default_expiry = datetime.now(timezone.utc) + timedelta(hours=48)
    name_index = build_user_name_index(db)

    for doc in db.collection("conversations").stream():
        data = doc.to_dict() or {}
        updates: dict[str, Any] = {}

        # Participant uids are required by the rules for any read or write.
        participant_ids = data.get("participantIds")
        if not isinstance(participant_ids, list) or len(participant_ids) < 2:
            resolved: list[str] = []
            reporter_uid = data.get("reporterUserId")
            requester_uid = data.get("requesterUserId")
            if reporter_uid and requester_uid:
                resolved = [str(requester_uid), str(reporter_uid)]
            else:
                for name in data.get("participants") or []:
                    uid = name_index.get(name) if isinstance(name, str) else None
                    if uid and uid not in resolved:
                        resolved.append(uid)
            if len(resolved) >= 2:
                updates["participantIds"] = resolved
            else:
                print(
                    f"WARNING {doc.reference.path}: could not resolve participant "
                    "uids; conversation will be unreadable until fixed manually"
                )

        if data.get("isReportChat") is True:
            anonymous_reporter = data.get("anonymousReporter") is True
            if "anonymousReporter" not in data:
                anonymous_reporter = (
                    data.get("reporterDisplayName") == "Anonymous Reporter"
                )
                updates["anonymousReporter"] = anonymous_reporter

            if "requesterProfileShared" not in data:
                updates["requesterProfileShared"] = True

            if anonymous_reporter and "expiresAt" not in data:
                updates["expiresAt"] = default_expiry

            changed += backfill_conversation_messages(
                doc.reference,
                {**data, "anonymousReporter": anonymous_reporter},
                name_index,
                apply_changes,
            )

            # Strip real names for parties that chose privacy; display names
            # already carry the masked value.
            if anonymous_reporter and data.get("reporterName") is not None:
                updates["reporterName"] = None
            if (
                data.get("requesterProfileShared") is False
                and data.get("requesterName") is not None
            ):
                updates["requesterName"] = None
        else:
            changed += backfill_conversation_messages(
                doc.reference, data, name_index, apply_changes
            )

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
