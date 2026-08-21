# Complete Functional Beta — Consolidated Master Register

**Audit date:** 2026-08-14  
**Baseline:** `main` at `fe1686046fdd7970d540822f05e415a4280e2004`  
**Audited refs:** `claude/missing-game-features-vcrzwz` at `e21e221`,
`origin/claude/road-to-beta-plan-40e904` at `ad7fb72`, and
`claude/implement-landscape-screens-63c2b1` at `38b46a5`

This is the single completion register for the first functional beta. It replaces the idea that a
small college-only slice could be called beta-ready. College-first is a valid implementation order,
but not a release scope: `PRODUCT.md` commits v1 to both tiers, one continuous college-to-pro career,
the match engine and 2D view, college and professional acquisition, staff and scheme, the living
world, carousel, records, and 20-season durability. The 62-family inventory in
`docs/04-UX-AND-DESIGN-SYSTEM.md` is therefore mandatory unless canon is formally amended before
implementation.

When evidence conflicts, this register uses the following authority order:

1. current executable code and newly reproduced tests;
2. `PRODUCT.md`, `docs/02-GAME-DESIGN.md`, and ratified owner decisions;
3. current architecture and UX contracts;
4. branch status files and historical plans.

A historical green count, a view file, a read model, a helper, or a checked plan box is not proof of
player-facing functionality.

## 1. Completion contract

### 1.1 What “functional” means

Every one of the 62 screen families is complete only when all applicable clauses below are true:

1. **Production reachability:** reachable from at least two logical origins, with Back, deep-link or
   state restoration, and no DEBUG/sample-only route.
2. **Truthful authority:** its read model is built from `simulationSnapshot` or another named
   authoritative state, uses stable IDs, observes fog-of-war rules, and never invents staff voice,
   progress, history, or causal explanation.
3. **Real actions:** every enabled control maps to one validated engine intent. Success produces a
   visible, persisted receipt; refusal explains the authoritative reason before or after the tap as
   appropriate. Decorative and no-op controls are prohibited.
4. **Complete states:** loading, empty, error, unavailable/refused, disabled, delegated,
   interrupted, confirmation, first-week teaching, success, resume, and AX5 states exist wherever
   the flow can enter them.
5. **Durability:** the exact destination, selection, pending task, and safe transaction boundary
   survive backgrounding and save/reload before and after every mutation.
6. **Downstream proof:** a deterministic integration test proves that the system which should consume
   the committed state actually does so. A stored value with no consumer is unfinished.
7. **Rendered accessibility:** the family passes the complete device/accessibility matrix in section
   9, including 44-point targets, VoiceOver order, Reduce Motion, and no clipping or data loss.
8. **Performance and failure safety:** the interaction meets the device budget and cannot corrupt,
   silently replace, duplicate, or partially apply authoritative state.

For a gameplay decision to count, it must retain the design contract in
`docs/02-GAME-DESIGN.md:47-59`: at least two defensible answers, an attributable visible consequence
within three weeks, and a real opportunity cost. A generic confirmation, an always-correct option,
or a binary delegation bypass does not count.

### 1.2 Explicit v1 non-goals

These are the only product-wide omissions already authorized by canon: multiplayer, networking,
accounts, analytics, IAP/ads/subscriptions, custom-universe import/export, a school editor,
historical starts, iPad, and portrait. They are not backlog for this beta. Everything else promised
by `PRODUCT.md`, the weekly/offseason loops, or the 62-family registry remains in scope.

### 1.3 Current verdict

**The combined candidate is a simulation-rich prototype, not a functional beta.** Main exposes
Coaching HQ, Roster, a Player Profile sheet, and Recruiting Board. The landscape branch adds League
Map. Title/Continue is an incomplete inline state. Match Day is a DEBUG sample backed by `.sample`
data. Thus, after reconciling all three branches, only five gameplay destinations are production
reachable, most only partially, and 56 of the 62 registry families still have no family view.

## 2. Immediate release stops

These must be corrected before broad feature integration can be trusted.

| ID | Severity | Confirmed defect | Completion gate |
|---|---|---|---|
| STOP-01 | P0 data loss | Both feature branches add required persisted fields without changing envelope v1 or root schema 11. Missing-features adds four required `TeamGameStatistics` fields with synthesized decoding; road-to-beta requires `recentChanges`. Existing saves lack those keys and can fail to load. | Design the next schema, use defaulted/custom decoding or one-step migrations as appropriate, add full binary fixtures from every shipped/beta schema including completed games, migrate → integrity-check → re-save → reload, and document downgrade/TestFlight rollback policy. |
| STOP-02 | P0 data loss | A corrupt load leaves the ordinary New Career button available. Starting writes the same single `career.pfcsave`, potentially replacing the only unreadable save without backup or confirmation (`CoachWorldAppRootView.swift:104-166`; `CoachWorldSaveStore.swift:8-39`). | Quarantine failed bytes, keep a backup generation, offer retry/export/recover/confirmed replacement/delete, and prove interrupted write, low-storage, protected-data, and corrupt-primary recovery. |
| STOP-03 | P0 career dead end | `CareerSession` requires college control and rejects promotion acceptance, while the lower resolver clears college control on acceptance. There is no playable pro session. Firing and resignation do not clear college control, so a former coach can keep managing the old programme. | Introduce tier-neutral controlled-organisation/session authority; make hire, fire, resign, promotion, demotion, and rehire atomic with typed events; prove both accept/decline and fired/jobless paths through save/reload. |
| STOP-04 | P0 match truth | The detailed controlled game runs synchronously and auto-answers call-ins. One `TacticalPlanCaller` is reused for both possessions, so away offense can use the home offensive plan and home defense the away plan; the same controlled call-in driver can affect the opponent. Overtime bypasses it. | Persist a resumable `MatchSession`; choose plans by possession and controlled side; pause only for the player's team; support call-ins, takeover/handback, halftime edit, timeout/challenge/personnel controls; cold-resume deterministically. |
| STOP-05 | P0 competition truth | Detailed `GameRecord` drives/weather/call-ins are reduced immediately to `GameSummary`; in-play injuries are reported but never applied. Both abstract and detailed paths credit false participants, including unavailable/redshirted players, and starts are hard-coded to zero. | Persist bounded game evidence, apply/dedupe injuries before aftermath, derive actual participation/starts/workload from authoritative lineups/packages, and enforce redshirt/emergency rules in both simulators. |
| STOP-06 | P0 rollover | Controlled postseason portal matching requires player retention overrides, but postseason decisions are not generated before the final-week scheduler tries to resolve the market. The rollover can fail or deadlock. | Stop before each controlled portal window, generate every required decision, persist/delegate answers, then commit once; add a controlled final-week/postseason integration test. |
| STOP-07 | P0 performance | Measured median week advance is 2.83s against 2.0s; season rollover is 29.6s. A season-20 compressed save is 25,659,354 bytes and takes 8.653s to encode against 8MB/400ms; season 30 is 36,032,520 bytes/12.527s. | Bound/archive growing authority, remove unnecessary whole-root work, coalesce/checkpoint saves off-main, stream or otherwise cap peak memory, and pass end-to-end physical-device budgets including simulation, read-model rebuild, persistence, and render. |
| STOP-08 | P0 packaging | `App/project.yml:13` uses `sources: [.]`; the generated project bundles build databases, compiler artifacts, `project.yml`, and the project itself. The existing simulator app contains dozens of junk top-level resources. | Use explicit source/resource roots and exclusions, regenerate from a clean clone with pinned XcodeGen, assert a bundle allowlist, and inspect the signed Release archive. |
| STOP-09 | P1 suite integrity | Missing-features compiles but its latest run was stopped with at least 9 failing suites/14 checks and roughly one third unrun. Landscape and road branches also owe clean post-change full runs. | Root-cause failures without reflexively re-pinning; merge only after focused and complete suites pass; certify the final integration SHA, not branch-era counts. |
| STOP-10 | P1 pro result corruption | Detailed pro overtime can end tied; the abstract model always breaks ties. Standings record a tie as two losses and assign the away team as head-to-head winner; postseason also advances away on a tie. | Add tier-aware ties, tie standings/win percentage and no H2H winner; postseason must continue until a winner; reconcile detailed/abstract outcomes. |

## 3. Branch consolidation and merge disposition

All three refs descend directly from the audited `main`.

| Ref | Delta | Preserve | Do not credit as complete | Disposition |
|---|---:|---|---|---|
| `claude/implement-landscape-screens-63c2b1` | 5 commits; 11 files; +3,031/-10 | League Map view/read model/provider, production route, identifier joins, tier/rivalry labels, accessibility enumeration | Normal-size markers can overlap and become untappable; no pan/zoom/search/list parity, Team Profile route, truthful reach, or notable meetings; no device proof | Integrate first, then repair and re-certify. |
| `origin/claude/road-to-beta-plan-40e904` | 1 commit; 9 files; +1,314/-11 | G-03 bounded last-six player attribute deltas and causal components | Not wired to Player Profile; `recentChanges` decoding breaks old saves; G-15 is a plan and G-14 a sketch, not implementation | Extract G-03 selectively with migration-safe decoding and UI wiring. |
| `claude/missing-game-features-vcrzwz` | 46 commits; 97 files; +12,183/-185 | Detailed match mechanics, box stats, postseason/bowls, weather, injuries, derived depth, morale/discipline/camp, staff/finance helpers, contracts, draft ownership, difficulty/settings models, inbox/glossary read models, multiweek advance, privacy/assets skeleton | Suite is red/incomplete; match is auto-only and incorrectly routed; most models are off-screen; schema compatibility is broken; several systems have no production caller | Stabilize and extract in dependency-sized groups. Do not merge wholesale. |

### 3.1 Required conflict resolution

| Files/refs | Risk | Required resolution and proof |
|---|---|---|
| `PeopleState.swift` — missing + road | Suspension and recent-change state overlap; road requires an absent old-save key. | Retain both fields; explicit `CodingKeys`; `decodeIfPresent` defaults; bound/cause tests; main full-save fixture; discipline, lifecycle, and G-03 round trips. |
| `Statistics.swift` — missing | Four required team box-score keys are not backward-decodable. | Custom tolerant decode or schema migration; load a real main career containing completed `GameSummary` rows. |
| `docs/plans/2026-08-12-road-to-beta.md` — missing + road | Competing progress histories. | Preserve historical evidence and point current work to this file. |
| `docs/STATUS.md` — road + landscape | Both histories touch the same tracker. | Retain both accounts; do not merge stale readiness claims into present status. |
| missing + landscape | No textual conflict found. | Still run semantic change detection and all route/read-model tests after integration. |

### 3.2 Fresh verification evidence

| Candidate | Evidence | Verdict |
|---|---|---|
| Missing-features focused Release contracts | 169 tests / 1,130 checks / 1 failure | Red: `DisciplineIncidentKind` is a dictionary key without deterministic coding-key conformance. |
| Missing-features partial default run | Reached 74 suites; at least 9 suites/14 checks failed | Red and incomplete: Contracts 1, Snap 4, Game Loop 2, Conversion 1, Substitution 1, Band 1, Authoritative State 2, Abstract Competition 1, Postseason 1. |
| Landscape touched surfaces | 34/9,244 screen checks and 174/1,175 core contract checks | Green for those surfaces only. |
| Landscape full suite | Historical 750/763,687 before a later fix; subsequent full runs did not complete | Re-run owed. |
| Road-to-beta | Branch status explicitly says one uninterrupted full run is owed | Re-run owed. |

The exact-zero college tie band (`0.0...0.0`) conflicts with a generic `lower < upper` band contract.
Fix the representation or contract deliberately; do not use it to excuse unrelated red checks or
weaken all band validation.

### 3.3 Stale tracker claims reconciled

| Claim | Current truth |
|---|---|
| “Compression is absent.” | False. Envelope v1 uses zlib. Migration, backup, bounded decode, size, latency, and docs still fail. |
| “Save size is solved.” | False. Season 20 is about 3.2× the 8MB ceiling; encode latency is about 21.6× the 400ms ceiling. |
| “Signing is the only thing between the app and a phone.” | False. Packaging, icon, privacy validation, recovery, performance, route completeness, archive validation, and device gates remain. |
| “Four screens are truthful/reachable.” | Snapshot-backed is not functionally complete; live screens still contain no-op, empty, disabled, or misleading controls. |
| “G-18–G-45 written.” | Source existence only. The branch is red and most outputs have no production route. |
| “Programme evolution/realignment are absent.” | Stale. Both exist in simulation; realignment still lacks a typed event, before/after receipt, and UI. |
| “Roster tenure is absent.” | Stale. Current main has it. |
| “Professional trades are absent.” | Stale at the lower resolver: a one-for-one trade exists. It is unreachable from `CareerSession` and has no counterpart acceptance or valuation, so gameplay remains incomplete. |
| Historical full-suite counts prove integration. | False. Only one clean final-SHA run with all manual gates, app build, device evidence, and retained artifacts counts. |
| Unchecked personnel-plan boxes are backlog. | Stale: Roster/Profile code and proof assets landed. The plan should be archived only with owner approval. |

## 4. System capability register

This section captures cross-screen authority and simulation work. Screen rows in section 5 do not
duplicate these mechanics; they depend on them.

### SYS-01 — Tier-neutral career and employment authority

- Replace college-only `CareerControlState`/`CareerSession` assumptions with one controlled
  organisation that can be college, professional, or jobless without invalid projections.
- Add pro management, pro market, responsibility/delegation, and match intents to the actor.
- Keep league phase transitions scheduler-owned. A player must not be able to invoke global
  `openOffseason`, `beginDraft`, `resolveExpiredWaivers`, or `close` prematurely.
- Make appointment, accept/decline/expiry, promotion, firing, resignation, demotion, and rehire
  atomic across control, career arc, job history, typed events, news, and navigation.
- Prune expired opportunities and provide explicit reject/decline actions.
- Retain per-coach season, team, role, W-L, postseason, honours, and exit reasons across both tiers.

**Acceptance:** fresh appointment → college seasons → offer decline → later offer accept → pro week →
firing/demotion → carousel/rehire, with reload at every boundary and no former-team control.

### SYS-02 — Enforced weekly agenda and real delegation

- Persist a per-week agenda for Inbox, Game Plan, Practice, Recruiting/Front Office, and any dated
  mandatory roster/health/discipline work.
- Continue/fast-forward must name every blocker and stop at the next player event. Current code gates
  only sparse `mandatoryDecisions`, silently uses coordinator/balanced defaults, and permits zero
  recruiting work.
- Explicit delegation must produce an auditable plan/receipt. The assignee's role, attributes,
  workload, knowledge, and risk must affect quality; today staff ID is ignored.
- Partial multiweek progress must return committed steps/events and the exact stop/failure boundary.
- Every choice must meet the two-defensible/visible-cost/three-week-consequence contract.

**Acceptance:** both a college and pro regular week refuse advance until all required beats are
completed or explicitly delegated; multiweek advance stops on each decision class and resumes once.

### SYS-03 — Observer-scoped knowledge and recommendation provenance

- Key opponent observations by observer, subject, source game/date, and confidence. Do not recompute
  perfect current truth for the player's film room or coordinator rationale.
- Distinguish system arithmetic from a named staff evaluation; never label a formula “staff says.”
- Recommendations identify the actual staff member, evidence, uncertainty, trade-off, and expected
  consequence.
- Apply the same knowledge discipline to college prospects, portal players, pro scouting, staff,
  and injuries.

**Acceptance:** two organisations observing the same subject can hold different, time-stamped
beliefs; no screen leaks hidden ratings/potential; changing staff/scouting investment changes
confidence through a tested consumer.

### SYS-04 — Complete tactical and practice models

- Expand game plans from run/pass, tempo, and pressure to the canonical offensive/defensive tempo,
  aggression, personnel emphasis, coverage lean, and two coordinator keys.
- Make coordinator AI opponent-, personnel-, staff-, game-state-, and situation-aware and preserve a
  readable rationale.
- Give install, conditioning, recovery, and position focus distinct costs/effects. Conditioning and
  recovery minutes are currently decorative; health uses flat recovery.
- Add sanctioned scheme adoption/change with installation time, staff/roster fit, continuity cost,
  history, and downstream match/development consumers.
- Persist depth chart, succession, and situation packages; validate 11 unique, eligible, available
  players and deterministic injury fallback.

**Acceptance:** commit → reload → next practice/development/health/match consumes the exact plan,
scheme, depth, and packages; changing one dimension produces the previewed bounded effect.

### SYS-05 — Resumable, side-correct match authority

- Store the match RNG/state, score/clock/down/distance/possession, plans by team and side, lineups,
  drives, prompts, outstanding choice, replay cursor, and last safe checkpoint.
- Pause for controlled-team call-ins only. Offer at most three choices, named recommendation/reason,
  accept/pick/defer, takeover/handback, speed/key moments, and full halftime edit.
- Implement player timeouts, challenges based on engine-owned spot/forward-progress/turnover facts,
  tempo/aggression, personnel/package, and substitution overrides. If an unpromised choice such as
  penalty accept/decline remains automatic, label the rule and prove it is deterministic.
- Overtime uses the same side-aware decision path and continues to a postseason winner.
- Add a deterministic sparse animation-anchor stream for all 22 roles, line/ball/end spot, and any
  recorded route segments. Anchors are derived from the resolved snap, byte-stable, and cannot
  mutate or contradict the result.
- The 2D view renders recorded outcomes only; it never invents routes or live actor positions.

**Acceptance:** interrupt at every prompt/quarter/halftime/OT boundary, relaunch, and reproduce the
same final fingerprint as uninterrupted play; player actions affect only future snaps for their side.

### SYS-06 — Durable match evidence, injuries, and aftermath

- Preserve a bounded detailed record for controlled games: drives/plays or recorded moments,
  turning points, penalties, injuries, weather, call-ins/answers, lineups, participants, starts, and
  full box stats. Define truthful bounded detail for abstract games.
- Convert each match injury exactly once into persistent availability before Aftermath and the next
  week; record recovery and substitution consequences.
- Derive appearances, starts, workloads, and stats from actual participation, not all roster IDs.
- Respect injury/suspension eligibility and redshirt appearance caps; an emergency override is an
  explicit decision/event.
- Add first downs, third-down conversion, time of possession, and any other box-score fields the UI
  promises before labelling the box score complete.

**Acceptance:** game detail/aftermath/schedule/history all resolve the same immutable result; totals
reconcile; no unavailable nonparticipant receives a stat, appearance, or workload.

### SYS-07 — Competition correctness and two-tier parity

- Represent pro ties in standings and win percentage with no false head-to-head winner; forbid tied
  postseason advancement.
- Ensure detailed and abstract models use the same authoritative eligibility, depth/role semantics,
  team plans, weather/travel inputs, and result invariants.
- Implement distance-based travel fatigue promised by geography and connect practice/recovery and
  schedule congestion.
- Validate college/pro schedules, standings, tiebreaks, ranks, bowls/brackets, awards, records, and
  rollover against stored games.
- Fix exact-zero metric representation without weakening generic range contracts.

**Acceptance:** recompute every table/archive from games and obtain identical results; paired
detailed/abstract TOST/TVD gates pass on tuning and holdout sets.

### SYS-08 — College acquisition and offseason

- Add full prospect discovery, shortlist, contact/evaluation/visit planner, offers, class needs,
  Signing Day, both portal windows, retention, portal recruiting, NIL allocation, redshirt/position
  changes, staff movement, camp/discipline, roster legality, and carousel.
- Generate mandatory decisions before each controlled portal transaction; never resolve a player's
  market invisibly or skip an unresolved choice.
- Make Keep/Release timing explicit: the decision is recorded now and applied when the portal
  transaction runs, with receipt and undo until the deadline.
- Enforce contact points, board/visit/offer capacity, scholarships, position needs, and NIL
  reservations before presenting controls as available.
- Decide camp's canonical role before implementation: if player choices affect position battles,
  expose them; otherwise make it a truthful report, not a fake decision.

**Acceptance:** a complete season/offseason survives reload at every dated boundary, applies every
choice once, and cannot enter the next season with an illegal roster or unresolved obligation.

### SYS-09 — College-to-pro player identity pipeline

- Feed eligible graduates and early declarations into the pro draft under the same player UUID,
  origin programme, college career, measurements/evaluation, and declaration reason.
- Preserve drafted, undrafted-free-agent, practice-squad, active-roster, release, and retirement
  outcomes without duplication.
- Age/develop/expire/retire practice-squad players; current lifecycle processes only active IDs.

**Acceptance:** trace sampled players from college recruitment through college stats and draft/UDFA
to pro career/retirement across multiple seasons and reloads with one identity each.

### SYS-10 — Professional front office and AI

- Build controlled cap compliance, extensions, releases/restructures, cuts, contracts, free-agency
  waves, waivers/claims, practice squad, UDFA, scouting, draft board/rankings, on-clock draft,
  pick/player/package trades, and roster legality.
- Replace threshold-only negotiation with persistent offer/counter/accept/reject/withdraw state,
  competing bids, deadlines, role/guarantee/term/cap consequences, and mid-negotiation save/resume.
- Replace unconditional one-for-one player swaps with counterpart proposal, valuation, accept/reject,
  multi-asset/pick support, and trade deadline. A user cannot trade a scrub for an AI star merely by
  passing ownership/cap checks.
- Complete AI roster construction: needs/value-aware FA/draft, expiry/extensions, cap cuts,
  waivers/claims, practice squad, trades/picks, and legal deadlines. Current AI signs one top-overall
  free agent and drafts best overall.
- Keep league-market phase progression with the scheduler; expose only controlled-club actions.

**Acceptance:** full pro offseason stops for every controlled deadline/on-clock decision, resumes
after reload, ends with a legal cap/active/practice roster, and proceeds into a playable pro season.

### SYS-11 — People, development, morale, discipline, and traits

- Activate a production discipline schedule: incidents, evidence, answer/delegation/default,
  suspension, morale/stakeholder/news effects, and visible receipt.
- Base morale/playing-time effects on actual appearances/starts. Either give morale causal,
  calibrated retention/performance/discipline effects or narrow its product claim.
- Implement and populate every declared trait or remove the dormant declaration before beta:
  workhorse, mentor, ice-in-veins, front-runner, and adaptable currently lack consumers; volatile's
  discipline effect is dead while discipline is unwired.
- Preserve recent attribute changes, causes, injuries, suspensions, fatigue, confidence/form, and
  development under bounded backward-compatible decoding.

**Acceptance:** each retained trait has a generation path, direct unit proof, downstream career
effect, UI explanation, and deterministic control case; no label is decorative.

### SYS-12 — Staff, responsibilities, facilities, and finances

- Provide complete roles, vacancies, assignments, workload, unit evidence, contracts, development,
  poaching, retention, hire/fire/replace, and career history.
- Connect staff quality/fit/workload to recommendation confidence, delegation, recruiting,
  development, scheme continuity, and match planning.
- Add annual revenues, salaries/wages, reserves/credit, spending receipts, and facility-upgrade
  actions/effects; today finances are largely immutable and spent only through an unreachable helper.
- Apply the same legality and budget rules to user and AI organisations.

**Acceptance:** every financial/staff transaction is atomic and reconciles roster/staff/ledger;
season rollover posts the expected ledger once; no duplicate role or invisible vacancy survives.

### SYS-13 — Living world, narrative, and durable history

- Activate the news/narrative scheduler and emit typed, linkable events for games/upsets/rivalries,
  injuries/discipline, recruiting/portal/draft/signings, awards, career moves, stakeholders, and
  realignment.
- Realignment must retain cause, before/after memberships, schedule/rivalry consequences, and player
  acknowledgement instead of silently swapping teams.
- Retain searchable team/player/coach seasons, schedules/results, brackets, awards, rivalries,
  records, and defining moments after rollover. Current archive is too shallow for Career Line and
  full historical navigation.
- Broaden the record book beyond highest score/most yards to every category exposed in UI; keep
  bounded entries with holder, opponent, date, and game link.
- Make rivalry meetings typed rather than stringly season labels so League Map/Profile can show
  notable meetings and accumulated stakes truthfully.

**Acceptance:** every history/news link resolves before and after rollover; archive reconstruction
matches original season facts; 20+ seasons remain bounded and searchable.

### SYS-14 — Settings, onboarding, and app lifecycle

- Apply selected difficulty to new worlds and all documented consumers; the branch store currently
  has no app consumer and bootstrap uses default difficulty.
- Expose responsibility ownership, call-in frequency/pacing, fast-forward, motion, and accessibility
  choices with truthful previews. Do not ship dead toggles.
- Build the first 15 minutes as a real appointment and real first week, not a separate fake tutorial.
- Persist last route/selection/task; current transient screen always reopens HQ.
- Handle scene phase, background, protected data, cancellation, and final safe checkpoints during
  bootstrap, load, resolution, save, and Match Day.
- Default audio/haptics stance for this offline beta is silent unless licensed assets and a tested
  runtime channel land; remove dead settings/claims while retaining visual and spoken equivalents.

**Acceptance:** settings survive relaunch/new career and change every promised consumer; the first
week can be completed with VoiceOver; each lifecycle interruption resumes at the exact safe state.

### SYS-15 — Save architecture, ordering, and recovery

- Version the envelope and root deliberately; provide forward-only one-step migrations and readable
  newer/older/corrupt/unsupported/storage errors.
- Keep primary + backup/quarantine; atomic replace alone is insufficient. Opening a save is read-only
  until a successful migration/explicit user action.
- Add a save coordinator with monotonic generations, latest-snapshot coalescing, and no overlapping
  out-of-order writes. `isWorking` currently ends before autosave.
- Perform encode/compress/write off the main actor; avoid simultaneous full root + ~307MB JSON +
  compressed payload memory spikes. Add preflight bounds or streaming/segmentation as the selected
  design requires.
- Save at meaningful checkpoints and app lifecycle boundaries rather than synchronously after every
  intent; preserve a resumable in-match checkpoint.

**Acceptance:** real fixtures, rapid-tap races, crash/interruption, low storage, corrupt primary,
future version, migration, background, and 20/30-season round trips all retain the last valid state
without UI stalls or silent replacement.

### SYS-16 — Calibration, determinism, and performance budgets

- Fix the rate-estimator unit bug: some metrics are scaled to 0–100 while standard error assumes a
  0–1 probability and clamps to one, yielding zero standard error.
- Connect every now-measurable detailed stat; implement all scalar/TVD rows. The suite currently
  keeps green by asserting more than ten metrics remain unimplemented.
- Compare same roster/seed detailed and abstract models over the canonical sample; separate tuning
  and holdout and require both reports to pass.
- Run deterministic fingerprints in independent processes, not twice in one process.
- Measure end-to-end p50/p95/max week, rollover, cold launch, warm resume, navigation, save/load,
  memory high-water/jetsam, frames, thermal, and energy on the ratified oldest device. Reconcile the
  stale A16 wording with the later iPhone 15 Pro/A17 Pro D15 promise; the 844×390 install floor must
  still work.
- Enforce the current hard ceilings unless canon is formally amended: 2.0s week, 35s college season,
  16.7ms frame, 2.0s cold launch, 400ms save, and 8MB season-20 save.

**Acceptance:** Debug/Release, both-tier 20+ season action soaks, 30-season history, tuning/holdout,
device performance/memory/thermal, and save-checkpoint equality pass on the same SHA.

### SYS-17 — Verdicts, player form, and evidence projections

- Build deterministic bounded league/week baselines for the facts that screens interpret. A raw
  total or rank is not yet a verdict.
- Add expectation delta, outlier classification, sample size, confidence, evidence links, and the
  real named staff interpreter to recommendation/verdict DTOs. Suppress unsupported judgements.
- Define one engine-owned, position-aware player-game rating and retain a bounded last-five form
  series which exactly reconciles with preserved box-score evidence.
- Keep fact, system interpretation, and staff opinion distinct in providers and copy.

**Acceptance:** rebuild every verdict/form projection from the same authoritative snapshots and get
identical output; thin samples visibly lower confidence; changing the named staff member changes
only the rule-authorized interpretation; every form point resolves to its game.

## 5. Complete 62-family screen register

Status key: **Partial** = live route but incomplete/misleading; **Engine-only** = authority/action
exists with no production surface; **Derivable** = enough state for a provider but no surface;
**Sample** = DEBUG/fixture only; **Absent** = neither complete authority nor production UI.

### Entry and system

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 1 | Title / Continue | **Partial.** One auto-restored file or New Career; no explicit continue/manage/delete/backup/migration/retry. Failed load can be overwritten. | Show durable save metadata and last task; continue, retry, backup/recover/export, confirmed replace/delete; readable old/new/corrupt/storage errors; restore exact route/task. |
| 2 | New Career & Coach Identity | **Absent.** Fixed seed; an existing generated coach is commandeered. | Accessible validated identity/world/difficulty form with cancel/back; identity persists and appears consistently in appointment, news, history, and both tiers. |
| 3 | Job Board | **Absent.** Lowest-prestige programme is silently selected. | Present exactly three defensible eligible starting jobs with truthful expectations/resources/fit; stable selection; reload/back cannot double-appoint. |
| 4 | Offer | **Absent.** No starting college offer flow; later pro opportunities are incomplete. | Show authority-backed terms, consequences, deadline, and stakeholders; accept and decline each create deterministic persisted outcomes/events; expiry prunes. |
| 5 | Appointment | **Absent.** Control is assigned without handoff/event. | Atomically establish control, career job/history, stakeholder state, appointment event, and first-week route; no duplicate coach/team ownership. |
| 6 | Settings & Accessibility | **Engine model only on missing branch; unwired.** | Difficulty, responsibilities, pacing/call-in rate, fast-forward, motion and accessibility choices persist and affect named consumers; no dead audio/haptic toggle. |
| 7 | World Search | **Derivable.** `WorldHistoryReadModel` indexes many entities; no provider/navigation. | Bounded search over live/historical people, teams, games, seasons, awards, records, rivalries/events; correct destination links; no hidden truth. |

### Week and match

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 8 | Coaching HQ | **Partial.** Week strip, correspondence, recommendation empty; Inspect/Delegate/correspondence callbacks are no-ops; League/Career routes mostly dead. | Authoritative dated agenda and blockers; all routes/actions work; delegation names assignee/effect; Continue blocks with reason and produces persisted receipts. |
| 9 | Inbox | **Engine-derived model only.** Repackages mandatory/support/story; no real inbound state. | Persist sender, arrival, read/unread, deadline/expiry/status, response options/effects, evidence and links for player/staff/recruit/stakeholder/press items. |
| 10 | Opponent Report / Film Room | **Absent.** HQ “film” shows mandatory-decision reasons; tactical observations are globally keyed/perfect. | Observer-scoped dated film with source games, tendencies/personnel, confidence and staff interpretation; links to evidence; feeds Game Plan without leaking truth. |
| 11 | Game Plan | **Engine-only and underspecified.** App never calls it; missing canonical dimensions. | Edit/recommend/delegate/commit tempo, aggression, personnel, coverage and two keys; visible costs; reload; next match consumes exact side-correct plan. |
| 12 | Practice Plan | **Engine-only.** Four buckets validate, but conditioning/recovery have no effect. | Allocate exactly the weekly pool; preview distinct install/conditioning/recovery/focus costs; commit/delegate receipt; development/health consume it exactly. |
| 13 | Team Health | **Engine data, no screen/actions.** Discipline has no caller. | Reconcile availability, fatigue, injury, recovery, suspension, workload and depth; expose valid workload/recovery/incident decisions; unavailable players never participate. |
| 14 | Match Day | **Sample only.** DEBUG fixture; missing branch auto-plays and auto-answers. | Launch a controlled fixture into resumable live state; pause/speed/key moments/takeover/tactics/call-ins/timeout/challenge/personnel/substitution controls affect future play only; restore exact point. |
| 15 | Aftermath | **Absent.** Full causal evidence is discarded. | Show result, complete box score, drives/turning points, injuries/discipline, call-in choices, tactical review, recovery/development/stakeholder consequences and links; acknowledge once. |

### Team and staff

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 16 | Roster | **Partial.** Real list/sort/profile; other tabs dead; raw hidden potential exposed. | Legal complete roster, bounded filter/sort/search, fogged ability/potential, availability/contracts/scholarships/NIL, task links, immediate count reconciliation. |
| 17 | Depth Chart | **Engine-derived auto chart only.** No edit/persist/package authority. | Assign/reorder starters/backups and roles with eligibility/availability validation; save/reload; match uses chart; deterministic visible injury fallback. |
| 18 | Player Profile | **Partial.** Overview only; hometown/staff/recent form empty; G-03 not wired. | Truthful biography, role, fogged ratings/potential, form/confidence/deltas, career/game stats, injury, eligibility/contract/NIL, staff evidence and working development route. |
| 19 | Development Plan | **Absent.** | Set/clear/delegate per-player/position focus with staff/load opportunity cost; next development pass consumes it; compare expected vs actual with receipts/history. |
| 20 | Staff Room | **Absent.** Staff state/automation exist. | Complete roles, vacancies, assignments, workload, continuity, unit evidence, contracts/finance; assign/delegate/fire/hire transactions; no duplicates or invisible vacancy. |
| 21 | Staff Market & Profile | **Engine helper only on missing branch; unreachable.** | Stable candidate pool/profile/compare, scheme/relationship/evidence, asking cost; shortlist/negotiate/hire/replace checks funds/role and atomically updates career/events/ledger. |
| 22 | Scheme Book | **Absent.** Scheme fields mutate elsewhere without a sanctioned action/history. | Compare/select offensive/defensive identity; show installation, staff/roster fit and continuity cost; commit transition; match/development consume it. |
| 23 | Personnel Packages | **Absent authority and UI.** | Create bounded situation packages; validate 11 unique eligible available players/roles; persist; detailed engine selects matching package and exposes fallback. |

### College acquisition and offseason

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 24 | Recruiting Board | **Partial.** Existing-board actions work; no discovery/add/filter; every choice appears available; points mislabeled hours; relationship log empty; formula labeled staff evaluation. | Discover/add/rank/filter/sort; preflight points/phase/slot/NIL; truthful units/provenance/history; commitments/withdrawals update immediately; no invented staff voice. |
| 25 | Prospect Profile | **Partial embedded dossier only.** | Open from search/shortlist/board; fogged evaluation/confidence/history/fit/interest/offers/NIL; legal actions; return with selection/context preserved. |
| 26 | Shortlist | **Absent.** | Bounded monitored-vs-active list from full pool; add/remove/filter/search/multiselect; next-contact/status alerts; board capacity and reload proven. |
| 27 | Contact & Visit Planner | **Partial inline actions only.** | Allocate finite weekly points across prospects, prevent overcommit before tap, schedule dated visits/bulk actions, show cost/receipt, reload identically. |
| 28 | Class Overview | **Derivable; no screen.** | Needs, slots, scholarships, commitments/signings, position capacity and class history reconcile exactly with board/roster; all prospects link. |
| 29 | Signing Day | **Engine-automated; no screen/stop.** | Timed deterministic feed; unresolved choices stop advance; sign/release outcomes atomically update roster, scholarship/NIL, history and news exactly once. |
| 30 | Portal Hub | **Engine-automated; no screen.** | Window/deadlines, entrants, roster exposure, movement summary and links; open/close/reload cannot skip or duplicate transactions. |
| 31 | Retention Decisions | **Partial via one-at-a-time HQ items.** | Batch risk/evidence/NIL/capacity/recommendation with provenance; keep/release commit, undo until deadline, receipt; advance blocks; transaction matches answer. |
| 32 | Portal Market | **AI-only; no user intent.** | Browse fogged players; scout/shortlist/offer/NIL/capacity actions; competitors/outcome evidence; controlled and AI transactions share rules and commit atomically. |
| 33 | NIL Allocation | **Engine actions; no screen.** | One finite pool across recruits/roster/portal with reservations, edit/rollback, over-budget prevention; downstream interest/retention uses committed allocation. |

### Professional front office

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 34 | Cap & Contracts | **Engine-only; no pro session.** | Reconciled multi-year cap/dead-money/active/practice ledger; player links; legal release/restructure/extension/sign; future warnings and deadline blockers. |
| 35 | Contract Negotiation | **Threshold helper only on missing branch.** | Persistent offer/counter/accept/reject/withdraw lifecycle, deadline/competing bids, role/term/guarantee/cap preview, save/reload mid-negotiation, atomic contract. |
| 36 | Roster Cuts & Transactions | **Lower actions exist; unreachable/incomplete.** | Cut/trade/waive/claim/practice/UDFA controls show cap/depth/legality; controlled compliance deadline blocks; receipts; AI follows same rules. |
| 37 | Pro Scouting Board | **Engine observations/action; no session/UI.** | Bounded searchable/filterable uncertain market; invest scouting; confidence/evidence update without truth leak; feeds Draft/FA profiles. |
| 38 | Draft Board | **Engine class/order/observations; no ranking UI.** | Persist user rankings, needs, scouting, owned picks; reorder/filter; unavailable prospects disappear; deterministic across reload. |
| 39 | Draft Room | **Engine phase/pick lower actions; unreachable.** | Stop on user clock; pick/trade/defer/timeout controls; owned/future pick ledger; counterpart acceptance; AI handling; atomic selection; no double pick. |
| 40 | Free Agency | **Engine signing unreachable; threshold negotiation only.** | Market waves/repricing/competing bids; search/profile; offer/counter/withdraw; cap/roster validation; deadlines; signed player/contract/history update once. |

### League and competition

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 41 | League Map | **Partial on landscape branch.** Truthful joins; covered markers untappable; only tier filter; no profile; reach/meetings empty. | All 166 places reachable via pan/zoom/search/region list at default and AX5; map/list/VoiceOver parity; Team Profile link; truthful distance/reach/rivalry meetings. |
| 42 | Team / Programme Profile | **Absent.** | Open any team from map/search/standings/schedule; identity, trajectory, roster/staff, venue/traditions, schedule/history/rivals reconcile; tier-neutral navigation. |
| 43 | Standings | **Engine-only.** | College/pro/conference/division tables with current tiebreak explanation, tie support, controlled focus and team links; recompute from schedule; preseason/empty states. |
| 44 | Schedule | **Engine-only.** | Full team/league chronology and filters; next-game preparation, completed Game Detail, postseason stages; no duplicate/missing result across rollover. |
| 45 | Rankings & Playoff Picture | **Engine-only.** | Current ranks/bracket projection, neighbours/bubble/path with rules/evidence; update after games; distinguish unranked/not-yet-ranked. |
| 46 | Bracket / Postseason | **Engine-only.** Bowls added on missing branch but suite red. | College/pro live elimination path, bowls/championships, seeds/byes/results/next matchup and game links; never advance a tied loser; archive champion reconciles. |
| 47 | Game Detail / Box Score | **Summary data only; no screen; detailed record discarded.** | Persist/show team/player box, actual participants/starts, drives/turning points, penalties/injuries/weather/call-ins for detailed games and labeled bounded detail for abstract games. |
| 48 | Statistics & Leaders | **Engine-only.** | Bounded college/pro team/player leaderboards; sort/filter, minimum-sample/context labels, profile/team links; totals reconcile to summaries/archive. |
| 49 | Awards & Honours | **Engine/archive; no screen.** | Show current race only if authority exists; completed season/team/player honours and career rollups; source evidence/links; rollover/reload stability. |
| 50 | News | **Derived model; no screen; narrative scheduler inactive.** | Typed specific truthful headline/body/link for every newsworthy event; newest-first bounded feed; read state/empty/error; no duplicate hot/archive story. |
| 51 | Realignment Event | **Engine mutation is silent.** | Persist cause and before/after memberships, affected schedules/rivalries; emit typed event; accessible acknowledgement; no invisible map change. |

### Career and legacy

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 52 | Career Hub | **Partial engine; no screen.** | Chronological appointments, season records, honours, decisions and exit reasons across college/pro; every item links to retained evidence. |
| 53 | Job Security | **Support number only; no screen; firing leaves control.** | Expectations/current movement/cause/threshold/warning; firing typed event clears control atomically and routes to carousel, never old-team HQ. |
| 54 | Stakeholders | **Support dictionary only; no causal voices.** | Four authority-backed voices/stances, delta and concrete trigger/evidence; player actions affect rules; no invented named quotation/personality. |
| 55 | Promotion Decision | **Lower opportunity exists; CareerSession rejects it.** | Offer delivered before expiry; accept/decline/expiry each persist/event; accept enters pro session/UI safely; decline keeps college; stale offer removed. |
| 56 | Coaching Carousel | **Absent.** | College/pro openings, interest/applications/offers/declines; apply/accept and valid jobless advance; time stops at decisions; rehire/demotion; no dead screen. |
| 57 | Record Book | **Derived read model; no screen; categories shallow.** | Bounded college/pro team/player records with holder/opponent/date/game link; authoritative update only; survive rollover/reload. |
| 58 | Rivalries | **Engine-only.** Stringly meeting data prevents truthful map history. | Sides/origin/intensity trend/stakes/notable meetings from typed data; team/game links; qualifying result updates and persists. |
| 59 | Career Line | **Authority insufficient.** Job history lacks season performance; archive lacks per-team ledgers. | Per-coach season role/team/W-L/postseason/honours/defining moments across both tiers, bounded and linked. |
| 60 | Coaching Tree | **Derived model; no screen.** | Mentor/disciples backed by shared season/organisation/role and later head-coach transition; staff/career links; empty/large-tree AX states. |

### Offseason command

| # | Family | Current integrated-candidate state | Required functional acceptance |
|---:|---|---|---|
| 61 | College Offseason | **Systems mostly automatic; no command flow.** | One dated checklist across signing, postseason/spring portal, NIL, redshirts/position, staff, camp/discipline, roster legality and carousel; stop/acknowledge/resume every boundary. |
| 62 | Pro Offseason | **Engine phases/actions; completely unreachable.** | One dated cuts/contracts/FA/draft/staff/waiver/cap flow; stop on user turns/deadlines; legal final active/practice roster/cap; reload each phase; playable next season. |

## 6. Known dead, deceptive, or unsafe controls

These are confirmed functional defects, not polish:

- HQ Inspect, Delegate, and correspondence are wired to empty closures; “Opponent film” displays
  mandatory-decision reasons, not film.
- Roster Depth/Development/Staff routes are disabled; Review Development reaches an app no-op.
- Player Profile non-Overview tabs are disabled and recent form is always empty.
- Recruiting Contact/Evaluate/Visit/Offer inherit `isAvailable = true` even when points, slots, or
  phase make them invalid; rejection occurs only after the tap. “Weekly hours” are contact points,
  relationship history is always empty, and an empty board has no add/search escape.
- Roster, Recruiting, and League Map always enable Continue even when a mandatory decision is known;
  only HQ pre-disables it with a reason.
- Match Day's apparent controls only mutate DEBUG status text and never alter a live game.
- League Map markers hidden under another marker cannot be tapped; selection cannot open a profile.
- Successful restore bypasses save management; failed restore exposes destructive New Career.
- The inline Title is not named `TitleContinueView.swift`, so the filename-based accessibility gate
  does not inspect it. It declares neither AX composition nor VoiceOver order.

No enabled control may remain on the final build until its path is traced through intent, authority,
receipt, save, reload, and downstream consumer.

## 7. End-to-end acceptance journeys

All eight journeys are mandatory tests, not manual aspirations.

### E2E-A — Fresh install and first appointment

Settings → coach identity/world → three truthful starting jobs → offer accept/decline → appointment →
real first-week teaching → HQ. Verify cancel/back, AX5/VoiceOver, validation, reload, and no duplicate
appointment.

### E2E-B — Resume, migration, and recovery

Explicit save metadata/selection → restore the exact destination/task → complete an interrupted
action. Exercise current, previous, newer, corrupt-primary/valid-backup, both-corrupt, interrupted
write, protected-data, and low-storage states. No failed bytes are overwritten silently.

### E2E-C — Complete college week and controlled match

Inbox → film → Game Plan → Practice → Health/Depth/Roster → Recruiting → every mandatory decision →
resumable Match Day with player call-ins/control → Aftermath → standings/rankings/news/career deltas →
next week. Save/reload before and after every mutation.

### E2E-D — Complete college season and offseason

Recruit discovery/contact/visit/NIL/signing → postseason → postseason and spring portal retention and
market → redshirts/position/development → staff/poaching → camp/discipline → roster legality → next
season. Interrupt/reload at each dated boundary; no user decision auto-skips or applies twice.

### E2E-E — Career consequence and recovery

Support declines → warning → firing clears control → carousel → new appointment or valid jobless
advance. Repeat with resignation. History, stakeholder, news, control, and save all agree; old team is
never actionable.

### E2E-F — College-to-pro continuity

Receive a pro offer → decline path remains college → later accept path enters tier-neutral pro session
→ cap/contracts/cuts/scouting/draft/trades/FA/staff → legal roster → pro regular season → controlled
Match Day/Aftermath → firing/demotion carousel. Same coach and save throughout.

### E2E-G — World and history integrity

Open every map/search/standings/schedule/news/award/record/rivalry/career/tree link; complete rollover;
open them again. Trigger realignment and verify cause, before/after, schedule/rivalry effects and
acknowledgement. No stale or broken ID.

### E2E-H — 20+ season durability

Run both tiers and every major action class across 20+ seasons, promotion/demotion included. At
checkpoints verify save size/load/write, deterministic reload equality, bounded collections, no stale
opportunities/events, all screen families still operable, and physical-device latency/memory/thermal
budgets. Extend the history gate to 30 seasons.

## 8. Verification debt and executable release gates

### 8.1 Promised tests that do not exist as promised

The following exact commitments appear in `PRODUCT.md`, `docs/PRE-DEPLOYMENT-CHECKLIST.md`, or
`docs/06-AUDIT-DISPOSITION.md` but have no equivalent complete executable gate:

- `CommitmentCoverageTest`
- `ContrastByConstructionTest`
- `DynamicTypeContractTest`
- `ReduceMotionContractTest`
- `VoiceOverLabelTest`
- `TouchTargetTest`
- `AgencyBudgetTests`
- `PerformanceBudgetTests`
- `DeterminismTests`
- `TwoTierConsistencyTests`
- `ReachabilityTest`
- `ErrorSurfaceTest`
- `SmallestDeviceLayoutTest`
- `AccessibilityContractTests`
- `SaveOffMainActorTest`
- `SaveCoalescingTest`
- `SaveWriteBudgetTest`
- `SaveOpenIsReadOnlyTest`

Existing partial checks are not substitutes:

- `AccessibilityReflowTests` performs six source-string checks, prints missing families rather than
  failing, and cannot see rendered clipping/data loss.
- Touch checks find the minimum-target token, not the hit region of every control.
- Palette checks cover some generated colors but not every rendered surface/state.
- Determinism runs twice in one process or uses manually edited pins, not two independent launches.
- Calibration validates harness shape but does not require full tuning and holdout reports to pass.
- `HistoryGateTests` claims load timing but measures encode size/time only and never decodes.
- `scripts/verify.sh` omits manual M1/M2/M3, pro soak, 30-season history, and timing suites.
- The generated Xcode scheme has no testable UI/XCTest target.

### 8.2 Required test architecture

1. One orchestrated command from a clean clone builds SwiftPM Debug/Release and the iOS app for
   simulator, generic device, Analyze, and signed Archive.
2. Core suites include migration fixtures, two-process determinism, paired detailed/abstract
   calibration, college/pro action soaks, 30-season history, integrity and boundedness.
3. App XCTest/UI tests drive all 62 families and E2E-A–H with accessibility identifiers and injected
   deterministic worlds/failures.
4. Render tests retain screenshots and accessibility trees for every required state/configuration.
5. Physical-device jobs retain Instruments/performance/memory/thermal/energy artifacts.
6. Every result, archive, dSYM, privacy report, bundle inventory, and screenshot set names the same
   git SHA and toolchain.

## 9. Accessibility and device matrix

Every reachable state of all 62 families must be exercised at:

- 844×390 install floor, 852×393 promise floor, and 956×440 ceiling;
- both landscape sensor orientations and verified safe areas;
- light and dark;
- default Dynamic Type and AX5;
- Bold Text, Increase Contrast, Reduce Transparency, Differentiate Without Color, Reduce Motion;
- VoiceOver, Voice Control, and Switch Control;
- loading, empty, error, refused, disabled, delegated, confirmation, sheet, interruption, recovery,
  first-week teaching, and resumed state.

The gate fails on clipped or lost data, unreachable action, wrong semantic order, color-only meaning,
animation under Reduce Motion, invented progress, sub-44-point target, inaccessible custom control, or
focus loss after mutation/navigation. Match Day needs special proof because it fixes field height and
compresses its score line at AX sizes.

## 10. Packaging, privacy, legal, and TestFlight

- Track real icon artwork; the missing branch's asset catalog contains metadata only.
- Validate the privacy manifest against Apple's generated privacy report/required-reason scan. Do
  not merge an unproven file-timestamp rationale merely because it is written in the branch.
- Preserve the explicit offline/no-account/no-analytics/no-IAP product stance. Tester diagnostics
  must be opt-in and local/exported or use TestFlight's platform channels.
- Decide English-only beta explicitly; add a localization catalog or at minimum test locale, dynamic
  copy expansion, dates, numbers, currency, and plurals. Hard-coded copy is not localization proof.
- Review generated names, colors, assets, screenshots, listing copy, and dataset provenance; retain
  counsel/owner decisions. Existing legal tests do not cover screenshots/assets/statistical or
  biographical resemblance.
- Add pinned XcodeGen/toolchain, deterministic clean project generation, CI, sanitizers/concurrency,
  archive/export configuration, bundle ID/signing/provisioning, version/build/schema policy, symbols,
  privacy/export-compliance validation, support/privacy URLs, feedback email, and rollback policy.
- Run internal TestFlight smoke, then external beta with “what to test,” tester groups, crash/hang
  triage, save-compatibility warning policy, and owner walkthrough on a physical supported iPhone.
- Validate Swift 6 strict-concurrency readiness or explicitly retain the supported Swift language
  mode/toolchain; current package tools, package language mode, and app setting do not prove it.
- Replace shared fixed `/tmp` verification logs and machine-path-specific source-rewriting calibration
  with isolated, clean-tree-safe jobs.

## 11. Ordered implementation plan — no scope deferrals

Order is dependency management only. Every wave remains required for beta.

1. **Freeze and protect:** ratify this completion scope; preserve current owner work; add save
   fixtures/backups; repair packaging; establish clean reproducible build/test orchestration.
2. **Stabilize branch assets:** integrate landscape; extract migration-safe G-03; root-cause and stage
   missing-feature groups; resolve `PeopleState`; get one green integrated core baseline.
3. **Repair authority:** tier-neutral career/session/control, typed transitions, enforced weekly
   agenda, responsibilities/delegation, observer knowledge, sanctioned transactions, save ordering.
4. **Finish the college week:** entry/onboarding, HQ/Inbox/Film/Plan/Practice/Health/Roster/Staff and
   complete recruiting surfaces with real intents/receipts/states.
5. **Finish Match Day:** resumable side-correct session, all canonical coaching controls, actual
   participation/injuries, durable evidence, Aftermath and Game Detail.
6. **Finish college season/offseason:** signing, both portal windows, retention/market/NIL,
   development/redshirts, staff/camp/discipline, legality and carousel.
7. **Finish the career/pro tier:** player identity pipeline, promotion/demotion, all professional
   front-office screens/actions/AI, pro regular season and offseason, same live match loop.
8. **Finish world/legacy:** all competition, map/profile/search/news/realignment, career/history,
   records/rivalries/tree surfaces with rollover-stable links.
9. **Tune and bound:** two-tier calibration, deterministic independent-process proof, 20/30-season
   storage/history, physical-device performance/memory/thermal/frame work until budgets pass.
10. **Certify UI and ship:** all 62 rendered/state/accessibility matrices; legal/privacy/assets;
    signed archive; internal and external TestFlight acceptance on one final SHA.

## 12. Hard Definition of Done

The game is ready for beta testing only when all boxes below are true on one clean, reproducible,
signed commit:

- [ ] All three branch contributions have been deliberately integrated, rejected, or superseded;
  no red/incomplete branch suite or migration hazard remains.
- [ ] All STOP-01–STOP-10 defects are closed with regression tests.
- [ ] All SYS-01–SYS-17 acceptance criteria pass.
- [ ] All 62 families meet the section 1 functional contract; no DEBUG/sample-only, no-op, dead,
  deceptive, or post-tap-knowably-invalid control remains.
- [ ] E2E-A–H pass with save/reload and interruption at every safe boundary.
- [ ] College and professional weekly, match, postseason, offseason, carousel, promotion, demotion,
  firing, and jobless paths are playable without dead ends.
- [ ] Every displayed value and narrative has authority/provenance; fog-of-war is respected; every
  mutation has one receipt and one downstream application.
- [ ] Existing, migrated, corrupt, future, interrupted, and long-career saves are safe; a failed load
  can never silently destroy the last valid bytes.
- [ ] Debug/Release/app builds, all core/UI suites, two-process determinism, paired calibration,
  both-tier 20+ season soaks, 30-season history, and final integrity pass on the same SHA.
- [ ] The current hard latency, size, frame, memory, thermal, and launch/save budgets pass on the
  ratified physical device; no budget is waived by a stale status note.
- [ ] Every required device/accessibility/state rendering passes with retained screenshots and
  semantic trees.
- [ ] Clean generated project and signed archive contain only intended sources/resources; icon,
  privacy, legal, localization scope, metadata, support, symbols, and rollback policy are complete.
- [ ] The exact archive is installed through TestFlight and E2E-A–H are smoke-tested on a physical
  supported iPhone.

Until every applicable box is closed—or canon is explicitly amended before implementation to remove
a promise—the honest status remains **not ready for functional beta testing**.
