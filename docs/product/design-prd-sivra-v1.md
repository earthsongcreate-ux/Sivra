# Design PRD — Sivra (V1)

---

# 1) Product Objective

Deliver an interface that makes users feel:
- calm,
- current,
- articulate,
- ready.

Turn “daily learning” into a premium ritual through restraint, editorial clarity, and earned progress signals.

---

# 2) Target User & Context

Busy professionals who feel the world accelerating and fear sounding behind.

Typical sessions:
- 6–10 minutes/day
- often morning or pre-meeting

Primary device:
- iPhone first
- later Android via Flutter

---

# 3) Design Principles (Non-Negotiables)

## Calm Over Clever
Remove cognitive noise before adding delight.

## Editorial Hierarchy
Typography and spacing do the heavy lifting.

## Earned Prestige
Bronze is reserved for:
- completion,
- streaks,
- membership,
- “lock-in” moments.

## Human Warmth
Ivory surfaces and sage feedback prevent “cold AI” vibes.

## Focused Flow
One primary action per screen.

---

# 4) Brand & Visual System

## 4.1 Color

### Base Colors

#### Deep Ink
`#0F172A`
- backgrounds
- navigation
- modal backdrops

#### Warm Ivory
`#F7F3EB`
- cards
- reading surfaces
- drill panels
- onboarding pages

---

### Accent Colors

#### Bronze
`#B08968`
- streak replacement
- “Pro” indicators
- key highlights
- progress moments

#### Soft Sage
`#A8B5A2`
- success states
- reflection states
- gentle confirmations

---

### Usage Rules

- Bronze maximum:
  - one hero element per screen
  - e.g., progress ring OR streak OR CTA

- Avoid saturated reds/greens.
- Semantic colors should remain muted and mature.

---

## 4.2 Typography

### Display / Ritual Headings
## Playfair Display

Use for:
- onboarding statements
- “Today’s Brief”
- weekly recap titles
- ritual banners

---

### UI / Body
## Inter

Use for:
- UI labels
- questions
- explanations
- navigation
- buttons

---

### Typographic Behavior

- Larger line-height than typical apps.
- Favor breathing room.
- Max 1–2 font weights on most screens.

Goal:
- calmness,
- readability,
- editorial rhythm.

---

## 4.3 Spacing & Layout

### Grid
- 8pt baseline grid

### Preferred Editorial Gaps
- 12
- 16
- 24
- 32

### Cards
- generous padding
- minimal borders
- subtle elevation only when needed

### Layout Philosophy
Avoid:
- dense dashboards
- multi-column clutter

Prefer:
- single-column reading rhythm

---

## 4.4 Iconography

- Simple
- Geometric
- Low-detail

Prefer:
- outline icons
- controlled stroke weight

Avoid:
- excessive AI sparkles
- decorative noise

If sparkles are used:
- reserve for one ritual moment
- e.g., daily pack reveal

---

# 5) Component Library (V1)

## Primary Button
- Ivory or Ink base depending on screen
- Bronze reserved for commitment actions

---

## Secondary Button
- Soft Sage outline
- Muted Ink outline
- Never visually loud

---

## Card (Ivory)
Structure:
1. Title
2. Short subtitle
3. Single action

Avoid:
- multi-widget clutter

---

## Progress Indicator
- Bronze ring or bar
- subtle animation only

Avoid:
- gamified meters
- aggressive progress visuals

---

## Streak Module
Minimal presentation:
- “7-day ritual”
- bronze ring/dot

Avoid:
- flames
- dopamine-heavy streak mechanics

---

## Chip (Source)
Small “Source” pill:
- briefing items only
- opens bottom sheet

---

## Bottom Sheet
Warm Ivory surface containing:
- source publisher
- date
- link
- single “Open link” action

---

## Paywall Module

Editorial-style layout.

Benefits presented as:
- calm bullets
- concise statements

Bronze reserved for:
- “Pro”
- commitment emphasis

---

# 6) Motion & Interaction Spec

## Page Transitions
- soft fade
- slight upward motion
- short distance

---

## Card Interactions
- subtle press state
- no exaggerated physics

---

## Completion Moment
- brief bronze highlight
- gentle confirmation text

---

## Haptics
Light and deliberate.

Use only for:
- completion
- important toggles

---

# 7) Core Screens (V1)

## 7.1 Onboarding (Identity + Calm Setup)

### Goal
User should feel:
> “This is my private study.”

within 30 seconds.

### Pages

1. Brand statement (Playfair)
2. “Your daily ritual” explanation (Inter)
3. Goal selection
   - “Sound current in meetings”
4. Domain focus
   - AI-first default
5. Notification permission
   - framed as “daily briefing appointment”

---

## 7.2 Home / Today

### Above the Fold
- “Today’s Brief”
- time estimate
- Start button

### Below
- minimal review queue
- previous session recap

---

## 7.3 Drill Flow

### Rules
- one question per screen

### Always Show
- subtle progress
- prompt
- response UI
- Reveal action

### After Reveal
- explanation
- optional Save
- optional Review Later

### Source Chip
Appears only on briefing items.

---

## 7.4 Weekly Report / Status Artifact

Should feel like:
> an editorial digest

Tone:
> “This week you became sharper at…”

### Structure
- 3–5 concise highlights
- calm and shareable

---

## 7.5 Share Card

### Visual Style
- Warm Ivory base
- Playfair headline
- subtle Bronze accent

### Example Copy
- “Sivra Ritual • 7 Days”
- “Walked into the room prepared.”

### Avoid
- IQ scores
- “genius level”
- flames
- loud emojis
- childish gamification

---

## 7.6 Settings / Profile

- Minimal
- Text-forward
- Restrained Bronze “Pro” badge

---

# 8) Accessibility & Quality Bars

## Accessibility
- Ink/Ivory contrast must meet accessibility targets.

## Dynamic Type
- iOS layouts must reflow without truncation.

## Tap Targets
- comfortable spacing
- especially during drills

## Reduced Motion
- simplified transition mode supported

---

# 9) Content & Tone Guidelines (UI Copy)

## Voice
- calm authority
- quietly affirming
- never hype

### Preferred Tone
- “You’re becoming sharper.”
- “Ready for the room.”

### Avoid
- “Grind”
- “Hustle”
- “Dominate”
- “100x”

---

# 10) Deliverables (Design)

## Design Tokens
- colors
- type scale
- spacing scale
- shadows
- radii

---

## Component Library
- buttons
- cards
- chips
- progress indicators
- bottom sheets
- paywall modules

---

## Screen Designs
- onboarding
- Today screen
- drill flow
- source sheet
- weekly report
- share card
- settings

---

## Motion Guidelines
- transition specs
- completion moment spec

---

# 11) Acceptance Criteria (V1)

- App feels calm and premium within first 10 seconds.
- “Today” screen has one clear primary action.
- No visual clutter.
- “Source” chip appears only on briefing items.
- Source chip opens clean bottom sheet.
- Bronze feels like earned prestige, not flash.
- Share cards feel socially safe and adult.
- No childish gamification.