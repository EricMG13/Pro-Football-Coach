# Consolidated review register — 2026-08-20

Five independent reviews ran against this tree today. This document merges them into one register,
marks where they agree, and records what each found alone. It supersedes none of them; each source
holds the evidence and should be read for any finding you intend to act on.

## Sources

| # | Document | Scope | Size |
|---|---|---|---|
| **AR** | `2026-08-20-adversarial-review-codebase-and-branches.md` | whole codebase + branches, incl. a football-rules pass with a 1,400-game probe | 1,269 lines |
| **CR** | `2026-08-20-confidence-review.md` | whole codebase + all branches, 23 numbered findings | 1,111 lines |
| **RR** | `2026-08-20-release-review.md` | release readiness, 39 findings C/H/M/L | 1,167 lines |
| **PA** | `2026-08-20-swiftui-performance-audit.md` | app-layer render performance | 412 lines |
| **FR** | `2026-08-20-full-codebase-and-branch-review.md` | `/code-review` max-effort pass, 23 findings | this session |

**Verdicts converge:** AR says *BLOCK*. RR says *not shippable, and not currently assemblable*.
Nothing here dissents.

**The one-line diagnosis, from AR, that the other four corroborate:**
*this project's gates are green because they cannot go red.*

---

## Part 1 — Corroborated by two or more independent reviews

These are the highest-confidence items in the register. Independent passes, different methods, same
conclusion.

| ID | Finding | Sev | Found by | Status |
|---|---|---|---|---|
| **X-1** | **Cross-process determinism pins are stale; the full suite is red.** Bisected to `c6e2d21` (the naming commit) by two reviews independently. FR ran the full lane: 967 tests, 787,806 checks, **F1 is the only failure**. RR reports 964/787,761 and confirms a clean extract of `c6e2d21^` passes. | P0 | FR, RR, CR | **Run, 3×** |
| **X-2** | **All 166 team logos resolve at exactly one world seed** (20260812), while the new-career screen takes a free-text seed. No test calls the lookup at another seed. | P0 | AR, CR, RR, PA, FR | **Confirmed, 5×** |
| **X-3** | **The branch is 208 commits behind `origin/main`** and is re-solving, worse, problems fixed upstream — including the whole P0/P1 remediation pass and the 2026-08-13 legal hardening. | P0 | AR, CR, RR, PA, FR | **Confirmed, 5×** |
| **X-4** | **CI runs one lane.** `verify.sh` wires 17 of SimTests' 68 flags; `--m3-soak` (the 8 MB ceiling) is wired to no lane at all; the iOS app is never compiled in CI; 15 suites never run by default or by CI. | P1 | FR, CR, RR | Confirmed, 3× |
| **X-5** | **Departed-player retention is unbounded, and the in-flight fix moves the wrong way.** The durable carve-out retains every ever-signed recruit forever (~3,350/season); the new soak assertion subtracts the unbounded term from both sides. | P0 | FR, RR, CR | Confirmed, 3× |
| **X-6** | **The git index holds different code than the working tree.** `git commit` without `-a` ships a weakened integrity check nothing has built or tested. Re-confirmed here: `PeopleState.swift` is +10/−19 unstaged, four other files also diverge. | P0 | AR, CR, FR | **Confirmed, 3×** |
| **X-7** | **The calibration gate asserts nothing.** `holdoutSeeds` declared, asserted disjoint, never passed to the harness; no test reads `report.passed` or `report.failures`. No lane asserts a band holds. | P1 | AR, RR, CR | Confirmed, 3× |
| **X-8** | **Compaction deletes the coaching tree's only authority.** `CoachingTreeReadModel` builds solely from `staffCareers`, which the new weekly compaction prunes to currently-employed staff. | P1 | FR, CR | Confirmed, 2× |
| **X-9** | **`authoredFloor >= 12` compares a constant to a literal** — the gate that let G-35/G-36 ship was never fixed, only the app. Names just got longer. | P1 | FR, RR | Confirmed, 2× |
| **X-10** | **`PerformanceBudgetTests` cannot fail on budget.** `SuiteCatalog` deliberately asserts it is *not* a gate. | P2 | FR, RR | Confirmed, 2× |
| **X-11** | **`Akron` is in the place pool and absent from the blocklist**, so `"Akron, OH Institute"` ships unflagged. The dual-use test derives its count from the same under-inclusive list it audits. | P1 | FR, CR, RR | Confirmed, 3× |
| **X-12** | **The "reviewed release seams" contract test hand-lists twelve view files** — a spot check over instances, which CLAUDE.md names as a defect in itself. | P2 | FR, RR | Confirmed, 2× |
| **X-13** | **Every generated name now carries a comma and a state code** — schools, pro teams, stadiums and regions alike ("Albion, IA Reach", "Archer Lodge, NC Timber Wardens", "Alamo, TN Field"). | P1 | FR, RR | Confirmed, 2× |
| **X-14** | **Competing `PeopleState` retention models across five open branches**; two staff-prune implementations will collide on merge. | P2 | FR, CR | Confirmed, 2× |

---

## Part 2 — Found by one review only

Single-source, but several are the most serious items in the whole register. Ordered by severity,
not by source.

### From AR — the football-rules pass (nobody else ran one)

24 findings, 7 CRITICAL, 11 confirmed empirically by a probe package running 1,400 headless games:

- **The match engine does not implement the rules of American football.** The engine awards a
  **fifth down**. The team on offence at the end of the first half **receives the second-half
  kickoff** (0 of 677 half boundaries changed possession). The **away team can never possess the
  ball in overtime** (235 home, 0 away). Every turnover is spotted at the previous line of
  scrimmage. A walk-off overtime score does not end a professional game. 17 of 600 games were ended
  early by a drive budget and settled by a coin flip. There is **no two-point conversion, no
  two-minute warning, no kickoff, and no penalties at all**.
- **College overtime ends after one possession** (P0-6).
- **Twelve shipped team identities sit inside the project's own ΔE-25 trade-dress radius of a real
  professional team's colours**, with logo artwork generated from those exact hexes. The trade-dress
  table holds 39 college pairs and **zero professional ones**, while the game generates 32
  professional teams. Reproduced independently. *(P0-1 — the single most serious legal finding in
  the register.)*
- **The name-collision partition assertion is `Set(A + B) == Set(A).union(B)`** — a mathematical
  identity. It cannot fail and never could. *(P0-2 — and FR's report praised this same test as
  well-constructed. AR is right; FR was wrong.)*
- **Coach names are swept by nothing.** A code comment says they are. *(P0-3)*
- **Shipped features that never run:** the discipline system has zero callers; player morale never
  executes and never appears in the UI; scheme identity changes nothing in any played match;
  in-match fatigue is structurally zero; the professional tier has no trades, no waivers, no
  practice squads. **Six tests pin these dead features green** — most explicitly
  `ReadModelProviderTests.swift:1173-1181`, whose assertion is documented as *"correspondence is
  empty because no inbox system exists"*. *(P0-9)*
- **A default new career cannot finish its first season.** Not delegating responsibilities — the
  default — makes the postseason portal window throw permanently. Both multi-season tests delegate
  everything first, so the default configuration has no coverage.
- **28 further measured findings** on the season around the games.

### From RR — release readiness

- **There is no app icon anywhere in the project.** (C-01)
- **157 MB of 1024×1024 logos** to draw marks at 20, 32 and 44 points. (C-02; PA and CR give
  156/164 MB — the figure differs by measurement basis, the finding does not.)
- **Week advance measured at 4.031 s against a 2.0 s ceiling**, Release build on desktop silicon;
  the iPhone measurement has never been taken. (C-04)
- **Saves measured at ≈14.76 MB at season 20 and ≈37.11 MB at season 30** against D7's 8 MB —
  1.8× to 4.6× over. (C-05) *This is the measurement FR's X-5 argued for and did not take.*
- **Two thirds of every generated world begins with the letter A.** Re-verified here: of 570 places,
  **380 (66.7%) start with A, 490 (86.0%) with A or B, and only 17 of 26 letters appear at all.**
  The pool was harvested alphabetically from the Gazetteer and truncated. (C-07)
- **Only 2 of 17 major sports markets are in the pool**, so a 32-franchise professional league plays
  in towns of a few hundred people. (H-08)
- **No export-compliance declaration** (H-09) and **no privacy manifest** (H-11) — both required for
  submission.
- **The engine's core arithmetic routes through `exp`, `log` and `cos`**, and the cross-process proof
  never leaves the host. (H-13)
- **Whole-root integrity validation runs on every intent**, and twice per market transaction. (H-12)
- **Match Day's causal commentary is a restatement of possession.** (H-14)
- **Five of the fourteen default release gates are grep-over-source.** (H-01)
- **No rendered UI test of the shipping app runs anywhere.** (H-02)
- **No diacritic folding** — `blocks("Míami")` is false. (M-01b; also AR P0-4)
- **`try!` sample fixtures compile into Release** (M-06); **raw Swift errors are shown to the
  player** (M-11); **there is no way to start over** and the API that would do it is dead (M-10).
- **14 GB working tree, 329 MB of it one `git add` from being committed.** (M-09)
- **The enforced envelope limit is 64× the product ceiling.** (M-12)

### From CR — confidence pass

- **`referencedEntityIDs`'s `default: []` now gates deletion.** A payload case that returns no IDs
  no longer merely fails to retain — it actively permits the compaction to delete. (F5)
- **Widened prospect retention can make `advanceWeek` throw.** (F16)
- **No programme in the world ever redshirts anyone** — measured. (F18)
- **Three D4 budgets measured over their hard ceilings.** (F17)
- **The trademark screen no longer describes the names it screens.** (F6)
- **Quarantined saves are unbounded and invisible** (F12); **agent tooling directories untracked and
  unignored** (F14); **`SuiteCatalog`'s lane vocabulary is not `verify.sh`'s** (F20); **college has
  half the calibration bands of pro and nothing checks** (F21).
- **Concurrent agent sessions in one working tree kill test runs** — observed. (F15)

### From PA — SwiftUI performance

- The app root **takes an observation dependency on all 28 read models**, so any change re-evaluates
  everything. (P1-1)
- **35 of 41 scrolling surfaces build every row eagerly.** (P1-4)
- **World Search rebuilds 166 rows and re-filters the whole world on every keystroke.** (P1-3)
- `selectedX` computed properties **linear-scan, then get read a dozen-plus times per body**. (P1-2)
- The ball and player tokens are **the most expensive things in the 60 Hz frame** (P2-1); three
  progress-bar primitives are each a `GeometryReader` used inside rows (P2-2).
- `ColorValue.color` **allocates a fresh `Color` at 718 call sites** (P3-2); a package-build-only
  fallback **decodes a 1 MB PNG per body evaluation** (P3-3).

### From FR — this session

- **The `"City, ST"` format defeats the blocklist's contiguous-word matcher, and it reaches a mark
  that upstream already blocks.** Executed: `blocks("Las Vegas, NV Bowl") == false`, while
  `origin/main` blocks `"Las Vegas Bowl"`. `venueWords` contains `"Bowl"`, `"Las Vegas, NV"` is in
  the pool, so the venue path is live. RR found the same mechanism on the institution path
  (`"Boston, MA Technical Institute"`, M-01) and rated it Medium for limited reachability — **the
  venue limb raises it**, because it defeats a fix that has already been made rather than exposing a
  list that was merely under-inclusive.
- **The full set of eight nickname-pool regressions, cross-checked against main's 485-entry list.**
  This branch still emits `Timber Otters`, `Hollow Herons`, `Storm Wayfarers`, `Storm Kestrels`;
  `Storm` plus `Drovers, Foresters, Marauders, Harriers, Herons, Otters, Beacons` are all live here
  and all blocked upstream. `--legal-only` passes on this branch. (CR found `Otters`.)
- **The logo manifest lost the word "fictional" from 165 of 166 generation prompts** in the rename,
  and 32 concepts still describe deleted place-names, while all 166 records still read
  `humanApproved: true` with a 2026-08-20 review note.
- `bowlName` has no production caller; `isDecorative` is never set at any of 18 call sites, making
  its accessibility label unreachable; `EntityStore.values` re-sorts by `uuidString` on every read
  across 152 call sites.

---

## Part 3 — Fix-order traps

Both flagged by AR, and both are the kind that turn a correct fix into a regression:

1. **Re-key the logo catalog before touching the trade-dress table.** Repairing the table changes how
   many colours the rejection-resampling loop discards, which shifts the RNG stream, which changes
   every team UUID, which invalidates the entire logo catalog *even at the default seed*.
2. **Do not fix the vacuous overtime guard alone.** Fixing it makes the away-possession bug worse:
   the game would then wait forever for a possession the away team can never receive.

A third, from this consolidation:

3. **Resolve `NameGrammar.swift` toward `origin/main`, not toward this branch.** The branch rewrote
   the file wholesale (+606/−39) on a base that predates main's legal hardening. A merge resolved in
   the branch's favour silently reverts the 2026-08-13 fix (X-3, and FR's nickname finding).

---

## Part 4 — Suggested order

The reviews agree on the sequencing, so this is their consensus rather than a new proposal.

1. **Make the gates real first.** X-1, X-7, AR P0-2, X-9, X-10, X-4. Until an assertion can fail, no
   later fix can be shown to have worked. This is the cheapest block of work in the register and it
   gates the value of everything after it.
2. **Integrate before building anything else.** X-3 and X-6 — merge `origin/main`, and reconcile the
   index with the working tree. Several findings below are already fixed upstream.
3. **The legal cluster.** AR P0-1 (twelve identities inside the trade-dress radius) is the most
   serious single item in the register; then AR P0-3, AR P0-4 / RR M-01b, X-11, FR's venue limb.
4. **The football.** AR's rules pass — fifth down, half-boundary possession, overtime — is the
   largest body of confirmed, empirically probed defect and it is what the product *is*.
5. **Budgets and payload.** RR C-04, C-05, C-02, and X-5's retention model underneath them.
6. **Submission blockers.** RR C-01, H-09, H-11 — small, and none of them are optional.

---

## Part 5 — What remains uncovered

Stated so the register is not mistaken for completeness:

- **No device measurement of anything.** Every performance and save figure is a host measurement.
  The iPhone gates named in `PRODUCT.md` remain open.
- **No simulator demonstration.** Per CLAUDE.md that is an owner action regardless.
- **No soak, calibration or `--m7-gate` run in this session.** FR's retention findings argue from the
  code; RR's 14.76/37.11 MB figures come from `docs/HANDOFF-CODEX-2026-08-20.md`, not from a run made
  today.
- **The 90 branches were surveyed for divergence and duplication, not reviewed commit-by-commit.**
- **`docs/proofs/2026-08-18-exhaustive-critique/` (80 findings, 21 surfaces) was not re-driven.**
  STATUS.md records five of its findings closed on 2026-08-19; `--design-contracts` was re-run today
  and confirms `62 landed, 0 pending`, so the reachability claim holds. The per-surface craft
  critique underneath it was not revisited.
