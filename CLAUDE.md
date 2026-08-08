# CLAUDE.md — Pro Football Coach (iOS)

Instructions for Claude (Opus 5) building this project. Read this first, every session.

## What this project is

A text-based **pro football management simulator** for iOS (SwiftUI, offline, no backend). The player is a head coach / GM of a fictional pro team: sim games, manage rosters, draft, sign free agents, handle the salary cap, trade, win championships, build a dynasty across seasons.

It is the professional-league successor to a college football simulator the owner admires (screenshots and full screen inventory in `docs/`). College mechanics (recruiting, redshirts, 4-year eligibility) are replaced by pro mechanics (draft, contracts, cap, free agency, trades).

**Legal guardrail:** All team names, city names, logos, player names, and branding are fictional and original. Never use NFL/NCAA team names, logos, or real player names. Never copy UI assets or text from the reference app — it is design inspiration, not source material.

## Documents (read before coding anything)

| Doc | Purpose |
|---|---|
| `docs/00-EXECUTIVE-PLAN.md` | Master plan: vision, scope, phase sequence, execution process |
| `docs/01-RESEARCH.md` | Reference-app screen inventory, game-family research, community wishlist |
| `docs/02-GAME-DESIGN.md` | The game design document — rules, systems, numbers. Source of truth for gameplay |
| `docs/03-ARCHITECTURE.md` | Tech stack, module layout, data model, sim engine design, persistence |
| `docs/04-SCREENS-UI.md` | Screen-by-screen UI spec |
| `docs/05-IMPLEMENTATION-PLAN.md` | Phased task breakdown; Phase 1 fully specified |
| `docs/06-PLAYED-GAME-MODE.md` | "On the Field" arcade mode (controls, ratings mapping, presentation, legal) |

If a gameplay question isn't answered in `02-GAME-DESIGN.md`, add the answer there first, then implement.

## Process (non-negotiable)

These mirror the owner's established workflow from prior projects: plan → build small → adversarial review → verify → commit.

1. **One phase at a time.** Before starting a phase, run the `superpowers:writing-plans` skill against the phase's spec section in `05-IMPLEMENTATION-PLAN.md` to produce a bite-sized task plan (Phase 1's is already written). Save to `docs/plans/`.
2. **TDD for all engine code** (`superpowers:test-driven-development`). The sim engine is pure Swift with no UI dependency — every mechanic gets a failing test first. UI views may be built without unit tests but must compile and be exercised in the simulator.
3. **Frequent small commits.** One task = one commit. Conventional Commits format.
4. **Adversarial review at phase end.** Run `adversarial-reviewer` (or `/code-review`) on the phase's diff before declaring it done. Fix confirmed findings before moving on.
5. **Verification before completion** (`superpowers:verification-before-completion`): build must succeed, all tests pass, and the feature must be demonstrated in the iOS simulator before a phase closes.
6. **Debugging:** use `superpowers:systematic-debugging` — no guess-fixes.

## Tech stack (decided — don't relitigate)

- Swift 5.10+ / SwiftUI, iOS 17 minimum, Xcode 16+
- Architecture: `@Observable` view models, unidirectional data flow, no third-party dependencies
- Sim engine: standalone Swift Package (`FootballSimCore`) — pure logic, deterministic under a seeded RNG (`SeededRandom`), fully unit-tested, zero `import SwiftUI`
- Persistence: `Codable` JSON save slots in Application Support; versioned `saveFormatVersion` field for migration
- No network, no accounts, no analytics, no ads

## Conventions

- Fictional league: **32 teams, 2 conferences × 4 divisions × 4 teams** (naming tables in `02-GAME-DESIGN.md`)
- Ratings are 40–99 ints; money is integer dollars (`Int`, no floating-point currency)
- Season calendar, cap rules, draft order logic: all constants live in `FootballSimCore/Sources/.../LeagueRules.swift`, never inline magic numbers
- Files small and focused; split by responsibility (model / engine / feature-view)
- Player-facing copy: short, plain, no lorem ipsum — real strings from `04-SCREENS-UI.md`
