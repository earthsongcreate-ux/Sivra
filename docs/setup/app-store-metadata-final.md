# Sivra App Store Metadata Final Pass

Milestone 15 finalizes the first App Store metadata set for TestFlight and App Store Connect entry.

## App Identity

- App name: `Sivra`
- Bundle ID: `com.veloranlabs.sivra`
- Primary category: Education
- Secondary category: Business
- Copyright: `© 2026 Veloran Labs`
- Support email: `support@veloranlabs.com`

## Subtitle

```text
Daily AI fluency for founders
```

Length: 29 characters.

## Promotional Text

```text
A calm daily ritual for staying sharp on AI: briefings, drills, and articulation practice in about 8 minutes.
```

## Description

```text
Sivra helps founders and ambitious professionals build practical AI fluency without doomscrolling.

Each daily pack combines concise briefings, source-aware explanations, and short drills that help you think more clearly about AI strategy, risk, adoption, and everyday work decisions.

Choose your focus areas, complete a daily pack, write clearer answers, and review your learning memory over time.

Sivra is built for people who need to explain AI clearly, evaluate tradeoffs, and make better decisions without chasing every headline.

Sivra Pro unlocks AI-generated daily packs when available. Free users can continue with curated packs.

Subscription details:
Monthly: $12.99 per month with no trial.
Annual: $99.99 per year after a 7-day free trial.

Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. You can manage or cancel subscriptions in your App Store account settings.
```

## Keywords

```text
AI,founder,learning,briefings,drills,strategy,startup,productivity,education,business
```

Approximate length: 86 characters.

## Review Notes

```text
Sivra uses Firebase Anonymous Auth. No login credentials are required.

On first launch, choose one to three focus areas, answer the short onboarding questionnaire, and enter the daily pack experience.

Sivra Pro subscriptions are managed through RevenueCat and the App Store. Free users can continue using curated daily packs. Pro users unlock AI-generated packs when the backend AI endpoint is configured.

The mobile app does not contain an OpenAI API key. AI-generated content is produced through a backend Firebase Function. If AI generation is unavailable, Sivra falls back to curated content so the core experience remains usable.
```

## App Privacy Draft

Likely App Privacy categories for V1:

- User ID: Firebase anonymous user ID and RevenueCat app user ID.
- Product Interaction: onboarding choices, daily pack progress, written answers, and app events.
- Purchase History: subscription entitlement and product identifiers through RevenueCat.

Current non-collection claims:

- No name.
- No email account.
- No phone number.
- No precise location.
- No contacts.
- No photos.
- No advertising tracking.
- No health data.

Re-check before submission if analytics, crash reporting, push notifications, email accounts, or new payment providers are added.

## URLs To Fill After Cloud Pages Is Live

- Marketing URL: landing page root.
- Privacy Policy URL: `/privacy.html`.
- Terms URL: `/terms.html`.
- Support URL: `/support.html`.
- FAQ URL: `/faq.html`.

The Privacy and Terms pages are currently placeholders and must be reviewed before public App Store submission.
