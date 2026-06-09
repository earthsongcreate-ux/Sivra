# Sivra Paywall and RevenueCat Setup

Sivra uses RevenueCat entitlement checks, hosted RevenueCat paywalls, and AI pack gating.

## Recommended Offer

- Monthly: `$12.99`, no trial.
- Annual: `$99.99`, 7-day free trial.

RevenueCat and App Store Connect are the source of truth for pricing, trial, and paywall copy.

## RevenueCat Dashboard

Create these products in App Store Connect and Google Play, then attach them to a RevenueCat offering:

- Monthly product ID: `sivra_monthly_1299`
- Annual product ID: `sivra_annual_9999`
- Entitlement ID: `sivra_pro`
- Offering: `default`, configured as the current offering.
- Monthly package: `$rc_monthly` -> `sivra_monthly_1299`.
- Annual package: `$rc_annual` -> `sivra_annual_9999`.

Only the annual subscription should include the 7-day free trial in the store configuration. The monthly plan is a straight subscription with no trial.

The hosted RevenueCat paywall connected to the current `default` offering is presented from the app with `RevenueCatUI.presentPaywallIfNeeded("sivra_pro")`.

## App Build Flags

Run local builds without RevenueCat keys to test the free curated path:

```sh
flutter run \
  --dart-define=SIVRA_BUILD_CHANNEL=local \
  --dart-define=SIVRA_DIAGNOSTICS=true
```

Run TestFlight or internal builds with RevenueCat keys:

```sh
flutter build ios \
  --dart-define=SIVRA_BUILD_CHANNEL=testflight \
  --dart-define=SIVRA_REVENUECAT_IOS_KEY=<RevenueCat public iOS SDK key> \
  --dart-define=SIVRA_PRO_ENTITLEMENT=sivra_pro \
  --dart-define=SIVRA_MONTHLY_PRODUCT_ID=sivra_monthly_1299 \
  --dart-define=SIVRA_ANNUAL_PRODUCT_ID=sivra_annual_9999 \
  --dart-define=SIVRA_AI_PACK_ENDPOINT=https://your-function-url \
  --dart-define=SIVRA_DIAGNOSTICS=false
```

Use `SIVRA_REVENUECAT_ANDROID_KEY` for Android builds.

## App Behavior

- Free users receive the curated daily pack.
- Pro users unlock AI-generated packs.
- Existing packs still load even if entitlement status changes.
- If RevenueCat is missing or unavailable, Sivra falls back to the free curated path.
- Restore purchases is available from the paywall.

## QA Checklist

- Fresh install opens Focus screen.
- Completing Focus lands on Today.
- Today shows the Sivra Pro prompt for free users.
- Hosted RevenueCat paywall opens when RevenueCat is configured and `sivra_pro` is not active.
- Closing the hosted paywall without purchase leaves curated packs available.
- Restore purchases activates Pro for a valid subscribed test account.
- Pro account creates an AI-generated pack when the AI endpoint is configured.
- Free account creates a `curated_free_v1` pack.
- Diagnostics shows RevenueCat configuration and product IDs.
