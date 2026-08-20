# Floodlit Phase 10 — App Root Authoritative Dark State (Task 12)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make dark appearance and honest unavailable-state handling authoritative at both app roots,
replace 62 copies of a silent-blank pattern with one shared helper, and complete the debug proof
launch seam so a future device-matrix pass can walk every registered surface without a hand on the
device. This is Task 12 of the master plan — the first phase in this cutover that is not a per-family
presentation conversion.

**Architecture:** No new UI vocabulary. `CoachWorldAppRootView.career(_:)` currently repeats `if let
model = store.X { View(...) }` once per registered screen with no `else` branch — a nil model renders
nothing at all, not even navigation chrome. This phase introduces one `surface(_:screen:content:)`
helper that shows `CoachWorldSystemState` instead of silence, and rewrites every one of `career`'s
branches to call it.

**Tech Stack:** Swift 6.3.3 (Swift 5 mode), SwiftUI, the hand-rolled `SimTests` harness, XCTest.

**Spec:** Task 12 of `docs/superpowers/plans/2026-08-15-floodlit-all-surfaces.md`.

## Global Constraints

- Dark-only. No `Palette.light`, no `colorScheme` branch.
- Do not change route eligibility or invent a fallback model — `surface(_:screen:content:)` only
  changes what renders when a model is nil, never which routes are reachable.
- CLAUDE.md scope guard applies as everywhere else, with one deliberate exception this phase names
  explicitly rather than silently exceeding: the master plan's own Step 3 requires touching every
  branch of `career`, not a subset.

## The concurrent-session collision, and the decision to proceed

`CoachWorldAppRootView.swift` is the exact file a separate, concurrent session has queued
uncommitted work on — `stash@{0}`, sitting since early in this session, adding decision-receipt
correspondence to the `.inbox` and `.coachingHQ` (via `default:`) branches. This phase's Step 3
rewrites the outer structure of every branch in `career`, including those two, into
`surface(...) { model in ... }` trailing closures — which reindents everything inside. **Confirmed
with the owner before starting:** proceed with the full refactor now. The stash is unaffected as a
git object (nothing is lost), but it will not `git stash pop` cleanly afterward — reapplying it
against the new structure is deferred to whoever picks that work back up, not something this phase
attempts to pre-merge or guess at.

## Step 1: Impact the root symbols

Run GitNexus upstream impact for `CoachWorldAppRootView`, `career`, `navigate`, `RootView`, and
`DebugCoachingHQRoot` before editing. GitNexus has failed to resolve most `*View` type names by fuzzy
match throughout this cutover — direct source reading is the fallback, and this phase already required
reading the full 1180-line file to plan it. `career` is the single largest blast radius any file in
this app has: it is the only caller of all 62 presentation roots. There is no smaller edit that
satisfies Step 3's actual requirement ("use it for each optional read-model branch"), so the impact
finding here is expected to be repo-spanning by construction, not a signal to re-scope.

## Step 2: One root-level dark commitment, at both roots

**`CoachWorldAppRootView.body`** (the shipped root): wrap the existing `Group { ... }` in
`.preferredColorScheme(.dark)` and a `CoachWorldTokens.dark.page.color` background — added at the
outermost `Group`, not per-branch; this is a guardrail underneath the per-family
`CoachWorldFloodlitStage` wraps, not a replacement for them, so it must not fight with what those
already draw (a plain solid ground behind everything, no gradient/grain of its own — the family views
own that).

**`RootView.body`** (`#if DEBUG` → `DebugCoachingHQRoot()`, else → a bare `ContentUnavailableView`):
this file is a *separate* debug/proof harness — App/ProFootballCoachApp.swift only routes to it when
`PROOF_SCREEN` is set, which is a different, older env-var convention than the `PROOF_SCREEN_NUMBER`
seam Step 5 adds to `CoachWorldAppRootView`. Both its branches need the guardrail: the non-DEBUG
`ContentUnavailableView("No career loaded", ...)` becomes `CoachWorldSystemState(.empty("No career
loaded. Start or load a career to enter the coach's world."), palette: CoachWorldTokens.dark)` inside
a `CoachWorldFloodlitStage`; `DebugCoachingHQRoot.body`'s `Group { if/else if chain }` gets the same
`.preferredColorScheme(.dark)` + page-ground wrap `CoachWorldAppRootView` gets — it is a flat sample-
data harness with no per-screen Floodlit conversion of its own to defer to, so the guardrail here is
the only dark commitment it has.

## Step 3: The `surface` helper and the 62-branch rewrite

Add, in `CoachWorldAppRootView`, next to `career`:

```swift
/// One truthful state for every registered route with no retained read model, in place of the 62
/// copies of `if let model = store.X { View(...) }` with no `else` this file used to carry — a nil
/// model rendered nothing at all, not even navigation chrome. Never invents a fallback model or
/// changes which routes `navigate(_:in:)` considers reachable; it only changes what the glass shows
/// when a reachable route's model has not been retained.
@ViewBuilder
private func surface<Model, Content: View>(
    _ model: Model?,
    screen: CoachWorldScreenID,
    @ViewBuilder content: (Model) -> Content
) -> some View {
    if let model {
        content(model)
    } else {
        CoachWorldSystemState(
            .empty(
                "\(screen.canonicalName) unavailable. No retained career evidence is "
                    + "available for this surface."
            ),
            palette: CoachWorldTokens.dark
        )
    }
}
```

The master plan's own code sample for this helper uses `CoachWorldSystemState(kind:title:detail:)` —
that initializer does not exist. The shipped type (Phase 2) is `CoachWorldSystemState(_ kind: Kind,
palette:)` with `Kind.empty(String)` carrying one message, not a separate title and detail — the same
adaptation every phase since Phase 1 has made when a master-plan code sample predates what actually
shipped. Followed the Phase 4/6 precedent for folding two-part messages into one sentence.

**Every** `case .X: if let model = store.Y { View(model: model, ...) }` in `career` becomes `case .X:
surface(store.Y, screen: .x) { model in View(model: model, ...) }` — the inner `View(...)` call is
untouched byte-for-byte except for reindentation; only the outer wrapping changes. The `default:`
branch (`.coachingHQ`, the fallback for any screen not explicitly cased) becomes `default: surface
(store.coachingHQ, screen: .coachingHQ) { model in CoachingHQView(model: model, ...) }`.

The doc comment immediately above `career` currently reads: "A family with no production view reports
that it has none rather than presenting an empty one." That was true of the silent-blank behavior this
step removes and becomes false the moment `surface` ships — update it to describe what the new
behavior actually is (a truthful unavailable state, not silence) rather than leave a comment
contradicting the code beneath it.

## Step 4: Root contracts

Added to `Tests/SimTests/Suites/ContractTests.swift`, matching this cutover's established pattern of
reading a file's own source text rather than instantiating SwiftUI (the harness cannot render views):

- `CoachWorldAppRootView.swift` contains `.preferredColorScheme(.dark)` at the shipped root.
- `RootView.swift` contains `.preferredColorScheme(.dark)` for both the non-DEBUG and DEBUG branches.
- `CoachWorldAppRootView.swift` contains `private func surface<Model` (the helper exists).
- Every `CoachWorldScreenID` case has a corresponding `case .` (or is covered by `default:`) inside
  `career`'s switch — enumerated from `CoachWorldScreenID.allCases`, by construction, the same
  enumeration discipline `AccessibilityReflowTests.swift` already uses, not a hand-copied list.
- No remaining `if let model = store\.\w+ \{` pattern inside `career` that is not wrapped by
  `surface(` — a source-scan regression test in the same family as the "no design-token literal"
  scans, so a future edit that reintroduces the silent-blank pattern for one screen fails loudly.

Added to `Tests/ProFootballCoachTests/ProFootballCoachTests.swift`, matching its existing minimal
style (`testRootCanBeConstructed`): a construction-only test for `RootView`, since XCTest here has no
SwiftUI-introspection tooling (no third-party dependency) to assert more than "does not crash."

## Step 5: Complete the proof launch seam

`PROOF_NEW_CAREER` already exists (`restoreExistingCareer()`, checked as `!= nil` only) and calls
`beginNewCareerSetup()`, which fetches starting jobs and shows the interactive
`NewCareerCoachIdentityView` — it does not itself start a career. Per the master plan: read
`PROOF_NEW_CAREER`'s *value* as a seed, and when valid and no save exists, obtain the starting jobs for
that seed directly, pick the first, and call the existing `startNewCareer(firstName:lastName:seed:
programmeID:)` — bypassing the interactive setup UI so a screenshot harness can launch straight into a
real, playable career state. Synthetic identity `firstName: "Proof"`, `lastName: "Coach"` — no existing
convention to match (this seam has never been exercised by any test), chosen to read unmistakably as
non-real and gated `#if DEBUG` so it never reaches a release build regardless.

Add `PROOF_SCREEN_NUMBER`, read only in `#if DEBUG`: after a career is loaded or started, if
`ProcessInfo.processInfo.environment["PROOF_SCREEN_NUMBER"]` parses as an `Int` and
`CoachWorldScreenID(rawValue:)` accepts it, set `screen` to that value — preferred over whatever the
restored presentation route would have set, so a proof harness can launch straight into any of the 62
registered surfaces without navigating there by hand. Invalid or out-of-range values are ignored
silently (fall back to the restored route), not treated as a launch failure.

## Step 6: Verify and commit

```bash
swift build
swift run SimTests --core-contracts
swift run SimTests --design-contracts
swift build
```

Run `detect_changes({scope: "unstaged"})` — expect it to report the full blast radius honestly this
time (every one of `career`'s 62 branches genuinely changed), not the under-reporting seen in recent
phases. Then the full suite, adversarial review (this diff is large enough to warrant the same
dimension-reviewer shape as every prior phase, weighted toward structural correctness given the size),
and commit exact task paths as `fix: make Floodlit root states explicit` — the master plan's own
specified message, not this cutover's usual `feat: convert Floodlit ... surfaces` phrasing, because
this phase is not a family conversion.

## What this phase is not

It does not touch any of the 62 already-converted family views. It does not add new Floodlit
vocabulary. It does not resolve the AX5-ground-versus-double-paint tension flagged after Phases 5 and
6 — that remains an open, owner-level question about the Floodlit pattern, orthogonal to what surfaces
when a model is absent.
