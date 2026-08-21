# Audit Remediation Program Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development`
> (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Use
> `superpowers:using-git-worktrees` before Task 1. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce one immutable release candidate on which every 2026-08-20/21 audit finding is
either fixed and proven, removed from v1 and from its claims, or explicitly blocked on owner/counsel
evidence, with every machine gate green on the same SHA.

**Architecture:** Treat reports as symptom inventories, not implementation specifications. Work in
nine independently reviewable slices ordered by dependency: integrate first; make the user journey
and gates truthful; repair match state transitions; unify retention; close legal and identity
boundaries; make calibration and budgets real; dispose of dead feature claims; add distribution
resources and CI; then certify one SHA. Reuse existing production systems and TestKit runners; add
no dependency or parallel framework.

**Tech Stack:** Swift 6, Swift Package Manager, SwiftUI/iOS 26, XcodeGen, XCTest/XCUITest, the
repository's executable TestKit harness, Bash, GitHub Actions.

## Global constraints

- Work only from a clean, isolated worktree. The shared branch is moving and contains unrelated
  user changes; never stage them and never use `git add -A`.
- Integrate current `origin/main` before fixing findings. All baseline and final evidence must name
  an immutable commit SHA.
- Before editing any function, method, class, or enum, run GitNexus upstream impact analysis and
  report direct callers, affected processes, and risk. Warn before HIGH or CRITICAL edits.
- Before each commit, run GitNexus `detect_changes(scope: "compare", base_ref: "main")` and stage
  only the explicit task paths.
- Use TDD for behavior changes. A test-only weakening cannot close a product finding.
- After non-trivial code edits, run `rewrite-tournament`; before declaring a slice complete, run
  `confidence-review` and investigate every stated uncertainty.
- Preserve explicit seeded randomness, draw order, cross-process determinism, and the zero
  `hashValue`/ambient `UUID()`/ambient `Date()` engine contract.
- Preserve the product baseline: offline, no accounts, analytics, ads, subscriptions, IAP, network,
  or third-party app dependency.
- Do not loosen calibration margins, the 8 MiB save ceiling, or the 2.0 second week ceiling to turn
  a red gate green. `docs/OPEN-DECISIONS.md` names programme count as the D14 performance lever.
- Legal tests are engineering controls, not legal clearance. Counsel/owner decisions remain
  explicit handoff gates.
- Simulator walkthroughs, device timing, season-duration observation, visual authenticity, and
  final legal/export answers are owner-verifiable. Agents prepare evidence and never claim them.
- No TestFlight/App Store build goes out while any item in
  `docs/PRE-DEPLOYMENT-CHECKLIST.md` remains unchecked.

---

## Phase 0: Documentation discovery and allowed APIs

Read these before starting any implementation slice:

- Authority and release gates: `docs/DOC-MANIFEST.md:5-10,170-215`, `CLAUDE.md:68-121`,
  `docs/08-OPUS5-BUILD-PROMPT.md:44-69`, `docs/PRE-DEPLOYMENT-CHECKLIST.md:16-94`.
- Dependency order: `docs/roadmap/01-SYSTEM-DEPENDENCY-MAP.md:3-77` and
  `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md`.
- Match and calibration contracts: `docs/03-MATCH-ENGINE.md:55-205`.
- Legal contract: `CLAUDE.md:27-66` and `docs/02-GAME-DESIGN.md:588-611`.
- Retention and budgets: `docs/OPEN-DECISIONS.md:212-236,317-345,603-644` and
  `docs/roadmap/05-PERSISTENCE-PERFORMANCE-TESTING.md:19-43,47-60,105-110`.
- Current evidence: `docs/reviews/2026-08-21-CURRENT-STATE-REVIEW.md` plus the three source
  reviews it names. Re-probe claims against the immutable candidate; do not copy old measurements.
- Existing patterns to copy:
  - runner and evidence structure: `docs/superpowers/plans/2026-08-20-budget-runners.md`;
  - logo manifest/catalog pipeline: `docs/superpowers/plans/2026-08-20-canonical-team-logos.md`;
  - history archive: `docs/superpowers/plans/2026-08-12-m7b-historical-aggregate-archive.md`;
  - coaching-tree projection: `docs/superpowers/plans/2026-08-12-m7a-living-rivalry-and-coaching-tree.md`.

Allowed implementation surfaces:

- Test dispatch is `Tests/SimTests/SuiteCatalog.swift` plus `Tests/SimTests/main.swift`.
- Release commands run through `scripts/verify.sh`; enumerate direct focused commands with:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --catalog
```

- App configuration is generated from `App/project.yml`; do not hand-edit the generated Xcode
  project.
- For iOS submission, Apple supports a target-owned `AppIcon` asset set selected with
  `ASSETCATALOG_COMPILER_APPICON_NAME`, a bundled `PrivacyInfo.xcprivacy`, and generated Info.plist
  keys such as `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`. Use Apple's primary documentation for
  [app icons](https://developer.apple.com/documentation/xcode/configuring-your-app-icon),
  [privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files),
  [required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api),
  and [export compliance](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption).
- For app-container file metadata, Apple reason `C617.1` is the candidate required-reason value;
  confirm it with the archive privacy report before treating it as final.

Anti-pattern guards:

- Do not repair the overtime dictionary guard alone.
- Do not re-key artwork by modulo/hash; each mark depicts a canonical nickname.
- Do not change trade-dress generation before the world/logo identity decision.
- Do not call a tautological partition assertion exhaustive.
- Do not call host timing device evidence or a source scan rendered accessibility evidence.
- Do not wire known-red slow commands into required CI and then describe CI as repaired.
- Do not keep isolated tests for intentionally deferred vocabulary; remove the vocabulary or the
  product claim in the same slice.

---

## Finding-to-task coverage

| Finding family | Owning task |
|---|---|
| Moving branch, stale evidence, main divergence | Task 1 |
| Default career/postseason progression | Task 2 |
| Fifth down, halftime possession, overtime sequencing/walk-off/fairness, synthetic tiebreak | Task 3 |
| Turnover spot, conversions, kickoffs, penalties, two-minute event | Task 3 disposition ledger; implement only retained v1 rules |
| Staff/player/prospect retention, coaching lineage, save growth | Task 4 |
| Tautological legal sweep, coach names, diacritics, pro trade dress | Task 5 |
| Editable seed/logo coupling, stale generated proof names, final mark review | Task 5 |
| Holdout calibration, two-tier consistency, performance threshold | Task 6 |
| Discipline/morale, detailed scheme/fatigue, transaction action construction, other inert claims | Task 7 |
| CI lane drift, M3 omission, app icon, privacy/export configuration, accessibility/device proof | Task 8 |
| Full suite, all lanes, 20-season save, archive, signed build, owner/counsel handoff | Task 9 |

---

### Task 1: Integrate and freeze the actual candidate

**Files:**

- Modify: `docs/reviews/2026-08-21-CURRENT-STATE-REVIEW.md`
- Modify only when conflicts are confirmed: `docs/DOC-MANIFEST.md`, `CLAUDE.md`,
  `docs/08-OPUS5-BUILD-PROMPT.md`, `docs/OPEN-DECISIONS.md`

**Interfaces:**

- Consumes: current branch tip, current `origin/main`, all audit reports, canonical document map.
- Produces: one integrated SHA and a disposition ledger with one row per material finding.

- [ ] **Step 1: Create the isolated execution worktree**

Use `superpowers:using-git-worktrees`. Create branch `codex/audit-remediation` from the current
reviewed branch tip. Confirm the source worktree remains untouched.

- [ ] **Step 2: Verify the source boundary before integration**

Run:

```bash
git status --short
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
git rev-list --left-right --count origin/main...HEAD
```

Expected: the isolated worktree is clean and both exact SHAs are recorded. If it is not clean, stop;
do not stash or absorb another session's work.

- [ ] **Step 3: Integrate main without hiding conflicts**

Run:

```bash
git merge --no-ff --no-edit origin/main
git diff --check
git rev-parse HEAD
```

Resolve any conflicts by current canon and behavior, not by selecting an entire side, then record
the merge SHA.

- [ ] **Step 4: Capture the integrated baseline**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --catalog
swift run -c release -Xswiftc -enable-testing SimTests --commitment-coverage
./scripts/verify.sh
```

Expected: truthful pass/fail output. Red is acceptable as baseline evidence; interrupted or moving
source is not.

- [ ] **Step 5: Rebuild the finding ledger**

Update `2026-08-21-CURRENT-STATE-REVIEW.md` so every material item is one of `resolved`, `open`,
`obsolete`, `owner/counsel gate`, or `out of v1 with claim removed`. Add the integrated SHA and exact
command evidence. Resolve these canon conflicts explicitly:

1. two-limb canon rule versus `RETAINED`-only wording;
2. obsolete five-dimension wording versus the eight-dimension 31/40 rubric;
3. iPhone 15/A16 versus iPhone 15 Pro/A17 device baseline.

- [ ] **Step 6: Commit the boundary**

Run `confidence-review`, GitNexus change detection, and commit only the ledger and any confirmed
canon-document corrections as `docs: freeze audit remediation baseline`. The preceding merge is
already its own commit.

---

### Task 2: Prove the default career journey instead of weakening its test

**Files:**

- Modify: `Tests/SimTests/Suites/CareerControlTests.swift`
- Modify only if the journey exposes a production bug:
  `Sources/FootballSimCore/Career/CareerSession.swift`
- Modify only if UI routing fails: `Sources/CoachWorldApp/CoachWorldStore.swift`

**Interfaces:**

- Consumes: `CareerControlSystem.startCollegeCareer`, `CareerSession.resolve(.prepareWeek)`,
  `.advanceWeek`, `.match`, and `.mandatoryDecision`.
- Produces: one default, all-user-owned first-season journey test that reaches season 1.

- [ ] **Step 1: Restore progression as the test's outcome**

In `runCareerPortalDecisionTests`, do not stop at persistence of a portal choice. Add a separate
test named `default user-owned career completes its first season` that:

1. starts with every responsibility owned by `.user`;
2. resolves every mandatory decision through its declared recommended option;
3. calls `.prepareWeek` whenever preparation is missing;
4. completes any started controlled match through the existing match action loop;
5. advances until `calendar.season == 1`;
6. save/loads at the boundary and asserts `WorldIntegrity.check(restored).isValid`.

- [ ] **Step 2: Run the journey red**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --career-portal-decisions
swift run -c release -Xswiftc -enable-testing SimTests --weekly-authority
```

Expected: the new journey fails at the first real unreachable action. A failure solely because the
test skipped `.prepareWeek` is a test defect, since preparation is the supported user-owned path.

- [ ] **Step 3: Fix only the shared production boundary that fails**

If the session lacks an action needed by the journey, add it once in `CareerSession.resolve` and
route it through `CoachWorldStore`. If the journey succeeds after using existing actions, make no
production change.

- [ ] **Step 4: Verify and commit**

Run the two focused commands, then `./scripts/verify.sh --lane core` and the full default lane.
Run `rewrite-tournament` only if production code changed, then `confidence-review` and GitNexus
change detection. Commit as `test: prove default career season progression` or, if code changed,
`fix: complete the default career journey`.

---

### Task 3: Make period and overtime progression one football state machine

**Files:**

- Modify first: `docs/03-MATCH-ENGINE.md`
- Modify: `Sources/FootballSimCore/Engine/DriveEngine.swift`
- Modify: `Sources/FootballSimCore/Engine/MatchReducer.swift`
- Modify if state shape changes: `Sources/FootballSimCore/Rules/ClockRules.swift`
- Test: `Tests/SimTests/Suites/EngineTests.swift`
- Test: `Tests/SimTests/Suites/MatchReducerTests.swift`

**Interfaces:**

- Consumes: `DriveEnding`, `DriveEngine.step/finish`, `MatchReducer.progressAfterDrive`,
  `MatchSessionState`, tier/stage overtime policy.
- Produces: legal post-drive situation, single-owner period transitions, explicit overtime phase.

- [ ] **Step 1: Settle the rules in canon**

Amend `docs/03-MATCH-ENGINE.md` with exact retained v1 behavior for college/pro regular season and
postseason: possession order, starter alternation, equal-possession guarantee, score walk-offs,
bounded tie policy, conversion, kickoff, turnover spot, penalty, and two-minute behavior. Mark any
deliberately omitted mechanic out of v1 and remove conflicting product/test claims. Obtain owner
approval because `ClockRules.swift` currently labels the rule set unconfirmed.

- [ ] **Step 2: Write focused failing invariants**

Add tests asserting:

- a fourth-down snap that expires a quarter never creates down 5;
- quarter boundaries keep possession, halftime changes it exactly once;
- a turnover spot accounts for play yards before field reversal;
- college overtime cannot complete before both sides possess;
- the opening side alternates by overtime period;
- pro timed overtime applies the documented walk-off rule;
- a drive limit never fabricates a scoring drive or coin-flip winner.

Copy the deterministic caller pattern from `EngineTests.swift:684-700`, the period-sequence pattern
from `EngineTests.swift:729-740`, and `PuntOnlyCaller` from `MatchReducerTests.swift`.

- [ ] **Step 3: Run the state-machine tests red**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --engine
swift run -c release -Xswiftc -enable-testing SimTests --match-reducer
```

Expected: each new invariant fails for its named mechanism before production edits.

- [ ] **Step 4: Consolidate transition ownership**

Make `DriveEngine` resolve the drive ending and final spot; make `MatchReducer` alone own quarter,
half, overtime-period, next-possession, and completion transitions. Remove the duplicate halftime
flip. Replace dictionary-vacuous completion with explicit checks for both `.home` and `.away`.
Persist only the minimum overtime state required by the approved rules and validate its decoder.

- [ ] **Step 5: Remove synthetic football outcomes**

Replace `applyOvertimeTiebreak` on ordinary play paths with the documented tie/continuation rule.
Keep a liveness bound as an error or explicitly permitted non-scoring termination, never as an
empty-play field goal added to the record.

- [ ] **Step 6: Verify determinism and calibration impact**

Run engine, reducer, core, determinism, calibration, and two-tier consistency commands. Re-pin a
fingerprint only after reviewing the canonical diff and proving two separate process runs match.
Run `rewrite-tournament`, `confidence-review`, and GitNexus change detection. Commit as
`fix: unify football period and overtime progression`.

---

### Task 4: Define one bounded historical-identity retention policy

**Files:**

- Create: `Sources/FootballSimCore/History/HistoricalIdentityRetention.swift`
- Modify: `Sources/FootballSimCore/Scheduling/WorldScheduler.swift`
- Modify: `Sources/FootballSimCore/People/PeopleState.swift`
- Modify: `Sources/FootballSimCore/College/CollegeCycleSystem.swift`
- Modify: `Sources/FootballSimCore/Integrity/WorldIntegrity.swift`
- Modify: `Sources/FootballSimCore/History/CoachingTreeReadModel.swift`
- Test: `Tests/SimTests/Suites/CoachingTreeTests.swift`
- Test: `Tests/SimTests/Suites/CollegeStateTests.swift`
- Test: `Tests/SimTests/Suites/M3CollegeSoakTests.swift`

**Interfaces:**

- Produces: `HistoricalIdentityRetention.calculate(in:)` returning canonical retained player,
  staff, and archived-prospect ID sets.
- Consumes: recent/notable archived events, competition awards, active rosters/staff, controlled
  coach, and documented history bounds.

- [ ] **Step 1: Write the byte and lineage contract first**

Record exact bounds for former-coach lineage and departed player career summaries in
`docs/OPEN-DECISIONS.md`. Preserve enough archived assignment data for `CoachingTreeReadModel`
without retaining every full person forever. The 20-season encoded save remains under 8 MiB.

- [ ] **Step 2: Write three failing integration tests**

Add tests that:

1. compact a world after a former coach leaves and still build the documented coaching-tree branch;
2. prune a prospect referenced only by an archived notable event and have integrity agree;
3. run 20 seasons and prove player/staff career counts and encoded bytes remain bounded.

Use archive setup from `CollegeStateTests.swift:1812-1920` and tree construction from
`CoachingTreeTests.swift:14-187`.

- [ ] **Step 3: Centralize reference calculation**

Implement the pure calculator once. Use its sets in `WorldScheduler` compaction,
`CollegeCycleSystem` prospect pruning, and `WorldIntegrity`. Remove the duplicate recent-only
`requiredArchivedProspectIDs` derivation.

- [ ] **Step 4: Compact summaries, not required history**

Change `PeopleState.compacted` so recruiting/portal history does not bypass the global departed
bound. Preserve the documented compact career/lineage representation; update
`CoachingTreeReadModel` to consume live plus archived authority rather than only live
`staffCareers`.

- [ ] **Step 5: Run the durability gates**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --history-archive
swift run -c release -Xswiftc -enable-testing SimTests --m7-gate
M3_SOAK_SEASONS=20 swift run -c release -Xswiftc -enable-testing SimTests --m3-soak
```

Expected: integrity green, lineage retained to the documented bound, and every measured save at or
under 8 MiB. Run `rewrite-tournament`, `confidence-review`, and GitNexus change detection. Commit as
`fix: unify bounded historical identity retention`.

---

### Task 5: Close the legal and team-identity boundary

**Files:**

- Modify: `Sources/FootballSimCore/Generation/Blocklist.swift`
- Modify: `Sources/FootballSimCore/Generation/NameGrammar.swift`
- Modify: `Tests/SimTests/Suites/LegalTests.swift`
- Modify: `Tests/SimTests/Suites/TeamLogoTests.swift`
- Modify: `Sources/ProFootballCoachUI/NewCareerSetupView.swift`
- Regenerate: `Sources/ProFootballCoachUI/TeamLogoCatalog.generated.swift`
- Read as the generation authority: `Tools/TeamLogos/manifest.json`

**Interfaces:**

- Consumes: all `NameGrammar.personName` callers, full `GameState.bootstrap`, canonical logo
  manifest, `CoachWorldStore.defaultSeed`.
- Produces: exhaustive person/institution/place sweeps, diacritic-insensitive comparison, one
  explicit world/mark contract, synchronized generated catalogue.

- [ ] **Step 1: Choose the minimal world contract**

Adopt one canonical beta world and remove the player-editable seed field. Continue loading existing
non-canonical saves with the established abbreviation fallback. If the owner explicitly keeps
arbitrary new-world seeds, stop this task and author a separate seed-independent art identity spec;
do not assign canonical nickname art by hash.

- [ ] **Step 2: Write failing legal tests at production boundaries**

Replace the self-derived `Set(A + B) == Set(A).union(B)` assertion with tests that bootstrap full
states across the documented 200 seeds and sweep:

- programme/team/conference/division/venue/tradition names;
- player names;
- initial and replacement staff/coach names;
- place names under the place-specific policy.

Add planted accented collisions for institution and person entries.

- [ ] **Step 3: Normalize once at the shared function**

Use Foundation's POSIX-stable folding before the existing alphanumeric filter:

```swift
name.folding(
    options: [.caseInsensitive, .diacriticInsensitive],
    locale: Locale(identifier: "en_US_POSIX")
).filter { $0.isLetter || $0.isNumber }
```

Keep all person-name generation routed through `NameGrammar.personName`; do not add caller-local
blocklist loops.

- [ ] **Step 4: Regenerate and prove the catalogue**

Run:

```bash
swift Tools/TeamLogos/generate_catalog.swift
swift run -c release -Xswiftc -enable-testing SimTests --team-logo-manifest
```

Add a test comparing all 166 generated proof names, abbreviations, colours, IDs, and asset names to
the manifest. Expected: zero mismatches; retain the existing 256 px, per-file, and 20 MiB bounds.

- [ ] **Step 5: Freeze art, then perform legal review**

Finish the current mark normalization/redraw work before counsel review. Supply the final names,
marks, and colours to the owner/counsel. A professional reference set and policy must come from that
review; do not check in the reviewer's non-authoritative NFL list or call its 12 screen hits legal
findings.

- [ ] **Step 6: Verify and commit**

Run legal, generation, logo-manifest, all six logo-family lanes, determinism twice, and design
contracts. Run `rewrite-tournament`, `confidence-review`, and GitNexus change detection. Commit the
code/catalog change as `fix: close generated identity legal coverage`; record counsel disposition in
a separate docs commit.

---

### Task 6: Make calibration and performance capable of failing

**Files:**

- Modify: `Tests/SimTests/Suites/CalibrationTests.swift`
- Modify: `Tests/SimTests/Suites/TwoTierConsistencyTests.swift`
- Modify: `Tests/SimTests/Suites/PerformanceBudgetTests.swift`
- Modify only to correct measured behavior: `Sources/FootballSimCore/Calibration/*`,
  `Sources/FootballSimCore/Abstracted/AbstractGameSimulator.swift`, detailed engine/rules files
- Modify after observed results: `PRODUCT.md`, `docs/STATUS.md`

**Interfaces:**

- Consumes: `CalibrationHarness.holdoutSeeds`, `CalibrationHarness.run`,
  `CalibrationReport.passed/failures`, `Band.test`, `ContinuousClock`.
- Produces: real holdout TOST gate, full two-tier metric agreement, separate host regression and
  device product budgets.

- [ ] **Step 1: Add the real holdout assertion before tuning**

For each tier, add this gate shape:

```swift
let report = CalibrationHarness.run(
    tier: tier,
    seeds: CalibrationHarness.holdoutSeeds
)
expect(report.passed, report.summary)
expect(report.failures.isEmpty, report.summary)
```

Run `--calibration` in Release and preserve the first red report. Tuning seeds remain tuning-only.

- [ ] **Step 2: Finish the declared two-tier metrics**

Complete the in-flight explosive-play, field-goal-bucket, and home-advantage comparisons in
`TwoTierConsistencyTests`. Add any still-listed `CalibrationBands.unimplementedMetrics` or remove
the product claim that requires them. Do not widen margins after seeing failures without an owner
doc-first decision.

- [ ] **Step 3: Split host and device performance claims**

Make `PerformanceBudgetTests` assert `weekSeconds <= 2.0` in a Release build on the named reference
host. Treat that as a conservative regression guard, not device proof. Separately certify the same
2.0 second product ceiling on the reconciled iPhone baseline. Measure first, optimize the observed
hotspot second, and use D14's programme-count fallback if the shipping device cannot meet the
ceiling.

- [ ] **Step 4: Run and record evidence**

Run:

```bash
swift run -c release -Xswiftc -enable-testing SimTests --calibration
swift run -c release -Xswiftc -enable-testing SimTests --two-tier-consistency
swift run -c release -Xswiftc -enable-testing SimTests --performance-budget
```

Expected: every test can fail on a bad model or exceeded host threshold. Record hardware-qualified
figures; never carry forward 2.030-2.069 s, 2.965 s, or older save numbers as current evidence.

- [ ] **Step 5: Verify and commit**

Run core, engine, determinism twice, calibration, and performance. Run `rewrite-tournament`,
`confidence-review`, and GitNexus change detection. Commit as
`test: enforce holdout calibration and performance budgets`.

---

### Task 7: Resolve dead or inert v1 claims at the production boundary

**Files:**

- Inspect/modify as retained scope requires:
  `Sources/FootballSimCore/People/DisciplineSystem.swift`,
  `Sources/FootballSimCore/People/PlayerMorale.swift`,
  `Sources/FootballSimCore/Engine/SnapResolver.swift`,
  `Sources/FootballSimCore/Engine/MatchReducer.swift`,
  `Sources/FootballSimCore/Pro/ProMarketSystem.swift`,
  `Sources/FootballSimCore/Intent/IntentResolver.swift`,
  `Sources/CoachWorldApp/CoachWorldProOffseasonProvider.swift`
- Test: existing discipline, engine, pro-market, read-model, and contract suites
- Modify for explicit scope disposition: `PRODUCT.md`, `docs/02-GAME-DESIGN.md`, `docs/STATUS.md`

**Interfaces:**

- Produces: one disposition per claim: production-reachable and effect-proven, or removed from v1
  vocabulary, UI, tests, and commitments.

- [ ] **Step 1: Build the current reachability/effect matrix**

For discipline/morale, detailed scheme/fatigue, trades, waiver placement, practice-squad movement,
recruiting/NIL mandatory decisions, kneel selection, history search, and correspondence, record:
producer, production caller, session/intent route, read model, UI action, and effect test.

- [ ] **Step 2: Apply the YAGNI decision per row**

Retained v1 behavior gets one narrow end-to-end path through the existing system. Deferred behavior
loses its unreachable UI/vocabulary and any test that falsely presents isolated code as shipped.
Do not rewrite `ProMarketSystem`: core transactions already exist; add only missing provider action
construction and provider-to-session tests.

- [ ] **Step 3: Prove retained effects**

Required probes for retained claims:

- scheduler/session/UI integration for discipline with morale consequence;
- detailed match leverage changes for non-zero scheme fit and lifecycle fatigue;
- provider-generated trade/waiver/practice-squad actions that mutate a production session;
- a consumer for any retained search/correspondence surface.

- [ ] **Step 4: Verify and commit by subsystem**

Do not combine this whole matrix in one commit. Use one commit per retained production boundary or
one docs/deletion commit per deferred feature. Each commit runs its focused suite, core contracts,
full default lane, `rewrite-tournament` where applicable, `confidence-review`, and GitNexus change
detection.

---

### Task 8: Route every real gate and add submission-owned resources

**Files:**

- Modify: `Tests/SimTests/SuiteCatalog.swift`
- Modify: `Tests/SimTests/main.swift`
- Modify: `scripts/verify.sh`
- Modify: `.github/workflows/tests.yml`
- Modify: `App/project.yml`
- Create: `App/Assets.xcassets/Contents.json`
- Create: `App/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- Create: `App/PrivacyInfo.xcprivacy`
- Test: `Tests/ProFootballCoachTests/ProFootballCoachTests.swift`
- Test: `Tests/ProFootballCoachUITests/ProFootballCoachUITests.swift`

**Interfaces:**

- Produces: one source of truth for gate-to-command routing, short PR CI, scheduled long CI, and an
  app bundle containing required target-owned resources.

- [ ] **Step 1: Make the routing contract fail on drift**

Add a commitment-coverage test proving every `SuiteCatalog` lane is accepted and dispatched by
`scripts/verify.sh`. Add explicit `legal`, `performance`, and `persistence` lanes; make `soaks` run
M1, M2, and M3. Keep the existing Release/TestKit invocation pattern.

- [ ] **Step 2: Make each lane green locally before requiring it**

Run all wrapper lanes individually. Only after a lane is green, add it to CI. Use a PR matrix for
full/core/determinism/legal/app/release and scheduled jobs for calibration, accessibility, archive,
and the full soaks. Run the performance lane only on the named reference host; do not turn variable
GitHub-hosted timing into device certification.

- [ ] **Step 3: Add the app icon through XcodeGen source configuration**

Add the target-owned asset catalog and set:

```yaml
ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
```

Put the owner-approved 1024 x 1024 iOS image at
`App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`; do not derive the app icon from a random
team mark.

- [ ] **Step 4: Add and validate the privacy manifest**

Bundle `PrivacyInfo.xcprivacy` in the app target. Declare only observed data collection and required
reason APIs. If Xcode's archive privacy report attributes the save-size metadata read to file
timestamp/stat APIs, declare `NSPrivacyAccessedAPICategoryFileTimestamp` with reason `C617.1`.
Reject unexpected keys/values rather than guessing.

- [ ] **Step 5: Record the export-compliance answer**

Have the owner confirm whether the app plus linked libraries use non-exempt encryption. If the
confirmed answer is no, add:

```yaml
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
```

If yes, follow Apple's export documentation and record the supplied compliance code. Absence alone
is not an automatic rejection; an unreviewed guess is not a fix.

- [ ] **Step 6: Add bundle assertions and app tests**

Generate the project, build Release for generic iOS, and assert the built bundle contains a primary
icon declaration and `PrivacyInfo.xcprivacy` with valid plist structure. Add XCUITest coverage for
the default career route at 844 x 390, both appearances, default and AX5, Reduce Motion, and
VoiceOver labels/order where automation can observe them.

- [ ] **Step 7: Verify and commit**

Run app, release, accessibility, and full lanes. Run `confidence-review` and GitNexus change
detection. Commit routing as `ci: run every release gate` and bundle resources separately as
`build: add App Store submission resources`.

---

### Task 9: Certify one SHA and close the register

**Files:**

- Modify: `docs/reviews/2026-08-21-CURRENT-STATE-REVIEW.md`
- Modify: `docs/STATUS.md`
- Modify: `docs/PRE-DEPLOYMENT-CHECKLIST.md` only with actual evidence
- Create: a dated owner walkthrough script under `docs/briefs/`

**Interfaces:**

- Consumes: all prior task commits and owner/counsel decisions.
- Produces: same-SHA machine evidence, owner handoff, and zero undispositioned findings.

- [ ] **Step 1: Freeze the final SHA**

Require a clean worktree, record `git rev-parse HEAD`, and do not change source while the matrix
runs. Any source change invalidates all collected evidence and restarts this task.

- [ ] **Step 2: Run every machine lane**

Run:

```bash
./scripts/verify.sh
./scripts/verify.sh --lane core
./scripts/verify.sh --lane determinism
./scripts/verify.sh --lane legal
./scripts/verify.sh --lane calibration
./scripts/verify.sh --lane performance
./scripts/verify.sh --lane persistence
./scripts/verify.sh --lane soaks
./scripts/verify.sh --lane accessibility
./scripts/verify.sh --lane archive
./scripts/verify.sh --lane release
./scripts/verify.sh --lane app
```

Expected: every command exits zero with recorded counts. Determinism runs in two separate processes;
M3 runs 20 seasons and remains at or under 8 MiB.

- [ ] **Step 3: Build and inspect the release archive**

Generate the Xcode project, build/archive the Release scheme, inspect the built Info.plist, icon,
privacy manifest, and privacy report, then perform Apple's validation with owner signing
credentials. Record the exact archive SHA and tool versions.

- [ ] **Step 4: Hand off owner-only gates**

Provide a walkthrough covering fresh install, new career, full season, quit/relaunch/resume, both
appearances, AX5, VoiceOver, Reduce Motion, simulator floor, physical device, season duration,
device performance, visual rubric, onboarding, and legal/export review. Do not check these boxes on
the owner's behalf.

- [ ] **Step 5: Close every finding**

Update the register row by row with fix commit and evidence, removed-v1 claim commit, or explicit
owner/counsel result. No `open` or `unverified` row may be converted to `resolved` by inference.

- [ ] **Step 6: Final review and commit**

Run `confidence-review`, adversarial review, GitNexus change detection, and `git diff --check`.
Commit the evidence-only documents as `docs: certify audit remediation candidate`.

## Final acceptance

The program is complete only when:

1. every audit row has a concrete disposition and evidence;
2. all machine lanes pass on one SHA;
3. the 20-season save is at or below 8 MiB;
4. the approved device meets the 2.0 second week ceiling;
5. legal, privacy, export, accessibility, walkthrough, and rubric owner gates are signed off;
6. the candidate contains no unrelated or unreviewed worktree files.
