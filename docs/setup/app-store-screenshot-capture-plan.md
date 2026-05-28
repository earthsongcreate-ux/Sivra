# Sivra App Store Screenshot Capture Plan

Milestone 15 uses a benefit-led screenshot plan. We are not generating polished marketing screenshots yet; first we need strong raw simulator captures that show the app in convincing, non-empty states.

## Current Apple Screenshot Target

For iPhone, App Store Connect accepts one to ten screenshots per display size. For the current first pass, capture portrait screenshots for the 6.9-inch display size.

Accepted 6.9-inch portrait sizes include:

- `1260 x 2736`
- `1290 x 2796`
- `1320 x 2868`

Use App Store Connect to confirm the exact size required before final upload.

## ASO Benefit Headlines

These are the first-pass benefit-led screenshot headlines. They are written as action-oriented claims that map to real Sivra screens.

1. `WALK INTO ANY ROOM PREPARED`
   - Screen: Today screen with a ready daily pack.
   - Why: Communicates readiness and the identity Sivra helps build.

2. `SHAPE HOW YOU THINK`
   - Screen: Onboarding focus selection.
   - Why: Turns personalization into an identity promise.

3. `PRACTICE CLEAR ANSWERS`
   - Screen: Articulation drill with a written answer.
   - Why: Shows the user doing the core learning work, not just reading.

4. `THINK WITH BETTER SIGNAL`
   - Screen: briefing with source sheet or Source Admin.
   - Why: Sells confidence rather than source mechanics.

5. `YOUR THINKING COMPOUNDS`
   - Screen: Learning Memory or Weekly Recap.
   - Why: Makes saved progress feel cumulative and personal.

6. `CONTINUE YOUR DAILY REHEARSAL`
   - Screen: Sivra Pro paywall.
   - Why: Frames Pro as continued disciplined practice.

## Raw Screenshot Set

Capture these raw app screens first:

1. `01-today-ready.png`
   - Today screen.
   - State: focus areas selected, daily pack ready, Pro prompt visible for free user.

2. `02-onboarding-focus.png`
   - Choose your focus screen.
   - State: at least one focus option selected, Continue enabled.

3. `03-articulation-answer.png`
   - Screen 7 articulation drill.
   - State: realistic answer typed, Next enabled.

4. `04-source-context.png`
   - Source bottom sheet or Content QA screen.
   - State: source title, publisher, and date visible.

5. `05-learning-memory.png`
   - Learning Memory screen.
   - State: at least one saved written answer visible.

6. `06-paywall.png`
   - Sivra Pro screen.
   - State: monthly and annual plans visible when RevenueCat is configured.

## Screenshot Quality Rules

Rate every raw screenshot before using it:

- Great: rich state, clear hierarchy, no debug banner, no placeholder content, obvious benefit.
- Usable: good enough for TestFlight/App Store draft, but could be clearer with better state.
- Retake: empty, sparse, confusing, debug UI visible, low-value screen, or too much tiny text.

Retake immediately if:

- Debug banner is visible.
- Content is empty or mostly placeholder.
- The keyboard covers important UI.
- The screen looks like settings/admin instead of user value.
- The status bar looks distracting.
- Text is clipped or overlapping.

## Capture Setup

Use:

- Dark mode.
- Clean simulator/device state.
- No personal data.
- Realistic test answers.
- Diagnostics disabled.
- Debug banner hidden.

Recommended run command:

```sh
cd apps/sivra
flutter run \
  --dart-define=SIVRA_BUILD_CHANNEL=screenshot \
  --dart-define=SIVRA_DIAGNOSTICS=false
```

Simulator screenshot command:

```sh
xcrun simctl io booted screenshot screenshots/app-store/raw/01-today-ready.png
```

Repo helper:

```sh
scripts/capture-ios-screenshot.sh 01-today-ready.png
```

Controlled raw screenshot generation:

```sh
cd apps/sivra
flutter test test/app_store_screenshot_test.dart \
  --update-goldens \
  --dart-define=GENERATE_APP_STORE_SCREENSHOTS=true
```

## Draft Pairings

| Headline | Raw screenshot | Status |
| --- | --- | --- |
| `WALK INTO ANY ROOM PREPARED` | `01-today-ready.png` | Captured, Usable |
| `SHAPE HOW YOU THINK` | `02-onboarding-focus.png` | Captured, Great |
| `PRACTICE CLEAR ANSWERS` | `03-articulation-answer.png` | Captured, Usable |
| `THINK WITH BETTER SIGNAL` | `04-source-context.png` | Captured, Usable |
| `YOUR THINKING COMPOUNDS` | `05-learning-memory.png` | Captured, Usable |
| `CONTINUE YOUR DAILY REHEARSAL` | `06-paywall.png` | Captured, Great |

Detailed raw QA notes live in `screenshots/app-store/raw/QA.md`.

## Later Polished ASO Pass

After raw screenshots are captured and approved:

1. Pair each benefit headline to the strongest raw screenshot.
2. Use a consistent brand background.
3. Keep large headline text in the top safe area.
4. Place app screenshots in consistent iPhone frames.
5. Resize/export to the exact App Store Connect dimensions.

Do not generate polished assets until the raw screenshots are rated Great or Usable.

When the raw screenshots are approved, continue with `docs/setup/app-store-screenshot-generation.md`.

## References

- Apple screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- Apple screenshot upload workflow: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
