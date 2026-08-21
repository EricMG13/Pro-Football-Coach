# Confidence review — whole codebase and all branches

**Date:** 2026-08-20
**Scope:** `agent/floodlit-injury-evidence` @ `c0f4334` plus its uncommitted working tree, all 46
remote branches compared against `origin/main`, and the whole of `Sources/` (300 Swift files,
96,534 lines).
**Method:** static review plus a real toolchain. Swift 6.3.3 was available, so the package was
built (`swift build -c release -Xswiftc -enable-testing`, **exit 0**) and suites were executed.
Every claim below is either a captured command output, a byte/line count taken from the tree, or an
arithmetic consequence of one. Where a claim is unverified it says so.
**No source code was changed by this review.**

**Runs completed for this review:**

| Run | Result |
|---|---|
| `swift build -c release -Xswiftc -enable-testing` | exit 0, ~10 min |
| Default suite (the lane CI runs) | **964 tests, 787,761 checks — 1 failing test, 2 failed checks**, both F1. 54.5 min. |
| `--architecture-only` | 25 tests, 222 checks — the same 2 failures |
| `--calibration` | 20 tests, 164 checks, all passed (see F19 for what that does *not* mean) |
| `--m3-soak` with `M3_SOAK_SEASONS=5`, twice | 2,301 checks — 2 failed, both save size. Byte-identical state across both processes. |

**The whole default suite has exactly one failing test, and it is F1.** Everything else in
`Sources/` that this suite covers is green. That is worth saying plainly: the findings below are
almost all about assertions that were never written, not about code that is broken.

---

## Summary

Twenty-three findings. Two are already on the record and are corroborated here with independent
measurement rather than re-reported as new. The other twenty-one are new.

Five are worth reading first.

**The branch does not pass its own determinism gate.** `--architecture-only` fails two checks, and
the cause is a single commit that re-pinned one of the two pin files. CI runs exactly the lane that
contains this test, so the branch cannot go green on a pull request. (F1)

**The calibration gate does not measure calibration.** `CLAUDE.md` §5 names "calibration bands" as a
machine gate. The harness runs, computes a `passed` flag for every band, and no test in the
repository ever reads it. A band can be violated by any margin and the suite stays green. (F19)

**Three of D4's seven performance budgets are over their hard ceilings, measured.** A 5-season M3
soak on this tree, reproduced in two processes: 150.7 s per college season against a 35 s ceiling,
and the 8 MB save ceiling breached at **season 4** rather than season 20 — on a Mac, not the A16 the
budgets are written for. The compaction work this branch exists to deliver does not reach its
target. (F17)

**The 164 MB logo set renders on exactly one world seed.** Marks are looked up by seed-derived team
UUID, the catalogue holds only the 166 from seed 20,260,812, and the New Career screen has an
editable "World seed" field. Any other seed shows text chips for all 166 teams and carries the
164 MB anyway. Every logo test bootstraps `manifest.worldSeed`, so no test can see it. (F22)

**The in-flight people-compaction work deletes the only authority the coaching tree reads**, and a
second branch attacking the same problem identified that requirement and protected against it. The
new soak assertions codify the unprotected behaviour as correct. (F3, F4)

| # | Finding | Severity | State |
|---|---|---|---|
| F1 | Branch HEAD fails the cross-process determinism pins | P0 | **Confirmed by run** |
| F2 | 164 MB of 1024x1024 logos, mandated by plan and pinned by test | P0 | Corroborated (known) |
| F3 | Compaction deletes the coaching tree's only authority | P1 | **Confirmed** |
| F4 | Two competing staff-prune implementations will collide | P1 | **Confirmed** |
| F5 | `referencedEntityIDs`'s `default: []` now gates deletion | P1 | **Confirmed** |
| F6 | Trademark screen no longer describes the names it screens | P1 (legal) | **Confirmed** |
| F7 | `Akron` is in the place pool and absent from the blocklist | P1 (legal) | **Confirmed** |
| F8 | CI runs one lane; the iOS app is never compiled in CI | P1 | **Confirmed** |
| F9 | Index and working tree disagree; `git commit` ships a reverted change | P2 | **Confirmed** |
| F10 | Branch is 138 commits behind main, 454 files differ | P1 | Corroborated (known) |
| F11 | Five open branches carry competing `PeopleState` retention models | P2 | **Confirmed** |
| F12 | Quarantined saves are unbounded and invisible | P3 | **Confirmed** |
| F13 | `rosterTargets` not asserted exhaustive while its siblings are | P3 | **Confirmed** |
| F14 | Agent tooling directories untracked and unignored | P3 | **Confirmed** |
| F15 | Concurrent agent sessions in one working tree kill test runs | P2 (process) | **Observed** |
| F16 | Widened prospect retention can make `advanceWeek` throw | P1 | **Confirmed by inspection** |
| F17 | Three D4 budgets measured over their hard ceilings | P0 | **Measured** |
| F18 | No programme in the world ever redshirts anyone | P1 | **Measured** |
| F19 | The calibration bands are measured and never asserted | P1 | **Confirmed by run** |
| F20 | `SuiteCatalog`'s lane vocabulary is not `verify.sh`'s | P3 | **Confirmed** |
| F21 | College has half the calibration bands of pro, and nothing checks | P2 | **Confirmed** |
| F22 | The 164 MB logo set works on exactly one world seed | P0 | **Confirmed** |
| F23 | The generated logo catalog holds 166 stale team names | P2 | **Confirmed** |

---

## F1 — Branch HEAD fails the cross-process determinism pins (P0)

**Evidence.** Built release binary, run from the repo root:

```
[FAIL] Authoritative game state — 9 tests, 2 failed checks
  FAIL Authoritative game state / root and scheduler fingerprints are pinned across processes:
       expected 3251160748987753141, got 2399181485827482543  [ArchitectureTests.swift:83]
  FAIL Authoritative game state / root and scheduler fingerprints are pinned across processes:
       expected 11229646605763785595, got 10425352982328808663 [ArchitectureTests.swift:84]
```

**Root cause.** `c6e2d21 feat: use real places and generic postseason names` is the **only** commit
on this branch that touches `Sources/FootballSimCore/Generation`, `.../Model` or `.../World`
(`git log --oneline main..HEAD -- <those paths>` returns exactly one line). It rewrote
`NameGrammar`, which every programme, region and city name comes from, and it updated
`GenerationTests`' `PINNED_WORLD_BYTES` (824,922 → 825,480) and `PINNED_WORLD_DIGEST`. It did not
update `ArchitectureTests`' `pinnedRootFingerprint` / `pinnedAdvancedRootFingerprint`.
`git log --oneline main..HEAD -- Tests/SimTests/Suites/ArchitectureTests.swift` is empty: no commit
on this branch touched that file at all.

Line 83 is the **root** fingerprint, hashed from `GameState.bootstrap(seed: 20_260_810)`, which
calls `LeagueGenerator.generate`. None of the uncommitted working-tree changes participate in
bootstrap, so this failure is present at committed HEAD, not only in the working tree. Line 84
(advanced) moves for the same reason plus the uncommitted compaction.

Two pins assert the same class of fact — "generation did not move" — and only one was refreshed.

**Blast radius.** `.github/workflows/tests.yml` runs `./scripts/verify.sh` with no arguments, which
is the `full` lane, which is `swift build` plus the no-flag SimTests run — the run that contains
this suite. The branch is red on any PR.

**And it is the only thing red.** The complete default suite finished at **964 tests, 787,761
checks, 1 failing test, 2 failed checks** — these two. Nothing else in the lane fails. So this is a
one-line-each fix standing between the branch and a green PR, and it is worth doing carefully rather
than quickly (see the "do not fix on the branch" note below).

**Do not fix on the branch.** See F10: `main` carries entirely different pin values
(`13_271_746_992_715_500_232` / `2_051_777_162_885_451_912`) and 275 more lines in the same test
file. Re-derive both pins from **one deterministic run on the merged tree**, reproduced in two
independent processes, as the file's own docstring requires.

---

## F2 — 164 MB of 1024x1024 logos, mandated by plan and pinned by test (P0, corroborated)

Already `P0-1` in `docs/reviews/2026-08-20-swiftui-performance-audit.md`. Independent measurement
here agrees exactly (its 156.2 MB is MiB; this is the same bytes):

- 166 PNGs, **every one 1024 x 1024, 8-bit, PNG colour type 6 (truecolour + alpha)**, read from the
  IHDR of each file.
- **163.7 MB** on disk (156.1 MiB). Decoded, 4.2 MB each; 696 MB if all resident.
- Each imageset declares one `"scale":"1x"` universal entry — no `2x`/`3x`, so App Thinning cannot
  reduce the download.
- `CoachWorldTeamLogo` draws them at `compact = 20`, `medium = 32`, `large = 44` points.
- `Sources/` is **158.8 MB of the repo's 178 MB of tracked bytes — 89%**.

**What is new here:** the dimension is not a deviation to correct. It is specified —
`docs/superpowers/plans/2026-08-20-canonical-team-logos.md` line 15: *"Source art: exactly 1024 x
1024 transparent PNG files"* — and it is **pinned by a test in the default suite**:
`expectEqual(properties[kCGImagePropertyPixelWidth] as? Int, Optional(1024))`. There is no
downscale-for-ship step anywhere in the plan. Any remedy has to move the plan, the test and the
assets together; changing the assets alone turns the suite red.

---

## F3 — The compaction deletes the coaching tree's only authority (P1, new)

**What the code does.** The uncommitted `WorldScheduler.compactHistoryBoundState` (originating on
`origin/codex/people-compaction-wip`) runs on every week advance and prunes both `state.staff` and
`people.staffCareers` to:

```
history-referenced IDs  ∪  programme.staffIDs  ∪  proTeam.staffIDs  ∪  career.coachID
```

**Why that is wrong.** `CoachingTreeReadModel.build(from:)` reads **only**
`state.people.staffCareers`. Its own docstring names it: *"`PeopleState.staffCareers` is the
authority"*. A coaching tree is by definition about coaches who have moved on; the retention set
keeps only coaches who are currently seated.

**Why history retention cannot save it.** Retention through events would require `staffHired`
(weight 35) to survive. It cannot:

- `DomainEventLedger.recent` is a flat FIFO of **all** events at `retentionLimit = 4_096`. The
  ledger's own comment records the scale: *"A season archives roughly 70,000 events into 32
  slots."* So `recent` is roughly three weeks deep.
- `SeasonHistoryDigest.maximumNotableEvents = 32`, filled by `historicalWeight` rank.
- `ProRules.draftPickCount = draftRounds (7) * draftPicksPerRound (teamCount, 32) = 224`
  `proDraftPick` events per draft season at weight **50**, plus `seasonCompleted` 100,
  `worldCreated` 90, `postseasonScheduled` 80, `realignment` 75 and four kinds at 60.

224 events at weight 50 fill 32 slots on their own. **No `staffHired` event ever reaches an
archived season digest.** A coach who loses their seat therefore has no retained reference within
weeks, and their `Staff` entity and `StaffCareerRecord` are deleted at the next week advance.

**Consequence.** The coaching tree silently and permanently degrades to relationships between
coaches who are *both currently employed*. Retired mentors vanish as tree nodes; where a name is
still reachable, `CoachingTreeReadModel.name(of:in:)` renders `"Former coach"`.

**Why no test sees it.** All eleven tests in `CoachingTreeTests` construct synthetic
`staffCareers` via `coachingTreeState(careers:)`. Not one runs a season and then derives a tree.

**The new tests assert the loss as correct.** `M3CollegeSoakTests` now asserts
`expectEqual(Set(state.people.staffCareers.keys), Set(state.staff.ids))` and
`expect(Set(state.staff.ids).isSubset(of: retainedStaffIDs))`; `PeopleLifecycleTests` asserts
`compacted.staffCareers[staleStaffID] == nil`.

**Independent corroboration.** `origin/claude/coach-career-promotion-integrity-f10168`
(`4644809 fix: carry coach records and prune seatless staff`) attacks the same problem and
*does* protect the tree — `SeasonLifecycleSystem.pruneSeatlessStaff` builds
`CoachingTreeReadModel.build(from: projected)` and unions every `branch.mentorID` and
`disciples.staffID` into `protectedIDs` before removing anything. Two agents reached the same
problem; only one protected the read model.

**Residual risk in the better implementation:** protection there is bounded by
`CoachingTreeReadModel.maximumBranches = 256` and `maximumDisciplesPerBranch = 16`, so a mentor who
falls out of the top-256 branches loses protection too.

---

## F4 — Two competing staff-prune implementations will collide on merge (P1, new)

- `codex/people-compaction-wip` prunes **every week**, in
  `WorldScheduler.compactHistoryBoundState`.
- `claude/coach-career-promotion-integrity-f10168` prunes **at season rollover**, in
  `SeasonLifecycleSystem.pruneSeatlessStaff`, and restructures the same
  `WorldScheduler.advanceWeek` season-end block (+42 lines, including moving the
  `SeasonLifecycleSystem.advance` call).

Merged naively, the world gets two prunes with different retention sets. The weekly one runs far
more often and has the weaker set, so it wins: the tree protection the other branch added would be
undone before it could matter. These two branches must be reconciled as one design, not merged in
sequence.

---

## F5 — `referencedEntityIDs`'s `default: []` now gates deletion (P1, new)

`DomainEventPayload` has 39 cases.

| Member | Cases covered | Has `default` |
|---|---|---|
| `historicalWeight` | 39 / 39 | **no** — a new case cannot compile without a rank |
| `referencedEntityIDs` | 31 / 39 | yes |
| `referencedProspectIDs` | 4 / 39 | yes |

The eight cases that fall through `referencedEntityIDs`' default — `worldCreated`,
`integrityChecked`, `weekAdvanced`, `portalWindowCompleted`, `proMarketOpened`, `proDraftStarted`,
`proWaiversResolved`, `proMarketClosed` — genuinely carry no entity identifiers, so the function is
**correct today**.

What the diff changes is its *consequence*. Before, `referencedEntityIDs` fed only
`WorldIntegrity`'s dangling-reference check and `CoachWorldInboxProvider`'s filter — both read-only.
Now it decides which players and staff are **deleted**. A future payload case that carries an
identifier and is not added to this switch will silently delete the entity it names, and
`WorldIntegrity.swift:436` cannot catch it because that check reads the same function.

The same shape appears in the pruner's award retention: it hand-filters
`award.kind == .playerOfTheYear`. `SeasonAwardKind` is `CaseIterable` with three cases;
`champion` and `topOffense` carry *team* identifiers and teams are never pruned, so it is correct
today — and a future player-referencing award kind silently loses its winner.

This is the exact defect `CLAUDE.md` names under Conventions: *"the test's coverage boundary became
the quality boundary."* An exhaustive switch (the pattern `historicalWeight` already uses) turns
both into compile errors.

---

## F6 — The trademark screen no longer describes the names it screens (P1, legal, new)

`c6e2d21` rewrote the **Executive result** and **Recommended product rule** of
`docs/reviews/2026-08-20-team-name-and-trademark-screen.md` to describe `City, ST` naming, and left
the **Risk tiers** section untouched.

Those risk tiers still name and propose renames for five specific team names:

> Harrow Springs West, Harrow Bluff Thunder Otters, Central Harrow Gate, Harrow Harbor West,
> Harrow Basin Kindled Ironsides

The same commit deleted the `placeStems` array those names came from.
`grep '"Harrow' Sources/FootballSimCore/Generation/NameGrammar.swift` returns nothing, and the
current manifest reads `Altus, OK City College`, `Franklin, NH Institute`, `Audubon Park, KY Silver
Kestrels`. The tiers screen a name set the code no longer produces. (`Kestrel`, `Dunmore`,
`Fairbank` and `Wexford` do still appear — as *nickname* nouns, not place roots, which is a
different commercial impression than the one the tiers analysed.)

Conversely, **the 429 distinct real place names that now carry every team identity were never risk-
screened**. The document's own claim is scoped to NFL/NBA/MLB/NHL/MLS *club* names. It lists the
NCAA member-school directory as a source but makes no NCAA finding — and moving the world onto real
U.S. places is precisely the change that puts collision risk on NCAA programmes.

**Action:** re-run the risk-tier analysis against the 429 real place names before the doc is cited
as a clearance input. As written, its Executive result and its Risk tiers describe different games.

---

## F7 — `Akron` is in the place pool and absent from the institution blocklist (P1, legal, new)

`NameGrammar.realAmericanPlaces` contains **`Akron, OH`, `Akron, CO`, `Akron, IN`, `Akron, AL`,
`Akron, IA`**. `LeagueGenerator` passes `city.name` straight into
`NameGrammar.institutionName(place:using:)`, so the generator can produce `Akron, OH Technical
College` with `cityName` = `Akron, OH`.

`Blocklist.institutions` does not contain "Akron". I re-implemented `blocks` and `blocksPlaceName`
in Python over the actual lists and swept all 570 places, and all 570 places crossed with all ten
`institutionWords` plus `"Institute"`: **zero hits in both sweeps.** So `LegalTests`' 200-league
sweep is working exactly as designed and cannot fail on this — the gap is in the maintained list,
not in the test.

CLAUDE.md's stated rule for the eight refused cities is that each *"either is a real programme or
contains one."* Akron is a current FBS programme **and** its host city, which satisfies that rule.
The blocklist already blocks the Akron nickname **"Zips"** under `nicknames`, so the programme was
screened and its name was not.

Same class, host-city-only (no name collision, so a blocklist entry is the wrong instrument — this
is the "jointly identify a real one" review obligation CLAUDE.md and `Blocklist`'s own header
describe): `Ann Arbor, MI`, `Athens, OH`, `Athens, WV`, `Bozeman, MT`, `Boulder, MT`, `Butler, PA`.

**Also noted:** the comment inside `LegalTests`' *"a real city is allowed as a place and refused as
an institution"* still says *"the six names that are both a real city and a real programme"* and
lists six, while the assertion two tests above proves the set is eight and names Kansas City as the
one hand counts miss. One of the two should move.

---

## F8 — CI runs one lane; the iOS app is never compiled in CI (P1, new)

`.github/workflows/tests.yml` is one job:

```yaml
jobs:
  full:
    runs-on: macos-15
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/verify.sh
```

No arguments means `lane=full`, which is `swift build` plus `run_sim full`. `run_sim` does
`local label="$1"; shift`, so `"$@"` is empty and the binary runs **with no flags** — the default
suite.

Therefore CI never runs:

- `--m1-soak`, `--m2-soak`, `--m3-soak` (the 20-season soaks)
- `--calibration`, `--m3-recruiting-calibration` (the calibration bands)
- `--m7-gate`, `--performance-budget`, `--week-advance-timing`
- the `app` lane — **xcodegen + xcodebuild for iOS is never run in CI at all**, so
  `App/ProFootballCoachApp.swift` and the landscape/orientation policy compile only on a
  developer's machine.

CLAUDE.md §5 names the machine gates as "build green, tests green, calibration bands, cross-process
determinism, the soak, the two legal tests". Of those, only the build, the default suite,
determinism and the two legal tests are automated. Everything else is manual and therefore
periodically stale.

**Secondary, and now measured: the 60-minute timeout has no headroom.** On this machine the release
build took roughly **10 minutes** and the default suite took **54.5 minutes** (15:53:45 → 16:48:14,
964 tests, 787,761 checks). That is about **65 minutes for one CI job budgeted at
`timeout-minutes: 60`**, and GitHub's `macos-15` runners are slower than an M-series Mac.

One honest caveat: this machine was concurrently running other agents' soaks throughout (F15), which
inflates the number by an unmeasured amount. The right response is to measure it on a clean machine
rather than to assume either direction — but a job that finishes in 54.5 minutes under load has no
margin against a 60-minute ceiling, and a timeout reads as a red build with no failing test to point
at. F17 explains the shape of the cost: anything that advances weeks pays the same ~7 s per week the
soak measured, and one portal-scheduler characterisation test alone reported
`runtimeMs=232766` — 3.9 minutes in a single test.

---

## F9 — Index and working tree disagree; a plain `git commit` ships a reverted change (P2, new)

`Sources/FootballSimCore/Integrity/WorldIntegrity.swift` is `MM` in `git status`, and
`git diff HEAD -- <that file>` is **empty**. The index changes

```swift
-        checkPortalCapacity(allCareerRecords, issues: &issues)
+        checkPortalCapacity(currentTargetRecords, issues: &issues)
```

and the working tree reverts it. A plain `git commit` commits the index, so it would ship the
narrowed check that the working tree has already walked back.

The working-tree revert looks correct: `checkPortalCapacity` groups by
`(targetSeason, window, destinationProgrammeID)`, so historical records already partition into
their own capacity keys and are checked against their own recorded capacity. Restricting the input
to the current target season strictly reduces coverage.

`PeopleState.swift` and `WorldScheduler.swift` carry the same split. The working tree additionally
deletes `PlayerCareerRecord.compactedForDeparture()` (so departed players with recruiting or portal
history keep their **full** career record rather than a stripped one) and widens retention from
`history.recent` to `history.recent + history.archive.flatMap(\.notableEvents)`. Both changes reduce
the save-size win the branch exists to deliver; that trade is not recorded anywhere.

`docs/HANDOFF-CODEX-2026-08-20.md` deliberately preserves this WIP — the hazard is not that it
exists, it is that the index and the tree now disagree about one line of engine behaviour.

---

## F10 — Branch is 138 commits behind main, 454 files differ (P1, corroborated)

`git rev-list --left-right --count main...HEAD` = **`138  33`**.
`git diff --name-only main HEAD -- Sources/ Tests/ | wc -l` = **454**.

`Tests/SimTests/Suites/ArchitectureTests.swift` differs from main by **−275 lines** with no branch
commit touching it: main has substantially more architecture coverage and different pin values.

Already recorded as `P0-2` in the SwiftUI performance audit, which states the branch predates
main's memoised store, `availableScreens` root query, coalesced autosave and launch-backup skip,
and that merging as-is "reintroduces a measured 5,454 ms week advance and a 5,259 ms match snap
against a 1,200 ms auto-advance dwell."

The practical consequence for F1: the pins must be re-derived on the merged tree, not patched here.

---

## F11 — Five open branches carry competing `PeopleState` retention models (P2, new)

27 branches are open (unmerged into `origin/main`); 18 more are fully merged and undeleted.
Branches with unmerged **source** work:

| Branch | Src | Tests | Lines | Heaviest source files |
|---|---|---|---|---|
| `claude/missing-game-features-vcrzwz` | 59 | 23 | +9,718 / −180 | `Competition/Statistics.swift`, `Engine/GameEngine.swift` |
| `claude/game-surfaces-floodlit-plan-qo0okd` | 23 | 2 | +4,203 / −184 | `DesignSystem/WorldBackdrop.swift`, `DesignTokens.swift` |
| `cursor/p12-week-screens-fbc0` | 15 | 2 | +2,841 / −77 | `WeekScreenReadModels.swift`, `CoachWorldChrome.swift` |
| `codex/p4-calibration-attempt-7` | 12 | 3 | +2,053 / −90 | `Engine/DistributionSnapResolver.swift`, `Rules/OutcomeDistributionRules.swift` |
| `claude/football-manager-game-psychology-gyldwl` | 15 | 4 | +1,444 / −118 | **`People/PeopleState.swift`**, `PlayerDossierReadModel.swift` |
| `claude/implement-landscape-screens-63c2b1` | 6 | 2 | +1,331 / −5 | `LeagueMapView.swift`, `LeagueMapReadModels.swift` |
| `claude/twotier-consistency-tests-runner-11d4f1` | 9 | 8 | +1,046 / −35 | `Rules/MatchupRules.swift`, `Engine/SnapResolver.swift` |
| `claude/coach-career-promotion-integrity-f10168` | 5 | 3 | +577 / −6 | **`People/PeopleState.swift`**, `SeasonLifecycleSystem.swift` |
| `codex/people-compaction-wip` | 7 | 10 | +535 / −115 | **`People/PeopleState.swift`**, `RosterView.swift` |
| `codex/team-logos` | 229 | 8 | +1,463 / −90 | the asset catalog |
| `claude/road-to-beta-plan-40e904` | 2 | 2 | +217 / −7 | **`People/PeopleState.swift`**, `Rules/PeopleRules.swift` |
| `claude/production-scale-local-testing-if99bb` | 11 | 3 | +397 / −31 | `CoachWorldLeagueMapProvider.swift`, `CoachWorldReadModelProvider.swift` |
| `claude/career-length-cap-30` | 4 | 2 | +105 | `Rules/SharedRules.swift`, **`Scheduling/WorldScheduler.swift`** |
| `claude/football-coach-spec-review-1dz4u8` | 1 | 2 | +311 | `Support/SeedDerivation.swift` |
| `codex/fix-review-findings` | 1 | 1 | +50 / −3 | `CoachWorldAppRootView.swift` |
| `claude/codebase-review-confidence-b6b216` | 1 | 0 | ±28 | `CoachWorldAppRootView.swift` |
| `codex/fm-touch-personnel-examples` | 2 | 0 | +9 / −1 | `Calibration/CalibrationHarness.swift`, `CalibrationBands.swift` |

Four branches modify `PeopleState.swift` and two more modify `WorldScheduler.swift`, all with
different retention or compaction models. `docs/HANDOFF-CODEX-2026-08-20.md` already flags the
save-size composition problem; F4 is its concrete instance.

`claude/missing-game-features-vcrzwz` (+9,718 lines, last touched 2026-08-14, now 338 commits
behind main) is effectively unmergeable as a branch and should be treated as a source of
cherry-picks or closed.

---

## F12 — Quarantined saves are unbounded and invisible (P3, new)

`CoachWorldSaveStore.quarantinePrimary` / `quarantineBackup` copy the whole save file to
`Documents/Quarantine/<prefix>-<UUID>.pfcsave` on every failed load (called from
`SaveCoordinator.load()` and `recover()`; both live in the same file, which is why a naive grep
makes them look dead — they are not).

Nothing prunes that directory. `delete()` removes `career.pfcsave`, its `.backup` and its
`.metadata`, and leaves `Quarantine/` intact. No surface lists it. Saves are megabytes — the
`docs/STATUS.md` D7 record has them breaching the 8 MB ceiling by roughly 3x at season 20 — so
repeated corrupt loads grow the user's Documents directory without bound. This is the one class
CLAUDE.md says must have a stated bound: *"Every collection that can grow across seasons has a
stated bound."*

Minor, same file: `quarantineName` defends against path separators by taking the last component,
but `"."` and `".."` still resolve into the parent. Both would throw rather than overwrite, and the
argument is internally generated, so this is hardening rather than a defect.

---

## F13 — `rosterTargets` not asserted exhaustive while its siblings are (P3, new)

`CollegePortalPolicyV1.rosterTargets` is a private `[Position: Int]` with 15 entries against
`Position`'s 15 cases — exhaustive today, asserted nowhere.

`admissionComponents` then divides by it two different ways:

```swift
// line 263
let targetPositionCount = max(1, rosterTargets[evidence.position] ?? 1)
// line 339
let targetPositionCount = positionTargetCount(for: evidence.position) ?? 1
// line 357
10 - evidence.fixedPositionRoomCount * 5 / targetPositionCount
```

The `max(1, ...)` clamp at 263 is absent at 339. A `0` in the table, or a new `Position`, traps at
357 and degrades silently at 263.

The repository already asserts exactly this shape for the sibling tables —
`RulesTests.swift:44` for `SharedRules.declineAgeByPosition`, `PortalMatchingTests.swift:284` for
`CollegePortalPolicyV1.ratedAttributes` — so this is an inconsistency in applying the project's own
convention, not a new idea.

---

## F14 — Agent tooling directories are untracked and unignored (P3, new)

`.agents/`, `.claude/`, `.impeccable/`, `.superpowers/`, `.impeccable.md` and `exports/` are
untracked and absent from `.gitignore`. `docs/HANDOFF-CODEX-2026-08-20.md` warns *"Do not use
`git add -A`"* — a prose warning doing a job `.gitignore` should do mechanically, in a repository
where several agents commit. CLAUDE.md is explicit that third-party agent skills are development
tooling only and must never be linked into the app.

`.gitignore` is otherwise well maintained: it already handles `.worktrees/`, `build/`, the
accidental nested `Pro-Football-Coach/` gitlink and the third-party `FM Screenshots/`.

---

## F15 — Concurrent agent sessions in one working tree kill test runs (P2, process)

During this review, other `swift run SimTests` processes were live against this same working copy —
including `--m2-soak` at 30 minutes elapsed and an `M3_SOAK_SEASONS=3 --m3-soak`. Three of this
review's background test runs were terminated mid-suite at the same point; the other session's
`--m3-soak` log likewise contains only a build line and no test output. Copying the built binary to
a different filename let a run survive to completion.

That is the signature of a name-matched kill (`pkill -f SimTests` or similar). It matters more here
than in most repositories, because SimTests contains self-re-executing child-process tests: a
name-matched kill is indistinguishable from a real crash in those tests, and two agents sharing one
tree also share `.build`.

**Operational recommendation:** one worktree per agent (the repo already has `.worktrees/` ignored
and several in use), never kill by process name, and prefer `--scratch-path` per session.

---

## F16 — Widened prospect retention can make `advanceWeek` throw (P1, new)

This one is introduced by a **single unstaged line** in the working tree, and it is the sharpest
thing in the review.

`CollegeCycleSystem.hotProspectIDs` was:

```swift
Set(history.recent.flatMap { $0.payload.referencedProspectIDs })
```

and is now:

```swift
Set((history.recent + history.archive.flatMap(\.notableEvents))
    .flatMap { $0.payload.referencedProspectIDs })
```

`hotProspectIDs` drives both `pruningArchivedProspects` (what is kept) and `closeAndOpen` (what is
archived). Meanwhile `WorldIntegrity.checkCollegeState` still derives the expected set from
`history.recent` alone:

```swift
let requiredArchivedProspectIDs = Set(
    state.history.recent.flatMap { $0.payload.referencedProspectIDs })
    .subtracting(prospectIDs)
    .subtracting(playerIdentityIDs)
…
for id in archivedProspectIDs.symmetricDifference(requiredArchivedProspectIDs) … {
    issues.append(.invalidProspect(prospectID: id))
}
```

`symmetricDifference` is **exact set equality**, not a subset test. And the integrity result is not
advisory — `WorldScheduler`'s `.saveGrowthAndIntegrity` step does:

```swift
let report = WorldIntegrity.check(integrityProjection)
guard report.isValid else { throw WorldSchedulerError.integrityFailed(report.issues) }
```

**The failing case.** A prospect commits in season *S* (`prospectCommitted`, `historicalWeight` 30,
and it is in `referencedProspectIDs`), then never signs. Season *S*'s digest is filled in
chronological order as events overflow `recent`, and it starts empty, so an early-season weight-30
event is admitted while fewer than 32 higher-weight events for that season have been recorded — the
224 `proDraftPick` events at weight 50 that eventually crowd it out arrive later in the calendar.
At the next `closeAndOpen` the prospect is archived because the widened `hotProspectIDs` still names
them. The pruner then keeps them, `requiredArchivedProspectIDs` does not contain them because the
reference now lives in the archive rather than in `recent`, the symmetric difference is non-empty,
and **`advanceWeek` throws `integrityFailed([.invalidProspect(…)])`** — the world cannot advance.

Before this line, `hotProspectIDs` and `checkCollegeState` used the identical predicate. The
widening moved one of them.

**The new soak test moved with the pruner, not with the integrity check.** `M3CollegeSoakTests` now
computes its expectation as `(state.history.recent + state.history.archive.flatMap(\.notableEvents))
.flatMap { $0.payload.referencedProspectIDs }`. So there are now two authorities on the same set
and they disagree; the one that throws is the one that was not updated.

**Related, same shape, opposite direction.** `WorldIntegrity`'s dangling-reference check
(line 435) also scans `state.history.recent` only:

```swift
for event in state.history.recent {
    for entityID in event.payload.referencedEntityIDs where !allEntityIDs.contains(entityID) { … }
}
```

but `NewsFeedReadModel.swift:49` and `WorldHistoryReadModel` both read
`state.history.recent + state.history.archive.flatMap(\.notableEvents)`. An archived notable event
pointing at a deleted entity is therefore invisible to integrity and visible to the news feed. The
pruner's retention set, the integrity check's expectation, and the read models' consumption are
three different predicates over the same ledger; any two of them drifting is either a false throw
(F16) or a silent dangling reference.

**Fix direction:** make one function the single definition of "which events are retained history"
and have the pruner, the integrity check and the read models all call it.

---

## F17 — Three D4 budgets measured over their hard ceilings (P0, new)

The M3 college soak was run on the working tree, release build, 5 seasons:

```
M3_SOAK_SEASONS=5 SimTests --m3-soak

M3 soak: seasons=5 weeks=106 weekTotal=753.4092584848404 weekMean=7.107634514007929
         marketTotal=0.0831611156463623 classMin=3 classMedian=14 classMax=25
         portal=["returned": 442, "transferred": 1158, "retained": 825]
         redshirts=[notDesignated: 70350] saves=[5: 9031744, 1: 6605216]

[FAIL] M3 college management soak — 1 tests, 2 failed checks
1 tests, 2301 checks
  FAIL … save is 8736281 B at season 4, over the 8 MB D4 ceiling [M3CollegeSoakTests.swift:49]
  FAIL … save is 9031744 B at season 5, over the 8 MB D4 ceiling [M3CollegeSoakTests.swift:49]
EXIT=1
```

Against `docs/OPEN-DECISIONS.md` §D4:

| D4 budget | Target | Hard ceiling | Measured here | Over by |
|---|---|---|---|---|
| Full-season sim, college | 20 s | **35 s** | **150.7 s** (753.4 s / 5 seasons) | **4.3x** |
| Week advance, college | 1.2 s | **2.0 s** | **7.11 s** mean over 106 weeks | 3.6x (mean) |
| Save size, **20** seasons | 4 MB | **8 MB** | **8.33 MB at season 4**, 8.61 MB at season 5 | breached at season 4 |

**Reproduced in two independent processes.** A second run of the same command returned byte-identical
state — `saves=[1: 6605216, 5: 9031744]`, the same `classMin=3 classMedian=14 classMax=25`, the same
`portal=["transferred": 1158, "returned": 442, "retained": 825]`, the same
`redshirts=[notDesignated: 70350]` and the same two failures at seasons 4 and 5. Only the timings
moved (712.5 s / 6.72 s mean versus 753.4 s / 7.11 s mean), which is what should move. That is the
two-process reproduction this repository requires of any measurement it acts on.

Three caveats, stated so the numbers are not over-read:

1. **This is a Mac, not an A16 iPhone.** D4's falsifier is explicitly device-based, so this does not
   formally falsify D4. It is evidence in the wrong direction on hardware several times faster than
   the target, under no thermal load.
2. The **per-season** figure is the robust one. The 7.11 s week mean is an average over 106 weeks
   and the distribution was not captured, so season-rollover weeks may dominate it. The
   150.7 s/season number does not depend on the distribution.
3. `weekDurations` times **only** `session.resolve(.advanceWeek)`. Save encode, decode and the
   integrity check sit outside the timed block, so this is engine cost, not app-layer cost.

**Why the existing probes do not show this.** Both `PerformanceBudgetTests` and
`WeekAdvanceTimingProbe` are deliberately thresholdless — they print and assert nothing, and the
probe's docstring explains why honestly ("a development Mac is several times faster than an iPhone
under thermal load"). That reasoning is right. What is not right is **what they measure**: both time
`WorldScheduler.advanceWeek` on a *freshly bootstrapped* world — season 0, week 1, with no portal
window, no postseason, no draft and no season rollover. That is the cheapest week the engine ever
executes. The soak's own instrumentation, already in the tree, measures the representative case and
is 5x larger.

**On the save size specifically.** `SaveEnvelope`'s own comment records the season-20 compressed
baseline as "about 26 MB" and says the 8 MB target is "reduced by history compaction rather than by
silently rejecting valid careers" — the compaction this branch exists to deliver. The measurement
says the compaction as written does not get there: **6.30 MB at season 1** and **8.61 MB at season
5**, roughly 600 KB per season, which extrapolates to the high teens by season 20.
`docs/HANDOFF-CODEX-2026-08-20.md` independently records ~14.76 MB at season 20 for a sibling
retention branch and ~37.11 MB at season 30 for the career-cap branch. The growth is not in the
collections this pruner touches.

That matters for F3: the coaching tree is being spent on a size reduction that does not reach its
target. Confirming *where* the remaining megabytes actually live should precede deciding what else
to prune.

---

## F18 — No programme in the world ever redshirts anyone (P1, new)

The same soak reports, across 5 seasons and 134 programmes:

```
redshirts=[FootballSimCore.RedshirtSeasonOutcome.notDesignated: 70350]
```

**70,350 college player-seasons, and every one of them `notDesignated`.** Neither of the other two
outcomes — `preservedCompetitionSeason`, `burnedByUsage` — occurred once.

**Root cause.** The only writer of a `RedshirtPlan` is `CollegeRedshirtSystem` (line 263, via
`CollegeState.setRedshirtPlan`), and the only thing that reaches it is a **mandatory decision**
raised for the player's own programme (`MandatoryDecision.swift:275`). There is no autonomous
redshirt path for the other 133 programmes — no AI system designates a redshirt for anyone. In this
soak all responsibilities are `.delegated`, so the player's programme designates none either.

**Why it matters.** `docs/02-GAME-DESIGN.md:472` makes redshirting load-bearing in the eligibility
model: *"4 seasons of competition within a 5-year clock — the redshirt year is the difference, and
§4.1's redshirt decision is what spends it."* If nobody in the world spends it, the five-year clock
collapses to four seasons everywhere, roster ages and class turnover shift league-wide, and a
headline college mechanic is invisible in 133 of 134 programmes. `CollegeRedshirtTests` (1,223
lines), the `redshirtResolution` field, the integrity checks and the eligibility clock all work —
against a world that never exercises them. That is `docs/BETA-READINESS-CONSOLIDATED.md` §1.1's own
clause 6: *"A stored value with no consumer is unfinished."*

**Why no test sees it.** The soak counts the outcomes into `redshirtOutcomes` and **prints them
without asserting anything**. One `expect(redshirtOutcomes[.preservedCompetitionSeason, default: 0]
> 0)` beside the existing `expect(!collegeSeasons.isEmpty)` would have caught this the first time
the soak ran.

**Cross-check on method:** the same run reproduced `docs/STATUS.md:333`'s recorded class sizes
exactly — "class sizes **3–25** (median **14**)" against this run's `classMin=3 classMedian=14
classMax=25` — so the soak configuration matches the one the status file describes.

---

## F19 — The calibration bands are measured and never asserted (P1, new)

`CLAUDE.md` §5 lists the machine gates an agent must assert before completion: *"build green, tests
green, calibration bands, cross-process determinism, the soak, the two legal tests."* There is no
assertion anywhere in the repository that a calibration band holds.

**What was run.**

```
SimTests --calibration

[ok  ] TOST — 8 tests
[ok  ] Total variation distance — 3 tests
[ok  ] Band tables — 5 tests
[ok  ] Calibration harness — 4 tests

20 tests, 164 checks
all passed
EXIT=0
```

**What those four suites actually check.**

- **TOST** (8 tests) — the equivalence arithmetic, against **hand-constructed** estimates:
  `band.test(Estimate(value: 0.55, sampleSize: 40, standardDeviation: 0, …))`. Real arithmetic,
  synthetic input.
- **Total variation distance** (3) — the TVD function.
- **Band tables** (5) — the *shape* of `CalibrationBands`: `lower < upper`, no band wider than 15x,
  college floors above pro floors, `unimplementedMetrics.count > 10`.
- **Calibration harness** (4) — the seed ladder splits; the harness is reproducible; the harness
  *reports on* every declared band (`expectEqual(report.results.count, declared.count)`); the talent
  ladder produces mismatches.

`CalibrationHarness.run(tier:seeds:)` returns `CalibrationReport { let results: [BandResult] }`, and
`BandResult` carries `let passed: Bool`. **No test reads `.passed` on a harness-produced result.**
The only calls to `Band.test(_:)` in the whole tree are the TOST suite's synthetic ones. Grep for an
assertion that a measured estimate falls inside its band and there is nothing to find.

So the harness measures the engine, computes pass/fail per band, and every automated check throws
that answer away. A band can be violated by any margin and the suite stays green.

**It is worse than a missing assertion, because of F8.** `runCalibrationTests()` is *already* in the
no-flag default suite, so `verify.sh --lane calibration` adds nothing over what CI already runs
except `--m3-recruiting-calibration` — which is a recruiting-fixture suite, not the match-engine
bands. There is no lane, in CI or out of it, whose failure means "a calibration band moved."

This is the same defect as F5 and the one `CLAUDE.md` names under Conventions, in its most
consequential place: the gate exists, it is named in canon, it runs, it passes, and it is not
measuring the thing it is named for. Any statement of the form "21 of 24 bands hold" came from
reading a printed report, not from a gate — which means it is a snapshot with no mechanism keeping
it true.

**One concrete thing this leaves uncovered.** `EngineTests`' snap-result reachability check is
otherwise a model by-construction test — it enumerates `SnapResult.allCases` and fails naming any
result the engine declares and never produces, and the fixture was explicitly widened with goal-line
snaps so `touchdown` is reachable, with a comment saying why. It then carves out exactly one case
with no comment and no compensating check:

```swift
let unreachable = SnapResult.allCases.filter { !seen.contains($0) && $0 != .safety }
```

`.safety` is genuinely produced by the engine (`SnapResolver.swift:384` and `:398`, handled in
`DriveEngine.swift:274`), so this is a fixture limitation — the fixture's yard lines (96, 92, 30, 55)
never put the offence deep enough in its own end. The independent evidence that safeties occur at a
plausible rate would be the `safeties per game` band, `0.005–0.05`, `provisional [U]` — which is one
of the 24 nothing asserts. Two gaps that would each have caught the other. Not a claim that safeties
are broken; a claim that nothing here would tell you if they were.

**Smallest fix that closes it:** one test that runs the harness over the **holdout** ladder for both
tiers and asserts `report.results.allSatisfy(\.passed)`, with `BandResult.report` as the failure
message (it already formats metric, estimate, CI90, band, n and violated edge, exactly as
`01` §6.6 clause 3 requires). If some bands are known-open, assert the *named* exceptions rather
than skipping the check, so closing one is a one-line edit and adding one is deliberate.

---

## F20 — `SuiteCatalog`'s lane vocabulary is not `verify.sh`'s (P3, new)

`Tests/SimTests/SuiteCatalog.swift` opens with its purpose:

> *"Release lanes are data so the default harness and CI can enumerate the same gates."*

The two vocabularies do not match:

| Source | Lanes |
|---|---|
| `SuiteCatalog.lane(for:)` | `accessibility`, `determinism`, **`legal`**, **`persistence`**, `soaks` |
| `scripts/verify.sh` | `accessibility`, `app`, `archive`, `calibration`, `core`, `determinism`, `full`, `release`, `soaks` |

`./scripts/verify.sh --lane legal` and `--lane persistence` both exit 2 with `unknown lane`. Nothing
asserts the catalog's lane strings are lanes the runner accepts, so the one artefact whose stated job
is to keep the harness and CI enumerating the same gates can name a lane that does not exist.

Two things the catalog gets right and are worth keeping: every `Runner.command` it names does exist
in `main.swift` (all nine verified), and it asserts `entry.runner != nil` for every gate. The
missing assertion is only the lane string.

**`ReleaseGateID` also has no calibration entry at all** — 18 gates across accessibility,
determinism, persistence, soaks and legal, and calibration is not among them. That is F19 seen from
the other side: the artefact that enumerates the release gates does not consider calibration one,
while `CLAUDE.md` §5 does.

---

## F21 — College has half the calibration bands of pro, and nothing checks (P2, new)

`CalibrationBands` declares **24 bands: 16 pro, 8 college.** Nine metrics have a pro band and no
college counterpart:

> Q4 share of points, blowout rate, completion percentage, interceptions per team-game, **pass yards
> per team-game**, **rush yards per team-game**, sacks per team-game, safeties per game, tie rate

That is most of the box score. College carries one metric pro does not (combined game total).

**Why the imbalance is backwards.** `docs/OPEN-DECISIONS.md` §D4 opens with: *"Derived from the
**college** case, which is the worse one."* College is the tier the performance budgets are written
for, the tier the M1 and M3 soaks exercise, the tier the career opens in, and the tier with 134
programmes against pro's 32. It is the half-calibrated one.

**Why no test notices.** The two tests that look like they would:

- *"both tiers are covered, and the tier is not a label"* asserts `!CalibrationBands.pro.isEmpty` and
  `!CalibrationBands.college.isEmpty`. One college band would pass it as comfortably as eight.
- *"the tiers disagree where 01 section 6.5 says they disagree"* iterates a **hand-written list of
  three metrics** — `["points per team-game", "offensive plays per team-game", "explosive run
  rate"]` — and checks the college floor is higher. Every one of the nine missing metrics is outside
  that list.

`CLAUDE.md` is explicit about this shape under Conventions: *"Spot-check tests over hand-listed
instances are a defect, not coverage."*

**For scale, and to be fair to the authors.** 16 metrics from `01` §6.5 are declared in
`unimplementedMetrics` with a stated blocker each, so the table covers 24 of ~40 named metrics and
says so in its own header comment. Confidence labels are carried per band and are honest: 7 `[C]`,
8 `[Q]`, 3 `[P]`, **5 `provisional [U]`** and one `[ASSUMPTION] blocked on 01 section 4.2`. And the
test *"what the harness does not yet measure is named, not dropped"* is a genuinely good
by-construction check — it walks `unimplementedMetrics`, requires a reason on each, and asserts no
metric is both implemented and listed as missing. That is the pattern the tier-parity test needs and
does not have.

Stacked with F19, the calibration position is: **60% metric coverage, half-weight on the tier the
design names as the harder one, and zero enforcement of any of it.**

---

## F22 — The 164 MB logo set works on exactly one world seed (P0, new)

The logo lookup is a dictionary keyed by the team's UUID:

```swift
// CoachWorldReadModelProvider.swift:471
mark: CoachWorldTeamLogoCatalog.mark(forStableID: id.uuidString)

// TeamLogoCatalog.generated.swift
public static func mark(forStableID stableID: String) -> CoachWorldAssetReference? {
    assetNames[stableID].map { CoachWorldAssetReference(stableID: stableID, assetName: $0) }
}
```

Those UUIDs are **seed-derived**. The catalogue holds exactly the 166 identifiers produced by
`GameState.bootstrap(seed: 20_260_812)` — `Tools/TeamLogos/manifest.json` records
`"worldSeed": 20260812`, `CoachWorldStore.defaultSeed` is `20_260_812`, and `TeamLogoTests` pins
both.

**And the player can change the seed.** `NewCareerSetupView` renders an editable text field:

```swift
@State private var seedText: String                    // line 18
TextField("World seed", text: $seedText, onCommit: refreshJobsForSeed)   // line 88
    .accessibilityLabel("World seed")                                     // line 90
…
guard canSubmit, let seed = UInt64(seedText) else { return }              // line 206
onStart(firstName, lastName, seed, selectedJobID)                         // line 207
```

Any `UInt64` is accepted and nothing clamps it. A career started on any seed other than 20,260,812
generates 166 different programme and team UUIDs, none of which are in `assetNames`, so
`mark(forStableID:)` returns `nil` for every team and `CoachWorldTeamLogo` falls through to its
abbreviation-chip fallback everywhere.

**Net effect: 163.7 MB of assets ship in the bundle and render for exactly one seed.** For every
other world the app is 164 MB heavier and shows text chips.

It degrades gracefully rather than crashing — the fallback chip is well built, carries the team
colours and is accessibility-labelled — which is precisely why nothing has caught it. Every logo
test runs `GameState.bootstrap(seed: manifest.worldSeed)`, so the tests can only ever see the one
world where the mapping holds.

**This is F2's real cost.** The 164 MB is not merely oversized for a 44 pt chip; it is oversized
*and* conditional. Deciding what to do about F2 should start here: either the seed field goes (and
the world becomes a fixture, which is a product decision, not a technical one), or team marks must
be generated or selected from something seed-independent — an archetype, a nickname family, a
procedural mark — rather than keyed to identifiers that change with the seed.

**Smallest test that would have caught it:** one case that bootstraps a world at a seed *other* than
`manifest.worldSeed` and asserts something about logo coverage — even just recording the number,
which would read `0 / 166`.

---

## F23 — The generated logo catalog holds 166 stale team names (P2, new)

`Sources/ProFootballCoachUI/TeamLogoCatalog.generated.swift` opens with *"Generated by
`Tools/TeamLogos/generate_catalog.swift`. Do not hand-edit."* The naming commit `c6e2d21` rewrote
`Tools/TeamLogos/manifest.json` (1,168 lines) and **did not regenerate the catalogue**. Comparing
the two by stable ID: **166 of 166 names disagree.**

| Stable ID | Catalogue says | Manifest says |
|---|---|---|
| `0017F958-…` | Oakhaven Heath Upper | Altus, OK City College |
| `00EBE0C0-…` | West Ivory Crossing | Carlsbad, NM Normal Institute |
| `0213C958-…` | Jessup Hollow Coastal | Alamo, TN Agricultural Institute |
| `04EF984B-…` | South Dunmore Reach | Agoura Hills, CA Technical College |
| `05293748-…` | Yarrow Basin Silver Kestrels | Audubon Park, KY Silver Kestrels |

**Scope, stated honestly.** Production reads only `mark(forStableID:)`, which returns the
stableID→asset mapping, and the stable IDs did not move — only the names did. So the shipped game is
unaffected. The stale names live in `proofTeams`, consumed by `TeamLogoProofView`, which is the
owner's `#if DEBUG` visual proof surface. An owner opening that screen to check names against
artwork sees the naming scheme the game abandoned.

**Why no test caught it.** The same commit *added* a manifest-versus-world name assertion —

```swift
expectEqual(team.name, worldNames[team.stableID], "manifest display name drifted for \(team.stableID)")
```

— and there is no equivalent catalogue-versus-manifest assertion. The generated file is the third
copy of the same facts and the only one nothing checks. That is F5's shape again: two of three
authorities are tied together and the third drifts silently.

It is also a live instance of F6 and F23 pointing the same way — after `c6e2d21`, the manifest, the
generated catalogue and the trademark screen each describe a different generation of team names.

---

## Verified fine — and how

Each of these was a specific worry, investigated to a conclusion rather than assumed.

- **Determinism of the moved `recordPortalKnowledgeBatch` call.** The diff moves the call and
  changes its argument to `offersByPlayerID.values.flatMap { $0.map(\.knowledge) }` — Swift
  dictionary iteration, hash-seeded per process. Harmless:
  `ScoutingState.recordPortalKnowledgeBatch` de-duplicates by a five-field
  `PortalKnowledgeIdentity`, tests only *counts* against `maximumKnowledgeObservers` and
  `maximumKnowledgePerObserverWindow`, and stores `Self.canonical(current)`, which sorts by
  `(targetSeason, window, sourceProgrammeID, playerID)` — a total order within one observer.
- **Award-winner determinism.** `seasonAwards` picks winners with `max(by:)` over a filtered
  dictionary, but `awardValueOrder` and `playerAwardValueOrder` both tiebreak on `key.uuidString`,
  giving a strict total order. Iteration order cannot change the winner.
- **Integrity-report determinism.** `checkTacticalState` iterates three dictionaries raw, but each
  loop appends the same `.invalidTacticalState` value, and only the count is persisted —
  `.integrityChecked(issueCount: report.issues.count)`.
- **`EntityStore` ordering.** `values` is `ids.compactMap { … }` and `ids` is UUID-string sorted, so
  `compacted.staff = EntityStore(retainedStaff)` cannot vary by launch.
- **`PeopleState.compacted` ordering.** `for id in departedPlayers.keys` is hash-ordered but feeds a
  `Set`; the over-cap path sorts on `(season desc, week desc, uuidString asc)`, a total order given
  the `endedAt != nil` filter that built the array.
- **Award retention coverage.** `champion` and `topOffense` carry team identifiers and teams are
  never pruned, so retaining only `.playerOfTheYear` winners is complete today (see F5 for the
  future-case risk).
- **Force unwraps.** The engine has six. `PlayerRecruitingOrigin`'s `commitmentHistory.last!` is
  protected in both directions — a `precondition` in `init` and an `isValid` guard in
  `init(from:)` that requires `!commitmentHistory.isEmpty`. `CollegeSigningSystem`'s
  `commitmentContext!` is guarded by the `commitmentHistory.last?.winner.programmeID ==
  programmeID` check in the `compactMap` that produced the candidate, and `commitmentContext` is
  defined as `commitmentHistory.last`.
- **Division by zero.** Every `/ x.count` site in the engine guards or clamps:
  `AbstractGameSimulator.strength` (`guard !players.isEmpty`), `distributedLines`,
  `CareerArcState.averageSupport`, `TacticalPlanSystem.coordinatorRating`,
  `TeamSeasonStatistics.winningPercentage` (`guard games > 0`), realignment centroids
  (`guard !cities.isEmpty`), `pursuitSaturation`, and both portal NIL divisions. F13 is the one
  asymmetry.
- **Logo loading across packaging modes.** `CoachWorldTeamLogo.packagedImage` tries
  `UIImage(named:in: .module)` first — the compiled `Assets.car` path used by an Xcode iOS build —
  and falls back to the loose-file `Bundle.module.url(…subdirectory: "TeamLogos.xcassets/….imageset")`
  used by a SwiftPM resource copy. Both packagings work.
- **`RootView`'s empty Release body.** `RootView` renders only an empty state outside `#if DEBUG`,
  which looked alarming; it is the proof harness. `App/ProFootballCoachApp.swift` ships
  `CoachWorldAppRootView`, and only reaches `RootView` under `#if DEBUG` with `PROOF_SCREEN` set.
- **Quarantine is wired in.** `quarantinePrimary`/`quarantineBackup` appeared to have no callers
  because `SaveCoordinator` lives in the same file; `load()` and `recover()` call them, with
  `UUID`-suffixed names so `copyItem` cannot collide.
- **The legal sweep enumerates by construction.** `everyGeneratedName` =
  `everyGeneratedInstitutionName + everyGeneratedPlaceName`, covering conference, division,
  programme, pro-team, nickname, venue and tradition names as institutions, and region, city and
  `cityName` as places, over 200 decorrelated seeds. F7 is a gap in the maintained list, not in the
  sweep.
- **Contract scans resolve their root from `#filePath`**, not the working directory, so they cannot
  pass vacuously because of where the binary was launched.
- **Decompression bomb defence.** `SaveEnvelope.decompress` streams the body in 64 KB chunks and
  enforces `output.count <= maximumBodyBytes` **inside the loop**, aborting mid-decompression rather
  than after it. Combined with the `maximumStoredBodyBytes` check on the compressed input before
  decompression starts, a hostile file cannot force an unbounded allocation. This is the correct
  shape and it is rarer than it should be.
- **`try!` in the UI layer.** The only two in `Sources/ProFootballCoachUI` and
  `Sources/CoachWorldApp` (`ScreenReadModels.swift:1892` and `:2217`) sit inside the file's single
  `#if DEBUG` block (lines 1803–2274) and build sample read models. Nothing ships. There is no
  `fatalError`, no `DispatchQueue`, and no `Thread.sleep` anywhere in `Sources/`.
- **`SuiteCatalog`'s runner commands.** All nine `Runner.command` strings it names exist as flags in
  `main.swift`, and a test asserts `entry.runner != nil` for every gate. Only the lane strings drift
  (F20).
- **Hygiene.** Zero `TODO` / `FIXME` / `HACK` / `XXX` in `Sources/`. One `.hashValue` occurrence in
  the whole tree, and it is the comment in `SeededRandom.swift` explaining why it is forbidden.

**A fair characterisation of the codebase.** Almost none of these twenty-three findings are unsafe code.
The engine is defensive in a way most codebases are not: every division guarded, every force unwrap
backed by a validating decoder, canonical ordering everywhere a dictionary could leak hash order into
state, a streaming decompression bound, exhaustive switches where they matter. The findings are
overwhelmingly about **gates** — assertions that were never written, coverage boundaries mistaken for
quality boundaries, and lanes that do not run. That is a much better problem to have, and a cheaper
one to fix.

---

## Still open

- **Whether `main` itself is green.** Not run; this review's scope was the branch. Worth doing
  before F1 is fixed, because it decides whether the merged tree needs one re-pin or two.
- **Whether the 65-minute build-plus-suite figure holds on a clean machine.** Measured under
  concurrent load from other agents (F15). Re-measure before changing the CI timeout.
- **The soak lanes and the `app` lane on this tree.** `--m1-soak`, `--m2-soak` and
  `verify.sh --lane app` were not run here. `docs/HANDOFF-CODEX-2026-08-20.md` records the
  professional tier as blocked by FSC-013 (week-21 turnover invalidating live game participant
  manifests), so `--m2-soak` is expected red for a known reason.
- **Whether F16 fires in practice.** It did **not** fire in the 5-season soak — `expect(WorldIntegrity
  .check(state).isValid)` passed at every checkpoint. The mechanism is confirmed by inspection and
  unobserved in five seasons; a 20-season soak is the falsifier, and the cost of being wrong about
  it is a career that cannot advance.
- **How many coaching-tree branches actually survive twenty seasons.** F3's mechanism is proven from
  the retention arithmetic and corroborated by the sibling branch's fix; the size of the loss in a
  real career is not measured. The cheapest falsifier: run `--m1-soak`, then derive
  `CoachingTreeReadModel.build(from:)` on the final state and count branches whose mentor is not
  currently seated. It should be zero, and if it is, that is the whole finding in one number.
- **Where the remaining save megabytes actually are.** F17 shows the compaction does not reach
  8 MB. Nothing in this review measured the per-collection breakdown of a season-5 save, and that
  measurement should come before any further pruning is designed.

---

## The pattern underneath

Eight of the twenty-three findings are the same defect wearing different clothes, and `CLAUDE.md` already
names it under Conventions:

> *"The defect is not ignorance of contrast; it is that the test's coverage boundary became the
> quality boundary."*

- **F19** — the calibration gate runs, passes, and never reads the `passed` flag it computed.
- **F5** — `referencedEntityIDs` has a `default: []` that is correct today and becomes a silent
  delete tomorrow; the integrity check that would catch it reads the same function.
- **F18** — the soak counts redshirt outcomes and prints them without asserting, so 70,350
  consecutive `notDesignated` results were never a failure.
- **F16** — retention, integrity and the read models each carry their own copy of "which events are
  retained history"; the working tree moved one of the three.
- **F3** — the pruner's retention set was designed around history events and never asked which read
  models consume the data it deletes.
- **F20** — the artefact whose stated job is to make the harness and CI enumerate the same gates
  names two lanes the runner rejects, and omits calibration entirely.
- **F22** — every logo test bootstraps `manifest.worldSeed`, so the one world where the mapping
  holds is the only world the tests can see.

F21 and F23 are the same thing in its other form: a check that *looks* general but is a hand-written
list of three metrics (F21), and a third copy of the same facts that nothing compares against the
other two (F23).

In each case the machinery is present, careful and well documented. What is missing is the assertion
that connects it to the thing it exists to protect. Three of them (F19, F18, F5) close with one test
each. That is the highest-value work in this list.

---

## Recommended order

1. **F19** — one test asserting `report.results.allSatisfy(\.passed)` over the holdout ladder. It is
   the cheapest finding here and it is a named canon gate that currently does not exist.
2. **F1** — do not re-pin on the branch. Merge main first (F10), then derive both fingerprints from
   one deterministic run reproduced in two processes.
3. **F17** — decide what the measurement means before more compaction is designed. D4 states its own
   lever: *"If measurement shows the 2.0 s ceiling cannot be met, the lever is D14's programme
   count, not the ceiling."* And measure where the season-5 megabytes actually are, because they are
   not in the collections this pruner touches.
4. **F3 + F4** — reconcile the two staff-prune designs into one before either merges. The
   `pruneSeatlessStaff` retention set is the correct starting point; the weekly cadence of
   `compactHistoryBoundState` is the correct trigger. F17 says this is being paid for a size
   reduction that does not currently arrive.
5. **F16** — one function defining "retained history", called by the pruner, the integrity check and
   the read models. Until then, do not ship the widened `hotProspectIDs` line: it can throw.
6. **F5** — make `referencedEntityIDs` and `referencedProspectIDs` exhaustive, as
   `historicalWeight` already is. The only change that stops the class recurring.
7. **F6 + F7** — legal. Re-screen the 429 real place names; add `Akron` to
   `Blocklist.institutions`, and take the six host-city cases to the owner as the trade-dress
   review obligation they are, not as blocklist entries.
8. **F18** — owner question first (is AI redshirting in v1 scope?), then either an AI path or an
   explicit canon amendment. Either way, one assertion in the soak.
9. **F8** — put at least the soaks, the calibration lane and the `app` lane on a schedule, even if
   not on every PR.
10. **F22 + F2** — one owner decision, not two. F22 says the logo set is conditional on a seed the
    player can change; F2 says it is 60x oversized for the largest chip it draws. Both are answered
    by the same question: is the world a fixture (drop the seed field) or is it generated (then
    marks cannot be keyed to seed-derived identifiers)? Answer that before touching the assets.
    Meanwhile F23 is a one-command fix — regenerate the catalogue and add the missing
    catalogue-versus-manifest assertion.
11. **F21** — replace the three-metric hand list with a by-construction tier-parity check, in the
    same pass as F19.
12. **F9, F11–F15, F20** — housekeeping, but F15 first: it is currently costing every agent in this
    repo real time.
