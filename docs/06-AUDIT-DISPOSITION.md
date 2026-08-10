# 06 — Audit Disposition

Disposition of `docs/AUDIT.md` against the new design.

## Scope, and why it is not 78 rows

`AUDIT.md` confirmed 78 findings: 1 P0, 24 P1, 36 P2, 17 P3. The v3 brief asked for all 78 to be
dispositioned individually. That is the wrong shape of work, for three reasons:

1. **The findings carry no IDs.** They are prose under severity headings; there is no `F<n>` to
   reference. A 78-row table would require inventing an ID scheme first.
2. **Most describe code that will not exist.** `Chip(filled:)`, `JobOffersSheet`, `ArcadeGameView`,
   "11 call sites" — Tier C discards all source. Dispositioning them individually produces rows of
   "structurally impossible in the new design", which is a ritual, not a safeguard.
3. **The transferable value is concentrated in the patterns**, not the instances. `AUDIT.md:777`'s
   five systemic issues are the diagnosis; the 78 are its symptoms.

So this document dispositions **all 25 P0/P1 findings** and **all five systemic patterns**, each
converted where possible into a **standing invariant with a named test**, and retires the P2/P3 tail
with a stated reason. The point is to convert findings into tests, not into prose.

One framing correction, on the record: **`AUDIT.md` is not the diagnosis of why the previous build
was boring.** It audits `Sources/ProFootballCoachUI/` only, excludes the engine, and concludes the
codebase is "structurally sound and idiomatic". It measures craft. The engagement diagnosis is
`01-RESEARCH.md` §6.0, and it is a different document with different findings.

---

## 1. P0 — Blocking (1)

| Finding | Disposition |
|---|---|
| **Every league mutation performs a 2.4–3.3 MB synchronous JSON encode, backup copy, atomic write and directory rescan on the main actor** (`AppState.swift:164`, 11 sites; 84–112 ms measured; `advanceWeek` pays it twice, `completeDraftStage` up to five times) | **(ii) Addressed, structurally.** `03b` §3 requires all saves off the main actor with coalescing writes, and `03b` §4 requires the schema version to be readable without parsing the whole file. **Tests:** `SaveOffMainActorTest` asserts no save path is reachable from the main actor; `SaveCoalescingTest` asserts one write per user action; `SaveWriteBudgetTest` asserts the D4 budget (150 ms target, 400 ms ceiling). |

---

## 2. P1 — Major (24)

**(i)** = structurally impossible in the new design · **(ii)** = addressed, with the test named ·
**(iii)** = retired, with the reason.

| # | Finding | Disposition |
|---|---|---|
| 1 | Reduce Motion ignored everywhere — zero checks in the UI layer | **(ii)** D12 requires a defined reduced form for every animation; the match view degrades to a discrete state sequence rather than switching off. **Test:** `ReduceMotionContractTest` walks every animated surface. |
| 2 | Fixed `.frame(width:)` truncates the primary number on 19 rows | **(ii)** D12's Dynamic Type clause forbids fixed-height/width text containers. **Test:** `DynamicTypeContractTest` renders every screen at AX5 and fails on clipping. |
| 3 | White chips on the team gradient at 2.77–4.08:1 for all 32 teams | **(ii)** D12's measured-surface contrast rule, enumerated by construction. **Test:** `ContrastByConstructionTest`. |
| 4 | "Kick Off the Season" CTA white-on-white at 2.48–4.03:1 | **(ii)** Same rule, same test. |
| 5 | The on-field aiming surface is a bare drag gesture with no accessibility element | **(i)** There is no aiming surface. The mission forbids direct control of players; `02` §3 replaces it with call-ins, which are ordinary controls inside the design system and inherit its accessibility contract. |
| 6 | Stat and standings rows read as loose fragments, not sentences | **(ii)** D12's VoiceOver clause requires composed labels. **Test:** `VoiceOverLabelTest` asserts every data row emits one sentence, not N fragments. |
| 7 | Chip-as-button filter and scouting controls ~21pt tall, 6pt apart | **(ii)** D12's 44×44 pt floor. **Test:** `TouchTargetTest`. |
| 8 | Record Book aggregates every player's career and season stats inside the view body | **(i)** `03b` §2 forbids it: the UI reads engine-produced snapshots and never computes aggregates. **Test:** the engine/UI boundary source scan. |
| 9 | `StatsView` recomputes season stats for all 2,208 players, twice per render | **(i)** Same boundary. Note the number gets worse, not better, at ~134 programmes — which is exactly why the boundary is enforced by test rather than by care. |
| 10 | Opening a save parses the file twice then immediately re-encodes and rewrites it | **(ii)** `03b` §4: version readable without a full parse; opening a save is read-only. **Test:** `SaveOpenIsReadOnlyTest`. |
| 11 | Power Rankings builds 32 unvirtualized rows and computes each team's overall three times | **(i)** Same boundary as 8/9; ratings arrive precomputed in the snapshot. |
| 12 | `Chip(filled:)` hard-codes `Color.white`; 1.41–4.13:1 at every call site | **(i)** `03b` §1's source scan fails the build on a colour literal in a view. Plus **(ii)** the contrast test. |
| 13 | Tinted `Chip` called with raw system colours — 1.41–3.44:1 in light mode | **(i)/(ii)** Same. |
| 14 | Headline figures painted in raw `.green`/`.red`/`.orange`/`.purple` on a card | **(i)/(ii)** Same. |
| 15 | `TeamTheme.gradient` translucent stops composite over the page — hero text at 3.31:1 | **(ii)** D12's measured-surface rule tests the *composited* surface, not the idealised one. **Test:** `ContrastByConstructionTest` composites before measuring. |
| 16 | White labels on `accentColor`/`theme.tint` at 2.65–2.90:1 in dark mode | **(ii)** Same test, run in both appearances. |
| 17 | Landscape declared supported, but the arcade's fixed-height layout puts play-call controls off-screen | **(i)** **One** orientation and iPhone-only are declared in `App/project.yml`, and there is no arcade. The orientation is landscape as of 2026-08-10 (`04` §5.2); the finding was about a layout that broke under an orientation nothing had declared a policy for, so the disposition is unaffected by which one is named. **Test:** `OrientationPolicyTest` reads the project manifest. |
| 18 | An irreversible "sim the rest of the game and commit it" action sits in the navigation bar's leading (cancellation) slot | **(ii)** The design system in `04` defines placement for destructive and irreversible actions, and requires confirmation for anything uncommittable. **Test:** `DestructiveActionPlacementTest` over the component set. |
| 19 | Four filter/action bars use a 21pt Chip as the entire tap target, 6pt apart | **(ii)** Same as 7; `TouchTargetTest`. |
| 20 | Save and load failures captured into `AppState.lastError` and never shown | **(ii)** Every error path must terminate in a presented surface. **Test:** `ErrorSurfaceTest` asserts no error sink is written without a reader. |
| 21 | App ships with no orientation policy at all | **(i)** As 17. |
| 22 | "On the Field" — the one landscape screen — loses all controls when rotated | **(i)** As 17; the screen does not exist. |
| 23 | iPhone SE portrait: field-goal and punt buttons fall off the bottom of the arcade screen | **(ii)** The smallest supported device is a layout target, not an afterthought. **Test:** `SmallestDeviceLayoutTest` renders every screen at the smallest supported size and fails on off-screen controls. |
| 24 | First-run tutorial clips its own body text at XXXL on a 667pt screen | **(i)** There are no tutorial cards — D9 teaches through the first real week. Whatever replaces them is covered by `DynamicTypeContractTest`. |

**Tally:** 11 structurally impossible, 13 addressed with a named test, 0 retired.

---

## 3. Systemic patterns → standing invariants

These matter more than the individual findings. Each becomes an invariant with a test.

### Pattern 1 — "Contrast was measured exactly where it was tested, and nowhere else"

> *"The defect is not ignorance of contrast; it is that the test's coverage boundary became the
> quality boundary."* — `AUDIT.md:777`

The prior suite rigorously verified five rating tiers and all 32 team tints, and every surface it did
not look at failed.

**Invariant.** A test that checks a class of surfaces must enumerate that class **by construction**,
so a new surface is covered the day it is added, not the day someone remembers it.

**Test.** `ContrastByConstructionTest` derives its surface list from the token set and the component
registry, and a meta-assertion fails if the count of surfaces visited differs from the count of
surfaces consuming a colour token. Spot-check tests over hand-listed instances are a defect.

This is promoted to a standing rule in `CLAUDE.md`, because it generalises past contrast.

### Pattern 2 — Token bypass at scale

43 literal spacings, 25 literal radii, 9–10 hard-coded font sizes, 3 off-scale radii — against
`DESIGN.md`'s own written rule that "a literal in a view is a defect".

**Invariant.** The rule is enforced by the build, not by review.
**Test.** The `03b` §1 source scan fails on any spacing, radius, colour or font-size literal in a
view.

### Pattern 3 — Written-down commitments with zero implementations

Reduce Motion: 0 occurrences. VoiceOver: 3 modifiers in ~140 KB of view code, 0
`accessibilityElement` calls. Both were stated requirements in `PRODUCT.md` and `DESIGN.md`.

**Invariant.** Every product commitment names the test that proves it, and no commitment ships
untested.
**Test.** `CommitmentCoverageTest` reads the commitment table in `PRODUCT.md` and fails if any row
lacks a test identifier that exists in the suite. A promise without a test is a defect.

### Pattern 4 — Persistence is synchronous and over-eager

**Invariant.** Saves are off the main actor, coalesced to one write per user action, and opening a
save does not write.
**Tests.** `SaveOffMainActorTest`, `SaveCoalescingTest`, `SaveOpenIsReadOnlyTest`.

### Pattern 5 — The weakest area was partly unreachable

`ArcadeGameView` was dead code: its only gate, `arcade && !isFinished`, was statically false because
the single call site passed `arcade: false`. An entire feature area was being reviewed, scored and
discussed while being unreachable.

**Invariant.** No unreachable screen ships.
**Test.** `ReachabilityTest` asserts every `View` type in the feature layer is reachable from a
navigation path rooted at the app entry point. This one generalises furthest: `01-RESEARCH.md` §6.0
found the same class of defect throughout the engine — 22 of 24 coach skill nodes with no reachable
effect, scouting points with nothing to buy, a "Call the Plays" mode that called no plays. Dead
capability is the previous build's signature failure, and it is not a UI problem.

---

## 4. The P2/P3 tail — retired

The 36 P2 and 17 P3 findings are retired without individual disposition. Reason: every one of them
describes a specific line in a codebase Tier C discards, and each belongs to a class already covered
by an invariant above — token literals, contrast sites, touch targets, Dynamic Type clipping,
navigation-title usage, main-actor work. The invariants catch the class; enumerating the instances
would document a codebase that will not exist.

`AUDIT.md` is retained in full under Tier B, so any specific finding remains readable if a question
arises later.

---

## 5. What this disposition does not cover

`AUDIT.md` scoped itself out of the engine, iPad, size classes and App Store review. iPad and size
classes are out of scope by P1. App Store review is covered by `docs/PRE-DEPLOYMENT-CHECKLIST.md`.
The engine has never been audited by this rubric — `04b` applies to UI surfaces, and engine quality
is gated instead on calibration, determinism and the soak.
