# TestFlight QA Script

Use this script for each TestFlight candidate build.

## Install And First Run

1. Install the app fresh.
2. Confirm the first screen is `Choose your focus`.
3. Select one to three focus areas.
4. Tap Continue.
5. Continue through AI level, obstacle, routine, and plan preview.
6. Tap `Start first pack`.
7. Confirm Today loads a pack.

## Paywall And Entitlements

1. Confirm Today shows the Sivra Pro prompt for free users.
2. Open the paywall.
3. Confirm monthly and annual packages appear when RevenueCat is configured.
4. Tap Continue free.
5. Confirm Today is still usable.
6. Tap Restore purchases on a subscribed sandbox account.
7. Confirm Pro entitlement unlocks AI pack generation.

## Daily Pack

1. Tap Start pack.
2. Step through screens 1-6 using Reveal and Next.
3. On screen 7, enter a written answer.
4. Tap Next.
5. Confirm screen 8 shows answer content and Finish.
6. Tap Finish.
7. Confirm Today shows Done.

## Learning And History

1. Open Learning Memory.
2. Confirm the written answer appears.
3. Open History.
4. Confirm the completed pack appears.
5. Open Review.
6. Open Practice and confirm the pack starts.
7. Open Weekly Recap and confirm counts are non-zero.

## Content Quality

1. Open Content QA.
2. Confirm generator and QA score are visible.
3. Open Source Admin.
4. Confirm source counts and hosts are visible.
5. Confirm fallback count is understandable.

## AI Fallback

1. Run a build without `SIVRA_AI_PACK_ENDPOINT`.
2. Complete focus selection.
3. Confirm free users still receive a curated pack.
4. Confirm Pro users fall back gracefully when AI generation is unavailable.
5. Confirm Source Admin shows fallback usage where expected.

## AI + Subscription Matrix

| User | RevenueCat | AI endpoint | Expected result |
| --- | --- | --- | --- |
| Free | Missing | Missing | Curated pack still works |
| Free | Configured | Configured | Curated free pack |
| Pro | Configured | Missing | Curated fallback pack |
| Pro | Configured | Configured | AI-generated pack if QA passes |

## Diagnostics

Internal QA builds may show Diagnostics. External TestFlight builds should be launched with:

```sh
--dart-define=SIVRA_DIAGNOSTICS=false
```
