# App Review Notes Draft

Sivra is an AI fluency training app for founders, operators, and teams.

The app provides a daily pack of short AI briefings and exercises. The user chooses focus areas, completes an 8-screen daily pack, writes a short answer on one exercise, and can review progress in Learning Memory, History, and Weekly Recap.

Sivra uses Firebase anonymous authentication for early testing. Daily pack content can be generated through a backend Firebase Function. The mobile app does not contain an OpenAI API key.

If AI generation is unavailable or content QA rejects generated content, the app falls back to curated content so the user can still complete the daily flow.

Internal/debug screens currently include Content QA, Source Admin, and Diagnostics. Diagnostics should be disabled for external TestFlight and production builds with:

```sh
--dart-define=SIVRA_DIAGNOSTICS=false
```

Deferred items:

- Subscriptions/paywall.
- Expanded onboarding.
- Landing page-hosted Privacy Policy, Terms, FAQ, and Support.
