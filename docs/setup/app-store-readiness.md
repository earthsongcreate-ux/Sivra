# Sivra V1 App Store Readiness

Use this as the working checklist for TestFlight and App Store Connect.

## Build Identity

- App name: Sivra
- Bundle ID: `com.veloranlabs.sivra`
- Version: `1.0.0`
- Build: `1`
- Platform scope for V1: iPhone
- Firebase project: `project-fc7d7ede-835b-4486-95a`
- Signing team in Xcode project: `SC5G3FJ7FG`

## Current Build Status

- Debug simulator build: passed.
- Release iPhone build without codesigning: passed.
- Signed IPA export: blocked by local keychain/code signing. `codesign` stalled while signing `Flutter.framework`.

Before the next IPA attempt:

1. Open Xcode.
2. Open `apps/sivra/ios/Runner.xcworkspace`.
3. Confirm the Runner target has the correct team selected.
4. In macOS Keychain prompts, allow Xcode/codesign to access the signing certificate.
5. Run `flutter build ipa --release`.

## App Store Metadata Draft

### Subtitle

Daily AI fluency for founders.

### Promotional Text

A calm daily ritual for staying sharp on AI: briefings, drills, and articulation practice in about 8 minutes.

### Short Description

Sivra helps founders and ambitious professionals build daily AI fluency without doomscrolling. Each session combines concise briefings with practical drills for clearer thinking, better decisions, and stronger conversations.

### Keywords

AI, founder, learning, briefings, drills, strategy, startup, productivity, education, business

### Category

Primary: Education

Secondary: Business

## Screenshot Plan

Capture iPhone portrait screenshots for:

1. Onboarding focus selection.
2. Onboarding plan preview.
3. Today screen.
4. Daily briefing prompt.
5. Source bottom sheet.
6. Drill answer/reveal state.
7. Articulation drill.
8. Learning Memory or Weekly Recap.

Use real app screens, not marketing mockups, for the first TestFlight/App Store pass.

See `docs/setup/app-store-assets-and-landing.md` for the full asset plan.

## Privacy Notes

Sivra V1 uses:

- Firebase Anonymous Auth.
- Firestore user profile document at `users/{uid}`.
- Firestore daily completion documents at `users/{uid}/daily/{dayId}`.

Data stored:

- Anonymous Firebase user id.
- Selected focus areas.
- Onboarding level, obstacle, and routine choices.
- Daily completion timestamp.
- Daily item count.
- Written drill answers.
- Subscription entitlement and product identifiers through RevenueCat.

Sivra V1 does not currently collect:

- Name.
- Email.
- Phone number.
- Precise location.
- Contacts.
- Photos.
- Advertising ID.
- Payment information.

Recommended App Privacy answers for V1:

- Data linked to user: User ID, Product Interaction, Purchase History.
- Tracking: No.
- Third-party advertising: No.

Confirm these answers again before submission if analytics, purchases, accounts, crash reporting, or notifications are added.

## URLs Needed Before App Store Submission

- Marketing URL: landing page root once hosted.
- Privacy Policy URL: landing page `/privacy.html` once hosted.
- Terms URL: landing page `/terms.html` once hosted.
- Support URL: landing page `/support.html` once hosted.
- FAQ URL: landing page `/faq.html` once hosted.

## Review Notes Draft

Sivra uses Firebase Anonymous Auth. No login credentials are required. On first launch, choose one to three focus areas to enter the daily experience.

## Manual Release Checklist

1. Increment build number for each upload.
2. Run `flutter analyze`.
3. Run `flutter test`.
4. Run persistence test plan.
5. Run the TestFlight QA + Store Configuration Pass.
6. Run `flutter build ipa --release`.
7. Upload with Transporter or Xcode Organizer.
8. Confirm TestFlight processing.
9. Install from TestFlight and repeat the fresh-install and returning-user checks.
