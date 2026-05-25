## Summary

Implement Firebase Anonymous Auth and Firestore persistence for Sivra V1:
- Automatically sign in anonymously on app start (for testing).
- Save onboarding focus areas to Firestore.
- Save “daily pack completed” to Firestore when the user finishes the drill flow.
- On app launch, skip onboarding if the user already has a profile document; go straight to Today.

This plan does not include Firebase Console setup (enabling Anonymous Auth, creating Firestore DB), per the prerequisites.

## Current State Analysis (Repo Truth)

**Firebase**
- Firebase is initialized in [main.dart](file:///Users/macbook/Sivra/apps/sivra/lib/main.dart#L5-L19) using generated [firebase_options.dart](file:///Users/macbook/Sivra/apps/sivra/lib/firebase_options.dart).
- The app currently runs a placeholder `MaterialApp` with a single “Sivra” text screen (it does not run `SivraApp` yet).

**Navigation / Screens**
- `SivraApp` exists and defines theme + routes but currently starts at onboarding: [sivra_app.dart](file:///Users/macbook/Sivra/apps/sivra/lib/sivra_app.dart#L7-L22).
- Onboarding selection UI exists but is not persisted: [onboarding_screen.dart](file:///Users/macbook/Sivra/apps/sivra/lib/screens/onboarding_screen.dart#L12-L114).
- Today is a static screen that starts the drill flow: [today_screen.dart](file:///Users/macbook/Sivra/apps/sivra/lib/screens/today_screen.dart#L5-L51).
- Drill flow finishes by popping the route; no persistence: [drill_flow_screen.dart](file:///Users/macbook/Sivra/apps/sivra/lib/screens/drill_flow_screen.dart#L28-L41).

**Dependencies**
- `firebase_core` is present. `firebase_auth` and `cloud_firestore` are not yet included: [pubspec.yaml](file:///Users/macbook/Sivra/apps/sivra/pubspec.yaml#L30-L38).

## Proposed Data Model (Firestore)

**1) User Profile**
- Path: `users/{uid}`
- Fields:
  - `focusAreas: List<String>`
  - `createdAt: server timestamp` (set once when doc is first created)
  - `updatedAt: server timestamp` (updated on every upsert)

**2) Daily Pack Completion**
- Path: `users/{uid}/daily/{dayId}`
- `dayId` format: `YYYY-MM-DD` (local date)
- Fields:
  - `completedAt: server timestamp`
  - `itemCount: int` (number of drill items in that pack)

Rationale:
- Using `users/{uid}` makes “profile exists?” a single document existence check.
- Using `daily/{dayId}` makes “completed today?” a simple doc existence/read.

## Proposed Changes (Files + What/Why/How)

### A) Add dependencies

1) Edit [apps/sivra/pubspec.yaml](file:///Users/macbook/Sivra/apps/sivra/pubspec.yaml)
- Under `dependencies:` add:
  - `firebase_auth: ^6.0.0`
  - `cloud_firestore: ^6.0.0`

2) Run:
- `cd /Users/macbook/Sivra/apps/sivra`
- `flutter pub get`

### B) Ensure the real app boots

Edit [main.dart](file:///Users/macbook/Sivra/apps/sivra/lib/main.dart)
- Replace the placeholder `MaterialApp` with `runApp(const SivraApp());`
- Add import for `sivra_app.dart`.

Why:
- Firestore/auth flows need to run through the actual app screens and routing.

### C) Add Auth + Firestore services (thin wrappers)

Add file: `apps/sivra/lib/services/auth_service.dart`
- `AuthService.ensureSignedIn()`:
  - If a Firebase user already exists, return it.
  - Else call `FirebaseAuth.instance.signInAnonymously()`.

Add file: `apps/sivra/lib/services/firestore_service.dart`
- `getProfile(uid)` → read `users/{uid}` and map to a `UserProfile`.
- `upsertProfile(uid, focusAreas)` → transaction or merge write:
  - set `focusAreas`, `updatedAt`
  - if doc doesn’t exist, also set `createdAt`
- `markDailyCompleted(uid, dayId, itemCount)` → write/merge `users/{uid}/daily/{dayId}` with `completedAt` and `itemCount`.

Why:
- Keeps Firebase SDK calls out of widgets and makes flows easy to test/adjust.

### D) Add model + utility

Add file: `apps/sivra/lib/models/user_profile.dart`
- Simple model with `uid` and `focusAreas`, plus a `fromMap` factory.

Add file: `apps/sivra/lib/utils/day_id.dart`
- Helper to format a `DateTime` into `YYYY-MM-DD`.

### E) Add a Bootstrap gate (skip onboarding if profile exists)

Add file: `apps/sivra/lib/screens/bootstrap_screen.dart`
- On init:
  1) `AuthService.ensureSignedIn()`
  2) `FirestoreService.getProfile(uid)`
- Render states:
  - Loading → spinner
  - Error/null state → simple “Unable to start”
  - `profile != null` → show `TodayScreen`
  - else → show `OnboardingScreen(uid: uid, onCompleted: …)`
- `onCompleted` updates local bootstrap state so the user sees Today immediately after onboarding without restarting the app.

Edit [sivra_app.dart](file:///Users/macbook/Sivra/apps/sivra/lib/sivra_app.dart)
- Change `home:` from `OnboardingScreen()` to `BootstrapScreen()`.

Why:
- Deterministic decision point on launch that satisfies “skip onboarding if profile exists”.

### F) Persist onboarding focus areas

Edit [onboarding_screen.dart](file:///Users/macbook/Sivra/apps/sivra/lib/screens/onboarding_screen.dart)
- Update `OnboardingScreen` to accept:
  - `uid: String`
  - `onCompleted: VoidCallback`
- Add `_saving` state + `_continue()` async method:
  - guard against invalid state or double taps
  - call `FirestoreService.upsertProfile(uid: widget.uid, focusAreas: _selected.toList())`
  - call `widget.onCompleted()`
  - navigate to Today (replace)
- Button:
  - disabled while saving
  - show “Saving…” while saving

Why:
- Ensures focus areas are persisted before the user enters Today and makes “profile exists” true on next launch.

### G) Persist “daily pack completed” on drill finish

Edit [drill_flow_screen.dart](file:///Users/macbook/Sivra/apps/sivra/lib/screens/drill_flow_screen.dart)
- Replace the final-step `Navigator.pop()` with an async `_finish()` method:
  - read `FirebaseAuth.instance.currentUser?.uid`
  - if uid exists, call:
    - `FirestoreService.markDailyCompleted(uid: uid, dayId: dayIdFromDate(DateTime.now()), itemCount: _items.length)`
  - then `Navigator.pop()` if still mounted

Why:
- Ensures completion is recorded the moment the user finishes the drill flow.

### H) Fix tests impacted by constructor changes

Edit [widget_test.dart](file:///Users/macbook/Sivra/apps/sivra/test/widget_test.dart)
- Update `OnboardingScreen()` usage to pass required params:
  - `uid: 'test'`
  - `onCompleted: () {}`

Optional (if the project has more tests later):
- Add a small unit test for `dayIdFromDate`.

## Assumptions & Decisions (Locked)

- “Profile exists” means: Firestore doc `users/{uid}` exists (regardless of fields).
- Anonymous auth is acceptable for V1 testing and is initiated by the app (no sign-in UI).
- Firestore write failures do not block navigation permanently; the UI will show “Unable to start” only if bootstrap cannot determine state.
- Day completion uses local date (`DateTime.now()`), formatted as `YYYY-MM-DD`.

## Verification (Required)

**Static / Build**
- Run Flutter analyze for the app package:
  - `cd /Users/macbook/Sivra/apps/sivra`
  - `flutter analyze`

**Unit/Widget tests**
- `cd /Users/macbook/Sivra/apps/sivra`
- `flutter test`

**Manual workflow (Simulator)**
1) Fresh install or clear app data → launch app
   - Expect: silent anonymous sign-in, then onboarding shown.
2) Select 1–3 focus areas → Continue
   - Expect: button shows “Saving…” briefly, then Today screen.
3) Kill and relaunch app
   - Expect: onboarding is skipped; app opens directly to Today.
4) From Today → Start → finish all drill items
   - Expect: on last step “Finish” returns to Today; Firestore has `users/{uid}/daily/{YYYY-MM-DD}` written.
