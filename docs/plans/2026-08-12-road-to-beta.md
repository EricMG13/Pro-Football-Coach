# Road to beta — the consolidated outstanding list

**Destination:** appended to the build plan (`docs/05-IMPLEMENTATION-PLAN.md`), which defers build
ordering to `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md`. This file aggregates every outstanding
item known on 2026-08-12 into one place so no thread is held only in a session transcript.

**Amended 2026-08-13** with the engagement-levers work, merged from
`claude/football-manager-game-psychology-gyldwl` onto the version on
`codex/fm-touch-personnel-examples` (`13731d2`). New: §3b, G-01a, V-7 to V-10. Changed: **§6d, two of
whose entries that work retired**; G-03, now built but to different rules than it specifies; §6c, now
holding a concrete first instance rather than a hypothetical one.

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
| B-1 | **There is no iOS app target that builds.** `App/project.yml` declares the app and `Sources/ProFootballCoachUI/` holds views, but the verified build is `swift build` of a SwiftPM package plus a headless test executable. Nothing in this session compiled an `.app`, and no session has. | **Unverified — never built as an app** | `03b` |
| B-2 | **No signing, bundle identifier, provisioning profile or TestFlight record exists**, and none can be created by an agent — it needs the owner's Apple Developer account. | Owner action, not started | `docs/PRE-DEPLOYMENT-CHECKLIST.md` |
| B-3 | **The UI is fixture-driven end to end.** `ScreenReadModels.swift` carries `CoachWorldSampleData` with provenance `sample`; `RootView` shows an unavailable state in RELEASE. A device build today shows sample data or nothing. | Gap G-01, not started | `03b` |
| B-4 | **Performance has never been measured on any device.** D4's budgets (2.0 s week advance, 16.7 ms frame) are stated and unmeasured. A beta is the first time they are tested, so they should be measured before it rather than discovered during it. | D4 open | `docs/OPEN-DECISIONS.md` |

**B-1 is the single largest unknown in this document.** Every other item assumes an app that runs;
this one asks whether it compiles as one. It should be settled first and cheaply, by the owner
opening the project and building to a device once, before any further feature work is scheduled.

---

## 1. Engine and model gaps

Carried from `docs/briefs/2026-08-12-gap-register.md`. Ordered by what blocks the most.

| # | Item | State | Blocks |
|---|---|---|---|
| G-01 | Truthful read-model providers per screen family; provenance flips `sample` to `simulationSnapshot` | Not started | Every truthful surface; B-3 |
| G-01a | *The inbox-first slice of G-01, specified 2026-08-13.* `Sources/ProFootballCoachUI` has **never imported `FootballSimCore`** and `simulationSnapshot` is never constructed anywhere. Needs: a `WeekDeskReadModel` built like `NewsFeedReadModel.build(from:)`; inbox ordering by **deadline then weight** (`PendingQueues` sorts by `id.uuidString`, so nothing leads it); `RootView.navigate`'s hard reject of `.inbox` removed; `onOpenCorrespondence` made to answer rather than set a status string; and **an answer intent — `CoachIntent` has seven cases and none answers a decision** | Not started | Makes E-2/E-3 reachable by a player at all |
| G-02 | Engine-owned verdicts: league-relative baselines, expectation deltas, sample and confidence, staff-voice attribution (owner: **named staff**) | Not started | Every `VerdictLine`; the density model's strongest technique |
| G-03 | Bounded per-player attribute-change record (bound: last 6, discarded on departure) | **Built as E-6, but to different rules — owner to reconcile.** Two deliberate divergences: the ring is retained **by significance, not chronology** (keeping the newest six fills it with the plateau every long career ends in and evicts the breakout), and it is **kept on departure, not discarded** (`PlayerDossierReadModel` treats a departed player as still having a dossier, since `02` §8 wants the coach to look up who they let go). If the original rules were load-bearing for `DeltaMark`, E-6 needs changing, not this row | `DeltaMark`; Player Profile truthfulness |
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
| P-2 | **Cap-compliance cuts (beat 2)** — owner decided cuts are forced by the compliance date and nothing else | **Blocked on an architectural fork — see §6** |
| P-3 | Full both-tier professional soak green | Red: fails in the college portal, see §3 |

---

## 3. Known defects, unresolved

| # | Defect | Evidence | Note |
|---|---|---|---|
| D-1 | **College portal postseason commit fails in the soak** — `portalCommitFailed(.postseason)` at season 0 week 21 | Reproduced repeatedly | Its own focused gate passes at 27,823 checks, so it is a soak-path defect. **Unattributed:** the experiment that would have separated "unmasked by the FSC-013 integrity fix" from "independent" was destroyed mid-run when its probe was deleted during cleanup. **Re-run that attribution before fixing anything.** |
| D-2 | **P4 match calibration holds 5–6 of 24 bands** | `docs/STATUS.md` | Model thinness — no per-drive accounting, thin run game — not constants. D2's falsifier has **not** fired and must not be counted against until per-drive accounting exists (`OPEN-DECISIONS` D2, amended 2026-08-12) |
| D-3 | **Save encode latency**, not size | 12.53 s at season 30 after compression | Size is solved (307 MB → 36 MB, `447f4b2`). Latency on device is untested and is a B-4 question |

---

## 3b. Engagement levers — written 2026-08-12/13, none of it verified

*Added 2026-08-13, from branch `claude/football-manager-game-psychology-gyldwl` (PR #6, draft).* A
deep-research brief scored the project against twelve FM retention levers; three were present, nine
were not. Canon landed first (`6dc10f6`), then four engine items (`a4e1d45`, `3efd313`).

**Read the state column literally. No Swift toolchain existed in the sessions that wrote this, so
none of it has been compiled and no test in it has run.** It is recorded the same way in
`docs/STATUS.md`. This is not green, not passing, not verified.

| # | Item | State |
|---|---|---|
| E-1 | Canon: `02` §2.4 session unit, §2.1 unanswered obligations and inbox-as-resting-state, §7 carousel floor, §8 player dossier; `03` §5.1 narrative-independence band; `04` §4.6; `CLAUDE.md` engagement-ethics guardrail | **Done** (`6dc10f6`), doc-only |
| E-2 | The game initiates — `newsAndNarrative` active, obligations raised inside the weekly transaction | Written, **never compiled** |
| E-3 | Advancing is always permitted — `IntentResolver`'s all-or-nothing gate removed, `expiringInboundEvents` active and answering elapsed obligations with the delegate's recommendation | Written, **never compiled**. Retires two entries in §6d |
| E-4 | Carousel exit — `.fired` → `.seeking`, firing releases the programme as well as the job, an offer is guaranteed | Written, **never compiled**. D8's *minimum floor only*, not the full carousel |
| E-5 | Scouting fog exposed as a band — `errorRadius` was computed and discarded | Written, **never compiled** |
| E-6 | Player dossier (`02` §8) — `PlayerDossierReadModel` projection, plus fog-at-signing and a significance-ranked six-beat development ring | Written, **never compiled**. **Supersedes G-03**, which asked for exactly this bound |
| E-7 | **The adversarial review `CLAUDE.md` §4 requires never ran.** A workflow was launched; all seventeen agents failed with terminal errors and returned nothing. It was stopped rather than left looking like coverage | **Outstanding. Phase 2 is not done until this runs** |
| E-8 | **`ArchitectureTests` determinism fingerprints are knowingly wrong.** Step one now emits events before every other step, so global sequences shift | **Must be repinned from two agreeing rebuilt runs** — never adjusted until green |
| E-9 | Unwritten tests: both-tier soak across the new steps; carousel-exit reachability over seeded careers (D8's floor, currently unasserted); save-size re-measurement for the dossier ring | Not started |
| E-10 | `PlayerDossierTests` written and registered, **never executed** | Blocked on a toolchain |

**E-8 and V-1 are the same shape of problem** and should be settled in one sitting: the suite has not
been run since `0deb629`, and part of it is now expected to fail for a known reason.

**Two consequences that land outside this table.** The new `DomainEventPayload` cases change the
encoded root, so every existing save is expected to be unreadable — see §6c, which this makes
concrete rather than hypothetical. And E-6's ring is the only new save-growth term: six beats across
~13,000 players, which is what D-3 should be re-measured against.

---

## 4. Design system and UI

| # | Item | State |
|---|---|---|
| U-1 | The eight `*-v3.dc.html` reference sheets, owner-approved, review findings applied | **Done** |
| U-2 | `04` §6.1/§6.2 token values with measured ratios; §4.5 density budget; §6.5 registry; §6.6 symbol register | **Done** |
| U-3 | M8 entry-gate tests — orientation, token sync, symbol register, sheet lint | **Done** (`11b9f8e`) |
| U-4 | **G-12 AX5 reflow contract test**, enumerating families from the registry by construction | **Not done** — plan written 2026-08-13, `docs/plans/2026-08-13-p11a-entry-gate-remainder.md` Task 2 |
| U-5 | G-13 failure-set views (designs exist on `failure-v3`; view implementations do not) | Not started |
| U-6 | Production views built against the sheets, per family | Not started (P11–P15 / M8) |
| U-7 | Light-primary team colours unreachable from the generator; card contract uses a labelled synthetic pair | Open against P2 |
| U-8 | **G-09's `SmallestDeviceLayoutTest` does not exist.** U-3 reads as if the whole entry gate landed; `05` P11a names G-09's test half as *two* instruments — `OrientationPolicyTest`, which is green, and the two-tier install-floor/promise-floor layout test, which was never written and which no grep finds | **Not done** — same plan, Task 1 |
| U-9 | **Nineteen of the 23 `04` §6.5 registry entries have no Swift type.** Only `CoachWorldRouteButton`, `CoachWorldActionButtonStyle`, `CoachWorldBlankPhotoPlate` and the `coachWorldDeskSurface` modifier exist; the rest are inlined across the five shipped views. §6.5 already calls the extraction P11/M8 work | **Not started — and it gates U-6.** Every element in §4b lands on one of these types |
| U-10 | Sample-driven design build — the harvested element set from §4b, deployed into the extracted types | Not started, blocked on U-9 |

---

## 4b. Sample-driven design build

*Added 2026-08-13.* Five generative design tools were run or supplied against the approved sheets to
build a pool of alternatives, then reviewed for what actually deploys. Full workings:
`docs/briefs/2026-08-13-stitch-composition-harvest.md`,
`docs/briefs/2026-08-13-uxpilot-sample-review.md`,
`docs/briefs/2026-08-13-sample-pool-deployment-review.md`; artefacts in
`docs/proofs/stitch-2026-08-13/` and `docs/proofs/figma-pool-2026-08-13/`.

**Those paths, and `docs/plans/2026-08-13-p11a-entry-gate-remainder.md`, live on branch
`claude/google-stitch-proofs-redesign-7b6640` until it merges.** They are referenced here by their
post-merge paths so this list does not need rewriting; until then, read them there.

| Source | Yield | State |
|---|---|---|
| Google Stitch (MCP) | 8 boards, one per v3 sheet; 3 of 8 failed on density, appearance or legibility | Harvested, 24 ideas kept |
| Figma (MCP) | 60 variables bound to exact `04` §6.1 values; 12 treatment variants over registry 7, 12, 13 | Built, awaiting a pick per board |
| UX Pilot | 2 Match Day samples | Reviewed; 7 ideas kept |
| Banani | 6 screens **and 12 named components**, ten matching our registry vocabulary | Reviewed; the most deployable artefact of the five |
| Visily | 2 boards | **Not cleared — see S-3** |

**The deployable set, summarised.** Twenty elements land on existing or extractable registry types;
five are new objects with no entry. Highest-value: the world strip carrying the **next fixture
inline** (`vs … · Sat 14:30 → Continue`), the verdict line as a **24 pt band** rather than a card,
the shipping/target verdict forms at **shared geometry**, confidence as **fill width plus printed
observation count**, and selection as **boundary plus leading bar plus spoken word**. Two new
registry entries are proposed: a **drive summary strip** and a **pressure gauge**.

| # | Item | State |
|---|---|---|
| S-1 | `04` amendments for the six items that need canon before they are drawn — shared verdict geometry, over-capacity as a shape difference, reclaimable delegation, and the two new registry entries | Not started; doc-first rule makes this precede any view work |
| S-2 | Adopt the Banani copy as the commentary, call-in and staff-note exemplars | Not started, cheap, no code |
| S-3 | **Visily is not cleared.** Board `2692030` would not render for review at all. On `2692031` the standings appear to hold real NFL clubs — read at 50 % zoom, flagged rather than confirmed. Owner to open at full zoom and confirm or clear | **Blocking on that board only.** If confirmed, discard both and record it |
| S-4 | Re-render the affected v3 sheets from amended canon **by hand** — not regenerated from any of these tools | Not started, follows S-1 |

**The finding worth carrying beyond this list.** Three tools out of three reached for real football
identities unprompted: Stitch assumed a networked product, UX Pilot printed `NFL` in a panel header,
Visily appears to have populated a league with real clubs. **A real-mark scan is now the mandatory
first step on any externally-generated sample, before anyone reviews the design.** The name-collision
test is the authority, not a reviewer's eye.

Second finding: the cleaner UX Pilot sample had **no coach controls at all** — a spectator broadcast.
Asked for a football match screen, a generative tool produces a broadcast, because broadcasts are
what it has seen. The shaping is the whole product, so "what does the coach do on this screen, and
where is it?" is now a standing review question for any Match Day work.

---

## 5. Verification and hygiene

| # | Item | State |
|---|---|---|
| V-1 | **The full suite has not been run since `0deb629`.** Focused gates were run and are green: `--pro-draft-probe`, `--roster-population` (8 / 147,551), `--architecture-only` (25 / 222, twice independently) | **Outstanding — run before any release claim** |
| V-2 | Repo-wide confidence review and rewrite tournament | Deferred to final shipping by the roadmap |
| V-3 | Sourcing row Q9 (competitor field orientation) — owner answers by opening the app rather than by retrieval | Open |
| V-4 | iPhone 16e landscape insets and the 17e entirely — unsourced, recorded as gaps, never guessed | Open |
| V-5 | AS-6.5-13 minimum discriminable mark size — literature not obtained (403s); distance anchor verified at 36.2 cm | Partial |
| V-6 | Owner simulator walkthrough script | Not written |
| V-7 | **`PRODUCT.md`'s commitment table names eleven tests and none of them exists** — including `CommitmentCoverageTest`, the instrument whose whole purpose is catching that. The machinery is already there: `DesignContractTests.swift:23-55` parses a canon Markdown table at run time, `ContractTests.swift:20` resolves the repo root, `:28` walks the corpus. Build it, let it fail, then correct the table | **Not started.** A pre-deployment checklist item that cannot currently be ticked |
| V-8 | **A test suite can silently never run.** `Tests/SimTests/main.swift` is a hand-maintained if/else chain; a suite absent from the default branch is skipped and nothing notices. Assert that every `run*Tests` symbol in the corpus is called | **Not started.** The coverage-boundary defect `CLAUDE.md` names, applied to the harness itself |
| V-9 | **The one assertable engagement-ethics limb** (`03` §5.1) — margin distribution TOST-equivalent across favoured / underdog / losing-streak, comparing the three estimates to each other rather than each to a fixed band. Needs a margin band (`"average margin by context"` is in `unimplementedMetrics`, and is also a §6b row), binning, and `public` on `CalibrationHarness.measure` and `SampledGame` | **Not started.** Say in the test name that it **passes by construction today** — the engine takes no narrative input. It is a tripwire against a future drama term, not a discovery |
| V-10 | **`04` §6.5 registry enforcement.** The table was corrected on 2026-08-12 to mark 19 of 23 unbuilt (it had claimed all 23 mapped 1:1, with an enforcement that did not exist). Nothing keeps it honest as U-9 extracts the types — copy the §6.6 symbol-register pattern | **Not started**, and it should land *with* U-9, not after |

---

## 6. Owner decisions outstanding

| # | Decision | Recommendation |
|---|---|---|
| O-1 | **The cap invariant.** Beat 2 presumes a team *can* be over the cap until a date. The engine forbids it: `acquire` refuses anything that would exceed the cap, and `release` validates the whole root, so an over-cap team could not take its first step back. Either (a) accept the cap as structural and rewrite beat 2 as a continuously-enforced constraint, or (b) make temporary illegality representable inside a bounded window. | **(b), scoped to the week-21 boundary** — opened by expiry, closed by compliance in the same `advanceWeek`, so no *persisted* root is ever illegal and the cap-laundering defence in `PORT-LOG.md` stays intact. `enforceCapCompliance` is written and correct for (b); under (a) it is dead code and should be deleted, not left looking load-bearing |
| O-2 | Whether to schedule per-drive accounting now (unblocks D-2) or after M8 | After M8. It is a change to the core loop every calibration number is measured against; doing it beside other engine work makes a red band impossible to attribute |
| O-3 | B-2 signing and TestFlight setup | Owner-only; cannot be delegated |

---

## 6b. Calibration, sorted by what each row waits on

D-2 counts 5–6 of 24 bands. `01` §6.5 lists **16 further rows unmeasured**, and they are not one
problem — a plan that treats them as one will mis-size the work:

| Waiting on | Rows | Size |
|---|---|---|
| Harness aggregation | points per drive | **Done** (`fe12fac`) — `DriveRecord` always carried `pointsScored`; the harness never summed it. **Unmeasured**: the run was stopped before it reported |
| Play-length accounting | TD 40+ yards, FG% 50+ yards | Small — `PlayRecord` has outcomes, needs distance buckets |
| Per-player stat lines | TE / RB / max receiver target share | Real engine work — this is G-11 |
| Overtime | overtime rate, college tie rate, OT settled in one period | P6 |
| Schedule context | best-vs-worst, blowout by context (×2), margin by context, title-capable share | P6 |
| Binned distribution | modal combined total | Needs the TVD shape check |
| **Deliberately unset in canon** | college completion %, pass/rush yards, sacks, INTs, points per drive | `01` §4.9 — **not work.** Canon declines to guess; do not count these as a gap |

## 6c. A beta consequence of having no migration table

Schema is **11**, and `GameState` refuses every version but the current one — there is no migration
path and none is planned before M9. **Any schema bump destroys every tester's save.** So either the
schema is frozen before testers install, or the migration table is built first. This is cheap to
decide now and expensive to discover from a tester.

**This stopped being hypothetical on 2026-08-12.** E-3's new `DomainEventPayload` career cases change
the encoded root, so **existing saves are already expected to be unreadable**, and the schema version
was deliberately *not* bumped pending this decision. Nothing has shipped, so nothing is lost yet —
but the decision now has a concrete first instance rather than a future one, and it should be taken
before a tester ever installs. (E-6's two additions decode with `decodeIfPresent` and are
backward-compatible on their own; it is the event payloads that break the root.)

## 6d. What is not a gap — and two entries overtaken on 2026-08-13

- **`userGame` is the only genuinely inactive scheduler step.** Still true, and still unbuilt work.

> **The two entries that stood here have been overtaken by the engagement-levers work in §3b, and are
> kept rather than deleted because the reasoning that retired them is the useful part.** Both were
> correct when written. Neither is now.
>
> - *"Pending-decision deadlines cannot pass, because `advanceWeek` refuses while any decision is
>   unresolved."* **That gate no longer exists** (`a4e1d45`). Deadlines can now elapse, and the
>   invariant is held by `expiringInboundEvents` answering them with the delegate's recommendation
>   before integrity runs. The integrity rule survives unchanged; what changed is *what keeps it
>   true*. A reader who acts on the old note will conclude a save cannot wedge for a reason that has
>   been removed.
> - *"`newsAndNarrative` and `expiringInboundEvents` have nothing to do, because there is no inbox
>   state in the engine."* **Both steps are now active.** The premise was accurate and is what the
>   work changed: obligations are now raised *inside* the weekly transaction rather than by
>   `CareerSession` after it returned, which is the mechanical reason `01` §6.0 could previously
>   count zero inbound events.
>
> News being a derived projection, and `02` §4.2b forbidding persisted prose, both still hold — the
> news half of `newsAndNarrative` remains a projection. It is the obligations half that is new.

---

## 7. Suggested order to beta

1. **Settle B-1** — build the app to a device once. Cheapest possible answer to the largest unknown.
2. **V-1, with E-8 and E-7** — full suite green on the current branch. These three belong in one
   sitting: the suite has not been run since `0deb629`, part of it is now *expected* to fail for a
   known reason (E-8's fingerprints), and E-7's review is owed on the same diff. Repin from two
   agreeing rebuilt runs; do not adjust a fingerprint until it goes green.
3. **G-01**, starting with **G-01a** — read-model providers, so a device build shows the world rather
   than fixtures. The inbox slice first: it is the smallest end-to-end proof that the seam works, and
   E-2/E-3 are unreachable by a player without it.
4. **U-4 and U-8** — both remaining M8 entry-gate instruments, planned in
   `docs/plans/2026-08-13-p11a-entry-gate-remainder.md`. Then the M8 gate opens. U-8 was believed
   done and is not, which is why it is named here rather than left inside U-3.
5. **U-9** — extract the nineteen inlined registry types. Nothing in U-6 or U-10 can be deployed
   cleanly before this: today the same element has to be hand-edited into up to five screen files,
   which is the coverage-boundary failure applied to components.
6. **S-1** — the `04` amendments the harvested elements need, doc-first.
7. **U-6 and U-10** — production views per family against the approved sheets, with the harvested
   element set deployed into the extracted types.
8. **B-4** — measure D4's budgets on the device that will run the beta.
9. **D-1** — the portal soak defect, after re-running its attribution.
10. **O-1**, then **P-2** — the compliance beat, once the invariant question is settled.
11. **B-2** — signing and TestFlight, owner action, in parallel with 3–7.
12. **Beta on a real iPhone.**

**S-3 is not in this order because it is not on the path** — it is a five-minute owner check that
either clears the Visily board or discards it. Do it whenever, but do it before anything is prompted
from or copied out of that board.

**Neither is §6c, and it is the one that bites hardest if left.** Freezing the schema or building the
migration table is a decision, not a task, and it costs nothing today — but E-3 has already made the
first breaking change, so the answer is needed before a tester installs rather than after.

**V-7 through V-10 are not on the critical path to a device, and should not be deferred past it
either.** Each closes a case of the repository claiming a test it does not have, which is the
specific failure `CLAUDE.md` treats as worse than the missing test.

Items in §1 beyond G-01 are what make the surfaces *truthful* rather than merely present; a beta can
begin without all of them, provided every surface that lacks its engine backing ships without the
claim rather than with an invented one — which `04` §4.4 and §6.5 already require.
