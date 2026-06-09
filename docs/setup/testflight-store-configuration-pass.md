# Sivra Milestone 13: TestFlight QA + Store Configuration Pass

This is the operating checklist for getting Sivra from a local build to a useful TestFlight candidate.

Privacy Policy, Terms, FAQ, and Support pages are still deferred to the future landing page. Do not submit to public App Store review until those URLs exist.

## 1. Preflight Build Health

Run these before every candidate:

```sh
cd apps/sivra
flutter analyze
flutter test
node --check functions/index.js
```

Then run one iOS simulator build after native dependency changes:

```sh
flutter build ios --simulator --no-codesign
```

For archive/upload builds, use Xcode or:

```sh
flutter build ipa --release \
  --dart-define=SIVRA_BUILD_CHANNEL=testflight \
  --dart-define=SIVRA_REVENUECAT_IOS_KEY=<RevenueCat public iOS SDK key> \
  --dart-define=SIVRA_PRO_ENTITLEMENT=sivra_pro \
  --dart-define=SIVRA_MONTHLY_PRODUCT_ID=sivra_monthly_1299 \
  --dart-define=SIVRA_ANNUAL_PRODUCT_ID=sivra_annual_9999 \
  --dart-define=SIVRA_AI_PACK_ENDPOINT=https://your-function-url \
  --dart-define=SIVRA_DIAGNOSTICS=false
```

Increment the build number for every upload.

## 2. App Store Connect Setup

App identity:

- App name: `Sivra`
- Bundle ID: `com.veloranlabs.sivra`
- Category: Education
- Secondary category: Business
- Platform: iPhone first

Required before external TestFlight or App Store review:

- App icon uploaded.
- Age rating completed.
- Export compliance completed.
- App privacy answers completed.
- Test information filled in for beta review.
- Review notes explain Firebase anonymous auth and first-run flow.
- Privacy Policy URL added from the hosted landing page before public App Store submission.
- Support URL added from the hosted landing page before public App Store submission.

Internal TestFlight can be used before public App Store metadata is perfect, but external testing requires Beta App Review.

## 3. Subscription Configuration

Create one subscription group for Sivra Pro.

Products:

| Product | Product ID | Price | Trial |
| --- | --- | --- | --- |
| Monthly | `sivra_monthly_1299` | `$12.99/month` | No trial |
| Annual | `sivra_annual_9999` | `$99.99/year` | 7-day free trial |

App Store Connect:

- Create the auto-renewable subscriptions.
- Add localized display names and descriptions.
- Add the 7-day free trial only to the annual subscription as an introductory offer.
- Confirm pricing is correct in target storefronts.
- Confirm products are cleared for sale.

RevenueCat:

- Create entitlement `sivra_pro`.
- Attach both products to the entitlement.
- Create or update offering `default` and make it current.
- Add `$rc_monthly` -> `sivra_monthly_1299`.
- Add `$rc_annual` -> `sivra_annual_9999`.
- Confirm `SIVRA_REVENUECAT_IOS_KEY` is set to the RevenueCat public iOS SDK key from the dashboard and is never committed to docs.

Expected app behavior:

- No RevenueCat key: free curated packs still work.
- RevenueCat key but no active entitlement: user sees Sivra Pro prompt and receives curated packs.
- Active `sivra_pro`: user can receive AI-generated packs when the AI endpoint is configured.
- Restore purchases activates Pro for subscribed test accounts.

## 4. Firebase + AI Configuration

Firebase:

- Anonymous Auth enabled.
- Firestore enabled.
- Firestore rules reviewed for external testing.
- Function `generateDailyPack` deployed.

Function environment:

- `OPENAI_API_KEY`
- `OPENAI_MODEL`

App environment:

- `SIVRA_AI_PACK_ENDPOINT`

Never put the OpenAI API key into the Flutter app.
The app authenticates AI requests with the signed-in Firebase user's ID token.

## 5. Test Accounts

Create at least three test paths:

- Fresh free user: no purchase, first install, new anonymous auth.
- Returning free user: existing focus/profile/daily pack history.
- Pro test user: sandbox subscription active through RevenueCat.

For each build, record:

- Build number.
- Device model.
- iOS version.
- RevenueCat key present or missing.
- AI endpoint present or missing.
- Diagnostics enabled or disabled.

## 6. On-Device QA Script

### Fresh Install

1. Delete the app.
2. Install the TestFlight build.
3. Launch app.
4. Confirm first screen is `Walk into any room prepared.`
5. Continue to `Your Daily Pack (7 min)`.
6. Select one to three thinking roles.
7. Continue to `From informed → sharp.`
8. Tap `Start Day 1`.
9. Confirm Today loads.

### Today + Paywall

1. Confirm Today shows a daily pack.
2. Confirm free users see the Sivra Pro prompt.
3. Open paywall.
4. Confirm monthly and annual packages appear when RevenueCat is configured.
5. Confirm `Continue free` closes the paywall.
6. Confirm `Restore purchases` does not crash.

### Daily Pack

1. Tap `Start pack`.
2. Step through screens 1-6 using Reveal and Next.
3. On screen 7, type an answer.
4. Confirm Next enables after typing.
5. Tap Next.
6. Confirm screen 8 shows content and a Finish button.
7. Tap Finish.
8. Confirm Today shows Done, progress, and answer count.

### Back Navigation

1. Start a pack.
2. Advance to at least screen 3.
3. Tap the back arrow.
4. Confirm it returns to the previous pack screen, not Today.
5. Back from screen 1 may return to Today.

### Learning + History

1. Open Learning Memory.
2. Confirm written answer appears.
3. Open History.
4. Confirm completed pack appears.
5. Open Review.
6. Open Practice.
7. Confirm the pack starts.
8. Open Weekly Recap and confirm counts are understandable.

### Source Trust + QA

1. Open Content QA.
2. Confirm generator and QA score are visible.
3. Open Source Admin.
4. Confirm source counts, hosts, warnings, and fallback counts are visible.

### AI + Entitlement Matrix

| User | RevenueCat | AI endpoint | Expected pack |
| --- | --- | --- | --- |
| Free | Missing | Missing | `curated_free_v1` or existing curated pack |
| Free | Configured | Configured | `curated_free_v1` |
| Pro | Configured | Missing | `curated_fallback_v1` |
| Pro | Configured | Configured | AI pack if generation and QA pass |

## 7. App Privacy Working Notes

Current likely App Privacy categories for Sivra V1:

- User ID: Firebase anonymous user ID and RevenueCat app user ID.
- Product Interaction: onboarding choices, pack completion, events.
- Purchase History: subscription status/purchase identifiers via RevenueCat.

Current non-collection claims:

- No precise location.
- No contacts.
- No photos.
- No health data.
- No advertising tracking.
- No email/password account in the app.

Re-check this before submission if analytics, crash reporting, notifications, email accounts, or landing-page account creation are added.

## 8. Beta Review Notes Draft

Sivra is a daily AI fluency training app. Users can start without an account by using Firebase anonymous authentication. On first launch, choose focus areas and answer a short onboarding questionnaire. The app then creates a daily pack of briefings and drills.

Sivra Pro uses auto-renewable subscriptions managed through RevenueCat. Free users can continue using curated daily packs. Pro users unlock AI-generated packs when the backend AI endpoint is configured.

The mobile app does not contain an OpenAI API key. AI-generated content is produced through a backend Firebase Function. If AI generation is unavailable, the app falls back to curated content so the core experience remains usable.

## 9. Candidate Sign-Off

A build is ready for a small TestFlight group when:

- Analyze and tests pass.
- Simulator iOS build passes after native dependency changes.
- Fresh install QA passes.
- Free user QA passes.
- Pro sandbox QA passes.
- AI unavailable fallback QA passes.
- Diagnostics are disabled in external TestFlight builds.
- Known issues are written down with severity.

## 10. Landing + Assets

Before public App Store submission:

- Cloud Pages site is published from `landing/`.
- Footer shows `© 2026 Veloran Labs`.
- Support page uses `support@veloranlabs.com` and does not include a form.
- Privacy, Terms, FAQ, and Support URLs are entered in App Store Connect where required.
- App Store screenshots follow `docs/setup/app-store-assets-and-landing.md`.
- App Store metadata follows `docs/setup/app-store-metadata-final.md`.
- Raw screenshot capture follows `docs/setup/app-store-screenshot-capture-plan.md`.

## References

- Apple TestFlight overview: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Apple internal tester limits: https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers
- Apple introductory offers: https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions
- RevenueCat offerings: https://www.revenuecat.com/docs/offerings/overview
- RevenueCat SDK quickstart: https://www.revenuecat.com/docs/getting-started/quickstart
