# Sivra Paywall and RevenueCat Setup

Milestone 7 adds a custom Sivra paywall, RevenueCat entitlement checks, and AI pack gating.

## Recommended Offer

- 7-day free trial.
- Monthly: `$12.99`.
- Annual: `$99.99`.

The annual plan is the better anchor because it gives committed learners a meaningful discount while keeping the monthly plan available for cautious users.

## RevenueCat Dashboard

Create these products in App Store Connect and Google Play, then attach them to a RevenueCat offering:

- Monthly product ID: `sivra_monthly_1299`
- Annual product ID: `sivra_annual_9999`
- Entitlement ID: `sivra_pro`
- Offering: make the monthly and annual packages available in the current offering.

Both subscriptions should include the 7-day free trial in the store configuration. The app copy assumes that trial is active.

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
  --dart-define=SIVRA_REVENUECAT_IOS_KEY=appl_your_public_sdk_key \
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
- Paywall opens and lists monthly and annual packages when RevenueCat is configured.
- Continue free closes the paywall and leaves curated packs available.
- Restore purchases activates Pro for a valid subscribed test account.
- Pro account creates an AI-generated pack when the AI endpoint is configured.
- Free account creates a `curated_free_v1` pack.
- Diagnostics shows RevenueCat configuration and product IDs.
