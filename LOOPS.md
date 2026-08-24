# Project loops

Repeatable agent loops for finding and patching **unknown** faults in this project: faults no current
assertion is shaped to detect. Each one widens a detector first and runs it second, because running an
existing gate can only re-find faults that gate already knows how to see.

Format and method follow the Loop Library at <https://signals.forwardfuture.com/loop-library/>. The full
records, with steps, verification detail and rationale, are `docs/loops/catalog.json`; this file is the
register an agent reads. `scripts/check-loops.mjs` fails if the two disagree, so edit the catalog and
regenerate rather than editing here.

**These files carry no canon authority.** `docs/DOC-MANIFEST.md` is the authority on what is canon, and
nothing below amends a design decision. A loop that turns out to need one stops and says so.

## Standing rules every loop inherits

1. **Widen, then run.** A pass that only re-runs an existing check has not looked anywhere new.
2. **Fix the system, never the instrument.** Never widen a calibration band, relax an invariant,
   re-record a fingerprint, add a scan exemption or delete a commitment to reach green.
3. **Enumerate by construction.** A check over a hand-written list stops covering the codebase the day
   after it is written.
4. **Stop honestly.** Terminal states are success, clean no-op, blocked, approval required, exhausted
   and no progress. An error is never success, and an exhausted budget is never success.
5. **No progress means stop.** Absent a limit the owner set, stop after two consecutive passes that
   widen coverage and find nothing.
6. **Canon first.** A gameplay decision is amended in the documents before it is implemented. Never
   encode a design decision only in code.
7. **Escalate, do not resolve.** Legal identity questions, owner gates, device measurement and
   simulator walkthroughs are not agent decisions.
8. **Never claim an unrun gate.** With no Swift toolchain a loop stops as blocked. Write the code to the
   same standard, record it in `docs/STATUS.md` as unverified and never compiled, and do not report a
   build or a test run that did not happen.
9. **Hand the long run off.** Where a loop carries a companion prompt, its verification is a soak or a
   sweep measured in tens of minutes. Do not sit through it: widen the detector, then hand the companion
   to a second agent with the commit named, and carry on. The companion reports and never fixes, so the
   two halves cannot race on the same tree.

## The loops

### 901 — Determinism drift hunt

`determinism-drift-hunt` · Simulation determinism · saved 2026-08-19

Widens the determinism fingerprint one unpinned field at a time and fixes every cross-process divergence it exposes, never by loosening the pin.

Prompt:

> Pick one determinism surface in FootballSimCore that no current assertion pins: a store, ledger, scheduler or calendar field absent from the pinned fingerprints. Extend the --architecture-only suite to pin it by construction, then run ./scripts/verify.sh --lane determinism in two separate process invocations and compare. Fix any divergence in the engine, never by loosening a pin or re-recording a literal to match. Record each widening in docs/STATUS.md. Stop when two consecutive passes add coverage and find no divergence. Ask before changing an existing pinned fingerprint literal.

### 902 — World generation invariant widening

`generation-invariant-widening` · Procedural world generation · saved 2026-08-19

Adds one generation invariant per pass across programmes, conferences, rosters and identities, and repairs the generator wherever a wider seed sweep breaks it.

Prompt:

> Name one property of a generated world that docs/02-GAME-DESIGN.md section 11 requires and no suite asserts: conference sizes summing to 134, division shape, roster position templates, trait distribution, jersey-number legality or rating spread. Assert it across a seed sweep, then run the --generation-only and --trait-population suites. Identity distribution has no flag of its own and is reached only by the default full run, so use that lane when the property touches names or identity. Fix the generator, not the invariant. Stop when two consecutive passes add an invariant and find no failure. Escalate any fix that would change a documented rules constant.

### 903 — Legal partition sweep

`legal-partition-sweep` · Intellectual-property guardrail · saved 2026-08-19

Holds the name-collision and trade-dress tests to a strict partition of every generated name, so a name kind that neither sweep checks cannot exist.

Prompt:

> Enumerate every kind of name a generated world produces and check that each is swept by either the institution-kind check or the place-kind check, never neither. Extend the partition assertion by construction, then run the --legal-only suite across at least 200 leagues along with the trade-dress delta-E check on both members of each colour pair in both orientations. Fix generation, never the threshold. Stop when two consecutive passes add coverage and find nothing. Escalate every borderline identity to the owner; resolve none yourself.

### 904 — Match engine oracle widening

`match-engine-oracle-widening` · Match simulation · saved 2026-08-23

Adds one situational oracle per pass to play resolution, the clock and the anchor contract, and repairs the engine wherever the widened oracle catches an illegal state.

Prompt:

> Choose one match situation the engine can reach and the suite never constructs: a clock or down edge, a scoring-play boundary, an overtime path, or an anchor set at the field bound. Assert its legality, then run the --engine, --match-reducer and --snap-anchors suites. Fix the engine where the new oracle fails. Keep each change bounded and re-run all three. Stop when two consecutive passes add a situation and find nothing. Ask before changing any calibrated outcome distribution.

### 905 — Calibration band tightening

`calibration-band-tightening` · Statistical calibration · saved 2026-08-23

Tightens one calibration band per pass under TOST, across the paired lane and the two-tier holdout gate, and fixes the model when a band will not hold rather than widening it.

Prompt:

> Pick the loosest calibration band in docs/03-MATCH-ENGINE.md section 5.1 and tighten its margin one step. Run ./scripts/verify.sh --lane calibration and the --m3-recruiting-calibration suite, reading the TOST confidence interval and margin rather than a point estimate. The two-tier holdout gate shares this instrument, so run --two-tier-consistency in the same pass and treat a band it derives its margin from as in scope here. If a tightening fails, fix the model or state the margin honestly in the document; never widen the band to pass, and never move a metric into the uncovered list to reach green. Stop when a band cannot be tightened without a model change you cannot justify. Ask before amending a band in canon.

Companion prompt — Calibration lane run:

> Run only what this prompt names, on the commit named in the request, built with -c release. Do not widen an assertion, tighten a band, adjust a budget or fix anything: this pass reports. Run ./scripts/verify.sh --lane calibration, the --m3-recruiting-calibration suite and the --two-tier-consistency gate. For every band report the TOST confidence interval and the margin, not a point estimate, and say for each whether the interval sits entirely inside the margin. Name the host. Report any band whose lane passed without asserting that the band holds, since a lane can validate its own mechanics and assert nothing about the model. The run counts as complete only if it ends with the suite summary line; a non-zero exit with no summary is an abort, and an abort is reported as an abort rather than as a failure. A release build plus the lane itself runs long: start it detached and never read a long silence as a hang. If there is no Swift toolchain, stop and report blocked.

### 907 — Season transition fuzz

`season-transition-fuzz` · Season and calendar · saved 2026-08-23

Walks the calendar across season boundaries at many seeds, asserting scheduling, standings, realignment and rollover invariants that the current suites do not reach.

Prompt:

> Advance the world across season boundaries at many seeds and assert one structural property the suites do not currently check at every transition: game and bye counts, standings arithmetic, conference realignment legality, rivalry ordering, or calendar step order. Run the --competition-only, --season-rollover, --realignment and --rivalry-order suites. Fix the scheduler where a transition breaks it. Stop when two consecutive passes add a property and find nothing. Ask before changing a documented calendar constant.

Companion prompt — Season-boundary sweep run:

> Run only what this prompt names, on the commit named in the request, built with -c release. Do not widen an assertion, tighten a band, adjust a budget or fix anything: this pass reports. Run the season-boundary sweep at the seed count the parent loop specifies, plus the --competition-only, --season-rollover, --realignment and --rivalry-order suites. Report per-seed pass and failure, and for each failure the season index, the transition step and the first assertion that broke, so the parent loop can reproduce it at a single seed rather than re-running the sweep. The run counts as complete only if it ends with the suite summary line; a non-zero exit with no summary is an abort, and an abort is reported as an abort rather than as a failure. A release build plus the lane itself runs long: start it detached and never read a long silence as a hang. If there is no Swift toolchain, stop and report blocked.

### 908 — College acquisition legality sweep

`college-acquisition-legality-sweep` · College football systems · saved 2026-08-19

Sweeps recruiting, the transfer portal, redshirts, commitments and scholarship limits for states the rules permit on paper but the code can reach illegally.

Prompt:

> Take one college acquisition rule that the rules module fixes and the suites do not enforce end to end: scholarship count, eligibility clock, redshirt legality, commitment uniqueness or portal window. Assert it after every transaction rather than at rest, then run the --college-commitments, --college-state, --redshirt-only, --portal-policy, --portal-transaction and --portal-scheduler suites. Fix the system, not the rule. Stop when two consecutive passes add a rule and find nothing. Escalate any rule the documents leave ambiguous.

### 909 — Pro front office legality sweep

`pro-front-office-legality-sweep` · Professional front office · saved 2026-08-19

Holds the salary cap, contracts, the draft and the player market to invariants asserted after every transaction, including the dead-money overage the rules permit.

Prompt:

> Take one professional rule the rules module fixes and the suites check only at rest: cap compliance including permitted dead-money overage, contract validity, roster limits, depth-chart completeness or draft order. Assert it after every transaction, then run the --cap-compliance, --pro-management, --pro-market, --pro-draft-probe and --depth-chart suites. Fix the system, never the limit. Money stays integer dollars. Stop when two consecutive passes add a rule and find nothing. Escalate any ambiguity to canon before coding it.

### 910 — People lifecycle drift watch

`people-lifecycle-drift-watch` · Player and staff lifecycle · saved 2026-08-23

Watches ratings, ages, injuries, discipline and tenure across long runs for distributional drift the per-week suites cannot see.

Prompt:

> Pick one lifecycle distribution with no band: rating spread by tier, age curve, injury incidence and duration, discipline frequency, tenure length or churn rate. State a band with its source, assert it at several season indices across a long run, then run the --people-lifecycle, --discipline, --roster-tenure, --injury-evidence and --programme-evolution suites. Fix the model when the band breaks. Stop when two consecutive passes add a band and find nothing. Ask before amending a decline age or trait constant.

Companion prompt — Lifecycle long-run measurement:

> Run only what this prompt names, on the commit named in the request, built with -c release. Do not widen an assertion, tighten a band, adjust a budget or fix anything: this pass reports. Run the long lifecycle horizon and the --people-lifecycle, --discipline, --roster-tenure, --injury-evidence and --programme-evolution suites. Report each watched distribution at every season index sampled, as a distribution rather than a mean: a drift that only shows in the tail is invisible in an average. Name any distribution that has no stated band, since an unbanded distribution cannot fail and must not be counted as watched. The run counts as complete only if it ends with the suite summary line; a non-zero exit with no summary is an abort, and an abort is reported as an abort rather than as a failure. A release build plus the lane itself runs long: start it detached and never read a long silence as a hang. If there is no Swift toolchain, stop and report blocked.

### 911 — Career arc continuity hunt

`career-arc-continuity-hunt` · Coaching career arc · saved 2026-08-19

Walks a coach career from the college game through promotion into the pro league, asserting that identity, history and stakes survive every transition.

Prompt:

> Walk one coach career across the college-to-pro promotion and assert that one carried thing survives intact: career record, coaching tree, rivalry history, job security state, staff relationships or archived seasons. Run the --career-arc, --career-control, --coaching-tree, --professional-career-session and --history-archive suites. Fix the transition where something is dropped or duplicated. Stop when two consecutive passes add a carried thing and find nothing. Ask before changing what the promotion arc carries.

### 912 — Architecture boundary scan widening

`architecture-boundary-scan-widening` · Architecture enforcement · saved 2026-08-19

Rewrites each boundary scan to enumerate its class by construction, so a new file, symbol or import is covered the day it is added rather than the day someone remembers it.

Prompt:

> Take one source scan in the contract suite and check whether it enumerates its class by construction or spot-checks a hand-written list. Rewrite one hand-listed scan per pass to enumerate from the file system or the type graph, then run ./scripts/verify.sh --lane core. Fix every violation the wider scan finds. Stop when two consecutive passes widen a scan and find nothing. Ask before exempting any file from a boundary rule.

### 913 — Save durability hunt

`save-durability-hunt` · Persistence and migration · saved 2026-08-19

Attacks the save format with hostile and truncated inputs and every schema boundary, so corruption is refused with a plain message rather than partially opened.

Prompt:

> Construct one hostile save the suite does not currently cover: truncated envelope, corrupted entity key, invalid calendar, malformed history ledger, an older schema version or a newer one. Assert it is refused or migrated with a plain message and no partial open, then run the --save-document, --history-archive and --core-contracts suites. Fix the decode path, never the assertion. Stop when two consecutive passes add a hostile input and find nothing. Ask before changing the save schema version.

### 914 — Soak horizon extension

`soak-horizon-extension` · Long-horizon soak · saved 2026-08-23

Extends the long-run soak one assertion or one horizon at a time and treats every unbounded collection as a defect rather than a growth curve.

Prompt:

> Add one assertion to the soak that docs/03-MATCH-ENGINE.md section 6 requires and it does not yet make, or extend the horizon past twenty seasons at shipping league size. Run ./scripts/verify.sh --lane soaks and the --m3-soak suite. Every collection that grows across seasons must be verified bounded by growth check, not by inspection. Fix the engine when an assertion breaks. Stop when two consecutive passes add an assertion and find nothing. Ask before reducing league size to make a run fit.

Companion prompt — Soak run:

> Run only what this prompt names, on the commit named in the request, built with -c release. Do not widen an assertion, tighten a band, adjust a budget or fix anything: this pass reports. Run ./scripts/verify.sh --lane soaks and the --m3-soak suite at shipping league size, and the --m7-gate history lane if the request names it. Report every assertion's result, the save size at each checkpoint against the 8 MB ceiling, and the growth curve of every collection that grows across seasons. A collection reported as bounded by inspection rather than by a growth check is reported as unbounded. Do not reduce league size or shorten the horizon to make a run fit; if it will not fit, report that instead. The run counts as complete only if it ends with the suite summary line; a non-zero exit with no summary is an abort, and an abort is reported as an abort rather than as a failure. The soaks run for tens of minutes and the history lane for up to about an hour and a half: start it detached and never read a long silence as a hang. If there is no Swift toolchain, stop and report blocked.

### 915 — Performance budget potency

`performance-budget-potency` · Performance budgets · saved 2026-08-23

Turns the week-advance probe from printed evidence into a gate that can fail, and rebuilds the season-length instrument that was deleted rather than implemented.

Prompt:

> PerformanceBudgetTests now has a runner and cannot fail: it asserts only the league size and that recruiting produced decisions, then prints PERFORMANCE EVIDENCE ONLY with no pass/fail threshold while week advance measures over the 2.0 s ceiling. Give one budget from the docs/03-MATCH-ENGINE.md section 7 table a real threshold assertion per pass, starting with week advance at shipping league size, and prove the assertion is potent by making it fail on a deliberate regression before you rely on it. AgencyBudgetTests was deleted rather than implemented and its commitment now sits in PRODUCT.md's unverified-targets table; rebuild the instrument and move the row back rather than leaving the promise unbacked. Report the measurement and the hardware, and keep host figures labelled as host figures: the device gate stays open and is not yours to close. Stop when every budget in the table has a runner, a figure and a threshold. Never report an estimate as a measurement, and never lower a ceiling to fit a measurement.

Companion prompt — Budget measurement run:

> Run only what this prompt names, on the commit named in the request, built with -c release. Do not widen an assertion, tighten a band, adjust a budget or fix anything: this pass reports. Run each performance budget command on a warmed build, three times, discarding no result. Report every figure with its target and its hard ceiling, and the host: model, core count, memory and operating system. Say explicitly for each whether the command asserted the threshold or merely printed the figure, because a printed figure is evidence and an asserted threshold is a gate. Host figures are host figures and never close a device budget. The run counts as complete only if it ends with the suite summary line; a non-zero exit with no summary is an abort, and an abort is reported as an abort rather than as a failure. A release build plus the lane itself runs long: start it detached and never read a long silence as a hang. If there is no Swift toolchain, stop and report blocked.

### 916 — Accessibility matrix widening

`accessibility-matrix-widening` · Accessibility contract · saved 2026-08-19

Grows the accessibility contract across the full screen inventory by construction, so a surface added today is checked at AX5 and under Reduce Motion today.

Prompt:

> Take one accessibility check and confirm it enumerates all 62 screen families by construction rather than a sampled list. Widen one check per pass, then run ./scripts/verify.sh --lane accessibility. Fix every surface the wider check fails, at the supported layout floor and at AX5, in both appearances and both sensor orientations. Stop when two consecutive passes widen a check and find nothing. Ask before exempting a surface from the contract.

### 917 — Design token discipline sweep

`design-token-discipline-sweep` · Design system enforcement · saved 2026-08-19

Holds every view to the design system by scanning for literals, unregistered symbols and unnamed motion across the whole view layer rather than a sampled part of it.

Prompt:

> Pick one design-system rule enforced by a scan: token literals, the symbol register, or the motion register. Confirm the scan enumerates the whole view layer by construction, widen it if not, then run ./scripts/verify.sh --lane accessibility and the --core-contracts suite. Replace every literal the wider scan finds with its token; never add an exemption. Stop when two consecutive passes widen a scan and find nothing. Ask before adding a token, symbol or motion to the registry.

### 918 — Surface truthfulness audit

`surface-truthfulness-audit` · Product UI audit · saved 2026-08-19

Audits screens against the eight-dimension rubric one family at a time, treating any displayed fact without a read model as a defect rather than a placeholder.

Prompt:

> Take one screen family and map every displayed fact to a named read model. Anything with no source is a truthfulness defect, not a placeholder. Score the family on all eight dimensions of docs/04b-AUDIT-RUBRIC.md and run the --screen-read-models, --history-read-model and --core-contracts suites. Fix P0 and P1 findings before anything else, and classify borderline findings upward. Stop when a family reaches 31 of 40 with no P0 or P1. Ask before inventing any figure the engine does not produce.

### 919 — Release gate traceability loop

`release-gate-traceability-loop` · Release readiness · saved 2026-08-23

Keeps every commitment, registered gate, dispatched runner and status claim in agreement, so no promise is backed by a test that cannot run.

Prompt:

> Run the --catalog and --commitment-coverage suites and list every gate registered without a runnable command and every commitment naming one. Then check the other direction, which is how this gate was last made green: a commitment moved out of PRODUCT.md's gate table into the unverified-targets table makes the test pass without building anything, and standing rule 2 forbids it. Any row that moved needs its instrument built and the row moved back, or an owner decision to drop the promise. Close one gap per pass, then reconcile docs/STATUS.md so nothing unverified is described as verified. Stop when the catalog prints no missing runner, no commitment sits in the unverified table for want of an instrument, and status matches the tree. Ask before removing any commitment.

### 920 — End-to-end journey walk

`e2e-journey-walk` · End-to-end player journeys · saved 2026-08-23

Walks one mandatory acceptance journey end to end with a save and reload at every mutation, so a dead end between two green units is found before a player reaches it.

Prompt:

> Take one journey from the acceptance set in docs/BETA-READINESS-CONSOLIDATED.md section 7, E2E-A through E2E-H, and walk it end to end as a headless integration test through the app-layer entry points rather than by calling the engine directly. Save and reload at every mutation boundary and assert that the destination, the pending task and the unapplied decision all survive the round trip. A dead end, a silently auto-skipped decision, a decision applied twice, or a control that cannot be reached from the previous step is a defect, not an unfinished screen. Run the --core-contracts and --screen-read-models suites. Fix the flow, never the journey. Stop when two consecutive passes add a journey step and find nothing. Escalate anything that needs a canon decision about what the journey should do before you implement one.

Companion prompt — E2E-H durability walk:

> Run only the twenty-plus season durability journey, E2E-H, on the commit named in the request, built with -c release. Expect tens of minutes; run it detached and do not read a long silence as a hang. At each season checkpoint report save size, load and write time, deterministic reload equality, bounded-collection growth and whether every screen family is still operable. Do not widen an assertion, tighten a budget or fix anything: report only. The run counts as complete only if it ends with the suite summary line; a non-zero exit with no summary is an abort to be reported as an abort, not as a failure. If there is no Swift toolchain, stop and report blocked.

### 921 — Dead control sweep

`dead-control-sweep` · Control liveness · saved 2026-08-23

Traces every enabled control to a real state change, so a control that acts on nothing, or only on debug text, is caught as a defect rather than passing as an unfinished screen.

Prompt:

> Enumerate every interactive control in the view layer by construction from the source rather than from a hand-written list. Take one screen family per pass and trace each enabled control through intent, authority, receipt, save and downstream consumer. Four things are defects, not placeholders: a control wired to an empty closure, a control disabled with no reason shown to the player, a control enabled while a known mandatory decision already makes it invalid so the rejection only arrives after the tap, and a control that mutates debug status text and never alters the live game. Run the --core-contracts and --screen-read-models suites. Fix the control or remove it; never leave an enabled control that cannot act. Stop when two consecutive passes add a family and find nothing. Ask before removing a control that canon names.

### 922 — Gate potency sweep

`gate-potency-sweep` · Gate potency · saved 2026-08-23

Proves each release gate can fail by feeding it a deliberate violation, so a suite that is green because it asserts nothing is caught before anyone trusts it.

Prompt:

> Take one registered release gate and prove it can fail. Introduce a deliberate violation of the property it claims, run its command, and confirm it goes red; then remove the violation and confirm it goes green. A gate that passes both ways asserts nothing about its property and is a defect however green the lane is. Two are known vacuous today: PerformanceBudgetTests prints PERFORMANCE EVIDENCE ONLY with no pass/fail threshold, and the calibration lane validates TOST mechanics, seed separation and result counts without asserting that any band actually holds. A third pattern to look for is an assertion that compares a set to its own definition, which is an identity rather than an exhaustiveness check. Fix the gate to assert its property; never delete or relocate the commitment instead. Run --catalog and --commitment-coverage after each change. Record each gate as potent or vacuous. Stop when every registered gate has been shown potent. Ask before landing an assertion that would turn a lane red on main.

### 923 — CI lane routing audit

`ci-lane-routing-audit` · Continuous integration routing · saved 2026-08-23

Holds every named lane and registered gate to being reachable from a scheduled job, so a gate that exists and only ever runs by hand cannot be counted as coverage.

Prompt:

> List every lane scripts/verify.sh accepts, every gate SuiteCatalog registers with its lane and default-run membership, and every command the workflows actually invoke. A lane no workflow runs and a gate outside every scheduled lane are uncovered however green they are locally, and today the soaks, calibration, accessibility, archive, release and app lanes all exist and none is scheduled. Close one gap per pass by routing the gate into a job, respecting the 180-minute job ceiling and the runner cap: a long lane belongs on its own scheduled job, not bolted onto the default one. Confirm the job actually ran the suite by its printed summary line rather than by exit code alone. Stop when every registered gate is reachable from a scheduled job. Ask before adding a job that would exceed the runner budget.

### 924 — Packaging and submission readiness

`packaging-submission-readiness` · Packaging and submission · saved 2026-08-23

Closes one submission requirement per pass and asserts the built bundle carries only intended files, so the archive is not discovered to be unshippable at upload time.

Prompt:

> Take one thing the submission path requires that the repository does not yet have: the app icon set, the privacy manifest including the required-reason API declaration for the save loader's file-metadata reads, the export-compliance declaration, the version and build numbers, or explicit source and resource roots in App/project.yml in place of a bare whole-directory source list that packages build databases and compiler artefacts into the app. Add it, then assert it by construction rather than by inspection: a bundle allowlist check that fails when an unintended file is packaged, run from a clean checkout. Run ./scripts/verify.sh --lane app. Where a step is owner-only, such as choosing the product's export-compliance answer or the signed archive itself, prepare it and stop there. Stop when every box in the checklist's release-hygiene section is either machine-asserted or explicitly named as owner-only. Ask before choosing a product answer on the owner's behalf.

### 925 — Branch integration convergence

`branch-integration-convergence` · Branch integration · saved 2026-08-23

Converges divergent agent branches onto one immutable candidate, so a gate is proven on the tree that will ship rather than on a tree nobody will ever build.

Prompt:

> Survey every unmerged branch and classify each as integrate, supersede or reject, recording the reason. Integrate one per pass onto a single candidate, run the default lane on the result, and root-cause any red rather than re-pinning a fingerprint or re-recording a literal to match. Look for duplicate work before integrating: two agents have already built the same gate twice, and the branch whose version landed was not the branch that built it first, so check whether the work in front of you already exists on the trunk in another form. A red suite on the trunk is usually an unmerged fix rather than a new defect, so look for one before debugging. Watch for a branch that closed a finding by moving the promise instead of building the instrument; that is standing rule 2 broken and it integrates as a defect, not as a fix. Stop when every branch is dispositioned and one commit carries the whole candidate. Ask before rejecting a branch that carries unique work.

### 926 — Owner gate evidence pack

`owner-gate-evidence-pack` · Owner gate evidence · saved 2026-08-23

Prepares the artefacts the owner-only checklist boxes need, without ever asserting a box an agent may not assert.

Prompt:

> Take one owner-only box from the checklist's owner-gate section and prepare everything an agent legitimately can: the exact walkthrough steps with their expected results, the device and appearance matrix including the supported layout floor and the largest supported class, the capture list the evidence bundle must retain, or the protocols and instruments for the season-length timing decision and the first-session onboarding decision. Order the steps by how fast they fail, so a syntax error costs seconds rather than a whole lane. Label every expected result the agent has not observed as a prediction, never as a record, and state plainly what the pack cannot see: a headless suite cannot judge a rendered property such as clipping or reachability. Hand the pack to the owner and stop. Never report a walkthrough, a device measurement or a simulator demonstration as having happened. Stop when every owner-gate box has a runnable pack. Ask before changing what a protocol measures.
