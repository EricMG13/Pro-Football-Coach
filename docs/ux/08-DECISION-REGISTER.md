# 08 — DECISION REGISTER

D-format. Anything expensive to reverse after implementation gets an entry.

---

```
D-001 | The fast-path interaction budget is left UNDEFINED rather than estimated
Status:      Accepted
Context:     Gate Zero §1.1 requires a per-week interaction budget derived from empirical mobile
             session data. Two research passes produced nothing admissible; every quantitative
             figure was refuted, and the primary benchmark source states it does not segment by
             genre or platform.
Options:     (a) Adopt a plausible industry figure. Precedent: none — the figures were refuted.
             (b) Derive from a comparable title's tap count. Precedent: Retro Bowl — but its tap
                 count was never sourced (02 §5).
             (c) Leave undefined, substitute a density budget derived from measurable evidence.
Ruling:      (c). Budget undefined; the 72-cell density budget (00 §4) constrains the same design
             question on Grade-A evidence.
Rationale:   Brief invariant 1 and §4 forbid asserting what was not observed. A fabricated constant
             would propagate into the density model and cost a rebuild cycle to detect. The density
             ratio answers "how much can one surface carry" directly, where the interaction budget
             would only have answered it by inference.
Consequences: Forecloses any per-week interaction cap in tests. Obligates TestFlight instrumentation
             as the first real source. Every "N interactions" figure downstream is Grade D and
             labelled.
Reversal cost: LOW. Adding a budget later tightens existing rules; it does not restructure them.
```

```
D-002 | Session-intent model replaces the two-persona brief
Status:      Accepted
Context:     The brief names two personas. Gate Zero §1.2 requires interrogating whether they are
             two users or one user in two modes.
Options:     (a) Keep two personas, fork the UI. Precedent: FM's SKU ladder (B) — but that is three
                 separate products, not two modes in one.
             (b) Simple/advanced toggle. Precedent: none observed in any benchmark.
             (c) Session-intent model, four intents, one app.
Ruling:      (c). Four intents: CRUISE, TRIAGE, DEEP, CEREMONY.
Rationale:   Grade D from Grade B premises. OOTP ships a per-area delegation matrix (11 areas,
             stable since 2017), a separate temporary layer, and threshold-configurable handback.
             A design serving two fixed types needs none of these. NO BEHAVIOURAL EVIDENCE EXISTS —
             no telemetry, no survey, no characterised community thread survived. This is the
             weakest load-bearing ruling in the dossier.
Consequences: Forecloses a simple/advanced toggle and any second app. Obligates transition cost as
             the primary metric, and obligates TestFlight instrumentation of delegated↔manual
             transitions per save.
Reversal cost: HIGH after build. Personas would require forking navigation and surface sets.
             Falsifier: if most saves show ZERO delegated↔manual transitions, this is wrong.
```

```
D-003 | The 62-screen registry survives; no new IA taxonomy is introduced
Status:      Accepted
Context:     The brief instructs applying and validating a READOUT/DESTINATION split "found in the
             repo". It does not exist — zero occurrences in the UI module.
Options:     (a) Invent the split and add it as a type.
             (b) Keep the registry, express readout/action as a surface attribute.
             (c) Restructure the IA around Madden's five destinations.
Ruling:      (b).
Rationale:   The registry derives family from screen in a switch, so coverage is by construction —
             exactly what CLAUDE.md demands. Its alias table already performs the consolidation
             Madden 27 arrived at (B). Seven families vs FM26's six top-level destinations is within
             one of the closest comparable (A). Adding a parallel taxonomy would create the doc/code
             disagreement CLAUDE.md treats as a defect.
Consequences: Obligates every canonical surface to declare READOUT / ACTION / MIXED. Forecloses a
             second classification system.
Reversal cost: MEDIUM. The attribute is additive; removing it is cheap. Restructuring families is not.
```

```
D-004 | Ceremony is ambient by default, capped at five dedicated surfaces per season
Status:      Accepted
Context:     Gate Zero §1.3. 21 match weeks; ceremony costing one dismissal per week is
             unaffordable at any plausible budget — a conclusion robust to D-001 being open.
Options:     (a) Skippable cutscenes. Precedent: Madden console, unmeasured.
             (b) Ambient + a bounded exception list.
             (c) Front-load into a season highlight digest. Precedent: none observed.
Ruling:      (b). Ambient default; ≤5 dedicated surfaces/season; zero dismissals on a routine week.
Rationale:   Grade A on three shipped zero-cost patterns: the persistent Madden news ticker (every
             generation 2012→); ceremony as a destination rather than an interruption (League News);
             and ceremony inside the match frame (FM23 Mobile goal lower-third, landscape, no
             dismissal).
Consequences: Obligates NewsTicker in chrome and CeremonyPlate in BROADCAST. Forecloses unskippable
             animation and any modal on a routine advance. A sixth surface is a register amendment.
Reversal cost: LOW to add ceremony; HIGH to remove it once players expect it.
```

```
D-005 | Delegation is a per-area matrix with named delegates, not a global toggle
Status:      Accepted
Context:     The fast path requires delegation; its shape determines the whole architecture.
Options:     (a) Global auto on/off. Precedent: OOTP's "Do Not Disturb" — but that sits ON TOP of
                 the matrix, not instead of it (B).
             (b) Per-area matrix with named delegates + temporary layer + threshold handback.
             (c) Per-decision only, no standing policy.
Ruling:      (b), with (a) as a layered escape.
Rationale:   Grade B, high confidence, verified across six OOTP product generations and corroborated
             on two hosts. Delegate competence is printed where the assignment is made, and the
             delegate is named (The Show scouting board, A) — that is how trust is bought.
Consequences: Obligates GAP-05 (XL) before any fast-path claim is true. Obligates that no area ever
             resolves to nobody. Forecloses a single automation switch as the primary surface.
Reversal cost: VERY HIGH. The policy object is persisted and migrated.
```

```
D-006 | DecisionCard shows the PRICE, never the predicted RESULT
Status:      Accepted
Context:     The brief's axis 4 asks whether consequences are previewed. This is arguably its single
             most design-relevant question.
Options:     (a) Preview the outcome ("this raises your rating by 3").
             (b) State the price only.
             (c) Show nothing.
Ruling:      (b). Madden's SUGGESTED TRADE OFFER names the asset given up (A). Price is observed;
             outcome preview is not.
Rationale:   Consequence preview was REFUTED 0-3 for Madden 26's weekly loadout AND 0-3 for
             Madden 27's delegation flow. There is no benchmark precedent for previewing an outcome
             in this genre. Specifying one would be designing from an unverified assumption, and it
             would additionally require the engine to predict its own output — a boundary problem.
Consequences: Forecloses outcome preview without new evidence and an engine capability. Obligates an
             explicit decline control (Madden's NOT INTERESTED, A).
Reversal cost: MEDIUM. Adding preview later is additive but needs engine prediction.
```

```
D-007 | The rating heat scale moves from three bands to five, and "average" becomes neutral
Status:      Proposed — REQUIRES AN AMENDMENT TO docs/04-UX-AND-DESIGN-SYSTEM.md §6.4 FIRST
Context:     CoachWorldTokens.Heat is three bands: red <70, amber 70-84, green ≥85. Under it, an
             average player reads as a caution.
Options:     (a) Keep three bands.
             (b) Five bands, average neutral. Precedent: The Show prints exactly five —
                 Well Below 0-64 / Below 65-74 / Average 75-79 / Above 80-84 / Well Above 85-99 (A).
Ruling:      (b), CONDITIONAL on amending 04 §6.4.
Rationale:   Grade A. Also enables BandLegend, which is the cheap answer to GAP-02 — fixed printed
             thresholds instead of a live percentile.
Consequences: Changes a shipped token's behaviour. Every surface using Heat re-reads.
Reversal cost: LOW mechanically, MEDIUM in review — pinned colour expectations may exist in tests.
NOTE:        CLAUDE.md's doc-first rule binds. 04 §6.4 owns the three-band scheme and must be amended
             before implementation. This document does NOT get to change it unilaterally.
```

```
D-008 | No delegation area may ever resolve to nobody
Status:      Accepted
Context:     OOTP's own documentation volunteers the failure: leaving an area on "Use Current
             Settings" while you personally own it means nobody covers it in your absence —
             "no changes will be made... other than the minimum required to keep the team running."
Options:     (a) Mirror the inheritance model, trap included.
             (b) Require every area to resolve to a named owner at all times.
Ruling:      (b). Enforced by an exhaustive switch plus a runtime assertion, not by UI validation.
Rationale:   The inheriting default is a hazard, not a safe default. A cruise mode that silently
             leaves an area uncovered produces a season the player cannot explain — the worst
             possible failure for a delegation-first design, because it destroys trust invisibly.
Consequences: Obligates a compile-time-exhaustive DelegationArea enum. Forecloses "unset" as a state.
Reversal cost: LOW. It is a constraint, not a structure.
```

```
D-009 | A user-facing density control ships, with no benchmark precedent
Status:      Proposed
Context:     The 5:1 density ratio means one column set cannot serve both a one-handed player and a
             player studying a roster.
Options:     (a) No control; one tier per surface.
             (b) Comfortable / Compact, defaulting to Comfortable.
Ruling:      (b).
Rationale:   HONEST NOTE: no benchmark precedent was observed for a user-facing density control. It
             is proposed from the arithmetic, not copied. It never overrides the rule that ACTION
             surfaces may not be DENSE, and never reduces a touch target below 44 pt.
Consequences: Obligates every DENSE-capable surface to render at both settings, and the density test
             to assert both.
Reversal cost: LOW.
```

```
D-010 | Landscape thumb-reach zones are unevidenced and controls are placed from the design references
Status:      Accepted (as an acknowledged gap)
Context:     Both research passes returned nothing on touch ergonomics, thumb zones or one-handed
             use. Question D, which existed to supply this, returned nothing.
Options:     (a) Import a desktop-derived heuristic.
             (b) Invent zones and present them as research-backed.
             (c) Place from the owner-approved v3 design references and flag the gap.
Ruling:      (c).
Rationale:   Brief invariant 8. (b) is the failure mode the evidence protocol exists to prevent.
Consequences: Any thumb-reach claim downstream is unsourced and must say so.
Reversal cost: LOW. Closed by one session of first-hand capture, or by TestFlight heatmaps.
```

```
D-011 | LeaderMark (position-and-direction) is the standard comparison encoding
Status:      Accepted
Context:     Every semantic colour needs a redundant non-colour cue (brief §5.6).
Options:     (a) Colour + text label on every comparison row.
             (b) An amber triangle on the leading side, pointing at it. Precedent: Madden Game Stats
                 and Team Stats (A).
Ruling:      (b).
Rationale:   Encodes by position and direction, so it survives greyscale and colour-blindness with
             no extra design. Discharges the comparison-row half of the accessibility obligation for
             free.
Consequences: Obligates a spoken "leading"/"trailing" for VoiceOver — a triangle that reads only
             visually defeats its own purpose.
Reversal cost: LOW.
```

```
D-012 | ScreenReadModels.swift is split per family
Status:      Proposed
Context:     2302 lines, largest file in the module, sitting on the engine/UI boundary. Violates
             CLAUDE.md's "files small and focused". Not a boundary violation.
Ruling:      Split per surface family.
Rationale:   Hygiene. Mechanical and low-risk.
Consequences: Touches many imports.
Reversal cost: LOW.
```

```
D-013 | Two proof views are deleted from the shipped module
Status:      Proposed
Context:     RedesignedJobBoardProofView (371 lines) and TeamLogoProofView (44) are proof artefacts
             compiled into the shipped UI target.
Ruling:      Delete both; move proof tooling to Tools/ if still needed.
Rationale:   Not product surfaces. The job board is already an alias to Career Hub.
Consequences: Any proof tooling referencing them must move.
Reversal cost: LOW — git.
```

```
D-014 | Engine/UI separation is strengthened, never relaxed, to serve any design in this dossier
Status:      Accepted
Context:     Brief invariant 2. The boundary is currently clean and test-enforced.
Ruling:      No design proposal may require FootballSimCore to know about presentation. Ceremony
             triggers (GAP-08) emit DOMAIN events; the UI decides what is ceremonial.
Rationale:   The boundary is the healthiest part of the codebase: zero SwiftUI imports in the engine,
             structurally enforced by Package.swift, scanned by ContractTests. GAP-08 is the one
             gap that could tempt a violation, by putting presentation knowledge in the engine.
Consequences: Ceremony trigger classification lives UI-side. The engine says "a championship was
             won", never "play the championship ceremony".
Reversal cost: VERY HIGH if breached. This is the invariant that keeps the UI redesignable at all.
```

---

## Open questions carried forward

| # | Question | Closed by |
|---|---|---|
| Q-1 | The actual per-session interaction budget | TestFlight instrumentation, or verified 2025 GameAnalytics genre segmentation |
| Q-2 | Do players oscillate within a save, and what triggers it? | TestFlight: delegated↔manual transitions per save, with trigger |
| Q-3 | Is Madden's coordinator-trust cost previewed, numeric, or undoable? | First-hand capture of Madden 26/27 |
| Q-4 | Retro Bowl's management-system inventory and tap count per week | 30 minutes with Retro Bowl |
| Q-5 | Does the bounded-delegation pattern hold on phone-native titles? | Capture of Motorsport Manager Mobile, Madden Mobile |
| Q-6 | Why did FM26's progressive disclosure fail — drill-down cost on routine repeated tasks, or disclosure itself? | Nothing published isolates the mechanism. Instrument click-cost per routine task in this product |
