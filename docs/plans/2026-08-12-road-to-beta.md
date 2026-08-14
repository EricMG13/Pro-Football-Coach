# Road to beta — the consolidated outstanding list

**Destination:** appended to the build plan (`docs/05-IMPLEMENTATION-PLAN.md`), which defers build
ordering to `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md`. This file aggregates every outstanding
item known on 2026-08-12 into one place so no thread is held only in a session transcript.

> **Execution log, 2026-08-13 (branch `claude/road-to-beta-plan-40e904`).** Items 1, 2, 3, 4 and 7
> of §7's suggested order were worked, in that order, by a session that had a full Xcode 26.6 /
> Swift 6.3.3 toolchain — the first in this rebuild to have one. Status is marked inline below and
> the account is `docs/STATUS.md` under *2026-08-13 — the road to beta*. The two owner-only items
> (B-2, device measurement) are written up as `docs/OWNER-WALKTHROUGH.md`.

**Definition of complete, owner-stated 2026-08-12: a beta test on a real iPhone.** Not a simulator
run, not a green suite — the game installed on the owner's device through TestFlight and played.
Everything below is ordered by what stands between the build and that.

Two standing rules this list inherits. An agent asserts a machine gate only by having run it in the
session that claims it (`CLAUDE.md`, D11). Simulator and device demonstration are **owner** actions:
an agent writes the walkthrough and never claims it happened.

---

## 0. What already blocks the device, before any feature

These are the items without which "install it on a phone" is not a meaningful instruction. Nothing
below this section matters until these are true.

| # | Item | State | Owner doc |
|---|---|---|---|
| B-1 | **Answered 2026-08-13: it builds.** Debug and Release for the iPhone 17 simulator, and the arm64 device slice unsigned; installed, launched and photographed. Signing (B-2) is now the only thing between this and a phone. Original text: **There is no iOS app target that builds.** `App/project.yml` declares the app and `Sources/ProFootballCoachUI/` holds views, but the verified build is `swift build` of a SwiftPM package plus a headless test executable. Nothing in this session compiled an `.app`, and no session has. | **Built, run and photographed on the simulator; never on a phone** | `03b` |
| B-2 | **No signing, bundle identifier, provisioning profile or TestFlight record exists**, and none can be created by an agent — it needs the owner's Apple Developer account. | Owner action, not started | `docs/PRE-DEPLOYMENT-CHECKLIST.md` |
| B-3 | **Closed 2026-08-13 for Coaching HQ by G-01; open for every other family.** Original text: **The UI is fixture-driven end to end.** `ScreenReadModels.swift` carries `CoachWorldSampleData` with provenance `sample`; `RootView` shows an unavailable state in RELEASE. A device build today shows sample data or nothing. | Coaching HQ truthful; other families still fixture-only | `03b` |
| B-4 | **Measured on the host, 2026-08-13, and D4's week-advance budget is already blown there.** `--week-advance-timing`: median **2.83 s/week** against a 2.0 s budget, worst **29.6 s** at the season boundary, and **1.01 s** of every week is one whole-root integrity check over 15,766 players. The falsifier does not need a phone to fire. Frame time (16.7 ms) is still unmeasured and needs a device and Instruments | **D4 falsified on the host; device still unmeasured** | `docs/OPEN-DECISIONS.md` |

**B-1 is the single largest unknown in this document.** Every other item assumes an app that runs;
this one asks whether it compiles as one. It should be settled first and cheaply, by the owner
opening the project and building to a device once, before any further feature work is scheduled.

---

## 1. Engine and model gaps

Carried from `docs/briefs/2026-08-12-gap-register.md`. Ordered by what blocks the most.

| # | Item | State | Blocks |
|---|---|---|---|
| G-01 | Truthful read-model providers per screen family; provenance flips `sample` to `simulationSnapshot` | **Coaching HQ, Roster, Player Profile and Recruiting Board done**, via the `CoachWorldApp` composition target, and all four reachable in the shipped app. Match Day still needs G-06/G-11; the other 56 families need views before they need providers | Every truthful surface; B-3 |
| G-02 | Engine-owned verdicts: league-relative baselines, expectation deltas, sample and confidence, staff-voice attribution (owner: **named staff**) | Not started | Every `VerdictLine`; the density model's strongest technique |
| G-16 | **Jersey numbers.** Found 2026-08-13 while writing G-01's providers, and **closed the same day** — as a roster-scoped *derivation* rather than the schema change first assumed. Uniqueness belongs to a team and a player changes teams, so a stored field would need reassignment on every transfer, draft pick and walk-on; derived, it holds by construction with no schema bump and no fingerprint re-pin. `02` §4.1a states the rule; uniqueness is **per unit**, because 105 college players do not fit in 100 numbers | **Done** (`JerseyNumbers`, `--jersey-numbers`) | Unblocked Roster and Player Profile; box score and match-day actors can now read it |
| G-03 | Bounded per-player attribute-change record (bound: last 6, discarded on departure) | Not started | `DeltaMark`; Player Profile truthfulness |
| G-04 | Per-player form series and an engine-owned player-game rating definition | Not started | `FormLine`; recent-form surfaces |
| G-05 | Opponent-preparation knowledge boundary with graded confidence | Partial — prospect/portal/draft fog exists; opponent open (FSC-007) | Opponent Report density |
| G-06 | Match animation anchor stream (FSC-011) | Not started | P13 Match Day; broadcast live depictions |
| G-10 | Throughput primitives — filter, bounded search, multi-select over simulation objects | Sorting only exists | Market, board and standings families at scale |
| G-11 | Detailed-match per-player stat lines | Abstract model has them; detailed engine does not | Box score; played-match verdicts; P4 band coverage |
| G-14 | Engine-owned load policy: condition bands, dose multipliers, derived cost | Not started | Practice Plan derived-cost region |
| G-15 | Partial-advance completion record | Not started | Truthful interrupted-state copy |

---

## 2. The professional tier

| # | Item | State |
|---|---|---|
| P-1 | **Bootstrap contracts** — terms rotate 1–5, ~a fifth expires per season, cap-legal by allocation | **Done** (`0deb629`). Measured: 327 expiries, ledger 327/512, first draft pick succeeds |
| P-2 | **Cap-compliance cuts (beat 2)** — owner decided cuts are forced by the compliance date and nothing else | **AI-facing half done, 2026-08-13** (`ProManagementSystem.enforceCapCompliance`, wired into the week-21 boundary, `docs/superpowers/plans/2026-08-13-cap-compliance.md`). Correct and tested against hand-built fixtures — five unit tests plus one real `advanceWeek` integration test, all passing; the architecture fingerprint pins are unchanged, confirming it is a true no-op under normal generation. `WorldIntegrity.checkProfessionalCap` was never touched, only a step that runs before it. Has no reachable trigger under current generation (`acquire` still refuses any over-cap signing, so no team is ever actually over cap to force-release). The controlled team's own mandatory-decision path is explicit remaining work — see `02` §4.2a |
| P-3 | Full both-tier professional soak green | The season-boundary blocker is fixed (`fce9e2a`); the soak itself is not re-measured in that session |

---

## 3. Known defects, unresolved

| # | Defect | Evidence | Note |
|---|---|---|---|
| D-1 | **Attributed and fixed, 2026-08-13** (`fce9e2a`) | `--pro-market-root-probe`, kept in the tree | **It was never a portal defect and never the cap fork.** Attribution first, as required: the portal commit checks the root *projected into the next season*, and professional contracts whose term had run out were still attached to players, so the cap invariant refused them. Zero teams were over the cap. It was masked by a second defect — contract expiry ran before `SeasonLifecycleSystem` wrote the career records FSC-013 needs — which aborted the same week earlier in the step. Both were latent until `0deb629` made a world issue contracts at all |
| D-2 | **P4 match calibration holds 5–6 of 24 bands** | `docs/STATUS.md` | Model thinness — no per-drive accounting, thin run game — not constants. D2's falsifier has **not** fired and must not be counted against until per-drive accounting exists (`OPEN-DECISIONS` D2, amended 2026-08-12) |
| D-3 | **Save encode latency**, not size | 12.53 s at season 30 after compression | Size is solved (307 MB → 36 MB, `447f4b2`). Latency on device is untested and is a B-4 question. Note the app autosaves after every intent, so this compounds with B-4's week cost rather than being separate from it |
| D-4 | **A whole-root integrity check costs 1.01 s** and `saveGrowthAndIntegrity` runs one every week | `--week-advance-timing`, 2026-08-13 | Discovered while measuring B-4. This alone is half the week-advance budget, so D4 cannot be met by tuning around it — it is a question about how often the whole root must be checked, and belongs to `03b` §5 |

---

## 4. Design system and UI

| # | Item | State |
|---|---|---|
| U-1 | The eight `*-v3.dc.html` reference sheets, owner-approved, review findings applied | **Done** |
| U-2 | `04` §6.1/§6.2 token values with measured ratios; §4.5 density budget; §6.5 registry; §6.6 symbol register | **Done** |
| U-3 | M8 entry-gate tests — orientation, token sync, symbol register, sheet lint | **Done** (`11b9f8e`) |
| U-4 | **G-12 AX5 reflow contract test**, enumerating families from the registry by construction | **Enumeration limb done 2026-08-13**; all 62 families resolved from `CoachWorldScreenID`, partition asserted total, landed families required to declare an AX5 composition and VoiceOver order. **The rendered limb stays open** — this harness has no view host, and `04` §7.1 says so rather than letting the gate read as more than it is |
| U-5 | G-13 failure-set views (designs exist on `failure-v3`; view implementations do not) | Not started |
| U-6 | Production views built against the sheets, per family | **Started 2026-08-13**: League Map (family 41) landed and wired to the shipped `League` route, with a read model, provider and its own contract-suite assertions (`docs/superpowers/plans/2026-08-13-league-map.md`). 56 of 62 families remain, each real UI-system work behind its own `writing-plans` pass, not a freehand continuation |
| U-7 | Light-primary team colours unreachable from the generator; card contract uses a labelled synthetic pair | Open against P2 |

---

## 5. Verification and hygiene

| # | Item | State |
|---|---|---|
| V-1 | **Run on 2026-08-13. It was red**, and the reason is D-1's two defects above. Fixed, and re-run. Two coverage holes found while there: the no-argument suite never included `DesignContractTests` at all, and the harness fully buffers stdout down a pipe so the aborted run reported two lines instead of twenty passing suites | Fixed and re-run; see `docs/STATUS.md` |
| V-2 | Repo-wide confidence review and rewrite tournament | Deferred to final shipping by the roadmap |
| V-3 | Sourcing row Q9 (competitor field orientation) — owner answers by opening the app rather than by retrieval | Open |
| V-4 | iPhone 16e landscape insets and the 17e entirely — unsourced, recorded as gaps, never guessed | Open |
| V-5 | AS-6.5-13 minimum discriminable mark size — literature not obtained (403s); distance anchor verified at 36.2 cm | Partial |
| V-6 | Owner simulator walkthrough script | **Written**: `docs/OWNER-WALKTHROUGH.md`, from a run that actually happened |

---

## 6. Owner decisions outstanding

| # | Decision | Recommendation |
|---|---|---|
| O-1 | **Reframed by evidence, 2026-08-13.** The fork was posed on the assumption that teams go over the cap at the season boundary. They do not: `--pro-market-root-probe` reports **zero over-cap teams** against eleven whose contracts had merely outlived their term, and fixing that removed the whole symptom. The fork is therefore not blocking, and the live question is narrower — whether beat 2 has anything to do at all until free agency and the draft put a team over. Original text: **The cap invariant.** Beat 2 presumes a team *can* be over the cap until a date. The engine forbids it: `acquire` refuses anything that would exceed the cap, and `release` validates the whole root, so an over-cap team could not take its first step back. Either (a) accept the cap as structural and rewrite beat 2 as a continuously-enforced constraint, or (b) make temporary illegality representable inside a bounded window. | **(b), scoped to the week-21 boundary** — opened by expiry, closed by compliance in the same `advanceWeek`, so no *persisted* root is ever illegal and the cap-laundering defence in `PORT-LOG.md` stays intact. **Correction, 2026-08-13: `enforceCapCompliance` does not exist anywhere in this tree.** `grep -rn enforceCapCompliance Sources/` returns nothing; the claim that it is "written and correct" traced only to `docs/plans/2026-08-12-m6-roster-turnover.md`, a planning document, not to code. Beat 2 is unbuilt: `acquire` still refuses anything that would exceed the cap, so a team cannot yet take the first step (b) requires — over-cap signing — let alone be brought back under one. This is real engine work, not a wiring gap, and belongs behind its own `superpowers:writing-plans` phase like any other milestone slice, not a freehand continuation. **The forcing half of (b) is now built** — see the P-2 row above and `02` §4.2a. The invariant itself (`WorldIntegrity.checkProfessionalCap`) was never touched; only a function that runs before it was added |
| O-2 | Whether to schedule per-drive accounting now (unblocks D-2) or after M8 | After M8. It is a change to the core loop every calibration number is measured against; doing it beside other engine work makes a red band impossible to attribute |
| O-3 | B-2 signing and TestFlight setup | Owner-only; cannot be delegated |
| O-4 | **Career Hub's chronology, found blocking U-6 2026-08-13.** Four families (52 Career Hub, 53 Job Security, 54 Stakeholders, 55 Promotion Decision) all need a career-arc history the engine does not keep: `CareerArcState.jobHistory` is empty until a firing/promotion/resignation, no season retains the coach's own W-L past a rollover, `DomainEventPayload` has no hired/fired/promoted/resigned case at all, and `CareerSession.resolve` throws on `.acceptOpportunity` so the promotion arc has no reachable path through the actor the shipped app uses. Full account in `docs/STATUS.md`'s 2026-08-13 League Map entry. This is milestone-sized engine and canon work — a career-arc domain event, per-season record retention, and the promotion-accept path — not a view-layer gap | Scope as its own milestone slice behind `superpowers:writing-plans`, decided before any of the four dependent families is attempted. Recommend after U-6's remaining independently-buildable families (League Map's pattern — engine truth already sufficient) are exhausted, since those return working screens sooner |

---

## 7. Suggested order to beta

1. **Settle B-1** — build the app to a device once. Cheapest possible answer to the largest unknown.
   **Done, 2026-08-13:** builds and runs on the iPhone 17 simulator, Debug and Release; the device
   arm64 slice builds unsigned. Never run on a phone — that step is B-2's, owner-only.
2. **V-1** — full suite green on the current branch. **Done, 2026-08-13**, after five pre-existing
   `0deb629` failures and one process-killing crash were found and fixed (`docs/STATUS.md` carries
   the account) — `729` tests, `756,466` checks at last measurement, no known regressions.
3. **G-01** — read-model providers, so a device build shows the world rather than fixtures. **Done
   for four of five already-built screens** — Coaching HQ, Roster, Player Profile, Recruiting
   Board — all reachable and truthful in the shipped app. Match Day is still blocked on G-06/G-11,
   real unbuilt engine features, not a wiring gap.
4. **U-4** — the last M8 entry-gate instrument, then the M8 gate opens. **Enumeration limb done,
   2026-08-13**; the rendered limb (no datum lost, no clipping) stays open — this harness has no
   view host, `04` §7.1 says so, and its mechanism is `03b` §5's to decide.
5. **U-6** — production views per family, against the approved sheets. **Started 2026-08-13**: League
   Map (family 41) landed. 56 of 62 families still have no view. Each is real UI-system work — sheet
   fidelity, the accessibility contract, AX5, adversarial review — and belongs behind its own
   `superpowers:writing-plans` pass per `CLAUDE.md`'s process, not a freehand continuation. Four of
   the 56 (Career Hub, Job Security, Stakeholders, Promotion Decision) are blocked on engine work
   named at O-4 and cannot be attempted as view-only slices. This is
   the largest remaining item on the road to beta.
6. **B-4** — measure D4's budgets on the device that will run the beta. **Measured on the host,
   2026-08-13, and already falsified there**: median week advance 2.83 s against a 2.0 s budget,
   worst 29.6 s at the season boundary. Frame time and the on-device number are still the owner's.
7. **D-1** — the portal soak defect, after re-running its attribution. **Done, 2026-08-13.** It was
   never a portal defect: contract expiry ran before the season wrote the career records FSC-013
   needs, and the "last body at a position" exemption kept an expired contract attached instead of
   re-signing. Fixed; `--season-rollover` pins the invariant.
8. **O-1**, then **P-2** — the compliance beat. **O-1 reframed, not answered**: the fork was posed
   on the assumption teams go over the cap at the season boundary, and the probe shows zero ever
   do. **P-2's AI-facing half is done, 2026-08-13** (`enforceCapCompliance`, via its own
   `writing-plans`/`executing-plans` phase per `docs/superpowers/plans/2026-08-13-cap-compliance.md`
   — the earlier claim that it already existed was false and is corrected in §6). The
   controlled-team half remains a mandatory-decision surface, not yet designed.
9. **B-2** — signing and TestFlight, owner action, in parallel with 3–6. **Not started; cannot be
   started by an agent.**
10. **Beta on a real iPhone.** **Not reached.** Everything an agent could verify without a device or
    a signing certificate has been verified. `docs/OWNER-WALKTHROUGH.md` is the handoff.

Items in §1 beyond G-01 are what make the surfaces *truthful* rather than merely present; a beta can
begin without all of them, provided every surface that lacks its engine backing ships without the
claim rather than with an invented one — which `04` §4.4 and §6.5 already require.


## 8. Recruiting Board wired, and a false gap caught the same day

The Recruiting Board provider is done and every field on it is real, including
`Capacity.weeklyHoursRemaining`/`officialVisitsRemaining` — read from
`ProgrammeRecruitingState.contactPointsRemaining` (a genuine weekly-reset resource, 100 points,
reset by `WorldScheduler`) and a derived visit count from the same pool. Confirmed live on the
simulator: `HOURS 100h`, `VISITS 3` at week one, moving when `Contact` resolves.

**This section briefly recorded a "G-18: recruiting weekly capacity" gap that did not exist.** A
search for the resource by name missed `contactPointsRemaining`, and the provider shipped the two
fields as `Int?` with a "not built" note for part of this session. Wrong, and corrected the same
day once a closer read of `CollegeState.swift` found the real resource — `02` §4.3 carries the full
account, including the correction itself. No gap number is spent on it: it was never a real gap, so
G-18 is not reserved and the next one issued should be G-18.
