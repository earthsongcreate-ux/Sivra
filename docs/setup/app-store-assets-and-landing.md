# Sivra Milestone 14: App Store Asset + Landing Page Shell

This milestone prepares the public-facing materials needed before a wider TestFlight and App Store submission.

## Landing Page

Static site location:

- `landing/index.html`
- `landing/privacy.html`
- `landing/terms.html`
- `landing/faq.html`
- `landing/support.html`

Hosting plan:

- Publish directory: `landing/`
- Build command: none
- Host: Cloud Pages when ready

Footer:

- `© 2026 Veloran Labs`

Support:

- `support@veloranlabs.com`
- No support form.

Required URL placeholders once hosted:

- Marketing URL: `https://your-domain/`
- Privacy Policy URL: `https://your-domain/privacy.html`
- Terms URL: `https://your-domain/terms.html`
- Support URL: `https://your-domain/support.html`
- FAQ URL: `https://your-domain/faq.html`

Replace `your-domain` after Cloud Pages is connected.

## App Store Copy

App name:

- `Sivra`

Subtitle:

- `Daily AI fluency for founders`

Promotional text:

- `A calm daily ritual for staying sharp on AI: briefings, drills, and articulation practice in about 8 minutes.`

Short description:

- `Sivra helps founders and ambitious professionals build daily AI fluency without doomscrolling. Each session combines concise briefings with practical drills for clearer thinking, better decisions, and stronger conversations.`

Keywords:

- `AI, founder, learning, briefings, drills, strategy, startup, productivity, education, business`

Categories:

- Primary: Education
- Secondary: Business

See `docs/setup/app-store-metadata-final.md` for the final App Store Connect copy block.

## Screenshot Storyboard

Capture real app screens first. Use marketing frames later only if the raw screenshots feel too plain.

Recommended first set:

1. Onboarding: `Choose your focus`
   - Caption idea: `Choose the AI topics that matter to your work.`
2. Onboarding: plan preview
   - Caption idea: `Start with a pack tuned to your level and routine.`
3. Today screen
   - Caption idea: `A daily pack you can finish between meetings.`
4. Briefing/reveal screen
   - Caption idea: `Read concise briefings with source context.`
5. Articulation drill
   - Caption idea: `Practice explaining AI tradeoffs clearly.`
6. Learning Memory or Weekly Recap
   - Caption idea: `Track your answers and build durable fluency.`
7. Sivra Pro paywall
   - Caption idea: `Try AI-generated daily packs with a 7-day trial.`

See `docs/setup/app-store-screenshot-capture-plan.md` for benefit headlines, raw capture names, and screenshot QA rules.

## Capture Checklist

- Use a clean simulator or physical device state.
- Avoid showing real personal data.
- Use a stable test account or anonymous test user.
- Prefer dark mode because Sivra’s current UI is designed around it.
- Hide debug banners for App Store screenshots.
- Capture the latest App Store Connect-required iPhone size before upload.
- Verify screenshot requirements in App Store Connect before final submission.

## Local Capture Commands

Run the app with production-like flags but diagnostics disabled:

```sh
cd apps/sivra
flutter run \
  --dart-define=SIVRA_BUILD_CHANNEL=screenshot \
  --dart-define=SIVRA_DIAGNOSTICS=false
```

Simulator screenshot:

```sh
xcrun simctl io booted screenshot screenshot-name.png
```

## App Icon Status

Existing app icon assets live in:

- `apps/sivra/ios/Runner/Assets.xcassets/AppIcon.appiconset`

Before App Store submission:

- Confirm the 1024x1024 icon is final.
- Confirm there is no alpha channel.
- Confirm it matches the visual identity used by the landing page.

## Legal Page Status

The current Privacy and Terms pages are placeholders. Before public App Store submission:

- Review and replace placeholder legal copy.
- Confirm subscription terms are represented clearly.
- Confirm App Privacy answers match the final app behavior.

## References

- Apple screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- Apple screenshot upload workflow: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
