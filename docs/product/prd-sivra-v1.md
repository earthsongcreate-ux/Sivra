# Product PRD (V1) — Sivra

**Tagline:** Daily AI fluency for founders and ambitious professionals.  
**Positioning:** An intellectual ritual (not productivity, not an “AI toy”).  
> “A calm room in a loud internet.”

---

# 1) Goals

- Make users feel calmer, clearer, and more prepared for real conversations:
  - meetings,
  - hiring,
  - fundraising,
  - strategy discussions.

- Create a daily 8-minute ritual that becomes identity-reinforcing:
  > “I’m someone who stays sharp.”

- Ship an AI-first wedge (AI domain only) that can later expand into elective tracks:
  - markets,
  - biotech,
  - additional domains.

- Monetize with a Free + Pro model without harming early retention.

---

# 2) Non-Goals (V1)

- No multi-domain catalog browsing.
  - No “courses”
  - No massive content library UI

- No social feed, comments, leaderboards, or public profiles.

- No heavy gamification:
  - no flashy badges,
  - no dopamine-heavy scores,
  - no childish streak mechanics.

- No “any topic” chatbot as the core product.
  - AI powers the ritual,
  - but Sivra is not a chat app.

---

# 3) Primary User

## Founders / Builders

Users who need:

- fast situational awareness of what changed in AI,
- correct mental models for strategic decisions,
- articulation under pressure:
  - boardroom,
  - customer,
  - investor conversations,
- a repeatable daily edge without doomscrolling.

---

# 4) Core Value Loop

## Brief
2 items:
- what changed,
- why it matters.

Each briefing includes:
- hidden source metadata,
- exposed only through a subtle “Source” chip.

---

## Drill
6 items focused on:
- recognition,
- reasoning,
- articulation.

---

## Review Queue
Spaced repetition system for:
- missed items,
- flagged concepts,
- weak areas.

---

## Weekly Artifact
“Boardroom Brief”:
- weekly summary,
- progress reflection,
- tasteful share card.

No public score flexing.

---

## Retention Loop
Streaks framed as:
> ritual, not grind.

---

# 5) Product Requirements

## 5.1 Daily Pack

### Duration
- ~8 minutes
- 8 total items

---

### Composition

#### 2× Briefings
News-style and founder-relevant.

Includes:
- Source chip
- Bottom sheet containing:
  - title,
  - publisher,
  - date,
  - link

---

#### 4× Concept / Decision Drills
Focus on:
- mental models,
- trade-offs,
- strategic thinking,
- “What would you do?” reasoning.

---

#### 1× Articulation Drill
User:
- types or records a response.

V1 recommendation:
- typed first.

---

#### 1× Review Item
Pulled from spaced repetition queue when available.

---

### UX Rules

- One question per screen.
- Minimal chrome.
- Calm typography and spacing.
- Progress always visible subtly.
- Avoid loud progress meters.

---

## 5.2 Personalization (Layered V1)

### Layer A — Topic Weights
User selects:
- 2–3 founder goals during onboarding.

Examples:
- Product
- GTM
- Hiring
- Infra / Costs

This adjusts content weighting.

---

### Layer B — Difficulty Adaptation
- Increase complexity when performance is strong.
- Reduce complexity when user struggles.

---

### Layer C — Spaced Repetition
- Missed items enter review queue.
- Each item receives next due date.

---

### Layer D — Briefing Relevance
Optional briefing bias toward:
- selected goals,
- preferred themes.

---

## 5.3 Weekly “Boardroom Brief”

### Purpose
Primary Pro-tier value moment.

---

### Includes

- 3–5 “What you now understand” highlights
- 2 “Use it in a meeting” scripts
- “Your next week focus” recommendation

---

### Share Artifact
Generates:
- calm,
- tasteful,
- socially safe share card.

Avoid:
- IQ framing,
- rank flexing,
- loud gamification.

---

## 5.4 Monetization (Free + Pro)

### Free (V1)

Recommended limits:
- 1 pack/day
- limited history
- limited review queue depth
- teaser version of weekly report

---

### Pro (V1)

Includes:
- full daily pack access
- unlimited review queue
- full weekly Boardroom Brief
- stronger personalization
- higher usage limits

---

### Billing Stack

- Apple / Google subscriptions
- RevenueCat for entitlement management
- RevenueCat webhooks → Firestore entitlements

---

# 6) Content Standards

- Founder-relevant
- Applied, not academic
- “Explain it like you’re in a meeting” tone

Every briefing must:
- store source metadata internally,
- expose source only through Source chip UI.

Tone:
- calm authority,
- clear thinking,
- no hype language.

---

# 7) Success Metrics (V1)

## Activation
- % completing first pack

---

## Retention
- Day-2 retention
- Day-7 retention

---

## Ritual Adherence
- packs completed per week

---

## Articulation Completion
- typed articulation completion rate

---

## Review Engagement
- review queue participation

---

## Monetization
- Free → Pro conversion after first “win” moment:
  - streak,
  - weekly brief,
  - visible sharpness progress.

---

# 8) V1 Tech Requirements (Implementation-Ready)

## Client
Flutter
- iOS-first
- cross-platform architecture

---

## Backend
- Firebase Auth
- Firestore
- Cloud Functions

---

## AI Routing
Provider-agnostic orchestration in Cloud Functions.

Includes:
- prompt templates,
- quotas,
- caching,
- safety checks.

---

## Billing
RevenueCat:
- subscriptions,
- entitlement sync,
- webhook → Firestore integration.

---

# 9) Risks & Mitigations

## Risk: Commoditization
> “It’s just trivia.”

### Mitigation
Emphasize:
- decision drills,
- articulation,
- applied thinking.

---

## Risk: AI Costs

### Mitigation
- cap AI calls per pack,
- cache briefings,
- pre-generate content packs.

---

## Risk: Trust / Hallucinations

### Mitigation
- store sources internally,
- expose via Source chip,
- avoid hallucinated certainty.

---

## Risk: Overwhelm

### Mitigation
- strict 8-minute limit,
- calm visual hierarchy,
- no infinite feed,
- no dashboard chaos.