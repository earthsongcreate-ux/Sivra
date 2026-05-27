# Release Environment

Sivra uses Dart defines for app-side environment configuration.

## Dart Defines

| Key | Purpose | Example |
| --- | --- | --- |
| `SIVRA_BUILD_CHANNEL` | Labels the build channel in Diagnostics. | `local`, `testflight`, `production` |
| `SIVRA_AI_PACK_ENDPOINT` | HTTPS endpoint for AI daily pack generation. | Firebase Function URL |
| `SIVRA_AI_PACK_TOKEN` | Optional bearer token sent to the AI endpoint. | Shared endpoint token |
| `SIVRA_DIAGNOSTICS` | Shows or hides Diagnostics entry point. | `true` or `false` |
| `SIVRA_REVENUECAT_IOS_KEY` | RevenueCat public iOS SDK key. | `appl_...` |
| `SIVRA_REVENUECAT_ANDROID_KEY` | RevenueCat public Android SDK key. | `goog_...` |
| `SIVRA_PRO_ENTITLEMENT` | RevenueCat entitlement checked by the app. | `sivra_pro` |
| `SIVRA_MONTHLY_PRODUCT_ID` | Monthly subscription product ID. | `sivra_monthly_1299` |
| `SIVRA_ANNUAL_PRODUCT_ID` | Annual subscription product ID. | `sivra_annual_9999` |

## Recommended Channels

Local:

```sh
--dart-define=SIVRA_BUILD_CHANNEL=local
--dart-define=SIVRA_DIAGNOSTICS=true
```

TestFlight:

```sh
--dart-define=SIVRA_BUILD_CHANNEL=testflight
--dart-define=SIVRA_REVENUECAT_IOS_KEY=appl_your_public_sdk_key
--dart-define=SIVRA_PRO_ENTITLEMENT=sivra_pro
--dart-define=SIVRA_MONTHLY_PRODUCT_ID=sivra_monthly_1299
--dart-define=SIVRA_ANNUAL_PRODUCT_ID=sivra_annual_9999
--dart-define=SIVRA_AI_PACK_ENDPOINT=https://your-function-url
--dart-define=SIVRA_DIAGNOSTICS=false
```

Production:

```sh
--dart-define=SIVRA_BUILD_CHANNEL=production
--dart-define=SIVRA_REVENUECAT_IOS_KEY=appl_your_public_sdk_key
--dart-define=SIVRA_PRO_ENTITLEMENT=sivra_pro
--dart-define=SIVRA_MONTHLY_PRODUCT_ID=sivra_monthly_1299
--dart-define=SIVRA_ANNUAL_PRODUCT_ID=sivra_annual_9999
--dart-define=SIVRA_AI_PACK_ENDPOINT=https://your-function-url
--dart-define=SIVRA_DIAGNOSTICS=false
```

## Firebase Functions Environment

The `generateDailyPack` function expects:

- `OPENAI_API_KEY`
- `OPENAI_MODEL`
- optional `SIVRA_AI_PACK_TOKEN`

Do not place the OpenAI API key in the Flutter app.
