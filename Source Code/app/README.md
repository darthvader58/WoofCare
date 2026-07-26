# WoofCare - App
An app for stray dogs in need.

## Google Maps API keys

Google Maps keys are supplied at build time and are not stored in tracked
source files. Use a separate, platform-restricted key for each target.

For a local Android build, create the ignored configuration file:

```bash
cp android/maps.properties.example android/maps.properties
```

Replace the placeholder with an Android-restricted Maps SDK key. In GitHub
Actions, add that key as the repository secret
`GOOGLE_MAPS_ANDROID_API_KEY`, then expose it only to the Android build step:

```yaml
- name: Build Android app
  env:
    GOOGLE_MAPS_ANDROID_API_KEY: ${{ secrets.GOOGLE_MAPS_ANDROID_API_KEY }}
  run: flutter build appbundle --release
```

The Android build reads the environment variable without writing it to the
repository. The signed Android Actions workflow also requires
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and
`ANDROID_KEY_PASSWORD`. Web builds use the separate `GOOGLE_MAPS_API_KEY` secret
configured in `.github/workflows/web.yml`. The native iOS setup is intentionally
deferred to a separate change and must use its own iOS-restricted key.

Do not reuse the web Maps key for Android or iOS. A Maps key can have only one
application-restriction type, so WoofCare needs distinct web-, Android-, and
iOS-restricted keys.

## Firebase client configuration

`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and
`lib/firebase_options.dart` contain Firebase client configuration. Firebase API
keys in these files identify the Firebase project; they are public by design
and do not authorize access to Firestore or Storage. Keep each platform's
Firebase-generated key restricted to Firebase APIs, enforce Firestore and
Storage Security Rules, and enable Firebase App Check before enforcing it in
the Firebase console.

The Web Push VAPID value is a public key and is used only by web builds. The web
Actions workflow reads it from `FIREBASE_WEB_VAPID_KEY` and now fails a
deployable build if that value is absent. Android and iOS Firebase Messaging do
not use the web VAPID key.

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
