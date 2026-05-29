# Milestone 22: Native iOS Build Recovery + Security Hardening

Date: 2026-05-28

## 1. Xcode Build Hang Diagnosis

The earlier simulator build was not frozen. Verbose `xcodebuild` logs showed active native compilation in CocoaPods, especially:

- `RevenueCat`
- `FirebaseFirestoreInternal`
- `gRPC-Core`
- `BoringSSL-GRPC`
- `abseil`
- `leveldb-library`

The slow path was caused by building a generic simulator destination, which compiled broader simulator architecture work than needed.

Use a concrete simulator destination for local recovery builds:

```sh
xcodebuild \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=BA08B0FB-A974-490E-B63B-C3AC72FE0806' \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_IDENTITY='' \
  COMPILER_INDEX_STORE_ENABLE=NO \
  build
```

## 2. Repo And Hook Safety

The iOS project security scanner passed after the native builds:

```sh
scripts/check-ios-project-security.sh
```

No active non-sample Git hooks were present in `.git/hooks`.

## 3. Clean Simulator Build

A clean native simulator build succeeded for iPhone 17 Pro on iOS 26.5 using the concrete simulator destination above.

Remaining warnings are dependency warnings from CocoaPods deployment targets and generated script phases. They do not block the simulator build.

## 4. Simulator Runtime Check

The built `Runner.app` was installed and launched on the iPhone 17 Pro simulator.

Initial runtime issue found:

- The app reached `Unable to start` when backend startup sync failed.

Fix applied:

- Startup now falls back to onboarding if Auth/Profile loading is unavailable.
- Local-only fallback completion can proceed into a preview Daily Pack.
- Local-only onboarding disables analytics writes to avoid Firestore permission noise.

Verified result:

- The native simulator app now launches into the Sivra onboarding promise screen.

## 5. TestFlight Readiness Notes

Before a TestFlight upload:

- Use the concrete simulator build command above for local recovery checks.
- Run `flutter analyze`.
- Run `flutter test`.
- Run `scripts/check-ios-project-security.sh`.
- Confirm `.git/hooks` has no active non-sample hook.
- Confirm Firebase Auth and Firestore rules are configured for the TestFlight bundle.
- Confirm RevenueCat offerings are configured for `com.veloranlabs.sivra`.
- Archive from Xcode only after the simulator build and security scanner pass.

