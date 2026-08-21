# Full codebase and branch review — 2026-08-20

**Target:** working tree + `agent/floodlit-injury-evidence` @ `c0f4334`, the engine and app sources,
the test/CI harness, and the 90 local/remote branches.
**Method:** ten review angles run sequentially in one context (line-by-line diff, removed-behavior,
cross-file tracer, language pitfalls, wrapper correctness, reuse, simplification, efficiency,
altitude, CLAUDE.md conventions), then verification. No code was changed.

**Toolchain was available** (Apple Swift 6.3.3), so most findings below are *executed*, not asserted.
Verification artefacts live in the session scratchpad; the exact commands and outputs are quoted inline.

## Verification status

| Gate | Result |
|---|---|
| `swift build` | **green** (exit 0) |
| `SimTests --architecture-only` | **RED — 2 failed checks** (see F1) |
| `SimTests --legal-only` | green, 23 tests / 144 checks — **and that is itself a finding** (see F2) |
| `SimTests --design-contracts` | green — `AX5 contract: 62 landed, 0 pending`, `Floodlit conversion: 62 converted, 0 pending`. STATUS.md's 2026-08-19 surface-reachability claim checks out. |
| Full no-flag `SimTests` | **RED — 967 tests, 787,806 checks, 1 failing test / 2 failed checks.** The two checks in F1 are the *only* failures in the whole suite. |
| Soaks / calibration / m7-gate / app build | **not run** — and CI never runs them either (see F13) |

Do not read "build green" as "verified". The suite is red at the branch tip.

---

## P0 — blocking

### F1. Both cross-process determinism pins are stale; the branch tip ships a red suite
`Tests/SimTests/Suites/ArchitectureTests.swift:31,33,83,84`

```
FAIL Authoritative game state / root and scheduler fingerprints are pinned across processes:
  expected 3251160748987753141,  got 2399181485827482543   [ArchitectureTests.swift:83]
  expected 11229646605763785595, got 10425352982328808663  [ArchitectureTests.swift:84]
```

Reproduced twice: once through `SimTests --architecture-only`, once through an independent probe
binary that recomputes `architectureFingerprint` from `Sources/`. Both produce the same actual values.

**Cause, isolated.** The *root* pin hashes `GameState.bootstrap(seed: 20_260_810)` only — nothing in
the uncommitted working tree touches bootstrap. Since the pins were last set (`e3d237f`,
2026-08-16), exactly one commit has touched `Sources/FootballSimCore/Generation`:

```
c6e2d21 feat: use real places and generic postseason names
```

That commit re-pinned `GenerationTests`' `PINNED_WORLD_BYTES` / `PINNED_WORLD_DIGEST` and did not
touch `ArchitectureTests`. The same invariant is pinned in two files and only one was maintained.

**Why it matters.** This is the determinism gate CLAUDE.md calls non-negotiable ("a given seed plus a
given input state reproduces a match exactly, across processes and app launches"). It is currently
the only red gate, and it is red for a legitimate reason — the world genuinely changed — which means
it is telling the truth and nobody looked.

### F2. The branch is 208 commits behind `origin/main` and still generates eight real college nicknames that main removed a week ago

`origin/main` carries `1db001a` *"fix(legal): block the near-miss marks, and clear real nicknames
from the pools"* (2026-08-13): blocklist 274 → 485 entries, a new `marks` limb, bowl games,
conference acronyms, trade dress 39 → 71 pairs, and the removal of eight real nicknames from
`NameGrammar`'s own pools. **This branch has none of it.**

Generated on this branch, `LeagueGenerator.generate(seed: 4242)`:

```
Silver Delvers | Ember Sentinels | Timber Otters | Timber Wardens | Harbor Wayfarers
Thunder Prospectors | Slate Wreckers | Copper Prospectors | Hollow Reapers | Hollow Herons
Storm Wayfarers | Iron Wayfarers | Storm Kestrels
```

Checked against main's blocklist:

```
branch nickname ADJECTIVES blocked by main's list: ['Storm']
branch nickname NOUNS blocked by main's list:
    ['Drovers','Foresters','Marauders','Harriers','Herons','Otters','Beacons']
  'Timber Otters'    blocked-by-main=True
  'Hollow Herons'    blocked-by-main=True
  'Storm Wayfarers'  blocked-by-main=True
  'Storm Kestrels'   blocked-by-main=True
```

`SimTests --legal-only` on this branch is **green**, because the branch's blocklist is the pre-fix
274-entry version. A green legal gate over a stale list is worse than no gate: it is the exact
failure `docs/PORT-LOG.md` records and `Blocklist.swift`'s own header warns about.

Merge risk compounds it: `NameGrammar.swift` and `LegalTests.swift` are both changed on both sides
(22 conflicting regions across 22 shared files). Resolving `NameGrammar.swift` in favour of this
branch — which rewrote it wholesale, +606/−39 — silently reverts main's legal fix.

### F3. The new `"City, ST"` place format defeats the blocklist's contiguous-word matcher
`Sources/FootballSimCore/Generation/NameGrammar.swift:17-48`, `Generation/Blocklist.swift:93-110`

`Blocklist.contains` matches *contiguous runs of words*, deliberately (substring containment blocks
invented names). Every generated place is now `"<City>, <ST>"`, and that place is spliced into
institution names, venue names, region names and pro-team names. The state token lands **between**
the city and the following word, so no multi-word mark that begins with a city can ever match again.

Executed against the real `Blocklist`:

```
Boston, MA Technical College  -> blocks: false      Boston College   -> blocks: true
Las Vegas, NV Bowl            -> blocks: false      Las Vegas Bowl   -> blocked by main: true
```

Both left-hand strings are reachable output: `institutionName` emits `"<place> Technical College"`,
and `venueWords` contains `"Bowl"` so `venueName` emits `"<place> Bowl"` — the shape main's own
comment calls out as "a shape the generator produces on every save". `"Boston, MA"` and
`"Las Vegas, NV"` are both in `realAmericanPlaces`.

This survives main's hardened blocklist. Merging F2 does not fix F3.

---

## P1 — must fix before the next release claim

### F4. The dual-use city guardrail is asserted over a list the generator does not use
`Sources/FootballSimCore/Generation/Blocklist.swift:~150 (realCities)`, `Tests/SimTests/Suites/LegalTests.swift:150-168`

`LegalTests` asserts that the set of names that are both a real city and a real programme is exactly
the eight CLAUDE.md quotes — by filtering `Blocklist.realCities`, a hand-maintained list of **42**
cities. The generator draws from `NameGrammar.realAmericanPlaces`, **429 distinct** cities.

```
realCities count: 42
generated cities not in Blocklist.realCities: 426 of 429
```

So 426 of the generator's cities are never tested against the institution limb. The list is already
short by at least one live case: `Blocklist.blocks("Akron") == false`, while Akron is a real FBS
programme and `"Akron, OH"`, `"Akron, CO"`, `"Akron, IN"`, `"Akron, AL"`, `"Akron, IA"` are all
generated places — so `"Akron, OH Institute"` ships unflagged.

This is CLAUDE.md's own rule broken: *"A test that checks a class of surfaces must enumerate that
class by construction."* Good news: none of the eight refused cities are currently in the place list,
so nothing is live *today* — but nothing stops the next entry.

### F5. `PeopleState.compacted` leaves the dominant growth term unbounded
`Sources/FootballSimCore/People/PeopleState.swift:1082-1089`, `Rules/PeopleRules.swift:5`

```swift
retainedDepartedPlayerIDs.formUnion(playerCareers.compactMap { id, career in
    guard playerLifecycle[id] == nil,
          career.recruitingOrigin != nil || !career.portalWindows.isEmpty else { return nil }
    return id
})
```

`recruitingOrigin` is set for **every** signed recruit (`CollegeSigningSystem.swift:224`). So every
player who ever signed with a programme keeps a `PlayerCareerRecord` *and* a `DepartedPlayerIdentity`
forever. `CollegeRules.programmeCount = 134` × 25 signings per class ≈ **3,350 permanently retained
records per season**, in steady state. `PeopleRules.maximumRetainedDepartedPlayers = 4_096` applies
only to the *other* set — the players with neither a recruiting origin nor portal history.

Nothing else prunes `playerCareers` (`grep` finds only the initialiser, the decoder, and this method).

CLAUDE.md: *"Every collection that can grow across seasons has a stated bound."* This one has a
stated bound that does not bind. Compression currently hides it — see F6 and F21.

### F6. The soak that guards the 8 MB ceiling cannot see the growth, and cannot run long enough to
`Tests/SimTests/Suites/M3CollegeSoakTests.swift:6,155-166`

Two independent gaps in the same gate:

1. **The bound assertion is vacuous for the growing term.** The soak computes `durablePlayerIDs`
   (careers with a recruiting origin or portal history), folds it into `exceptionalDepartedPlayerIDs`,
   then asserts `departedPlayerIDs.count <= maximumRetainedDepartedPlayers + exceptionalDepartedPlayerIDs.count`.
   The right-hand side grows with the left. The only genuinely bounded assertion excludes
   `durablePlayerIDs` explicitly. Nothing constrains the term that grows by 3,350 a season.
2. **It cannot be run past 20 seasons.** `precondition((1...20).contains(requested), "M3 soak seasons
   must be in 1...20.")` — setting `M3_SOAK_SEASONS=30` traps. The product's career cap is 30 seasons
   and `SaveEnvelope.swift:44` quotes a 30-season measurement. The ceiling is measured at two-thirds
   of the horizon it exists to protect.

### F7. The working tree removes a per-record bound and replaces it with whole-record retention
`Sources/FootballSimCore/People/PeopleState.swift` (vs `origin/codex/people-compaction-wip:90d96a6`)

The branch this work evolved from had:

```swift
/// D7 keeps departed players as identity plus season aggregates. Recruiting and portal
/// decision detail remains only while the bounded history still cites the player.
func compactedForDeparture() -> PlayerCareerRecord   // portalWindows: []
```

called at the retention site. The working tree **deletes the method and the call**, retaining full
records including `portalWindows` — each holding up to `maximumOffersPerEntrant` offers, and each
offer carrying `knowledge`, a `playerFit` explanation with evidence and components,
`destinationAdmission` and `fixedCapacity`. Net effect versus its own parent: strictly more bytes
retained, with no bound.

The integrity check that motivated retention was narrowed in the same change
(`WorldIntegrity.swift:1446`, `checkPortalCapacity(allCareerRecords)` → `(currentTargetRecords)`),
and the knowledge cross-check already filters to the current target season — so the justification for
keeping historic offers is weaker than when the retention rule was written, not stronger.

### F8. Staff compaction silently destroys the coaching tree's lineage
`Sources/FootballSimCore/Scheduling/WorldScheduler.swift:956-987`, `History/CoachingTreeReadModel.swift:44-66,179`

`compactHistoryBoundState` retains only staff who are currently employed, named by a retained event,
or the player's coach — then drops the rest from both `state.staff` and `people.staffCareers`.

`CoachingTreeReadModel.build` reads **only** `state.people.staffCareers`, and its own docstring
justifies not persisting a second copy on the grounds that `staffCareers` *is* the authority, bounded
"at `PeopleRules.careerSeasonHistoryLimit` assignments per coach" — a bound on assignments **per
record**, not on the number of records. Deleting whole records was never in that reasoning.

Consequence: a coach who retires in season 10 is gone from `staffCareers` in season 11, so
`headCoachesBySeat` loses their seat and every disciple who came up under them silently drops out of
the tree. The `?? "Former coach"` fallback at line 179 becomes unreachable — `state.staff` and
`staffCareers` are now filtered by the *same* set, so a career record can no longer outlive its
staff entity. A fallback that exists precisely for this case is now dead code, which is the tell.

### F9. Team logos work on exactly one world seed, and the UI lets the player pick any seed
`Sources/ProFootballCoachUI/TeamLogoCatalog.generated.swift:9`, `Tools/TeamLogos/manifest.json`, `NewCareerSetupView.swift:88`

The catalog keys 166 assets by `stableID`, which is `programme.id.uuidString` — a value produced by
the seeded RNG. The manifest pins `"worldSeed": 20260812`, matching `CoachWorldStore.defaultSeed`.

`NewCareerSetupView` renders `TextField("World seed", text: $seedText)` and accepts any `UInt64`.
Any seed other than 20260812 produces different UUIDs, so `mark(forStableID:)` returns `nil` for all
166 teams and every surface falls back to the abbreviation chip. Thirty-plus commits, ~330 image
assets and a 2,496-line manifest are load-bearing for one world.

Nothing warns the player, and no test covers a non-default seed — `TeamLogoTests` hard-codes
`bootstrap(seed: 20_260_812)` throughout.

### F10. The rename invalidated the approved logo set, and the approval flags did not move
`Tools/TeamLogos/manifest.json` (regenerated in `c6e2d21`)

Measured on the current manifest:

```
teams: 166
prompts containing "fictional": 1          (was: all 166)
humanApproved: 166
generationStatus == "approved": 166
concepts still naming a deleted place-ending motif: 32
```

Three distinct problems:

1. **The word "fictional" was stripped from 165 of 166 generation prompts.**
   `"...logo for the fictional Oakhaven Heath Upper"` became `"...logo for the Altus, OK City College"`.
   That word is the one piece of the prompt that documents originality intent to the image model.
2. **Concepts are now orphaned from their teams.** `"a bold falcon shaped by the Heath landscape of
   Altus, OK City College"` — "Heath" was a deleted place-ending. `"a single pale-limestone bridge
   arch ... for Carlsbad, NM Normal Institute"` — the bridge motif belonged to "West Ivory *Crossing*".
   The PNGs were not regenerated; only the text was.
3. **Every record still says `humanApproved: true` with `reviewNotes: "Owner approved the
   20/32/44px light/dark specimen on 2026-08-20."`** The approval survived a change that invalidated
   what was approved. An approval flag that does not clear when its subject changes is not a record.

---

## P2 — real, not blocking

### F11. The gate that missed the type-floor defect was never fixed — only the app was
`Tests/SimTests/Suites/ContractTests.swift:968`, `Sources/ProFootballCoachUI/DesignTokens.swift:215`

```swift
expect(CoachWorldTokens.TypeRole.authoredFloor >= 12, "authored text must remain at least 12 points")
```

`authoredFloor` is `public static let authoredFloor: CGFloat = 12`. The assertion compares a constant
to a literal; it can only fail if someone edits the token. It cannot see a view that authors
`.font(.system(size: 7.5))` or scales an 8.5 pt label below the floor.

`docs/STATUS.md` names this exact defect (G-35/G-36: *"the `04b` §8 check that should catch it asserts
`authoredFloor >= 12` — a constant, not a call site"*) and then records the findings **closed** on
2026-08-19. The app was fixed; the gate that failed to catch it was not. The next instance is
undetectable by the same mechanism.

### F12. `PerformanceBudgetTests` is a budget test that cannot fail
`Tests/SimTests/Suites/PerformanceBudgetTests.swift:5,24-32`

The suite is named "Performance evidence probe — no host threshold". It measures recruiting AI and
week advance, then **prints** `"...target 1.200 s; hard ceiling 2.000 s (host measurement; no
pass/fail threshold)"`. The two numbers appear only inside a format string; nothing compares against
them. The sole failure path is `"performance fixture threw"`.

A week-advance regression is caught only by a human reading stdout.

### F13. CI runs one lane; the 8 MB ceiling has no lane at all
`.github/workflows/tests.yml`, `scripts/verify.sh:100-165`, `Tests/SimTests/main.swift`

CI runs `./scripts/verify.sh` with no arguments — the `full` lane, which is `swift build -c release`
plus a no-flag `SimTests` run. The no-flag run is broad (52 suites, including legal, generation,
architecture and design contracts), but every other lane is unreachable from CI:

`soaks`, `calibration`, `archive` (`--m7-gate`), `release`, `accessibility`, `determinism`, `app`.

`SimTests` accepts **68** flags; `verify.sh` wires **17** into lanes. Notably **`--m3-soak` appears
nowhere in `verify.sh`** — the M3 college soak carries the `data.count <= 8 * 1024 * 1024`
assertion (the D4/D7 ceiling), and it is runnable only by hand. The iOS app build (`app` lane) is
also never exercised by CI.

### F14. The rename collapsed the college naming vocabulary and made every name longer
`Sources/FootballSimCore/Generation/NameGrammar.swift:41-49,~760 (institutionWords)`

Measured, seed 4242, 134 programmes:

| | old grammar | new grammar |
|---|---|---|
| suffix vocabulary | State, University, Academy, College, Institute, Technical, Polytechnic, Mining, Agricultural, Maritime, Normal | **Institute (106), College (28)** |
| name length min / median / max | 5 / 20 / 33 | **19 / 29 / 38** |

Every programme is now an Institute or a College. No school can be an `X State` or an `X University` —
the two most characteristic words in American college football naming. Sample output:

```
Albany, NY Regional Institute       Anna Maria, FL Polytechnic Institute
Adairville, KY Maritime Institute   Ambrose, ND Agricultural Institute
```

The minimum name is nearly four times longer than before and the median is up 45%. `docs/STATUS.md`
already records that *"real generated names break the personnel table, the depth chart and the Match
Day field (all three truncate or clip the thing they exist to show)"* — and the same branch added a
20 pt logo to the left of the name in `ScheduleView`, `StandingsView`, `CompetitionOverviewView`,
`WorldSearchView` and `LegacyHistoryView` rows, all of which apply `.lineLimit(1)`. Two changes made
the same defect worse from both ends, at the 844 × 390 install floor.

### F15. Regions, pro teams and venues all inherited the `"City, ST"` shape
`Sources/FootballSimCore/Generation/GameMap.swift:77`, `LeagueGenerator.swift:~200`, `NameGrammar.swift:82`

Generated, seed 4242:

```
REGIONS:    Albion, IA Reach   South Burlington, VT Basin   Albany, IN Tidelands
PRO TEAMS:  Archer Lodge, NC | Timber Wardens      Alton, UT | Storm Kestrels
VENUES:     Alamo, TN Field    Blades, DE Field     Aitkin, MN Stadium
```

A *region* is a multi-state area; naming one after a single small town plus its state code is
nonsense. A pro team's `name` is now literally its `cityName`, so the pro league reads "Archer Lodge,
NC Timber Wardens" — and Archer Lodge NC has roughly 5,000 residents. The old grammar hid market
scale because the towns were invented; real towns make it visible and wrong.

### F16. `institutionName`'s four-way switch has three identical branches
`Sources/FootballSimCore/Generation/NameGrammar.swift:41-49`

```swift
switch rng.int(in: 0...3) {
case 0: return "\(place) Institute"
case 1: return "\(place) \(rng.pick(institutionWords))"
case 2: return "\(place) \(rng.pick(institutionWords))"
default: return "\(place) \(rng.pick(institutionWords))"
}
```

Cases 1, 2 and `default` are the same expression. The switch survives only to preserve the RNG draw
count; what it actually expresses is a 25/75 split. Say that instead of leaving three identical arms
for the next reader to diff.

### F17. `bowlName` has no production caller
`Sources/FootballSimCore/Generation/NameGrammar.swift:57-59`

Its own docstring concedes it: *"The engine currently stores postseason stage rather than a title;
callers that project a bowl badge should use this."* `grep` finds exactly one reference — the new
`LegalTests` case that exercises it. A test whose only subject is uncalled code proves nothing about
the shipped build.

### F18. `EntityStore.values` re-sorts by `uuidString` on every access
`Sources/FootballSimCore/World/EntityStore.swift:37-43`

```swift
public var ids: [UUID] { entitiesByID.keys.sorted { $0.uuidString < $1.uuidString } }
public var values: [Entity] { ids.compactMap { entitiesByID[$0] } }
```

Both are computed properties with no cache. Each `.values` is an *O(n log n)* sort whose comparator
allocates two `String`s per comparison, then *n* dictionary lookups. There are 152 `.values` and 57
`.ids` call sites, 50 of them inside `Engine/`, `Scheduling/` and `College/`.
`NewsFeedReadModel.swift:180-184` walks `programmes`, `proTeams`, `players` and `staff` in
succession — `players` alone is ~14,000 entities — and
`WorldScheduler.compactHistoryBoundState` now adds three more full walks per scheduler step, three
steps per week.

The determinism reason for sorting is correct and should stay. Caching the sorted id array on
mutation instead of recomputing it on read preserves it at a fraction of the cost.

### F19. `CoachWorldTeamLogo.isDecorative` is dead flexibility and its accessibility label is unreachable
`Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift:20,32-33`

```swift
var isDecorative = true
...
.accessibilityLabel(team.name)
.accessibilityHidden(isDecorative)
```

`isDecorative` is never passed at any of the 18 call sites and appears nowhere else in the tree, so
`accessibilityHidden(true)` is unconditional and `accessibilityLabel` never reaches VoiceOver.

Hiding is the *right* call — every placement pairs the logo with a `Text(team.name)`, verified in
`ScheduleView:135`, `StandingsView:138` and the rest — so this is cleanup, not an a11y defect. Drop
the parameter and the label, or set the parameter somewhere.

### F20. `ContractTests`' "reviewed release seams" is a hand-listed spot check
`Tests/SimTests/Suites/ContractTests.swift:974-1000`

The test resolves ~12 named files (`CoachingHQView.swift`, `RosterView.swift`, `DepthChartView.swift`,
`GamePlanView.swift`, …) by `hasSuffix`, each with a `?? ""` fallback, then asserts substrings in
them. A view added tomorrow is not covered until someone remembers to add it — the coverage boundary
becoming the quality boundary, which CLAUDE.md names as a defect in its own right. The neighbouring
`AccessibilityReflowTests` change on this same branch (`f69085d`) fixed exactly this shape by deriving
the expectation from `CoachWorldScreenID.allCases`; this test did not get the same treatment.

(The `?? ""` fallbacks are safe as written — the assertions are all positive `contains`, so a moved
file fails loudly rather than passing silently. Worth keeping that polarity if the test is extended.)

### F21. `SaveEnvelope`'s size commentary contradicts the soak's own gate
`Sources/FootballSimCore/Persistence/SaveEnvelope.swift:52-56` vs `M3CollegeSoakTests.swift:48-52`

> "The current season-20 compressed baseline is about 26 MB; this leaves room for legitimate saves
> while the production 8 MB target is reduced by history compaction"

The soak asserts `data.count <= 8 * 1024 * 1024` at season 20 and passes. One of these is stale.
Given F5–F7, it matters which: if the 26 MB figure is current, the soak is not measuring what the
comment describes; if the soak is current, the parser-ceiling rationale is built on a dead number.

---

## Branch and PR landscape

| | |
|---|---|
| Local branches | 47 · Remote branches | 44 |
| `HEAD` vs `origin/main` | **208 behind, 33 ahead** |
| Local `main` vs `origin/main` | 71 behind, **1 ahead** (unpushed commit on `main`) |
| Files changed on both sides | 22 · conflicting regions: 22 |
| Open PRs | 13, oldest `#6` |

### F22. The same compaction work exists twice, on two different bases
`origin/codex/people-compaction-wip` (`90d96a6`, 9 commits ahead of local `main`) contains the
compaction feature. The identical feature sits **uncommitted** in the working tree of
`agent/floodlit-injury-evidence`, on a different base, already diverged (F7 — the working tree has
dropped `compactedForDeparture()` and narrowed `checkPortalCapacity`). Whichever lands second will
either revert the other's refinements or produce a conflict nobody has context for.

### F23. Four branches are working the same calibration problem
`codex/calibration-m3-terminal-fix` (69 commits), `codex/calibration-handoff-screening` (45),
`codex/calibration-resolutions` (44), `codex/p4-calibration-attempt-7` (31) — plus
`handoff-lifecycle-codex` (41) and `claude/lifecycle-band-validation-a50138` (39) on lifecycle.
`origin/main` has already merged `calibration-m3-terminal-fix` (PRs #55, #56); the other three are
still open against a base that has moved.

Several open PRs carry their unverified status in the title — `#41 "Codex: canonical team logo set
(unverified, needs legal-g…)"`, `#40 "Codex: P4 calibration attempt (unverified, overlaps activ…)"`.
`#42 "Cap career length at 30 seasons (D7)"` is directly relevant to F6's 20-season ceiling.

---

## What was not verified

- The full no-flag suite **did** complete: 967 tests, 787,806 checks, 1 failing test / 2 failed
  checks — F1 and nothing else. It was run from a **debug** binary (`.build/debug/SimTests`) while
  `verify.sh` uses `-c release`, so timings are not comparable, but pass/fail is.
- No soak, calibration, or `--m7-gate` run was performed — each is a 20–85 minute release-mode run.
  Every save-size claim above is therefore reasoning over the code and the constants, not a measured
  30-season save. F5–F7 are argued from the retention rule and the signing rate, and would be settled
  by one 20-season `--m3-soak` in release with the retained-record counts printed.
- No simulator demonstration. Per CLAUDE.md that is an owner action regardless.
- The 90 branches were surveyed for divergence, duplication and conflict surface, not reviewed
  commit-by-commit. F22 and F23 are the structural findings; individual branch contents are not.

## Suggested order

1. **F1** — re-pin `ArchitectureTests` (or explain the drift) so the suite is honest again.
2. **F2** — rebase or merge `origin/main` into this branch *before* any further naming work, and
   resolve `NameGrammar.swift` in favour of main's pool removals.
3. **F3 / F4** — decide whether the place format carries the state code into institution, venue,
   region and team names at all. If it must, the blocklist matcher needs to skip state tokens, and
   the dual-use test needs to enumerate `NameGrammar.realAmericanPlaces` rather than a 42-entry
   parallel list.
4. **F5–F7** — settle whether durable career records are bounded, then make the soak able to see it
   and able to reach 30 seasons.
5. **F9 / F10** — decide whether the logo set is a fixed-seed beta artefact (say so in the UI) or a
   general feature, and clear the approval flags the rename invalidated.
