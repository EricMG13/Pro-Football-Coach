# Road to beta — the consolidated outstanding list

**Destination:** appended to the build plan (`docs/05-IMPLEMENTATION-PLAN.md`), which defers build
ordering to `docs/roadmap/06-BUILD-ROADMAP-AND-GATES.md`. This file aggregates every outstanding
item known on 2026-08-12 into one place so no thread is held only in a session transcript.

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
| G-02 | Engine-owned verdicts: league-relative baselines, expectation deltas, sample and confidence, staff-voice attribution (owner: **named staff**) | Not started | Every `VerdictLine`; the density model's strongest technique |
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

## 4. Design system and UI

| # | Item | State |
|---|---|---|
| U-1 | The eight `*-v3.dc.html` reference sheets, owner-approved, review findings applied | **Done** |
| U-2 | `04` §6.1/§6.2 token values with measured ratios; §4.5 density budget; §6.5 registry; §6.6 symbol register | **Done** |
| U-3 | M8 entry-gate tests — orientation, token sync, symbol register, sheet lint | **Done** (`11b9f8e`) |
| U-4 | **G-12 AX5 reflow contract test**, enumerating families from the registry by construction | **Not done** — the one entry-gate instrument still missing |
| U-5 | G-13 failure-set views (designs exist on `failure-v3`; view implementations do not) | Not started |
| U-6 | Production views built against the sheets, per family | Not started (P11–P15 / M8) |
| U-7 | Light-primary team colours unreachable from the generator; card contract uses a labelled synthetic pair | Open against P2 |

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

---

## 6. Owner decisions outstanding

| # | Decision | Recommendation |
|---|---|---|
| O-1 | **The cap invariant.** Beat 2 presumes a team *can* be over the cap until a date. The engine forbids it: `acquire` refuses anything that would exceed the cap, and `release` validates the whole root, so an over-cap team could not take its first step back. Either (a) accept the cap as structural and rewrite beat 2 as a continuously-enforced constraint, or (b) make temporary illegality representable inside a bounded window. | **(b), scoped to the week-21 boundary** — opened by expiry, closed by compliance in the same `advanceWeek`, so no *persisted* root is ever illegal and the cap-laundering defence in `PORT-LOG.md` stays intact. `enforceCapCompliance` is written and correct for (b); under (a) it is dead code and should be deleted, not left looking load-bearing |
| O-2 | Whether to schedule per-drive accounting now (unblocks D-2) or after M8 | After M8. It is a change to the core loop every calibration number is measured against; doing it beside other engine work makes a red band impossible to attribute |
| O-3 | B-2 signing and TestFlight setup | Owner-only; cannot be delegated |

---

## 7. Suggested order to beta

1. **Settle B-1** — build the app to a device once. Cheapest possible answer to the largest unknown.
2. **V-1** — full suite green on the current branch.
3. **G-01** — read-model providers, so a device build shows the world rather than fixtures.
4. **U-4** — the last M8 entry-gate instrument, then the M8 gate opens.
5. **U-6** — production views per family, against the approved sheets.
6. **B-4** — measure D4's budgets on the device that will run the beta.
7. **D-1** — the portal soak defect, after re-running its attribution.
8. **O-1**, then **P-2** — the compliance beat, once the invariant question is settled.
9. **B-2** — signing and TestFlight, owner action, in parallel with 3–6.
10. **Beta on a real iPhone.**

Items in §1 beyond G-01 are what make the surfaces *truthful* rather than merely present; a beta can
begin without all of them, provided every surface that lacks its engine backing ships without the
claim rather than with an invented one — which `04` §4.4 and §6.5 already require.
