# Milestone 21: TestFlight Build + Device QA Pass

Date: 2026-05-28

## Testing Rule Used

This pass follows the codebase testing rule supplied in `codebase-testing-global-rule.docx`:

1. Static checks first.
2. Unit and widget tests next.
3. Workflow validation for user-critical paths.
4. Regression checks for changed behavior.
5. Clear release notes for blockers and residual risk.

## 1. Clean iOS Build

Status: Blocked.

Checks completed:

- `flutter analyze`: passed.
- `flutter test`: passed.
- iOS asset catalog JSON validation: passed.
- Launch storyboard XML validation: passed.
- App icon and launch image dimensions: passed.
- `git diff --check`: passed.
- `scripts/check-ios-project-security.sh`: passed after cleanup.

Build attempt:

```sh
flutter build ios --simulator --no-codesign
```

Result:

- Pod install completed.
- Xcode build ran silently for about 8 minutes.
- Build was interrupted to avoid leaving a hung build process.
- Output showed RevenueCat and dependency warnings, but no app icon, launch image, or storyboard errors before interruption.

Blocker:

- A clean simulator build has not completed yet.
- TestFlight should not proceed until this build completes successfully.

Security finding:

- A local `.git/hooks/pre-commit` hook was found running an obfuscated shell command.
- The hook was removed locally.
- The Xcode project file was cleaned of the injected README build rule, `A8DAD24` build settings, and obfuscated shell execution path.
- A repo script now checks for these markers.

## 2. First-Run QA

Status: Passed with one fix.

Validated:

- Onboarding opens on `Walk into any room prepared.`
- Flow advances through:
  - Promise
  - Daily Pack ritual
  - Personalization
  - Identity shift
- Personalization now enforces max 3 role selections at interaction time.

Regression added:

- `onboarding limits personalization to three roles`

## 3. Core Product QA

Status: Passed in automated workflow tests.

Validated:

- Daily Pack starts.
- Screens advance through 1/8 to 8/8.
- Screen 7 accepts a typed answer.
- After Screen 7, Next advances to Screen 8.
- Back from Screen 8 returns to Screen 7 and preserves the typed answer.
- Finish returns to Today and marks progress as done.
- Daily Pack validator accepts valid generated pack shape.
- Validator rejects vague placeholder source context.
- Weekly recap summarizes recent packs.
- Personalization engine identifies weak drill types.
- Learning profile round-trips safely.
- Source audit summarizes trusted sources and fallback count.

## 4. Paywall QA

Status: Passed for fallback behavior.

Validated:

- Paywall renders when RevenueCat is not configured.
- Fallback copy appears:
  - `RevenueCat offerings are not available in this build. Free curated packs remain available.`
- Restore purchases path is present.
- Restore purchases returns a clear no-active-purchase message.
- Continue free path remains available.

Remaining device QA:

- Live RevenueCat purchase flow still needs TestFlight or sandbox account validation after the iOS build blocker is cleared.

## 5. TestFlight Readiness Notes

Current readiness: Not ready for TestFlight submission.

Blocking items:

1. Complete a clean iOS simulator or device build without interruption.
2. Confirm the Xcode project remains clean after build and commit operations.
3. Run a real first-install device pass once the build is installable.
4. Validate RevenueCat sandbox purchase and restore flows.

Non-blocking warnings:

- RevenueCat emits Swift `Sendable` warnings from pod code.
- `purchases_flutter` emits a deprecated debug log API warning from plugin code.

Recommended next action:

- Resolve the long-running Xcode build first. Do not continue to TestFlight upload until the native build completes cleanly.
