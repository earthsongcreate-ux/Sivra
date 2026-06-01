# AI Pack Generation Endpoint

Sivra's Flutter app does not call OpenAI directly. Mobile binaries can be inspected, so the OpenAI API key should live on a backend endpoint.

Configure the app with:

```sh
flutter run \
  --dart-define=SIVRA_AI_PACK_ENDPOINT=https://your-api.example.com/sivra/daily-pack
```

The included Firebase Functions endpoint is `generateDailyPack`. After deploy, use that HTTPS URL as `SIVRA_AI_PACK_ENDPOINT`.

Server configuration:

```sh
firebase functions:secrets:set OPENAI_API_KEY
```

Set `OPENAI_MODEL` in the functions environment before deploy. The app sends
the signed-in Firebase user's ID token and the function verifies it before
generating a pack.

Keeping the model in configuration makes model upgrades explicit.

## Request

```json
{
  "uid": "firebase-user-id",
  "dayId": "2026-05-26",
  "focusAreas": ["Product strategy", "GTM & sales"],
  "schemaVersion": 1
}
```

## Response

Return either the pack object directly or `{ "pack": { ... } }`.

```json
{
  "pack": {
    "dayId": "2026-05-26",
    "focusAreas": ["Product strategy", "GTM & sales"],
    "generator": "openai_responses_v1",
    "items": [
      {
        "id": "b1",
        "type": "briefing",
        "prompt": "A sourced briefing prompt.",
        "answer": "Concise answer.",
        "explanation": "Why it matters.",
        "source": {
          "title": "Source title",
          "publisher": "Publisher",
          "dateLabel": "Today",
          "url": "https://example.com/source",
          "snippet": "Short source context."
        }
      }
    ]
  }
}
```

## Validation Rules

The app validates generated packs before saving:

- Exactly 8 items.
- Exactly 2 sourced briefings.
- Screen 7 is an `articulation` item.
- Screen 8 is a `review` item.
- Non-articulation items need an answer and explanation.
- Sources need title, publisher, date label, and a valid URL.

If validation fails or the endpoint is unavailable, the app saves the curated fallback pack instead.

## Content QA

Every generated pack can carry a `qaReport` with:

- `status`: `accepted`, `accepted_with_warnings`, or `fallback_used`.
- `score`: a compact 0-100 review signal.
- `issues`: blocking problems that caused fallback.
- `warnings`: non-blocking concerns such as unreviewed source hosts.

The app's Today screen includes a Content QA review view for inspecting generator status, issues, warnings, and source hosts.

## Backend Guidance

Use OpenAI Structured Outputs so the model returns the same JSON shape every time. Keep sources explicit and reject packs with vague or missing source URLs before returning them to the app.
