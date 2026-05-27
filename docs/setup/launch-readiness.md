# Sivra Launch Readiness Foundation

This checklist prepares Sivra for TestFlight and later store submission. Privacy Policy, Terms, FAQ, and Support are intentionally excluded because they will live on the future landing page.

## Build Configuration

Use explicit build flags for every shared build:

```sh
flutter build ios \
  --dart-define=SIVRA_BUILD_CHANNEL=testflight \
  --dart-define=SIVRA_REVENUECAT_IOS_KEY=appl_your_public_sdk_key \
  --dart-define=SIVRA_PRO_ENTITLEMENT=sivra_pro \
  --dart-define=SIVRA_MONTHLY_PRODUCT_ID=sivra_monthly_1299 \
  --dart-define=SIVRA_ANNUAL_PRODUCT_ID=sivra_annual_9999 \
  --dart-define=SIVRA_AI_PACK_ENDPOINT=https://your-function-url \
  --dart-define=SIVRA_AI_PACK_TOKEN=optional-client-token \
  --dart-define=SIVRA_DIAGNOSTICS=false
```

For local QA, keep diagnostics enabled:

```sh
flutter run \
  --dart-define=SIVRA_BUILD_CHANNEL=local \
  --dart-define=SIVRA_DIAGNOSTICS=true
```

## Landing Page

- Static landing shell lives in `landing/`.
- Cloud Pages publish directory: `landing/`.
- Support email: `support@veloranlabs.com`.
- Footer: `© 2026 Veloran Labs`.
- Privacy, Terms, FAQ, and Support pages exist as placeholders and must be reviewed before public App Store submission.

## Firebase / AI Readiness

- Firebase anonymous auth enabled.
- Firestore rules reviewed before external testing.
- `generateDailyPack` function deployed.
- `OPENAI_API_KEY` configured as a Firebase secret.
- `OPENAI_MODEL` configured for the function environment.
- App launched with `SIVRA_AI_PACK_ENDPOINT`.
- AI fallback path tested by launching without `SIVRA_AI_PACK_ENDPOINT`.
- RevenueCat app created.
- RevenueCat current offering includes monthly and annual Sivra Pro packages.
- App launched with `SIVRA_REVENUECAT_IOS_KEY` or `SIVRA_REVENUECAT_ANDROID_KEY`.
- Free account receives curated packs.
- Pro account receives AI-generated packs.
- Content QA screen reviewed for at least one generated pack.
- Source Admin screen checked for source warnings and fallback count.

## TestFlight QA

- Fresh install opens the Focus screen.
- Onboarding V2 progresses through focus, level, obstacle, routine, and plan preview.
- Onboarding completion saves and moves to Today.
- Today creates or loads one daily pack.
- Today shows the Sivra Pro prompt for free users.
- Paywall opens, restores purchases, and can be dismissed with Continue free.
- Daily Pack advances through all 8 screens.
- Screen 7 saves written answer.
- Screen 8 Finish returns to Today.
- Today shows Done, progress, and answer count.
- Learning Memory shows saved answer.
- History shows recent packs.
- Weekly Recap shows aggregate counts.
- Source Admin opens and lists recent packs.
- Diagnostics is disabled for external TestFlight builds.

Use `docs/setup/testflight-store-configuration-pass.md` as the release-candidate checklist.

## App Review Notes Draft

Sivra is an AI fluency training app. It provides a daily pack of short briefings and exercises based on the user's selected focus areas. Users can complete the daily pack, save written answers, review past packs, and inspect source and content QA information.

Current authentication uses Firebase anonymous auth. AI-generated content is produced through a backend Firebase Function; the mobile app does not contain an OpenAI API key.

If AI generation is unavailable, Sivra uses curated fallback content so the app remains functional.

## Known Deferred Items

- Final Privacy Policy copy.
- Final Terms copy.
- Final hosted domain.
