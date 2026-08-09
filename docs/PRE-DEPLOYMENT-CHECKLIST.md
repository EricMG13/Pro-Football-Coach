# Pre-Deployment Checklist — Adversarial Review Findings

**Date:** 2026-08-09
**Tree reviewed:** `dc18380` plus the uncommitted experience-XP diff (`CoachEngine.swift`, `SeasonEngine.swift`, `ExperienceTests.swift`)
**Produced by:** `/adversarial-reviewer` full-codebase pass (Saboteur / New Hire / Security Auditor personas) plus a dedicated unwired-mechanic sweep of every setting, trait, model field, and public engine API.
**Test suite at review time:** `swift run SimTests` → 252 tests, 13,455 checks, **4 failing**.

**Verdict: BLOCK.** Nothing below the Verification Gate ships until every C-item is closed and every U-item has a recorded decision.

---

## How to use this document

- **C-items (Critical)** — release gates. All must be fixed and verified before any TestFlight or App Store build.
- **W-items (Warning)** — gameplay-correctness defects. Each is either fixed or gets a one-line written accept-risk note here before deploy.
- **U-items (Unwired inventory)** — mechanics that exist in data, copy, or UI but do nothing. Each needs an explicit decision: **Wire** (implement the effect) or **Cut** (remove the UI/copy/field so the game never advertises what the sim doesn't do). Shipping a visible toggle, trait card, or skill node with no effect is a broken promise to the player; that is the bar.
- **N-items (Notes)** — polish and hygiene. Author's discretion.
- Check items off in place. When a fix changes a game rule, update `docs/02-GAME-DESIGN.md` first per CLAUDE.md.

---

## A. Release gates (CRITICAL)

### ☐ C1 — The draft runs twice on the live-draft path; scouting feeds a ghost board on the sim path
Two manifestations of one seam: `OffseasonEngine.advanceStage(.draft)` regenerates a fresh class and runs the full AI draft unconditionally.

- UI path: `DraftDayView` → user drafts via `DraftSession` (rookies committed) → "Finish Draft" → `completeDraftStage()` → `advanceOffseasonStage()` → `OffseasonEngine.swift:467` runs **a second complete draft** with a brand-new 304-player class. Every team gains ~7 phantom rookies plus UDFAs; rosters hit ~76; cutdown later releases real players with dead money.
- Sim path: `runFullOffseason` ignores the scouted `league.draftClass` entirely and never clears it, so next season's `startSeason` guard (`if draftClass.isEmpty`) skips regeneration — the user scouts a stale class that is never the one drafted.

Fix shape:
- [ ] `advanceStage(.draft)` consumes `league.draftClass` when non-empty instead of `DraftClassFactory.makeClass`.
- [ ] Skip the engine draft entirely when a `DraftSession` already ran this stage (track a `draftCompleted` flag or check roster deltas).
- [ ] Clear `league.draftClass` at the end of the draft stage on **both** paths.
- [ ] Acceptance test at the `advanceStage` layer (the new ExperienceTests draft-board test asserts against `DraftEngine.runDraft` directly — the wrong layer — and is currently red anyway).
- [ ] Post-fix soak: after any offseason path, every roster ≤ 69 and each team gained ≤ 7 + UDFA draftees.

### ☐ C2 — The coaching skill tree is mostly fake (19 of 24 nodes have no effect)
`CoachEngine.offenseRatingBonus`, `defenseRatingBonus`, `injuryRateMultiplier` (`CoachEngine.swift:161–189`) are defined and never called. Eleven more nodes have no implementation anywhere. Players spend earned points on placebo. Full node list in **U25**. For each node: wire it or remove it from `SkillTrees` so it cannot be purchased. Closing this item means U25 shows a decision on all 24 rows.

### ☐ C3 — Test suite is red on the current tree (4 failures)
- [ ] `SeasonEngine › advancing a week is fast enough` — 411 ms vs 150 ms budget (`SeasonTests.swift:218`). Suspects: draft-class generation inside the timed window, `selectAwards`-style refolds (see N9).
- [ ] `Offseason › every roster is legal after the offseason` — oversized practice squad (`DynastyTests.swift:108`).
- [ ] `Ten-season soak › the league does not hoard players` — 38-year-old unsigned player, past the 36 retirement cap (`DynastyTests.swift:287`). Likely ordering: free agents age at training camp (stage 6) *after* the retirement check (stage 2), and cutdown releases (stage 7) enter the pool after the check too.
- [ ] `Experience › the draft consumes the board the coach scouted` (`ExperienceTests.swift:187`) — same seam as C1.

Gate: `swift run SimTests` fully green before the experience diff is committed.

---

## B. Gameplay correctness (WARNING)

- ☐ **W1 — Safety awards possession to the wrong team.** `GameSimulator.swift:244`: regulation `.safety` sets `nextYardLine = 40` but never toggles `offenseIsHome`; the conceding team keeps the ball. The overtime path *does* toggle — the inconsistency is the proof. One-line fix.
- ☐ **W2 — Two-point chart is sign-inverted.** `GameSimulator.swift:686`: `[2,5,10].contains(deficit + touchdownPoints)` — should subtract (situation scores are pre-TD). As written the AI goes for two while **up 7 or up 10** and never when down 8/11/16.
- ☐ **W3 — Interception returns move the ball the wrong way.** `GameSimulator.swift:494` treats INT `outcome.yards` (defender return, `PlayResolver.swift:161`) like offensive advance; a longer return leaves the intercepting team *worse* off. Correct for fumbles only — branch on the turnover type.
- ☐ **W4 — Victory formation can never happen.** Kneel requires `defenseTimeouts == 0` (`PlayCaller.swift:174`) but timeouts are never decremented anywhere; users can't call kneel either (`standardCalls` excludes it). Leading teams run live plays at 0:30 and can fumble the win away. Couples to U18.
- ☐ **W5 — AI teams can never re-sign their own players.** `OffseasonEngine.swift:457`: `rolloverContracts` moves every expired deal to free agency *before* `runReSigning` scans the roster — the scan is empty by construction. Dead code; the asymmetry silently favors the user. Re-sign on `isExpiring` before rollover.
- ☐ **W6 — End-of-season goals pay out in September, permanently.** `settleGoals` runs weekly (`AppState.swift:224`) and ignores `isEndOfSeason`; a week-2 division leader is paid "Win the division" instantly, and the diff's `hasPaidOut` flag makes the premature payment permanent. Settle `isEndOfSeason` goals only once the season is decided.
- ☐ **W7 — Rookie of the Year can never go to a rookie.** `PlayerFactory` sets `yearsPro = max(0, age − 22)` (a 23-year-old draftee is born a second-year pro) and training camp increments `yearsPro` before the rookie's first season. OROY/DROY pools contain only street fillers, or nobody.
- ☐ **W8 — Traded draft picks don't survive anything.** `League` has no picks field; `TradeEngine.makePicks` regenerates all picks with original owners on every load (`AppState.swift:140`) and again inside the draft stage. Latent today (trade UI is players-only) but the engine supports pick packages and the Draft-Day Trader node advertises them. Persist picks in `League` (bump `saveFormatVersion`) before wiring any pick-trade UI.
- ☐ **W9 — Trades are never cap-checked.** `TradeEngine.evaluate` checks positional minimums only; either side can end over the cap mid-season and nothing enforces in-season compliance. Docstring claims otherwise.
- ☐ **W10 — Saving mid-draft and reloading re-runs the whole draft.** `draftSession` is transient; `beginDraftIfNeeded` after reload rebuilds at pick 1 over the remaining pool while committed picks sit on rosters. Same inflation as C1 through a second door. Either persist session progress or block save/exit during the draft.
- ☐ **W11 — Injuries freeze during the playoffs.** `healInjuries` runs only in `advanceRegularSeasonWeek`; a 1-week wild-card injury sidelines the player for the entire postseason. Tick during playoff rounds (and decide the offseason-healing rule in docs/02).
- ☐ **W12 — Potential ceilings are a treadmill.** `projectedCeiling = overall + ceilingBonus` recomputed every camp, so headroom is a per-grade constant and the "closer to his ceiling the slower" comment (`ProgressionEngine.swift:118`) is false; grades scale rate, never cap. Store a fixed ceiling at generation, or rewrite the comment and accept unbounded-until-peak growth in docs/02.
- ☐ **W13 — Career records regress when the holder retires.** `RecordsBook` career kinds scan current rosters only; a retired career leader's mark reverts to the seeded fictional name, and kept season-record holders display as "A former player" (`findPlayer` can't see history). Snapshot holder names/marks into persistent state.
- ☐ **W14 — Save trust boundary is unvalidated.** Decode is the only gate; no post-load structural checks. `Team.depthOrder`'s `Dictionary(uniqueKeysWithValues:)` **traps** on duplicate player IDs, so a hand-edited or half-corrupted save crashes at first roster read instead of failing at load. Backup fallback also restores older state silently. Add a post-decode validation pass + user-visible "restored from backup" notice.

---

## C. Unwired & outstanding inventory

Every row needs **Wire** or **Cut** recorded before deploy. "Cut" means the field, toggle, copy, or node is removed — not left visible.

### Settings & toggles

| # | Item | Where | Status | Decision |
|---|------|-------|--------|----------|
| ☐ U1 | `autoCallPlays` — "Coordinators call plays" toggle | Live toggle `NewFranchiseWizard.swift:197`; setting read **nowhere** | Dead toggle shown to every new franchise | Wire / Cut |
| ☐ U2 | `showPredictionLine` — "Show point spreads" toggle | Live toggle `NewFranchiseWizard.swift:198` with explanatory footer; read **nowhere** (matchup cards never consult it) | Dead toggle + false footer copy | Wire / Cut |
| ☐ U3 | `franchiseTagEnabled` | `League.swift:142`, defaults `true`; no tag mechanic exists anywhere, no toggle either | Dead field; misleading to future maintainers | Wire (whole mechanic) / Cut field |

### Economy & career

| # | Item | Where | Status | Decision |
|---|------|-------|--------|----------|
| ☐ U4 | `CoachProfile.cash` (starts $500K) | `Staff.swift:234` | Never earned, never spent; coach salary never accrues | Wire / Cut |
| ☐ U5 | `ExperienceEvent.draftSteal` (50 XP) | `CoachEngine.swift:89` | Never fired — no steal detection after the draft | Wire / Cut |
| ☐ U6 | `Team.staffBudget` | Generated per team, **displayed** at `TeamViews.swift:608` | Never enforced; staff salaries unconstrained | Wire / Cut display |
| ☐ U7 | Staff hiring/firing UI | — | **Absent entirely** (zero call sites); carousel churns coordinators autonomously, user is a spectator to their own staff | Wire (screen) / document as post-1.0 |
| ☐ U8 | `SeasonGoal.Kind.topOffense` / `.championship` | `CoachEngine.swift:208` | `makeSeasonGoals` never generates either kind | Wire / Cut cases |
| ☐ U9 | `activeScenario` + scenario objectives | `AppState.swift:39`; scenario picker promises "Win a championship within three seasons" etc. | Set once, never read, not persisted — objectives are pure flavor, no tracking, no win/fail state | Wire / soften copy |

### Player & staff traits (cards promise effects)

| # | Item | Card copy | Status | Decision |
|---|------|-----------|--------|----------|
| ☐ U10 | `Trait.clutch` | "Raises his game late in one-score games." | Zero gameplay effect (assigned by Aging Legend scenario, too) | Wire / Cut |
| ☐ U11 | `Trait.boomBust` | "Spectacular and infuriating, often in the same quarter." | Zero effect | Wire / Cut |
| ☐ U12 | `StaffTrait.motivator` | "Keeps the locker room happy." | Zero effect | Wire / Cut |
| ☐ U13 | `StaffTrait.negotiator` | "Signs staff and players for less." | Zero effect | Wire / Cut |

Working traits for reference: `injuryProne`, `ironMan` (injury severity), `leader` (morale drift), `loyal`, `mercenary` (contracts/interest), `lateBloomer` (progression), `StaffTrait.developer` (camp bonus).

### In-game mechanics

| # | Item | Where | Status | Decision |
|---|------|-------|--------|----------|
| ☐ U14 | Timeouts | Tracked, reset at half/OT in `GameSimulator`; carried in `GameSituation` | Never consumed by anyone; gates W4 | Wire / Cut fields |
| ☐ U15 | `OffensivePlay.spike` | `PlayMatrix.swift:6` | No caller can ever produce it; two-minute clock-stop toolkit absent | Wire / Cut |
| ☐ U16 | Two-point try resolution | `PlayMatrix` has a `.twoPointConversion` profile + matchup weights | `attemptTry` uses a flat `rng.chance(0.48)` — ratings ignored, arcade `PlayExecution` ignored, profile dead | Wire through `PlayResolver` |
| ☐ U17 | Penalties | `PlayCategory.penalty`, `TeamGameStats.penalties/penaltyYards` | Mechanic absent; box scores show 0 penalties forever | Wire / Cut fields + box-score row |
| ☐ U18 | `PlayCategory.timeout` / `.injury` events | `GameRecord.swift:83` | Never emitted into the play log | Follows U14 / injury-log decision |
| ☐ U19 | `possessionSeconds` | `TeamGameStats` | Never populated; any time-of-possession display would show 0:00 | Wire / Cut |
| ☐ U20 | `Tempo` user control | Engine auto-selects only | Docs describe it as "the clock-management lever"; user never touches it | Confirm design / expose |
| ☐ U21 | `aiCapFloorShare` (0.89) | `LeagueRules.swift:58` | AI spending floor never enforced — cap-hawk teams can hoard forever | Wire / Cut |

### Dead API with misleading comments

| # | Item | Where | Status | Decision |
|---|------|-------|--------|----------|
| ☐ U22 | `GameRecord.compacted()` | `GameRecord.swift:234` — "Applied to older seasons so saves stay small" | **Never called**; comment describes a pruning pass that doesn't run (results are wiped yearly instead) | Wire / delete + fix comment |
| ☐ U23 | `DraftSession.grade(for:expectedRound:)` | Used by tests only | War-room pick grade never shown in `DraftDayView` | Wire / delete |
| ☐ U24 | `ScoutingEngine.sleepers(in:)` | No callers | Pairs with the dead Sleeper Radar node | Follows U25 |
| ☐ U26 | `NewsCategory.milestone` | `League.swift:170` | No milestone news is ever generated (record broken, 10k-yard careers, etc.) | Wire / Cut case |
| ☐ U27 | `AppState.isBusy` | `AppState.swift:57` | Written never, read never | Delete |

### U25 — Skill tree node audit (closes with C2)

| Branch | Node | Status |
|--------|------|--------|
| Scouting | ☐ Sharper Eye I / II | **Works** (`scoutingFogReduction`) |
| Scouting | ☐ Extra Scouts | **Works** (`scoutingPoints`) |
| Scouting | ☐ Combine Insider | Dead — no implementation |
| Scouting | ☐ Sleeper Radar | Dead — `sleepers()` exists, no caller (U24) |
| Scouting | ☐ Draft-Day Trader | Dead — and pick trading itself doesn't persist (W8) |
| Development | ☐ Position Coaches I / II | **Works** (`developmentBonus`) |
| Development | ☐ Veteran Mentors | Dead |
| Development | ☐ Youth Program | Dead |
| Development | ☐ Breakout Culture | Dead |
| Development | ☐ Iron Regimen | Dead — `injuryRateMultiplier` defined, never called |
| Offense | ☐ Scheme Guru I / II | Dead — `offenseRatingBonus` defined, never called |
| Offense | ☐ Red-Zone Package | Dead |
| Offense | ☐ Two-Minute Drill | Dead |
| Offense | ☐ Explosive Plays | Dead |
| Offense | ☐ Fourth-Down Analytics | Dead |
| Defense | ☐ Scheme Guru I / II | Dead — `defenseRatingBonus` defined, never called |
| Defense | ☐ Third-Down Stop | Dead |
| Defense | ☐ Turnover Chain | Dead |
| Defense | ☐ Blitz Architect | Dead |
| Defense | ☐ Bend Don't Break | Dead |

Score: **5 of 24 nodes function.**

---

## D. Notes & polish (author's discretion)

- ☐ N1 — `recordPlay` uses raw `UUID()` for play IDs (`GameSimulator.swift:867`) — violates the seeded-identity doctrine for every retained-plays (user) game.
- ☐ N2 — Injury victim selection is the lexicographically-first UUID among involved players, not a weighted draw — deterministic bias per matchup.
- ☐ N3 — "Finish top 10 in total defence" goal ranks by roster *rating*, not season stats; copy promises a stats table.
- ☐ N4 — `kickerFieldGoalProbability` reads the pre-game `Team`, not the injury-aware `TeamSnapshot`; the AI kicks on a kicker who left the game.
- ☐ N5 — `reSign(chance:)` advances `league.rng` without persisting on rejection — free save-scum reroll.
- ☐ N6 — `runCutdown` auto-cuts the **user's** roster too; engine backstop silently overrides user cutdown choices. Intended? Document or exempt.
- ☐ N7 — DraftBoardView empty-state copy is stale post-diff ("Prospects appear once the season reaches the draft" — they now appear at kickoff).
- ☐ N8 — OT points land in the Q4 bucket of `quarterPoints`; box score has no OT column.
- ☐ N9 — `selectAwards` re-folds full-season stats inside `max()` comparators (~2 evaluations per element over every game record); adjacent to the failing 150 ms budget (C3).
- ☐ N10 — Kneel at your own 1 can reach yard line 0 without a safety check (edge case; moot until W4/U14 land).
- ☐ N11 — `divisionGamesPerTeam` and several `LeagueRules` constants are asserted only by convention; schedule tests cover counts — keep it that way when touching the generator.
- ☐ N12 — Playoff reseeding uses live `playoffSeeds` during the bracket, so a playoff head-to-head result can reorder two equal-record teams between rounds — official seeding should be frozen at week 18.

---

## E. Verification gate (run before *any* deploy, after the above)

1. ☐ `swift build` clean, zero warnings introduced by the fixes.
2. ☐ `swift run SimTests` — all suites green (252+ tests), including new acceptance tests for C1, W1–W3, W6.
3. ☐ Determinism soak: same seed → identical save bytes across two full simulated seasons (including one live-played game with `retainPlays`, which currently fails via N1).
4. ☐ Ten-season dynasty soak: roster sizes legal every year, free-agent pool ≤ 400, no player past retirement age unsigned (currently red via C3).
5. ☐ iOS simulator demo of the full loop: new franchise → season → live game → playoffs → every offseason stage **through the draft room** → season 2 kickoff. Roster count checked after the draft (catches C1 regression).
6. ☐ Mid-draft kill-and-relaunch test (catches W10).
7. ☐ Hand-corrupted save load test: duplicate player ID + truncated file → graceful error, no trap (catches W14).
8. ☐ `docs/02-GAME-DESIGN.md` updated for every rule decision made closing W/U items (CLAUDE.md requirement).
9. ☐ Adversarial re-review (`/adversarial-reviewer --diff <fix-range>`) on the fix branch before merge.

---

*Cross-reference: process rules in `CLAUDE.md`; gameplay source of truth in `docs/02-GAME-DESIGN.md`; original review delivered in-session 2026-08-09.*
