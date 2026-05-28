# Sivra Onboarding Flow 3.0

Milestone 8 originally introduced personalization. The current V3 refinement tightens onboarding to Sivra’s standard: calm authority, executive clarity, and identity-led language.

## Product Choice

Sivra now uses a four-screen onboarding flow designed to complete in about 30-40 seconds:

- Lead with the promise, not a settings form.
- Explain the daily ritual.
- Ask one personalization question.
- End with the identity shift.
- Keep Back available.
- Show subtle dot progress.
- Defer permissions.
- Defer paywall until the user has context for the value.

## Flow

1. `promise`
   - Title: `Walk into any room prepared.`
   - Copy: `Sivra turns information into clear thinking—and helps you express it with calm, executive precision.`
   - CTA: `Continue`

2. `ritual`
   - Title: `Your Daily Pack (7 min)`
   - Copy: `2 briefings to stay current. 3 thinking drills to sharpen judgment. 1 articulation prompt to say it clearly.`
   - CTA: `Build my pack`

3. `personalization`
   - Title: `What do you think for a living?`
   - Copy: `Choose what matters most. Sivra shapes your Daily Pack around how you think.`
   - Options: Founder, Product / Strategy, Operator, Investor, Builder, Marketing, Other.
   - Max selections: 3.
   - CTA: `Continue`

4. `identity_shift`
   - Title: `From informed → sharp.`
   - Copy: `Six months from now, you won’t just know more. You’ll walk into meetings with a point of view, explain complexity simply, and think with greater precision under pressure.`
   - CTA: `Start Day 1`

## Saved Profile Fields

Profile data is saved under the user document:

- `focusAreas`
- `onboarding.version`
- `onboarding.thinkingRoles`
- `onboarding.completedAt`

Selected thinking roles are mapped to first-pack focus areas so the existing Daily Pack pipeline can start immediately.

## Analytics Events

- `onboarding_started`
- `onboarding_step_completed`
- `onboarding_completed`

Each event includes `version: 3`; step completion includes `step` and `stepId`.

## Deferred

- Push notification priming.
- Account gate.
- Paywall during onboarding.
- A true interactive demo inside onboarding.

Those are best added after TestFlight behavior is stable and after we decide exactly where the Pro trial should appear.
