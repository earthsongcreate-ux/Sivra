# Milestone 23: Backend Services + TestFlight Archive Dry Run

Date: 2026-06-01

## Backend Services

- Firebase Anonymous Auth remains the app identity layer.
- Firestore rules are tracked in `apps/sivra/firestore.rules` and referenced by
  `apps/sivra/firebase.json`.
- Users can read and write their own profile and daily pack documents.
- Users can create their own analytics event documents.
- The AI daily-pack function now requires a Firebase ID token and rejects a
  request when the authenticated user does not match the requested user id.
- Returning users with a Firestore profile now skip onboarding.

Deploy backend services from `apps/sivra`:

```sh
firebase deploy --only firestore:rules,functions
```

Configure the AI function before deployment:

```sh
firebase functions:secrets:set OPENAI_API_KEY
```

Set `OPENAI_MODEL` in the functions environment before deployment.

Verified locally:

- `firebase deploy --only firestore:rules --dry-run --project project-fc7d7ede-835b-4486-95a`
  passes.
- The combined Firestore + Functions dry run compiles the rules, analyzes the
  function, and packages the bundle.
- Functions deployment remains blocked until `OPENAI_API_KEY` is created in
  Firebase Secret Manager.

## Unsigned Archive Dry Run

Run:

```sh
scripts/testflight-archive-dry-run.sh
```

The script runs the iOS project security check, rejects active non-sample Git
hooks, runs Flutter analysis and tests, checks the Firebase Function syntax,
and builds an unsigned TestFlight-channel `.xcarchive`.

The dry run does not upload to App Store Connect. A signed archive still
requires the Apple distribution certificate, provisioning profile, build
number increment, production RevenueCat key, and deployed AI endpoint.

Verified locally:

- `scripts/testflight-archive-dry-run.sh` passes.
- Unsigned archive: `apps/sivra/build/ios/archive/Runner.xcarchive`.
- Validated app settings: version `1.0.0`, build `1`, deployment target `13.0`,
  bundle id `com.veloranlabs.sivra`.

## Dependency Note

`firebase-functions` is updated to `7.2.5`. `npm audit --omit=dev` still reports
nine moderate findings in Firebase Admin's transitive Google packages. npm's
suggested broad fix is a major downgrade of `firebase-admin`, so it was not
applied automatically.
