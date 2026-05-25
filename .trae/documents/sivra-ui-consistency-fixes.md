## Summary

Make two targeted Flutter UI consistency updates in `/Users/macbook/Sivra/apps/sivra` (no redesign):

1. Drill flow articulation step (7/8): remove the special “Continue then reveal” behavior, always show explanation under the textbox, and use a Next/Finish button that is disabled until the user types something.
2. Onboarding focus options: update copy to more founder-relevant options and tweak the subtitle string.

Then verify with `flutter test` and `flutter run`, and report exactly which files changed.

## Current State Analysis

### Articulation step behavior

File: `/Users/macbook/Sivra/apps/sivra/lib/screens/drill_flow_screen.dart`

- Drill flow is driven by `MockDailyPack.items` (8 total items; the articulation item is 7/8). Source: `/Users/macbook/Sivra/apps/sivra/lib/data/mock_daily_pack.dart`.
- For `DrillItemType.articulation`:
  - Body shows a `TextField` (multiline) and only shows `item.explanation` after `_revealed == true`.
  - Footer button currently behaves as:
    - Label is `Continue` before reveal, then `Next`/`Finish` after reveal.
    - `onPressed` toggles between `_reveal()` and `_next()` based on `_revealed`.
- Other item types follow a “Think first. Then reveal.” pattern and reveal answer/explanation after tapping Reveal.

### Onboarding copy

File: `/Users/macbook/Sivra/apps/sivra/lib/screens/onboarding_screen.dart`

- Options are currently `['Product', 'GTM', 'Hiring', 'Infra/Costs']`.
- Subtitle is currently `Pick up to 3. This shapes your daily brief.`
- Selection logic already supports “pick up to 3” (disables options once 3 are selected) and persists `focusAreas` to Firestore.

## Proposed Changes

### 1) Fix articulation step to match other screens’ mechanics (except for the required input)

File: `/Users/macbook/Sivra/apps/sivra/lib/screens/drill_flow_screen.dart`

Make these changes only inside the `DrillItemType.articulation` branches of `_buildBody` and `_buildFooter`:

1. Remove the “Continue then reveal” behavior for articulation
   - Do not gate any articulation UI on `_revealed`.
   - Do not use `_reveal()` from the articulation footer.

2. Always show explanation under the textbox (if present)
   - In `_buildBody`, render `item.explanation` under the `TextField` whenever `item.explanation?.isNotEmpty ?? false` is true (no `_revealed` check).

3. Update the bottom button behavior for articulation
   - Label:
     - `Next` when not on the last item
     - `Finish` on the last item
   - Disabled until the text field is non-empty using: `_articulationController.text.trim().isNotEmpty`
   - Add `onChanged` to the `TextField` that calls `setState(() {})` so the button enables immediately as the user types.
   - Keep existing `_finishing` handling so saving cannot be triggered multiple times (button remains disabled while finishing).

Implementation notes (to keep behavior unchanged beyond the request):
 - Keep `_revealed` as-is for non-articulation item types.
 - Do not change the existing reveal behavior for other item types.
 - Do not change progress labels, item order, Firestore completion, or navigation.

### 2) Make onboarding focus options more founder-relevant

File: `/Users/macbook/Sivra/apps/sivra/lib/screens/onboarding_screen.dart`

1. Change `_options` to:
   - `Product strategy`
   - `GTM & sales`
   - `Hiring & team`
   - `Infra & costs`

2. Change the subtitle copy to:
   - `Pick up to 3. This shapes your daily pack.`

Implementation notes:
 - Keep selection behavior exactly the same (still max 3).
 - Keep Firestore payload shape the same (still a `List<String>` stored to `focusAreas`).

## Assumptions & Decisions

- “Disabled until non-empty” applies only to the articulation step button; other steps remain unchanged.
- “Explanation text under the textbox (if present)” means “show when non-null and non-empty”; no placeholder text is added when it is absent.
- `flutter run` will be executed from `/Users/macbook/Sivra/apps/sivra` on the default available device (typically iOS simulator on macOS).

## Verification (Required)

Run these commands from `/Users/macbook/Sivra/apps/sivra`:

1. Static + unit/widget tests:
   - `flutter test`

2. App launch sanity check:
   - `flutter run`
   - Manual spot-check:
     - Navigate to Daily Pack and reach item 7/8 (articulation).
     - Verify explanation is visible under the textbox immediately.
     - Verify the Next/Finish button is disabled until the user types (trimmed non-empty), and enables immediately while typing.
     - Verify other steps still show the same Reveal flow as before.
     - Verify onboarding shows the updated option strings and subtitle; selection still caps at 3.

3. Report file changes:
   - Show changed files (expected: only the two files above).
   - Confirm “no behavior change” outside the two requested improvements.
