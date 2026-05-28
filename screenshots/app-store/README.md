# Sivra App Store Screenshots

Use this folder for raw and final App Store screenshot assets.

## Folders

- `raw/`: direct simulator or device captures.
- `final/`: resized/exported App Store Connect screenshots.

## Raw Capture Names

- `01-today-ready.png`
- `02-onboarding-focus.png`
- `03-articulation-answer.png`
- `04-source-context.png`
- `05-learning-memory.png`
- `06-paywall.png`

See `docs/setup/app-store-screenshot-capture-plan.md` for the storyboard and QA criteria.

## Final Generation

From the repo root:

```sh
scripts/generate-app-store-final-screenshots.sh
```

This creates the final `1320 x 2868` App Store screenshot set from the approved raw captures.
Final QA notes live in `final/QA.md`.
Brand assets used by the generator live in `brand/`.

## Helper Command

From the repo root:

```sh
scripts/capture-ios-screenshot.sh 01-today-ready.png
```

Check missing raw and final assets:

```sh
scripts/check-app-store-screenshots.sh
```

Prompt files for polished screenshot generation live in:

- `screenshots/app-store/prompts/`
