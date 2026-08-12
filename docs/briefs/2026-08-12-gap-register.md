# Gap register — what does not exist, and what has to change

**Destination:** `docs/briefs/2026-08-12-gap-register.md`. **Working input, not canon.** The
register the brief names as this session's primary durable output alongside the density model.
§2 contains **proposed amendments to `docs/05-IMPLEMENTATION-PLAN.md`** (insertions only, nothing
renumbered); §4 is the consolidated owner-question list. Nothing in canon has been edited.

Grounding rule applied: every `Today` names a path in the tree as it exists right now (HEAD plus
working copy), or says `nothing`. `docs/STATUS.md` was treated as testimony and checked against the
tree; where they disagreed, the tree won and the disagreement is recorded in §3.

Entries are **ordered by what blocks the most**, not by stack position.

---

## 1. The register

| Field | G-01 |
|---|---|
| Requirement | Truthful UI data for every screen family; serves all four outcomes (the density model prices real data, not fixtures) |
| Today | UI is fixture-driven end to end: `Sources/ProFootballCoachUI/ScreenReadModels.swift` (`CoachWorldSampleData`, provenance enum `sample`), `RootView.swift` DEBUG-only proof root, RELEASE shows an unavailable-state view. Engine side, `Sources/FootballSimCore/Career/CareerSession.swift` already returns immutable fog-of-war projections and the source gate keeps `GameState` out of the UI target (`Tests/SimTests/Suites/ContractTests.swift`) |
| Delta | Per-family read-model providers mapping `CareerSession` projections into the `CoachWorld*` read models; provenance flips `sample` → `simulationSnapshot` per family as it lands |
| Owner doc | `03b` |
| Phase | `05` P12/P14; gated behind the M8 production-UI entry gate named in `docs/HANDOFF-CLAUDE.md` |
| Cost | View/adapter work, no save growth; test surface: one contract per family asserting the provider consumes projections, never `GameState` |
| Blocks | Every truthful surface; consumption of G-02…G-06; the proof-to-production transition in `04` §10 |

| Field | G-02 |
|---|---|
| Requirement | Engine-owned verdicts: distributional baselines, expectation deltas, outlier naming, sample and confidence — density model T1 (Outcome 1); `04` §4.2's "lead analytical readouts with staff interpretation" |
| Today | `Sources/FootballSimCore/Competition/Statistics.swift` computes team/player statistics; `Sources/FootballSimCore/History/WorldHistoryReadModel.swift` indexes but judges nothing; no percentile/baseline machinery exists anywhere in `Sources/FootballSimCore/` |
| Delta | Deterministic league-week aggregates per metric; verdict derivation carrying sample size and confidence; staff-voice attribution from `Sources/FootballSimCore/Model/Staff.swift` identities. A verdict the engine cannot back is not rendered (fabrication rule) |
| Owner doc | `03` for the computation contract; `02` for which judgements exist and who voices them |
| Phase | **Needs a phase**: proposed insertion P10b (§2); fits the active M7 living-world slice in `docs/STATUS.md` terms |
| Cost | Build medium. Runtime: aggregates bounded at current season + 1 prior, ≈ 166 organisations × ~20 metrics × ~21 weeks × 2 seasons ≈ **≤ 1.5 MB** uncompressed, discarded beyond the bound. Test surface: determinism of verdict text, reachability of every verdict class |
| Blocks | T1 everywhere: analytics-class readouts, cap/NIL warnings with judgement, hub tiles (finding F10), the verdict slot on every READOUT card in the reference library |

| Field | G-03 |
|---|---|
| Requirement | Per-attribute recent-change record — density model T3, finding F2 ("what changed" answered in place on the dossier) |
| Today | `Sources/FootballSimCore/People/DevelopmentSystem.swift` produces twice-seasonal causal one-point changes with typed events; hot event ledger evicts at 4,096 (`docs/STATUS.md` M3), so changes are not durably queryable per player |
| Delta | Bounded per-player recent-change ring (attribute, direction, cause, season-week), written at development time. **Bound: last 6 changes per active player**, discarded on departure |
| Owner doc | `03b` (projection and persistence), `02` §5 (what counts as a change worth marking — a rules constant, not a per-screen judgement) |
| Phase | Proposed insertion P10b; M-terms: beside M2 systems |
| Cost | ≈ 15.6k active people × 6 entries × ~6 bytes ≈ **≤ 0.6 MB**. Test: bound enforcement under the soak's growth check |
| Blocks | `DeltaMark` cards; Player Profile and Development Plan truthfulness |

| Field | G-04 |
|---|---|
| Requirement | Bounded per-player form series — density model T3, `FormLine` |
| Today | Per-game player statistics and participant manifests exist (`Sources/FootballSimCore/Competition/Statistics.swift`; M3 manifests per `docs/STATUS.md`); `Sources/ProFootballCoachUI/PersonnelReadModels.swift` `FormEntry` is fixture-fed; **no engine definition of a per-game player rating exists** |
| Delta | A `03`-owned player-game rating definition (deterministic, position-aware), then a last-5-games projection derived from retained results — derived, not stored, if retention suffices; else a bounded ring |
| Owner doc | `03` (the rating definition is simulation truth, not UI arithmetic), `03b` (projection) |
| Phase | Proposed insertion P10b |
| Cost | 0 if derived at load; else 15.6k × 5 × 4 B ≈ **≤ 0.3 MB**. Test: rating determinism; agreement between form entries and box scores |
| Blocks | `FormLine` cards; Player Profile form region; recent-form story surfaces |

| Field | G-05 |
|---|---|
| Requirement | Opponent-preparation knowledge boundary with graded confidence — density model T2 beyond recruiting/draft; Opponent Report family |
| Today | Prospect/portal/draft fog exists (`Sources/FootballSimCore/College/ScoutingState.swift`, `Sources/FootballSimCore/Pro/ProMarketState.swift`); `Sources/FootballSimCore/Tactical/TacticalState.swift` carries opponent snapshots (schema 8), but `docs/FUTURE-SIMULATION-CONTRACT.md` FSC-007 names opponent knowledge as the open remainder |
| Delta | Observer-scoped opponent observations feeding banded tendencies/personnel confidence, same permitted-knowledge pattern as M3/M6 |
| Owner doc | `03`; `02` §2.1 beat 2 |
| Phase | M4 completion; `05` P10's opponent-AI neighbourhood |
| Cost | Bounded per-opponent-per-season observation set (propose: ≤ 12 observations per opponent, current season only, ≈ **≤ 0.2 MB**). Test: fog cannot be widened by re-reading (the M3 no-resampling pattern) |
| Blocks | Opponent Report / Film Room truthful density; `ConfidenceTag` on opponent surfaces |

| Field | G-06 |
|---|---|
| Requirement | Match animation anchor stream — `04` §9 (routes only when recorded; all 22 represented; render cannot change outcome); FSC-011 |
| Today | `Sources/FootballSimCore/Engine/SnapOutcome.swift` records deciding matchups; no anchor stream (`docs/FUTURE-SIMULATION-CONTRACT.md` FSC-011); `Sources/ProFootballCoachUI/MatchDayView.swift` renders one recorded fixture frame |
| Delta | An anchor contract in `03`: per-snap sparse anchors (lines, ball path, end spot, template marks for the deciding matchup), a deterministic pure function of the recorded outcome, byte-identical across renders, never contradicting the box score (`01` §6.5 §8's two constraints) |
| Owner doc | `03` |
| Phase | `05` P13; FSC-011's "match-presentation milestone after anchor contract" |
| Cost | Save: **current game only** (D7's play-by-play bound) — no cross-season growth. Runtime: within D4's 16.7 ms frame ceiling. Test: the render-cannot-change-outcome assertion P13 already names |
| Blocks | P13 Match Day; live broadcast cards in the reference library |

| Field | G-07 |
|---|---|
| Requirement | Token write-back: canon must hold every token value before any sheet or production view claims it (Outcome 4 precondition P-b) |
| Today | `Sources/ProFootballCoachUI/DesignTokens.swift` carries ~40 colour values, 6 spacing steps, 4 radii, 7 type roles; `docs/04-UX-AND-DESIGN-SYSTEM.md` §6.1 names roles only, no values, no measured ratios |
| Delta | Value tables with measured contrast ratios (both appearances, composited pairs) written into `04` §6.1/§6.2; then a `ContractTests` sync check so code and canon cannot drift |
| Owner doc | `04` |
| Phase | P11 / M8 entry condition |
| Cost | Doc work plus ratio computation; test: token-sync contract. No runtime cost |
| Blocks | Every `*-v3.dc.html` sheet; the P11 token gate; contrast-by-construction testing |

| Field | G-08 |
|---|---|
| Requirement | A canonical density budget and per-family budget statements (Outcome 1's durable home) |
| Today | `nothing` — proposal drafted in `docs/briefs/2026-08-12-density-model.md` §7 |
| Delta | `04` §4.5 adopted (or amended); each `04` §8 family carries its budget statement; a by-construction contract test walks `Sources/ProFootballCoachUI/ScreenRegistry.swift` (all 62 families enumerated there today) and asserts the glyph vocabulary stays within cap |
| Owner doc | `04`, audited under `04b` |
| Phase | P11 insertion (§2) |
| Cost | Canon + test work; makes the caps falsifiable. No runtime cost |
| Blocks | Budget-costed cards (card contract §4.9); `04b` scoring of density claims |

| Field | G-09 |
|---|---|
| Requirement | Device window reconciliation and its asserting tests (Outcome 3; D15) |
| Today | `04` §7 declares 844 × 390 through 932 × 430; the tree's proofs render at 956 × 440 (`docs/proofs/README.md`, `docs/proofs/personnel/`); `App/project.yml` declares landscape-only, but the `OrientationPolicyTest` that `CLAUDE.md` says asserts it **does not exist** — no orientation or device-layout test exists under `Tests/` |
| Delta | Owner decides D15; `04` §7 window rewritten from verified sizes (sourcing rows Q4–Q5); `OrientationPolicyTest` actually written (reads `App/project.yml`); two-tier `SmallestDeviceLayoutTest` (install floor 844 × 390 no-clipping; promise floor full budget) |
| Owner doc | `04` §7; `docs/OPEN-DECISIONS.md` D15 (proposed in `2026-08-12-device-floor-evaluation.md` §6) |
| Phase | P11/P13 test work; the decision itself is an owner action, not a phase |
| Cost | Test surface: two rendered tiers × registry families. No runtime cost |
| Blocks | Card widths (contract §4.2); honest proof matrix; closing the proofs-outside-window discrepancy |

| Field | G-10 |
|---|---|
| Requirement | Throughput primitives — search within data at world scale (density model §6; `ListControls`) |
| Today | Sorting only: `RosterSortDescriptor` in `Sources/ProFootballCoachUI/PersonnelReadModels.swift` over an 8-player fixture. Engine search exists and is bounded (`Sources/FootballSimCore/History/WorldHistoryReadModel.swift`, tokenised, never exposes `GameState`) |
| Delta | Filter/search/multi-select primitives in the UI; read-model queries at scale (134 rosters; portal pool bounded 300 and free-agent pool 400 per D7) |
| Owner doc | `04` (component), `03b` (query surface) |
| Phase | P12 first consumer, P14 across families |
| Cost | View work; test: sort/filter determinism over simulation truth, not display strings |
| Blocks | Market, board and standings families reaching their N; half of density property D5 |

| Field | G-11 |
|---|---|
| Requirement | Detailed-match per-player stat lines (evidence layer for played-match verdicts; box score; calibration coverage) |
| Today | The abstract model produces per-player lines (`Sources/FootballSimCore/Abstracted/AbstractGameSimulator.swift` + `Competition/Statistics.swift`); the detailed engine does not (`docs/STATUS.md` P4: sixteen §6.5 band rows unmeasured, target shares waiting on exactly this) |
| Delta | Per-player attribution inside `Engine/` snap resolution (who was targeted, who blocked, who tackled), aggregated to lines |
| Owner doc | `03` |
| Phase | The P4-widening work `docs/STATUS.md` already prescribes ("widen the model, not the grid"); M-terms: detailed-match integration |
| Cost | Engine medium; save: current game + existing season aggregates, no new growth. Test: line-vs-play-by-play consistency; unlocks calibration rows |
| Blocks | Game Detail / Box Score for played games; played-match verdicts (T1); P4 band coverage |

| Field | G-12 |
|---|---|
| Requirement | AX5 reflow contract test enumerating dense screens by construction (D12; `04` §7; density budget's AX5 column) |
| Today | Source-level spot checks only (working-copy `Tests/SimTests/Suites/ContractTests.swift` asserts one `lineLimit` accessibility guard by string match); no rendered AX5 test; no `DynamicTypeContractTest` |
| Delta | A test that walks `ScreenRegistry.swift` and asserts, per family as it lands: AX5 renders lose no datum, order preserved, no clipping. Mechanism (snapshot vs layout assertion) is `03b` §5's to decide |
| Owner doc | `03b` test architecture; `04` §7 is the contract it enforces |
| Phase | P11 |
| Cost | Test infrastructure; the coverage-boundary rule in `CLAUDE.md` demands the enumeration come from the registry, not a hand list |
| Blocks | AX5 statements on cards (contract §4.2); `04b` accessibility scoring at G3 |

| Field | G-13 |
|---|---|
| Requirement | The failure set — empty, error, interrupted, resume states inside their owning compositions (`04` §7 last clause; registry entry 23) |
| Today | `nothing` beyond the RELEASE unavailable-state in `Sources/ProFootballCoachUI/RootView.swift`; every prior design pass records the set as undrawn (`docs/STATUS.md`) |
| Delta | State designs per composition class plus the `failure-v3.dc.html` sheet; view implementations as families land |
| Owner doc | `04` |
| Phase | P11 (designs) then per-family |
| Cost | Design + view work; test: states reachable, not just drawn |
| Blocks | Card contract §4.4 (states, not one happy instance); honest `04b` resilience scores |

**Running save-size estimate** (brief rule: across both tiers and every programme). Baseline
measured: 22.1 MB season 1 → 84.7 MB season 20 uncompressed (M2, `docs/STATUS.md`), 28.4 MB current
calibration save; FSC-003 (compression/chunking, 8 MB product ceiling) is open and owns the problem.
This register adds, at stated bounds: G-02 ≤ 1.5 MB, G-03 ≤ 0.6 MB, G-04 ≤ 0.3 MB, G-05 ≤ 0.2 MB,
G-06 zero (current game only), others zero — **≤ 2.6 MB uncompressed total, ~3 % of the existing
save problem**. The density model does not meaningfully move the save-size risk; FSC-003 dominates
it, and every bound above is written to be enforced by the existing soak growth check.

## 2. Proposed `docs/05-IMPLEMENTATION-PLAN.md` amendments (insertions; nothing renumbered)

1. **Insert "P10b — Analytics and evidence authority" between P10 and P11.** Scope: G-02 baselines
   and verdicts, G-03 change record, G-04 form series and the player-game rating definition, G-05
   opponent knowledge completion, G-11 detailed-match stat lines. Gates: G1, G2, G4, G6, plus a
   verdict-reachability test (every verdict class producible) and the soak growth check over the new
   bounds. Displaces nothing: it is pure insertion; it may run alongside P10 but must complete
   before P14's readout families. In the milestone vocabulary `docs/STATUS.md` actually builds by,
   this is an M7 slice plus the M4 remainder.
2. **Amend P11's entry conditions** to name G-07 (token write-back), G-08 (density budget + registry
   adoption), G-09's test half (`OrientationPolicyTest`, two-tier `SmallestDeviceLayoutTest`), G-12
   (AX5 instrument) and G-13 (failure-set designs). P11's existing scope is unchanged; these are
   preconditions it currently assumes silently.
3. **Amend P13** to state its dependency on G-06's anchor contract explicitly (FSC-011 already
   implies it; the plan should say it).
4. **Amend P14's gate** to include the per-family density-budget statement check from G-08.
5. **Record the numbering seam:** `05`'s header defers to a "Master Build Documentation"
   (`06-BUILD-ROADMAP-AND-GATES.md`) that is **not a path in this repository**; under
   `docs/DOC-MANIFEST.md`'s own rule a document outside the canon paths carries no authority. This
   register is phrased in both vocabularies, but the seam is an escalation (§4 Q6), not something
   these amendments can repair.

## 3. Tree-versus-document discrepancies found while grounding (report, not fix)

1. The brief describes `Sources/ProFootballCoachUI/` as one placeholder file and P5–P17 as not
   started; the tree holds 13 UI files, five proof captures, and M0–M7 milestone records. The brief
   predates the tree it commissions work on; the tree won throughout this session.
2. The brief's structural references into `04` (§2 tokens, §3 registry, §4 budget with
   DESTINATION/READOUT, §5.2 arithmetic, five-destination ceiling, two-pane 38/62 chassis) resolve
   only to the pre-2026-08-11 `04` (`git show a60f4d9:…`). Current `04` replaced all of them; by the
   brief's own priority rule the brief is the defect. The mapping used here: tokens → §6.1/§6.2,
   registry → absent (G-07/§3 of the library plan), budget → §4 rules + 62-family inventory,
   device arithmetic → §7 (window) with the superseded §5.2 as recoverable history.
3. `CLAUDE.md` says landscape-only is "asserted by `OrientationPolicyTest`"; no such test exists
   under `Tests/` (declaration exists in `App/project.yml`). G-09 carries the repair.
4. `04` §7's device window excludes the 956 × 440 viewport the tree's own proofs use (G-09).
5. `04` §1.1 and `docs/proofs/README.md` attribute the reference corpus to Football Manager Touch;
   the corpus contains no capture of that SKU (findings file §2).
6. `01-RESEARCH.md` §6.6 §4.4 still says "portrait only", and §4.3's anti-lesson is phrased against
   the removed five-tab bar; both stale in place (findings file §5.3).
7. Uncommitted working-copy changes materially improve the legal posture (a shipped-copy blocklist
   sweep over all `Sources/` string literals, plus three fixture hometowns moved off real-city
   collisions — `Tests/SimTests/Suites/LegalTests.swift`, `PersonnelReadModels.swift`). Unverified
   by this session (nothing was run); noted so it is not lost uncommitted.

## 4. Return as questions — the consolidated owner list

1. **D15 reading.** Does "iPhone 15 Pro and newer" exclude the currently-sold `e` class (class
   reading) or include it (date reading)? The layout floor only moves under the class reading, and
   dropping currently-sold devices from the promise is a market decision. Also: 8-render or
   12-render proof matrix once sizes are verified?
2. **SKU naming.** Is Football Manager Touch actually the intended density target, given the corpus
   contains zero FM Touch captures? Approve the proposed `04` §1.1 rewording (findings file §2), or
   supply FM Touch captures to ground the name?
3. **Density budget adoption.** Accept, amend or reject the proposed `04` §4.5 (density-model file
   §7) — specifically the three-glyphs-per-row and twelve-symbol vocabulary caps, which are design
   law only if the owner sets them.
4. **Registry reconstitution.** Accept the proposed `04` §6.5 registry (library plan §3), including
   the five renames/merges relative to the deleted a60f4d9 registry, which are stated rather than
   inherited?
5. **Sourcing gate one.** Approve or strike each query Q1–Q10 in
   `docs/briefs/2026-08-12-sourcing-log.md` as written; Q9 and Q10 are flagged competitor-product
   queries that the plan deliberately does not argue for.
6. **Canon seam.** Where does the Master Build Documentation (M0–M9 roadmap) canonically live? `05`
   defers to it; it is not a repo path; `docs/DOC-MANIFEST.md`'s rule strips authority from
   documents outside the canon list. This is a manifest-level defect only the owner can place.
7. **Light-primary team colours.** The P2 finding stands: the sampled generator output was
   uniformly dark-primary, so the light-primary contrast floors have never met their case. For the
   card contract's three-pair rule: change the generator's reachable space, or accept a labelled
   synthetic pair until it changes?
8. **§6.6 corrections.** Approve the proposed provenance corrections (mobile SKU year uncertainty;
   mock-grade citations; two stale clauses marked superseded in place) — edits to a RETAINED
   document, so owner-gated.
9. **Verdict voice.** When G-02 lands, verdicts are attributed to staff by name (`02` §7's named
   stakeholders instinct) or to an unnamed analytics function? Changes `02`, the events, and the
   copy register; a test cannot settle a voice.
10. **What the brief itself got wrong** — recorded for the brief's author: the stale tree
    description, the stale `04` references, the five-destination ceiling and two-pane chassis listed
    as open questions when the 2026-08-11 correction had already removed both from canon, and a
    sheet mandate keyed to a registry canon no longer holds (§3 items 1–2 here; no action needed
    beyond awareness — this session executed against current canon per the brief's own precedence
    rule).

## 5. Owner dispositions, 2026-08-12

All ten questions above were put to the owner and disposed the same day:

1. **D15: decided, option (b)** — class reading; `e` class leaves the promise; floor 852 × 393,
   ceiling 956 × 440 pending size verification. Written into `docs/OPEN-DECISIONS.md` D15 with its
   falsifiers; the `04` §7 window rewrite stays gated on sourcing rows Q4–Q5 passing gate two.
2. **Sourcing: Q1–Q8 approved as written; Q9 not run** (owner will answer by opening the app);
   **Q10 mooted** by owner testimony — the target is defined by the experience (desktop-level
   functionality on iPhone), not the brand. Gate two remains per-row after retrieval.
3. **`04` §4.5 density budget: adopted** as proposed, including the three-glyph and twelve-symbol
   caps.
4. **`04` §6.5 registry: adopted** with the five stated renames/merges.
5. **`04` §1.1 SKU rewording: adopted**; owner intent recorded as testimony in `04` §1.1 and the
   `05` amendment appendix.
6. **`01` §6.6 corrections: all five accepted** (mobile SKU year; two mock-grade citations;
   §4.3/§4.4 superseded-in-place marks; §1.1 handled under item 5; proofs README / personnel plan
   downgrade deferred to "when next touched" — they are live-session working files).
7. **Master Build Documentation located**: `~/Documents/Pro-Football-Coach-Master-Build-Documentation/`,
   eleven documents (00 through 09 plus README). Canonical placement remains an open owner action;
   the manifest seam stands until they are placed. **Resolved 2026-08-12: owner approved import** —
   the pack now lives at `docs/roadmap/` with manifest rows; the `05` header pointer resolves.
8. **Light-primary team colours: labelled synthetic pair** for the card contract until the
   generator's reachable space changes; the generator gap is raised against P2.
9. **Verdict voice: named staff.** G-02's staff-voice attribution is a requirement, not an option;
   lands in `02` when G-02 is implemented.
10. **Deliverables committed** as docs-only commits, separate from the live session's work.

## 6. Post-sheet additions, 2026-08-12

Two gaps surfaced while drawing the approved reference sheets; same eight-field shape.

| Field | G-14 |
|---|---|
| Requirement | Engine-owned load policy: condition-band cut points, dose multipliers and the plan's derived cost (intensity, staff workload) — week-v3 sheet card 3; Practice Plan family |
| Today | Condition is engine-owned (M2, `Sources/FootballSimCore/People/`); no policy object, no multiplier constants, no derived-cost computation anywhere in `Sources/FootballSimCore/` |
| Delta | A rules-module policy (5 bands, multipliers as constants per tier), deterministic derived-cost computation, per-team standing rule persisted |
| Owner doc | `02` (which judgements exist), `03` (computation), rules module (constants) |
| Phase | M4 remainder / P10b-adjacent |
| Cost | Trivial save growth (per-team policy, 5 bands); test: determinism + bound. The sheet ships its derived-cost region omitted until this exists |
| Blocks | Practice Plan derived-cost region; load-policy ladder card's shipping form |

| Field | G-15 |
|---|---|
| Requirement | Partial-advance completion record — the interrupted state's "what was preserved" line (failure-v3 card C) needs the engine to expose what completed before interruption |
| Today | `nothing` — advance is atomic to the caller; no partial-completion read model |
| Delta | A completion record on the advance boundary (which steps committed, which did not), exposed read-only |
| Owner doc | `03b` (session/read-model boundary) |
| Phase | P12 / M8 entry-adjacent |
| Cost | Small; bounded to the current advance. Test: record matches committed state after induced interruption |
| Blocks | Truthful interrupted-state copy; resume-preserving guarantees in `04` §7's last clause |
