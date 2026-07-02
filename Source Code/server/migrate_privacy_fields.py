"""Backfill Firestore privacy fields used by the WoofCare app.

Run from the server directory:

    python migrate_privacy_fields.py firebase-credentials.json
    python migrate_privacy_fields.py firebase-credentials.json --apply

The default mode is a dry run. Use --apply to write changes.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore


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
