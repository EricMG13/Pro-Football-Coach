# Release review — Pro Football Coach

**Date:** 2026-08-20
**Branch reviewed:** `agent/floodlit-injury-evidence` @ `c0f4334`, plus the uncommitted working tree
**Also reviewed:** `origin/main` @ `087a60d`, local `main` @ `17e2d43`, and all 57 local branches
**Platform:** iOS 26+, iPhone-only, landscape-only. Distribution: TestFlight then paid App Store.
**Reviewer stance:** adversarial. Findings are stated as defects.

---

## Method, and what it does and does not prove

- Toolchain **is** available here: Swift 6.3.3, Xcode 26.6. That is unusual for this repo's history
  and it means several claims below were checked against source rather than guessed.
- **Four builds were run and measured**, all recorded in [§9](#9-suite-result--the-full-lane-is-red):
  the full lane on the working tree; the determinism lane on a clean `git archive` extract of `HEAD`;
  the same lane on a clean extract of `c6e2d21^` to bisect the failure; and the app lane
  (xcodegen + `xcodebuild` for `generic/platform=iOS`), whose output bundle supplied the size and
  `Info.plist` measurements in C-01 and C-02.
- **No code was written or changed.** Nothing was committed, staged, or unstaged; the extracts were
  read-only copies in a scratch directory, and the repository was not mutated in any way.
- No simulator was driven. This review does not supersede
  `docs/reviews/2026-08-18-floodlit-exhaustive-design-critique.md`, which drove a real career at the
  install floor and found 80 per-surface defects. Where that review already owns a finding, this one
  says so and does not restate it.
- What this review adds over the existing registers
  (`docs/BETA-READINESS-CONSOLIDATED.md`, the design critique, `docs/HANDOFF-CODEX-2026-08-20.md`):
  distribution readiness, branch/integration state, test-instrument integrity, asset payload, and
  the naming and retention changes that landed *after* those registers were written.

---

## Summary

| Priority | Count |
|---|---|
| Critical (release-blocking) | 8 |
| High | 14 |
| Medium | 13 |
| Low | 4 |

**Verdict: not shippable, and not currently assemblable.**

Two of the eight criticals are not code defects at all: there is no integrated release candidate
(C-03), and there is no app icon (C-01). Two are performance and durability budgets the project's own
documents record as exceeded — a 4.031 s week advance against 2.0 s (C-04) and a 14.76 MB save
against 8 MB (C-05). The remaining four all trace to work that landed in the last two days:
157 MB of logos sized for a poster (C-02), keyed so that they resolve at exactly one world seed out
of 2⁶⁴ (C-02b), and a place table that puts a comma and a state code inside every school, team,
stadium and region name (C-06) while making two thirds of them start with the letter A (C-07).

That last cluster is the useful signal in this review: **the newest, least-reviewed work is where the
worst defects are**, and it went in on a branch that is 208 commits behind `origin/main`, which carries the
remediation everybody agreed to.

**The full lane was run and it is red, and the cause is bisected.** 964 tests, 787,761 checks, one
failing test — the cross-process determinism gate, with both pinned root fingerprints moved. A clean
extract of `c6e2d21^` passes that lane; `HEAD` fails it with identical values whether or not the
uncommitted work is present. **`c6e2d21`, the naming commit, broke it, and nothing has caught that
for a day.** Full method and numbers in [§9](#9-suite-result--the-full-lane-is-red).

The engineering underneath is much better than that verdict suggests. Determinism, the legal test
mechanism, and persistence safety are genuinely well built. Section 8 says so specifically.

---

## 1. Critical — must fix before any build goes out

### C-01 · Distribution · There is no app icon anywhere in the project

**Evidence:** the only asset catalog in the shipping target is
`Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets`. There is no `Assets.xcassets`, no
`AppIcon.appiconset`, no `.icon` file, and no `INFOPLIST_KEY_CFBundleIconName` in
[App/project.yml](App/project.yml). Confirmed by searching the whole tree; the only `AppIcon*` hits
are inside `node_modules` in a worktree.

**Confirmed from the built artifact, not from the sources.** The device build's `Info.plist` was
dumped with `plutil -p`. Its complete key list is `CFBundleDisplayName`, `CFBundleIdentifier`,
`CFBundleShortVersionString` 1.0, `CFBundleVersion` 1, `MinimumOSVersion` 26.0, `UIDeviceFamily` [1],
`UILaunchScreen`, `UIRequiredDeviceCapabilities` [arm64], `UISupportedInterfaceOrientations`
[LandscapeLeft, LandscapeRight], plus build metadata. There is **no `CFBundleIconName` and no
`CFBundleIcons` — no icon key of any kind**. There is likewise no `PrivacyInfo.xcprivacy` anywhere in
the bundle (H-11) and no `ITSAppUsesNonExemptEncryption` (H-09).

**Impact:** App Store Connect rejects an upload with no 1024×1024 icon. TestFlight builds show the
generic placeholder. This blocks the first external build, not the last one.

The same plist dump is the positive evidence for the orientation policy: landscape-only, iPhone-only,
iOS 26 floor, arm64 — all present and correct.

### C-02 · Payload · 157 MB of 1024×1024 logos to draw marks at 20, 32 and 44 points

**Evidence:**
- `du -sh Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets` → **157 MB**, 166 PNGs, every one
  1024 × 1024 (verified with `sips` across all 166 — no other size exists).
- [CoachWorldTeamLogo.swift:9](Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift:9) declares the
  only three render sizes: `compact = 20`, `medium = 32`, `large = 44` points. At @3x the largest is
  **132 physical pixels**.
- Every `Contents.json` declares a single `"scale":"1x"`, `"idiom":"universal"` entry. With one
  universal 1× slice, App Store thinning has nothing to strip and the 1024 px bitmap ships to every
  device.
- The catalog copy is on the critical path of every build. In this review's run,
  `[5/8] Copying TeamLogos.xcassets` held the build for minutes; CI pays it on every push.

**Impact, three separate ways.** Download size for a text-and-tables management sim whose executable
is 57 KB. Runtime memory: a decoded 1024×1024 RGBA image is 4 MB, and `StandingsView` draws a
column of them — sixteen visible rows is 64 MB of decoded bitmaps for 32-point marks. And the
non-catalog fallback path in `packagedImage`, `UIImage(contentsOfFile:)`, is uncached, so it
re-decodes 1 MB per appearance.

**Measured on a real device build, not inferred.** `./scripts/verify.sh --lane app` was run
(xcodegen + `xcodebuild -destination 'generic/platform=iOS'`); it **succeeded**, and the resulting
`.app` was inspected:

| Artifact | Size |
|---|---|
| `ProFootballCoach.app` (Debug, `iphoneos`) | **155 MB** |
| `ProFootballCoach_ProFootballCoachUI.bundle/Assets.car` | **109.6 MB** |
| `ProFootballCoach.debug.dylib` | 45.5 MB — stripped in Release |
| `ProFootballCoach` executable | 72 KB |

The resource bundle contains exactly two files: `Assets.car` and `Info.plist`. So the compiled
catalog is 109.6 MB, and a **Release build lands around 110–115 MB, of which roughly 95 % is team
logos** for a management sim whose executable is 72 KB.

**Note:** at 132 px maximum, a 256 × 256 asset is already generous. The corrected catalog is on the
order of 10 MB, not 110.

**One thing this build settles positively:** the bundle is clean — six top-level entries, no `.pcm`
module caches, no `.xcodeproj`, no header maps. `BETA-READINESS` STOP-08 is fixed, and the junk in
`App/build` (L-04) is genuinely just a stale 2026-08-12 directory.

### C-02b · Content · The 157 MB of logos only work at one world seed out of 2⁶⁴

**Evidence, end to end:**

1. `TeamLogoCatalog.generated.swift` is a dictionary `[stableID: assetName]` whose keys are **team
   UUIDs**: `"0017F958-E7D0-4FFC-9EA8-01A252B40FD6": "TeamLogo_0017F958E7D04FFC9EA801A252B40FD6"`.
2. Lookup is by UUID:
   [CoachWorldReadModelProvider.swift:471](Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:471)
   — `CoachWorldTeamLogoCatalog.mark(forStableID: id.uuidString)`.
3. Team UUIDs come from the seeded RNG:
   [LeagueGenerator.swift](Sources/FootballSimCore/Generation/LeagueGenerator.swift) uses
   `let programmeID = rng.uuid()` and `let teamID = rng.uuid()`.
4. The manifest pins the seed: `TeamLogoTests` asserts
   `expectEqual(manifest.worldSeed, 20_260_812)` and
   `expectEqual(Set(manifest.teams.map(\.stableID)), Set(worldIDs))` against
   `GameState.bootstrap(seed: 20_260_812)`. `CoachWorldStore.defaultSeed` is `20_260_812`.
5. The seed is player-editable:
   [NewCareerSetupView.swift:88](Sources/ProFootballCoachUI/NewCareerSetupView.swift:88) —
   `TextField("World seed", text: $seedText, onCommit: refreshJobsForSeed)`, and `onStart` passes
   whatever `UInt64` the player typed.

**So: any seed other than 20260812 produces 166 different UUIDs, every `assetNames[stableID]` lookup
misses, and every team in the career falls back to a three-letter abbreviation chip
([CoachWorldTeamLogo.swift:65](Sources/ProFootballCoachUI/CoachWorldTeamLogo.swift:65)) — while the
app still carries all 157 MB.**

No test covers a non-default seed for logo resolution. The failure is total and silent: not one
missing mark, all of them.

`NameGrammar.placeName` even carries the comment *"Keep the two-draw shape of the former stem/ending
grammar so stable IDs remain stable"* — the coupling is known and was deliberately preserved through
C-06, which is what makes its fragility a design decision rather than an accident.

**The shape of the fix is a product decision, not a bug fix.** Either the seed field goes (and the
game ships one canonical world, which would also fix G-44 and G-45 from the design critique), or the
mark is chosen by a seed-independent derivation — index within conference, or a hash of the team's
own generated identity — so that any world gets a stable, distinct mark. Re-exporting at 256 px
(C-02) should happen in the same pass.

### C-03 · Integration · The branch under review is 208 commits behind `origin/main` and is missing the entire P0/P1 remediation pass

**Evidence:** `git rev-list --left-right --count main...HEAD` → `138 33`, merge base `91a108d`
(2026-08-19). But local `main` is itself stale: `git rev-list --count main..origin/main` → **71**,
so the real gap is

```
HEAD..origin/main   208
HEAD..main          138
main..origin/main    71
```

**208 commits, not 138.** Anyone measuring against the local `main` — as an earlier draft of this
section did — understates the gap by a third. The 138 commits on local `main` that this branch does
not have include, by their own subjects:

- `763c6e5 fix: give Settings & Accessibility one real choice`
- `ec95a81 fix: give VoiceOver and AX5 a reachable Depth Chart position-group control`
- `66ff380 fix: give Coaching HQ's AX5 composition a way to advance the week`
- `4fb3141 fix: stop six league views silently no-opping on a malformed team id`
- `fc3bc71 fix: stop Match Day's control-depth picker promising a choice it never had`
- `094a2d1 fix: converge the three disagreeing rating-colour scales on canon`
- `2967658`, `7cbe289`, `df85c52`, `f44b467`, `c8dfda2`, `8a6104c`, `83b3df1`, `30247bf`, `648207f`,
  `f11b512`, `7b4bb81`, `8b929c5`, `da025d2`, `5867204`, `f322deb` …

That is the remediation the 2026-08-18 critique demanded. `docs/STATUS.md`'s "Closed 2026-08-19:
G-01, G-02, G-05, G-35 and G-36 no longer describe the current app" is true **of `main`**, and the
STATUS file asserting it sits on a branch that does not contain the fixes.

**Measured gap.** `git diff HEAD main --stat -- Sources Tests`: **454 files changed, 4,551
insertions, 4,644 deletions**, concentrated in **54 files under `Sources/ProFootballCoachUI`** and
**30 test suites**. The single largest divergence is
`Sources/CoachWorldApp/CoachWorldAppRootView.swift` at **521 changed lines** — the navigation root,
which is exactly where G-01's fix lives — followed by `AccessibilityReflowTests.swift` (216) and
`DesignContractTests.swift` (111). This is not a merge; it is a reconciliation.

**The wider picture.** 14 branches were last committed on 2026-08-20 and none are merged:

| Branch | Commits ahead of `main` |
|---|---|
| `codex/calibration-m3-terminal-fix` | 69 |
| `codex/handoff-pointer` | 46 |
| `codex/calibration-handoff-screening` | 45 |
| `codex/calibration-resolutions` | 44 |
| `codex/handoff-resolutions` | 42 |
| `claude/lifecycle-band-validation-a50138` | 39 |
| `agent/floodlit-injury-evidence` (this one) | 33 |
| `codex/team-logos` | 31 |
| `claude/coach-career-promotion-integrity-f10168` | 28 |
| `claude/priceless-bhaskara-94199a`, `claude/twotier-consistency-tests-runner-11d4f1` | 14 each |
| `claude/tighten-calibration-bands-0a1924`, `docs/handoff-codex-calibration`, `claude/career-length-cap-30` | 11, 10, 3 |

Four of them — `calibration-m3-terminal-fix`, `lifecycle-band-validation`,
`coach-career-promotion-integrity` and the calibration siblings — share merge base `45d6ee1` and all
edit the *same* engine files: `Calibration/Band.swift`, `CalibrationHarness.swift`,
`Career/CareerControlState.swift`, `College/CollegePortalState.swift`, `Engine/DriveEngine.swift`,
`Engine/GameEngine.swift`. They are parallel, mutually-conflicting rewrites of one surface.

**Impact:** there is no branch that is a release candidate. Shipping from this one ships the UI the
critique rejected; shipping from `main` drops the logos and the naming work; merging is a
multi-hundred-commit reconciliation across four conflicting engine forks. This is the single item
that gates every other fix, because there is nowhere to land them.

### C-04 · Performance · Week advance is measured at 4.031 s against a 2.0 s ceiling

**Evidence:** [PRODUCT.md](PRODUCT.md), the repo's own "Unverified product targets" table:

> Week advance under 2.0 s at shipping league size | The host performance probe measured recruiting
> AI at 1.260 s and full week advance at **4.031 s** on a Release Mac at 134 programmes; the 2.0 s
> ceiling is exceeded and the iPhone gate remains open

That is a Release build on desktop silicon. An iPhone is slower, and the iPhone measurement has
never been taken. Advancing the week is the core verb of the game.

**And nothing guards it.** [PerformanceBudgetTests.swift:5](Tests/SimTests/Suites/PerformanceBudgetTests.swift:5)
is `runPerformanceBudgetProbe`, whose own suite name is *"Performance evidence probe — no host
threshold"*; it prints a measurement and asserts only that 134 programmes exist and that the
recruiting AI returned something. [SuiteCatalog.swift](Tests/SimTests/SuiteCatalog.swift) then
asserts, deliberately, `expect(!SuiteCatalog.entries.contains { $0.gate.rawValue == "PerformanceBudgetTests" })`
— the budget is registered as *not* a gate. The file name says budget; nothing in it can fail on
budget.

### C-05 · Persistence · Saves are 1.8× to 4.6× over the 8 MB ceiling, and the in-flight fix makes it worse

**Evidence:** [docs/HANDOFF-CODEX-2026-08-20.md](docs/HANDOFF-CODEX-2026-08-20.md) records
**≈37.11 MB at season 30** and **≈14.76 MB at season 20** after the retention branch, against D7's
8 MB. `PRODUCT.md` lists "A save survives 20 seasons under 8 MB" as unverified.

The uncommitted working tree contains the current attempt at a fix, and it moves the wrong way. See
[H-05](#h-05--persistence--the-uncommitted-retention-edit-is-a-regression-and-its-new-test-subtracts-the-unbounded-term)
for the mechanism; it belongs to this critical.

### C-06 · Content · Every generated name now reads as a data field

**Evidence:** commit `c6e2d21 feat: use real places and generic postseason names`, the second commit
from the tip of this branch. `NameGrammar.realAmericanPlaces` holds 570 **state-qualified** strings
— `"Adak, AK"`, `"Abbeville, AL"`, `"Apache Junction, AZ"`, `"Agra, OK"`, `"Antelope, OR"` — and
`LegalTests` pins that shape: `expect(places.allSatisfy { $0.contains(", ") })`.

Those strings are interpolated directly into names, with nothing stripping the comma or the state
code:

| Producer | Result |
|---|---|
| [NameGrammar.swift:44](Sources/FootballSimCore/Generation/NameGrammar.swift:44) `institutionName` via [LeagueGenerator.swift:148](Sources/FootballSimCore/Generation/LeagueGenerator.swift:148) | programme **"Apache Junction, AZ Agricultural Institute"** |
| [LeagueGenerator.swift:194](Sources/FootballSimCore/Generation/LeagueGenerator.swift:194) `name: city.name` | pro team name **"Adak, AK"**, displayed as `"\(cityName) \(nickname)"` → **"Adak, AK Iron Kestrels"** |
| [GameMap.swift:77](Sources/FootballSimCore/Generation/GameMap.swift:77) | region **"Adona, AR Reach"** |
| [NameGrammar.swift:81](Sources/FootballSimCore/Generation/NameGrammar.swift:81) `venueName` | stadium **"Abbeville, AL Field"** |
| [NameGrammar.swift:57](Sources/FootballSimCore/Generation/NameGrammar.swift:57) `bowlName` | postseason **"Adona, AR Classic"** |

No formatter, splitter or state-stripping helper exists anywhere in `Sources` (searched for
`split(separator: ",")`, `components(separatedBy: ",")`, `stateAbbrev`, `shortPlace` — zero hits).
The UI renders them raw: `Text("\(place.cityName) · \(place.regionName)")`
([LeagueMapView.swift:526](Sources/ProFootballCoachUI/LeagueMapView.swift:526)) →
`"Abbeville, AL · Adona, AR Reach"`.

**Three consequences, each independent.**

1. **It reads wrong.** Nothing in the game is now named the way a school, a team or a stadium is
   named.
2. **It is longer, into layouts already known to clip.** The 2026-08-18 critique's G-25/26/27
   recorded that real generated names already broke the personnel table, the depth chart and the
   Match Day field, at names like *"Marrow Hollow Normal"* (20 characters). The longest name this
   change can produce is *"Apache Junction, AZ Agricultural Institute"* — **41 characters**. Those
   three findings were never closed, and the change that landed after them roughly doubled the
   input. Nothing measured it.
3. **VoiceOver degrades.** [TeamProgrammeProfileView.swift:90](Sources/ProFootballCoachUI/TeamProgrammeProfileView.swift:90)
   builds `"\(model.team.name), \(model.cityName), \(model.tier), \(conferenceLine)"` →
   *"Apache Junction, AZ Agricultural Institute, Apache Junction, AZ, College, …"*: the city is
   spoken twice and the state code is spoken as two letters.

**It also left the branch red.** Bisected in [§9.1a](#91a-bisect--the-breaking-commit-is-c6e2d21):
`c6e2d21^` passes the cross-process determinism lane, `c6e2d21` and everything after it fails it.
The commit re-pinned `GenerationTests`' two digests and never opened `ArchitectureTests.swift`,
which carries the other two.

**Process note.** `docs/STATUS.md` previously said, of exactly this change: *"Populating it with real
geography is a separate design change that would touch D6's geography-driven rivalry seeding, and
under the doc-first amendment rule it belongs in canon before it is built."* Commit `c6e2d21`
implemented it and rewrote that paragraph in the same commit. `docs/02-GAME-DESIGN.md` was not
amended — it is not in the commit's file list. That is a direct doc-first violation under
`CLAUDE.md`, on the change with the largest player-visible blast radius on the branch, and the same
commit shipped a failing release gate.

### C-07 · Content · Two thirds of every generated world begins with the letter A

**Evidence.** First-letter distribution of the 570 entries in `NameGrammar.realAmericanPlaces`:

| Initial | Count | Share |
|---|---|---|
| A | **380** | 67 % |
| B | 110 | 19 % |
| C | 29 | 5 % |
| D–Z combined | 51 | 9 % |

The list is ordered `"Adak, AK"`, `"Abbeville, AL"`, `"Adona, AR"`, `"Apache Junction, AZ"`,
`"Adelanto, CA"`, `"Aguilar, CO"`, `"Ansonia, CT"`, `"Bellefonte, DE"`, `"Alachua, FL"`,
`"Abbeville, GA"`, `"Ackley, IA"` … — **the alphabetically-first entries of each state**, cycling
through the state list and only reaching B or C where a state has no A-named place. This is a
sampling artefact of how the Gazetteer was read, not a choice.

**Consequence.** Every save draws 166 of these without replacement, so roughly 110 of the 134
college programmes and most of the 32 professional teams are named after a place starting with A.
The whole world reads as one alphabetical page: Abbeville Technical Institute, Adak, Adona Classic,
Alachua Field, Ansonia Polytechnic Institute.

**It also breaks abbreviations.** `CoachWorldReadModelProvider.abbreviation(_:)` is
`String(name.filter(\.isLetter).prefix(3)).uppercased()`
([CoachWorldReadModelProvider.swift:488](Sources/CoachWorldApp/CoachWorldReadModelProvider.swift:488)).
The 570 places collapse to only **198 distinct three-letter prefixes**, and the worst buckets are
brutal: **35 places share `ALB`**, 22 share `ALT`, 17 `ALL`, 15 `ADA`. So a single league routinely
contains several teams whose compact identity is the same three letters — in standings, schedules
and the score bug. There is no uniqueness pass over abbreviations anywhere.

That collision matters twice over, because per
[C-02b](#c-02b--content--the-157-mb-of-logos-only-work-at-one-world-seed-out-of-2⁶⁴) the
abbreviation chip **is** the team's entire visual identity at any non-default seed.

**Fix scope:** this one is cheap relative to its impact. A properly sampled place list — largest
places per state, or a uniform sample across the Gazetteer — fixes the alphabetical skew, materially
reduces prefix collisions, and (by favouring places people have heard of) also softens
[H-08](#h-08--content--the-place-pool-is-570-small-towns-and-the-pro-league-is-sited-in-them). It
does not fix C-06, which is about the `", ST"` suffix, and both live in the same table.

---

## 2. High

### H-01 · Verification · Five of the fourteen default release gates are grep-over-source

**Evidence:** `Tests/SimTests/Suites/ContractTests.swift` contains **408** `.contains("…")`
assertions against the *text* of source files (454 across all suites). Samples, verbatim:

```
appRoot.contains(".onDisappear { personnelPlayerID = nil }")
root.contains(".preferredColorScheme(.dark)")
!recruiting.contains("onTapGesture")
inbox.contains("minimumTarget")
staffRoomModel.contains("public struct StaffRoomReadModel")
```

`SuiteCatalog` routes **`contrastByConstruction`, `voiceOver`, `touchTarget`, `reachability` and
`errorSurface`** to `runContractTests` via `--core-contracts`. So five of the fourteen gates in
`SuiteCatalog.defaultRun` are satisfied by a string existing in a file.

The touch-target gate is the clearest case. It asserts
[`CoachWorldTokens.Shape.minimumTarget >= 44`](Tests/SimTests/Suites/ContractTests.swift:966) — a
constant comparing itself — and elsewhere that a source file *contains the word* `minimumTarget`. No
control's frame is ever measured. `PRODUCT.md` lists "44 pt touch targets | `TouchTargetTest`" as a
product commitment.

These assertions also fail on formatting: a `swift-format` pass that respaced
`{ personnelPlayerID = nil }` would turn the suite red without changing behaviour, which is the
inverse of what a test should do.

**This is the mechanism by which 80 design defects passed a green suite.**

**The distinction that matters, because the repository gets it right elsewhere.** Source scanning is
the correct instrument for a *structural* property, and this codebase has two good examples:
`ArchitectureTests`' engine/UI import boundary (a rule about what a file may name), and
`ReduceMotionContractTests` (a rule that every Tier-B animation construct routes through the
`coachWorldAnimation` choke point). Both scan source, both carry planted-construct self-tests in
both directions, and both are checking exactly the kind of claim a scan can settle. Neither is
implicated here.

The defect is the assertions that stand in for *rendered behaviour* — a 44-point target, a spoken
label, a reachable route, an error surface. Those are claims about what the app does on a screen, and
no amount of substring matching can settle them.

### H-02 · Verification · No rendered UI test of the shipping app runs anywhere

**Evidence:** [Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift](Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift)
is 105 lines. It contains `func testLaunchContractIsRegistered() { XCTAssertTrue(true) }` and one
XCUITest that launches with `--redesigned-job-board` — the DEBUG proof harness — and asserts, in its
own words, *"No save was changed."* `Tests/ProFootballCoachTests` is 17 lines.

Neither runs. [.github/workflows/tests.yml](.github/workflows/tests.yml) runs `./scripts/verify.sh`
with no arguments, which is the `full` lane: `swift build` plus the default SimTests run. The `app`
lane exists but only calls `xcodebuild … build` — never `test` — and CI never selects it.

So the only rendered test of the product exercises a prototype screen, and it is never executed.

### H-03 · Verification · Fifteen test suites are defined and never run by default or by CI

**Evidence:** comparing every `func run*()` defined under `Tests/SimTests` against the calls in
`main.swift`'s no-argument branch, these are defined and not called:

`runProfessionalCareerSessionTests`, `runWeeklyAuthorityTests`, `runInjuryEvidenceTests`,
`runHistoryGateTests`, `runM1SoakTests`, `runM2SoakTests`, `runM3CollegeSoakTests`,
`runM3RecruitingCalibrationTests`, `runProSoakTests`, `runProWeekWalkTests`,
`runProDraftProbeTests`, `runProMarketRootProbe`, `runPerformanceBudgetProbe`,
`runWeekAdvanceTimingProbe`, `runInvalidRedshirtCareerGamesProbe`.

**And eleven of the fifteen have no `verify.sh` lane either.** Cross-referencing every `--flag` in
`main.swift` against every flag any lane invokes: `--m7-gate` (archive lane), `--m1-soak`/`--m2-soak`
(soaks lane) and `--m3-recruiting-calibration` (calibration lane) are at least *runnable by name*.
These eleven are reachable only by typing the flag by hand:

`--injury-evidence`, `--m3-soak`, `--performance-budget`, `--pro-soak`, `--pro-week-walk`,
`--pro-draft-probe`, `--pro-market-root-probe`, `--professional-career-session`,
`--weekly-authority`, `--week-advance-timing`, `--redshirt-invalid-*-career-games-probe`.

Four of those matter disproportionately:

- **`--professional-career-session`** — the professional half of the career, which `CLAUDE.md`
  calls a v1 feature, not a sequel.
- **`--weekly-authority`** — the weekly authority model, i.e. the core loop's permission system.
- **`--injury-evidence`** — the feature this branch is *named after*.
- **`--m3-soak`** — `M3CollegeSoakTests`, which contains the **only** assertion in the repository
  of the 8 MB save ceiling
  ([M3CollegeSoakTests.swift:50](Tests/SimTests/Suites/M3CollegeSoakTests.swift:50)). It is in no
  lane, in no default run, and in no CI job. That is why C-05 could reach 14.76 MB without anything
  going red.

### H-04 · Verification · CI runs one lane, and the lane registry names lanes that do not exist

**Evidence:** `verify.sh` accepts `accessibility|app|archive|calibration|core|determinism|full|release|soaks`
([scripts/verify.sh:36](scripts/verify.sh:36)). `SuiteCatalog.lane(for:)`
([Tests/SimTests/SuiteCatalog.swift:55](Tests/SimTests/SuiteCatalog.swift:55)) returns
**`"persistence"`** for the four save gates and **`"legal"`** for the legal gate. Neither is a lane;
`verify.sh` would exit 2 with `unknown lane`.

Nothing cross-checks them. The commitment-coverage test verifies only that each gate's *command
string* appears in `main.swift`; it never validates the lane. So the two legal tests that `CLAUDE.md`
calls mandatory have no lane of their own, and `saveWriteBudget` is additionally absent from
`SuiteCatalog.defaultRun` — the D7 write budget runs nowhere.

CI running only `full` also means the app never compiles in CI, the soaks never run in CI,
calibration never runs in CI, and the M7 history gate never runs in CI. Two commits on `main` are
literally titled `chore: trigger CI (no CI had ever run on this branch)`.

### H-05 · Persistence · The uncommitted retention edit is a regression, and its new test subtracts the unbounded term

This is the mechanism behind [C-05](#c-05--persistence--saves-are-18-to-46-over-the-8-mb-ceiling-and-the-in-flight-fix-makes-it-worse).
The working tree is **half-staged**: `git diff --cached` and `git diff` differ for
`Sources/FootballSimCore/People/PeopleState.swift` by 29 lines, and the two halves disagree about
the design.

**The staged half** keeps `PlayerCareerRecord.compactedForDeparture()` and a two-tier policy: full
record for active-or-cited players, slim record (season aggregates only, `portalWindows: []`) for
everyone else, drop beyond the bound. Bounded per record.

**The unstaged half deletes `compactedForDeparture()` entirely** and replaces the policy with:

```swift
retainedDepartedPlayerIDs.formUnion(playerCareers.compactMap { id, career in
    guard playerLifecycle[id] == nil,
          career.recruitingOrigin != nil || !career.portalWindows.isEmpty else { return nil }
    return id
})
```
— [PeopleState.swift:1084](Sources/FootballSimCore/People/PeopleState.swift:1084) — and then stores
the **full** record for every id in that set.

Every college player who was ever signed carries a `recruitingOrigin`; `M3CollegeSoakTests` itself
counts recruits that way. So the clause retains, at full size, forever, every player the world has
ever recruited — roughly 134 programmes × a signing class per season. The
`PeopleRules.maximumRetainedDepartedPlayers = 4_096` bound added in the same change applies only to
`recentlyEndedPlayerIDs`, a set this clause bypasses.

**The new soak assertions cannot see it.** [M3CollegeSoakTests.swift:123](Tests/SimTests/Suites/M3CollegeSoakTests.swift:123)
defines

```swift
let durablePlayerIDs = Set(state.people.playerCareers.compactMap { id, career in
    career.recruitingOrigin != nil || !career.portalWindows.isEmpty ? id : nil
})
```

— the *same predicate as the production retention clause* — folds it into `retainedPlayerIDs`, and
then asserts

```swift
expect(departedPlayerIDs.subtracting(exceptionalDepartedPlayerIDs).count
    <= PeopleRules.maximumRetainedDepartedPlayers)
expect(departedPlayerIDs.count <= PeopleRules.maximumRetainedDepartedPlayers
    + exceptionalDepartedPlayerIDs.count)
```

where `exceptionalDepartedPlayerIDs ⊇ departedPlayerIDs ∩ durablePlayerIDs`. Both assertions
subtract out the one term that grows without bound, and the second is algebraically implied by the
first. The suite can report the growth as bounded while it is not.

The only real backstop is the 8 MB assertion in the same file — and per [H-03](#h-03--verification--fifteen-test-suites-are-defined-and-never-run-by-default-or-by-ci)
that soak is not in the default run or in CI.

Note that the staged half has its own defect, already recorded independently as P1 in
`docs/HANDOFF-CODEX-2026-08-20.md`: dropping `portalWindows` loses portal history that portal
capacity validation later needs. Neither half is correct; the correct shape is the staged half's
two-tier policy with the cited-set widened to cover portal validation, not the unstaged half's
unbounded retention.

### H-06 · Accessibility · The authored type floor is a constant that nothing enforces, and names just got longer

**Evidence:** [DesignTokens.swift:215](Sources/ProFootballCoachUI/DesignTokens.swift:215) declares
`authoredFloor: CGFloat = 12`. Five lines above it,
[DesignTokens.swift:209](Sources/ProFootballCoachUI/DesignTokens.swift:209) declares
`microLabelSize: CGFloat = 10`, a real and widely used token. `FloodlitChrome` adds `railLabel = 9`,
`familySize = 9`, `siblingSize = 9.5`, `recordSize = 11`; `DisplaySize.pill = 10.5`, `.flag = 9`.

The gate is [ContractTests.swift:968](Tests/SimTests/Suites/ContractTests.swift:968):
`expect(CoachWorldTokens.TypeRole.authoredFloor >= 12)`. It compares the constant to itself. No call
site is checked, which is exactly the defect the 2026-08-18 critique raised as G-36 and which is
still present here.

**The shrink floors compound it.** Six views declare `nameScaleFloor: CGFloat = 0.6`
(`TeamProgrammeProfileView`, `CareerHubView`, `DevelopmentPlanView`, `GamePlanView`,
`ProspectProfileView`, `CoachingHQView`), applied to `DisplaySize.figure = 34` with
`lineLimit(2)`. `CoachWorldVocabulary.swift:235` uses a bare `.minimumScaleFactor(0.6)`.

Shrink-to-fit is designed for the exceptional long name. After C-06 the *typical* name is 30–41
characters, so the 0.6 floor becomes the normal rendering path rather than the exception.

### H-07 · Design coherence · Real place names sit on a fake map

**Evidence:** `GameMap.generate` ([GameMap.swift:98](Sources/FootballSimCore/Generation/GameMap.swift:98))
assigns each real city a **random** grid coordinate inside a random region centre, and
`marketSize: Rating(rng.int(in: 40...99))` — a random number, under a docstring that reads
*"Population on the rating scale."* Region names are `"<random real city> <regionWord>"`.

So Adak, Alaska can neighbour Key West on the map that drives recruiting reach, travel fatigue and
rivalry candidacy (D6: *"Place is a mechanic, not flavour text"*), and a town of a few hundred people
can carry a market size of 99.

The invented-place design had no such problem: an invented map may be arbitrary. Using real names
imports the player's own knowledge as a correctness oracle and then contradicts it. This is a design
consequence of C-06 that no test covers and that no canon document authorises.

### H-08 · Content · The place pool is 570 small towns, and the pro league is sited in them

**Evidence:** the pool is drawn from the Census Gazetteer and is dominated by places such as
`"Adak, AK"`, `"Adona, AR"`, `"Agra, OK"`, `"Antelope, OR"`, `"Beachwood, OH"`. Of seventeen major
sports markets checked, only `"Boston, MA"` and `"Baltimore, MD"` are present.

Legally this is the conservative choice and it is worth keeping. Dramatically it means a
professional league of 32 franchises plays in towns of a few hundred people, which is the register
the whole broadcast presentation is authored against.

### H-09 · Distribution · No export-compliance declaration

**Evidence:** `App/project.yml` sets no `ITSAppUsesNonExemptEncryption`. The app has no networking
and no cryptography (verified: zero `URLSession`, zero `import Network`, zero `http`/`https`
literals in `Sources` or `App`), so the correct value is `false` and it is a one-key declaration.
Without it, every TestFlight build stalls on a manual export-compliance answer before it can be
distributed.

### H-10 · Calibration · No lane asserts that any calibration band holds

**Evidence:** `CalibrationBands.all` declares 24 bands (points per team-game, pass yards,
completion percentage, interceptions, sacks, field-goal percentage, and so on, per tier). The suite
that runs them, `runCalibrationTests()`, contains exactly four harness tests
([CalibrationTests.swift:195–227](Tests/SimTests/Suites/CalibrationTests.swift:195)):

1. two runs of the same two seeds produce the same numbers,
2. the harness *reports on* as many bands as the tier declares,
3. the talent ladder produces mismatched matchups,
4. plus the `Band`/`Estimate`/TOST self-tests above them.

Every `.passed` assertion in the file — lines 19, 29, 41, 89, 95 — is against an `Estimate`
**constructed inside the test**. Not one is against a `CalibrationHarness.run(...)` result. There is
no `expect(result.passed)` for a measured metric anywhere in the repository.

`verify.sh --lane calibration` dispatches `--calibration`, and `main.swift:95` maps `--calibration`
to this same `runCalibrationTests()`. So the calibration lane is a self-test of the statistics
library plus a two-seed smoke run.

**Impact:** the match model's realism is entirely ungated. The "21 of 24 bands hold" figure that
STATUS and the handoffs quote is a manual measurement, not a gate, and nothing prevents a tuning
change from silently moving a passing band out of range. The band table is well built — it uses TOST
so an imprecise estimate inside the band still fails, which is the right statistic — and it is
wired to nothing.

### H-11 · Privacy · A privacy manifest is required, and there is none

**Evidence:** [CoachWorldSaveStore.swift:246](Sources/CoachWorldApp/CoachWorldSaveStore.swift:246)
calls `FileManager.default.attributesOfItem(atPath:)` on the save file to read its size before
decoding. `NSFileManager.attributesOfItemAtPath` is on Apple's required-reason list under
`NSPrivacyAccessedAPICategoryFileTimestamp`, so the app must ship a `PrivacyInfo.xcprivacy`
declaring that category with reason `C617.1` (metadata of files inside the app's own container).
There is no `PrivacyInfo.xcprivacy` anywhere in the tree.

**Impact:** uploads draw ITMS-91053 ("Missing API declaration"), which is currently a rejection for
new submissions.

**The good news is how small the manifest is.** This is the *only* required-reason API in the whole
app — verified by searching for `UserDefaults`, disk-space keys, `URLResourceValues`,
`creationDate`, `contentModificationDate`, `systemUptime` and `activeProcessorCount`, all of which
return zero hits. Tracking is absent, there are no third-party SDKs, and the App Privacy answer is
"Data Not Collected". One file, one entry.

**Minor, in the same call:** the `try?` swallows a failed attribute read, so the oversize-save guard
immediately below it is skipped rather than failing closed.

### H-12 · Performance · Whole-root integrity validation runs on every intent, and twice per market transaction

This is the most likely mechanism behind [C-04](#c-04--performance--week-advance-is-measured-at-4031-s-against-a-20-s-ceiling),
and it compounds with [C-05](#c-05--persistence--saves-are-18-to-46-over-the-8-mb-ceiling-and-the-in-flight-fix-makes-it-worse).

**Evidence:** `WorldIntegrity.check(_:)` walks the entire `GameState` — 2,283 lines with roughly 248
loop/scan sites — over 134 programmes, 32 professional teams, the full player and staff population,
and the history. It is called from **40 sites**:

| Caller | Sites |
|---|---|
| `Pro/ProMarketSystem.swift` | 11 |
| `Career/*` | 8 |
| `People/ProManagementSystem.swift` | 7 |
| `Intent/IntentResolver.swift` | 7 |
| `Scheduling/WorldScheduler.swift` | 3 |
| `College/CollegePortalTransactionV1.swift`, `World/GameState.swift` | 2 |

Seven of them are in `IntentResolver`, so **every player action revalidates the whole world**.
[ProMarketSystem.swift:548](Sources/FootballSimCore/Pro/ProMarketSystem.swift:548) and
[ProManagementSystem.swift:453](Sources/FootballSimCore/People/ProManagementSystem.swift:453) run it
**twice** — before and after — to diff the issue sets, so a single roster transaction costs two
full-world validations.

**Why this is not simply a defect.** Copied-root validation is a deliberate, documented constraint
(`docs/HANDOFF-CODEX-2026-08-20.md` lists it among the invariants to preserve) and it is a large part
of why the save integrity story is as good as it is. The problem is that its cost is O(world) and
paid per intent, so it scales with the same growth C-05 describes: as the save moves from 2 MB to
14.76 MB, every tap gets slower. Any serious attempt at the 2.0 s budget has to make this
incremental or scoped rather than whole-root, and that is a design change, not a tuning pass.

### H-13 · Determinism · The engine's core arithmetic routes through `exp`, `log` and `cos`, and the cross-process proof never leaves the host

**Evidence:**

- [Leverage.swift:41](Sources/FootballSimCore/Engine/Leverage.swift:41) —
  `2 / (1 + Foundation.exp(-ratingDifference / MatchupRules.leverageScale)) - 1`. `Leverage.score`
  is called **six times per snap** from `SnapResolver` (lines 72, 98, 148, 216, 284, 323).
- [SeededRandom.swift:123](Sources/FootballSimCore/Support/SeededRandom.swift:123) —
  `mean + sd * (-2 * Foundation.log(u1)).squareRoot() * Foundation.cos(2 * .pi * u2)`, a Box–Muller
  Gaussian. It is used by `Leverage.score` (noise), by `AbstractGameSimulator` (the whole off-screen
  model, lines 172 and 186) and by `RosterPopulationGenerator:238` (player ages at world
  generation).

`exp`, `log` and `cos` are libm functions. IEEE-754 pins `+ - * /` and `sqrt` exactly; it does **not**
pin the transcendentals, whose last-ulp results are implementation- and version-defined. A one-ulp
difference that crosses a comparison threshold changes a play, and from there the whole game.

**The contradiction is internal to the codebase.** `GameMap` uses integer grid coordinates and
squared distances with this docstring: *"a floating-point map would make distance comparisons drift
between platforms and take cross-process determinism with them."* That reasoning is correct, and it
was not applied to the play resolver, the off-screen model or the RNG.

**What the proof actually covers.** The cross-process limb is
`PINNED_PRO_GAME_FINGERPRINT`, described in
[EngineTests.swift:520](Tests/SimTests/Suites/EngineTests.swift:520) as *"a literal in a source file
and therefore cannot be salted per launch."* That is a sound design for catching per-launch salting —
which is the bug it was written for — but the pin is only ever compared on the **host**. Nothing
evaluates it on an iOS device, on a different OS version, or on non-Apple-silicon. So the claim
verified is host↔host, and the claim made in `CLAUDE.md` is "across processes and app launches",
which for a shipping app means across devices and OS updates.

**Practical risk today is low and the blast radius is high.** All Apple arm64 platforms share one
libm family, so a divergence is unlikely right now. But the failure mode is a save that replays
differently after an OS update, which is silent, unrecoverable and indistinguishable from
corruption. The cheap mitigation is to run the pinned fingerprint on a device in the `app` lane; the
real fix is a deterministic logistic and Gaussian (rational approximation or a fixed table) so the
engine's determinism does not depend on anybody's libm.

### H-14 · Truthfulness · Match Day's causal commentary is a restatement of possession

**Evidence:** [CoachWorldMatchProvider.swift:50](Sources/CoachWorldApp/CoachWorldMatchProvider.swift:50):

```swift
let commentary = interruption.map { "\($0.message)" }
    ?? "The next recorded snap belongs to \(possession == .home ? … : ….name)."
```

That string is passed as `causalCommentary` on `MatchDayReadModel`
([:108](Sources/CoachWorldApp/CoachWorldMatchProvider.swift:108)). When there is no staff
interruption — the common case — the flagship surface's causal line says only whose ball it is,
which the score bug and the possession indicator already show. It explains nothing and it is not
commentary.

**Compare the fixture.** `CoachWorldSampleData.matchDay`
([ScreenReadModels.swift:2240](Sources/ProFootballCoachUI/ScreenReadModels.swift:2240)) sets
`causalCommentary: "The safety stepped down after the tight end motion."` — a real causal sentence.
The sample is the promise; production is a possession restatement.

**This is a third instance of the pattern the 2026-08-18 critique made its central charge** — G-21
(`WHY IT IS HERE` is a label with nothing after it) and G-48 (*"`FloodlitCostLine` is built and
correct; the real read model never fills it"*). The critique's Match Day list (G-27, G-08, G-30,
G-28, G-29, G-31, G-37, G-60, G-61, G-62) does not include this one, so it is new. The component
exists, the read model has the field, and the provider fills it with a placeholder.

`02-GAME-DESIGN.md`'s agency model rests on the player being able to attribute an outcome to a
decision. On the one surface where that attribution is supposed to be visible, the sentence is
inert.

---

## 3. Medium

### M-01 · Legal · The blocklist's institution list is narrower than its own stated rationale

`CLAUDE.md` and `LegalTests` both assert that **exactly eight** real cities are refused as
institution names — Buffalo, Cincinnati, Houston, Kansas City, Miami, Pittsburgh, Tulsa, Washington
— *"each because it either is a real programme or contains one."*

That rationale is true of many more names in `Blocklist.realCities`: Charlotte, Jacksonville,
Boston, San Diego, Green Bay, Oakland, Cleveland, Saint Louis, Portland, Sacramento, Detroit,
Milwaukee and Denver all name real universities, several of them Division I football programmes
(Charlotte and Jacksonville State are FBS). The test at
[LegalTests.swift:149](Tests/SimTests/Suites/LegalTests.swift:149) derives the count from the same
under-inclusive institution list it is meant to audit, so it can only ever confirm the list against
itself.

**Reachability today is limited**, which is why this is Medium rather than High:
`institutionWords` are all `"… Institute"` or `"… College"`, so a bare `"Charlotte"` is not
generable. But `"Boston, MA"` **is** in the place pool, so `"Boston, MA Technical Institute"` is
reachable and is not blocked (`blocks()` finds no contiguous run: the entry is `boston college`, and
bare `boston` is not an entry).

The maintenance note in `Blocklist`'s header — *"Refreshed per release"* — is the right home for
this. `docs/PRE-DEPLOYMENT-CHECKLIST.md` carries the item.

### M-01b · Legal · The blocklist does no diacritic folding

`Blocklist.normalised` is `name.lowercased().filter { $0.isLetter || $0.isNumber }`. Accented
characters *are* letters, so they survive normalisation as distinct code points: `"Nôtre Dame"`
normalises to `nôtredame`, which does not equal the entry's `notredame`. Every entry in the list is
ASCII, so any accented spelling of a real name passes both limbs. No test plants one.

**Reachability is narrow, which is why this is Medium.** `realAmericanPlaces` and the syllable pools
are all ASCII, so the *generator* cannot currently emit an accent. The exposed limb is the
shipped-copy scan (`no string literal anywhere in Sources is a real name`): a real programme typed
into a source file with an accent — deliberately or by paste — evades it. Folding with
`applyingTransform(.stripDiacritics, reverse: false)` inside `normalised` closes both limbs at once.

### M-02 · Legal · Trade dress covers college pairs only, while pro teams now sit in real cities

`Blocklist.tradeDressHex` holds 39 pairs, and they read as collegiate (Notre Dame navy/gold, Oregon
green/yellow, Michigan blue/maize, LSU purple/gold). `docs/HANDOFF-CODEX-2026-08-20.md` records that
NFL trade-dress pairs were added on the unmerged `claude/coach-career-promotion-integrity-f10168`
branch; `git diff HEAD main -- .../Blocklist.swift` is empty, so **neither `HEAD` nor `main` has
them**. Meanwhile professional nicknames *are* in the name denylist, so the two limbs of the
guardrail disagree about whether the pro tier is in scope.

### M-03 · Persistence · There is no migration table, only a three-version tolerance

`GameState.schemaVersion = 13`; `init(from:)` accepts `schemaVersion`, `previousSchemaVersion` or
`legacySchemaVersion` and throws otherwise. `SaveEnvelope` is stricter still —
`currentSchemaVersion: UInt32 = 1`, `guard version == currentSchemaVersion`, with
`SaveEnvelopeError.unmigratableVersion` documented as *"until that table exists, an older save is
refused."*

For a TestFlight beta where testers accumulate 20-season careers, the fourth schema bump discards
every save from before it, with no fixtures proving even the three-version window across shipped
builds. `docs/BETA-READINESS-CONSOLIDATED.md` STOP-01 asked for full binary fixtures from every
shipped schema; that is not what exists.

### M-04 · Verification · `PerformanceBudgetTests.swift` is named for a gate it explicitly is not

See [C-04](#c-04--performance--week-advance-is-measured-at-4031-s-against-a-20-s-ceiling). The
contents are honest — the suite title says "no host threshold" — but the file name and the
`SuiteCatalog` exclusion have to be read together to learn that.

### M-05 · Verification · The "reviewed release seams" contract test hand-lists twelve files

[ContractTests.swift:976](Tests/SimTests/Suites/ContractTests.swift:976) names
`FloodlitChrome.swift`, `CoachWorldFloodlitComposition.swift`, `CoachingHQView.swift`,
`RosterView.swift`, `DepthChartView.swift`, `GamePlanView.swift`, `PracticePlanView.swift`,
`CareerHubView.swift`, `OpponentReportFilmRoomView.swift`, `OpponentFilmView.swift`,
`CoachWorldMatchProvider.swift`, `CoachWorldAppRootView.swift`, `CoachWorldStore.swift` one at a
time. `CLAUDE.md`: *"Spot-check tests over hand-listed instances are a defect, not coverage."*

`AccessibilityReflowTests` shows the right pattern in the same repository — it enumerates from
`CoachWorldScreenID` and derives the file name — so the fix is a known local idiom, not new design.

### M-06 · Robustness · `try!` sample fixtures compile into Release

[ScreenReadModels.swift:1892](Sources/ProFootballCoachUI/ScreenReadModels.swift:1892) and
[ScreenReadModels.swift:2217](Sources/ProFootballCoachUI/ScreenReadModels.swift:2217) construct
`CoachWorldSampleData` fixtures with `try!`. `CoachWorldSampleData` is a `public enum` with no
`#if DEBUG` guard, and its only consumer, `RootView`, is likewise unguarded at file level — only the
*call site* in `ProFootballCoachApp` is behind `#if DEBUG`.

**Not a live crash today**, and worth being precise about why: Swift `static let` is lazy, and in a
Release build nothing ever instantiates `RootView`, so the `try!` never executes. The finding is
that it is one accidental reference away from being a launch-time crash instead of a test failure,
and that the sample fixtures and `RootView` are dead weight in the shipped binary.

The genuinely DEBUG-guarded proof screens — `RedesignedJobBoardProofView` and `TeamLogoProofView` —
each carry a proper `#if DEBUG` and are not implicated.

### M-07 · Convention · Four files are far past "small and focused"

`Integrity/WorldIntegrity.swift` 2,283 lines; `ProFootballCoachUI/ScreenReadModels.swift` 2,274;
`College/CollegePortalState.swift` 1,745; `CoachWorldApp/CoachWorldAppRootView.swift` 1,744.
`Tests/SimTests/Suites/ContractTests.swift` is 2,476.

### M-08 · Build · The asset copy dominates build time

`[5/8] Copying TeamLogos.xcassets` held both verification runs in this review for minutes before any
Swift file compiled. CI pays it on every push and every PR. Resolved by [C-02](#c-02--payload--157-mb-of-1024×1024-logos-to-draw-marks-at-20-32-and-44-points).

### M-09 · Repo hygiene · 14 GB working tree, and 329 MB of it is one `git add` from being committed

`.worktrees` 3.9 GB, `.build` 1.1 GB, `.git` 467 MB, `App/build` 240 MB (stale since 2026-08-12),
`Pro-Football-Coach/` 33 MB nested clone. All of those are ignored.

**`exports/` (329 MB) is untracked and *not* ignored**, as are `.claude/`, `.agents/`,
`.impeccable/`, `.impeccable.md` and `.superpowers/`. `docs/HANDOFF-CODEX-2026-08-20.md` already
warns *"Do not use `git add -A`"*; the `.gitignore` should make that unnecessary rather than relying
on everyone remembering.

`.git` at 467 MB is largely the 157 MB logo import; C-02's fix shrinks future clones but not history.

### M-10 · Product · There is no way to start over, and the API that would do it is dead

`CoachWorldSaveStore.delete()` exists and has **zero call sites** — not in `Sources`, not in
`Tests`. In `CoachWorldAppRootView`, `NewCareerCoachIdentityView` is behind
`} else if showingNewCareerSetup {`, reachable only when `store == nil`. So once a career is loaded
the New Career route is gone, and nothing else deletes the save.

**A player who wants a different world must delete and reinstall the app.** For a "one save, one
coach" game whose selling point is a long career, "start over" is table stakes, and it is also one
of the recovery options `BETA-READINESS` STOP-02 asked for ("retry/export/recover/confirmed
replacement/**delete**").

The related overwrite hazard is now mostly closed: `load(source:)` quarantines corrupt primary bytes
before throwing, so a New Career started from the recovery state no longer destroys the only copy.

### M-11 · Copy · Raw Swift errors are shown to the player

[CoachWorldAppRootView.swift:1737](Sources/CoachWorldApp/CoachWorldAppRootView.swift:1737):
`failure = "The career could not be saved: \(error)"`, and
[:1605](Sources/CoachWorldApp/CoachWorldAppRootView.swift:1605):
`setupError = "The world could not be built: \(error)"`.

Interpolating the error produces developer text — a `CocoaError` sentence about a file path, or an
enum dump such as `bodyTooLarge(bytes: 15482112, maximum: 536870912)`. This is the same class as the
design critique's G-10 (engine vocabulary in player copy), and it lands on the two moments where
copy matters most. The comment above the save handler is right that the failure must be reported and
not swallowed; the finding is only about what the report says.

There is also no specific low-storage path — `NSFileWriteOutOfSpace` has no handling anywhere and
falls into this generic message.

### M-12 · Persistence · The enforced envelope limit is 64× the product ceiling

`SaveEnvelope.maximumBodyBytes = 512 * 1024 * 1024`. That is a sane denial-of-service guard against
a hostile file and it should stay, but it means the only *enforced* size limit is 512 MB while the
product commitment is 8 MB. Nothing between those two numbers fails anything. This is why C-05 can
be 1.8× over budget without any code path noticing.

*(The former M-10 on privacy was promoted to [H-11](#h-11--privacy--a-privacy-manifest-is-required-and-there-is-none)
after `attributesOfItem(atPath:)` turned out to be a required-reason API.)*

---

## 4. Low

- **L-01 · VoiceOver duplication.** `"\(model.team.name), \(model.cityName), …"` speaks the city
  twice once the team name contains it (C-06), and reads `", AZ"` as letters.
- **L-02 · Logo accessibility.** `CoachWorldTeamLogo` sets `.accessibilityLabel(team.name)` and then
  `.accessibilityHidden(isDecorative)` with `isDecorative = true` by default, so the label it builds
  is never spoken at any current call site.
- **L-03 · Quarantine naming.** `CoachWorldSaveStore.quarantineName` splits on `/` and `\` and takes
  the last component, which is safe against traversal, but a name of `".."` resolves to the parent
  directory and fails the write rather than being sanitised.
- **L-04 · Stale build products.** `App/build` holds a 2026-08-12 simulator bundle containing
  `.pcm` module caches, `ProFootballCoach.xcodeproj/`, `.hmap` files and `-OutputFileMap.json` —
  the symptom `BETA-READINESS` recorded as STOP-08. **That defect is fixed**: `App/project.yml` now
  declares `sources: [ProFootballCoachApp.swift]`. Only the stale directory remains.

---

## 5. Register reconciliation — what is already fixed

`docs/BETA-READINESS-CONSOLIDATED.md` (2026-08-14) listed ten release stops. Checked against `HEAD`:

| ID | Status at `HEAD` |
|---|---|
| STOP-02 corrupt-load replaces the only save | **Fixed.** `CoachWorldSaveStore` writes atomically, keeps `.backup` and `.metadata`, and quarantines; `CoachWorldAppRootView` has `recoveryRequired` and `onUseBackup`. |
| STOP-03 no playable pro session | **Fixed.** `CareerControlTests` covers *"promotion opens a professional projection and persists its tactical plan"*, and `CareerSession(state: promoted)` succeeds. `CareerControlState.college` remaining the only control is by design; pro surfaces gate on `career.college == nil` plus `careerArc.currentJob`. |
| STOP-07 performance and save size | **Open.** See C-04 and C-05. |
| STOP-08 project bundles build junk | **Fixed, and confirmed on a fresh device build.** The `.app` produced by the app lane has six top-level entries and no `.pcm` caches, `.xcodeproj` or header maps. Only the stale `App/build` directory remains (L-04). |
| STOP-01, 04, 05, 06, 09, 10 | **Not re-verified in this review.** They need the integrated candidate C-03 asks for before a verdict means anything. |

`docs/reviews/2026-08-18-floodlit-exhaustive-design-critique.md` (80 findings): G-01, G-02, G-05,
G-35 and G-36 are recorded closed **on `main`**, which this branch does not contain (C-03). G-36 is
demonstrably still open in this branch's source (H-06). G-25/26/27 — real names breaking the
personnel table, depth chart and Match Day field — were never closed and were made materially worse
by C-06.

---

## 5b. Concurrent reviews — overlap and what they add

Three further review documents were written into `docs/reviews/` by other agents **while this review
was running** (timestamps 16:40, 16:52 and 17:11; this one 17:10). That is itself worth flagging:
several sessions are auditing and writing into one working tree at once, which is the hazard
`docs/HANDOFF-CODEX-2026-08-20.md` already warns about for source files.

They corroborate this review's central findings independently — the stale determinism pins, the
seed-keyed logo catalog, the unbounded retention term, the budget test that cannot fail, the single
CI lane. Two of their numbers were **better than mine and are folded in above**: the 208-commit gap
against `origin/main` (C-03) and the missing diacritic folding (M-01b), both re-verified here before
inclusion.

**They also assert several findings this review did not reach.** They are listed here as leads, not
as confirmed results — I did not verify them, and they should be checked before being acted on:

| Claim | Source | Why it matters if true |
|---|---|---|
| Twelve shipped team identities sit inside the project's own ΔE radius of a real professional team's colour pair | adversarial review, P0-1 | Would make M-02 a live legal exposure rather than a list gap |
| The legal partition assertion is a mathematical identity, so it cannot fail | adversarial review, P0-2 | Would remove one of the two limbs `CLAUDE.md` calls a test |
| Coach names are swept by nothing | adversarial review, P0-3 | A whole generated name class outside both sweeps |
| College overtime ends after one possession; the engine diverges from the rules of the sport | adversarial review, P0-6/P0-8 | Competition truth, and unreachable by H-10's ungated bands |
| The `"City, ST"` format weakens the blocklist's contiguous-word matcher | full-codebase review, F3 | Would make C-06 a legal regression, not only a copy one |
| Staff compaction destroys coaching-tree lineage | full-codebase review, F8 | A second, distinct retention defect beside H-05 |
| The rename invalidated the approved logo set while `humanApproved` stayed true | full-codebase review, F10 | The manifest does carry `"humanApproved": true` beside renamed teams |
| `bowlName` has no production caller; `institutionName`'s four-way switch has three identical branches | full-codebase review, F16/F17 | Dead code in the subsystem C-06 and C-07 are about |

On F3 specifically, one caution from reading the matcher: inserting a token between two words of a
blocked entry does break contiguity, but the state code only ever sits between the *place* and the
*institution word*, and `institutionWords` are all two-word phrases (`"City College"`,
`"Technical Institute"`), so a place word is never adjacent to the trailing word of an entry anyway.
The mechanism is real; a *reachable* collision still needs demonstrating.

---

## 6. What was not covered

- No simulator run — the app was **built**, not launched — so no rendered evidence: Reduce Motion,
  Reduce Transparency, VoiceOver order, sensor-left/right, the 956 × 440 ceiling and the 844 × 390
  install floor are all unevidenced here. Anything in this review about how a surface *looks* comes
  from the 2026-08-18 critique, not from this session.
- No calibration band measurement, soak, archive or M7-gate run.
- No review of the 40-plus dormant branches beyond divergence counts; the 14 active ones are
  characterised in `docs/HANDOFF-CODEX-2026-08-20.md` and this review does not duplicate that.
- No counsel review. M-01 and M-02 are engineering observations about a maintained list, not legal
  advice, and the joint-identification gap that `Blocklist`'s own header names remains open.

---

## 7. Recommended order

0. **Get the branch green, today.** The determinism gate has been failing since `c6e2d21`
   ([§9.1a](#91a-bisect--the-breaking-commit-is-c6e2d21)). Confirm that generation is the only thing
   that moved, then re-pin `ArchitectureTests`' two fingerprints — deliberately and visibly, the way
   `EngineTests` says a pin edit should be. Until that is done, every other change lands on a red
   branch and nobody can tell what they broke.
1. **C-03, because nothing else can land.** Decide the integration target — most likely
   rebase this branch's 33 commits onto `main` — then reconcile the four conflicting calibration and
   career branches one at a time against that target. Nothing below is worth doing twice.
2. **The naming cluster: C-06, C-07, H-07, H-08, and the abbreviation collisions.** These are one
   table and one interpolation, and they are the cheapest large win on this list. Replace the
   alphabetically-skewed pool with a proper sample, strip the `", ST"` suffix at generation, and
   either give the map real coordinates or stop claiming place is a mechanic. Then re-run the
   layout evidence for G-25/26/27 at the install floor — the critique measured them against
   *"Krisam Kendhaven"*-length names, and the current generator emits
   *"Apache Junction, AZ Agricultural Institute"*. Amend `docs/02-GAME-DESIGN.md` first, per the
   doc-first rule that C-06 broke.
3. **C-02b with C-02, in one pass.** Decide whether the world seed stays player-editable. If it
   does, the mark has to be chosen seed-independently or the 157 MB is dead payload for every
   non-default world. Re-export at 256 px in the same change, give the imagesets real 1×/2×/3×
   slices, update the `expectEqual(pixelWidth, 1024)` assertion in `TeamLogoTests`, and add a
   catalog byte ceiling. This also resolves M-08.
4. **H-05, then C-05.** Reject the unstaged half of the retention edit; restore the staged two-tier
   policy and widen its cited set to cover portal capacity validation. Rewrite the soak assertions so
   they do *not* subtract `durablePlayerIDs`. Then re-measure at seasons 20 and 30.
5. **C-01, H-09 and H-11.** An app icon, one export-compliance key, and a one-entry
   `PrivacyInfo.xcprivacy`. An afternoon, and together they are the literal gate on the first
   TestFlight upload.
6. **C-04 and H-12.** Take the iPhone measurement, then decide whether the 2.0 s ceiling moves or the
   week-advance work does. Whole-root `WorldIntegrity.check` on every intent is the first thing to
   look at. Convert `runPerformanceBudgetProbe` into a gate with a threshold either way.
7. **H-01 through H-04, and H-10.** Put the fifteen orphaned suites into CI; add the `app` lane and
   at least the soaks to the workflow; fix the two dead lane names; make the calibration lane assert
   `result.passed` for the 24 declared bands; and begin replacing the highest-value source-text
   assertions — touch target and VoiceOver first — with rendered checks driven from the XCUITest
   target that already exists.
8. **H-13, cheaply first.** Run the pinned game fingerprint on a device as part of the `app` lane.
   That converts the cross-process determinism claim from host-only to something the shipping
   platform has actually confirmed, before deciding whether the logistic and Gaussian need
   deterministic replacements.

---

## 8. What is genuinely good

These are load-bearing and should not be disturbed while fixing the above.

- **Determinism.** `EntityStore.values` sorts by `uuidString` so every engine iteration over
  entities is ordered by construction; seeds derive from identifier *bytes* and a source scan forbids
  `hashValue`; `CollegePortalMatchingV1` sorts by `uuidRanksBefore` at every point where dictionary
  order could leak; `ScoutingState.canonical` normalises before storing. I looked specifically for a
  cross-process order leak and did not find one.
- **The legal test mechanism** is the best-designed thing in the repository. It enumerates generated
  output rather than source lists; it exhausts `GenerationVocabulary.everyEmittableWord` rather than
  sampling; it asserts that the institution and place sweeps *partition* every generated name; it
  carries self-tests in both directions (a planted real name must fail, an invented name must pass);
  and `sweepSeed` documents and fixes a correlation bug that had quietly reduced 200 leagues to about
  five. The residual risk is list contents (M-01, M-02), not mechanism.
- **Persistence safety.** Atomic writes through a temporary sibling, a backup generation, quarantine
  of corrupt bytes without materialising them in memory, header validation before body decode, and
  decoders that re-check invariants rather than trusting the encoder (`PlayerRecruitingOrigin`,
  `CollegeCareerControl` and `EntityStore` all `guard` on decode, which is why the force-unwraps at
  `PeopleState.swift:541` are safe).
- **Hygiene.** Zero `TODO`/`FIXME`, zero emoji, zero `print` outside test probes, zero third-party
  dependencies, zero networking, zero `UserDefaults`, zero unsafe pointers, no secrets in tracked or
  untracked files, and only eight hard-coded design-token literals across 99 view files.
- **The conventions are actually held.** `Rating` is an `Int` value type that clamps in its
  initialiser and encodes as a bare number (with a stated reason: `{"value":68}` is four times the
  bytes of `68`, across thousands of players). There is no floating-point money anywhere. Rules
  constants live in the per-tier rules modules rather than inlined. These are the sort of rules that
  usually decay into comments, and here they did not.
- **Static analysis used where static analysis is the right tool.** The engine/UI import boundary and
  the Reduce Motion choke point are both source scans with planted-construct self-tests in both
  directions. They are the model that H-01's behavioural gates should be measured against, not
  examples of the same problem.
- **Honest documentation.** `PRODUCT.md`'s "Unverified product targets" table and `docs/STATUS.md`'s
  "what is not verified" sections state the 4.031 s week advance and the failing save ceiling
  plainly. Several findings in this review were *sourced* from the project's own admissions. That is
  rarer than it should be and it is worth protecting.

---

## 9. Suite result — the full lane is red

`./scripts/verify.sh` (full lane: release build with `-enable-testing`, then the default SimTests
run) was executed on this machine, on the working tree as found.

```
964 tests, 787761 checks
1 failing test(s), 2 failed check(s):
  FAIL Authoritative game state / root and scheduler fingerprints are pinned across processes:
       expected 3251160748987753141, got 2399181485827482543   [ArchitectureTests.swift:83]
  FAIL Authoritative game state / root and scheduler fingerprints are pinned across processes:
       expected 11229646605763785595, got 10425352982328808663 [ArchitectureTests.swift:84]
FAIL  full
```

**The one failing test is the cross-process determinism gate** — `DeterminismTests`, one of the
fourteen entries in `SuiteCatalog.defaultRun`, and the gate `PRODUCT.md` names against the
commitment *"Same seed, same league, across app launches."* Both pins moved:
`architectureFingerprint(GameState.bootstrap(seed: 20_260_810))` and the same fingerprint after one
`WorldScheduler.advanceWeek`.

### 9.1 The failure is in `HEAD`, not in the working tree

`HEAD` was extracted to a clean directory with `git archive` — no working-tree changes of any kind —
and the determinism lane run against it:

```
25 tests, 222 checks
1 failing test(s), 2 failed check(s):
  FAIL … expected 3251160748987753141,  got 2399181485827482543   [ArchitectureTests.swift:83]
  FAIL … expected 11229646605763785595, got 10425352982328808663  [ArchitectureTests.swift:84]
```

**Byte-identical to the dirty-tree run.** Both the expected and the observed values match exactly,
which settles two things at once:

1. **`HEAD` (`c0f4334`) is red on its own.** The branch tip fails the cross-process determinism gate
   with nothing uncommitted in play.
2. **The uncommitted retention work is not the cause.** Both fingerprints are unchanged between the
   two runs, so H-05's edit does not move them at all. An earlier draft of this section reasoned that
   the *advanced* fingerprint had moved because the retention edit runs inside `advanceWeek`; the
   measurement says otherwise, and the measurement wins.

`ArchitectureTests.swift` is clean in the working tree and was last touched several commits ago. The
prime suspect is `c6e2d21`, the real-place naming commit: it changed every generated name, names are
encoded into the root, and it re-pinned `GenerationTests`' `PINNED_WORLD_BYTES` and
`PINNED_WORLD_DIGEST` while never opening `ArchitectureTests.swift`. §9.1a settles that by running
the same lane against `c6e2d21^`.

### 9.1a Bisect — the breaking commit is `c6e2d21`

Same method, same lane, against a clean extract of `c6e2d21^` (`20cefc4 docs: record team naming and
legal screen`):

```
[ok  ] Authoritative game state — 9 tests
25 tests, 222 checks
all passed
```

| Commit | Determinism lane |
|---|---|
| `20cefc4` — `c6e2d21^` | **green**, 25 tests / 222 checks, all passed |
| `c6e2d21` — *feat: use real places and generic postseason names* | *(the change)* |
| `c0f4334` — `HEAD` | **red**, both root fingerprints moved |

**`c6e2d21` broke the cross-process determinism gate, and the branch has been red ever since.** The
commit changed every generated name; names are encoded into the authoritative root, so both
`architectureFingerprint(bootstrap(seed: 20_260_810))` and its post-`advanceWeek` counterpart moved.
The commit re-pinned `GenerationTests`' `PINNED_WORLD_BYTES` and `PINNED_WORLD_DIGEST` and never
opened `ArchitectureTests.swift`, which carries the other two pins.

Two things follow that matter more than the failing test itself.

**The re-pin is mechanical, but it must not be done blind.** Both pins are *supposed* to move when
generation changes deliberately — `EngineTests` says exactly that about its own pin: *"a tuning
change must be a visible edit here."* The defect is that the edit was never made, not that the
numbers changed. Re-pinning is correct here; doing it without first confirming that generation is
the only thing that moved is not.

**Nothing caught it for a day.** The commit landed 2026-08-20 at 14:51 and the gate has been failing
since. CI runs on push and pull request, so either this branch has not been pushed since, or it was
pushed and the red was not acted on. Two commits on `main` are titled
`chore: trigger CI (no CI had ever run on this branch)`, which suggests the first. That is the
practical face of C-03 and H-04: work accumulates on long-lived branches that CI never sees.

### 9.2 The app lane is green

Run separately, since CI never runs it: `./scripts/verify.sh --lane app` — xcodegen generate, then
`xcodebuild -destination 'generic/platform=iOS' build` — **`** BUILD SUCCEEDED **`, 2 passed,
0 failed, zero compiler errors or warnings surfaced.** The iOS app compiles for a real device from a
clean copy of the package.

That is worth stating plainly because this repository's history includes a phase that shipped
uncompiled: the app builds, and this review saw it build. The measurements in C-01 and C-02 come
from that artifact.

### 9.3 What these lanes do not cover

Per H-03 and H-04, even with the app lane green, nothing has run: any soak (including the only 8 MB
save-ceiling assertion), any calibration band check, the archive or M7 gate, the iOS app build, or
any rendered UI test. The 964 tests and 787,761 checks are real, and 454 of the checks are string
matches against source text (H-01).

One incidental measurement worth recording: the portal scheduler characterization step alone
reported `runtimeMs=200961` — **3 minutes 21 seconds for one suite**, in a Release build on an Apple
silicon Mac. That is consistent with C-04 and H-12.

Two contracts did pass and are worth stating positively, because they are the ones the design
critique's systemic findings turn on: `AX5 contract: 62 landed, 0 pending` and
`Floodlit conversion: 62 converted, 0 pending`. The registry is complete on this branch; what is
missing here is the *routing* work that lives on `main` (C-03).

