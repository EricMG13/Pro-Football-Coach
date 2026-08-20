# Sample pool — consolidated review for deployment, 2026-08-13

Reviews every sample generated or supplied in this session and answers one question: **what actually
goes into `Sources/ProFootballCoachUI/`, and in what order.**

## Sources reviewed

| Source | What it produced | Detail |
|---|---|---|
| Google Stitch | 8 boards, one per `*-v3.dc.html` sheet | `docs/proofs/stitch-2026-08-13/`, harvest in `2026-08-13-stitch-composition-harvest.md` |
| Figma | 60 token-bound variables, 12 treatment variants over 3 registry entries | `docs/proofs/figma-pool-2026-08-13/` |
| UX Pilot | 2 Match Day samples | review in `2026-08-13-uxpilot-sample-review.md` |
| Banani | 6 screens **and 12 named components as separate JSX files** | `https://app.banani.co/preview/D1aAV7hbgqt3` |
| Visily | 2 boards | **not cleared — see §2** |

---

## 1. The gate nobody has named yet

`04` §6.5 lists 23 registry entries and says they "map 1:1 onto Swift types in
`Sources/ProFootballCoachUI/`". They do not. Of the 23, **three exist as types**:

- 1 `CoachWorldRouteButton`
- 2 `CoachWorldActionButtonStyle`
- 4 `CoachWorldBlankPhotoPlate`

(plus `coachWorldDeskSurface` as a modifier, entry 3.)

The other nineteen — `WorldStrip`, `IdentityBand`, `DenseTable`, `ColumnSet`, `ListControls`,
`RatingBadge`, `DeltaMark`, `ConfidenceTag`, `VerdictLine`, `Meter`, `OpposedBar`, `FormLine`,
`StatusChip`, `RoleToken`, `AgendaRow`, `ScoreBug`, `LowerThird`, `CallInCard` and the failure set —
are **inlined inside the five screen views**: `CoachingHQView`, `MatchDayView`, `RosterView`,
`RecruitingBoardView`, `PlayerProfileView`. `04` §6.5 already anticipates this and calls it
"extraction refactors when promoted — P11/M8 work, not a silent rename".

**This is the gate.** Every element below lands on a registry type. Nineteen of those types do not
exist, so "deploy the element" currently means "edit the same idea into up to five screen files by
hand, and hope they stay in sync". That is precisely the coverage-boundary failure `CLAUDE.md`
warns about, applied to components instead of tests.

**Recommendation: do the extraction first, then deploy into it.** Not the other way round.

---

## 2. Visily — not cleared, do not use yet

Board `2692031` loaded. Board `2692030` renders as empty canvas for me and the board's canvas would
not pan or zoom reliably through the browser tools, so **I have not seen it and cannot review it**.

On board `2692031` I read the standings and roster panels at 50 % zoom. The entries appear to be
**real NFL clubs** — I read what look like *Kansas City Chiefs, Buffalo Bills, Baltimore Ravens,
Houston Texans, Detroit Lions, Philadelphia Eagles, San Francisco 49ers* and *Atlanta Falcons*. City
and nickname are correctly paired in each case, which random fiction does not produce.

**I am flagging this as blocking but not asserting it as confirmed** — the read was at reduced zoom
on a canvas-rendered board, and Visily's inspect and present modes are unavailable to a public
viewer. Before anything from Visily is used, open it at full zoom and check the standings list. If
those names are there, the board is unusable under the `CLAUDE.md` guardrail and should not be
forwarded, prompted from, or committed.

Note the pattern this makes three-for-three: **Stitch invented a networked product, UX Pilot printed
`NFL`, and Visily appears to have populated a whole league with real clubs.** Every one of these
tools reaches for real football identities the moment the prompt says football. A real-mark scan is
now a mandatory first step on any externally-generated sample, before anyone looks at the design.

---

## 3. Banani is the find

`https://app.banani.co/preview/D1aAV7hbgqt3` is the most deployable artefact produced this session,
because it is **already decomposed into named components** rather than screens:

`CallInCard` · `CausalLowerThird` · `DecisionCard` · `DriveSummary` · `FootballField2D` ·
`HQSideNav` · `MatchControls` · `PressureGauge` · `Scorebug` · `StaffNote` · `WeekPlanRow` ·
`WorldStrip`

Ten of those twelve names are our registry vocabulary. Its identities are fictional
(Carson Tech, Southern State, Eric Mercer, D. Tillman, Perry, Carver) — **subject to the blocklist
test, which is the authority, not my reading.**

The copy is the strongest thing in it. Three examples worth keeping verbatim as exemplars:

- **Call-in:** "D. Tillman · OC — Shift to Power-I formation, they're over-rotating the boundary CB
  every 3rd down." Named staff, causal, and a *recurring* read rather than a one-play observation.
- **Lower third:** "Incomplete pass — Perry. CB Jones jumped the route on the dig. Southern State
  showing Cover 2 robber all series." Names the cause *and* the pattern.
- **Staff note:** "Perry's route discipline improved — ready to start Sat if Carver's hamstring
  doesn't clear." Conditional, and it tells the coach what decision it bears on.

That is the register `04` §4.3 asks for — decisions living beside their cause — written better than
anything in the current sheets.

---

## 4. The deployment list

Status key: **A** adopt as drawn · **B** adopt after an `04` amendment · **C** idea only, needs design
work · **R** reject.

### 4.1 Elements that land on an existing type

| Element | Source | Type | Status | Note |
|---|---|---|---|---|
| Decide/inspect/delegate as three explicit controls on one card | Banani `CallInCard` | `CoachWorldActionButtonStyle` | A | Accept / Dismiss / Inspect, violet fill on the primary only |
| Register-contrast pair (radius 8 DESK vs radius 0 BROADCAST) | Stitch sheet 7 | `CoachWorldActionButtonStyle` | A | Teaching device for the sheet, not a code change |

### 4.2 Elements that land on a type that must be extracted first

| Element | Source | Registry | Status | Note |
|---|---|---|---|---|
| World strip carrying the **next fixture inline** and a named advance | Banani `WorldStrip` | 5 | **A** | `vs Southern State · Sat 14:30 → Continue`. Names what you are advancing *to*. Best single upgrade in the set |
| Verdict as a 24 pt **band** under the world strip | Stitch A / Figma V1 | 13 | **A** | Figma pool V1. Cheapest in points, stays in frame |
| Shipping/target verdict forms at **shared geometry** | Stitch / Figma V4 | 13 | **B** | Needs `04` §6.5 to say the two forms share geometry and the gap ID prints in the empty slot |
| Confidence as **fill width + printed observation count** | Stitch sheet 4 / Figma C2 | 12 | **A** | One element, two facts, survives greyscale |
| Four-state confidence escalation strip | Figma C4 | 12 | A | Sheet teaching block |
| Depth slot as a **leading swatch**, status in a **fixed trailing column** | Stitch sheet 3 / Figma R2 | 7, 17 | **A** | Buys ~22 pt of name column; gives the trailing edge a rule |
| Chip carrying its own value — `INJURED · 3 WK` | Stitch sheet 3 / Figma R3 | 17 | **A** | State and magnitude in one read |
| Selection as boundary + 2 pt leading bar + printed word | Figma R4 | 7 | **A** | Already required by §6.3; this is the drawing |
| Over-capacity meter that **breaks its track boundary** | Stitch sheet 5 | 14 | **B** | Needs §6.5 registry 14 to require a shape difference, not only colour |
| Delta rows printing the VoiceOver sentence inline | Stitch sheet 4 | 11 | A | Including the no-change row |
| `FormLine` as discrete blocks + rating thread + printed summary | Stitch sheet 4 | 16 | A | `6-3-1, AVG 7.2` |
| Interrupted state as progress + done/pending checklist + RESUME | Stitch sheet 8 | 23 | A | Honest where a spinner is not |
| Delegated state with **RECLAIM** and a report-back date | Stitch sheet 8 | 19, 23 | **B** | Implies engine support for withdrawing a delegated task. Owner decision |
| Error banner as an inline row inside the table | Stitch sheet 8 | 23 | A | Headers and controls stay live |
| Empty state carrying its resolving control | Stitch sheet 8 | 23 | A | `NO PLAYERS FOUND → CLEAR FILTERS` |
| Causal lower third naming cause **and** pattern | Banani, UX Pilot | 21 | **A** | Adopt the Banani copy as the exemplar |
| Score bug: two team blocks, clock, down and distance, possession dot | Banani `Scorebug` | 20 | A | Hard edges, compact |
| Five match controls: speed · pause · key moments · tactics · take over | Banani `MatchControls` | — | **A** | Independently lands on five, which is what `04` requires |
| Key moments as clock-stamped jump marks | UX Pilot A | 22 | A | One 20 pt row |
| Agenda row with day, title, **reason**, type chip and load level | Banani `WeekPlanRow` | 19 | A | The reason line is the addition |

### 4.3 New objects — no registry entry exists

| Element | Source | Status | What it needs |
|---|---|---|---|
| **Drive summary strip** — start yard, per-play delta dots, plays, yards, elapsed | Banani `DriveSummary`, UX Pilot B | **B** | New registry entry. ~30 pt, four facts, and it is the unit a coach thinks in. Engine must own drive state |
| **Pressure gauge** — Win Now 72 / Roster Depth 58 / Recruit Class 85 / Staff Morale 44 | Banani `PressureGauge` | **B** | New registry entry, maps to the `04` §8 stakeholder family. A coach's readout, not a broadcast one |
| **Momentum bar** — `IRON 61% — 39% VALE` on one shared track | UX Pilot A | **C** | Only if the engine owns a momentum term. If not, §4.4 forbids drawing it. Good honesty test |
| **Staff note** — timestamped, conditional, decision-bearing | Banani `StaffNote` | **C** | Overlaps `CallInCard`; decide whether it is a second component or a state of the first |
| **Split-rail Match Day chassis** — persistent score/clock rail beside the field | UX Pilot B | **C** | Test at true 852 x 393 before committing. Portrait starved the field; landscape may not |

### 4.4 Rejected

Stock Tailwind palette in every external sample · gradients, blur, glass, decorative shadow ·
emoji in UI copy (Stitch, UX Pilot, both) · `BOOST` as a control verb · marquee tickers · desktop and
portrait frames · five-step rating-badge colour ladder · full-width saturated status bars · fabricated
contrast ratios · every networked failure state · all of UX Pilot B's identity layer · Visily pending §2.

---

## 5. Assets

There are almost none, and that is correct. The product bundles no fonts, no images, no crests and no
photographs; `CoachWorldBlankPhotoPlate` exists precisely so no face is ever generated. The only
things that behave like assets:

- **The token set.** Now materialised as 60 Figma variables carrying the exact `04` §6.1 values, and
  already shipped in `DesignTokens.swift`. The Figma file is a mirror, not a source — `04` remains the
  only canonical home, and gap G-07's test half still owes a code/canon sync check.
- **SF Symbols names.** The 23 learned symbols in `04` §6.6 plus the unbounded-but-labelled control
  furniture. System-provided, nothing to bundle. Gap G-08 walks `ScreenRegistry.swift` to enforce the
  caps by construction.
- **The synthetic team trio.** Three labelled placeholder colour pairs, pending generator output.

Nothing from any sample adds a bundled asset, and nothing should. Any sample element that needs an
image is drawn instead.

---

## 6. Sequence

1. **Scan Visily at full zoom.** If the real club names are there, discard both boards and record it.
2. **Extract the nineteen inlined registry types** out of the five screen views into
   `Sources/ProFootballCoachUI/`. This is the P11/M8 work `04` §6.5 already names. Nothing else in
   this list can be deployed cleanly until it exists.
3. **Amend `04`** for the six **B** items — the two shared-geometry and shape-difference rules, the
   reclaimable-delegation decision, and the two new registry entries (drive strip, pressure gauge).
   Doc first, per `CLAUDE.md`.
4. **Deploy the A items** into the extracted types, TDD where they carry logic.
5. **Re-render the affected `*-v3.dc.html` sheets** from amended canon, by hand. Do not regenerate
   them from any of these tools.
6. Adopt the Banani copy as the commentary and call-in exemplars.

Everything in §4 remains a proposal. Where a sample and `04` disagree, `04` wins.
