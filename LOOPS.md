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

`match-engine-oracle-widening` · Match simulation · saved 2026-08-19

Adds one situational oracle per pass to play resolution, the clock and the anchor contract, and repairs the engine wherever the widened oracle catches an illegal state.

Prompt:

> Choose one match situation the engine can reach and the suite never constructs: a clock or down edge, a scoring-play boundary, an overtime path, or an anchor set at the field bound. Assert its legality, then run the --engine, --match-reducer and --snap-anchors suites. Fix the engine where the new oracle fails. Keep each change bounded and re-run all three. Stop when two consecutive passes add a situation and find nothing. Ask before changing any calibrated outcome distribution.

### 905 — Calibration band tightening

`calibration-band-tightening` · Statistical calibration · saved 2026-08-19

Tightens one calibration band per pass under TOST and fixes the model when a band will not hold, never widening the band to make the lane green.

Prompt:

> Pick the loosest calibration band in docs/03-MATCH-ENGINE.md section 5.1 and tighten its margin one step. Run ./scripts/verify.sh --lane calibration and the --m3-recruiting-calibration suite, reading the TOST confidence interval and margin rather than a point estimate. If it fails, fix the model or state the margin honestly in the document; never widen the band to pass. Stop when a band cannot be tightened without a model change you cannot justify. Ask before amending a band in canon.

### 906 — Two-tier agreement gate

`two-tier-agreement-gate` · Model equivalence · saved 2026-08-19

Builds the missing runner for the detailed-versus-abstracted equivalence gate, then hunts the metrics on which the two simulation models disagree.

Prompt:

> TwoTierConsistencyTests is registered in SuiteCatalog with no runner, so the commitment that the simulation and the off-screen model agree is unbacked. Add a dispatched command and function for it, then assert equivalence under TOST on one metric per pass from docs/03-MATCH-ENGINE.md section 5.1. Fix the abstracted model where it diverges. Stop when every listed metric holds or a divergence needs a design decision. Ask before changing the detailed model to fit the abstracted one.

### 907 — Season transition fuzz

`season-transition-fuzz` · Season and calendar · saved 2026-08-19

Walks the calendar across season boundaries at many seeds, asserting scheduling, standings, realignment and rollover invariants that the current suites do not reach.

Prompt:

> Advance the world across season boundaries at many seeds and assert one structural property the suites do not currently check at every transition: game and bye counts, standings arithmetic, conference realignment legality, rivalry ordering, or calendar step order. Run the --competition-only, --season-rollover, --realignment and --rivalry-order suites. Fix the scheduler where a transition breaks it. Stop when two consecutive passes add a property and find nothing. Ask before changing a documented calendar constant.

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

`people-lifecycle-drift-watch` · Player and staff lifecycle · saved 2026-08-19

Watches ratings, ages, injuries, discipline and tenure across long runs for distributional drift the per-week suites cannot see.

Prompt:

> Pick one lifecycle distribution with no band: rating spread by tier, age curve, injury incidence and duration, discipline frequency, tenure length or churn rate. State a band with its source, assert it at several season indices across a long run, then run the --people-lifecycle, --discipline, --roster-tenure, --injury-evidence and --programme-evolution suites. Fix the model when the band breaks. Stop when two consecutive passes add a band and find nothing. Ask before amending a decline age or trait constant.

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

`soak-horizon-extension` · Long-horizon soak · saved 2026-08-19

Extends the long-run soak one assertion or one horizon at a time and treats every unbounded collection as a defect rather than a growth curve.

Prompt:

> Add one assertion to the soak that docs/03-MATCH-ENGINE.md section 6 requires and it does not yet make, or extend the horizon past twenty seasons at shipping league size. Run ./scripts/verify.sh --lane soaks and the --m3-soak suite. Every collection that grows across seasons must be verified bounded by growth check, not by inspection. Fix the engine when an assertion breaks. Stop when two consecutive passes add an assertion and find nothing. Ask before reducing league size to make a run fit.

### 915 — Performance budget instrumentation

`performance-budget-instrumentation` · Performance budgets · saved 2026-08-19

Builds the missing performance and agency budget runners, then measures the unmeasured week-advance term instead of continuing to estimate it.

Prompt:

> PerformanceBudgetTests and AgencyBudgetTests are registered in SuiteCatalog with no runner, so two PRODUCT.md commitments are unbacked. Add a dispatched command and function for one per pass, then measure one budget from the docs/03-MATCH-ENGINE.md section 7 table against its target and hard ceiling. Start with week advance at shipping league size, whose recruiting-AI term has never been measured. Report the measurement and the hardware. Stop when every budget has a runner and a figure. Never report an estimate as a measurement.

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

`release-gate-traceability-loop` · Release readiness · saved 2026-08-19

Keeps every commitment, registered gate, dispatched runner and status claim in agreement, so no promise is backed by a test that cannot run.

Prompt:

> Run the --catalog and --commitment-coverage suites and list every gate registered without a runnable command and every commitment naming one. Close one gap per pass by building the runner and dispatching it, or by removing a commitment the project no longer makes. Then reconcile docs/STATUS.md so nothing unverified is described as verified. Stop when the catalog prints no missing runner and status matches the tree. Ask before removing any commitment.
