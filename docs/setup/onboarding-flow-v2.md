# Sivra Onboarding Flow 2.0

Milestone 8 turns onboarding into a short questionnaire that creates a useful first daily pack without adding signup, permissions, or paywall friction.

## Product Choice

The attached onboarding questionnaire recommends a broad pattern used by subscription apps. Sivra uses the parts that fit the current build:

- Start with the core personalization input: focus areas.
- Ask only questions that change the learning experience.
- Keep Back available.
- Show progress.
- Defer permissions.
- Defer paywall until the user has context for the value.

## Flow

1. `focus`
   - Title: `Choose your focus`
   - Copy: `Pick up to 3. This shapes your daily pack.`
   - Options: Product strategy, GTM & sales, Hiring & team, Infra & costs.
   - CTA: `Continue`

2. `level`
   - Title: `How fluent are you with AI today?`
   - Options: New to AI, Experimenting, Using AI weekly, Leading adoption, Not sure.
   - CTA: `Continue`

3. `obstacle`
   - Title: `What usually gets in the way?`
   - Options: Too much noise, Explaining it clearly, Trust and risk, Finding useful cases, Not sure.
   - CTA: `Continue`

4. `routine`
   - Title: `What pace feels realistic?`
   - Options: 3 min/day, 5 min/day, 10 min/day, 3x/week.
   - Default: 5 min/day.
   - CTA: `Continue`

5. `plan_preview`
   - Title: `Your first pack is ready`
   - Shows the user’s focus, level, obstacle, and routine.
   - CTA: `Start first pack`

## Saved Profile Fields

Profile data is saved under the user document:

- `focusAreas`
- `onboarding.version`
- `onboarding.aiFluencyLevel`
- `onboarding.obstacle`
- `onboarding.routineTarget`
- `onboarding.completedAt`

## Analytics Events

- `onboarding_started`
- `onboarding_step_completed`
- `onboarding_completed`

Each event includes `version: 2`; step completion includes `step` and `stepId`.

## Deferred

- Push notification priming.
- Account gate.
- Paywall during onboarding.
- A true interactive demo inside onboarding.

Those are best added after TestFlight behavior is stable and after we decide exactly where the Pro trial should appear.
