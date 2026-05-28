# Sivra Milestone 17: Polished App Store Screenshot Generation

Milestone 17 turns approved raw simulator screenshots into polished App Store marketing screenshots.

The raw screenshots in `screenshots/app-store/raw/` have been captured and rated Great or Usable.
See `screenshots/app-store/raw/QA.md` for the approval notes.

The first-pass final screenshots have been generated in `screenshots/app-store/final/`.
See `screenshots/app-store/final/QA.md` for final QA notes.

## Inputs Required

Raw screenshots:

- `screenshots/app-store/raw/01-today-ready.png`
- `screenshots/app-store/raw/02-onboarding-focus.png`
- `screenshots/app-store/raw/03-articulation-answer.png`
- `screenshots/app-store/raw/04-source-context.png`
- `screenshots/app-store/raw/05-learning-memory.png`
- `screenshots/app-store/raw/06-paywall.png`

Output folder:

- `screenshots/app-store/final/`

Target output:

- Portrait App Store screenshots.
- Exact export size confirmed in App Store Connect before upload.
- First-pass target: `1320 x 2868` for iPhone 6.9-inch portrait.

## Brand Direction

Use Sivra’s current visual identity:

- Background: deep navy, `#07111F`.
- Accent: muted bronze, `#B89467`.
- Text: warm off-white, `#F2F0EA`.
- Device: black modern iPhone frame with Dynamic Island.
- Style: calm, premium, practical, not flashy.

Avoid:

- Random sparkles or decorative clutter.
- Purple gradient backgrounds.
- Fake UI that is not in the app.
- Tiny text close to the canvas edges.
- Overpromising outcomes.

## Final Screenshot Set

| File | Headline | Raw input |
| --- | --- | --- |
| `01-build-ai-fluency-daily.png` | `WALK INTO ANY ROOM PREPARED` | `01-today-ready.png` |
| `02-choose-your-focus.png` | `SHAPE HOW YOU THINK` | `02-onboarding-focus.png` |
| `03-practice-clear-answers.png` | `PRACTICE CLEAR ANSWERS` | `03-articulation-answer.png` |
| `04-review-trusted-sources.png` | `THINK WITH BETTER SIGNAL` | `04-source-context.png` |
| `05-track-learning-memory.png` | `YOUR THINKING COMPOUNDS` | `05-learning-memory.png` |
| `06-unlock-ai-packs.png` | `CONTINUE YOUR DAILY REHEARSAL` | `06-paywall.png` |

## Master Prompt For ChatGPT Image Generation

Use this prompt with one raw screenshot at a time.

```text
Create a polished App Store screenshot for Sivra, a daily AI fluency iPhone app.

Use the attached raw app screenshot as the phone screen content. Do not change the app UI inside the phone.

Canvas:
- Portrait App Store screenshot.
- Export-ready composition for iPhone App Store screenshots.
- Use exact final size if supported: 1320 x 2868.
- If exact size is not supported, create a high-resolution portrait image that can be cropped/resized to 1320 x 2868 without cutting off text.

Brand:
- Solid deep navy background: #09111F.
- Warm bronze accent: #C79A6B.
- Warm off-white text: #F5F2ED.
- Premium, calm, practical, founder-focused.
- No gradients, no purple glow, no decorative clutter.

Headline:
- Use this exact headline: [HEADLINE HERE]
- Uppercase.
- Large, bold, centered near the top.
- Keep all headline text well inside the center safe area with generous side margins.
- Do not add any extra headline words.

Device:
- Place the raw app screenshot inside a modern black iPhone frame with Dynamic Island.
- Center the phone.
- Phone may extend slightly off the bottom edge for a modern App Store look.
- Keep the app screenshot readable.

Optional enhancement:
- Only add a subtle enlarged UI callout if there is a clear complete panel in the raw screenshot that directly supports the headline.
- Do not invent new UI.
- Do not add unrelated icons or random visual effects.

Restrictions:
- No fake App Store badges.
- No extra legal text.
- No watermarks.
- No form fields.
- No claims not visible or supported by the app.

Output a clean, polished App Store screenshot that looks consistent with a premium productivity/education app.
```

Replace `[HEADLINE HERE]` with the exact headline from the table.

## Per-Screenshot Prompt Notes

### 01: WALK INTO ANY ROOM PREPARED

Use `01-today-ready.png`.

Subheadline: `A 7-minute ritual for founders and operators who think for a living.`

Emphasize identity and readiness, not just the daily-pack feature.

### 02: SHAPE HOW YOU THINK

Use `02-onboarding-focus.png`.

Subheadline: `Choose the rooms you want to become sharper in.`

Keep this clean. The focus list supports the identity message.

### 03: PRACTICE CLEAR ANSWERS

Use `03-articulation-answer.png`.

The written answer is the hero. Make sure the text field remains readable and not hidden by the device crop.

### 04: THINK WITH BETTER SIGNAL

Use `04-source-context.png`.

Subheadline: `Confidence starts with source quality.`

If the source sheet is visible, it can be lightly emphasized as the trust signal. Do not invent source names.

### 05: YOUR THINKING COMPOUNDS

Use `05-learning-memory.png`.

Subheadline: `Save the ideas worth keeping.`

Show the idea that progress persists over time. A subtle callout around saved answers or recap metrics may work.

### 06: CONTINUE YOUR DAILY REHEARSAL

Use `06-paywall.png`.

Subheadline: `Personalized Daily Packs that sharpen thinking over time.`

Keep the transformation central while preserving transparent paywall details inside the app UI.

## QA Checklist For Generated Images

Rate every generated image:

- Great: clear headline, readable app UI, consistent brand, exact size or safely resizable.
- Usable: acceptable but could use better crop, text size, or device framing.
- Regenerate: UI altered, text clipped, fake elements added, hard to read, wrong dimensions, or inconsistent style.

Reject immediately if:

- The app UI inside the phone was changed.
- The image adds claims Sivra does not make.
- The headline differs from the approved wording.
- The output has a watermark.
- The support/legal/paywall details are obscured in subscription screenshots.

## Resize / Export

After approving an image:

1. Save it to `screenshots/app-store/final/`.
2. Confirm dimensions.
3. Resize/crop only if needed for App Store Connect.
4. Re-check that no headline text is clipped after resizing.

Use the final filenames from the screenshot table.

## Local Generator

The committed local generator creates the full first-pass set:

```sh
scripts/generate-app-store-final-screenshots.sh
```

The generator requires ImageMagick and keeps the app UI inside the phone frame based on the approved raw captures.
It uses the Sivra horizontal logo lockup from `screenshots/app-store/brand/`.
