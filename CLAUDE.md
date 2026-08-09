# CLAUDE.md — Pro Football Coach (iOS)

Standing rules for every session in this repo. Read this first, every time.

This file owns **conventions, process, stack and the legal guardrail**. It does **not** own the
mission or the definition of done — `docs/08-OPUS5-BUILD-PROMPT.md` owns those. If this file and
`08` ever disagree, `08` wins on mission and done, this file wins on how work is done, and the
contradiction is a bug to fix rather than a judgement call to make.

## What this project is

A **unified college→pro career simulator** for iPhone. One save, one coach: you start in the
college game, you win, you get promoted to the pro league, and your reputation, staff and scheme
identity travel with you. It is a career simulation about *being a coach* — roster construction,
scheme identity, opponent preparation, staff, player development, and the politics of the job.

**You never control a player.** There is no direct control of any athlete at any point. The match
is watched and steered from the sideline, not played. Anything that reads as "the player throws the
pass" is out of scope, and a request for it is a design change that goes through the canon before it
goes through the code.

The match is rendered as a **2D all-22 field in SwiftUI `Canvas` + `TimelineView`**. No SpriteKit,
no Metal, no third-party engine.

## The canon

`docs/DOC-MANIFEST.md` is the index of what is authoritative. **Read it before you trust any
document in this repo.** Every file is marked `RETAINED`, `SUPERSEDED-BY <path>` or `ARCHIVED-TO
docs/archive/<path>`, with a reason. Anything under `docs/archive/` describes a product that was
deliberately abandoned — it is history, not instruction, and following it will actively take you the
wrong way.

The canonical set:

| Doc | Owns |
|---|---|
| `docs/01-RESEARCH.md` | Evidence: the engagement post-mortem, the competitive set, calibration sources |
| `docs/02-GAME-DESIGN.md` | The game — loop, agency model, both tiers, the promotion arc, systems, stakes |
| `docs/03-MATCH-ENGINE.md` | Play resolution, determinism contract, the two-tier model, the calibration harness |
| `docs/03b-ARCHITECTURE.md` | Modules, engine/UI boundary, saves, test architecture |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | The design system and every screen, including the accessibility contract |
| `docs/04b-AUDIT-RUBRIC.md` | The audit rubric every phase gate is scored against |
| `docs/05-IMPLEMENTATION-PLAN.md` | Phases and their gates |
| `docs/06-AUDIT-DISPOSITION.md` | What the prior audit's findings became |
| `docs/OPEN-DECISIONS.md` | D1–D13, each with a falsifier and an instrument |
| `docs/08-OPUS5-BUILD-PROMPT.md` | Mission, done, and the phase-entry contract |
| `PRODUCT.md` | Audience, positioning, the market-gap argument, scope boundaries |

If a gameplay question is not answered in the canon, **answer it in the canon first, then
implement**. A mechanic that exists only in code is a mechanic nobody agreed to.

## Process (non-negotiable)

1. **One phase at a time.** Find the first phase in `05-IMPLEMENTATION-PLAN.md` whose gates are not
   green, execute that phase only, then stop. Do not run ahead into the next phase because the
   context is warm.
2. **Plan before building.** Produce a bite-sized task plan for the phase and save it under
   `docs/plans/`. Use `superpowers:writing-plans` if it is available in your session; if it is not,
   write the plan by hand and label it as manually produced.
3. **TDD for all engine code.** `FootballSimCore` is pure Swift with no UI dependency. Every
   mechanic gets a failing test first. UI views need not have unit tests but must compile, and every
   surface they touch must be listed for the owner's simulator walkthrough.
4. **Frequent small commits.** One task, one commit. Conventional Commits.
5. **Adversarial review at phase end.** Review the phase's diff before declaring it done and fix
   confirmed findings. **An adversarial review is not a build.** Never let one stand in for the
   other, and never describe reviewed-but-uncompiled code as verified.
6. **Verification before completion.** Build green and tests green before a phase closes. Whatever
   you could not run, say so — see *Honesty about verification* below.
7. **Debugging is systematic.** Reproduce, isolate, then fix. No guess-fixes.

### Honesty about verification

The build environment usually has **no Swift toolchain and no simulator**, and
`download.swift.org` is refused by the egress policy. This is normal here, not an emergency.

- Anything that has not been compiled is marked **unverified** in `docs/STATUS.md`, by name.
- "Tests green" means the suite was executed and reported pass counts. It never means the tests were
  read and judged likely to pass.
- Simulator demonstration is an **owner** action. Hand over a written walkthrough script — what to
  open, in what order, what should be true at each step — and do not claim the walkthrough yourself.
- If the toolchain is absent, keep building and label the output honestly. Do not stall, and do not
  quietly downgrade the meaning of "done".

## Tech stack (settled — do not relitigate)

- Swift 5.10+ / SwiftUI, **iOS 17 minimum**, **iPhone only, portrait only**, Xcode 16+
- `@Observable` view models, unidirectional data flow, **zero third-party dependencies**
- Engine: `FootballSimCore`, a pure Swift target — deterministic under a seeded RNG, fully
  unit-tested, **zero `import SwiftUI`**, enforced by a source-scanning test
- Match rendering: SwiftUI `Canvas` + `TimelineView` only
- Persistence: `Codable` JSON save slots in Application Support, with a versioned
  `saveFormatVersion` and a migration path
- Tests: an executable target with the hand-rolled harness in `Tests/SimTests/TestKit.swift`.
  Neither XCTest nor swift-testing ships with the Swift Command Line Tools, so this is not a
  preference — it is the only thing that runs. See D11 in `docs/OPEN-DECISIONS.md`.
- No network, no accounts, no analytics, no ads, no IAP

## Legal guardrail

**Every** team, school, conference, stadium, city identity, player, coach, mark, logo, colour
pairing, fight song, tradition and broadcast identity is **fictional and original**.

Adding college football raises this bar rather than leaving it flat: school trade dress, conference
identity and player NIL are among the most aggressively enforced IP in sport. Out of scope, permanently:

- bundled or downloadable real-name roster files, in any form;
- an importer whose documented purpose is to load real identities;
- a store listing, screenshot or trailer that winks at a real league.

If a feature only works with real identities, say so plainly and propose an original-IP substitute.
If something looks legally borderline, **flag it for the owner to take to counsel** — do not resolve
it yourself and do not quietly drop it.

Two parts of this guardrail are **tests**, and they run in CI-equivalent position on every phase that
touches generation:

1. **Name collision test** — no generated team, city, school, conference, stadium, player or coach
   name matches an entry in the maintained blocklist, at any seed, across N generated leagues.
2. **Trade dress test** — no generated primary/secondary colour pair falls within the stated ΔE of a
   real programme's known pair.

Everything else in this section is a **review checklist item, not an assertion**. Say so when
reporting; do not let prose imply coverage that no test provides.

## Conventions

- Ratings are 40–99 `Int`. Money is integer dollars — never floating point currency.
- Constants live in `LeagueRules.swift` (and its college counterpart). **A magic number in a call
  site is a defect.**
- A literal spacing, radius or font size in a view is a defect — use the design tokens.
- Files stay small and single-purpose. Split by responsibility: model / engine / feature view.
- Player-facing copy is short and plain, taken from `04-UX-AND-DESIGN-SYSTEM.md`. No lorem ipsum.
- Seeds derive from **identifier bytes, never `hashValue`**. Swift salts hashing per launch; the
  prior build shipped a generator seeded from `UUID.hashValue` and produced a different league every
  app start from the same save. A source-scanning test forbids reintroduction.

## Scope guard

Build what the current phase specifies. No unrequested refactors, no opportunistic rewrites of
neighbouring systems, no "while I was in here". If you find something genuinely broken outside the
phase, write it down in `docs/STATUS.md` and keep going.

## Escalate, don't improvise

Stop and ask the owner when:

- an item in `docs/OPEN-DECISIONS.md` is marked **blocking** and you have reached it;
- two canon documents contradict each other;
- a phase gate fails repeatedly and the fix would change a decision in the canon;
- the toolchain is absent and the phase's gate depends on running something.
