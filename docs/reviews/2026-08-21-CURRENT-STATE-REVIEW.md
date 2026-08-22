# Current-state audit register — 2026-08-21

This updates, but does not rewrite, the 2026-08-20 confidence, consolidated, release, and linked
Claude reviews. Those documents remain the historical evidence. This register records which of
their material findings still describe the current tree.

## Boundary and verdict

**Verdict: BLOCK.** Several 2026-08-20 findings are fixed, but the candidate still has a red
default-suite member, confirmed football-rule defects, incomplete legal and calibration gates,
unresolved retention conflicts, missing submission resources, and a large integration gap.

Evidence was frozen from the live tracked tree while HEAD was `f72f66a` in
`/private/tmp/pfc-current-audit.JV8b3P`. The live workspace was being edited during the review; one
direct build was discarded after Swift reported that an input file changed during compilation.
All test results below came from the frozen snapshot. Some fixes in that snapshot are therefore
uncommitted and are labelled as such. While the review continued, those captured naming and proof
changes were committed and HEAD advanced to `9ee56da`; newer uncommitted calibration and game-stat
tuning is outside the tested snapshot.

Remote `main` was independently confirmed at `4cf52164`. The reviewed branch is **241 commits
behind and 60 ahead** of it. It also contains local tracked and untracked work, so this is not yet a
reproducible release candidate.

Status vocabulary:

- **Resolved** — the original mechanism no longer exists and a current check passed.
- **Fixed locally** — resolved in the frozen worktree, but not in `f72f66a`.
- **Partial** — the original statement was too broad; a narrower defect remains.
- **Open** — reproduced in current source or by a current probe.
- **Unverified** — old measurement is stale and the release-grade replacement was not run.

## What changed since 2026-08-20

| Prior IDs | Current status | Current evidence |
|---|---|---|
| X-1 / F1 / P0-10 — stale determinism pins | **Resolved** | `--architecture-only` passed in two separate snapshot processes: 26 tests, 228 checks each. |
| Default career stalls at the postseason portal | **Open, changed failure** | The dedicated `--career-portal-decisions` regression now reaches and resolves the spring portal choices, but its final `advanceWeek` throws `missingWeeklyPreparation([gamePlan, practicePlan])`. The historical portal-delegation mechanism is no longer the observed failure, but default progression is not green. |
| C-02 / F2 — 157–164 MB of 1024 px logos | **Resolved** | 166 packaged PNGs are all 256×256; the asset catalogue is 6.8 MB. The manifest suite's size budget passed. |
| X-11 / F7 — Akron and Butler evade the legal list | **Resolved** | Both were substituted out without changing the 570-entry pool size; the exhaustive place check and `--legal-only` pass. |
| C-07 — 66% of places start with A | **Fixed locally** | The frozen local pool has 570 entries across 25 initials: A=26 (4.6%), A/B=67 (11.8%). `NameGrammar.swift` is modified but uncommitted. |
| C-06 / X-13 — every public name contains `City, ST` | **Partial** | Programme and pro display names now use `cityWithoutState`; stored cities, regions, and venue-derived strings remain state-qualified. The former “every name” claim is obsolete. |
| X-6 / F9 — staged code differs from tested code | **Obsolete in its original form** | Nothing is staged. The replacement risk is concurrent uncommitted work: the live tree changed during compilation and cannot serve as a release boundary. |
| F23 — generated logo catalogue names | **Open, changed form** | The local manifest now matches the canonical default world, but all 166 debug `proofTeams` names in `TeamLogoCatalog.generated.swift` differ from that manifest. Runtime asset lookup is still ID-only. |
| Coaching HQ truthfulness findings | **Resolved for the audited route** | The 2026-08-21 HQ audit records the removal of invented staff authority, confidence, score, weekday, cleared count, and cost. Current proof images exist locally but were untracked at the snapshot boundary. |

## Confirmed open blockers

### 1. Integration and release boundary

The branch is 241 commits behind current remote `main`, 60 ahead, and has a moving worktree. The
2026-08-20 recommendation to make gates real before integrating is not safe for this state: first
freeze and integrate the candidate, then repair gates on the tree that will actually ship.

The current `runCareerPortalDecisionTests` function is part of the default test list and is red in
isolation: one test, six checks, one failed check. Its portal decisions resolve, but the final week
advance encounters an unprepared scheduled game at the spring boundary. That may be a product-flow
defect or a stale fixture expectation; either way, the release claim remains blocked until the
default user path and its regression agree and pass.

### 2. The detailed match engine still violates core football rules

The current source reproduces the mechanisms from the adversarial review:

- `DriveEngine.swift:291-294` sets `.downs` after fourth down, then overwrites it with a clock
  boundary. The next quarter can begin with down 5.
- `DriveEngine.finish` changes possession for `.endOfHalf`, then `MatchReducer.swift:692` changes it
  again when crossing halftime. The same offence can receive both halves.
- `MatchReducer.swift:759-760` checks `values.allSatisfy` on a dictionary containing only teams that
  have possessed the ball. After the first college overtime possession, the guard is already true.
- `MatchReducer.swift:800` starts every overtime with the home team; there is no coin-toss or
  alternating initial possession.
- Timed professional overtime waits for the clock or drive cap rather than ending on the applicable
  walk-off score, and the global drive cap can still settle a football game through a synthetic
  tiebreak.

The current match tests assert that a winner eventually exists, not that both teams receive the
required possession or that the possession sequence is fair. Fix the overtime and halftime model
as one unit; changing only the vacuous overtime guard can create a non-terminating path.

### 3. Legal gates remain green without covering their claims

`--legal-only` passed 24 tests and 145 checks, but the structural findings remain:

- `everyGeneratedName` is defined as the concatenation of the institution and place arrays, while
  `LegalTests.swift:246-247` asserts its set equals the union of those same arrays. That assertion is
  an identity, not an exhaustiveness check.
- Staff/coach names are generated after `LeagueGenerator` and never enter either name sweep.
- `Blocklist.normalised` lowercases and removes punctuation but does not fold diacritics, so accented
  spellings can evade an ASCII entry.
- The trade-dress table still contains 39 college colour pairs and no professional reference set.
  Re-running the audit script against the current local manifest still reports **12** generated
  identities within its ΔE-25 radius of its NFL reference pairs.

The number 12 is an engineering screen, not a legal conclusion: the script's NFL colour list and
ΔE threshold are reviewer-maintained, not authoritative or counsel-approved. It is sufficient to
keep the finding open and require independent legal review, not to claim twelve infringements.

### 4. Logo identity still depends on one world seed

`CoachWorldTeamLogoCatalog.mark(forStableID:)` is a dictionary keyed by the UUIDs produced for seed
`20260812`. New Career still accepts an arbitrary `UInt64` seed and regenerates all organisation
UUIDs. The current tests bootstrap only `manifest.worldSeed`, so they prove one world has complete
marks, not that a user-selectable world does.

The payload fix and seed-keying fix are separate. Decide whether the seed is player-editable; if it
is, key marks by a seed-independent identity rather than generated UUID.

### 5. Compaction still disagrees with its consumers

- `WorldScheduler.compactHistoryBoundState` retains only employed, event-referenced, and controlled
  staff IDs, then `PeopleState.compacted` deletes all other `staffCareers`.
  `CoachingTreeReadModel.build` reads its lineage solely from `staffCareers`, so long-term coaching
  branches still disappear.
- Departed player careers with any `recruitingOrigin` or `portalWindows` are retained without a
  bound. The recent-departure cap therefore does not bound the dominant signed-player history.
- `CollegeCycleSystem.hotProspectIDs` retains references from recent and archived notable events,
  while `WorldIntegrity.checkCollegeState` derives `requiredArchivedProspectIDs` from recent events
  only. The pruner and integrity checker still define different legal states.

These are one ownership problem: define retained historical identities once and use that definition
in compaction, integrity, and history read models.

### 6. Calibration and performance checks still cannot fail on product quality

`--calibration` passed 20 tests and 164 checks. It validates TOST mechanics, seed separation,
reproducibility, and result counts, but no test runs the real holdout ladder and asserts
`report.passed` or `report.failures.isEmpty`. A mistuned model can still leave the lane green.

The warmed Release host timing probe measured week advance at **2.030–2.069 s** across three runs,
against the 2.000 s hard ceiling. That is materially improved from 4.031 s, but still over the
written ceiling. The test itself prints “no pass/fail threshold” and passed all three times.
Device performance remains unmeasured.

The 8 MB long-career save budget was not rerun. Its old 14.76/37.11 MB measurements are stale, but
the unbounded departed-player mechanism above remains. `--m3-soak` now contains an 8 MB assertion;
`scripts/verify.sh --lane soaks` still omits that suite and CI invokes only the default lane.

### 7. Submission resources remain absent

No `AppIcon.appiconset` or `PrivacyInfo.xcprivacy` exists in the frozen tree. The save loader reads
file metadata through `FileManager.attributesOfItem`, so the required-reason API declaration needs
to be assessed and supplied before submission. Apple documents the
[app-icon asset requirement](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
and [required-reason API manifest](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).

`ITSAppUsesNonExemptEncryption` is also absent. That is not automatically a hard release blocker;
Apple's [key documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption)
describes it as the declaration that avoids repeating export-compliance questions when the answer
is known. Record the correct product answer rather than treating absence alone as rejection.

## Still open below blocker level

- CI remains one `full` job running `./scripts/verify.sh`; it does not build the iOS app or schedule
  the named calibration, soak, accessibility, archive, and release lanes.
- `ContractTests.swift:984` compares the token constant `authoredFloor` to the literal 12. It does
  not enumerate rendered text and therefore cannot enforce the stated floor.
- `PerformanceBudgetTests` deliberately performs no threshold assertion.
- The generated place pool is now balanced locally, but the professional market-size and geographic
  plausibility finding was not re-evaluated.
- Device rendering, VoiceOver, Dynamic Type, physical accessibility, and simulator proof remain
  outside this review. The new Coaching HQ proof closes only that route's stale-image gap.
- Dead or inert feature claims from the adversarial review—discipline, morale, scheme effect,
  in-match fatigue, and parts of the pro transaction surface—were not re-probed here and must not be
  marked resolved from this update.

## Verification record

| Check | Result |
|---|---|
| `swift run SimTests --architecture-only`, process 1 | 26 tests, 228 checks, passed |
| `swift run SimTests --architecture-only`, process 2 | 26 tests, 228 checks, passed |
| `swift run SimTests --career-portal-decisions` | 1 test, 6 checks, failed: final advance requires game and practice plans |
| `swift run SimTests --legal-only` | 24 tests, 145 checks, passed; coverage defects above remain |
| `swift run SimTests --calibration` | 20 tests, 164 checks, passed; no real-band pass assertion |
| `swift run SimTests --team-logo-manifest` | 9 tests, 17,882 checks, passed |
| Release performance probe, warmed ×3 | week advance 2.069 s, 2.030 s, 2.045 s; test passed because it is evidence-only |
| Trade-dress audit script | 12 ΔE-25 screen hits; reference list is non-authoritative |
| Full default suite | Not run against the snapshot |
| `--m3-soak` / 20-season save measurement | Not run |
| iOS app lane / device gates | Not run |

## Corrected execution order

1. Freeze the worktree and integrate current remote `main`; produce one immutable candidate SHA.
2. Reconcile the default career progression flow with its red portal-decision regression, then make
   the remaining gates real: legal partition/coach/diacritic coverage, calibration holdout
   assertions, performance thresholds, and CI routing including `--m3-soak` and app build.
3. Fix the football cluster together: downs/clock precedence, halftime possession, overtime
   possession sequencing, walk-off rules, and drive-cap behavior.
4. Fix the shared retention model, then rerun the full 20-season save and history read-model gates.
5. Resolve the logo seed contract and obtain counsel review of the current colour/mark set.
6. Add the app icon, privacy manifest, and correct export-compliance declaration.
7. Rerun the full suite, all named release lanes, Release/device timing, save budgets, rendered UI,
   accessibility, and simulator proof from the immutable SHA.

Until all seven steps are evidenced on one candidate, the green focused lanes are useful component
checks, not release approval.
