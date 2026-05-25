# Sivra V1 Persistence Test Plan

Use this checklist before TestFlight builds and after any auth, Firestore, onboarding, or daily-pack changes.

## Preconditions

- Firebase project is configured for the app.
- Anonymous Auth is enabled.
- Firestore database exists.
- Firestore rules allow the signed-in user to read/write `users/{uid}` and `users/{uid}/daily/{dayId}`.
- Test on an iOS simulator or physical iPhone using a debug or release build.

## 1. Fresh Install

Goal: A new anonymous user can start Sivra and create a profile.

Steps:

1. Delete the app from the simulator/device.
2. Reinstall and launch Sivra.
3. Confirm onboarding appears.
4. Select one to three focus areas.
5. Tap Continue.
6. Confirm the app lands on Today.
7. In Firestore, confirm a new `users/{uid}` document exists with `focusAreas`, `createdAt`, and `updatedAt`.

Pass:

- No startup error appears.
- Focus areas are saved under the anonymous user's uid.
- The app routes to Today after save.

## 2. Returning User

Goal: A user with an existing Firestore profile skips onboarding.

Steps:

1. Launch Sivra with the same installed app/user from the fresh install test.
2. Confirm the app opens directly to Today.
3. Restart the app and confirm it still opens to Today.

Pass:

- Onboarding does not appear for a user with an existing profile.

## 3. No Network

Goal: The app fails gracefully when Firebase cannot be reached.

Steps:

1. Disable network access for the simulator/device.
2. Launch Sivra.
3. Confirm startup shows a recoverable error state.
4. Restore network access.
5. Tap Try again.

Pass:

- The app does not crash.
- The user sees a clear retry path.
- The app proceeds after network is restored.

## 4. Slow Network

Goal: Loading and save states prevent confusion or repeated actions.

Steps:

1. Use a throttled or unstable network.
2. Launch Sivra.
3. Confirm the startup loading indicator is shown while auth/profile loads.
4. If onboarding appears, choose focus areas and tap Continue.
5. Confirm the Continue button is disabled while saving.

Pass:

- The app remains responsive.
- The user cannot double-submit onboarding.
- The app eventually proceeds or shows a recoverable error.

## 5. Failed Profile Save

Goal: Onboarding save failures are visible and retryable.

Steps:

1. Temporarily publish Firestore rules that block writes to `users/{uid}`.
2. Fresh install or clear the profile for the test user.
3. Launch Sivra and complete onboarding.
4. Tap Continue.
5. Restore the correct Firestore rules.
6. Tap Continue again.

Pass:

- The first save failure shows an error message.
- The Continue button becomes available again.
- The second attempt succeeds after rules are fixed.

## 6. Daily Completion Repeat

Goal: Daily completion writes are idempotent and do not create duplicate state.

Steps:

1. Open Today.
2. Complete the daily pack.
3. Confirm Firestore has `users/{uid}/daily/{YYYY-MM-DD}` with `completedAt` and `itemCount`.
4. Run the daily pack again on the same day.
5. Confirm the same daily document is updated/merged, not duplicated.

Pass:

- Completion saves successfully.
- Repeating the flow does not create multiple documents for the same day.
- The app returns to Today after each completion.

## Sign-Off

Record each run with:

- Date
- Tester
- Device or simulator
- Build number
- Firebase project id
- Result for each test case
- Notes or follow-up fixes
