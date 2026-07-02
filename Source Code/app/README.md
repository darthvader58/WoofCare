# WoofCare - App
An app for stray dogs in need.

## Firestore location privacy validation

The Firestore rules and emulator test harness validate the report-location
privacy contract without using real Firebase credentials.

Install the local test dependencies once:

```bash
npm install
```

Run the rules validation:

```bash
npm run test:rules
```

The test seeds emulator-only data and verifies:

- public `reports/{reportId}` documents are readable only when they contain
  fuzzed coordinates and do not leak exact coordinate fields or values
- unauthenticated and ordinary clients can read fuzzed report coordinates
- unverified organizations, non-accepted organizations, and non-consented users
  cannot read `report_locations/{reportId}`
- the reporter, a verified accepted organization, and a user with a report-chat
  location consent grant can read exact coordinates from the private location
  document

This validation expects exact report coordinates to live at
`report_locations/{reportId}` and exact-location grants to live at
`report_location_grants/{grantId}`. Existing production report documents that
still store exact `latitude` or `longitude` values on the public report document
must be migrated before these rules are deployed.
