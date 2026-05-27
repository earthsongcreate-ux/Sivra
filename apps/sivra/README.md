# Sivra

Sivra is a Flutter iOS app for daily AI fluency practice.

## Local QA

```sh
flutter analyze
flutter test
flutter run \
  --dart-define=SIVRA_BUILD_CHANNEL=local \
  --dart-define=SIVRA_DIAGNOSTICS=true
```

## TestFlight Build Shape

```sh
flutter build ipa --release \
  --dart-define=SIVRA_BUILD_CHANNEL=testflight \
  --dart-define=SIVRA_REVENUECAT_IOS_KEY=appl_your_public_sdk_key \
  --dart-define=SIVRA_PRO_ENTITLEMENT=sivra_pro \
  --dart-define=SIVRA_MONTHLY_PRODUCT_ID=sivra_monthly_1299 \
  --dart-define=SIVRA_ANNUAL_PRODUCT_ID=sivra_annual_9999 \
  --dart-define=SIVRA_AI_PACK_ENDPOINT=https://your-function-url \
  --dart-define=SIVRA_DIAGNOSTICS=false
```

See `docs/setup/testflight-store-configuration-pass.md` from the repo root for the full release-candidate checklist.

## Landing Page

The static landing page shell lives at `../../landing` from this app folder. It is intended for Cloud Pages with no build command.
