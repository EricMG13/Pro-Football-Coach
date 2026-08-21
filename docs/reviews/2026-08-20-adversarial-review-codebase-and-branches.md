# Adversarial review: whole codebase and branches

**Date:** 2026-08-20 · **Branch reviewed:** `agent/floodlit-injury-evidence` (33 ahead, **208 behind `origin/main`**)
**Scope:** all 300 Swift files (96,534 lines), the working tree including uncommitted and staged
changes, the branch inventory, CI and the verification harness.
**Nothing in the codebase was modified.** This is a review; no fix was applied.

---


---

## If you read one page

**The match engine does not implement the rules of American football.** A dedicated rules pass —
the last lane to run, because nobody had checked the simulation *as football* rather than as code —
produced 24 findings, 7 CRITICAL, **11 of them confirmed empirically** by a probe package running
1,400 headless games. The engine awards a **fifth down**; the team on offence at the end of the
first half **receives the second-half kickoff** (0 of 677 half boundaries changed possession); the
away team **can never possess the ball in overtime** (235 home, 0 away); every turnover is spotted
at the previous line of scrimmage; a walk-off overtime score does not end a professional game; and
17 of 600 games were ended early by a drive budget and settled by a coin flip. There is no
two-point conversion, no two-minute warning, no kickoff, and no penalties at all.

**Two legal tests CLAUDE.md calls non-negotiable are both green for the wrong reason, and one of
the things they exist to prevent has already happened.**
- The name-collision partition assertion is `Set(A + B) == Set(A).union(B)` — an identity. It
  cannot fail, and never could.
- The trade-dress table holds 39 college colour pairs and zero professional ones, while the game
  generates 32 professional teams. **Twelve shipped identities already sit inside the project's own
  ΔE-25 radius of a real professional team's colours**, with logo artwork generated from those exact
  hexes. Reproduced independently.
- Coach names are swept by nothing. A code comment says they are.
- `blocks("Míami")` returns false, because the normaliser never folds diacritics.

**Whole shipped systems never run.** The discipline system has zero callers. Player morale never
executes and never appears in the UI. Scheme identity changes nothing in any played match, and
in-match fatigue is structurally zero. The professional tier has no trades, no waivers and no
practice squads — those actions are never constructed. And **six tests pin these dead features
green**, most explicitly `ReadModelProviderTests.swift:1173-1181`, whose assertion is documented as
*"correspondence is empty because no inbox system exists"*.

**The calibration gate — one of the three CLAUDE.md names — asserts nothing about the engine.**
`holdoutSeeds` is declared, asserted disjoint, and never passed to the harness. No test anywhere
reads `report.passed` or `report.failures`. It runs on 2 seeds and 24 games. And it measures against
a roster with a **four-man offensive line**, because `CalibrationHarness.offensivePositions` has one
guard where `DepthChart.offensiveTemplate` has two.

**A default new career cannot finish its first season.** Not delegating responsibilities — the
default — makes the postseason portal window throw permanently. Both multi-season tests delegate
everything first, so the default configuration has no coverage.

**163 MB of team logos work in exactly one world.** The catalog is keyed by UUIDs drawn from the
seeded RNG; the seed is a free-text field on the new-career screen. Type anything but 20260812 and
every logo silently becomes a three-letter chip. No test ever calls the lookup function.

**The uncommitted change bricks `advanceWeek` permanently.** `CollegeCycleSystem.hotProspectIDs`
was widened to retain prospects named by archived events; `WorldIntegrity.swift:1012` still derives
the mirror set from `history.recent` alone and `:1171` flags the symmetric difference. Every
newly-retained prospect is therefore an `.invalidProspect`, integrity goes invalid, and the week
never advances. Reproduced with a probe, and seed-dependent — so it will not show up on whichever
seed someone tests.

**The working tree does not pass its own suite.** Run during this review: `967 tests, 787806
checks`, and the two failing checks are the *only* cross-process determinism pins the project has
(`ArchitectureTests.swift:83-84`). The uncommitted state-shape change moved them and nothing
re-pinned them. Any claim that this branch is green is false as of today.

**The branch is 208 commits behind `origin/main` and is re-solving, worse, a problem fixed upstream
the day before.** And the git index currently holds different code than the working tree, so
`git commit` without `-a` would ship a weakened integrity check that nothing has built or tested.

The one-line diagnosis: **this project's gates are green because they cannot go red.** Six systemic
patterns produce nearly every finding, and the first is assertions that are tautologies. Fix the
gates first — five specific assertions and four unwired CI lanes — because until they are real, no
other fix can be shown to have worked.

There is a fix-order trap. Repairing the trade-dress table changes how many colours the
rejection-resampling loop discards, which shifts the RNG stream, which changes every team UUID,
which invalidates the entire logo catalog even at the default seed. **Re-key the catalog before
touching the table.** A second one: fixing the vacuous overtime guard *alone* makes the
away-possession bug worse, because the game would then wait forever for a possession the away team
can never receive.
## Method, and what it is worth

Nineteen independent reviewers ran in six rounds against separate subsystems, each running the
three adversarial personas (Saboteur, New Hire, Security Auditor) with a standing requirement to
produce findings rather than approvals.

Areas: the legal guardrail; determinism and the match engine; persistence and the save format; the
UI and app layer; the team-logo feature; the college portal subsystem; career and professional
systems; the week scheduler and the integrity validator; the test suite's coverage boundaries; the
model, tactical and intent code nobody had touched; **football-rules correctness**; the competition
and history layers; a completeness critic tasked with finding what nobody had looked at; and, on
its verdict, a final round on declared-vocabulary-with-no-consumer and on concurrency and
duplication. The coordinating reviewer took CI, the build harness, the uncommitted diff, branch and
delivery state, repository hygiene, documentation claims, and the dictionary-key encoding guard.

**Rounds continued until they stopped producing new ground.** Round 3 was still surfacing findings
in previously untouched files, so a fourth ran; the completeness critic then reported three named
modalities as unsaturated, so a fifth ran on exactly those; that round named two more, so a sixth
ran on those. The rules lane — added in round 3
because no earlier lane had checked the simulation *as football* — produced the highest yield of
any lane in the review, which is the clearest evidence that stopping at round 2 would have been
premature.

### Two other reviews ran the same day, and this one overlaps them

Credit where it belongs, and so nobody counts the same defect three times:

- **`docs/reviews/2026-08-20-release-review.md`** (8 critical / 14 high / 12 medium / 4 low)
  independently found the logo/world-seed coupling, and **bisected the red determinism pin to
  `c6e2d21`** — better evidence than the inference this review started with, and it corrected P0-10
  here. It also measured the built device app: **155 MB, of which `Assets.car` is 109.6 MB, against
  a 72 KB executable.**
- **`docs/reviews/2026-08-20-swiftui-performance-audit.md`** measured the logo bundle at
  **156.2 MB across 166 imagesets**, all 1024x1024 8-bit RGBA at a single `1x` scale, and named the
  merge trap: both logo-carrying branches predate `main`'s latency fixes, so merging either alone
  reintroduces them. It also states plainly that no frame was rendered and no trace captured.

Where this review overlaps them it says so in place. What it adds is the breadth: the legal
guardrail attacked as a system rather than a checklist, football-rules conformance, the
declared-vocabulary sweep, the test suite audited as an artefact in its own right, and the
independent verification pass below.

**Every high-severity subagent finding quoted below was re-derived independently from source by the
coordinating reviewer before being included.** That check changed the report in both directions:

- One CRITICAL was **refuted** and downgraded to NOTE (V-05, the duplicate-roster crash: the
  integrity validator does catch it, at `WorldIntegrity.swift:612-616`, and it runs before any read
  model is built).
- One CRITICAL was **reproduced from scratch** with an independent implementation (V-13, the
  trade-dress breach — 12 hits, matching the original count exactly).
- One was **sharpened for accuracy** (V-09: 15 render arms are dead, but the surfaces they name are
  still reachable through their canonical destination — "15 dead arms", not "15 missing screens").
- One of the coordinating reviewer's own suspicions was **checked and dropped**: the
  `verify.sh --lane app` iOS build was suspected broken and in fact passes (`2 passed, 0 failed`,
  run during this review).
- **Five of the coordinating reviewer's own conclusions were later overturned by other
  reviewers**, and they failed the same way — verifying one link and inferring the chain, or
  reasoning about a cost instead of measuring it.
  Concurrency was called sound on the strength of one clean actor, when the other actor has a live
  reentrancy race and the language mode disables the checking entirely. The calibration harness was
  called sound on the strength of one assertion, when no test asserts that a single band passes.
  The position-label duplication was reported as copy-paste drift when the source comment shows it
  was a deliberate response to a layout constraint. Each correction is kept in the text where the
  claim was made, rather than quietly deleted, because the failure mode is the same one this report
  attributes to the codebase.

Evidence quality is stated per finding. Where a claim rests on running code rather than reading it,
the method is given so it can be re-run.

### Limits of this review, stated plainly

- `swift build` is green (debug, verified this session). `verify.sh --lane app` is green. The
  **default test suite did not finish** inside this session — it was still running after more than
  90 minutes on a machine loaded with the review's own agents — so no claim here depends on a suite result.
- The soaks, the calibration lanes and the `--m7-gate` archive lane were not run. Several findings
  are *about* the fact that nothing else runs them either.
- No simulator walkthrough was performed. Per CLAUDE.md that is an owner action, and this review
  does not claim one happened.
- The professional colour reference list used in P0-1 came from the reviewer's own knowledge, not
  from a file in this repository. See that finding's caveat.
- **Coverage gap — closed.** Two reviewers were slow rather than stalled; both eventually reported.
  The uncommitted-diff lane took two and a half hours because it was building probe packages and
  running release soaks, and the competition lane likewise. Every area in the brief was covered.
---

## Verdict: BLOCK

Not because the code is bad — much of the engine is careful, and some of the test design is better
than anything I would have written. The block is because **the mechanisms this project relies on to
know it is safe are, in five specific and independently verified cases, incapable of failing.**

The single sentence that matters: *the two legal tests CLAUDE.md calls non-negotiable are both green
for the wrong reason, and one of the things they were supposed to prevent has already happened.*

---

## The through-line: six systemic patterns

Individual findings are listed further down. These six patterns generate most of them, and fixing
the pattern is worth more than fixing its instances.

### Pattern 1 — Assertions that cannot fail

Not weak tests. Tests whose predicate is a tautology, verified by substitution:

| Where | The assertion | Why it cannot fail |
|---|---|---|
| `LegalTests.swift:230` | `Set(names) == Set(institutionNames).union(placeNames)` | `names` **is** `institutionNames + placeNames` (`LeagueGenerator.swift:43`). `Set(A+B) == Set(A)∪B` for all A, B |
| `M3CollegeSoakTests.swift` | retained set == expected set | the expected set is recomputed from the implementation's own retention predicate |
| `TeamLogoTests.swift:123` | catalog matches the world | the world is bootstrapped **from the manifest's own seed** |
| `TeamLogoTests.swift` (near-dup gate) | min Hamming distance > 4 | the hash point-samples 64 of 1,048,576 pixels, so nothing is ever near |
| `SuiteCatalog.swift:98+` | every commitment names a gate | checks spelling, never what the gate asserts |

CLAUDE.md already names this failure once — *"the test's coverage boundary became the quality
boundary"* — and treats it as historical. It is current, and it is load-bearing.

### Pattern 2 — Proof by grep

`ContractTests.swift` contains **408** `.contains("…")` assertions over source text, including all
24 "must be reachable from the shipped app root" checks. A substring scan cannot distinguish live
code from dead code — which is exactly the distinction the reachability defect (STATUS.md G-01) was
about. It also fails in the other direction: correctly deleting the 15 dead render arms would turn
these tests **red**. A test that fails when you remove dead code is worse than no test.
The AX5 accessibility contract is two substring greps, and two shipped views with byte-identical
if/else branches satisfy it.

### Pattern 3 — A bound stated, then discarded on the next line

`PeopleRules.maximumRetainedDepartedPlayers = 4_096` caps one set; the very next statement unions in
"every career with a recruiting origin or portal history", which is every player ever recruited, with
no cap. The function whose purpose is bounding growth is unbounded.
The same shape appears in the save envelope: the 8 MB ceiling was breached, and the response was to
raise the parser ceilings to 64 MB stored / 512 MB decompressed and defer the real fix — with the
source honestly recording both numbers (`SaveEnvelope.swift:43-56`).

### Pattern 4 — The gate exists, but nothing runs it

CI runs `./scripts/verify.sh` with no lane, so only `full` executes. Never run automatically:
the **`app` lane** (the only thing that compiles the iOS target), the **`soaks`**, the
**`calibration`** lanes and the **`archive`/`--m7-gate`** lane. CLAUDE.md's completion gate names
"calibration bands, cross-process determinism, the soak" — CI enforces none of the three. 16 test
suites, including this branch's own `runInjuryEvidenceTests`, are outside the default run that every
"suite green" claim quotes. The one assertion of the 8 MB save ceiling is on a lane nothing invokes.
The lanes work. They are simply not wired.

### Pattern 5 — The branch is 208 commits behind, and is re-solving problems already solved upstream

`fc2cb2c fix(engine): bound departed-player retention, and assert the save size` is in `origin/main`
and is **not** an ancestor of HEAD. It bounds the same collection this branch's uncommitted work
bounds — with a different constant name, oldest-first eviction, explicit reasoning about the
integrity coupling, measured numbers, and a real assertion. This branch's version has none of those
and does not actually bound. Same story for `0e6953c` (the app-layer latency fix, four of whose five
named causes are live verbatim here) and `dfe3b76`.
Merging this branch as-is means resolving a conflict in `PeopleRules.swift` where one side bounds the
save and the other does not.

### Pattern 6 — Invariants enforced where decoding does not go

Measured across `Sources/`: **zero** `fatalError`, **zero** `as!`, two `try!`. That restraint is
real and worth keeping. But there are **69 `precondition(...)` calls**, concentrated in
`CollegePortalState` (15), `TacticalEvidence` (6), `TacticalCallIn` (6), `DepthChart` (5) and
`TacticalState` (4) — and `precondition` traps in release builds, it does not throw.

The recurring shape is this: a type validates its invariant in the **memberwise initialiser** —
by clamping, or by `precondition` — and then conforms to `Codable` by synthesis. Synthesised
`Decodable` assigns stored properties directly and **never calls that initialiser**. So every one
of those invariants holds for values the program constructs and does not hold for values the
program loads.

Seven separate findings across four independent reviewers are instances of this one root cause:
`OffensiveCall`/`DefensiveCall` clamps bypassed then fed to `Int(Double)` inside the determinism
fingerprint; `Staff`'s age clamp bypassed then `age += 1` at rollover; `TacticalCallInProposal`'s
preconditions bypassed, persisting an empty option set that wedges the match; `Prospect`'s
priority-completeness never validated then hit by `PlayerRecruitingOrigin`'s `precondition` at
season rollover; `Contract` salaries floored but never capped, then multiplied; `MapCity`
coordinates bounded only at the generation call site, then squared weekly by recruiting and the
portal; `ProRules.salaryCap` trapping on `cap * 7`.

The fix is structural and mechanical: validation belongs in `init(from:)`, and it should `throw`
`DecodingError` rather than trap. Several types in the codebase already do exactly that —
`Eligibility`, `Rating`, `Programme`, `DepthChartOverride`, `PersonnelPlan`, `OpponentObservation`,
`CalendarState` and others all carry real validating decoders — so the pattern to copy is already
in the tree. The defect is that which types got one was decided case by case rather than by a rule.
---

## P0 — resolve before anything else happens

### P0-1 · Twelve shipped team identities sit inside the project's own trade-dress radius of a real professional team's colours
`Tools/TeamLogos/manifest.json` · `Sources/FootballSimCore/Generation/Blocklist.swift:210-224`

`tradeDressHex` contains **39 pairs, all college. Zero professional.** The game generates 32
professional teams. The same file's person limb already lists professional players and coaches, and
`Blocklist.nicknames` lists professional nicknames — so the professional tier was consciously in
scope for *names* and never extended to *colours*.

Reproduced independently by re-implementing the repository's own CIE76/D65 maths from `Colour.swift`
and its `collidesWithTradeDress` predicate (both orientations, threshold 25.0), then running it over
all 166 shipped identities. Twelve hits; five of them are one team's navy-and-green:

```
Aldrich, MN Institute                 #549504/#141F34  ~ Seahawks   dE 16.9 / 9.6
Albia, IA Polytechnic Institute       #6BD44E/#19516B  ~ Seahawks   dE 11.0 / 23.1
Bad Axe, MI Slate Sentinels           #043C67/#8AF165  ~ Seahawks   dE 12.7 / 18.6
Amagon, AR Thunder Anchors            #120F3D/#639F23  ~ Seahawks   dE 16.1 / 16.5
Alliance, NC Technical Institute      #164655/#89B31E  ~ Seahawks   dE 23.0 / 16.1
Adams, MN Institute                   #C98208/#1D2287  ~ Rams       dE 20.5 / 10.7
Cortland, NY Polytechnic Institute    #3A258D/#F75074  ~ Bills      dE 14.7 / 24.1
Burns, WY Regional College            #D7AC14/#6D3709  ~ Commanders dE 15.5 / 22.9
Bullhead City, AZ Institute           #9BCBED/#3B0E44  ~ Colts      dE 22.6 / 24.7
Atlantis, FL Technical College        #CB9E34/#450547  ~ Vikings    dE 23.3 / 24.1
Agua Dulce, TX Agricultural Institute #154234/#7BABD5  ~ Eagles     dE 15.4 / 24.2
Bangor, ME Institute                  #FAE38E/#162C50  ~ Saints     dE 22.5 / 21.5
```

This is not theoretical. The AI logo artwork was generated **from these exact hexes** — each
manifest entry's prompt reads *"Use #X and #Y as the dominant colours"* — so the colour pair and the
artwork agree, which is what makes a trade-dress claim rather than a coincidence.

*Caveat on inputs:* the professional colour pairs came from the reviewer's own knowledge of published
team colours, not from a file in this repo. The ΔE maths, the threshold and the manifest hexes are
all from the repository. Confirm the reference list against an authoritative source before acting —
though the smallest distance found is 9.6 against a threshold of 25, so small errors do not change
the shape.

**CLAUDE.md's instruction applies literally: "Flag anything borderline for the owner to take to
counsel; never resolve it yourself."** This is flagged, not resolved.

### P0-2 · The legal partition assertion is a mathematical identity
`Tests/SimTests/Suites/LegalTests.swift:230-234` · `Sources/FootballSimCore/Generation/LeagueGenerator.swift:43-45`

CLAUDE.md: *"The two sweeps must partition every generated name between them: a name that belongs to
neither kind is a name nothing checks, and **the suite asserts the partition**."*

```swift
// LegalTests.swift:209
let names = world.everyGeneratedName
// LegalTests.swift:230
expectEqual(Set(names),
            Set(world.everyGeneratedInstitutionName).union(world.everyGeneratedPlaceName))

// LeagueGenerator.swift:43
public var everyGeneratedName: [String] {
    everyGeneratedInstitutionName + everyGeneratedPlaceName
}
```

Substituting: `Set(A + B) == Set(A).union(B)`. True for every A and B. A name kind collected by
neither list is absent from both sides simultaneously, so the equality still holds. The protection
CLAUDE.md describes is not in force and never has been. `Rivalry.notableMeetings` already escapes.

### P0-3 · Coach names are swept by nothing
`Sources/FootballSimCore/Generation/StaffPopulationGenerator.swift:43` · `NameGrammar.swift:114`

Coach names pass through no blocklist sweep at all. Player names are swept only at one seed, in
`RosterPopulationTests`, which is not the legal suite. `NameGrammar.swift:114` carries a comment
claiming *"LegalTests checks the full name"* — that check does not exist. The blocklist's person limb
lists real coaches and players (Knute Rockne, Joe Paterno, Tom Brady, Patrick Mahomes …), so the
denylist was written; nothing consults it for the names the generator actually emits.

### P0-4 · No diacritic folding, so accented spellings of real institutions evade both limbs
`Sources/FootballSimCore/Generation/Blocklist.swift`

```swift
public static func normalised(_ name: String) -> String {
    name.lowercased().filter { $0.isLetter || $0.isNumber }
}
```

No `.folding(options: .diacriticInsensitive, locale:)`, no Unicode decomposition. `Character.isLetter`
is true for combining and modifier letters, so they survive: `"Míami"` → `míami` ≠ `miami`;
`"Hawaiʻi"` keeps the ʻokina and → `hawaiʻi` ≠ `hawaii` — and that is the university's own preferred
spelling, not a contrived input. Verified by the legal reviewer compiling the real file:
`blocks("Hawaiʻi") == false`, `blocks("Notré Dame") == false`, `blocks("Míami") == false`.
Miami is one of the eight names CLAUDE.md refuses as an institution *specifically because it is a
real programme*. One character defeats it.

### P0-5 · All 166 team logos disappear on any world seed but one
`TeamLogoCatalog.generated.swift:3-9` · `LeagueGenerator.swift:191` · `NewCareerSetupView.swift:88`

The catalog is keyed by team **UUID**. Those UUIDs are drawn from the seeded RNG
(`let teamID = rng.uuid()`), so they are a pure function of the world seed. The manifest is pinned to
`"worldSeed": 20260812`. And `NewCareerSetupView.swift:88` is a free-text `TextField("World seed")`
whose value goes straight to `onStart` at line 206-207.

Type any other seed → every lookup misses → all 18 call sites fall through to the abbreviation chip.
163 MB of assets serve one of 2⁶⁴ reachable worlds, and it fails silently: no error, no
missing-asset state, just text where every logo was.

Nothing catches it, for two compounding reasons: every logo test hard-codes seed `20_260_812`, and
`TeamLogoTests.swift:123` bootstraps its world **from the manifest's own seed** — so the expectation
and the fixture share a source. And `grep -rn "mark(forStableID\|CoachWorldTeamLogoCatalog" Tests/`
returns **nothing**: the one function the whole feature depends on is called by no test.

**Second-order, and the reason this needs a design change rather than a patch:** UUIDs are positions
in the RNG stream. `ColourGenerator.swift:69,71` is a rejection-resampling loop whose draw count
depends on the contents of `Blocklist.tradeDress`. So fixing P0-1 — adding professional pairs to that
table — shifts the RNG stream and invalidates the entire catalog **even at seed 20260812**. The two
P0s collide. The catalog needs a content-derived key, not an RNG-position key.

### P0-6 · College overtime ends after one possession
`Sources/FootballSimCore/Engine/MatchReducer.swift:757-765`

```swift
case .alternatingPossessions:
    state.overtimePossessions[completedDrive.offense, default: 0] += 1
    guard state.overtimePossessions.values.allSatisfy({ $0 >= 1 }) else { return nil }
    if state.situation.homeScore != state.situation.awayScore { return .completed }
```

`overtimePossessions` is `[Side: Int]`, initialised `[:]` and reset to `[:]` by `beginOvertime`
(line 794). After the first overtime drive it holds exactly one entry, so
`values.allSatisfy { $0 >= 1 }` over `[1]` is **true** — and over an empty dictionary it is vacuously
true. The guard never blocks. First team scores, drive completes, scores differ, `.completed`. The
opponent never gets the ball.

The intended predicate is "every *side* has had a possession", which must be checked against
`Side.allCases`, not against whichever keys happen to be present. The decoder at line 389 encodes the
same wrong assumption: `allSatisfy { (0...1).contains($0) }` means the persisted model cannot even
represent a side taking two possessions in a period.

The defining rule of college overtime is inverted, in every overtime game.

### P0-7 · The git index holds different code than the working tree
Five files are `MM`. The sharpest, verified three ways:

```
HEAD:     checkPortalCapacity(allCareerRecords,    issues: &issues)
INDEX:    checkPortalCapacity(currentTargetRecords, issues: &issues)   <- staged
WORKTREE: checkPortalCapacity(allCareerRecords,    issues: &issues)    <- same as HEAD
```
`Sources/FootballSimCore/Integrity/WorldIntegrity.swift:1449`

The staged edit was reverted in the working tree and left in the index. The next `git commit` without
`-a` ships code that is not in the working tree, was not compiled by the green build, was exercised
by no test, and **narrows a portal-capacity invariant**. Insertion counts differ between index and
worktree on four of the five files, so this is not one stray hunk.

Related and worse in kind: the working tree **deletes** `compactedForDeparture()` — the D7 size
mitigation the index still has — along with the doc comment stating the rule it enforced.

### P0-10 · The working tree does not pass its own test suite, and what fails is the cross-process determinism pin

Run during this review, on the working tree as it stands:

```
967 tests, 787806 checks
1 failing test(s), 2 failed check(s):
  FAIL Authoritative game state / root and scheduler fingerprints are pinned across processes:
       expected 3251160748987753141, got 2399181485827482543   [ArchitectureTests.swift:83]
  FAIL Authoritative game state / root and scheduler fingerprints are pinned across processes:
       expected 11229646605763785595, got 10425352982328808663 [ArchitectureTests.swift:84]
```

These two literals are the project's **entire cross-process determinism evidence** — the pinned
bootstrap fingerprint and the pinned after-one-week fingerprint. A source literal is genuinely
process-independent, which is what makes the technique sound; it is also what makes this failure
unambiguous. The world these assertions describe is not the world the code now produces.

**Attribution — corrected.** I first assumed the uncommitted compaction work caused this, since it
changes the shape of persisted state and runs during week advance. That is wrong. A parallel
release review the same day **bisected it**: `c6e2d21^` passes `--architecture-only` and `c6e2d21`
("use real places and generic postseason names") onward fails on both fingerprints, verified
against clean `git archive` extracts. So this is HEAD, not the working tree, and it has been red
since that commit landed. `c6e2d21` re-pinned `GenerationTests`' two digests and never opened
`ArchitectureTests.swift` — four pins move when generation changes, and only two were updated.
See `docs/reviews/2026-08-20-release-review.md`.

The point is not that the fingerprints changed. It is that **nothing re-pinned them, and nothing
noticed for the commits since.** A sibling branch has a commit for exactly this step — `6bb5627 fix: re-pin fingerprints
for the second main merge` on `claude/lifecycle-band-validation-a50138` — so the workflow is known.
It was not done for `c6e2d21`.

Two consequences:
1. **Any statement that this branch is green is false as of this review.** The suite that every
   such claim quotes fails.
2. Re-pinning is not a formality. The correct order is: land the state-shape change deliberately,
   confirm the new fingerprints are the ones you *intended*, then pin them. Re-pinning first — to
   whatever the code currently emits — converts the only cross-process determinism gate in the
   project into a recording of the present behaviour, whatever that behaviour is.

*A note on the count.* 967 tests and 787,806 checks is a substantial suite, and the scale is real.
It also ran for about two hours here. That cost is why the soaks, the calibration lane and the
archive lane are not in CI (Pattern 4) — the incentive to skip gates is structural, not careless.

### P0-11 · The uncommitted change bricks `advanceWeek` permanently, because only one side of a mirrored derivation was widened

Found by the uncommitted-diff reviewer, **reproduced with a probe on the diff's own `NewsFeedTests`
scenario**, and re-derived independently here.

The working tree widens prospect retention — `CollegeCycleSystem.hotProspectIDs` becomes:
```swift
Set((history.recent + history.archive.flatMap(\.notableEvents))
    .flatMap { $0.payload.referencedProspectIDs })
```
so a prospect named by an *archived* notable event is now kept.

`WorldIntegrity` derives the same set independently, and was not changed.
`WorldIntegrity.swift:1012-1013`:
```swift
let requiredArchivedProspectIDs = Set(
    state.history.recent.flatMap { $0.payload.referencedProspectIDs }
)
```
`history.recent` only. And `WorldIntegrity.swift:1171-1173` compares the two by **symmetric
difference**:
```swift
for id in archivedProspectIDs.symmetricDifference(requiredArchivedProspectIDs)
    .sorted(by: uuidLessThan) {
    issues.append(.invalidProspect(prospectID: id))
}
```

So every prospect retained *because an archived event names it* is, by construction, an
`.invalidProspect`. Integrity goes invalid, `advanceWeek` throws `integrityFailed`, and it throws
again on every retry. The career is over.

The reviewer reports it as latent at seed 93,001 over 20 seasons — held off only by a ranking
coincidence in which weight-30 recruiting bodies lose the 32-slot digest — which is worse than
deterministic, not better: it means the brick is seed-dependent and will not reproduce on the seed
someone happens to test.

This is the sharpest instance of Pattern 1 in the change itself: a value is derived in two places,
one was widened, and no assertion compares them.

### P0-8 · The match engine does not implement the rules of American football

This was found in the last round, because nobody had checked the simulation *as football* rather
than as code. A dedicated rules pass produced **24 findings, 7 CRITICAL** — the highest yield of
any lane in this review. **Eleven were confirmed empirically**, by building a throwaway probe
package outside the repository and running 1,400 headless games plus 180 forced overtimes. The
measurements below are from that run.

**A fifth down.** `DriveEngine.swift:291` sets `.downs` when the down counter passes 4;
`:293-295` then assigns `progress.ending` unconditionally, so a fourth-down failure on the snap
that the quarter clock hits zero becomes `.endOfQuarter` — the one ending whose
`changesPossession` is `false` (`:43-49`). Possession is retained with `down == 5`, and the
reducer only resets `down` across halftime, so it survives the end of Q1 and Q3.
**Measured: 2 fifth-down snaps in 800 games.** Verified independently, line by line, by the
coordinating reviewer.

**The team on offence at the end of the first half receives the second-half kickoff.** Possession
is flipped twice at halftime — `MatchReducer.swift:694` and `DriveEngine.swift:309`.
**Measured: 0 of 677 half boundaries changed possession; the home team received both halves'
kickoffs in 591 of them.**

**Professional overtime kicks off from the opponent's 25-yard line.** `MatchReducer.swift:801` —
`beginOvertime` never reads the tier, so the pro tier inherits the college placement.
**Measured 120 of 120.**

**The away team can never possess the ball in overtime.** `MatchReducer.swift:800` hard-assigns
possession to `.home` in every overtime period. **Measured: 235 home possessions, 0 away.** This
is distinct from the vacuous `allSatisfy` guard in P0-6 — and the two interact badly: **fixing the
guard alone makes this one worse**, because the game would then wait forever for a possession the
away team can never receive.

**A walk-off overtime score does not end a professional game.** The `timedPeriod` branch
(`MatchReducer.swift:775-789`) never touches `overtimePossessions` and never checks the score, so
a touchdown that should end it can be answered.

**Every turnover is spotted at the previous line of scrimmage.** `DriveEngine.swift:277-278, 311`.
**Measured: on three sampled fumbles the defence gained exactly the yards the offence had gained
(+12).**

**The drive budget ends live games, and a coin flip settles them.**
`MatchReducer.swift:746-755, 816-842`. **Measured: 17 of 600 games ended by the 60-drive bound,
one of them with 5:59 left in the fourth quarter.** A tie is then settled by seed parity plus a
fabricated zero-play field goal. And the overtime path can push `drives.count` to 63, which the
decoder rejects at `MatchReducer.swift:384` — **producing a save that cannot be loaded.**

Below CRITICAL, what is simply absent reads as a design statement rather than a bug list: the
extra point is automatic and there is **no two-point conversion at all**, so a team down 8 cannot
tie; no two-minute warning in either tier; no kickoff, onside kick, fair catch or return; nothing
goes out of bounds; timeouts are stored, reset and fingerprinted but never spent; a missed field
goal is spotted at the line of scrimmage with no 20-yard minimum (measured: the opponent pinned on
its own 10); an interception stops the clock while an identical lost fumble does not; **a safety's
two points are recorded against the team that conceded them** (measured); the abstract off-screen
simulator can emit a final score of 1; and penalties do not exist at all — no pass interference, no
automatic first down, no half-the-distance-to-the-goal.

**What was checked and found correct**, so the picture is calibrated: four downs to gain ten, goal
-line handling with no off-by-one, a sack in one's own end zone correctly scoring a safety, the
turnover-on-downs spot, the punt touchback, and the tier-specific first-down clock stop.

**Why this matters more than the count.** `docs/02-GAME-DESIGN.md` puts the whole game in the
coach's chair — the player never touches the ball, so the simulation *is* the product. And the
calibration harness, which is genuinely well built and has a real holdout rule, measures aggregate
distributions: scoring rate, favourite win percentage. Those bands can sit comfortably inside
their targets while every rule above is wrong, because none of these changes a distribution enough
to show. **Calibration is not a rules-conformance suite, and the project has only the former.**
The rules reviewer notes that a single post-drive invariant check — asserting the situation is
legal after every drive resolves — would have caught every one of these findings.

### P0-9 · Shipped features that never run

A sweep for "declared vocabulary with no consumer" — a modality nobody had tried until round 5 —
found that whole systems in this codebase are wired, saved, tested and unreachable. These are not
unfinished features marked as such; they are features the code, the docs and the tests all present
as working.

- **The entire discipline system is dead.** `DisciplineSystem.incidents` and `.respond`
  (`DisciplineSystem.swift:83, 135`) have zero callers in `Sources/`. No incident is ever raised,
  no suspension ever served. An earlier finding had this as "the `.volatile` trait is never
  generated"; the truth is larger — even with the trait, nothing would call the system.
- **Player morale never runs and never appears.** `PlayerMorale.reading`
  (`PlayerMorale.swift:55`) has exactly one caller, and it is inside the dead function above. Zero
  `morale` references in either UI target.
- **Scheme identity changes nothing in any played match.** All six `Leverage.score` call sites in
  `SnapResolver.swift` pass `schemeFit: 0` or take the default. `EngineTests.swift:91` tests the
  term in isolation, so the formula is verified and never exercised.
- **In-match fatigue is structurally zero.** No call site ever passes `attackerFatigue` or
  `defenderFatigue`. `MatchupRules.fatigueWeight` is dead. Fatigue is a headline management concern
  in a coaching sim.
- **The professional tier has no trades, no waivers and no practice squads.**
  `ProMarketAction.trade`, `.placeOnWaivers`, `.moveToPracticeSquad` and `.promoteFromPracticeSquad`
  are never constructed anywhere. `proMarket.waivers` is therefore always empty, which makes the
  claim path, the expiry sweep, four event payloads and four error cases all unreachable. And
  `RulesTests.swift:196-201` pins the 16-man practice-squad limit — a test guarding the size of a
  collection that is always empty.
- **Recruiting and NIL mandatory decisions never reach the inbox.**
  `MandatoryDecisionSubject.recruiting` and `.nilAllocation` are never produced, so
  `CareerSession.applyDecision:452-461, 477-485` cannot run.
- **There is no victory formation.** `OffensivePlayType.kneel` is never produced by any caller, so
  a leading team runs live plays to the end.
- **`WorldHistoryReadModel.search` has zero callers**, and `entries` — up to 32,768 rows, rebuilt
  on every refresh — is never read.

**And six tests pin these dead features green**, which is why none of it surfaced:
`ModelTests.swift:235`, `GenerationTests.swift:322`, `ArchitectureTests.swift:274-293`,
`RulesTests.swift:15-20, 24, 196-201`, `PeopleLifecycleTests.swift:580`, and — most explicitly —
`ReadModelProviderTests.swift:1173-1181`, whose assertion is documented as *"correspondence is
empty because no inbox system exists"*. The suite has written down that the feature is absent and
made that absence the expected result.

**This modality is not exhausted.** Roughly 60 of about 200 named enums were swept. The reviewer
named the remaining high-yield ground: `IntegrityIssue`'s ~50 associated-value cases, the UI and
save-store vocabularies, the `SnapAnchors`/`SnapOutcome` broadcast vocabulary, error enums as a
class, and — the mirror modality, which produced three hits from three accidental samples —
declared struct *fields* with no consumer. A sixth round on the last two of those was running when
this report was written.

#### The mirror sweep: fields that are written, saved, and never read

The round-6 pass classified **all 1,212 stored properties across all 247 structs in
`Sources/FootballSimCore/`**, checking each for a read outside its own initialiser, `==`, `hash`,
`Codable` synthesis or a test. Seven more features turned out not to exist:

- **The game-plan review feature never runs.** Every game writes a review; nothing reads it.
- **`SnapAnchorSet.deciding`** — the whole information payload of decision D2 — is never read.
- **`MatchStepReceipt.boundary`**: the reason a match paused is computed and never surfaced, so the
  player is never told why play stopped.
- **`TacticalCallInOption.rationale` and `.risk`**: the coach-facing "why" on every call-in option
  is generated and never shown. In a game whose entire premise is that the player decides rather
  than acts, this is the explanation of the decision.
- **`Programme.rivalIDs`** is re-sorted every week by the scheduler and read by nothing — the
  rivalries screen recomputes the same order itself.
- **`ColourPair.onTeam`** — documented at `Colour.swift:108` as *"Whichever of white or black
  carries legible text on `primary`"* and computed by `ColourGenerator` through
  `legibleForeground(on:)`. Every reference to it in `Sources/` is inside the generator or the type
  itself; **no view reads it.** So the generator proves a WCAG-AA legible ink per team, stores it in
  the save, and the app paints team text with a different ink entirely. This extends CL-01: not only
  does the contrast test never look at a view, the one per-team contrast guarantee the engine
  actually computes is discarded at the module boundary.
- **`CareerProjection`** is rebuilt on every career intent and never read.
- **All 21 `MatchDayReadModel.ValidationError` cases are thrown and then swallowed.** Verified:
  `CoachWorldMatchProvider.swift:78` and `:329` are both `return try? MatchDayReadModel(...)`. Every
  read-model invariant the engine defends therefore fails as a `nil` model — which reaches the
  player as a blank Match Day with no diagnostic naming which invariant broke.

Below those: the saved record of which option the player chose (`MandatoryDecisionResolution.optionID`),
recruiting explanations, generated team flavour text, the "what just changed" lists in seven
`*Transition` types, the "what is new this week" event list, and the player-development story —
persisted three ways and shown nowhere. `MandatoryDecisionResolution.optionID` alone is about
500 KB of save data that nothing can resolve. And `ProDraftProspect.originProgrammeID` is never
written non-nil, so **there is no college-to-professional draft link at all** — the counterpart to
the promotion arc, and the same shape of gap. **The error sweep came back clean, and that is worth stating as a result.** All 21 `Error` enums
were found by conformance grep rather than a hand-list, and all 167 cases parsed: **165 are thrown,
2 are not** (`ProMarketError.waiverClaimExpired`, collapsed into `waiverClaimInvalid`, and
`ProManagementError.playerAlreadyRostered`, superseded). All 61 `IntegrityIssue` cases are appended
by some check, all 20 `check*` sub-functions are reachable from `WorldIntegrity.check`, and no dead
`catch` exists anywhere. On this axis the codebase is in good order.

The reviewer stated its own limits rather than claiming completeness: fields whose names collide
with fields on other types can score a false read (`title`, `reason`, `plan`), and closing that
needs a compiler-backed pass, not grep. The presentation layer's own ~125 structs — `ScreenReadModels.swift`
alone is 1,800+ lines — were used as readers but never swept as subjects.

**Taken together with the enum sweep, this is the largest single category in the review.** The
codebase carries a substantial quantity of vocabulary, state and computation that is declared,
maintained, encoded into every save, and connected to nothing.

### The season around the games is wrong too — 28 findings, measured

The competition and history lane also built a probe package against the real engine, so the
numbers below are output, not inference.

**Realignment is applied after the next season's schedule has already been built.**
`WorldScheduler.swift:715` calls `PostseasonSystem.completeSeason`, which generates the new
schedule at `PostseasonSystem.swift:177` (`ScheduleGenerator.regularSeason`).
`ConferenceRealignmentSystem.processTransition` runs at `WorldScheduler.swift:817` — **102 lines
later**. The comment immediately above it, at `:814-816`, states the required ordering explicitly:
*"both before the college cycle rebuilds the next season's schedule: the schedule is generated from
conference membership, so a swap has to land before it is read, not after."* The code does the
opposite of what its own comment specifies.
**Measured: all four realigned programmes play 10 of 12 games against their old conference and 1-2
against their new one. Every season.** Verified independently by the coordinating reviewer.

**Every touchdown in the world is credited to a quarterback.**
`AbstractGameSimulator.swift:222-228, 256-264`. **Measured: 4,207 touchdowns credited to
quarterbacks and zero to any other position.** Player of the Year is therefore a quarterback in
both tiers by construction — not by simulation.

**Every player action rebuilds a 29,053-entry history read model.** `CoachWorldStore.swift:127`
builds the whole `WorldHistoryReadModel` on every intent — **585 ms in release, on a Mac** — to
read two record-book rows the caller already holds in `state.competition.recordBook`.

And below those: home/away balance is never constrained (**measured a 12-0 all-home season**, worth
±28.8 points of scheduling advantage); a programme's bye week is a pure function of its UUID and is
**identical in all 20 seasons, for all 134 programmes**; the round-robin fallback fires in
production (1 of 40 pro schedules) and silently produces a 17-week season with no bye; the news
feed was **measured at 64 of 64 slots taken by a single payload kind**, with the weight-100
championship pushed off the feed entirely; raw enum tokens reach shipped copy ("…for
geographicFit"); leaderboards take the top 8 and *then* filter, so they render short; games-played
credits 105 players in an AI game and 23 in the user's own; an odd bracket count silently deletes a
whole round and bricks the save, reported to the player as `calendarDisagreement`; conference
championships affect nothing; and `points / 10` integer truncation is amplified fifty-fold into the
Player of the Year calculation.
---

## P1 — blocks the merge

### Careers that cannot continue

**A default new college career cannot advance past the postseason portal window.** Verified
end-to-end. `CareerControlState.swift:29-31` defaults every responsibility to `.user`.
`CollegePortalMatchingV1.swift:214-222` requires a `.portalRetention` resolution per retained
player whose `window == policy.window`. `MandatoryDecision.swift:410` is the only construction
site and hard-codes `window: .spring`. So in a postseason window the override set stays empty,
`makeMarketSnapshot` returns nil, and `WorldScheduler.swift:1037-1042` throws
`portalMarketFailed` — every time, forever. Both multi-season tests delegate all responsibilities
first (`CareerArcTests:238-244`, `M3CollegeSoakTests:18-25`), so the default configuration has
zero multi-season coverage. *(Condition: at least one player the AI baseline would retain, which
is the ordinary case for a populated roster.)*

**Promotion to the professional tier does not move the coach.** `CareerArcState` writes
`careerArc.currentJob` but only calls `clearCollege()`: the coach remains the college programme's
head coach, never joins the pro team, and never gains a pro `StaffCareerAssignment`.
`CareerArcTests.swift:81-83` asserts only what was cleared. CLAUDE.md calls the promotion arc
"a v1 feature, not a sequel". The fix exists as commit `3967855` on
`claude/coach-career-promotion-integrity-f10168` and on three other branches — **unmerged on all
four**.

**An over-cap professional team bricks `advanceWeek` permanently.** `enforceCapCompliance`
exempts the controlled pro team; `checkProfessionalCap` does not, and the scheduler runs it
weekly. `CapComplianceTests.swift:124-156` builds this exact state and omits the integrity
assertion its sibling test makes.

**Dead money is never retired.** `ProTeam.deadMoney` has two writes in all of `Sources/`, both
`+=`. It is charged in full every season and its own compliance loop feeds it until week 21
throws permanently.

**Being fired or resigning is unrecoverable.** Opportunities are minted only when
`career.college != nil`, which both separation paths clear. The app still says "Returned to the
job search."

**A save with a `matchSession` present bricks the career.** `matchSession` has zero references in
WorldIntegrity's 2,283 lines. A save with a present session and `fixtureID: null` passes every
gate; the only `matchSession = nil` in the engine is inside the finalize that throws.

**Infinite hang in recruiting.** `CollegeRecruitingSystem.swift:458` discards `addToBoard`'s
`Bool` and mirrors only two of its three guards. A relationship without a board entry makes
`apply` report success with no state change, and the unbounded `while let` at
`CollegeRecruitingAISystem.swift:877` spins forever. The orphan state is reachable through the
public initialiser and passes the decoder.

**`ProRules.salaryCap` traps on overflow around season 331**, reached from
`GameState.init(from:)`'s own integrity check *before* it can throw its `DecodingError`. The doc
comment above it says "clamp, never trap".

**Overflowing the 512 free-agent bound throws out of week 21 deterministically**, so a save that
reaches it can never leave it. `expireContracts` pre-checks only its own batch, not the resulting
pool size.

### Correctness of the things that guard correctness

**`WorldIntegrity.activeChecks` is a hand-written array, not a call graph.** 27 of 61
`IntegrityIssue` cases are named in no test. Deleting the roster-limit or history-bound check
leaves all 139 `check(state).isValid` assertions green. `ArchitectureTests.swift:398` actually
*fails* if you activate every check.

**The integrity gate is step 14 of 15.** Seven mutations, two destructive compactions and two
event appends run *after* it, and `.advanceWeek` is the only `IntentResolver` intent with no
post-check. The state that gets returned is never the state that was validated.

**`referencedEntityIDs` ends in `default: return []`** (`DomainEvent.swift:321-322`) — 43 lines
below a comment on the neighbouring property reading *"A `default` would silently score every
future event zero, which is exactly the coverage boundary CLAUDE.md calls a defect."* And this
function is what the uncommitted `compactHistoryBoundState` uses to decide what to **keep**: a
payload case falling through contributes no retained IDs, so the people it names are deleted
while the event survives and still names them. Silent, permanent save data loss.

**`catch { expect(true) }` at 42 sites.** Every hostile-decode test passes on any error at all,
including a `keyNotFound` caused by the test's own hand-written key string.

**The harness reports success for a run in which nothing executed.** `TestKit.finish()` defines
success as `failures.isEmpty`; a suite registering zero tests prints `[ok]` and exits 0. Counts
are printed, never asserted. `M3_SOAK_SEASONS=1`, `PRO_SOAK_SEASONS=1`,
`M3_RECRUITING_SEASON_ONLY` and `M7_GATE_SEASONS` already shrink release gates to nothing while
`verify.sh` reports PASS.

**Six of seven `[Position: …]` rules tables have no `Position.allCases` totality check**, and
every consumer reads them `?? 0` — including `WorldIntegrity.swift:2275`. A new position is
invisible to the entire suite while visible on every screen.

### Decode is the trust boundary, and it leaks

**The save body is parsed twice** — once by `JSONSerialization` into an untyped graph before any
typed guard runs. A ~600 KB zlib bomb reaches the 512 MB `maximumBodyBytes` cap and jetsams the
app before the quarantine handler can run. Permanent launch crash from one fixed save path.

**Quadratic decode validation over unbounded, attacker-controlled counts**
(`CollegeState.swift:632-637`), while lines 638 and 640 bound their neighbours.

**`retentionLimit` is save-controlled** (1…100,000) and sizes the window four integrity checks
validate. `retentionLimit: 1` makes them permanently vacuous.

**Validation that lives in a memberwise initialiser does not run on decode.**
`OffensiveCall`/`DefensiveCall` clamp `aggression` at `PlayCall.swift:74` and are decoded by
synthesised `Decodable`, which assigns stored properties directly. `GameEngine.swift:77,80,90`
then does `Int((aggression * 1_000_000).rounded())`, which traps — *inside*
`playByPlayFingerprint`, the function that exists to prove determinism.

**No migration path.** The document layer has a version field and nothing else; the first bump
quarantines primary and backup and strands every existing career.

**The quarantine directory grows without bound**, is written on every failed load of both primary
and backup, is never pruned, is omitted from `delete()`, and is not excluded from iCloud backup.

### The app layer

**The 2026-08-20 app-layer latency fix is not on this branch.** Four of its five named causes are
live verbatim, plus `WorldHistoryReadModel.build` and `CoachingTreeReadModel.build` running per
tap to extract two rows.

**Match Day auto-advance chains a 28-model rebuild plus a full encode/decode/write/read-back save
per snap**, behind a `.disabled` spinner with no way to stop it.

**`saveDocument()` busy-waits on the main actor** — `while isWorking { await Task.yield() }`.

**Dynamic Type is dead at 206 typography sites** — `Font.system(size:)` with no `relativeTo:`.
Six chrome tokens sit at 9–10.5 pt under a 12 pt floor whose only test asserts
`authoredFloor >= 12`, a constant rather than a call site. **STATUS.md's claim that G-35/G-36 are
closed does not hold.**

**The AX5 accessibility contract is two substring greps.** `RankingsPlayoffPictureView.swift:29-33`
and `BracketPostseasonView.swift:29-33` have byte-identical if/else branches and pass it.

**15 render arms in the root switch are statically unreachable.** `career(_:)` switches on
`Self.canonicalScreen(screen)`, which rewrites every alias first, and the alias table has exactly
15 entries. The surfaces are still reachable through their canonical destinations — the defect is
dead code plus 14 assertions that certify "reachable from the shipped app root" by grepping the
root view's source text, and which would turn **red** if someone correctly deleted the dead arms.

### Concurrency — and a correction to this report's own earlier verdict

I recorded, mid-review, that Swift concurrency in this project was sound: zero `@unchecked
Sendable`, zero `nonisolated(unsafe)`, a tiny actor surface, and `CareerSession` containing no
`await` in any method so reentrancy is structurally impossible there. The last of those is true.
The conclusion drawn from it was wrong, and a later reviewer caught it. Both corrections follow,
because how a wrong verdict was reached is as useful as the verdict.

**`Package.swift:49` sets `swiftLanguageModes: [.v5]`** (and the app target `SWIFT_VERSION 5.10`).
Under language mode 5 the compiler does **not** enforce `Sendable` conformance or actor-isolation
crossings. So "zero `@unchecked Sendable`" is not evidence of anything: all 471 `Sendable`
conformances and all 5 `Task.detached` isolation crossings are unchecked. I generalised from the
absence of an escape hatch without noticing that the checking it escapes was never switched on.

**`SaveCoordinator.flush` has a live actor-reentrancy race** — `CoachWorldSaveStore.swift:306-360`.
I checked `CareerSession`, found no `await`, and generalised to the other actor. `SaveCoordinator`
is the one with suspension points, and it clears its in-flight handle unconditionally after each:
```
if let active = flushTask {
    generation = try await active.value      // suspension point
    ...
    flushTask = nil                          // no identity check
    flushingGeneration = nil
```
Failure scenario, verified against the source: caller A suspends awaiting task T1. While A is
suspended, B enters the actor, also awaits T1, resumes first, sets `flushTask = nil`, loops, sees
`pending`, starts task **T2**, sets `flushTask = T2`, and suspends awaiting it. A now resumes and
executes its own `flushTask = nil` — niling out **T2's** handle while B is still awaiting it. A
loops, sees `flushTask == nil` and `pending` non-nil, and starts task **T3**. Two detached writers
are now running `storage.write(candidate)` and `storage.read() == candidate` against the same save
file. The verification read can observe the other writer's bytes and throw
`SaveCoordinatorError.writeVerificationFailed`, and `writeBackup(current)` can capture a
half-written primary — collapsing primary and backup to the same generation, which is the exact
scenario the backup exists to prevent.
`CoachWorldAppRootView.swift` has 83 unstructured `Task {}` sites feeding this path, and
`CoachWorldStore`'s `isWorking` guard releases before the save half runs, so concurrent entry is
not exotic.
The shape of the fix is one line — compare identity before clearing (`if flushTask === task`) —
but the language mode is the reason nothing flagged it.

### Calibration — the third gate CLAUDE.md names, and it does not exist

CLAUDE.md's completion gate lists "calibration bands" among the machine gates the agent must
assert. Verified directly, that gate asserts nothing about the engine.

`grep -rn "holdoutSeeds" Sources/ Tests/ scripts/` returns **three** hits in the whole repository:
the declaration at `CalibrationHarness.swift:35`, and two in `CalibrationTests.swift:190,192` that
only check the tuning and holdout sets are the same size and disjoint. **`holdoutSeeds` is never
passed to `CalibrationHarness.run`.** The holdout rule the harness states at its declaration site —
"Tune against A. Report against B. A band tuned until B passes is a band fitted to its own test" —
is correct methodology, written down, and inert.

All three `run` call sites (`CalibrationTests.swift:197, 199, 210`) pass
`Array(CalibrationHarness.tuningSeeds.prefix(2))` — 2 seeds × 12 matchups = **24 games**. And the
three tests assert, in order: that the two seed sets are disjoint; that two runs of the same seeds
produce the same numbers; and that `report.results.count == declared.count`.

That last one does close a real hole — a band whose metric went unmeasured would otherwise vanish
from the report rather than fail. But it is the *only* assertion about a report, and
`grep "report.passed\|report.failures" Tests/SimTests/Suites/CalibrationTests.swift` returns
**nothing**. **No test anywhere asserts that a single calibration band passes.** The three
properties tested are properties of the instrument — reproducible, complete, disjointly seeded —
not measurements of the engine.

`scripts/verify.sh:111-113` routes the `calibration` lane to `--calibration`, which runs exactly
those tests. So `./scripts/verify.sh --lane calibration` reports green while measuring nothing
about how the simulation plays. (That lane is also never invoked by CI — see the P2 process list.)

And the tuning side has no A/B split at all: `scripts/tune-calibration.sh` regex-rewrites
`MatchupRules.swift` and `ClockRules.swift` **in place**, optimising against a `SCORE` printed by a
probe binary at a hard-coded scratch path belonging to a previous session. Tuning happens against
an unnamed objective, and the holdout that was supposed to police it never runs.

**And what it does measure, it measures on a four-man offensive line.** Verified by reading both
tables:
```
DepthChart.offensiveTemplate         (Model/DepthChart.swift:217-220)   13 positions
  ... .leftTackle, .guardPosition, .guardPosition, .center, .rightTackle, ...
CalibrationHarness.offensivePositions (Calibration/CalibrationHarness.swift:248-251)  12 positions
  ... .leftTackle, .guardPosition,                  .center, .rightTackle, ...
```
One `guardPosition` instead of two. The real depth chart fields a five-man line — LT, G, G, C, RT.
Every calibration roster fields four. So pass protection, sack rate and run blocking are all
measured against a formation the game can never put on the field, and sack rate on blitz downs is
systematically under-reported. `DepthChartTests` pins the 13-position template — against itself.

Putting the four together: the calibration gate runs on 2 seeds and 24 games, against a roster
missing an offensive lineman, never touches the holdout set, and asserts nothing about whether any
band passes. The project's recorded "21 of 24 bands hold" is a measurement of something the game
does not do.

*This corrects an earlier judgement in this review.* I read the holdout docstring and the
`results.count == declared.count` assertion, confirmed the second closed the silent-drop hole, and
recorded the calibration harness as methodologically sound. The instrument is well built. The gate
around it is not, and one assertion does not make a chain.


### Corrections to this review's own account of the uncommitted compaction work

The uncommitted-diff reviewer ran for two and a half hours, built probe packages, and executed
**full 20-season A/B soaks in release**. Its measurements overturn two things stated earlier in
this report and sharpen a third. The originals are left standing above; these are the corrections.

**The change is a real improvement, not a regression.** Earlier text here treats the deletion of
`compactedForDeparture()` and the unbounded `recruitingOrigin` carve-out as making save growth
worse. Measured, on the same seed over twenty seasons in release:

| | season 20 save | seasons failing the 8 MB gate |
|---|---|---|
| baseline (HEAD) | 27,275,963 B | all 20 |
| with the change | 21,047,177 B | 4 through 20 |

A genuine **~23% constant-factor win**. What does *not* change is the slope — about 0.76 MB per
season either way — so it still lands at roughly **2.5× the 8 MB ceiling** and buys three seasons,
not a fix. That is the accurate framing: the carve-out is unbounded and the bound above it is
therefore not a bound, but the work as a whole moves the number in the right direction.

**The performance concern was wrong, and is withdrawn.** Earlier text argued that routing three
call sites through `compactHistoryBoundState` would walk the retained history six times a week at
superlinear cost. Measured: `weekMean` **improved from 5.63 s to 3.05 s**. The extra traversals are
paid for many times over by the smaller state everything downstream then handles. I inferred a cost
model instead of measuring one.

**The coaching-tree deletion is worse than stated.** The earlier finding was that compaction
silently erases tree history. The reviewer adds the part that makes it a defect rather than a
trade-off: `CoachingTreeReadModel`'s own documentation names `staffCareers` as its authority, and
`SeasonLifecycleSystem` **deliberately keeps retired staff alive** to serve it. Compaction deletes
exactly what another system is deliberately preserving. And no test catches it — `CoachingTreeTests`
uses synthetic states, and the new soak assertions are *satisfied by* the deletion.

**One more staged-index consequence.** Beyond the `checkPortalCapacity` narrowing already reported:
`compactedForDeparture()` is still present in the staged version while `CollegeCycleSystem` and
`NewsFeedTests` are not staged at all. A plain `git commit` therefore ships a compaction that drops
portal history *and* a `checkPortalCapacity` that stops validating every historical season — two
halves of two different designs.

**A methodology warning worth carrying forward.** The reviewer's first release measurement was
wrong: `.build/release/SimTests` was twelve hours stale and SwiftPM did not rebuild it, so the
numbers were HEAD's, not the change's — and they pointed the opposite way. Release runs need
`-Xswiftc -enable-testing` (see `scripts/verify.sh:92-97`). **Check the binary with `nm` before
trusting a release measurement in this repo.**

**One discrepancy, left open rather than resolved.** That reviewer reports "the whole suite is
green". This review ran the default suite directly and got two failures on the cross-process
determinism pins (P0-10), and a parallel session bisected those failures to `c6e2d21` against clean
`git archive` extracts. Two independent sources say red; one says green. The most likely explanation
is that the green claim covers the lanes that reviewer ran rather than the no-flag default, but it
was not run down. Treat P0-10 as standing.
---

## P2 — should fix

**Weight and hygiene**
- 166 logo PNGs at 1024×1024, **163 MB** on disk (the same-day performance audit measured the
  xcassets directory at 156.2 MB, and the **built device app at 155 MB with `Assets.car` alone at
  109.6 MB against a 72 KB executable**), drawn into 20/32/44 pt slots — ~8× oversampled linearly,
  ~60× by area. A 1024² RGBA decode is ~4 MB resident; a 24-row standings table retains ~96 MB of
  bitmaps to draw 24 icons. `UIImage(named:)` caches, so this is retained, not transient.
- `git add -A` in this working copy would stage **7.4 GB**: `.claude/` (7.1 GB) and `exports/`
  (329 MB, containing a 163.8 MB zip plus an unzipped copy) are untracked and **not** in
  `.gitignore`. `.gitignore`'s own comments record two prior accidents of exactly this kind.
- `.git` is 492 MB; all 333 resource files are tracked, no LFS. Regenerating the assets smaller
  later does not shrink history.
- The checked-in `TeamLogoCatalog.generated.swift` is **332 fields stale** against
  `manifest.json` — `c6e2d21` rewrote every name and the generator was never re-run. Same
  `stableID` reads "Oakhaven Heath Upper"/"OAK" in the catalog and "Altus, OK City College"/"ALT"
  in the manifest. No drift check exists, and the file's first line says "Do not hand-edit".

**Legal, beyond the P0s**
- Nothing checks a shipped logo against any *real* mark; the ΔE rule is applied to the declared hex
  pair, never to the artwork's pixels.
- The manifest asserts `"humanApproved": true` on all 166 entries. PR #41's own body says
  "Never built or tested by me… I have not reviewed these 18 generated logos against that test or
  that rule." The count also disagrees: 18 claimed, 166 present.
- `c6e2d21` find-and-replaced team names into all 166 `concept`/`prompt` fields while keeping the
  approval flags and the "owner approved" notes, and **stripped the word "fictional" from all 166
  prompts at the exact moment names became real places**.
- Logo prompts and concepts are screened by a hand-listed four-acronym denylist and by no
  blocklist scan at all.
- `abbreviation(name)` (`CoachWorldReadModelProvider.swift:488`) is a generated, player-facing mark
  that no legal test sees — and it is the *only* mark at non-default seeds (see P0-5).
- `ProTeam.name = city.name` (`LeagueGenerator.swift:194`) makes the place/institution kind split
  load-bearing, undocumented, and protective only by accident.
- The only "exhaustive" blocklist test checks single words, so 103 of 274 entries — every venue,
  every person, every multi-word school — are structurally undetectable by it.
- The human trademark screen's own findings (`Harrow`, `Jessup`, `Kestrel`, `Fairbank`) were never
  added to any blocklist limb, and its remediation list now names teams that no longer exist.
- Nickname and conference pools were re-screened only against "Division I", so names from outside
  that boundary remain.

**Determinism**
- The salted-hash source scan checks a spelling (`.hashValue`, `Hasher(`, `hash(into:`), not the
  mechanism. **Nothing anywhere scans for `Set`/`Dictionary` iteration order** — the thing that
  actually leaks the per-launch hash salt. The scan is also rooted only at
  `Sources/FootballSimCore`, so `Sources/CoachWorldApp` — which holds `GameState` — is unscanned.
- The ambient-identity marker list misses `.randomElement()`, in-place `.shuffle()`, and every
  non-`Date` clock.
- Cross-process coverage is four pinned literals: bootstrap, bootstrap + one week, and two
  `GameEngine.play` runs. `AbstractGameSimulator`, the controlled `MatchReducer` path, and
  everything past week 1 have no pin. In-process fingerprint comparisons cannot detect
  iteration-order instability by construction.
- 8 of 11 `SeedScope` cases are unpinned and the identifier-overload seed derivation has no golden
  vector.
- The cross-process pin ultimately rests on `Foundation.exp/log/cos`, which are not correctly
  rounded and not guaranteed stable across architecture or OS, while every outcome threshold is a
  bare `Double` comparison. One ULP flips an interception, and the divergence amplifies because
  the snap seed derives from `plays.count`.
- The SnapAnchors purity gate is filtered by literal *filename*, so splitting an 806-line file
  silently drops it.

**Growth and bounds**
- D7's bounds table in `OPEN-DECISIONS.md:323-333` has already drifted from the code: FA pool 400
  vs 512; news feed 200 vs 64-and-not-persisted; record book "top 50" vs two optionals.
  `archivedProspects` carries two contradictory bounds 24× apart — 100,000 at
  `CollegeState.swift:638` against 4,096 at `WorldIntegrity.swift:1175`.
- No test enumerates the persisted collections and asserts each has an enforced bound.
- The three save-shape scans stop at `Sources/FootballSimCore`; the save's root type
  `CoachWorldSaveDocument` lives in `Sources/CoachWorldApp` and is scanned by nothing.
- `CompetitionState` and `SeasonSchedule` have no custom decoder, so their write-path bounds are
  not decode-path bounds.
- Compaction now walks the entire retained history six times per simulated week (three call sites,
  two full traversals each), where the previous code did three cheap prospect filters.

**Integrity coverage gaps**
- `identities` is the only root collection with no orphan check, no bound and no field validation.
  One edited `homeCityID` silently removes a programme from recruiting *and* the portal for the
  life of the save.
- `history.archive[].notableEvents` is validated by nothing and rendered by everything; digest
  seasons are unbounded above `calendar.season`, so a fabricated future headline pins to the top
  of the news feed permanently.
- `reservedIdentityIDs` covers `recent` but not the archive, so a generated walk-on can take a
  UUID an archived event still names.
- `Rivalry` has no self-pair, tier or duplicate-pair check, against its own type comment.
- The `IntegrityCheck` enum, the `activeChecks` array and the `check()` body are three
  unreconciled hand-maintained lists; two running checks have no enum case, and `inactiveChecks`
  reports a falsehood.
- `WorldIntegrity.check` runs a full `CompetitionReducer.rebuild` on every call and is invoked
  ~10× in a single rollover week.

**The rest of the app layer**
- `PlayerProfileView` and `GameDetailBoxScoreView` are never passed `statusMessage`; refused
  navigations and failed autosaves vanish there.
- Tapping Speed on Match Day prints "That match action is unavailable at this checkpoint" and
  triggers a full world save.
- The design-token-literal scan covers 14 markers; ~206 CGFloat literals hide in 20 per-view
  `*Metric` enums, plus 88 `.opacity()` and 34 frame literals. The green fix for a caught literal
  is to hide it in one of those enums. `CoachWorldTeamLogo.swift:9-13` is a fresh instance —
  `case compact = 20, medium = 32, large = 44`.
- Every team logo is `.accessibilityHidden(true)` at all 18 call sites, with a dead
  `.accessibilityLabel(team.name)` on the line above. No call site passes `isDecorative: false`.
- The "All tasks" overlay is visual-only; nothing behind it is `accessibilityHidden`.
- Sibling links extend their 44 pt hit target vertically only; the `NIL` link is about 18 pt wide.
- The identity header is pinned to a hard-coded 709 pt against `maxWidth: .infinity` content, so
  it misaligns on every device wider than the 844 floor.
- Recruiting bands and a condition percentage are computed in the app target; a missing lifecycle
  record renders as 100% condition.
- Adding screen 63 needs 11 edit sites, one of which the compiler enforces. The render switch's
  `default:` silently shows Coaching HQ, and `allCases.count == 62` is a test literal.
- The two image-lookup paths in `CoachWorldTeamLogo` are mutually exclusive; whichever is live
  differs between the SwiftPM macOS build (which the suite uses) and the Xcode iOS build (which
  ships). The `contentsOfFile` path does not cache, so a 1 MB PNG re-decodes to a 4 MB bitmap on
  every body evaluation.
- The sole `#if canImport(UIKit)` in the codebase is this new logo renderer; its iOS branch is
  compiled only by `verify.sh --lane app`, which nothing automated runs.

**Process**
- CI runs one lane. The `app`, `soaks`, `calibration` and `archive` lanes are never invoked, and
  `timeout-minutes: 60` is below the recorded 20–85 minute `--m7-gate` runtime.
- 16 suites are outside the default run, including this branch's own `runInjuryEvidenceTests`,
  plus `runWeeklyAuthorityTests`, `runProfessionalCareerSessionTests`, `runProWeekWalkTests` and
  `runPerformanceBudgetProbe`.
- `SuiteCatalog.defaultRun` is read by nothing. The real default is a hand-maintained `else`
  branch of ~60 calls in `main.swift:161`.
- `PerformanceBudgetTests` asserts no threshold and pins the league size.
- Local `main` is 71 commits behind `origin/main`, so every "vs main" comparison made in this
  working copy is measured against a stale baseline.
- 13 open PRs, several large and dormant. PR #11 is 46 ahead / 268 behind, 97 files, +12,183
  lines, and its own tip commit reads "the run stopped mid-suite".
- 40+ local branches with no lifecycle marking; dead and live are indistinguishable.

**Concurrency and the save path (round 5)**
- `isWorking` covers only `run`'s intent-and-rebuild; every caller's `persistOrReport` runs after it
  clears, so `.disabled(store.isWorking)` (`RootView:1014`) releases mid-save. Match Day's 1.2 s
  auto-advance timer (`MatchDayView:531-544`) then fans out roughly **ten concurrent full-`GameState`
  documents per drive** and reaches the `SaveCoordinator` flush race with no user input at all.
- `saveDocument` bumps `metadata.generation` unconditionally (`CoachWorldStore:250`), so **every
  tap — including a refused advance** — forces a full encode, two reads, two writes and a
  byte-compare readback of a save that is ~26 MB at season 20.
- `guard !isWorking else { return }` (`Store:561`) drops a second intent with no receipt; a dropped
  PAUSE during playback is silent, and the winning order shows the pause-tapper a false "checkpoint
  is no longer current".
- Seven sites (`RootView:486/500/513/526/625/640/654`) mutate the world and never persist, and
  there is no `scenePhase` hook anywhere in the app.
- `failure` is latched on save error and never cleared on success, shadowing `store.statusMessage`
  on roughly 50 surfaces.
- `restoreExistingCareer` lacks the `!isRestoring && !isStarting` guard its sibling
  `recoverFromBackup` has, so Retry and Use-backup can both assign `store`.
- `beginNewCareerSetup`/`refreshStartingJobs` have no re-entry guard, and `Task.detached` makes a
  superseded `GameState.bootstrap` uncancellable.

**Divergence between duplicated tables (round 5)**
- **Three copies of the 40-99 rating band table, all disagreeing.** A 70 overall renders amber on
  the Roster and **red** on seven other screens; one card shows two different greens.
- The one status receipt has **30 render sites and 5 treatments**. Match Day renders refusals as
  muted chrome, disagrees with itself across type sizes, and only the Career Hub announces it to
  VoiceOver.
- Decision titles diverge — the HQ names the person, the Inbox prints the literal word "player".
- Five record formatters: one drops ties, and one uses an en dash beside a hyphen in the same frame.
- The stakeholder label is "Athletic dir." on one surface and "Administration" on another.
- The `replacement` seed pair differs only by `.scheduler` vs `.personnel` on the third derive over
  overlapping `(seed, org, season, ordinal)` tuples — aligning them to the scope the enum's own
  documentation prescribes would make the replacement player and the replacement coach draw the
  same name. A determinism trap sitting one refactor away.
- Shipped chrome uses the long sibling names the registry documents as overflowing; two of four
  `route()` copies lose the team colour; one of five `fact()` copies clips at large type; and Match
  Day's chips announce "Pause" when the action is "Resume".

**Season structure (round 4, measured)**
- Home/away balance is never constrained — **a measured 12-0 all-home season**, worth about ±28.8
  points of scheduling advantage.
- A programme's bye week is a pure function of its UUID and is **identical in all 20 seasons, for
  all 134 programmes**.
- The round-robin fallback fires in production (1 of 40 pro schedules) and silently produces a
  17-week season with no bye.
- The history index is 89% full after one season, growing ~198 entries a season, and its truncation
  order is alphabetical by kind — so seasons, records and rivalries are dropped **before** players.
- **Measured: 64 of 64 news-feed slots taken by a single payload kind**, with the weight-100
  championship pushed off the feed.
- Raw enum tokens reach shipped copy: "…for geographicFit".
- Leaderboards `prefix(8)` and *then* filter, so they render short.
- Games-played credits 105 players in an AI game and 23 in the user's own.
- An odd bracket participant count silently deletes a whole round and bricks the save, surfaced to
  the player as `calendarDisagreement`.
- Conference championship results are excluded from standings, so winning one affects nothing.
- Rivalry intensity only ever increases, with no restoring force (measured 0 → 2 at the ceiling
  over five seasons).
- **Measured: 10-12 of 12 games are in-conference**, so there is effectively no non-conference
  schedule.
---

## What is genuinely well built

This section is not politeness. The report's criticism is only usable if it is calibrated, and
several of these are the pattern the broken parts should be rewritten toward.

**The motion contract is the best test in the repository, and it is the model for fixing Pattern 1.**
`MotionContractTests.swift:105-155` does three things nothing else in the suite does:
1. **Containment instead of spot-checking** — `test("no view outside CoachWorldMotion.swift names
   raw motion vocabulary")` scans every view source and requires all motion vocabulary to sit behind
   one choke point. Surface 63 is covered the day it is added.
2. **An explicit anti-vacuity guard** — `expect(!consumers.isEmpty, "found no view sources to scan
   — the scan would pass vacuously")`. This is the single most valuable line of test code in the
   project, and the one line whose absence explains most of Pattern 1.
3. **Self-tests of the detectors** — `test("the containment scan catches raw vocabulary and spares
   the choke-point call")` and `test("the canon-sync scan catches a drifted value and a name only
   one side ships")` assert that the checkers actually fail when they should. And
   `test("the choke point actually contains what it claims to wrap")` reasons explicitly about the
   case where deleting the choke-point file would make the containment scan pass perfectly —
   *"an empty file has no raw vocabulary anywhere, inside or outside itself."*

**The ΔE mechanism itself is correct.** `Colour.deltaE` (`Colour.swift:47-52`) is CIE76 in L\*a\*b\*
under D65 — perceptual, not naive RGB. `ColourGenerator.swift:34-40` compares both members, as a
pair, in both orientations, and the swap case and the single-shared-colour case each have their own
test. The gate is well made; the table it consults is what is missing entries (V-13).

**The legal suite plants known-real strings to prove the scanner fires.** `LegalTests.swift`
plants "Delta State", "Pine Bluff", "Western Reserve", "Old Dominion" — the exact strings the prior
build shipped under a comment reading "Fictional alma maters" — and asserts they are caught. It also
guards against a vacuous sweep (`expect(names.count > CollegeRules.programmeCount)`) and checks each
named kind lands in the correct limb. The author was thinking about precisely the right failure
modes. It is the one line meant to close the loop (V-11) that closes on itself instead.

**The blocklist normaliser already survived one evasion class and documents it.** Its docstring
records that whole-string normalisation let `Old Dominion Tech` through in the prior build, and the
fix to word-sequence matching. That reasoning is exactly right; the diacritic class (V-12) simply
was not considered.

**Load ordering is deliberate and correct.** `CoachWorldStore.make(from:)` constructs `CareerSession`
— which runs `WorldIntegrity.check` and throws — *before* building any read model, with a comment
saying why. That ordering is what refuted a claimed crash path (V-05).

**`PRODUCT.md`'s "Unverified product targets" table is unusually honest.** It states outright that
the 6–8 hour season is unmeasured, that "the 20-season gate has not passed", and that week advance
"measured … 4.031 s … the 2.0 s ceiling is exceeded". Very few projects write that down. The
criticism in CL-01/CL-02 is aimed at the *other* table in the same file.

**`EntityStore` has canonical iteration order by construction.** `ids` sorts by `uuidString` and
`values` derives from `ids`, with a docstring explaining that surfaces must not depend on dictionary
order. This is why the determinism reviewer's sweep of every unsorted `.values`/`.keys` iteration in
the engine came back clean.

**The documentation system holds.** All five `RETAINED` documents in `docs/DOC-MANIFEST.md` exist at
their stated paths, and the deliberate decision to delete rather than archive superseded documents is
recorded and consistent.

**Money is integer dollars throughout the persisted graph** — checked and confirmed clean by the
persistence reviewer, exactly as CLAUDE.md requires.

**"Offline, zero third-party dependencies, no network of any kind" is true in fact.** Verified
directly: `grep -rn "URLSession\|URLRequest\|NWConnection\|https\?://" Sources/` returns nothing
at all, and `Package.swift` contains zero `.package(` declarations — only internal target
dependencies. A reviewer flagged that the *test* enforcing this is a two-file hand-list, which is
a fair criticism of the gate; the property itself holds today, and it is the one claim in this
project with direct App Store privacy consequences.

**The dictionary-key encoding guard is complete, and it survived a deliberate attempt to break
it.** `Support/CodingSupport.swift` solves the hazard that a Swift dictionary whose key is not
`CodingKeyRepresentable` encodes as a flat `[key, value, key, value…]` array **in hash order,
which differs run to run** — the exact cross-process save-byte churn that in-process tests cannot
see. Its own comment states why: "within one process the hash seed is constant, so a round-trip
test and a repeat-encode test both pass while the bytes churn between launches."

I tried to find a key type it missed. I extracted every dictionary key type used anywhere in
`FootballSimCore`, subtracted the conformances declared in `CodingSupport.swift`, and got two
candidates — `CareerStakeholder` and `DisciplineIncidentKind`. `CareerStakeholder` is a *stored,
persisted* property of `CareerArcState`, so it looked like a live defect in the one mechanism
protecting save determinism.

It is not. `CareerArcState.swift:10` declares `extension CareerStakeholder:
CodingKeyRepresentable {}` next to the type that uses it — one of 13 conformances across the tree,
of which `CodingSupport.swift` holds 10. `DisciplineIncidentKind` appears only in a non-persisted
`static let` rules table. My method was wrong; the guard was right.

Two design choices are why it held, and both are worth copying:
1. **The scan looks for the conformance anywhere in the engine**, not in one blessed file, so a
   conformance declared next to its type still counts.
2. **The exemption list is empty and inverted.** `saveShapeExemptDirectories: [String] = []`, with
   the comment: "Exempt-by-name, cover-everything-else — the inversion the ambient-identity scan
   already uses, carried across after P2 put ten `Codable` save types in `Generation/` while both
   of these scans still walked `Model/` alone. Nothing is exempt today; the list exists so that a
   future scratch-only directory is an explicit, visible decision rather than a scope that quietly
   stopped covering the tree."
   And `inherentlyKeyableTypes` deliberately excludes `UUID`, with the reasoning that allowlisting
   it "would have been allowlisting the fix rather than checking for it."

This is the antidote to Pattern 1 and Pattern 2, already written, already in the tree. The
project does not need to invent the technique — it needs to apply this file's standard to the
legal partition assertion, the reachability tests and the retention bounds.


**The error vocabulary is in good order, and it was checked exhaustively rather than sampled.** All
21 `Error` enums were found by grepping for the conformance, not by a hand-written list — the method
the rest of this report keeps asking for. All 167 cases were parsed: 165 are thrown somewhere, and
the 2 that are not are both explicable (`ProMarketError.waiverClaimExpired` collapsed into
`waiverClaimInvalid`; `ProManagementError.playerAlreadyRostered` superseded). All 61
`IntegrityIssue` cases are appended by some check, all 20 `check*` sub-functions are reachable from
`WorldIntegrity.check`, and there is no dead `catch` in the codebase. Against a review that spends
most of its length on vocabulary that connects to nothing, this axis came back clean.
---

## Recommended sequence

Nothing below was applied. The ordering matters more than the individual items, because two of the
P0s interact.

**0. Note that the suite is currently red.** `ArchitectureTests.swift:83-84` — both cross-process
determinism pins fail on the working tree. Do not re-pin them as a first move; establish which
state-shape change moved them and whether that change is one you are keeping (steps 1 and 2 decide
that). Re-pinning to whatever the code currently emits turns the project's only cross-process gate
into a recording of present behaviour.

**1. Before touching any code: decide the index.** `git commit` without `-a` right now ships a
weakened integrity check that nothing has built or tested. Either `git add -A` the five `MM` files
(after adding `.claude/` and `exports/` to `.gitignore` — otherwise that same command stages
7.4 GB) or `git reset` the index. Do this first; every other step is confounded until the tree and
the index agree on what the code is.

**1b. The uncommitted compaction cannot ship as it stands — but do not throw it away.** It bricks
`advanceWeek` (P0-11) because `WorldIntegrity.swift:1012` derives `requiredArchivedProspectIDs` from
`history.recent` while the change widened the other side of the same comparison; widen both, or
neither. Measured, the rest of the change is a **~23% save-size win** (27.3 MB → 21.0 MB at season
20) with the slope unchanged, and it **improves `weekMean` from 5.63 s to 3.05 s**. It is worth
keeping once the mirror derivation is fixed and the coaching-tree deletion is addressed —
`SeasonLifecycleSystem` keeps retired staff alive on purpose, and compaction deletes them.

**2. Then rebase on `origin/main`, before any more compaction work.** This branch is 208 commits
behind and is re-solving a problem that was solved upstream a day earlier, worse. `fc2cb2c` already
bounds departed-player retention with oldest-first eviction, an integrity-coupling argument,
measured numbers and a real assertion; the uncommitted work here adds a differently-named constant
whose bound is discarded by the next statement. After the rebase, re-ask whether the uncommitted
change is needed at all. Resolving that conflict in favour of the newer code silently reverts a
landed fix.

**3. The two legal P0s must be sequenced together, and this is the trap.** The fix for the
trade-dress breach is to add professional colour pairs to `Blocklist.tradeDress`. But
`ColourGenerator.swift:69,71` is a rejection-resampling loop whose draw count depends on that
table's contents, and team UUIDs are positions in the RNG stream, and the logo catalog is keyed by
those UUIDs. **Adding entries to the trade-dress table invalidates the entire 163 MB logo catalog
even at the default seed.** So: re-key the catalog on something content-derived first, then fix the
table. Doing it in the other order costs the logo set twice.

**4. Take the trade-dress finding to counsel, not to a code change.** CLAUDE.md is explicit: "Flag
anything borderline for the owner to take to counsel; never resolve it yourself." Twelve shipped
identities, with artwork generated from the matching hexes. Confirm the reference colour list
against an authoritative source first (see the caveat in P0-1).

**5. Fix the four assertions that cannot fail, before trusting any gate.** In priority order:
`LegalTests.swift:230` (compare against a list built independently of the two lists under test),
`TestKit.finish()` (assert a floor on test and check counts), the soak retention assertion (assert
a *size*, not a recomputed predicate), and the logo tests (bootstrap a world at a seed that is not
the manifest's). Until these are real, "green" carries no information about the things they cover.

**6. Wire the lanes that already exist.** `verify.sh` has working `app`, `soaks`, `calibration` and
`archive` lanes; CI invokes none of them. The `app` lane was run during this review and passes. This
is a few lines of YAML and it restores all iOS compile coverage, the soaks and the calibration
bands — three of which CLAUDE.md's completion gate names explicitly.

**7. Add one post-drive invariant check before touching any rule.** The rules reviewer's own
conclusion is that a single assertion — the situation is legal after every drive resolves: down in
1...4, distance consistent with the yard line, possession changed if and only if the ending says
so — would have caught **every one of the 24 rules findings**. Write that first, watch it go red,
then fix rules against it. Do not fix the overtime guard in isolation: fixing the vacuous
`allSatisfy` while possession is still hard-assigned to `.home` makes the game hang instead of
ending early.

**8. Then the gameplay bricks**, in whatever order suits: the postseason portal soft-lock, the
promotion that does not move the coach, the over-cap `advanceWeek` throw, dead money that is never
retired, the recruiting infinite hang, and the `SaveCoordinator` flush race.

---

## Reproducing the measurements in this report

```bash
# 163 MB of logo assets, and their dimensions
find Sources/ProFootballCoachUI/Resources -name '*.png' -exec ls -l {} + | awk '{s+=$5} END {print s" bytes, "NR" files"}'
sips -g pixelWidth -g pixelHeight "$(find Sources/ProFootballCoachUI/Resources -name '*.png' | head -1)"
```
```bash
# what `git add -A` would stage
git status --porcelain | grep '^??' | cut -c4- | xargs -I{} du -sh {} | sort -rh | head
```
```bash
# the three upstream fixes this branch does not contain
for c in 0e6953c fc2cb2c dfe3b76; do git merge-base --is-ancestor $c HEAD && echo "$c ancestor" || echo "$c NOT an ancestor of HEAD"; done
```
```bash
# suites that never run in the default (and therefore CI) path
grep -rhoE '^func run[A-Za-z0-9_]+\(' Tests/SimTests/Suites/*.swift | sed 's/^func //;s/(//' | sort -u > /tmp/defined.txt
awk '/^} else \{/{f=1;next} f' Tests/SimTests/main.swift | grep -oE 'run[A-Za-z0-9_]+\(' | sed 's/(//' | sort -u > /tmp/called.txt
comm -23 /tmp/defined.txt /tmp/called.txt
```
```bash
# the index and the working tree disagree
git diff --cached --stat; git diff --stat
git show :Sources/FootballSimCore/Integrity/WorldIntegrity.swift | sed -n '1449p'
sed -n '1449p' Sources/FootballSimCore/Integrity/WorldIntegrity.swift
```
```bash
# proof by grep, counted
grep -c '\.contains("' Tests/SimTests/Suites/ContractTests.swift    # 408
grep -c 'must be reachable' Tests/SimTests/Suites/ContractTests.swift  # 24
```
```bash
# the iOS lane works; nothing automated runs it
./scripts/verify.sh --lane app
```
The trade-dress reproduction script is included alongside this report as
`de-tradedress-check.py`; it re-implements `Colour.swift`'s CIE76/D65 maths and
`ColourGenerator.collidesWithTradeDress`'s predicate, then runs them over `manifest.json`.
---

## What was attacked and held

Recorded so the next reviewer does not repeat the work.

- **Determinism, engine-wide.** Every unsorted `.values` / `.keys` / `Set` iteration in the engine
  tree was traced and is currently safe — via `EntityStore.values` sorting by `uuidString`,
  order-independent accumulation, or sort-before-truncate. No unseeded RNG anywhere: no
  `Int.random`, `.shuffled()` or `.randomElement()` without an explicit generator. The concern is
  that none of this is *asserted*, not that it is wrong.
- **The deferred-acceptance portal matcher.** Every ordering path traced; no live cross-process
  break. Every comparator ends in a UUID tiebreak over distinct UUIDs, and the three remaining
  unsorted dictionary traversals are order-insensitive in effect.
- **Money is integer dollars** throughout the persisted graph.
- **No half-advanced world on a throw** — the scheduler mutates a value-type local. No step is
  silently skippable via early return. Append-time sequence and ID enforcement are real, and the
  archive size bounds are real.
- **Engine/UI separation** holds: zero `import SwiftUI` in `FootballSimCore`.
- **Orientation policy** is declared and asserted; `@MainActor` publishing is correct; launch
  double-generation does not occur.
- **The duplicate-roster crash path** was claimed and refuted: `WorldIntegrity.inspectPlayerIDs`
  (`:605-617`) does detect duplicates, and `CoachWorldStore.make(from:)` runs `CareerSession.init`
  — which throws on invalid — before building any read model.
- **The calibration harness does not silently drop unmeasured bands**;
  `CalibrationTests.swift:212` asserts `report.results.count == declared.count`.
- **`verify.sh --lane app` works** — xcodegen + `xcodebuild -destination generic/platform=iOS`,
  run during this review, "2 passed, 0 failed". The defect is that CI never calls it.
- **The documentation system holds.** All five `RETAINED` documents exist at their stated paths.
- **Postseason ties are properly forced to a winner**; `rankedRows` and `seasonAwards` comparators
  are total.
- **The trapping surface is smaller than expected and deliberately so.** Measured across
  `Sources/`: zero `fatalError`, zero `as!`, two `try!`. Both `try!` sites
  (`ScreenReadModels.swift:1892` and `:2217`) sit inside the `#if DEBUG` block spanning lines
  1803-2274, so neither reaches a release build. The remaining trap surface is 69 `precondition`
  calls, and Pattern 6 above is about how decoding routes around them — not about their number.
- **`CareerSession` specifically** contains no `await` inside any method, so actor reentrancy is
  structurally impossible *there*. That is the only concurrency claim in this report that survived
  — see the correction under "Concurrency" in P1 for the claim that did not.
- **No network, no dependencies.** `grep -rn "URLSession\|URLRequest\|NWConnection\|https\?://"
  Sources/` returns nothing; `Package.swift` has zero `.package(` declarations.
- **`[Attribute: Rating]` / `[UUID: …]` dictionary-key encoding order** is fully closed by
  `Support/CodingSupport.swift:10-40` plus the ContractTests key-type scan.
- **`SeedScope`'s eleven raw values are distinct**, with byte-based FNV-1a derivation.

---

## Saturation — where this review stopped, and why

Rounds ran until they stopped opening new ground, and the honest state differs by area.

**Exhausted.** Declared error cases — all 21 `Error` enums located by conformance grep rather than
a hand-list, all 167 cases checked, 165 thrown and 2 not; all 61 `IntegrityIssue` cases appended by
some check; all 20 `check*` sub-functions reachable; no dead `catch` anywhere. Also: persistence and
the save format; the legal guardrail; determinism; the scan harness;
Swift concurrency (all five `Task.detached` sites, all four store entry points and all 83 root
`Task {}` sites classified; all four `Sendable` sub-questions answered empty; one false lead closed
with a compiler probe); and copy-paste divergence (18 families chased, the remainder verified as
SwiftUI scaffolding carrying no behaviour).

**Substantially exhausted, with two named residuals.** The sixth round swept declared struct fields
and error cases: all 1,212 stored properties across all 247 structs in `Sources/FootballSimCore/`
were classified, and every `Error` enum checked for cases nothing throws. It reported its own limits
precisely, which is why they are repeated here rather than smoothed over:
1. A field whose name also exists on another type (`title`, `reason`, `plan`, `id`) can score a
   false read. One finding was caught only by hand-checking a sibling of an already-flagged field.
   Closing this properly needs type resolution — a compiler-backed pass, not grep. The cheap
   mitigation: for each of the ~40 structs with at least one confirmed-dead field, hand-verify the
   rest.
2. The presentation layer's own ~125 structs were used as readers but never swept as subjects.
   `ScreenReadModels.swift` alone is 1,800+ lines of declared model surface and is the obvious next
   target.

**Still open.** The enum-case sweep covered roughly 60 of about 200 named enums. `IntegrityIssue`'s
~50 associated-value cases, the save-store vocabulary, and the `SnapAnchors`/`SnapOutcome` broadcast
vocabulary were not reached.

**One question left open for the owner rather than reported as a finding:** whether bounded
overtime can end level. `CalibrationBands.swift:79` lists the tie rate as unmeasured.

The practical reading: the review is complete enough to act on, and a further pass on the two named
modalities would likely find more dead features. That is a statement about how much dead
vocabulary this codebase carries, not about the review being unfinished.

## Appendix — finding index

| Area | Reviewer | Findings | ID prefix |
|---|---|---|---|
| Legal guardrail and generation | subagent | 13 (4 CRITICAL) | `L-` |
| Determinism and match engine | subagent | 16 (5 CRITICAL) | `D` |
| Persistence and save | subagent | 17 (5 CRITICAL) | `P-` |
| UI and app layer | subagent | 20 (3 CRITICAL) | `UI-` |
| Team-logo feature | subagent | 20 (4 CRITICAL) | `S`/`N`/`A` |
| College portal subsystem | subagent | 11 (3 CRITICAL) | `CG-` |
| Career and pro systems | subagent | 18 (5 CRITICAL) | `CR-` |
| Scheduler and integrity | subagent | 15 (3 CRITICAL) | `SC-` |
| Test-suite coverage boundaries | subagent | 35 (6 CRITICAL) | `TS-` |
| Harness, CI, build claims | main thread | 10 | `H-` |
| Uncommitted compaction diff | main thread | 7 | `C-` |
| Contract-test methodology | main thread | 3 | `T-` |
| Branch and delivery state | main thread | 5 | `B-` |
| Upstream divergence | main thread | 1 | `X-` |
| Logo/seed coupling | main thread | 5 | `S-` |
| Repository hygiene | main thread | 2 | `R-` |
| PRODUCT.md claims | main thread | 4 | `CL-` |
| Football-rules correctness | subagent | 24 (7 CRITICAL, 11 measured) | `RU-` |
| Competition and history | subagent | 28 (3 CRITICAL, many measured) | `CO-` |
| Model, tactical, intent | subagent | 18 (4 CRITICAL) | `MD-` |
| Completeness critic | subagent | 12 (3 CRITICAL) + coverage map | `CP-` |
| Declared vocabulary sweep | subagent | 28 (12 CRITICAL) | `VO-` |
| Concurrency and divergence | subagent | 36 (4 CRITICAL) | `CD-` |
| Fields and error cases | subagent | 25 (7 CRITICAL) | `FE-` |
| Uncommitted compaction diff (probes + release A/B) | subagent | 14 (4 CRITICAL) | `F` |
| Independent verification pass | main thread | 26 | `V-` |

Every high-severity subagent finding quoted in P0 and P1 carries a matching `V-` entry recording
the independent re-derivation, including the one that was refuted and the one that was reproduced
from scratch.
