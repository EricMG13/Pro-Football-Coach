# 00 — Executive Plan: Pro Football Coach (iOS)

**Goal:** Ship a native SwiftUI pro-football franchise simulator for iOS — the professional-league successor to the college sim in the reference screenshots — built clean-room, offline, with real cap/draft/trade depth and live play-calling.

**Why now (evidence in `01-RESEARCH.md`):** the genre's community is active but its pro game died on Android in 2019, its successor is Steam-only, and iOS players are still asking for a port. The reference app proves the UX formula on iOS for college; nobody has shipped the pro version. Empty repo `EricMG13/Pro-Football-Coach` is the target.

**Architecture (one breath):** pure-Swift deterministic sim engine in a local Swift Package (`FootballSimCore`, TDD, seeded RNG, calibration tests) + SwiftUI app layer (`@Observable` view models, team-color theming, JSON save slots). No dependencies, no backend. Details: `03-ARCHITECTURE.md`.

## Document map

| # | Doc | Role |
|---|---|---|
| — | `CLAUDE.md` | Standing instructions for Opus 5 (copy to repo root) |
| 00 | this file | Master plan + execution process |
| 01 | `01-RESEARCH.md` | Evidence: 68-screenshot inventory, game-family history, community wishlist, prior-session methodology, legal guardrails |
| 02 | `02-GAME-DESIGN.md` | **Canon.** All gameplay rules and numbers |
| 03 | `03-ARCHITECTURE.md` | Stack, module layout, data model, engine principles, testing |
| 04 | `04-SCREENS-UI.md` | Every screen, field-by-field, + college→pro conversion map |
| 05 | `05-IMPLEMENTATION-PLAN.md` | Phases P0–P8; P0–P1 task-by-task with code; per-phase plan protocol for the rest |

## Scope

**V1 =** 32-team fictional league · 17-game season + 14-team playoffs (12/16 options) · live play-by-play with two-way play-calling + quick sim · full salary cap (proration, guarantees, dead money, rookie scale) · re-sign/FA/trades/cuts · 7-round draft with scouting fog + UDFA · progression/regression + training camp · injuries · 9-category stats, career stats, records, awards, HoF · news engine · coach RPG (XP, 4 skill trees, goals, job security, firing/job market) · trophy room · 3 scenarios · save slots + checkpoints + autosave · tutorial · light/dark.

**Not v1** (ordered backlog): custom league editor + JSON import/export (v1.5 — data model ready day 1), weather, comp picks, restructures/June-1, named coordinators, Game Center leaderboards, multiplayer/commissioner, iPad layout, monetization.

## Phase map (details + gates in `05`)

| Phase | Deliverable (each independently shippable to TestFlight-quality) |
|---|---|
| P0 Foundation | Repo, Xcode project + `FootballSimCore` package, test harness, docs committed |
| P1 Domain core | Models, seeded RNG, league/player generation (32 teams, 53+16 rosters), save round-trip; app shell lists generated league |
| P2 Game engine | Full play-by-play sim of one game, box scores, calibration tests green |
| P3 Season loop | Schedule gen, weekly advance, standings/tiebreakers, playoffs, power rankings, basic news; Season/Schedule/Standings screens |
| P4 Live game UI | Field view, coin toss, play-calling, quick-sim tiers, live box score, win prob, game report |
| P5 Team & stats UI | Depth chart, player cards, injuries, stats suite, team overview |
| P6 Front office | Cap engine, contracts, re-sign, free agency, trades, cuts (engine + UI) |
| P7 Draft & offseason | Scouting, draft class gen, draft day, UDFA; 10-stage offseason incl. camp/progression, retirements, awards, HoF, records |
| P8 Coach RPG & ship | XP/skill trees/goals/job security/team search, trophies, scenarios, settings, tutorial, onboarding wizard polish, App Store prep |

Sequencing rationale: engine before UI it feeds; cap before draft (rookie contracts need cap); coach RPG last because it hooks into everything. After P3 the game is already playable end-to-end (sim-only); every later phase deepens it — de-risks motivation and testing.

## Execution process (how Opus 5 runs this)

1. Copy `plan/` docs into the repo (`docs/` + `CLAUDE.md` at root). Commit as P0-Task 1.
2. Per phase: read the phase spec in `05` → run `superpowers:writing-plans` to expand it into a bite-sized TDD task plan (P0–P1 already expanded — execute directly) → execute via `superpowers:subagent-driven-development` (or `executing-plans` inline) → adversarial review the phase diff (`adversarial-reviewer` / `/code-review`) → fix confirmed findings → verify (build + tests + simulator demo) → commit throughout, one task = one commit.
3. Never advance a phase with red tests or unmet phase gate (gates listed per phase in `05`).
4. Ambiguity rule: gameplay question → answer in `02` (add it there first); UI question → `04`; if genuinely underdetermined, pick the simpler option and log it in the phase notes.

Suggested per-phase kickoff prompt: *"Read CLAUDE.md and docs/. Execute Phase N of docs/05-IMPLEMENTATION-PLAN.md: expand with writing-plans if not pre-expanded, then implement task-by-task with TDD, adversarial review at the end, and demo in the simulator."*

## Risks & mitigations

- **Sim realism is the product.** Mitigation: calibration test suite with hard statistical bands (P2 gate) + seeded determinism so tuning is reproducible.
- **Scope creep toward Madden.** Mitigation: v1 list above is closed; anything new goes to backlog, not scope.
- **Cap math correctness** (dead money, proration). Mitigation: property tests ("cap never negative", "sum of hits = contract value") in P6 gate.
- **Solo-dev asset load** (32 logos). Mitigation: geometric/SF-Symbol-composed logos generated in code, no image assets.
- **License contamination.** Mitigation: clean-room rule in `CLAUDE.md`; nobody opens the CC-NC Java source.

## Definition of done (v1)

New player can: onboard through wizard → play/sim a full season → survive an entire offseason (re-sign, FA, draft, camp, cutdown) → start season 2 with a coherent roster and cap → across 10 simmed seasons: no crashes, calibration bands hold, saves stay < 5 MB, week-advance < 150 ms, level-ups and firings both reachable. All tests green; adversarial review findings closed; runs on iPhone SE → Pro Max, light + dark.
