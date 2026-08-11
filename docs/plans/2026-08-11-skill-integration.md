# Development skill integration and creation plan

Authority: supporting execution plan for `docs/05-IMPLEMENTATION-PLAN.md`, the active M3 plan, and
future M4–M9 milestone plans. Skills guide development and verification; they do not override the
game design, architecture, test harness, deterministic contracts, or owner decisions.

## Platform contract

- Minimum OS: iOS 26.
- Supported and release-tested hardware: iPhone 15 generation and newer, landscape only.
- Performance baseline: physical iPhone 15/A16 or a slower supported-generation device if one is
  measured later.
- Layout floor: 844 × 390 points because later compact `e` models are smaller than the base iPhone
  15. The UI also renders the largest supported Plus/Pro Max class.
- Pre-iPhone-15 devices have no compatibility promise or layout gate, even if iOS 26 permits them to
  install the app.
- Third-party skills are developer tooling only. They add no package, framework, runtime code,
  network capability, analytics, or other app dependency.

## Installed external skills

Installed globally in `~/.codex/skills` on 2026-08-11. They become discoverable in a new Codex turn.

| Skill | Source revision | License |
|---|---|---|
| `ios-simulator-skill` | `conorluddy/ios-simulator-skill@e0ee87a884b438632238ef8ab42139797f8638a8` | MIT |
| `swiftui-expert-skill` | `AvdLee/SwiftUI-Agent-Skill@572c7e1f1ad29ab2fa4683474bd0d120eed4932d` | MIT |
| `ios-accessibility` | `dadederk/iOS-Accessibility-Agent-Skill@dcc3a36ce1d0099341d545c1af4eb5a8c989bf66` | MIT |
| `swift-concurrency-pro` | `twostraws/Swift-Concurrency-Agent-Skill@bee3f69ba17142da148d3c5406f148ed62592b69` | MIT |

The installed simulator copy removes only the upstream top-level `version:` metadata key so it
passes Codex's current skill schema; its instructions and scripts match the recorded revision.
The installed concurrency copy removes the upstream Claude plugin manifest and duplicate nested
wrapper so Codex discovers one plain `swift-concurrency-pro` skill; its instructions and references
remain unchanged.

| Skill | Activate for | Required use | Boundary that prevents duplication or drift |
|---|---|---|---|
| `swift-concurrency-pro` | M3 Task 5 atomic portal work, M3 Task 6 scheduler/intent boundaries, and later actor-based persistence | Review actor isolation, reentrancy, cancellation, structured tasks, and `Sendable` boundaries before each relevant milestone exits | The project remains in Swift 5 language mode until a separate migration is approved. Do not introduce Swift-6-only syntax merely because the skill prefers it, and keep the existing TestKit harness rather than adopting Swift Testing. |
| `swiftui-expert-skill` | Production UI foundation through match presentation and feature surfaces | Route state ownership, layout, animation, invalidation, and trace-driven performance work through the relevant references; profile before speculative optimization | This is the single SwiftUI umbrella. Do not also install separate SwiftUI animation, performance, UI-pattern, or “pro” bundles. It cannot change the engine/UI contract or select an architecture for the project. |
| `ios-accessibility` | UI foundation and every feature surface | Review VoiceOver, Dynamic Type AX5, Reduce Motion, Voice Control, Switch Control, focus, localization, contrast, and 44-point targets while each component is built | This owns user-experience guidance. Automated audit output is evidence, not a substitute for the manual VoiceOver and owner walkthrough gates. |
| `ios-simulator-skill` | Once the Xcode app target has real UI, then every UI milestone and pre-deployment | Build and launch, navigate semantically, set AX5/appearance, capture the accessibility tree, record evidence, compare screenshots, inspect logs, and watch hangs | This owns simulator operation, not SwiftUI design advice. Never run bulk simulator delete/erase operations without explicit approval. Accept only generated `xcresult-*` IDs; do not pass untrusted IDs to cache lookup commands. |

The deliberately excluded alternatives are Axiom simulator tooling, separate dpearson/Dimillian
SwiftUI packs, SwiftUI Pro, SwiftData persistence skills, generic game-development skills,
SpriteKit/Godot skills, and third-party snapshot-test packages. They either duplicate the four
skills above, conflict with the architecture, or add a dependency the app does not need.

### Installation risk boundary

All four sources are active, non-archived, single-maintainer repositories. The two guidance-only
skills add no executable code. The SwiftUI skill executes only local `xctrace` analysis/recording.
The simulator skill has the widest authority: it invokes Xcode/simulator commands, maintains local
caches, and exposes destructive simulator delete/erase modes. Therefore use generated identifiers
only, treat bulk lifecycle commands as destructive actions requiring explicit approval, and never
run these tools on user data or a physical-device container without resolving the exact target.
No installed script was executed during installation.

## Milestone activation map

### M3 — college management, now

Use `swift-concurrency-pro` for the atomic portal transaction and scheduler/intent boundary. The
review is additive to the existing deterministic, hostile-decode, integrity, and TestKit gates; it
does not replace them. The other installed skills remain dormant because the production UI target
is intentionally empty.

### M4 tactical integration and detailed-engine calibration

Create `.agents/skills/calibrate-football-simulation/` after the tactical/outcome schema and causal
metrics are fixed, but before changing calibration constants. It must encode the existing TOST,
A/B seed ladder, holdout, two-tier consistency, 20-season soak, performance, determinism, causal
explanation, and “fix model shape before constants” contracts. Validate it against one known failing
band and one holdout regression before using it to tune the detailed engine.

### Production UI foundation — P11-equivalent milestone

Before the first production component is implemented:

1. Create `.agents/skills/verify-ios-accessibility-matrix/` from `04` §6 and the platform matrix in
   this plan. It must enumerate device class × appearance × default/AX5 type × VoiceOver × Reduce
   Motion × representative state, produce an evidence manifest, and distinguish automated from
   owner/manual assertions.
2. Activate `swiftui-expert-skill` and `ios-accessibility` while implementing tokens and components.
3. Activate `ios-simulator-skill` once the app target can launch. Capture semantic trees and AX5
   screenshots at the 844 × 390 floor and largest supported class; do not establish baselines from
   an empty or placeholder UI.

The accessibility-matrix skill is complete only when its matrix is derived from the component and
screen registries rather than a hand-maintained list, so new surfaces enter the gate automatically.

### Match-presentation milestone — FSC-011 / P13-equivalent

Create `.agents/skills/render-recorded-match/` after the immutable movement/decision anchor schema
and render-cannot-change-outcome test exist, but before the first `Canvas`/`TimelineView` match
implementation. It must require recorded outcomes as the sole choreography input, deterministic
frame sampling, no simulation imports in the UI, a discrete Reduce Motion sequence, per-snap
VoiceOver sentences, stable replay screenshots, and a physical-device frame-budget trace.

Use `swiftui-expert-skill` for view invalidation/animation and Instruments evidence,
`ios-accessibility` for the equivalent nonvisual experience, and `ios-simulator-skill` for playback
evidence. None of those external skills may relax the project-local render boundary.

### M9 persistence and durability

Create `.agents/skills/persist-game-state-safely/` at milestone entry, after inventorying every
existing schema fixture and measured save-size checkpoint, but before changing the on-disk format.
It must encode header-first validation, bounded hostile decode, forward-only single-step migrations,
gzip, atomic replace, one backup, coalesced off-main writes, recovery drills, size/growth budgets,
cross-process fingerprints, and preservation of unknown/defaulted fields where the schema permits.

Use `swift-concurrency-pro` for the persistence actor and cancellation/reentrancy review. Reject any
generic persistence recommendation that introduces SwiftData/Core Data, writes from the main actor,
skips a version boundary, or replaces the hand-rolled test harness.

### Pre-deployment

Run the accessibility matrix across the supported device classes, archive semantic trees,
screenshots and hang/trace summaries, and perform the manual VoiceOver, field-readability,
onboarding, and first-hour owner walkthroughs. No skill may turn an owner-verifiable gate into an
agent assertion.

## Project-local skill creation gate

Each scheduled skill must be initialized with the system `skill-creator`, contain only `SKILL.md`
plus necessary `references/`, `scripts/`, or `assets/`, and pass `quick_validate.py`. Its triggering
description must name the relevant project phase and invariant. Forward-test it against a real
repository task before the phase relies on it; compare the result with the authoritative project
tests and documents rather than with the skill author's expected answer.
