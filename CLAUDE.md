# CLAUDE.md — Pro Football Coach (iOS)

Standing rules for the build. Read first, every session. **This file owns standing rules; `docs/08-OPUS5-BUILD-PROMPT.md` owns the mission and the definition of done.** Where they overlap, the build prompt states *what to achieve*, this file states *how to work*.

## What this project is

A text-first **pro football management simulator** for iPhone (SwiftUI, offline, no backend). The player is a head coach / GM of a fictional 32-team pro league: sim or play games, manage rosters, draft, sign free agents, run the salary cap, trade, win championships, build a dynasty across decades — with the league narrating it back.

This is a **ground-up rebuild** of a working v1 that was judged mechanically complete but bland. The rebuild is a hybrid of three references, researched in `docs/research/`: pro-football grounding and broadcast presentation, fast-session immediacy and star attachment, and analytical depth with emergent narrative. The engine's validated behavior survives as acceptance specifications; its code does not survive by default.

**Legal guardrail (binding):** every team name, city pairing, mark, player name, broadcast identity, and string is fictional and original. Never use real league, college, network, or player names. The reference apps are mechanics research only — never copy protected expression, assets, strings, trade dress, or source. The open-source ancestor is CC-NonCommercial: never read or reuse it.

## Canon (the only sources of truth)

| Doc | Role |
|---|---|
| `PRODUCT.md` | Product truth: users, purpose, the six Experience Pillars, constraints, brand, accessibility floor |
| `DESIGN.md` | The Primetime design system — **including the Time Layer** (motion, sound, haptics, number staging, celebrations). Read before any UI work |
| `docs/02-GAME-DESIGN.md` | Gameplay canon — rules, systems, numbers |
| `docs/03-ARCHITECTURE.md` | Module layout, data model, engine acceptance specs, persistence, presentation pipeline |
| `docs/04-SCREENS-UI.md` | Every screen: emotional job first, then fields |
| `docs/05-IMPLEMENTATION-PLAN.md` | Phases and per-phase gates |
| `docs/design/mockups/` | **Visual canon** — approved frames for the three hero surfaces |
| `docs/design/briefs/` | Per-screen design briefs (00-system is the locked foundation) |
| `docs/research/R1a–R1d`, `R2-synthesis.md` | Evidence base and the binding rulings/pillars every decision traces to. **Cite finding IDs when justifying a design choice** |
| `docs/OPEN-DECISIONS.md` | Owner decisions — resolved and open. **A blocking open item stops the run** |
| `docs/07-SALVAGE.md` | Justified ports from the old code (silence means rewrite); the parity ledger, checked every gate |
| `docs/06-PLAYED-GAME-MODE.md` | On the Field — the all-22 field, its control model and gates |
| `docs/09-CRAFT-RUBRIC.md` | The scale behind the craft gate — how a surface is scored |

Everything else in the repo is history, not authority.

## Process (non-negotiable)

1. **Doc-first amendment rule.** A gameplay question not answered in `02-GAME-DESIGN.md` gets answered there *before* it is implemented. UI questions go to `04-SCREENS-UI.md`; visual/feel questions to `DESIGN.md`. Never encode an unwritten rule in Swift.
2. **One phase at a time**, in plan order. Before starting a phase, expand its spec with `superpowers:writing-plans` into a task plan under `docs/plans/`. Existing files there are v1-era and are not phase plans for this rebuild.
3. **TDD for all engine code** (`superpowers:test-driven-development`). The engine is pure Swift with no UI dependency — every mechanic gets a failing test first. UI is not exempt from testing: views carry the design-system and presentation suites of `03-ARCHITECTURE.md` §9 (contrast coverage, staging specs, the P2 state-to-witness matrix). Only per-view snapshot tests are optional.
4. **One task = one commit**, Conventional Commits format.
5. **Adversarial review at phase end** (`adversarial-reviewer` or `/code-review`) on the phase diff. Fix confirmed findings before advancing.
6. **Verification before completion** (`superpowers:verification-before-completion`): build green, tests green, feature demonstrated in the iOS simulator.
7. **Cold-play gate at every phase close:** one uninstructed hour actually playing what exists (our dose; the FM evidence behind it is ~two hours), asking only "is this fun and does it pull?" This instrument exists because milestone tracking has historically missed a dead build until far too late (`docs/research/R1c` FM-27).
8. **Debugging:** `superpowers:systematic-debugging` — no guess-fixes.
9. **Parity ledger:** the rebuild ships v1's mechanics or better. Check `docs/07-SALVAGE.md` and the parity list each gate; deletion without replacement is the genre's cardinal sin.
10. **Scope guard:** build what the plan specifies. No unrequested refactors, tidying, or "while I'm here" improvements beyond the task — especially at high effort.

## Tech stack (decided — don't relitigate)

- Swift 5.10+ / SwiftUI, iOS 17 minimum, Xcode 16+, zero third-party dependencies.
- `@Observable` view models, unidirectional data flow, stock SwiftUI controls.
- Sim engine: standalone Swift package (`FootballSimCore`) — pure logic, deterministic under a seeded RNG, fully unit-tested, zero `import SwiftUI`.
- Persistence: `Codable` JSON save slots in Application Support, versioned `saveFormatVersion`, rolling backups. **Writes never block the main actor.**
- No network, no accounts, no analytics, no ads.

## Conventions

- 32 teams, 2 conferences × 4 divisions × 4 (table in `02-GAME-DESIGN.md`).
- Ratings are 40–99 `Int`; money is integer dollars — no floating-point currency.
- All tunable constants live in `LeagueRules.swift`. No inline magic numbers, and no literal spacing, radius, duration, or color in a view — tokens only.
- Files small and focused; split by responsibility (model / engine / feature view).
- Player-facing copy comes from the canon docs and follows the two-voice rule: the system voice is plainspoken with no exclamation marks; the fictional press has personality. Never lorem ipsum.
- Every design or gameplay decision traces to research, the pillars, or the locked system — or is marked `NOVEL` with its reasoning.

## Escalate to the owner (stop and ask) when

- An item in `docs/OPEN-DECISIONS.md` blocks progress.
- Canon contradicts itself and the conflict cannot be resolved by the doc-first rule.
- A phase gate fails repeatedly (three attempts) on the same criterion.
- A change would remove or reduce a shipped mechanic, or breach the legal guardrail, the offline constraint, or the accessibility floor.
