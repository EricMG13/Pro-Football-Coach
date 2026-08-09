# 05 — Implementation Plan

Phased build. **One phase at a time**: find the first phase whose gates are not green, execute that
phase only, run the phase-end adversarial review, update `STATUS.md`, stop.

Before starting a phase, produce a bite-sized task plan for it under `docs/plans/`.

---

## The gates

Every phase closes on **all** of these. A phase with an ungreen gate is not done, however finished
the code looks.

| # | Gate | Mechanism |
|---|---|---|
| G1 | **Build green** | `swift build` |
| G2 | **Tests green** | `swift run -c release SimTests` exits zero, with real pass counts. Per D11 — see *When the toolchain is absent* below |
| G3 | **Audit ≥10/12, zero P0/P1** on touched surfaces | `04b-AUDIT-RUBRIC.md`, three local dimensions. The two global dimensions are deferred to milestones |
| G4 | **Engine phases only:** calibration bands met, cross-process determinism proven, the soak passing | `03-MATCH-ENGINE.md` §§5–6 |
| G5 | **The two Tier A legal tests pass** | `nameCollisionTest`, `tradeDressTest` — from P1 onward, every phase |
| G6 | **`STATUS.md` updated**, with anything uncompiled named as unverified | By hand, honestly |

**Milestone gates** additionally require **≥17/20 across all five dimensions**, including the global
Platform Conformance and Adaptivity.

### When the toolchain is absent

Frequently there is no `swift` in the container (D11). This does not stop the phase:

1. Write the code and its tests in the same commit.
2. Mark G1 and G2 **BLOCKED — no toolchain**, not green, and never "green by inspection".
3. Name every uncompiled file in `STATUS.md` under **unverified**.
4. Add the phase's surfaces to the owner's walkthrough script.
5. **An adversarial review is not a build.** It may find real defects; it may not stand in for G1.

---

## Phases

### P0 — Foundations

Package skeleton, `SeededRandom`, the determinism contract, the test harness, the source-scanning
tests, design tokens.

- Three targets per `03b` §1; both libraries build for macOS
- `SeededRandom` with hierarchical seed derivation from **identifier bytes**
- `TestKit` harness: suites, assertion counting, non-zero exit
- Source scans: `noUIImport`, `noHashValueSeeding`, `noSystemSizeLiterals`, `noLiteralSpacing`
- `DesignSystem.swift` tokens, with the coverage-complete contrast meta-test
- `project.yml`: iPhone only, **portrait only**

**Extra gate:** the cross-process determinism *fixture mechanism* exists and is proven on a trivial
case, before anything depends on it.

### P1 — Identity and generation

Name banks, the blocklist, archetypes, programme and team generation.

- 8 programme archetypes; 24 anchor programmes authored; ~110 generated
- 32 pro teams authored
- Geometric marks — shape + monogram from team colours. **No image assets**
- `Resources/Blocklist/` with real league, programme, conference, stadium and notable-player names

**Extra gate (G5 begins here and never stops):** `nameCollisionTest` over 200 seeds in both tiers;
`tradeDressTest` at ΔE2000 ≥ 10 on the pair.

### P2 — The snap

The heart of the engine. TDD throughout.

- Assignment set, leverage scoring, decision-point resolution, `PlayResult`
- `EngineTuning.swift` — every constant named, none inline
- `SimHarness.sample(count:seed:tier:)`
- **Pro calibration bands asserted** (`03` §5.2)

**Extra gate:** every pro band green; a band changed during this phase is changed *in a commit with
a reason*, never widened to make a red suite green.

### P3 — The game

Drives, clock, situation, AI play selection, the game plan, the box score.

- Clock model incl. the college first-down rule; tempo settings
- Game plan → play-selection distribution; coordinator quality drift
- Opponent adjustment, and **the report of what changed** that makes in-drive adjustment a decision
- Fourth-down / clock EV model
- `retainingPlaysDoesNotChangeResult`

**Extra gate:** the three D10 AI tests — `noRubberBanding`, `difficultyDoesNotTouchRatings`,
exploit-resistance soak. These are gates, not polish; that is what stops AI quality being the thing
cut when the schedule slips.

### P4 — The abstract model and the consistency gate

- Possession-level resolution; stat distribution by depth-chart share
- **The KS consistency gate** (`03` §3.2): 200 detailed vs 200 abstract seasons, α = 0.01, plus mean
  bands, blowout frequency and standings dispersion

**This gate blocks. It is not a warning.** If the two models disagree, the league's statistics and
the player's own game come from different universes.

### P5 — The pro season — ★ MILESTONE 1

Schedule, standings, tiebreakers, playoffs, offseason pipeline, cap, draft, free agency, trades.

- 17 games + bye in the legal window; all playoff formats resolve cleanly
- Cap with proration, guarantees, dead money, rookie scale
- **The three practice-squad rules** (`02` §6) — squad place requires squad money, dead money follows
  the contract not a flag, a call-up is paid for
- Ten-season soak, headless

**Milestone gate:** a full pro season simulates end to end, headlessly, inside the D4 budgets, with
every invariant holding. **≥17/20 across all five dimensions.**

### P6 — The week

The densest screen in the app, and the one the whole diagnosis points at.

- Situation header, the decision stack, the inbox, the play control
- **5–9 meaningful decisions**, every card skippable with a sensible default
- Fast paths: Full / Key moments / Instant / Delegate
- Delegation is competent and generic, and **loses to good opponents**

**Extra gate:** a decision-surface census, run the same way as `01-RESEARCH.md` §6.0b, asserting
**≥5 meaningful decisions** offered in a regular in-season week. The prior build measured 1–3. This
is the phase where the diagnosis is either fixed or is not.

### P7 — The match surface — ★ MILESTONE 2

- `FieldCanvas` with `TimelineView`; camera framing rather than a whole-field draw
- Choreography with the **last frame pinned to the recorded yardage**
- Decisive-matchup emphasis; structural furniture
- Fidelity and speed controls; the intervention slot
- **The full D12 treatment**: play-by-play as the accessible representation, live region, labelled
  interventions, Reduce Motion as a stepped match

**Extra gate — the one the arithmetic rests on:** a timing harness measuring **wall-clock per
simulated match at default fidelity**, asserting ≤ 7.5 min for a pro game. Plus the owner's
legibility check on device: *can you tell what happened at 1.2 s/snap?* If the honest answer is no,
**stop and take D1's fallback** (drive-summary granularity) rather than quietly letting the snap
duration grow — §3.5's sensitivity table is the map.

**Milestone gate:** a complete pro week is playable end to end on device. **≥17/20.**

### P8 — The college tier

- 85/105 rosters, eligibility clocks, redshirts
- Recruiting: interest bands, a weekly contact budget, a ~25-target board, **promises**
- The transfer portal, both directions, driven by broken promises and buried players
- NIL as a programme pool
- 12 games + championship + 12-team playoff
- **College calibration bands** (`03` §5.3), including the blowout-frequency band that tests A9

**Extra gate:** the D4 **college week-advance budget** — ≤800 ms including recruiting/portal AI for
134 programmes. This is assumption A5 and the phase where it is settled.

### P9 — The career — ★ MILESTONE 3

- Reputation; the coaching carousel in both tiers
- **The promotion arc**: triggers, coordinator vs head-coach offers, what carries, the two-way door
- Players you developed appearing in the pro league
- Job security bands, firing with warning
- Staff market, ambition, departures

**Extra gate:** the **20-season soak** including at least one promotion and one firing, with
`soakCarouselNeverDeadEnds` holding at every boundary.

**Milestone gate:** a career runs college → pro → fired → college, unattended, with every invariant
holding. **≥17/20.**

### P10 — Persistence

- `SaveQueue` background actor; **one write per user action**, asserted
- Version prefix scan; rolling backup and recovery; explicit refusal of newer formats
- Migration fixtures — a real prior-version save committed to the repo
- **Every bounded collection asserted** by `soakCollectionsBounded`

**Extra gate:** `soakSaveSizeBounded` at season 20 — ≤6 MB target, 10 MB ceiling — and a test
asserting `advanceWeek` produces exactly one write. That second test is the regression guard the
prior build lacked, which is why its save defect reached P0.

### P11 — Almanac and memory

Records, hall of fame, rivalry history, the career line. The systems that make season 8 better than
season 1 — and the ones most likely to grow without bound, so every one arrives with its cap.

### P12 — First run

The fifteen minutes in `02` §9. The first week *is* the tutorial. Settings: appearance, fidelity
defaults, accessibility, tutorial replay.

### P13 — Hardening — ★ MILESTONE 4

- Full accessibility sweep against the D12 contract, coverage-complete
- Performance pass against every D4 budget, each asserted
- Adversarial review over the whole app
- Full `/impeccable audit`-equivalent across all five dimensions
- **If `/impeccable` is available, run it and correct `04b` with its real anchors** ([ESCALATION-1])

**Milestone gate:** **≥17/20, zero P0/P1, app-wide** — not just on touched surfaces.

### P14 — Pre-deployment

Work `docs/PRE-DEPLOYMENT-CHECKLIST.md` to completion. Owner-verifiable items are handed over, not
claimed.

---

## Dependency shape

```
P0 ─ P1 ─ P2 ─ P3 ─ P4 ─ P5★ ─ P6 ─ P7★ ─ P8 ─ P9★ ─ P10 ─ P11 ─ P12 ─ P13★ ─ P14
                              │                  │
                              └── P10 may start ─┘  (persistence is independent of the college tier)
```

**Engine before UI** — the match view can only be designed once the simulation can say what it knows
and when. **P6 before P7** — the week is the diagnosis; if the match surface arrives first it will be
where the effort goes, and the empty Tuesday will survive the rebuild.

---

## Risk register

| Risk | Phase | Mitigation |
|---|---|---|
| **1.2 s/snap is not legible** — breaks the whole §3 arithmetic | P7 | Sensitivity table in `02` §3.5; D1's drive-summary fallback; the timing harness is a gate |
| **College week-advance blows the budget** — recruiting AI for 134 programmes | P8 | Tiered evaluation, amortisation, bounded pools; a benchmark gate |
| **Detailed and abstract models diverge** | P4 | The KS gate blocks the phase |
| **No toolchain, so nothing is verified** | Any | Honest labelling; walkthrough script; CI is the recommended permanent fix (D11) |
| **The week is dense but tedious** rather than dense and interesting | P6 | Decision-surface census is a gate; the owner's play protocol is the real instrument |
| **Content authoring overruns** (~76 h) | P1, P8 | 24 anchor programmes carry the load; the other 110 are allowed to be thinner |
| **Rebuilding loses what the prior engine knew** | P2–P5 | Bands, invariants and the three practice-squad rules carried forward as knowledge; logged in `OPEN-DECISIONS.md` |
