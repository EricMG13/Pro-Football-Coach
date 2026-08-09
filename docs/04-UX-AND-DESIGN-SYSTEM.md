# 04 — UX and Design System

One home for the design system and the screens. `DESIGN.md` is archived rather than maintained in
parallel — two documents describing one system is how they drift, and the prior repo had exactly
that drift.

> **Produced manually.** Claude Design via the briefs workflow was not available in the executing
> session; per the brief's §10 fallback this was authored by hand and is labelled as such. The token
> scale, the Flat-Forever rule and the Measured-Surface rule are carried forward from the archived
> `DESIGN.md`, which was good work — its problem was coverage, not judgement.

---

## 1. What the app should feel like

**A coach's clipboard, not a broadcast graphic.** Information dense enough to trust, calm enough to
read on a phone at 11pm. The excitement comes from what the numbers mean, not from the chrome.

Two registers, and the discipline is in keeping them apart:

- **Chassis** — native iOS restraint. Grouped backgrounds, cards, generous whitespace, hairline
  dividers, colour only where it carries meaning. This is the default for roster, cap, contracts,
  recruiting, settings, stats: the great majority of the app.
- **Hero** — broadcast. Deep team-colour bands, heavy tabular numerals, tight stat blocks, decisive
  win/loss states. This is the moment you flip the clipboard around. **Permitted on exactly six
  surfaces**: the season hub header, the match view, the post-game result, the team header, the
  trophy case, and the promotion moment. Nowhere else, ever.

---

## 2. Tokens

**A literal spacing, radius, colour or font size in a view is a defect.** The prior build broke this
rule 43 times for spacing, 25 for radii and 9–10 for font sizes, against its own written rule. A
source-scanning test now enforces it (§7.3).

### 2.1 Spacing

Four steps. `tight` 6 · `small` 10 · `medium` 16 · `large` 24. Cards pad at `medium`. List rows
target 52pt, comfortably above the 44pt touch minimum.

### 2.2 Shape

Two radii and a capsule. Cards use `20` with `.continuous` — Apple's superellipse, not a circular
arc; the difference is visible at that size. Chips and small controls use `10`. Anything pill-shaped
is a true capsule.

### 2.3 Elevation

**The Flat-Forever Rule: zero shadows in the entire app.** Depth comes from fill and hairline, never
from a drop shadow or hand-rolled blur. Floating bars use the system `.bar` material. The prior
build honoured this completely — `grep -rn "\.shadow("` returned nothing — and it should stay that
way.

### 2.4 Colour

Every colour is a **token with light and dark values**, and every token is measured against the
surface it is actually drawn on.

| Group | Contents |
|---|---|
| Chassis | `pageBackground`, `cardFill`, `separator` — resolved from system grouped backgrounds so they adapt for free |
| Rating ladder | Five tiers, each a light/dark hex pair |
| Team / programme | Primary + secondary per team, with a `legibleOnDark` lift |
| Semantic | `positive`, `negative`, `caution`, `info` — **never raw `.green` / `.red`**, which measure 2.2:1 on a card |

### 2.5 Typography

System font throughout, Dynamic Type always. **No `.system(size:)` literals** — the prior build had
ten, four of them below the 11pt floor.

`Display` (heavy, rounded largeTitle) for a lone dominant figure — a final score, an overall.
`Title` / `Headline` / `Body` / `Caption` as standard. **`monospacedDigit()` on every figure that
changes**: scores, clocks, cap hits, ratings, stat columns. This is a real low-vision aid, not
polish — digits that reflow between rows are much harder to scan.

---

## 3. The D12 accessibility contract

The prior build scored **1/4** on accessibility: Reduce Motion at zero occurrences, three
accessibility modifiers across ~140 KB of view code, contrast failing at 50+ sites — **all against
commitments it had written down for itself.** Writing them down again is not the fix. The fix is
that each commitment is a **test whose coverage is the whole category**.

| # | Commitment | Test | Coverage rule |
|---|---|---|---|
| A1 | **4.5:1 for all text**, measured against the actual composited surface | `contrastAllTokens` | **Enumerates every colour token × every surface it is drawn on × both themes.** Fails if any pair is unasserted — not merely if an asserted pair is too low |
| A2 | **Dynamic Type to XXXL** with no truncation or overlap | `noFixedWidthAroundScalingText` | Source scan: no `.frame(width:)` on a container holding scaling text. `@ScaledMetric` is the sanctioned pattern |
| A3 | **Reduce Motion honoured on every animation** | `reduceMotionCoverage` | Source scan: **every** `.animation(` and `withAnimation` is inside a motion-aware wrapper. Zero exceptions, because zero was the prior count |
| A4 | **44pt minimum touch targets** | `touchTargetFloor` | Source scan: every `Button` has an explicit `minHeight ≥ 44` or sits in a List row |
| A5 | **VoiceOver reads sentences, not fragments** | `voiceOverRowLabels` | Every row builder that composes >2 `Text` views has `.accessibilityElement(children: .ignore)` and a composed label |
| A6 | **No 11pt floor violations** | `noSystemSizeLiterals` | Source scan: `.system(size:` appears nowhere |
| A7 | **Never colour alone** | Review checklist | Not mechanically testable. **Stated as a checklist item, not pretended to be an assertion** |

### 3.1 The hard case — the match view

A `Canvas` animation is invisible to VoiceOver by construction, and it is the app's signature
surface. Both answers are required, not either/or.

**VoiceOver.** The Canvas is *not* the accessible representation. The **play-by-play text is**, and
it is written first — the animation illustrates a sentence that already exists (§6.5). Concretely:

- The match surface exposes a live region that announces each play as a sentence: *"Second and
  seven. Pass complete to the tight end for eleven yards. First down."*
- The situation — down, distance, clock, score — is one labelled element, updated as a value.
- Every intervention (timeout, fourth-down choice, adjustment) is a real, labelled `Button`, never a
  gesture. **This is the constraint the prior build's arcade mode failed**: its whole field was an
  unlabelled `DragGesture`, so an entire advertised mode collapsed to one button for a VoiceOver
  user. The Sideline Model has no gestures to lose, which is a genuine accessibility dividend of
  cutting direct control.
- The Canvas itself gets a summary label and is marked as decorative for traversal.

**Reduce Motion.** The match becomes **stepped rather than animated**: each play resolves to a
static field state with a cross-fade, at the player's chosen pace, with the play-by-play line
carrying the narrative. No sliding, no continuous motion, no camera movement. This must be a
genuinely playable way to experience a match, not a degraded one — it is close to what the
"key moments" fidelity setting already produces.

---

## 4. Screens

Five tabs. Tabs are **sections, never actions**.

| Tab | Owns |
|---|---|
| **Week** (relabels to Offseason) | The weekly loop — the densest screen in the app |
| **Team** | Roster, depth chart, development, player cards |
| **Programme / Front Office** | Recruiting & portal & NIL (college) · cap, contracts, draft, free agency, trades (pro) |
| **League** | Standings, schedule, rankings, stats, news |
| **Coach** | Career, staff, job security, goals, almanac, settings |

### 4.1 Week — the most important screen in the app

§6.0b measured the prior build's weekly hub at **one branching decision**. This screen exists to
carry 5–9 (§3.6 of `02`), and its design problem is presenting them without becoming a form.

Structure, top to bottom:

1. **Situation header** (hero register) — opponent, record, what is at stake in one line. *"Beat them
   and you're bowl eligible for the first time since 2019."*
2. **The decision stack** — one card per decision, each with a plain-language trade-off and a
   default already selected. **Every card is skippable**; a player who presses Play Game uses the
   defaults. This is what makes 9 decisions feel optional rather than mandatory.
3. **The inbox** — 1–3 items with real consequences. Recruiting contacts, a trade feeler, a staff
   problem, a player asking about his role.
4. **Play** — one primary button, with fidelity choice attached (Full / Key moments / Instant /
   Delegate).

**Anti-pattern, named because the prior build fell into it:** a weekly hub that is mostly a segmented
picker over three read-only lists. Standings, rankings and news are **League tab** content. The Week
tab is for things you *do*.

### 4.2 The match surface

The hardest surface in the app, and the one the whole §3.5 arithmetic rests on.

```
┌──────────────────────────────────────────┐
│  scoreboard: score · quarter · clock     │  hero
├──────────────────────────────────────────┤
│                                          │
│         2D field — Canvas                │  the play
│         LOS · line to gain · 22 dots     │
│                                          │
├──────────────────────────────────────────┤
│  play-by-play — the most recent line     │  the sentence
├──────────────────────────────────────────┤
│  [ intervention appears here when live ] │  agency
├──────────────────────────────────────────┤
│  speed · fidelity · timeout · plan       │  control bar
└──────────────────────────────────────────┘
```

Legibility rules, from §6.5:

- **Emphasise the decisive matchup.** The engine reports which one decided the play; those two or
  three dots are drawn at full strength and the rest are muted. 22 equal dots is noise.
- **Structural furniture first.** Line of scrimmage, line to gain, hash marks and down-and-distance
  do more for comprehension than motion fidelity, and cost nothing.
- **The field is framed, not fully drawn.** A faithful all-22 across 53⅓ yards on a ~390pt portrait
  screen is unreadable. The camera frames the action and pans; it does not show the whole field at
  once by default.
- **The last frame is the truth** — pinned to the recorded yardage (`03-MATCH-ENGINE.md` §1.2).
- **Interventions appear in a fixed slot**, always in the same place, never as a modal that
  interrupts. A modal on a 1.2 s cadence is unusable.

**The unknown, stated:** nobody has ever seen this rendered. The prior build's field view was written
and never compiled. Legibility at 1.2 s/snap is assumption **A3**, and the owner's play protocol
(§6.0a and the walkthrough script) is the instrument.

### 4.3 Everything else

| Screen | Register | Notes |
|---|---|---|
| Roster / depth chart | Chassis | `List`, swipe actions, `EditButton`, auto-sort. The prior build's depth chart was a genuinely well-built native list — keep it |
| Player card | Chassis + one Display figure | Attributes, development, contract/eligibility, history |
| Recruiting board | Chassis | ~25 targets, filter and sort, interest as a **band** not a number, promises visible |
| Cap sheet | Chassis | Dense table, monospaced digits, dead money always visible |
| Draft | Chassis, full-screen | Immersive and must-resolve → `fullScreenCover`, like the prior build |
| Standings / stats | Chassis | Every large collection in a `List`. No 2,208-player aggregation in a view body |
| Almanac | Chassis | Records, hall of fame, rivalry history, your career line |
| Promotion | **Hero** | The one moment the app is allowed to be theatrical |
| Settings | Chassis | Appearance, fidelity defaults, accessibility, tutorial replay. **The prior build had no settings surface at all**, so its own Light/Dark spec was unreachable |

---

## 5. Copy

Short, plain, specific. No lorem ipsum, no filler.

- **Refusals name the door that shut.** "You're $2.1M over the cap" — not "Unable to sign player".
  The prior build got this right and it is worth keeping as a rule.
- **Numbers get units and context.** "$2.1M over" beats "-2100000".
- **The assistant coach voice** in the inbox is plain and brief, and it stops appearing once the
  player stops needing it.

---

## 6. Platform conformance

The prior build's verdict was "pass, with real violations", and the violations were specific and
avoidable. All of them are rules here:

| Rule | Because |
|---|---|
| **Large titles only at top level** | Six of eight modals and every detail screen used them, flattening the hierarchy they exist to signal |
| **Cancel goes in the leading slot. Never "Done", never a destructive action** | Four sheets put "Done" there, and the arcade put an *irreversible* commit action there |
| **Every modal has a way out** | `JobOffersSheet` disabled interactive dismissal and shipped no dismiss control — a genuine trap |
| **Stock controls always** | `Toggle`, `Stepper`, `Slider`, `Picker`, `swipeActions`, `alert`, `sheet`. Reinventing these is the most common form of native slop, and it brings VoiceOver traits and rotor support free |
| **Every icon-bearing control uses `Label`** | The single most common VoiceOver defect in SwiftUI, and the prior build was clean on it. Stay clean |
| **`fullScreenCover` for immersive must-resolve surfaces; sheets for sub-tasks** | The prior build's split was correct and deliberate |
| **Every list that can be empty has an `EmptyStateView`** | So a VoiceOver user never lands on silent blank space |
| **Portrait only, iPhone only, declared in `project.yml`** | No orientation policy at all produced four P1 findings by itself |

---

## 7. How the design system is prevented from drifting

Three mechanisms, because documentation alone demonstrably did not work.

1. **One document.** This one. `DESIGN.md` is archived.
2. **Tokens are code.** `DesignSystem.swift` is the only place a colour, spacing or radius is
   defined, the same way `LeagueRules.swift` owns gameplay constants.
3. **Coverage-complete tests.** §3's rule: a test that asserts a property for *some* members of a
   category must cover **all** of them or name its exclusions at the assertion site. This is the
   direct answer to `AUDIT.md`'s sharpest line — *"the defect is not ignorance of contrast; it is
   that the test's coverage boundary became the quality boundary"* — and the meta-test that
   enumerates every token is what keeps it honest.
