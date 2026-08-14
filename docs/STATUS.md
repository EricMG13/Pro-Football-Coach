# Build Status

The honest picture: what exists, what is verified, what is not.

**Read this first, before believing any other document about the state of the build.**

> **UI direction correction — owner decision 2026-08-11:** the v2 sheets, Stitch output and
> 34-screen Film Room gallery described in older dated entries below are rejected and removed.
> They are historical build notes, not references. The only current UI authority is
> `docs/04-UX-AND-DESIGN-SYSTEM.md`: **The Coach's World**, 62 screen families, no universal
> application chassis, and Film Room limited to scouting, tactics and replay.

**Platform baseline — owner decision 2026-08-11:** iOS 26+, iPhone-only and landscape-only, with
release support and performance evidence on iPhone 15-generation hardware and newer. The supported
layout floor remains 844 × 390 because later compact `e` models are smaller than the base iPhone 15.
Pre-iPhone-15 devices are outside the compatibility promise even when iOS 26 allows installation.

---

## Where the project actually is

> **2026-08-10 master-plan rebaseline:** the attached Master Build Documentation is now the primary
> product and technical authority. Its Milestone 0 architecture hardening is implemented. The
> previous P0–P4 work below remains an accurate account of the preserved deterministic foundation,
> but the old instruction to tune P4 next is superseded until `GameState`, `WorldScheduler`, the
> domain-event ledger, read-model/intent contracts, and whole-root integrity are established. The
> completed implementation record is `docs/plans/2026-08-10-m0-architecture-hardening.md`.
>
> Measured baseline for this rebaseline: `swift build` passed and `SimTests` passed with **263 tests,
> 78,296 checks**. No M0 production code existed at that measurement.

### M0 — architecture hardening — **implemented and green**

Built backend-first from the master plan:

- one normalized, versioned `GameState` root with deterministic entity stores;
- the exact 15-step `WorldScheduler`, with unavailable systems visibly marked inactive;
- typed domain events, bounded hot history, stable scheduler identities, and archive accounting;
- explicit `CoachIntent` resolution and immutable `WeekSnapshot`/`IntentResult` projections;
- whole-root integrity for topology, ownership, staff employment, roster limits, calendar, and
  history, enforced again when a save root decodes;
- hostile-save guards for entity-key mismatches, invalid calendar/version data, and malformed
  history ledgers;
- a source gate preventing the SwiftUI target from owning or reading `GameState`.

Verified on 2026-08-10 with `./scripts/verify.sh`: **289 tests, 78,530 checks, all passed**. Root and
one-week transition fingerprints are pinned as source literals, so cross-process changes are
visible. Existing generation and match-engine pins remain green.

The adversarial M0 review found four confirmed corruption/truthfulness issues; all were fixed and
regression-tested. At the owner's direction, the repository-wide rewrite tournament and confidence
review are deferred until the complete product's final verification rather than repeated at each
milestone.

At the M0 close, event references, schedule/standings, and positional coverage were truthfully
inactive. M1 has now activated those checks. Eligibility transitions, contracts, observer
knowledge, tactical-role eligibility, and salary-cap checks remain inactive until their named
systems exist; the live boundary is tracked in `docs/FUTURE-SIMULATION-CONTRACT.md`.

### M1 — playable world — **implemented and green**

The base competition world now runs at target scale:

- deterministic 134-programme college and 32-team professional schedules, with exact game/bye
  counts and bounded bye distribution;
- 15,766 deterministically generated players, legal roster ownership, tier-specific ages and
  eligibility, sparse position ratings, and minimum playable position coverage;
- rules-owned abstract outcomes, player/team statistics, regular-season standings with two-team
  head-to-head and conference-record tiebreaks, rankings, awards, and contextual record primitives;
- ten college conference championships, eight-team college and professional brackets, earned
  round advancement, champions, compact archives, and deterministic rollover schedules;
- typed game/postseason/season events and active integrity for results, event references,
  projections, brackets, archives, record context, ownership, and positional coverage.

Verified on 2026-08-10 with `./scripts/verify.sh`: **312 tests, 225,499 checks, all passed**. The
post-review release soak completed **20 seasons / 420 weeks / 22,000 games** in **266.816595875
seconds** (about 0.64 seconds/week) with no integrity drift. Save/load checkpoints were **9,615,246
bytes** at season 1, **10,591,838 bytes** at season 5, and **10,710,674 bytes** at season 20.

The detailed user match remains the preserved P3 engine rather than being integrated into the
career loop, and its P4 numerical calibration gate remains open. M1 does not claim people aging,
development, injuries, recruiting, contracts/cap, staff/career movement, AI/delegation, cold event
storage, or production UI; those begin with M2 and later milestones. Full implementation and review
details are in `docs/plans/2026-08-10-m1-playable-world.md`.

### M2 — people lifecycle — **implemented and green**

The authoritative world now carries people credibly across seasons:

- normalized active health/development state, compact departed-player identities, and bounded
  player/staff career records;
- deterministic recovery, fatigue from recorded workload, injury probability driven by fatigue and
  durability, real availability/fatigue effects on abstract results, and structured events;
- twice-seasonal causal development from age/decline, practice, playing time, position coaching,
  scheme fit, and work ethic, with one-point changes and a potential ceiling;
- college eligibility advancement and graduation, professional age/position retirement, compact
  career lines, and deterministic same-position replacement intake;
- 2,158 employed staff with complete role coverage, ratings/preferences, aging, continuity,
  careers, and deterministic vacancy resolution;
- active whole-root checks for people state, eligibility transitions, staff coverage, historical
  references, roster legality, and hostile persisted subrecord bounds.

Verified on 2026-08-11 with `./scripts/verify.sh`: debug and release builds passed, followed by
**330 tests / 710,609 checks, all passed**. The final target-scale soak completed **20 seasons / 420
weeks** in **677.408770083 seconds** with **326 checks, all passed**. It retained stable roster and
staff counts, legal ages/eligibility, bounded injury incidence, development explanations, plausible
broad rating bands, whole-root integrity, and save/load equality.

Measured uncompressed save checkpoints were **22,119,600 bytes** after season 1, **35,262,057
bytes** after season 5, and **84,659,139 bytes** after season 20. That does not meet the old 8 MB
production ceiling. The snapshot remains honest and deterministic, but compression, a cold event
archive, and chunked/streaming persistence remain required work under FSC-002/FSC-003 and M9.

The milestone adversarial review found that synthesized decoding bypassed bounds on nested career,
development, assignment, and departed-identity records; those corruption paths and impossible
active ages were fixed and regression-tested. It also confirmed two deliberate dependency bridges:
M2 replacement intake is not recruiting or the pro draft, and full historical archive storage is
not implemented. Both are registered below rather than represented as finished systems.

M3 college management is now active. Its current implementation record is
`docs/plans/2026-08-11-m3-college-management.md`; the completed M2 record remains
`docs/plans/2026-08-10-m2-people-lifecycle.md`.

### M3 — college management — **complete**

The authoritative world now has deterministic annual prospect pools, observer-specific scouting,
shared user/AI recruiting actions, visits, offers, NIL promises, competing commitments, signing,
exact scholarship ownership, explicit walk-on intake, and annual recruiting-cycle renewal.

Commitments are now projected capacity reservations rather than promises the roster may silently
discard. Deterministic global races preserve winner, runner-up, fallback, flip, NIL, visit, and
score context; signing resolves every commitment exactly once as signed or explicitly released,
and durable recruiting origins survive event eviction and player departure. AI boards ramp to a
class-sized 40-player ceiling, losing pursuits refund NIL exactly, full classes stop spending, and
each programme can stage five evaluation/offer/NIL pipelines per week under the shared action rules.

The annual transition preserves signed-player UUIDs and career recruiting origin while compact
former-prospect identities exist only as long as retained recent events need them. Recorded game
results now also carry canonical home/away participant manifests, so appearances are authoritative
for statless linemen, defenders, specialists, and reserves rather than inferred from production.

Save schema 5 now combines one authoritative seasonal NIL ledger per programme with persisted,
usage-aware redshirt plans and strict eligibility clocks. Roster allocations,
recruiting reservations, and future portal reservations share one conserved budget; remaining money
is derived rather than stored twice. Signing reclassifies an existing promise, withdrawals refund
it, departures remove it, and rollover carries only allocations for retained roster identities.
Strict decoding and whole-root integrity reject category overlap, orphan reservations, incorrect
programme/season/budget ownership, and overcommitment. A redshirt designation now controls actual
game participation, records a typed resolution before lifecycle departure, and preserves a season
only at four or fewer appearances. Hostile saves cannot erase live plans or persist impossible
eligibility/career chronology. Focused gates passed for college state (**39 tests / 4,102 checks**),
commitments (**25 / 124**), and redshirts (**33 / 104**), and the release core build succeeded.

On 2026-08-11 the settled schema-5 release suite passed with **454 tests / 715,092 checks** and zero
failures in **498.33 seconds**. Focused gates also passed for commitments (**25 / 124**), college
state (**39 / 4,102**), redshirts (**33 / 104**), event-ledger batching (**12 / 56**), and
architecture/determinism (**25 / 222**). Both root fingerprints were identical across two rebuilt
runs before their pins were updated. Runtime remains an explicit production target rather than an
unverified claim.

The first target-world recruiting calibration exposed a real Task 4 failure rather than
blessing legal rosters as plausible classes: median scholarship class was **2** against a median
projected target of **21**, with **902** signed recruits and **2,576** walk-ons. Two identical
one-season runs took **102.109 s / 105.813 s**, produced byte-identical roots, passed save/load and
integrity, and left all 134 rosters legal. That result is retained as the pre-correction baseline,
not the behavior of the current capacity-aware/NIL-causal policy. The replacement gate now passes
without relaxed bounds: **2,177** scholarship signings versus **1,301** walk-ons, **78%** aggregate
fill, **94%** median fill, and nonempty classes at all 134 programmes. Two identical runs took
**76.213 s / 81.268 s**, round-tripped exactly, passed integrity/history/save limits, and left every
roster position-covered and legal. An immutable shared fit snapshot removed the diagnostic's
whole-world rebuild per board entry; a final-week terminal market now converts legal last-week AI
work before signing; and AI deepens its strongest renewable relationship work instead of visiting
an entire board before following up. The current calibration save is **28,420,806 bytes** with
**73,865** total events, **4,096** retained hot and **69,769** archived.

Schema 6 now has the persistence foundation for two atomic portal windows. `CollegeState` requires
a season-bound stable portal state; transient open transactions cannot be encoded as valid saves.
Versioned records retain intent, permitted knowledge, separate player-preference and destination-
admission explanations, fixed capacity, offers, retention, outcomes, and summaries. Programme NIL
supports atomic roster updates and exact expected-amount portal-to-roster reclassification, while
player careers retain at most two windows across a five-season eligibility span with exact usage,
source, scholarship, NIL, tenure, transfer, and career-end continuity. Focused schema-6 gates pass
for portal contracts (**27 tests / 134 checks**), college state (**39 / 4,102**), people lifecycle
(**18 / 485,115**), commitments (**25 / 124**), and release core contracts (**140 / 777**).

The first schema-6 policy boundary is also active. A sealed, non-persisted window snapshot derives
authoritative intents, private-truth-limited observations, and retention decisions from one exact
season/window root; callers cannot substitute free-form explanations or mix windows. Portal-player
knowledge is deterministic, observer-scoped, immutable once recorded, canonically batch-written,
and bounded to the 134-programme world. Retention spends the smallest exact NIL amount in usage
priority order or releases the player without mutating the source ledger. The mechanically active
`restless` trait is populated deterministically at eight percent across every player-generation
route and changes portal intent by exactly ten points; signing preserves it. The seven trait names
without authoritative consumers remain deliberately unpopulated under FSC-014. Focused gates pass
for portal policy (**12 tests / 715 checks**) and trait population (**7 / 570**), with the existing
portal-contract, college-state, commitment, and release-core compatibility gates still green.

Portal destination matching is now a sealed pure transaction over that authority snapshot. It
captures post-retention roster, scholarship, and NIL capacity before any departure; schools form
bounded admission-ranked willingness sets, players form five-destination preference shortlists,
and equal per-school terms are derived from one fixed ledger snapshot. Entrant-proposing deferred
acceptance uses separate school-admission and player-preference orderings. Outbound players do not
create same-window capacity, losing NIL reservations refund exactly, accepted reservations alone
survive in the transient result, and a player cannot transfer twice in one target season. Saved V1
offer evidence now locally rederives all eight preference components, admission components, exact
equal NIL terms, and frozen calendar/collection bounds without consulting later balance rules.
Focused matching passed **15 tests / 108 checks**; portal contracts passed **27 / 137**, portal
policy **12 / 715**, college state **39 / 4,102**, and release core contracts **140 / 783**.

Portal matching results now commit as one sealed, all-or-nothing transaction. The commit preserves
player identity and career evidence while moving roster and scholarship ownership, reclassifying
the exact accepted NIL promise (including a truthful zero-dollar absence), refunding every losing
promise, appending durable career windows, and publishing one deterministic typed-event batch.
Whole-root integrity rederives current and rotated window summaries, ownership, scholarship, NIL,
career, capacity, knowledge, and retained event facts from durable records; its indexed hot-history
checks avoid per-observation career rescans. Portal admission also persists the programme's exact
minimum-position deficits and reserves enough remaining openings to repair them; an off-position
transfer can no longer consume the last coverage slot or create a 106-player roster.

The two-window cycle is now in the fixed scheduler. Final-week rollover resolves the terminal
recruiting market, career usage/redshirts/departures, season archive and next schedule, signing and
NIL renewal, the postseason portal, then minimum-only coverage walk-ons before persisting week 1 as
`awaitingSpring`. Week 1 resolves spring before scouting, recruiting, AI, or games, fills the final
roster with a distinct collision-free walk-on namespace, and closes the portal. The shared
recruiting action authority itself rejects work during the spring pause. A two-copy second-season
replay produced byte-identical roots and events with valid integrity: **363** portal-window records,
**62 retained**, **210 transferred**, and **91 returned**. Focused gates pass for scheduler
**9 tests / 27,813 checks**, transaction **16 / 118**, matching **16 / 116**, contracts **28 / 138**,
policy **12 / 715**, college state **39 / 4,102**, and release core contracts **140 / 786**.

The M3 management boundary is now active under schema 7. A persisted controlled college job owns
explicit user/delegated responsibilities; scheduled AI cannot also act for it, and delegation uses
the same recruiting policy and legality as every other programme. Typed mandatory decisions retain
subjects, deadlines, stable option IDs, recommendations, causal reasons, owners, and durable
resolutions. The actor-owned `CareerSession` derives programme authority internally, commits without
a reentrant suspension, checks cancellation before mutation, and returns immutable fog-of-war
projections rather than `GameState`. The app-target source gate continues to reject direct
`GameState` or `IntentResolver` access. Complete strict-concurrency diagnostics emitted no warnings,
actor-race instrumentation passed, the focused career gate is **11 tests / 77 checks**, and two
rebuilt architecture runs are **25 / 222** with identical schema-7 fingerprints.

Task 7 is now closed. The target-scale soak completed **20 seasons / 421 weeks** with **1 test /
8,307 checks**, all passing, including deterministic save checkpoints through season 20, bounded
portal/redshirt history, legal ages and ratings, class sizes **3–25** (median **14**), and valid
integrity after every checkpoint. Final release compatibility is **558 tests / 746,742 checks**,
all passing; the schema-7 architecture fingerprints match across two rebuilt runs. College
provisional replacement intake has been removed; the professional bridge remains intentionally
active until M6.

### M4 — tactical management — **active**

Schema 8 tactical state (carried by the current schema-10 root) carries calendar-bound tactical state
in the authoritative root. Immutable plans,
practice allocations, opponent snapshots, and bounded game-plan reviews survive save/load; the
fixed scheduler consumes explicit plans before games and records reviews after results. Practice
spends exactly 60 minutes across install, conditioning, recovery, and a position focus, and the
existing development path consumes that allocation. `CoachIntent` owns game-plan and practice-plan
writes, while `TacticalCallInSystem` produces deterministic, inspectable proposals with at most
three options and a named risk.

Focused tactical coverage is **6 tests / 67 checks**, tactical-state/intent coverage is **5 / 16**,
competition compatibility is **32 / 6,315**, and core contracts are **144 / 875**; all passed.
Strict Swift-5 concurrency diagnostics are clean. Architecture fingerprints are **25 /
222** in two rebuilt runs (the current schema-10 root includes the M5 field). Detailed-game call-in choices still need to be threaded through the live
match session and controlled career actor; no production UI or simulator evidence is claimed yet.

### M5 — career stakes — **active**

Schema 9 adds a persistent `CareerArcState` beside controlled-college authority. It records the
current job, bounded job history, four stakeholder support levels, deterministic professional
opportunities, and fired/seeking/employed status. Weekly completed results move stakeholder support
against a prestige-based expectation; support can end the job in-season, while the season-end
evaluation can create a professional opportunity after sustained success. Root integrity binds every
job, history entry, and opportunity to real organisations and calendar chronology, and the custom
encoding keeps save bytes deterministic across processes.

The scheduler now evaluates weekly stakes after statistics and evaluates the season-end arc before
the schedule is replaced. Focused career-arc coverage is **8 tests / 35 checks**, controlled-career
coverage remains **11 / 77**, strict-concurrency FootballSimCore is clean, core contracts are
**144 / 875**, and two rebuilt architecture runs are **25 / 222**. Professional offer acceptance
and resignation are available through the engine intent boundary; coaching-carousel transitions
and inbox events remain open.

### M6 — professional management — **active**

The cap-safe `ProManagementSystem` remains the ownership and money boundary. Schema 10 now adds a
bounded `ProMarketState` for deterministic offseason opening, free agency, draft class/scouting
fog, pick consumption, rookie contracts, and roster-build closure. `CoachIntent.proMarket` is
guarded by the promoted professional job and emits typed market events; college-controlled roots
cannot submit it. Final-week rollover closes the prior market before postseason projection and opens
the next market after college portal/cycle work.

Focused market coverage is **12 tests / 58 checks**. Portal scheduler compatibility is **9 / 27,823**
with two-season byte-identical replay and valid integrity; portal contracts are **28 / 138**.
Core contracts are **144 / 880**, and strict Swift-5 concurrency diagnostics remain clean. Practice-
squad movement, trades, waiver claims, expired-waiver release, sourced contract expiry, and
deterministic professional roster AI now use copied-root validation and typed events; the full
both-tier soak and professional actor/UI remain open. Architecture is **25 / 222** in two identical
rebuilt runs after the waiver schema update.

### M7 — living world/history — **active**

The first M7 slice adds `WorldHistoryReadModel`, a disposable deterministic projection that indexes
current programmes, pro teams, players, staff, departed identities, rivalries, season archives,
awards, record-book entries, and retained typed events. Search is tokenized, case/diacritic-insensitive,
bounded, and never exposes `GameState`; the index is rebuilt after load rather than persisted as a
second authority. Rivalry meetings now strengthen the stored intensity once, in the existing
relationships step, with bounded notable-meeting history. Focused coverage is **4 tests / 24 checks**,
portal-scheduler compatibility is **9 / 27,823**, and core contracts are **144 / 883**. Cold event
bodies, generated news, semantic rivalry narratives, coaching-tree projections, and the 30-season
history/performance gate remain open.

**M7A closed 2026-08-12: rival lists live, and the coaching tree exists.** Rival lists were seeded
once from geography and conference and never touched again, so a rivalry could become the most
intense in the world while still sitting last in the list that names it. The relationships step now
reinstalls the order its own intensity implies, through `RivalrySeeder.strongest` — the same ranking
that seeded the list, so seeding and maintenance cannot disagree. Only the sides of a rivalry that
actually moved are reordered, so the weekly cost is proportional to the week rather than to all 134
programmes. `CoachingTreeReadModel` derives who a head coach came up under, and who came up under
them, from the bounded staff career records M2 already keeps; it is rebuilt after load rather than
persisted, because a second copy of those facts would be a second authority.

Measured: rivalry order **7 tests / 11 checks**, coaching tree **11 / 25**, core contracts
**146 / 953**, architecture **25 / 222**, portal-scheduler two-season replay **9 / 27,823**, and the
full `./scripts/verify.sh` at **620 tests / 747,066 checks, all passed**.

The pinned one-week transition fingerprint moved, deliberately, and is documented at the literal.
The root pin did not, which is the evidence that generation is unchanged and only the step differs;
the new value was confirmed identical across two separate processes.

Two things the gates did not catch, recorded because they are the useful part. `ContractTests`
rejected the coaching tree's first seat index on the first run — every dictionary key type in the
engine must be `CodingKeyRepresentable` so a map can never encode in hash order — and the
confidence review found that a fired head coach taking a coordinator job was being made their new
boss's disciple, inverting the relationship. A disciple's first head-coaching season must postdate
the seat they shared.

Still open in M7: cold event bodies, generated news, cross-season semantic rivalry narratives, and
the 30-season history/performance gate. The plan for the next slice is
`docs/superpowers/plans/2026-08-12-m7a-living-rivalry-and-coaching-tree.md`, whose closing section
records why cold event bodies are their own milestone: they change a persisted root type and need a
bound design against FSC-002/FSC-003 and the save-size budget, which is still 84.66 MB at season 20.

### 2026-08-13 — the road to beta: B-1 answered, D-1 attributed and fixed, G-01 and U-4 landed

Executed against `docs/plans/2026-08-12-road-to-beta.md`. **This session had a full Swift and Xcode
toolchain** — Xcode 26.6, Swift 6.3.3, `xcodegen`, iPhone 17 simulators — which is the first time
any session in this rebuild has, and it changes what could be settled rather than described.

**B-1 — there is an app, and it builds. Answered, and it was the plan's single largest unknown.**
`xcodegen generate` in `App/` followed by `xcodebuild … -destination 'platform=iOS
Simulator,name=iPhone 17'` produced `** BUILD SUCCEEDED **` in both Debug and Release, and
`-destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO` builds the arm64 device slice too. The
Release `.app` was installed and launched on the iPhone 17 simulator and photographed. Signing is
the only thing left between this and a phone, and signing is B-2, which is the owner's.

*The simulator run is reported as what it is.* `CLAUDE.md`'s rule is that an agent must never claim
a demonstration happened; it was written when no session had a toolchain, and its purpose is to stop
fabricated claims. This session ran the app for real and reports only what the screenshots show.
**Nothing has run on a phone**, and no part of §4 of `docs/OWNER-WALKTHROUGH.md` has been done.

**V-1 — the full suite was run, and it was red in five places.** `PortalTransactionTests`'s fixture
aborted the process at season 0 week 21 with `professionalMarketFailed(.invalidRoot)`. The log was
two lines: the fatal error and the exit code. **The harness reported only at `finish()`**, so an
aborted run gave no account of the suites that had already passed or of where it had got to.
`TestKit.suite` now prints a line per suite and `main.swift` unbuffers stdout; the very next run
used that to name the abort site immediately.

**All five failures predate this session, and that was verified rather than assumed** — `a4a1ca1`
was checked out into a detached worktree, built, and the suites run there. Every one is a
consequence of `0deb629` giving a generated world contracts to expire, and every one was invisible
because the run died before reporting. The plan's "the full suite has not been run since `0deb629`"
was therefore load-bearing, not housekeeping.

| Suite | What it was | Why |
|---|---|---|
| Season-boundary people lifecycle | 33 checks | Asserted every player is on a roster and every professional roster is exactly 53. Beat 1 (`02` §4.2a) *is* players leaving a roster at the season boundary without leaving the world |
| College management state | 2 checks | Helper jumps the calendar to a later season without the scheduler; contracts stayed behind and 32 teams carried deals that had ended |
| College commitment integrity | 1 check | Same helper class |
| College redshirt rollover | 2 checks | Same helper class |
| M6 professional market | process abort | `removeProRosterPlayer` left the contract attached, so `openOffseason` built an empty free-agent pool and the AI signed nobody; the test then indexed `signedPlayerIDs[0]` after a soft `expect` and trapped, taking every later suite with it |

The three college helpers now roll contracts with the calendar through one shared
`professionalContractsRolled` (`Tests/SimTests/TestRoots.swift`) rather than three copies. The
people-lifecycle assertions are replaced by stronger ones — no player exists whom no roster and no
market accounts for, free agency is non-empty after a boundary, and every professional team still
has a playable body at every position, which is the invariant the expiry exemption exists to
protect. The crash became a `require`.

**D-1 — attributed, and it was never a portal defect.** The register asked for the attribution to be
re-run before anything was fixed, and it was, with `--pro-market-root-probe`. The finding:

1. The expiry abort *masked* D-1. Contract expiry ran earlier in the same step and threw first.
2. Neither defect was the cap fork O-1 anticipated. **No professional team was ever over the cap** —
   the probe separates the two ways a team fails the cap invariant and reports zero over-cap teams
   against eleven with run-out contract terms.
3. One ordering mistake caused both. `expireContracts` ran at the top of `jobAndStaffMarkets`:
   before `SeasonLifecycleSystem.advance` writes the career records FSC-013 needs to legalise a
   departure; before two wholesale `nextState.players` assignments that discarded its writes; and
   after nothing, when the college portal's commit — which checks the root *projected into the next
   season* — needed last season's deals already off the books.
4. The "last body at a position" exemption kept an expired contract attached. The cap invariant
   reads a contract as valid only while the season is inside its term, so eleven of thirty-two teams
   were permanently illegal in the projected season. `02` §4.2a now states that the club **re-signs**
   the player instead — one year, last base salary, no bonus.

Fixed in `fce9e2a`, with `--season-rollover` pinning the invariants rather than the seed that caught
them. `--pro-market-root-probe` is retained: the register recorded that the previous attribution
probe was destroyed during cleanup before it could answer, and this one is not to be deleted.

**G-01 — the shipped build shows the world.** `Sources/CoachWorldApp` is a new composition target,
and it exists because neither existing target could do this alone: the engine may not import the UI,
and the UI target may not name `GameState`. It holds `CoachWorldReadModelProvider` (root →
`CoachingHQReadModel`, provenance `.simulationSnapshot`), `CoachWorldStore` (the career, advanced
off the main actor through `CareerSession`), `CoachWorldSaveStore` (one save, written atomically)
and `CoachWorldAppRootView` (the shipped root). `App/ProFootballCoachApp.swift` launches into it.

Measured on the simulator, from the fixed new-career seed: programme *Marrow Hollow Normal*, coach
*Kelay Tarrford*, Season 1 Week 1, 0–0, #122, opponent *Calder Mining* at *Marrow Hollow Grounds*,
and a real queued decision carrying the engine's own reason codes as its evidence line.

**Three regions on that screen are blank by construction, and `--screen-read-models` asserts each
one.** The week strip has no days because the calendar's finest grain is a week (G-14); Your Desk
carries no correspondence because no inbox system exists (the scheduler's `expiringInboundEvents`
step is inactive to say so); no staff recommendation appears because G-02 is unbuilt and three of
its four fields would have to be invented. Filling one now requires deleting an assertion that names
the register item which would justify it.

**Coaching HQ, Roster and Player Profile are truthful; Match Day and Recruiting Board are not.** The
personnel pair needed something the model did not have — a jersey number — and **G-16 closed the
same day, as a derivation rather than the schema change first assumed**. Uniqueness belongs to a
team and a player changes teams, so a stored field would have needed reassignment on every transfer,
draft pick, signing and walk-on; derived over a roster it holds by construction, with no schema bump
and no fingerprint re-pin. `02` §4.1a states the rule and `--jersey-numbers` asserts it.

*Two things that rule got wrong first, both caught by tests rather than by reading:* uniqueness
cannot be roster-wide, because a 105-man college roster does not fit in 100 numbers — it is per
**unit**, which is also the real rule; and the bands were first sized from memory of real football,
which put eighteen defensive linemen into ten numbers and spilled a tackle to `#0` on the first
screen anyone opened. The bands are now sized against `CollegeRules.initialRosterByPosition`, and a
test asserts that rather than the arithmetic.

The remaining personnel blanks are named in the provider beside the field: no hometown (the root
records a *prospect's* origin city, not a rostered player's), no staff summary (G-02), and no recent
form (G-04). Match Day still needs G-06 and G-11.

**Recruiting Board is truthful too, added 2026-08-13.** `Capacity.weeklyHoursRemaining` is
`ProgrammeRecruitingState.contactPointsRemaining` — a real, weekly-reset resource
(`CollegeRules.weeklyRecruitingContactPoints`, 100) that `contact` and `evaluate` spend directly.
`officialVisitsRemaining` is derived from the same pool divided by `CollegeRules.visitContactCost`
(30), since the engine has one pooled resource rather than a separate visit counter. Confirmed live
on the simulator: `HOURS 100h` and `VISITS 3` at week one, beside a real `SLOTS` count. Everything
else on the board is likewise real — its own rank order, position needs, and each prospect's
evaluation via `RecruitingFitSystem`, the same arithmetic the AI itself reads.

*This section briefly said the opposite.* A search for the budget by name ("weekly hours",
"contact budget") missed `contactPointsRemaining`, and for part of this session the two fields
shipped as `Int?` under a "G-18: not built" note that asserted a gap the engine had already closed.
Corrected the same day, once a closer read of `CollegeState.swift` found it — see `02` §4.3.

A fresh week-one board is empty by design (the AI cycle populates it later), and the screen shows
an honest empty state — "No prospects on the board" — rather than a table implying data that isn't
there yet.

**Navigation is honest too.** The app root routes Office, Team and Recruit; every other tab reports
"<family> is not available yet" rather than presenting an empty screen, which would claim the
family exists.

**Continue meant two different things depending on which screen you were on, until wiring Roster
and Recruiting Board caught it.** Every screen carries the same "Continue" control — same icon, same
label, same position in the world strip — and on Coaching HQ it advances the week. Roster's and
Recruiting Board's copies of that control were wired to just navigate back to Office instead, so the
identical-looking button did something different depending on where you tapped it. Both now call
the same `advance(store)` path Coaching HQ uses, so the refusal a pending decision produces is the
same refusal everywhere, not a screen-dependent behaviour.

**P-2's AI-facing half is built, 2026-08-13 — `ProManagementSystem.enforceCapCompliance`.** Went
through its own `writing-plans`/`executing-plans` phase per `CLAUDE.md`'s process, rather than a
freehand continuation, because it is real unbuilt engine work: `docs/superpowers/plans/2026-08-13-
cap-compliance.md` has the full plan and its self-review. Every professional team but the one the
player controls is released — cheapest dead money first — down to cap-legal at the week-21 boundary,
inside the same `advanceWeek` transition that already runs beat 1's expiry. `WorldIntegrity.check
ProfessionalCap` was never touched; the function mutates state directly and validates once at the
end with the same difference-based guard `expireContracts` established this session, so it is never
the invariant itself that gets weaker, only what runs before it.

Five unit tests (event plumbing, ordering, already-legal, unfixable, controlled-team-skipped) plus
one integration test through a real `advanceWeek` all pass, and the architecture fingerprint pins
are unchanged —
confirming the function is a true no-op under normal bootstrap generation, which is also its honest
limit: no current signing path can ever put a team over the cap, so nothing in ordinary play reaches
this code yet. The controlled team's own cap choice is deliberately not built here — every other
consequential choice in this game is a mandatory decision the player makes, and automating the
player's own releases the way the AI's are forced would break that pattern. `02` §4.2a has the full
account, including what remains open.

**U-4 — the AX5 instrument exists, and its limits are written down.** `--design-contracts` now
enumerates all 62 families from `CoachWorldScreenID`, resolves each to its view file by convention,
asserts the landed/pending partition is total, and requires every landed family to declare an
accessibility-size composition and deterministic VoiceOver order. `04` §7.1 states plainly what it
does **not** assert: *no datum lost* and *no clipping* are properties of a render, and this harness
has no view host. **The rendered limb of G-12 stays open** and its mechanism is `03b` §5's to decide
— now a live question, because full Xcode is present and XCTest is therefore reachable in a way it
was not when `03b` was written. An audit may not score AX5 above 3 on this suite alone.

**Three scans had become directory rules rather than rules.** The GameState boundary scan, the
design-token-literal scan and the SF-Symbol register scan all read `Sources/ProFootballCoachUI`
literally. Adding a second target containing a view would have escaped all three on the day it was
created. They now enumerate "code that draws" by the UI import. Separately, the no-argument suite —
the one `verify.sh` runs and every release claim quotes — **never included `DesignContractTests` at
all**, so the orientation policy, token sync, symbol register and sheet lint were only ever checked
under an explicit flag. Both are fixed.

**V-1 is now green: `719 tests, 755,310 checks, all passed`**, release build, exit 0, run on
2026-08-13 after the repairs above. That is the first full-suite green since `0deb629`, and it
includes `DesignContractTests` and the AX5 contract for the first time in a no-argument run.

**B-4 — D4's week-advance budget is already blown, on a development Mac.** `--week-advance-timing`
measured, twice within 1%: bootstrap **0.15 s**, twenty-one weeks in **95.7 s**, **median 2.83 s per
week**, **worst 29.6 s** (the season-boundary week), and **one whole-root integrity check 1.01 s**.
D4 budgets **2.0 s**.

Three things follow, and the first is the one that matters:

1. **The median week is 40% over the budget before a phone is involved.** D4's falsifier does not
   need a device to fire. About a second of every week is `saveGrowthAndIntegrity` running
   `WorldIntegrity.check` over 15,766 players — the budget cannot be met while a full-root check is
   an every-week cost, so this is a structural question for `03b` §5 and D4, not tuning.
2. **The season-boundary week is 29.6 s.** Expiry, the college cycle, the portal, realignment and
   the draft class all land in one `advanceWeek`. On a phone this is a minute or more with a
   spinner, which is why `CoachWorldStore` advances off the main actor — but "responsive while
   unusable" is not the same as playable.
3. **Roughly 2 s of that 29.6 s is a cost this session added**, and it is named rather than hidden:
   `expireContracts` now takes the difference between the root's issues before and after, which is
   two whole-root checks instead of one. It buys the only week-ordering that satisfies FSC-013 and
   the cap invariant at once; if the check gets cheaper, this gets cheaper with it.

**What this session did not do.** U-6 (production views for the other 57 families) is untouched and
is the largest remaining item. B-2 and any device measurement are the owner's. P-2 (cap-compliance
cuts) is not built — and the probe's finding that no team is over the cap at the season boundary is
worth carrying into it, because beat 2 has nothing to do until spending puts a team over.

### The full default suite — **green on 2026-08-12, after a two-failure fix**

`./scripts/verify.sh` now passes: **602 tests / 747,027 checks, all passed**, debug build and
release suite. This is the first full-suite green recorded on this branch, and it took a fix.

The run before it was red with two failures, both reproducible at clean `HEAD` (70a60ed) in a
detached worktree, so neither came from the personnel UI slice:

- `College management state / two renewals retain exactly the former prospects referenced by hot
  history` — `threw integrityFailed(issueCount: 1)`
- `College commitment integrity / archived commitment and release events bind to the recruiting
  season` — `[The professional free-agency or draft market is malformed or out of phase.]`

**One root cause, in two test helpers, and the engine was right.** `applyingCollegeCycle` and
`archivedProspectRoot` move the root's calendar and league forward without moving `proMarket` with
it. `GameState.bootstrap` ties the two together and the final-week scheduler rollover keeps them in
step, but these helpers skip the scheduler; two renewals therefore left a season-0 market under a
season-2 calendar. M6's ±1-season plausibility window rejects that root, correctly — it is one the
engine could never produce. The fix sets the market season alongside the calendar in both helpers.
No production code changed, and the portal-scheduler replay, which drives the real scheduler across
two seasons, was green throughout — which is the evidence that the product path was never wrong.

**The M6/M7 handoff listed only focused gates as verified.** The full default run was not among
them and did not pass. Read that handoff as a claim about focused suites only.

### Personnel screens — **DEBUG reference fixtures, not career-wired**

Roster and Player Profile exist as SwiftUI screens over immutable read models, reachable from the
DEBUG `--roster` and `--player-profile` entry paths against a fixed seven-player sample. They read a
sample fixture, not `GameState`, and no career loop reaches them; that wiring is M8 work behind its
production-UI entry gate. Four proofs at the iPhone 17 Pro Max landscape viewport are in
`docs/proofs/personnel/`, recaptured 2026-08-12 from the current source. Sorting, selection, and
selection/sort survival across the dossier sheet were exercised on the booted simulator. Physical-
device VoiceOver, Voice Control, Switch Control, haptics, and audio remain owner verification.

**A legal-guardrail defect was found in the shipped fixtures and fixed.** The DEBUG sample data
carried real hometowns — three of them (`Columbus`, `Baltimore`, `Nashville`) sitting directly on
`Blocklist.cities`, the rest naming real states that are themselves real programme names. The
generated-name sweep could not see them: it enumerates what the generator emits, and these were
typed into source. All fixture hometowns are now drawn from the generator's own place and region
grammar. A new `Legal: shipped copy` sweep reads every string literal under `Sources/` — walking the
tree rather than naming files, so a screen added tomorrow is swept the day it is added — and fails
on any that collides with the blocklist. Legal coverage is **19 tests / 78 checks**; the suite runs
in release, where the DEBUG fixtures do not exist, because it scans source text rather than values.

Still open, and not claimed: whether a real *state or minor city* name belongs in a world whose
cities are generated fictional at all. The fix removed the collisions; the policy question is the
owner's.

### M7B — the historical aggregate archive — **implemented, and it measured a release blocker**

An event that falls out of the bounded hot journal now folds into a `SeasonHistoryDigest` for **its
own** season rather than vanishing into a global counter. Each digest holds that season's archived
count plus a bounded, ranked sample of bodies; `DomainEventLedger.digest(forSeason:)` answers
`docs/roadmap/06`'s second M7 exit clause — surfacing a past season reads that season's aggregate,
not the journal and not the save. This is the "historical aggregate archive" `docs/roadmap/05` §2
names. Schema 10 became **11**; both pinned fingerprints moved and were confirmed identical across
two separate processes.

**The gate found a defect that no unit test would have.** Notability began as a flag and bodies were
kept first-come. At target scale a season archives roughly 70,000 events into 32 body slots, so
those slots filled during the opening weeks with rollover joins and hires — and `seasonCompleted`,
the champion, happens in the final week and could **never** be kept. The digest was structurally
incapable of holding the most important event of every season it described. Notability is now an
ordinal `historicalWeight`, ties broken by sequence so equal-weight events keep the earliest and a
finished season stops changing.

**A planned whole-root integrity check was dropped rather than built.** `archive` is `private(set)`
and mutated only by `append` and by a decoder that already validates ordering, bounds and the
count-versus-bodies accounting. No reachable path produces a bad archive, so the check could not be
made to fail — and a check that cannot fail is prose pretending to be a test, which `CLAUDE.md`
forbids.

Measured: history archive **20 tests / 147 checks**, core contracts **146 / 955**, architecture
**25 / 222**, portal-scheduler replay **9 / 27,823**.

#### The 30-season gate, in release — history passes, performance does not

```text
seasons=30 weeks=630 weekMeanMs=4552.18
archivedSeasons=30 archivedEvents=2,032,988 hotEvents=4,096 notableBodies=960
save: s1=42,370,482B/1.516s  s5=70,136,921B/2.370s
      s20=213,935,579B/7.033s  s30=306,925,923B/10.160s
```

**The history half of the exit gate is met.** 2.03 million archived events reduce to 30 digests and
960 retained bodies. The archive is contiguous, ordered, bounded, every retained season carries a
notable body, and the root stays valid after 630 weeks.

**The performance half is not, and the numbers are worse than anything previously recorded.** M2
measured **84.66 MB at season 20**; this run measures **213.9 MB at season 20** and **306.9 MB at
season 30** — two and a half times the last recorded figure at the same horizon, against an original
8 MB production ceiling. Encoding alone costs **10.2 seconds** at season 30 on a development Mac,
before an iPhone is involved, and a week costs **4.55 seconds**, so a 21-week season is about 95
seconds of simulation.

**Compressed on 2026-08-12, and the picture changed.** `03b` §4 reserved header flags bit 0 for a
compressed body from the start and the decoder already refused it as unimplemented; claiming that bit
was the whole change, so the version field does not move and a `flags=0` save still opens. Re-measured
in release:

```text
s1=6,627,637B/1.890s  s5=9,516,121B/2.933s  s20=25,659,354B/8.653s  s30=36,032,520B/12.527s
```

**8.5x smaller: 306.9 MB becomes 36.0 MB at season 30**, and season 1 at 6.6 MB is inside the
original 8 MB ceiling. Encoding costs more, not less - 10.16 s becomes 12.53 s at season 30 - which
is the trade compression makes and is worth it at this ratio. **What remains open is encode time on
device, not size.** Chunked or streaming persistence is the lever `03b` §4 keeps in reserve "if
measurements require it"; on these numbers size no longer requires it and latency might.

**None of that is the archive.** The archive is bounded to 960 event bodies and 30 digests; the
growth is the authoritative snapshot, which FSC-003 has always owned. What is new is that it is now
*measured* past season 20 rather than extrapolated, and the trend is linear in seasons with no
ceiling. **Treat FSC-003 as a release blocker, not a tuning item** — compression, a cold archive and
chunked or streaming persistence are M9 work that the product cannot ship without.

### The professional soak — **built, and it is red for a real reason**

The M6/M7 handoff listed "run the full both-tier professional soak" as open. It was never written:
M6 built the entire professional market — free agency, draft, waivers, practice squads, trades,
sourced contract expiry — and **no soak had ever driven it across seasons**. `--pro-soak` now does,
asserting per season that all 32 teams stay inside the cap and every roster bound, that no
professional carries college eligibility, and that the root stays valid, plus a byte-identical
two-season replay.

**It fails, and the failure is the point.** Over two seasons and 42 weeks:

```text
phasesSeen=closed/freeAgency  events=[proMarketClosed=1 proMarketOpened=2]
draftedFinal=0  freeAgents=0  waivers=0
```

The market opens and closes. **Nothing else ever happens** — no draft pick, no signing, no waiver,
no trade, across 32 teams and two full seasons.

**Diagnosed to root cause, and it is deeper than a missing driver.** `--pro-draft-probe` reaches the
draft directly in seconds instead of twelve minutes and reports the thrown reason:

```text
first pick threw activeRosterFull  roster=53/53  practiceSquad=0/16
committedCap=0/255000000  draftClass=224
```

**The professional roster never turns over at all.** Bootstrap fills every team to exactly the
53-man active limit, and nothing ever cuts anyone, so there is no room for a single draft pick — the
class of 224 is generated every season and none of it can ever be taken. The same bootstrap gives
professionals **no contracts** (`committedCap=0`), so nothing expires, so nobody is ever released
into the free-agent pool either. The two halves of professional intake are each blocked by the same
missing thing: roster turnover.

The original two causes, both verified by reading the call graph rather than inferred:

1. **The professional draft has no autonomous driver.** `ProMarketSystem.beginDraft` and
   `ProMarketSystem.draft` are reachable only from `IntentResolver`, i.e. only when a *promoted*
   coach submits `CoachIntent.proMarket`. `WorldScheduler` calls `openOffseason` and never either of
   the others. An unattended world never drafts — and that includes every season of the college
   phase, before the player is promoted.
2. **The free-agent pool starts empty by construction.** `openOffseason` fills it from players who
   are unowned, uncontracted and not college-eligible; at bootstrap every professional is rostered
   and contracted and every college player is eligible, so the pool is empty and
   `ProRosterAISystem` — which does run weekly and does skip the controlled team — has nothing to
   sign.

**The consequence is a product one, not a test one.** Professional rosters take in no new talent for
the entire pre-promotion career. The promotion arc's premise is that you are promoted into a league
that has been living without you; today you would be promoted into one that has aged N seasons with
zero intake.

**The driver half is now built.** `02` §4.2 already fixed the offseason *order* — free agency, then
the draft pick by pick — but said nothing about what drives it when nobody is watching, which is why
the market sat inert. That rule is now in canon with its own falsifier, and `ProRosterAISystem`
implements it: free agency signs while signings remain legal, a pass that signs nobody begins the
draft, and the draft is then made pick by pick in draft order by every AI team, pausing only when the
controlled professional team is on the clock. Before promotion no professional team is controlled, so
it runs to completion unattended. Focused gates are unmoved by it — core contracts **147 / 969**,
architecture **25 / 222**, pro market **12 / 58**, pro management **6 / 17**.

**Roster turnover was attempted on 2026-08-12 and reverted, and the attempt is the finding.**
Giving bootstrap professionals staggered contracts is the obvious unlock: `expireContracts` already
removes expiring players from rosters *and* adds them to free agency, and it is already wired into
the final-week rollover, so contracts alone would open both roster seats and a free-agent pool. It
worked in isolation - 317 contracts expired, cap legal at 146.35 M of 255 M, and the probe reported
**"first pick succeeded."**

It then failed in the scheduler, at season 0 week 21, and `--pro-week-walk` names why:

```text
wouldExpire=315/512  validAfter=false
issues=Game ... violates its tier, week, participant, or result contract.
```

**That is FSC-013 firing exactly as written.** Whole-root integrity validates every recorded game
participant against the roster they belong to *now*, which is truthful only while ownership is stable
within a live season. Releasing 315 players in the final week of season 0 invalidates every game they
played in. FSC-013 registers the fix as dated roster-tenure history and names its activation trigger
as "the first in-season roster-movement system, no later than professional trades" — **the real
trigger is earlier than that: contract expiry at the final week of a live season.** The entry is
updated to say so.

Two things were kept from the attempt. `expireContracts` now refuses to expire the last playable body
at a position, because a 53-man roster carries exactly one kicker and one punter and blind expiry left
teams without one — a latent defect that could never fire while no professional held a contract.
And `--pro-week-walk` is a fast bisector that reports the exact week a professional step refuses,
which turned a twelve-minute opaque soak failure into a named cause in seconds.

**Both gates stay red to say so.** The driver cannot fire
while every roster sits at 53/53. The remaining work is roster turnover, and it is a design question
canon only half answers: §4.2 lists "retirements and expiring contracts" and "cap compliance — a hard
date the player must be legal by" as the first two offseason beats, but bootstrap issues no contracts
for anyone to expire and nothing implements the compliance date that would force cuts. Deciding who
gets cut, and when, is an owner-level design call rather than an implementation detail, so it is not
invented here. `--pro-soak` and `--pro-draft-probe` stay red until it is answered, in the same way
P4's calibration gate stays red; **neither is in the default run**, so `verify.sh` is unaffected.

### M7C — the news feed — **implemented and green**

The living world reports itself. `NewsFeedReadModel` renders a headline from each typed payload and
persists none of it, which is the rule `DomainEventPayload` already stated: presentation text is
derived by read-model builders, never stored as the source of truth. Wording can change without
migrating a league.

**Newsworthiness reuses `historicalWeight` rather than inventing a second editorial list** — the same
rank that decides which bodies an archived season keeps decides what leads the feed. One definition
of important, used twice. The headline switch is exhaustive with no `default`, so a new payload
cannot be added without someone deciding whether it is reportable and how it reads.

It reads the hot journal **and** the archive's retained bodies, so a championship stays reportable
after it leaves the hot window — the test that justifies M7B keeping bodies at all. Ordered newest
season first with the heaviest story leading inside a season, bounded at 64. `02` §4.2b carries the
rule and its falsifier.

Measured: news feed **8 tests / 14 checks**, core contracts **152 / 978**, architecture **25 / 222**.

**M7 now has one gap left**: programme evolution and conference movement, both listed in
`docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md` and unspecified in canon.

### M7D — programme evolution — **implemented and green**

Prestige moves. It was frozen at generation, which left the world unable to evolve in the one
dimension recruiting, the AI and the job market all read. The final ranking maps to a target and
prestige steps one point a season toward it — a target with a step rather than a delta, so a
programme that settles at a rank converges instead of drifting off the scale. `02` §8 carries the
rule and its falsifier.

Applied at season rollover **after** the people transition, never before: that assignment replaces
`programmes` wholesale, so prestige written earlier in the step would be silently discarded.

Measured: programme evolution **7 tests / 275 checks**, core contracts **152 / 980**, architecture
**25 / 222** (the pins do not move — evolution fires at rollover, and the pinned transition is one
week from bootstrap), and the two-season byte-identical replay **9 / 27,823**.

**The world visibly changed, which is the point.** The portal characterization moved with it:
entrant windows 385 to 409, transfers 210 to 217, returns 94 to 112. Those are descriptive outputs
rather than pins, and they moved because prestige now feeds recruiting rather than sitting still.

**M7's last gap is conference movement**, which `02` §8 specifies as driven by performance, market
and geography. It is not built: it changes league topology, and schedule generation, standings and
whole-root integrity all read that topology, so it is a milestone-sized slice rather than a rule.

### 2026-08-14 — Floodlit adopted as the visual language; Phase 0 and 0b complete

**Owner decision: Floodlit is the visual language for all 62 game surfaces**, arriving as ~1,900
lines of never-compiled SwiftUI (lit-world backdrops, glass panels at depth, arc gauges, film
grain). The Coach's World stays the product premise — registers, world navigation, composition
rules — and Floodlit is how that premise is painted. This is the direct answer to the U-6 finding
two entries above: **"production views for the other 57 families... is the largest remaining
item."** It is now a design system to build them against, not an open question.

Four decisions bound the work, made through `AskUserQuestion` before any file changed:

1. **Derive a Floodlit light appearance.** Floodlit ships dark-only; D12 and `04` §7/§10 require
   both appearances, so a full light "day facility" palette was derived and measured rather than
   the dual-appearance requirement being waived.
2. **`04` §4.5's density budget governs** where it conflicts with Floodlit's sparser prototype
   composition, not the reverse.
3. **The `04` §10 proof gate is honoured**, not bypassed: Coaching HQ, Recruiting Board and Match
   Day still land together, owner-approved, before the other 59 families begin. Not yet reached —
   this entry covers Phase 0 and 0b only.
4. **Every region ships backed by real simulation.** No family may ship a region omitted behind an
   unlabelled gap. Where a surface's backing engine work does not exist yet (verdicts, G-02; the
   partial-advance completion record, G-15), the sheet draws both a **shipping form** (the slot
   empty, its gap ID in place) and a **target form** (labelled "once G-NN lands"), and the shipping
   form is what ships. This is `04` §6.6's verdict-state rule, generalised to any gap-carrying
   region, not only verdicts.

A fifth, mid-execution: **redraw all eight `*-v3.dc.html` reference sheets in Floodlit now**, as a
sub-phase, rather than shipping them stale and fixing later. The v3 sheets rendered the retired
violet palette (action violet, live green); Floodlit's roles read differently (action gold,
live/negative red), so re-annotating in place would have produced sheets that pass the sheet-ratio
lint while quoting figures for colours canon no longer holds.

**Phase 0 — canon amended before code, per `CLAUDE.md`'s doc-first rule.** `04-UX-AND-DESIGN-
SYSTEM.md` §6.1 rewritten to Floodlit's palette in both appearances (every ink and fill ratio
measured, not estimated); §6.2/§6.3 for Floodlit's type ramp and `CutCorner` shape family; §5, §6.5
(12 new primitives, registry 24–35), §6.6 (25 learned symbols, up from 23), §7 and §9 for the
systems Floodlit's screens need. `02-GAME-DESIGN.md`, `03-MATCH-ENGINE.md` and `03b-ARCHITECTURE.md`
gained the game-design and engine-contract sections the new surfaces require (spatial anchors,
player-game ratings, verdict computation, inbound events, staff market, scheme change, depth charts
and personnel packages) — specified before being built, not encoded only in a view. `DesignTokens.
swift` moved in the same commits as `04` §6.1, because the token-sync assertion requires them
together. Three measurement findings this session's derivation caught rather than assumed: Floodlit's
quiet ink (`#65788F`) fails the body floor and was corrected to `#8496AC`; a standard glass panel
cannot carry body text over the lit pitch (2.69 worst case), so the deep panel is specified at
α ≥ 0.78, not the prototype's 0.70; and the state-role fills measure differently from their inks in
dark appearance only — light appearance has no separate fill form.

**Phase 0b — all ten reference sheets redrawn, verified the same way each time.** `tokens-v4`,
`depth-v4`, `gauge-v4` (the last two new, no v3 equivalent — Floodlit's twelve primitives had no
sheet), `chrome-v4`, `table-v4`, `person-v4`, `readout-v4`, `week-v4`, `broadcast-v4`, `failure-v4`.
Per sheet: an emoji-range sweep, a Python replica of `DesignContractTests`' sheet-ratio lint run
against the actual file, a headless Chromium render at 1600 pt, and a full visual inspection of
every card in both appearances before commit. **Defects the loop actually caught**, not a clean
pass claimed by assertion: a fabricated light-appearance state-fills table in `tokens-v4` (deleted;
canon's fill/ink-split rule written instead of inventing numbers); wrong `AttributeDial` arc math in
`gauge-v4` (off by up to 121 units on hand-estimated `stroke-dashoffset`; replaced with a precise
circumference calculation); three emoji-range characters across three different sheets
(`readout-v4`, `week-v4`, and — caught only during this consolidated pass, after the individual
sheet had already been committed — a checkmark in `chrome-v4`, fixed the same day); a flex-shrink
layout bug in `chrome-v4`. `failure-v4`'s `InterruptedState` card is the first sheet to apply the
generalised shipping/target pattern to a non-verdict gap (G-15).

`Tests/SimTests/Suites/DesignContractTests.swift`'s `designSheets()` now walks `-v4.dc.html` and
asserts ten, not eight. The eight `*-v3.dc.html` files and their `docs/proofs/design-references/`
renders are deleted (recoverable via `git show`, per the repo's no-archive convention); the ten v4
renders replace them, regenerated with the same headless-Chromium-then-downscale recipe.
`docs/DOC-MANIFEST.md` §4a and `CLAUDE.md`'s doc table point at the v4 set.

**What this entry does not claim.** No Swift toolchain exists in this container — `swift` is absent
and egress refuses `download.swift.org`. `DesignContractTests.swift`'s actual pass/fail has not been
seen by a compiler this session; the Python replicas run here (token-sync check, sheet-ratio lint,
emoji sweep, marker-match check) are exact reproductions of that suite's logic against the real
files on disk, which is not the same claim as "tests pass." Everything in Phase 0 and 0b is
**unverified — never compiled**, per `CLAUDE.md`'s standing rule, until `./scripts/verify.sh` runs
on a machine with Swift 6.3.3 / Xcode 26.6.

**What is still untouched.** Phase 1 (importing Floodlit's actual SwiftUI package, reworking
`DeviceFrame`/`Stage` to be adaptive rather than hard-framed, tokenizing every literal size Floodlit
ships, building out registry entries 5–23 which today exist only screen-locally) has not started.
The three proof screens (`04` §10) have not been rebuilt. U-6's finding stands exactly as before this
entry: 57 families still have no production view. What changed is that they now have a verified,
ten-sheet design reference to build against instead of a stale eight-sheet one.

### What is not wired, audited from the code on 2026-08-12

The scheduler marks unbuilt systems inactive by design, so it is the authority rather than any prose.
**Three of fifteen steps fall through to inactive**, and they are not the same kind of gap:

| Step | Why |
|---|---|
| `userGame` | **The player's own match is not in the career loop.** The detailed P3 engine exists and is preserved; every game, the player's included, currently resolves through the abstract simulator. This is the largest single hole in the build and it pairs with FSC-011, which wants the match rendered from recorded anchors. |
| `expiringInboundEvents` | **Nothing exists to expire.** There is no inbound-event or correspondence state in the engine at all — the inbox is a UI read model fed by sample data. The step awaits an inbox system, not a fix. |
| `newsAndNarrative` | **Nothing needs doing weekly.** M7C made news a derived projection, and `02` §4.2b requires that presentation text is never persisted, so there is no weekly state change to make. The step is idle by design now rather than unbuilt. |

**A trap that turned out not to be one, recorded so nobody re-finds it.** Whole-root integrity
refuses a root holding a pending mandatory decision whose deadline has passed, and nothing expires
decisions — which looks like a way to wedge a save. It is not: `IntentResolver.resolve(.advanceWeek)`
already refuses to advance while any decision is unresolved (`unresolvedMandatoryDecisions`), so the
deadline cannot pass with one outstanding. The integrity rule is a hostile-save guard, not a live
trap.

**Built and reachable by nothing.** `NewsFeedReadModel` and `CoachingTreeReadModel` have zero
references outside their own files; `WorldHistoryReadModel` has one. All three are correct and
tested, and no screen or career surface can reach them — they wait on M8.

**Integrity:** one check of 29 is inactive, `contractExpiry`, which activates with roster turnover.

**UI:** six view files against `04`'s 62 canonical screen families, all behind M8's entry gate.

### Preserved pre-rebaseline P0–P4 record

The remainder of this document records the older P-phase foundation and its measurements. It is
historical evidence, not the active build order; M0/M1 above supersede its statements about P5/P6
having no schedule or off-screen model. P0 through P3 remain complete. P4's instrument is built;
the detailed engine it measures is not yet calibrated.

Suite: **243 tests, 74,796 checks, all passed**, byte-identical across separate process invocations.

Under that superseded numbering, P5/P6 capabilities have now been implemented through master-plan
M1. P7–P17 remain future work, reorganized under master milestones M2–M9.

### P4 — calibration harness and bands — **instrument done, engine not calibrated**

Built and green: `01` §6.5's band tables with their confidence grades, §6.2's TOST, §6.3's total
variation distance, and a headless seeded harness with an A/B seed ladder.

**G5 does not hold, and this is the measured gap, not an estimate.** Over 240 games per tier on the
tuning ladder:

| Tier | Bands tested | Failing | After the first tuning pass |
|---|---|---|---|
| Pro | 16 | 14 | **13** |
| College | 8 | 8 | 8 |

Passing today: pro field goal percentage (82.3%, band 81–88), pro offensive plays per team-game
(64.7, band 60–68), pro Q4 share of points (0.281, band 0.22–0.32).

**The first pass fixed shape, not constants, which is the order `03` §5.2 requires.** Three
structural defects the harness exposed on its first run: the baseline caller ran only when distance
was 7 or less and first-and-ten is ten, so it threw on almost every snap and never deep — hence six
run plays per team-game and an explosive-pass rate of zero; the college first-down clock stop
skipped the entire pre-snap charge, putting college at 142 plays per team-game against a band of
67–75; and field goal difficulty was `40 + distance`, making a routine 25-yarder a 65-rated
opponent. None of those was a constant to nudge.

**Five of 24 bands hold.** Six held before commit `a629e86`, which gave the run game a right tail
and made it read `vision` — both required by `03` §1.1 and §1.2. The constants were tuned around the
old run model, so the tuned point moved when the model did, and a worse-scoring correct model beats
a better-scoring wrong one. **Attempt seven is a re-run of `scripts/tune-calibration.sh`**, whose
search space now includes the two tail constants.

The previous configuration's numbers, kept because the comparison is the useful part: **six on the
tuning ladder and five on the holdout.** That is the honest number
and it is not close to G5, which needs all of them.

**Hand-tuning was replaced by a bounded coordinate search**, committed as
`scripts/tune-calibration.sh`. Five hand attempts moved between one and three bands with no
direction — what guessing at six coupled parameters looks like. Two passes of coordinate descent
over four candidate values each, rebuilding and re-measuring all 48 candidates, reached six. **The
holdout ladder reports five**, so roughly one band's worth of overfit across 48 evaluations: the
search found structure rather than seed-specific noise. That check is the entire reason `01` §6.6
clause 2 demands an A/B split, and it is the first time in this phase it has had anything to say.

Holding now: pro points per team-game, pro pass yards per team-game, pro field goal percentage, pro
Q4 share of points, college points per team-game, college combined game total. Both tiers hold
points per team-game, which no hand-tuned configuration managed.

**Three of the earlier five attempts were fixing the harness, not the model, and each time the
harness was making the engine look wrong.** Carry this into the next attempt:

1. A favourite's win was counted as `winner == .home`, which measures home advantage twice and the
   favourite band not at all.
2. Every "mismatch" in the talent ladder was six points apart. A six-point favourite winning 53
   percent is correct; §6.5's 0.62–0.72 describes real betting favourites.
3. `CalibrationRoster` gave every player on a team one skill ±6, so a twenty-point team gap made all
   twenty-three matchups favour the same side and the favourite won 94 percent. Real rosters are
   spiky and the spikiness is most of what makes a game close.

**Two couplings, both worth knowing before attempt seven.** Cutting home advantage brings the pro
home-win rate into band and pushes favourite-win *out*, because a per-matchup home bonus dilutes the
talent signal. And flattening the talent curve to fix favourite-win broke `03` §1.1's requirement
that a ten-point gap matter more mid-scale than at the ends — the `Leverage` tests caught it, which
is the spec defending itself against a calibration change.

**The remaining 18 failures are concentrated where the model is thin rather than mistuned.** There
is no per-drive accounting, the run game barely exists (explosive run rate measures near zero
because a run is lane leverage times a scale with a rare break-tackle bonus and nothing else), and
the play-caller is P10's, not P4's. More search over these six constants will not fix those; the
next attempt should widen the *model*, not the grid.

**D2's falsifier has NOT been met, and reporting otherwise would be wrong.** It fires if the model
"cannot be tuned to hold every band simultaneously… across 5 consecutive tuning attempts". Six
attempts have happened; three were instrument repair and one was a search rather than a hand pass.
An instrument repair is not a failed tuning attempt.

**Sixteen of §6.5's rows are not measured at all**, listed in `CalibrationBands.unimplementedMetrics`
with what each waits on: per-drive accounting, target shares (which need per-player stat lines the
engine does not produce), overtime and schedule context (P6). §6.6 clause 3 wants every scalar band
gated by TOST; until that is true the honest statement is the list.

### P3 — match engine core

D2's hybrid assignment/leverage resolution, per tier, with the clock, the drive loop and the game
loop. `GameEngine.play(tier:home:away:seed:)` plays a whole game from a seed.

| Gate | Result |
|---|---|
| G1 build | green |
| G2 tests | 243 tests, 74,796 checks, all passed |
| G4 scope | engine only; no calibration, no off-screen model, no schedule, no view |
| G6 determinism | `playByPlayFingerprint` pinned per tier as a source literal; suite byte-identical across three process invocations |

`03` §3's determinism test is now the real one it asks for — "same seed across two separate process
invocations, compared by hash of the full play-by-play". P0's golden vectors deferred it to the
phase that had a play-by-play to hash.

`SnapOutcome` carries the matchups that produced it, which is the whole reason D2 rejected the
distribution model: `04` §5.3 draws a sack as *the protection duel that lost*, and it can only do
that if the engine recorded which one. A test asserts a sack is always decided by a protection duel
the blocker lost.

**Four defects the reachability tests found in P3's own work**, each a case of the engine declaring
something it could not produce — `08`'s first named failure mode:

1. The throw resolved against a difficulty derived by inverting the chosen receiver's openness, and
   since the target is the most open of four, `incompletion` and `interception` were unreachable.
   Fixed structurally (depth is the difficulty) rather than by moving a threshold, which would have
   been P4's calibration done early and by eye.
2. `DriveEnding` was initialised to `.endOfHalf` while the loop's continue-guard tested for that
   value, so the sentinel and a real terminal state were the same thing: every drive ended after one
   play and four of the eight endings were unreachable.
3. The baseline caller punted on every fourth down it could not kick, making turnover-on-downs
   unreachable — and punting while trailing inside two minutes is also just bad coaching.
4. The call-in test conflated the *qualifying* set with the *selected* set. `02` §3.1's 12-to-40 is
   a budget applied to the qualifying snaps; the phase that builds the call-in queue owns selection.

**The phase-end review found eleven more, every one measured against the running engine.** Three
were critical and all three were the same shape as the four above — a capability the engine declared
and could not produce. The after-turnover call-in trigger could never fire. Possession changed at
the end of the first and third quarters in every game. And the play-by-play fingerprint, the sole
cross-process determinism gate, was blind to possession, both play calls, the triggers, the matchup
kinds, the tier and every player identity: seven mutations of a real game produced a byte-identical
hash.

Two more worth carrying forward. `03` §3 clause 6's seed hierarchy stopped at week — `.game`,
`.drive` and `.snap` were declared scopes that only the seed-derivation tests passed — and each
drive and snap now derives its own node, which also makes the variable draw count inside a snap
harmless. And `stopsClock` and `clockStopsOnFirstDown` were both declared and read by nobody; the
second is the *one* tier difference `03` §2 names, so ignoring it meant there was no real tier
difference at all.

**The recurring lesson across all fifteen P3 defects: the engine kept declaring things it could not
produce, and only a reachability test over the declared set found them.** An enum case, a trigger, a
constant, a result — each looked implemented and was not. That is
`08-OPUS5-BUILD-PROMPT.md`'s first named failure mode, and the defence is a test that enumerates the
declared set and asserts every member is reachable, with no exemptions. `endOfGame` was surviving on
an exemption; it was deleted instead.

**Two things P3 must not be read as claiming.**

1. **The college clock constants are UNCONFIRMED.** `03` §8 clause 3 requires them checked against
   the current rule book before the tier constants are fixed. No rule book is reachable from the
   build environment and routing around the egress policy is forbidden. **Owner action:** confirm
   the college play clock, the first-down clock stop and its two-minute exception, and the overtime
   format. P4's calibration will show whether they produce the right plays-per-game, which is
   evidence and not confirmation.
2. **Nothing in `MatchupRules` is calibrated.** The engine is numerically wrong and is expected to
   be. P4 owns the bands under TOST; a P3 that tuned by eye would make that TOST a formality over
   numbers already fitted to it. What P3 asserts is *direction*, not magnitude: a better roster wins
   more, a longer kick is harder, college fits more plays into the same four quarters.

**Not built by P3, by design:** overtime (P6 owns it, when standings care about a tie), real
coordinator AI (P10 — `BaselinePlayCaller` is a named placeholder), penalties, injuries and fatigue
accumulation, and per-player stat lines.

### P2 — generation and identity

One seed builds a whole two-tier world: map, 10 conferences, 134 programmes, 32 pro teams,
colours, venues, traditions and rivalries. Canon gained `02` §11.3.5 (the ΔE colour space and
threshold, the contrast floors, the retry budget, the sweep size, and what the blocklist does and
does not cover — none of which existed) and a rewritten `04` §2.1 contrast contract.

| Gate | Result |
|---|---|
| G1 build | green |
| G2 tests | 194 tests, 40,025 checks, all passed |
| G4 scope | generation only; no engine, no season, no view |
| Name-collision test | green, exhaustively over the reachable word space **and** across 200 leagues |
| Trade-dress test | green across 200 leagues, plus every fallback pair |
| `IdentityDistributionTests` | both limbs of D6's falsifier |
| Cross-process | suite output byte-identical across five invocations; the encoded world pinned by size and an order-sensitive digest |

**D6's falsifier did its job and failed the first implementation.** Four of the five archetype
priors were never written onto a programme, so a programme carried an `archetypeID` and nothing the
id explained — the falsifier's own definition of cosmetic. `Programme` now carries resources,
fanbase volatility, academic constraint and recruiting reach, and a nearest-centroid classifier
recovers archetype at **100%** over 5,360 programmes against a 7% chance baseline and 13% from
prestige alone.

**The phase-end review raised 13 findings across four lenses; 12 survived independent refutation,
two of them legal.** The full detail is in the fix commit. Four lessons outlive P2:

1. **A denylist only protects the slice it covers.** The blocklist was FBS institutions plus FBS and
   NFL nicknames, and the generator emitted `Southern Conference` and `Frontier Conference` — both
   real bodies — 63 and 58 times across a sweep, seen by nothing.
2. **A whole-string comparison is not a name check.** `blocks("Old Dominion")` was true and
   `blocks("Old Dominion Tech")` false, and `Old Dominion Tech` is the exact string `PORT-LOG.md`
   records the prior build shipping.
3. **A sample is not "at any seed".** The morpheme check read one file and missed 505 of 638
   reachable words. The reachable space enumerates in a fraction of a second, so it is now checked
   exhaustively; `GenerationVocabulary` collects it from the types that draw it.
4. **Test seeds can be correlated without anyone noticing.** `sweepSeed` multiplied by SplitMix64's
   own gamma, so 200 "independent" leagues were one stream at 200 offsets and the trade-dress sweep
   was worth about five leagues.

**What P2 does NOT do.** Conference realignment (`02` §8) is a simulated system that needs seasons
to drive it; P2 generates the starting map only and P6 or later owns the rest. No players are
generated — rosters are empty id lists until P7 and P8 fill them. No staff are generated.

### P0 and P1 — foundation, model and rules

#### P1 — model and rules

`02` §11 did not exist; P1 needed league structure, scholarship limits, eligibility clocks, roster
sizes, the cap and the draft shape, and canon named none of them. Per the doc-first amendment rule
they went into `docs/02-GAME-DESIGN.md` §11 first. `02` also gained §11.3.1 (both tiers share one
21-week counter, because one save runs both leagues), §11.3.2 (decline ages), §11.3.3 (the trait
roster) and §11.3.4 (the scheme roster).

| Gate | Result |
|---|---|
| G1 build | green |
| G2 tests | 137 tests, 690 checks, all passed |
| G4 scope | model and rules only; no engine, no generation, no view |

**The phase-end review found a cross-process determinism bug this phase's own commit message claimed
to have closed.** `Player.traits` was a `Set<Trait>`, and `Set` encodes to an unkeyed container in
per-launch hash order — so the most-instantiated type in the save produced different bytes every
launch, with two traits enough to trigger it. It is fixed, and the suite is now byte-identical
across eight separate process invocations. Two lessons carried forward:

1. **A round-trip test cannot see an ordering bug**, because `Set` equality is order-independent and
   the hash seed is constant within a process. Only asserting the *encoded shape or bytes* can.
2. **The scan meant to prevent it looked at one spelling.** It now covers `Dictionary<K, V>` as well
   as `[K: V]`, bans a stored `Set` in `Model/`, and requires stored properties there to carry a
   type annotation — the inferred-literal case no annotation scan can otherwise see.

**What is NOT true yet:** nothing generates a league, nothing resolves a snap, and no rule is
*enforced* — `RosterLegality` is a predicate and P7 and P8 own enforcement. P2 starts generation.

#### P0 — foundation

The spec package is complete and P0 has run: the repository is stripped to the four things
`docs/PORT-LOG.md` justifies keeping, the `03b` §1 module skeleton exists, the `03` §3 hierarchical
seeding contract is implemented and pinned by golden vectors at both the root and every derived
level, the four build-wide source scans live in `Tests/SimTests/Suites/ContractTests.swift`, and the
save envelope carries a version readable from a 16-byte header.

**Gates, run on this machine in the session that claims them, not cited from elsewhere:**

| Gate | Result |
|---|---|
| G1 build | green, `swift build` clean |
| G2 tests | 50 tests, 134 checks, all passed |
| G4 scope | diff matches `docs/plans/2026-08-09-p0-foundation.md`'s File Structure table |
| G6 determinism | golden vectors pin `seed(from:)` and `derive`; three separate process invocations byte-identical; both determinism source scans green |

**The suite shrank from 324 tests / 18,631 checks to 50 / 134.** That is the phase working — 88 of
93 tracked source and test files were deleted, including 90 arcade tests. The full accounting, with
the retrieval SHA, is in `docs/PORT-LOG.md`.

**What is NOT true yet:** there is no model, no rules module, no engine, no generation, no AI, no
design system and no view beyond a placeholder. P1 starts the model.

### What P0's adversarial review found, and what it means for later phases

The phase-end review planted six real violations in the tree and the suite reported all passed. Both
gates P0 exists to install had been shipped without being watched failing against the spellings a
real offender uses. All findings are fixed and each fix was verified by re-planting the violation and
watching the suite turn red; the detail is in the fix commit. Three consequences outlive P0:

1. **A self-test that only tries the idealised spelling is not evidence.** The first version of
   `ContractTests` caught `import SwiftUI` and missed `import struct SwiftUI.Color`; caught
   `.hashValue` and missed `Hasher()`; caught `Date()` and missed `Date.now`. Every scan a later
   phase adds owes a self-test over the *evasions*, not the textbook case.
2. **A scan over a hand-written list of directories is the coverage-boundary failure wearing a
   gate's clothes.** The ambient-identity scan named four directories, all empty, and covered
   nothing. It now walks the whole engine and exempts `Model/` by name.
3. **A gate that fails on compliant code will be weakened, not obeyed.** The design-token scan
   rejected `.padding(.horizontal, Token.gutter)`. P11 would have hit that on its first view.

### Known gaps in P0's scans, stated rather than left implicit

- **Literal colours are not covered.** `03b` §1's fourth token class is colour; the scan checks
  spacing, radius and font size only. This is the pattern set the plan deliberately scoped small.
  **P11 owns extending it**, and `04` §3's component registry is what makes that enumeration by
  construction rather than by memory.
- **The comment scanner does not understand raw strings or multiline literals.** A `#"…"#`
  containing a backslash could mis-track its closing quote. The failure direction is a false
  negative on a line no current pattern occupies. Revisit if the tree gains raw strings.

---

## What exists, and what verified it

| Artefact | State | Verified by |
|---|---|---|
| `CLAUDE.md` | Rewritten as Deliverable 0 | Read by hand; consistent with `08` |
| `docs/DOC-MANIFEST.md` + archival | Done; anti-canon deleted 2026-08-10 | `git status` shows the moves; `README.md` repointed |
| `docs/01-RESEARCH.md` | 7,300 lines, §6.0–§6.5 plus carried-forward §A–§H | Adversarial completeness critic; two defects found and fixed |
| `docs/04b-AUDIT-RUBRIC.md` | Reconstructed from `AUDIT.md` evidence | **Not** extracted from the tool — see caveat below |
| `docs/02-GAME-DESIGN.md` | Written | Not independently reviewed |
| `docs/03-MATCH-ENGINE.md` | Written | Not independently reviewed |
| `docs/03b-ARCHITECTURE.md` | Written | Not independently reviewed |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | Written | Not independently reviewed |
| `docs/05-IMPLEMENTATION-PLAN.md` | Written | Not independently reviewed |
| `docs/06-AUDIT-DISPOSITION.md` | 25 P0/P1s + 5 patterns dispositioned | Finding titles extracted mechanically from `AUDIT.md` |
| `docs/OPEN-DECISIONS.md` | D1–D14, each with an instrumented falsifier | D11 **closed 2026-08-09** by running the gates; the rest undecided as marked |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` | Authored | — |
| `docs/08-OPUS5-BUILD-PROMPT.md` | Written as a phase-entry prompt | — |
| `PRODUCT.md` | Rewritten from the §6.3 gap argument | — |

**Nothing in this table has been compiled, because there is nothing to compile yet.**

---

## D11(b) — who has a toolchain — **CLOSED 2026-08-09**

**The gates ran. Build green; 299 tests, 18,412 checks, all passed.** The machine that hosts this
session has the toolchain the earlier entries below could not find:

```
swift 6.3.3 (swiftlang-6.3.3.1.3)   Xcode 26.6 (17F113)
xcode-select: /Applications/Xcode.app/Contents/Developer
simctl: iPhone 17 / 17 Pro / 17 Pro Max / 17e / Air available, two booted
```

`./scripts/verify.sh` — written as an owner handoff — was run directly by the session: `swift build`
complete in 6.91 s, `swift run -c release SimTests` reporting `299 tests, 18412 checks, all passed`.

**Three things this does and does not mean.**

1. **G1 and G2 are agent-assertable from here.** Not by the egress-policy change D11 recommends, but
   because the session runs on the owner's Mac rather than in the sandboxed container the entries
   below describe. Same outcome as D11 option 1, reached by option 2's route, and without option 2's
   synchronous human step.
2. **This is not evidence the rebuild works.** Those 299 tests cover the *previous* build — arcade,
   dynasty, front office — most of which P0 deletes. What is verified is the **gate mechanism**: the
   harness compiles, runs, and reports real exit codes on this machine. Nothing about the rebuild is
   verified, because the rebuild does not exist.
3. **It re-escalates if the environment changes.** A session in a sandboxed agent container has none
   of the above, and the rules in `CLAUDE.md` for that case still stand in full. The claim is
   "verified on this machine, this session", never "verified everywhere".

The record of the container investigation is kept below, unedited, because it is what the decision
was made against and because the container case will recur.

---

### The original finding, retained

D11 was originally recorded as wholly blocking; on inspection it splits, and the correction unblocks
most of P0:

- **D11(a) — what framework runs the tests: decided.** The prior build already solved it and the
  solution is in the tree. `Tests/SimTests/TestKit.swift` is a ~50-line hand-rolled harness, zero
  dependencies, real exit codes, run as an executable target via `swift build && swift run -c release
  SimTests`. It needs only the Command Line Tools, not full Xcode. It carried 224 tests and 13,226
  assertions. Ported per `docs/PORT-LOG.md`.
- **D11(b) — who actually has a toolchain to run it: ~~still escalated~~ closed, see above.** It was
  an owner question, and the answer turned out to be operational: the owner's machine is where the
  sessions run.

Verified in the container this was originally written in, not assumed:

```
swift: NOT FOUND    swiftc: NOT FOUND    xcodebuild: NOT FOUND
xcrun: NOT FOUND    simctl: NOT FOUND    uname: Linux
```

Every sanctioned route was tested this session, not assumed: `download.swift.org` returns **403 on
CONNECT** through the egress proxy; Ubuntu 24.04's `swift` packages are the unrelated OpenStack
object store; there is no Docker daemon (`/var/run/docker.sock` does not exist). Routing around the
policy is forbidden, so there is no way to obtain a toolchain from inside an agent environment.

**Phase 4C of the previous build shipped having never been compiled as a direct result** — and the
failure was not the missing toolchain, it was claiming otherwise.

**This is now measured, not remembered.** The repo carried 70 MB of committed Xcode build products.
Symbol counts in both the 3.9 MB `FootballSimCore.o` and, independently, the 926 KB `.swiftmodule`
show `SeededRandom`, `GameSimulator`, `PlayCaller` and `LeagueFactory` present — and **zero symbols
from any of the ten tracked files in `Sources/FootballSimCore/Arcade/`**. The arcade layer was added
after the last build that succeeded. Detail in `docs/PORT-LOG.md`; the artifacts are now untracked
and gitignored.

**Handoff:** `scripts/verify.sh` runs build and tests and prints a pasteable result. It needs only
the Swift Command Line Tools, not full Xcode.

Every "tests green" gate in `05`, and the whole machine-verifiable half of the definition of done,
depended on D11(b). They no longer do — see the top of this section. Lifting the egress rule for
`download.swift.org` remains the right fix **if the build ever moves back into a container**; it is
no longer on the critical path.

---

## Owner decisions taken during the build

### 2026-08-12 — real location names are permitted, generator included

The owner amended the legal guardrail's first sentence: cities and regions may be real, in generated
worlds as well as in hand-written copy. Venues were offered in the same decision and **not** taken —
"Rose Bowl", "Lambeau" and "Death Valley" are marks that read as places and stay refused.

**The interesting part is that this could not be implemented by deleting the city list.** Eight
real cities are also refused as institution names — Buffalo, Cincinnati, Houston, Kansas City,
Miami, Pittsburgh, Tulsa, Washington — each because it either is a real programme or contains one,
so a flat blocklist cannot express "permitted as a city, refused as a school".
The check is now split by the *kind of name* it holds: `Blocklist.blocks` for institution-kind names
(schools, teams, conferences, divisions, venues, traditions) against the full list, and
`Blocklist.blocksPlaceName` for place-kind names (map regions, map cities, the city a member plays
in, hometowns) against the venue and person limbs only. `GeneratedWorld` exposes the two kinds
separately, and the suite asserts they **partition** every generated name — a name belonging to
neither kind is a name nothing checks, which is the hole this shape exists to close.

Legal coverage is **21 tests / 98 checks**.

**What this decision does not resolve, stated rather than left implicit.** A fictional programme
placed in a real city, wearing that city's real programme's colours, can jointly identify the real
one. The trade-dress test catches the colour pair; the combination is exactly the "individually
fictional but jointly identifying" gap `Blocklist`'s own header calls a counsel question, and
permitting real cities makes that gap easier to fall into. It is a review obligation, not a
threshold, and nothing in the suite asserts it.

**The generator is now permitted to use real place names and does not yet do so.** `NameGrammar`
still draws cities from its invented stems and endings, so no generated world changed. Populating it
with real geography is a separate design change that would touch D6's geography-driven rivalry
seeding, and under the doc-first amendment rule it belongs in canon before it is built.

### 2026-08-10 — the app is landscape, not portrait

The owner reversed the orientation half of `CLAUDE.md`'s owner-fixed tech stack, citing FM as the
reference and reporting that FM Mobile is landscape throughout, menus included. That report is
**owner testimony, not capture** — the two FM Mobile screenshots in `01-RESEARCH.md` §6.6 are both
in-match — and it is recorded as testimony in AS-6.5-07.

**The geometry supports it, and the research had not checked.** `01-RESEARCH.md` §6.5 dismissed
landscape in a single uncomputed sentence ("would force either a 2.25:1 letterbox with the width
crushed, or horizontal panning"). Computed: the whole 120-yard field fits at **6.54 pt/yd** on the
base device, **6.28** on the mini class and **5.56** on the SE, with no pan and no between-snaps
recentring, against portrait's 7.31 pt/yd over 68 of 120 yards. About 11 % smaller marks for the
entire field, permanently. §6.5 now carries the correction and a scored option E.

**Changed:** `CLAUDE.md` tech stack, `README.md`, `PRODUCT.md` and `02` §12 non-goals,
`03b` §7, `04` §4 (new two-pane chassis and its three costs) and §5.1–§5.2 (rewritten) and §6 (new
`OrientationPolicyTest` row), `04b` §2 and its Adaptivity global checks, `05` P13,
`06-AUDIT-DISPOSITION.md` row 17, `01-RESEARCH.md` (six dated corrections, none rewriting what it
observed), and `App/project.yml`.

**Two consequences worth reading before P11.**

1. **Size classes are back.** Portrait made every supported iPhone compact-width — one case, which
   is why `04b` could exclude size classes. In landscape, Plus/Max report **regular** width and
   standard/SE report **compact**. A `NavigationSplitView` left to its defaults collapses at compact
   width, so the two-pane chassis is laid out explicitly and both classes are rendered in test.
2. **AX5 is now the binding accessibility constraint.** 369 pt of usable height, not 844.
   `DynamicTypeContractTest` is the contract test most likely to fail first.

**Verification.** `xcodegen generate` accepted the new `App/project.yml` and emits
`INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationLandscapeLeft
UIInterfaceOrientationLandscapeRight"`. That is the whole of what was verified — no app target has
been built, because there are no views to build. Every device point size and safe-area inset in
`04` §5.2 remains **ASSUMPTION**; P13 measures them.

**Unresolved, and pointing the other way.** FM's own community reports the *vertical* pitch reads
better for team shape, lines and gaps (`01-RESEARCH.md` §2.1), and FM26 ships a *Vertical Scrolling*
camera. Whether that transfers to a sport whose structure is a line of scrimmage is settled by
nothing in the package. `05` P13's owner walkthrough asks it.

---

### 2026-08-10 — the design pass, and the four things it falsified

`docs/briefs/2026-08-10-claude-design-ui-brief.md` was run. Output is `Tokens.dc.html`,
`Components.dc.html` and `Screens.dc.html` at the repository root — **untracked, and not canon.**
*(Superseded 2026-08-12: those sheets are gone, and the `04` §-numbers cited below belong to the
pre-2026-08-11 structure. The definitive design references are the eight `*-v3.dc.html` sheets
named in `04` §6.5.)*
Per the brief, the artefact the build consumes is the write-back into `04`, which is done: §2.1 now
carries every colour value with its measured ratio, §2.2 the six type roles, §2.3 the radius
assignment and both elevation definitions, §3 four new component rules, §4 the corrected chassis, and
§6 the changed contrast enumeration.

**The numbers were re-computed here before being written into canon** — 24 WCAG ratios, three surface
seams and both candidate rating ladders' L\* values, all reproduced exactly. That is the only claim of
verification this entry makes. Nothing was built; there is still nothing to build.

**Four things the pass falsified, three of them mine from earlier the same day:**

1. **The two-pane chassis does not hold at AX5.** It holds at 844 at default type and falls to a
   single scrolling column at AX5. `04` §4 said it held; it now states the reduction.
2. **A management screen keeps its status bar** — 22 pt off every two-pane budget, so 347 pt, not
   369. The Inbox rail is full at four items and Roster shows six rows at 812, not seven.
3. **The match view must therefore hide the status bar**, or the field misses by 2 pt on the base
   device and 3 pt on the mini. The §5.2 clearances were 20 pt and 19 pt, so the bar is the entire
   margin. This is arithmetic, not styling.
4. **The `rating.*` ladder can only be carried by lightness.** Hue ramps collapse two of five steps
   to ΔE 2 under deuteranopia. The surviving ladder is fill-only — `poor` is 2.45:1 and `bad` 1.51:1
   as text — which changes what `ContrastByConstructionTest` enumerates. Open question 4 is closed:
   five steps hold, it does not drop to four.

**Two findings that are not the design system's to fix.**

- **All 32 pro `TeamTable` pairs are dark-primary-with-light-secondary.** The light-primary case
  `04` §2.1's contrast floors exist to catch does not occur in the data, so those floors have never
  met the case that would break them. Either `ColourGenerator`'s reachable space is narrower than
  §2.1 assumes or the requirement is theoretical. **Raised against P2, unresolved.**
- **The pass's own geometry table does not reconcile.** It states a 59 pt sensor-housing inset and
  subtracts 75, reaching 6.41 pt/yd where `04` §5.2 has 6.54. Unresolved, and one more reason P13
  measures rather than derives. The conclusion survives the whole range — the field fits at 6.54,
  6.41 and 6.05 alike, with the status bar hidden.

**Still open:** the field reads at 6.41 pt/yd and the line of scrimmage reads as a line, but
**direction does not** — nothing in a still frame says the offence attacks rightward except the ball
spot. The header indicator is carrying drive direction as well as remaining moments. P13's
walkthrough asks about direction specifically.

---

### 2026-08-10 — four owner decisions, and the gaps they exposed

Taken in one session after an adversarial review of the v2 design reference against `04` and `05`.

> Historical record. The 2026-08-11 iOS 26 / iPhone 15-generation support decision at the top of
> this file supersedes item 1's pre-iPhone-15 fallback obligation. **Superseded again 2026-08-12
> by D15 (option b):** the promised window is 852 × 393 through 956 × 440 with 844 × 390 kept as
> the install floor. Item 1's floor/ceiling pair and its 6.54–7.28 pt/yd range are stale; `04` §7
> and `docs/OPEN-DECISIONS.md` D15 hold the current numbers. What item 1 says about the size-class
> split, AX5 and the install base still holds.

1. **The SE and mini classes leave the design budget.** Floor 844 × 390, ceiling 932 × 430; the field
   scale range narrows to 6.54–7.28 pt/yd and the management budget rises to 347 pt. **It does not
   remove the size-class split** (standard/Pro are compact width, Plus/Max regular — the boundary is
   inside the supported set), **it does not remove AX5** as the binding constraint, and **it cannot
   remove those devices from the install base** — no App Store mechanism excludes by screen size, so
   `SmallestDeviceLayoutTest` becomes two-tier rather than losing a tier. `04` §4.1.
2. **The destination bar is at the bottom**, 44 pt, icon beside label, active marked on the top edge,
   hidden in the broadcast register. Costs **one row** at default type and one at AX5 — 303 pt of
   content, 78 % of the screen. They are called destinations, not tabs, because one position mutates
   from Recruit to Front office on promotion. `04` §4.2.
3. **Broadcast packages by occasion** — the strongest idea in the sequence. Two houses (college cut
   at 9°, pro orthogonal) crossed with three escalations covers all seven occasions in `02` §11 from
   about ten values. The two house accents measure **1.01:1** against each other, so geometry is
   necessarily the primary channel and colour the secondary one; a hue-only house system would fail
   the never-only-colour rule. `04` §2.4.
4. **The first-run sequence was designed**, because the review found the app **had no entry point at
   all** — every screen in `04` §4 assumed a coach already in post, while `02` §10 requires the first
   fifteen minutes to end with a job chosen and a stakeholder met. Title, board, offer, appointment
   and settings are now in `04` §4, and **canon had contained zero mentions of a settings screen.**

**Three plan defects the review found, all corrected in `05`.** P11 cited nine contract tests when
`04` §6 has ten. **No phase owned the entry point** — P17 is where that would have surfaced. And P15
was scheduled to build onboarding after P14, when D9's onboarding is diegetic and rides P12's
screens; P12 now carries first-run state and P15 owns tuning and the protocol.

**Registry is nineteen.** `ScoreBug` and `StakeholderCard` were added — both used on four or more
surfaces, both previously assembled ad hoc, which is how the score bug ended up as a grey `StatCell`.

**Still open, and none of it is design's to close:** the failure set (`ErrorBanner`, `EmptyState`)
remains undrawn in every pass; the map, draft and signing-day surfaces have no reference; all 32 pro
`TeamTable` pairs are dark-primary so the light-primary contrast floors have never met the case that
would break them; and nothing gates two *opponents* against mutual illegibility — a fixture-time ΔE
floor that `02` §11.3.5's machinery could already serve.

---

### 2026-08-10 — the design reference library is complete

> **SUPERSEDED 2026-08-12.** The `*-v2.dc.html` library described below was deleted
> (`docs/DOC-MANIFEST.md`). The definitive design references are the eight owner-approved
> `*-v3.dc.html` sheets at the repository root, indexed in `docs/proofs/design-references/` and
> named in `04` §6.5. Nothing in this entry carries design authority; it is kept as a record of
> what was done and when.

Eight `*-v2.dc.html` groups at the repository root: Tokens, Components, Screens, FirstRun, Broadcast,
Failure, League, Career, Squad, Offseason. **Untracked as canon — `04` is still the only home for the
design system**, and every finding below was written into it.

**Grounded where the code is real, marked GUIDE where it is not.** The references now match shipped
types rather than inventing parallel ones: the game plan's four axes are `PlayCall`'s real
`Tempo` / `Depth` / `Gap` enums; the aftermath enumerates `DriveEnding`'s nine cases including the
zeroes; the refusal set is `RosterLegality.Violation`'s four cases; the map uses `GameMap`'s real
1000 × 700 / 8-region geometry; the rivalry card uses `Rivalry`'s real `origin`, `intensity` and
12-bounded `notableMeetings`. Surfaces needing P6–P9 are marked GUIDE and will be altered by the code
that implements them. **This caught an error in my own first-run pass** — it invented three programme
archetypes when `Archetype.all` has fourteen real ones; corrected to `Fallen blueblood`,
`Rural stalwart` and `Mining-town grinder`.

**`04` §4 grew from 13 rows to 30.** Three comma-list cells were hiding fourteen screens, in a table
that calls itself a budget. Registry is **twenty** — `MapCanvas` joins `ScoreBug` and
`StakeholderCard`.

**The two findings worth carrying into the phases that build them:**

1. **The draft and signing day are not list screens.** A countdown, events arriving whether the
   player acts or not, a deadline, and a named coordinator proposal — that is the call-in loop with
   different content. They take the broadcast register and reuse `ScoreBug` live and `CallInCard`.
   P8 building a second timed interaction would get it worse the second time. **An expired draft
   clock must auto-pick**; this is a commute game and a clock expiring into nothing soft-locks it.
2. **`MapCanvas` has no accessible form.** 134 positions with no natural order is harder for
   VoiceOver than the field's 22 named marks. Likely answer: the canvas is decorative and the verdict
   panel carries the meaning. Unresolved, and P14 owns it.

**Detector across all eight: 28 findings**, against 17 for v1's three files — but the composition
changed. Nineteen are `side-tab`, and on inspection **all nineteen are load-bearing or false
positives**: stakeholder rule colours identifying the speaker per §7, the roster depth spine encoding
order, refusal severity, and four that are the championship frame's corner marks being read as side
tabs. Two genuinely decorative stripes were found and removed. That distinction is stated rather than
hidden, because v1 was criticised for the same rule.

---

### 2026-08-10 — the design reference library is at 37/40, and canon points at it

> **SUPERSEDED 2026-08-12.** Canon no longer points at the `*-v2.dc.html` sheets — they were
> deleted, and `04` §6.5 now names the eight owner-approved `*-v3.dc.html` sheets as the definitive
> design references. Read this entry as history, not as direction: its screen counts, component
> names, chassis and navigation model all predate the owner's 2026-08-11 `04` rewrite.

**Sixteen `*-v2.dc.html` sheets at the repository root**, indexed in `docs/04-UX-AND-DESIGN-SYSTEM.md`
and named per-phase in `docs/05-IMPLEMENTATION-PLAN.md` for P11 through P15. `04` remains the only
canonical home: where a sheet and `04` disagree, `04` wins and the sheet is the defect.

**Two owner decisions closed the last open questions.** Light ships as an equal appearance. The
all-22 field is kept, with the frame redrawn at true 1.15 yd spacing — and the redraw settled the
question rather than confirming the assumption: at 7.52 pt centres a legible numeral needs a ~20 pt
disc, which is **62 % occluded**, and 58 % at the ceiling. So all 22 marks are drawn at true
positions, the nine interior linemen as ringed discs the eye can **count**, and 13 numerals sit on
the skill positions and the three foregrounded marks. `04` §5.2 is amended in that one direction, on
a redrawn frame rather than on an assertion.

**A six-lens adversarial review drove the uplift** — 37 agents, 46 raw findings, 31 rated P0/P1,
**10 confirmed after independent refutation.** The 21 that were refuted matter as much as the 10 that
held: several were confident, well-argued and wrong. Three findings were fixed before any plan was
written, and all three were the library lying about itself:

1. **A legal breach.** The pro tier shipped as *Detroit Motors* across four files. `Detroit` is in
   the project's own `Blocklist.swift:149`, so `blocks("Detroit Motors")` returns `true` — a name our
   own name-collision gate rejects, under a disclaimer saying no real franchise appears. The trade
   dress was clean (ΔE 32.6); the name alone was the defect.
2. **A false remedy.** The `ScoreBug` hairline was published at 3.4:1 and computes to 1.79:1. Solved
   rather than guessed: `#9E9E9E`, 7.84 on the block and 3.86 on turf.
3. **A cheating demonstration.** The all-22 frame drew linemen at 2.17× true spacing while claiming
   `04` §5.2 "already required" it — §5.2 says the opposite.

**Scores, honestly.** 31/40 before the uplift, **37/40** after. The three that moved were User
Control (match exit, call-in expiry and pause, save cadence, cold-launch resume), Consistency (one
palette, one budget table, one `ScoreBug` spec, the ceiling made isotropic) and Flexibility
(`ListControls` and `AttributeRow` — the library had **no filter, sort, search or multi-select
anywhere**, which was the largest single finding). The three still at 3 — Error Prevention,
Recognition, Help — are held down by P7–P10 mechanisms that do not exist yet.

Coverage: **27 device frames, 8 at AX5, 3 in light.** Legal sweep of the corpus against every
`Blocklist` entry: clean.

**Two housekeeping decisions taken this session, both legal.** The three v1 sheets were **deleted** —
superseded in full, and one carried the same real-identity breach. Reachable through `git show`, the
same disposition `docs/PORT-LOG.md` records for `NameBank.swift`. And the owner's Football Manager
reference screenshots are **gitignored, never committed**: they are third-party copyright and
`CLAUDE.md` permits reference titles as mechanics research only.

**Still unverified and needing a machine with the HIG in front of it:** the twelve SF Symbol names in
`System-v2`, and every AX5 point size. Neither is design work.

---

## Decisions made without owner input

The owner was asked and did not answer, so these were decided during execution and are marked
reversible. They are called out here because they are the ones most worth overturning if wrong:

- **D14 build order: college first.** The player starts there and both unsolved risks live there.
- **D14 league size: ~134 programmes**, with an explicit fallback to ~64 if D4's week-advance ceiling
  cannot be met at that scale.

---

## Caveats on the spec package itself

Stated plainly so nothing here is mistaken for more than it is.

1. **`04b` is reconstructed, not extracted.** The rubric was reverse-engineered from `AUDIT.md`'s
   evidence because `/impeccable` was not available. Re-run the tool and paste its rubric verbatim to
   make it authoritative.
2. **Three accessibility premises are UNVERIFIED.** The 44 pt touch-target floor, Apple's exact
   Reduce Motion semantics, and the SwiftUI API for suppressing `TimelineView` updates were cited
   from memory — `developer.apple.com` returned no readable body through the proxy. Confirm against
   the HIG before implementing D12.
3. **D1's timing constants are proposals, not measurements.** The seconds-per-call-in and
   seconds-per-drive-summary figures that the gate-zero arithmetic multiplies by need the owner
   protocol in `01-RESEARCH.md` §6.0 §8 and one layout measurement in Xcode.
4. **Recruiting-AI cost across ~134 programmes has never been measured.** D4's dominant
   week-advance term is an estimate. P5 of the plan is where it gets tested, and where D14's
   fallback fires if it fails.
5. **The engagement post-mortem's experiential half is unrun.** §6.0's static census is complete and
   its findings are strong — one mandatory decision per week, zero inbound events, jeopardy frozen
   for a season, 22 of 24 skill nodes inert. The play-session protocol is written but needs the owner
   and a running build.
6. **Most of the design documents have not been independently reviewed.** Only `01-RESEARCH.md` went
   through an adversarial critic — and a pre-push audit on 2026-08-09 (five lenses, every finding
   independently refuted before being accepted) confirmed 23 defects across the package, of which
   three were blockers. All 23 are fixed; the lesson is that the package had not been re-read against
   the tree after it was written.
7. **The legal guardrail violation is gone from the working tree, and remains in history.**
   `Sources/FootballSimCore/Generation/NameBank.swift` declared its college list "Fictional alma
   maters" while containing real NCAA institutions, and asserted "no real player is referenced" for
   a name cross product that cannot guarantee it. **P0 deleted it** along with the rest of
   `Generation/` (commit `37b10c3`). It is still reachable through `git show`, as every deleted file
   is, and `docs/PORT-LOG.md` keeps it as the worked example P2's collision test exists to catch.

---

## What the previous build was

Retained as Tier B evidence, not as a mandate. Its engine was calibrated, had 224 tests and 13,226
assertions, a ten-season soak, cross-process determinism (fixed the hard way — `UUID.hashValue` is
salted per launch), and bounded save growth (8.3 MB → 2.3 MB). Its UI scored 9/20. Its management
week contained one mandatory decision.

Full detail in `docs/AUDIT.md` and `docs/01-RESEARCH.md` §6.0.
