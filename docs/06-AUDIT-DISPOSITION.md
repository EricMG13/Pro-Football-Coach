# 06 — Audit Disposition

What `docs/AUDIT.md`'s findings become in the rebuild.

**Findings are converted into tests, not into prose.** The audit's 78 confirmed findings carry no
IDs in the source document and most describe code that Tier C discards, so a 78-row table would be
ritual. What follows is the 25 P0/P1 findings, the five systemic patterns — which matter more — and
one paragraph retiring the tail.

Each finding is dispositioned as:

- **(i) Structurally impossible** — the new design has no place for it;
- **(ii) Addressed** — *naming the test that catches a regression*;
- **(iii) Retired** — with a reason.

> **Note on what this audit is.** A **UI-layer** audit of 17 files, ~5,500 lines, explicitly
> excluding the engine, iPad, size classes and App Store review — and it concluded the codebase was
> *"structurally sound and idiomatic"*. It is evidence about **craft**, not about why the game was
> boring. **9/20 is not the diagnosis of blandness**; that diagnosis is in `01-RESEARCH.md` §6.0.

---

## 1. The five systemic patterns

These matter more than the individual findings, because each one generated many of them. Every
pattern becomes a **standing invariant with a named test**.

### PAT-1 — *"The test's coverage boundary became the quality boundary."*

The sharpest line in the audit. `DesignSystemTests` verified five rating tiers and all 32 team tints
against real composited surfaces — genuinely rigorous work. **Every surface the suite did not look
at failed**: filled chips, tinted chips from raw system colours, gradient hero text, white-on-tint,
`.tertiary` as body text, `.yellow` trophies at 1.51:1.

> **Invariant PAT-1.** A test that asserts a property for *some* members of a category must cover
> **every** member, or **name its exclusions in a comment at the assertion site**. A quietly
> sampling test is worse than no test, because it converts an unknown into a false assurance.

**Test:** `contrastAllTokens` — enumerates every colour token × every surface it is drawn on × both
themes, and **fails when a pair is unasserted**, not merely when an asserted pair measures low. The
failure mode it guards is *absence*, which is why it must be written as a coverage assertion rather
than a value assertion.

Also encoded as a scoring rule: a dimension cannot score 4 in `04b-AUDIT-RUBRIC.md` on the strength
of a rigorous test with a narrow scope.

### PAT-2 — Token bypass at scale

43 literal spacings, 25 literal radii, 9–10 hard-coded font sizes and 3 off-scale radii — against
`DESIGN.md`'s own rule that *"a literal in a view is a defect"*.

> **Invariant PAT-2.** Design literals cannot exist in view code.

**Tests:** `noLiteralSpacing`, `noLiteralRadius`, `noSystemSizeLiterals` — source scans over
`Sources/ProFootballCoachUI/`. The rule was already written down and was broken 77 times, so the
enforcement has to be mechanical.

### PAT-3 — Written-down commitments with zero implementations

Reduce Motion: **0 occurrences**. VoiceOver: 3 accessibility modifiers in ~140 KB of view code, 0
`accessibilityElement` calls. Both stated as requirements in `PRODUCT.md` and `DESIGN.md`.

> **Invariant PAT-3.** Every line of the accessibility contract has a test. A commitment without a
> test is not a commitment — it is an aspiration, and it must be written down as one.

**Tests:** the full D12 set — `reduceMotionCoverage`, `voiceOverRowLabels`, `touchTargetFloor`,
`noFixedWidthAroundScalingText`, `contrastAllTokens`. `04-UX-AND-DESIGN-SYSTEM.md` §3 additionally
marks *Never Colour Alone* as a **review checklist item rather than an assertion**, because it is
not mechanically testable — which is exactly the honesty this pattern demands.

### PAT-4 — Persistence synchronous and over-eager

The main-actor save is P0 on its own, and opening a save parses the file twice then immediately
rewrites it.

> **Invariant PAT-4.** Persistence never blocks the main actor, and one user action produces at most
> one write.

**Tests:** `saveOffMainActor`, `oneWritePerAction` (`advanceWeek` produces exactly one write),
`openDoesNotWrite` (loading a save performs zero writes and one parse).

### PAT-5 — Dead code behind a statically false gate

`ArcadeGameView` was unreachable: its only gate, `arcade && !isFinished`, was statically false
because the single call site passed `arcade: false`. An entire view file, audited and maintained,
that no user could ever reach.

> **Invariant PAT-5.** Every feature has a reachable entry path, and it is asserted.

**Test:** `everyFeatureIsReachable` — each top-level feature entry point is constructed in a test
through its real gate condition. Unreachable code is a defect, not dead weight: it consumes review
attention, it accrues findings, and it makes the app look more finished than it is.

---

## 2. P0

| Finding | Disposition |
|---|---|
| **Every league mutation performs a 2.4–3.3 MB synchronous encode, backup copy, atomic write and directory rescan on the main actor** — 11 sites, 84–112 ms each, `advanceWeek` paying it twice for 160 ms, `completeDraftStage` up to 5 times | **(ii) Addressed.** `SaveQueue` background actor; `mutate` marks dirty rather than saving; coalescing; `store.list()` removed from the save path; `flush()` on background. **Tests:** `saveOffMainActor`, `oneWritePerAction`. Design in `03b` §3.2 |

---

## 3. The 24 P1s

### Structurally impossible in the new design (7)

Cutting direct control and declaring an orientation policy eliminates seven P1 findings outright —
worth stating, because it is the clearest evidence that these were design consequences rather than
coding mistakes.

| # | Finding | Why it cannot recur |
|---|---|---|
| 5 | The on-field aiming surface is a bare drag gesture with no accessibility element — VoiceOver finds nothing on the 300pt field, so an entire advertised mode collapses to one button | **No gesture-driven gameplay exists.** Every intervention in the Sideline Model is a real, labelled `Button` (`04` §3.1). This is a genuine accessibility dividend of D1 |
| 10 | Opening a save parses the file twice and then immediately re-encodes and rewrites it | Version is read by **prefix scan**, and loading performs zero writes. Belt-and-braces: `openDoesNotWrite` |
| 17 | Landscape is a declared supported orientation, but the arcade's fixed-height non-scrolling layout puts the play-call controls off-screen | **Portrait only, declared in `project.yml` in P0**; the arcade layout is gone |
| 18 | An irreversible "sim the rest of the game and commit it" action occupies the navigation bar's leading cancellation slot | The action and the screen are both gone. The general rule — *Cancel in the leading slot, never a destructive action* — is in `04` §6 |
| 21 | The app declares no orientation policy at all, so every portrait screen rotates into a broken landscape | Declared in P0 |
| 22 | On the Field — the one screen specced as landscape — loses all its controls when rotated | Screen cut |
| 23 | iPhone SE portrait: the field-goal and punt buttons fall off the bottom of the arcade screen | Screen cut. The generalisation — no fixed-height non-scrolling layouts — is an Adaptivity rubric item |

### Addressed, with the test that catches a regression (17)

| # | Finding | Test |
|---|---|---|
| 1 | Reduce Motion ignored everywhere — zero checks in the entire UI layer | `reduceMotionCoverage` — **every** `.animation` / `withAnimation` inside a motion-aware wrapper, zero exceptions |
| 2 | Fixed `.frame(width:)` around scaling text truncates the primary number on 19 rows | `noFixedWidthAroundScalingText`; `@ScaledMetric` is the sanctioned pattern |
| 3 | White chips on the team gradient measure 2.77–4.08:1 — below AA for **all 32 teams** | `contrastAllTokens` (hero register included) |
| 4 | "Kick Off the Season" CTA is white-on-white at 2.48–4.03:1 — no team clears AA | `contrastAllTokens`; opaque-scrim rule in `04` §2.4 |
| 6 | Stat and standings rows read as loose fragments — "312" … "Total yards" … "289" as three disconnected elements | `voiceOverRowLabels` |
| 7 | Chip-as-button filter and scouting controls ~21pt tall, 6pt apart | `touchTargetFloor` |
| 8 | Record Book aggregates every player's career and season stats inside the view body | `noAggregationInViewBody` source scan + the render budget |
| 9 | StatsView recomputes season stats for all 2,208 players, twice per render | Same. Aggregates are precomputed into a snapshot type |
| 11 | Power Rankings builds 32 unvirtualized rows and computes each team's overall three times | Same, plus the `List` rule for every collection that can grow |
| 12 | `Chip(filled:)` hard-codes `Color.white`; white-on-fill measures 1.41–4.13:1 at every call site | `contrastAllTokens` |
| 13 | Tinted `Chip` called with raw system colours — 1.41–3.44:1 in light mode | `noRawSystemColourAsText` source scan + semantic tokens only |
| 14 | Headline figures and status text painted in raw `.green`/`.red`/`.orange`/`.purple` on a card | Same. `.green` and `.orange` measured 2.2:1 and were already documented as rejected — the tokens existed and were bypassed |
| 15 | `TeamTheme.gradient` uses translucent stops that composite over the page — hero text drops to 3.31:1 | `contrastAllTokens` measures against the **composited** surface, per the Measured-Surface Rule |
| 16 | White labels on `accentColor` / `theme.tint` measure 2.65–2.90:1 in dark mode | `legibleOnDark` carried forward — good work that should survive — now under coverage-complete assertion |
| 19 | Four filter/action bars use a 21pt Chip as the entire tap target, 6pt apart | `touchTargetFloor` (the audit filed this separately from #7 at different sites) |
| 20 | Save and load failures are captured into `AppState.lastError` and never shown to the user | `everyPersistenceErrorHasAPresentationPath`. Silent save failure is the worst possible failure in a game whose competitive set is defined by save corruption |
| 24 | First-run tutorial clips its own body text at XXXL on a 667pt screen | Onboarding is redesigned (`02` §9); `noFixedWidthAroundScalingText` plus the owner's XXXL walkthrough |

### Retired (0)

None. Every P1 either cannot recur or has a test.

---

## 4. The P2/P3 tail — 53 findings, retired in one paragraph

The 36 P2 and 17 P3 findings describe specific call sites in `Sources/ProFootballCoachUI/` — literal
spacings and radii, hard-coded font sizes, a `●` text glyph, empty picker labels, `.tertiary` used as
body text, minor modality and title-display choices. **Tier C discards that code, so a per-finding
disposition would be a disposition of files that will not exist.** Their *causes* are what carries
forward, and every one of those causes is a systemic pattern in §1 with a source-scanning test:
PAT-2 catches the literals, PAT-3 catches the missing accessibility affordances, and the
`04b-AUDIT-RUBRIC.md` Platform Conformance rules catch the modality and title choices at milestone
boundaries. The tail is therefore retired as a list and preserved as five invariants — which is the
whole point of converting findings into tests rather than into prose.

---

## 5. The six refuted findings

`AUDIT.md` kept an appendix of six findings raised and then refuted by an adversarial verifier,
because *"what the audit got wrong is as useful as what it found."* That practice carries forward
into `04b` §4: every finding is re-opened at its cited line by a verifier instructed to refute it,
and the refutations are kept. An audit process that only records confirmations has no way to
discover that it is over-reporting.

---

## 6. What the audit found that was *right* — and must survive

The audit's positive findings are why 9/20 does not mean "this code is bad", and several describe
decisions worth deliberately reproducing:

- **Zero shadows anywhere.** The Flat-Forever Rule was genuinely honoured, not just documented.
- **No icon-only unlabelled buttons** — the single most common VoiceOver defect in SwiftUI, entirely
  absent.
- **Zero safe-area violations** — the most common iOS slop, clean.
- **100% SF Symbols**, no bundled image assets, no emoji, no mixed icon set.
- **Stock controls throughout**, so their VoiceOver traits, values and rotor support come free.
- **`monospacedDigit()` on ~25 changing figures** — a real low-vision aid.
- **`EmptyStateView` on every list that can be empty**, so a VoiceOver user never lands on silent
  blank space.
- **The save-list sidecar pattern** — decoding small `.meta.json` files rather than 2.4 MB saves.
- **`TeamBadge` initialised from abbreviation + hex**, never the whole `Team`, so a badge in a 32-row
  list does not retain a 69-player roster.
- **The field-to-yards projection lived in one function** shared by drawing and input, with a comment
  saying why — the genuinely hard part of device-independent touch mapping, done correctly.
- **`TeamTheme.legibleOnDark` measured against the composited control wash**, not an idealised
  background, with a comment recording why the first version was wrong.

Every one of these is a rule in `04-UX-AND-DESIGN-SYSTEM.md` rather than a hope.
