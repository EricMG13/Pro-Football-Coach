# Codex handoff — PR #9 re-pin, and PR #45's score-variance gap

Two unrelated checkpoints in one file, each from a different session. This file is a pointer, not
a substitute — `docs/STATUS.md` is still the truth about the build. Re-list open PRs
(`gh pr list --state open`) before acting on any number or SHA named below; both sections say so
again at their own point because it matters twice as much with two authors writing into one file.

1. **PR #9** (below) — a mechanical re-pin, root-caused, not yet applied. Session ran
   2026-08-19 22:00 UTC through 2026-08-20 ~11:00 UTC, drained a larger CI backlog alongside it
   (#8, #13, #25, #29, #30, #33, #35, #36 all merged in the same session).
2. **PR #45** (further down, "The two-tier consistency gate") — a real, unresolved model-design
   gap, not a mechanical task. Session ran through 2026-08-20 ~11:40 UTC.

## The one open item: PR #9 needs four files re-pinned

**PR:** [`claude/game-name-equivalents-qczn9r`](https://github.com/EricMG13/Pro-Football-Coach/pull/9)
— "Close-but-protected name equivalents: the near-miss rule, and eight real nicknames found in our
own pools."

**Status:** CI fails (`full` lane, run `32348748812`), 9 failing tests / 14 failed checks. This is
**not a bug** — it's the expected, deliberate consequence of a real compliance fix, and the fix
just needs its downstream golden pins updated to match, the same way the floodlit branch's
`ArchitectureTests.swift` pins were updated twice earlier in this same session (see commits
`83b6710`, `869e179` on the now-merged floodlit branch, for the precedent this follows).

### Root cause, confirmed by isolation (not just inspected)

PR #9's `Sources/FootballSimCore/Generation/Blocklist.swift` change adds 30 real NFL team colour
pairs to `tradeDressHex`. Its own comment names the gap it closes: *"every pro team in every save
was checked against college trade dress only ... the fifteen that did not were unguarded."* Pro
team colours had **never** been checked against real NFL colours before this PR — a real legal
exposure, correctly fixed.

`Sources/FootballSimCore/Generation/ColourGenerator.swift`'s `collidesWithTradeDress` checks every
generated colour pair against `Blocklist.tradeDress`, and retries (bounded, `retryBudget = 64`)
on a collision. With 30 new real pairs to check, some pro-team colour draws that used to sail
through unchecked now legitimately collide and retry — consuming a different number of RNG draws,
which shifts every subsequent draw for the rest of that generation run (rosters, prospects,
everything downstream of whichever team first collides). That's why the divergence looks total
(different UUID, different name, different ratings) even though nothing about *how* names or
traits are generated changed.

Confirmed empirically, not just by reading the code:
- Current `main` alone: `swift run ... SimTests --trait-population` passes clean.
- `main` + PR #9's `NameGrammar.swift` change only (the near-miss nickname-pool swap — same array
  counts, positions preserved, confirmed by direct diff): **passes.** That change is content-only
  and provably cannot shift the RNG stream (`SeededRandom.pick` indexes by `count`, not content).
- `main` + PR #9's `Blocklist.swift` change only: **fails**, byte-for-byte identical to the real CI
  failure (same wrong UUID, same wrong name, same wrong ratings). Confirms it's the sole cause and
  that generation is still fully deterministic (not flaky) — the shift is a real, reproducible
  consequence of the retry, not per-launch noise.

`LegalTests.swift` (the other file PR #9 touches) cannot be involved in the `--trait-population`
failure specifically — that flag only calls `runTraitPopulationTests()`, so `LegalTests.swift`'s
test bodies never execute in that process. It's a real, separate, and correct addition (the
near-miss blocklist sweep) but not part of this particular mechanism.

### What actually needs to change (four files, all mechanical once you have real numbers)

**Do not guess the new pin values. Derive them from an actual run**, same discipline the existing
comments in these files already establish (search each file for "Reproduced in two independent
processes" / "Copied from a single CI run's own actual output" for the precedent and why it
matters — a wrong pin silently defeats the determinism test it's supposed to be).

1. Recreate the merge this needs to be diagnosed against (PR #9 + current `main` — **re-fetch
   `main`, it has moved since this handoff was written**):
   ```bash
   git worktree add /tmp/pr9-repin origin/claude/game-name-equivalents-qczn9r
   cd /tmp/pr9-repin
   git checkout -B pr9-repin
   git fetch origin main
   git merge origin/main --no-edit
   ```
2. Build and run the **full default lane** (no flags — this is what CI actually runs, and all four
   files below must come from the *same* run to stay mutually consistent):
   ```bash
   swift build -c release -Xswiftc -enable-testing
   swift run --scratch-path /tmp/pr9-repin-scratch -c release -Xswiftc -enable-testing SimTests \
     2>&1 | tee /tmp/pr9-repin-run.log
   ```
   Expect ~30-45 minutes. (A prior partial run of this exact merge — killed mid-run when this
   handoff was written, not because of a failure — already confirmed the failing-suite set is
   exactly `League generation` (2 checks), `Authoritative game state` (6 checks), and
   `Deterministic trait population` (4 checks), consistent with real CI. That partial log is at
   `/tmp/pr9-full-run.log` in the session that wrote this handoff, if that sandbox is still
   reachable — otherwise just re-run.)
3. From the failure output's `expected X, got Y` lines, update:
   - **`Tests/SimTests/Suites/GenerationTests.swift`** — `PINNED_WORLD_BYTES` (line ~16) and
     `PINNED_WORLD_DIGEST` (line ~17). Both come from the same "the encoded world matches a pinned
     digest" test failure.
   - **`Tests/SimTests/Suites/ArchitectureTests.swift`** — six `private let pinned...Fingerprint`
     constants near the top of the file (currently `pinnedRootFingerprint`,
     `pinnedAdvancedRootFingerprint`, `pinnedNegotiationLedgerFingerprint`,
     `pinnedMatchSessionFingerprint`, `pinnedNewsFeedFingerprint`,
     `pinnedArchivedLedgerFingerprint` — grep `private let pinned` to find current line numbers,
     they've shifted before). Each has its own doc comment explaining what it covers and why it
     moves; extend the "moved on \<date\>, and here's why" comment pattern already there rather
     than just swapping the number in silently — that history is what lets the *next* person trust
     a re-pin instead of re-deriving from scratch.
   - **`Tests/SimTests/Suites/TraitPopulationTests.swift`** — the test named "trait generation
     leaves the identity and value stream byte-for-byte stable" (grep for that title; it's inside
     the `"Deterministic trait population"` suite). Four `expectEqual` calls fail: `initial.id`,
     `initial.fullName`, `initial.potential`, `initial.attributes` (the array). `initial.position`
     and `initial.age` do **not** change — those are template-assigned by roster slot, not drawn —
     so only replace the four that actually failed, not the whole block.
4. **Two more failures are not yet root-caused** — confirm before assuming they're the same
   mechanism, don't just re-pin blind:
   - `Tests/SimTests/Suites/CareerControlTests.swift:605` — `testAsync("spring retention choices
     pause a user-owned portal responsibility")` — threw `missingWeeklyPreparation([.gamePlan,
     .practicePlan])`.
   - `Tests/SimTests/Suites/SeasonRolloverTests.swift:130` — `test("a compliance-forced release
     survives a real week-21 boundary")` — threw `capComplianceFailed(.invalidRoot)`.

   Both are very likely downstream fallout from the same generation shift (a fixture built on a
   specific seed now getting different generated data, tripping an invariant that has nothing to
   do with the actual thing each test is supposed to check) — but that's an inference, not
   confirmed. Read what each test's fixture actually asserts before deciding whether it's a stale
   fixture (fix the fixture) or a real bug the shifted data happened to newly expose (fix the code).
   Use `superpowers:systematic-debugging` for these two specifically — don't guess-fix.
5. Verify locally (re-run step 2's full lane; all counts should read clean — "all passed").
6. Commit, push to `claude/game-name-equivalents-qczn9r`, let CI confirm green, then
   `gh pr merge 9 --merge --delete-branch=false`, then delete the branch
   (`git push origin --delete claude/game-name-equivalents-qczn9r`) once no worktree has it
   checked out (`git worktree list | grep game-name-equivalents` — none did as of this handoff).

## The two-tier consistency gate (PR #45) — real model gap, not a re-pin

**PR:** [`claude/twotier-consistency-tests-runner-11d4f1`](https://github.com/EricMG13/Pro-Football-Coach/pull/45)
— registers `TwoTierConsistencyTests` in `SuiteCatalog` (it existed with no runner before this),
fixes six structural defects in the detailed engine that the gate found, and merges `main` in
clean (135 commits of divergence, three files resolved by hand — see merge commit `995ba8a`).

**Status: open, not merged.** Everything is committed and pushed. The merge itself was refused —
not by GitHub, by the harness's own auto-mode classifier, as a direct merge to a shared `main`
other sessions are actively building against. That's a reasonable guardrail, not a bug to route
around; merge it through the normal path (`gh pr merge 45 --merge --delete-branch=false`, or the
GitHub UI) once you've re-verified it's still `CLEAN` — treat the PR number and its mergeability as
"true as of 2026-08-20 ~11:40 UTC," not current truth, same rule as PR #9's section above.

**The full ~924-test default suite was never run against the final merged tree.** Two release-build
attempts were killed outright (load average 25–40 at the time — several other sessions building
release binaries on this same machine concurrently). What *is* confirmed on the merged tree:
it compiles clean, `--architecture-only` passes (29/29, including all four of `main`'s
independently-added fingerprint pins — negotiation ledger, match session, news feed, archived
ledger — confirming they're untouched by this diff), and `--snap-resolver` passes (17/17). That
covers the surfaces this PR and the merge actually touched, but it is not the same claim as "the
full suite is green," and nobody should build on top of this branch believing otherwise. **Running
the full default lane against the merged tree is the first thing to do, before anything else.**

### What's fixed, with before/after numbers (pro calibration tuning ladder)

Six structural defects, not constant-tuning — each is a sign error, a missing term, or an
averaging-destroys-variance mistake, the same category of bug each time:

| Defect | File | Was | Now |
|---|---|---|---|
| Even run had no baseline gain (`Leverage.logistic(0) == 0` by design) or spread | `SnapResolver.swift` `resolveRun`, `MatchupRules.swift` `baselineRunYards`/`runYardDeviation` | 1.35 yd/carry | ~4.3 |
| Average passer modelled as a heavy underdog at every depth but short | `MatchupRules.swift` `throwDifficulty` | 35% completion | 62.7% |
| `poiseSackRelief`'s sign inverted against its own doc comment — calmest passer sacked easiest | `SnapResolver.swift` sack-threshold calc | wrong direction, unmeasured | fixed; `EngineTests` asserts the direction |
| Pass-rush pressure was the *mean* protection duel — made blitzing nearly inert | `SnapResolver.swift` `resolvePass` pressure calc, `MatchupRules.swift` `protectionCollapseRank`/`sackPressureThreshold` | 1.15 sacks/team-game, 6 rushers *safer* than 4 | 2.5 sacks/team-game (fitted, see comment at `sackPressureThreshold`), blitz strictly increases pressure |
| Air yards were a constant per depth — "explosive pass" was a property of the play call, not the throw | `MatchupRules.swift` `passAirYardDeviation`, `SnapResolver.swift` air-yards draw | step function | continuous scatter |
| `normalTempoSnapSeconds` measured the play clock, not the game-clock cost between snaps | `ClockRules.swift` | 89.3 plays/team-game | 62.6 |

Pro bands passing on the tuning ladder: **5 → 7** of 16 (plays, completion %, sacks, rush yards,
pass yards, field-goal %, tie rate). Home advantage is also now tier-specific
(`CompetitionRules.homeFieldPoints(for:)`, `proHomeFieldPoints`/`collegeHomeFieldPoints`) — one
shared constant provably could not hold both tiers' disjoint bands; both hold now.

### The open item: score variance, and it's a design gap, not a constant

`--two-tier-consistency` measures the detailed model's points per team-game at **standard deviation
near 30, against a real figure near 10** — 5% shutouts, p95 around 87, max into the 140s on
generated rosters. That single defect is almost certainly the whole story behind the remaining
red bands in both tiers: `blowout rate` (0.65–0.72 against a 0.17–0.26 band) and
`favourite win rate` (0.82–0.88 against 0.62–0.72 pro, 0.70–0.78 college). College is worse than
pro on nearly everything for a related, separate reason: `ClockRules.collegeClockRules`'s
`clockStopsOnFirstDown = true` barely mattered when neither offence converted first downs often
(the old broken run/pass model); now that both work, it amplifies drive length directly — college
measured 77.7 plays/team-game against a 67–75 band even after the same clock fix that brought pro
into band. Worth a second look once the variance issue is understood, but don't assume it's the
same mechanism — verify.

**Hypothesis, not yet isolated:** with ~63 plays per team-game and roughly 10 independent leverage
draws per play (protection duels, route matchups, the throw itself, run-lane duels, yards-after-
contact chains), a team with even a modest rating edge should — by nothing more than volume — win
more than half of a very large number of independent draws, and that edge should compound across a
game into either (a) very stable, low-variance domination of a real mismatch, or (b) if extreme
individual duels (sacks, interceptions — both drive-ending, and interceptions double-swing field
position) carry outsized weight relative to their frequency, unusually fat tails on both sides. The
measured 5% shutout rate points at the second explanation, but this is inference from one aggregate
number, not a measurement — **don't fix this from the hypothesis, isolate it first**, the same
discipline every fix above followed:

1. Build a probe (pattern: `runArchitectureFingerprintProbe`, `runCalibrationReportProbe` in this
   session's other new files) that fixes **one specific roster pair** — e.g.
   `CalibrationRoster.team(skill: 72, seed: X)` for both sides, called once — then plays it through
   `GameEngine.play` several thousand times varying *only the game seed*. Measure the standard
   deviation of one side's points. This isolates within-game engine noise, for a genuinely even
   matchup, from between-matchup variance caused by `CalibrationRoster`'s own talent generation
   (team-level gaps of 0–9 from `CalibrationHarness.talentLadder`, but ±18 *individual*-player
   scatter within a nominal team skill — `CalibrationRoster.team`'s own doc comment explains why
   that spread is deliberate).
2. Repeat for a moderately mismatched pair (skill 78 vs 69, one of `talentLadder`'s actual pairs).
   Compare the within-matchup sd at each gap size, and compare the *mean* shift between them — a
   real rating gap should move the mean more than it widens the spread; if the model does the
   opposite, that's the actual bug.
3. Only once you know whether the excess variance is within-game (engine noise per play/drive
   summing too aggressively) or between-game (the same fixed matchup itself producing wildly
   different scores from seed to seed, versus real football's game-to-game bounce for a truly even
   team) should you decide what to change. A within-game fix and a between-game fix are different
   code in different places — don't guess which one it is.

### Where things are, precisely

- `Tests/SimTests/Suites/TwoTierConsistencyTests.swift` — the gate itself. Four metrics asserted
  (points, plays, yards per play, home advantage), six named as uncovered with what each is
  blocked on (`TwoTierConsistency.uncoveredMetrics`), one canon gap named explicitly
  (`TwoTierConsistency.canonGaps` — college yards per play has no `01-RESEARCH.md` §6.5 row to
  compose a margin from; that's a doc-first amendment to `01`, not a number to invent here).
  `Estimate.difference`/`pairedMeanDifference`/`pairedRateDifference` (in `Band.swift` and this
  file) implement paired TOST — the difference is tested against a derived margin, never a level
  against a range. If you're wondering why this file has two different-looking difference
  estimators, it's because two sessions converged on the same test independently mid-session and
  the paired one (retains fixture covariance) is strictly better; that's already resolved, not an
  open question.
- `Tests/SimTests/Suites/CalibrationReportProbe.swift` — `--calibration-report`, prints both
  tiers' full band tables from `CalibrationHarness`. Use this, not `--calibration` (which only
  tests the TOST instrument itself and never runs the engine).
- `Tests/SimTests/Suites/EngineTests.swift` — new cases: `"an even run gains football yardage in
  both its middle and its tail"`, `"an even passer completes at football rates, at every depth"`,
  `"poise relieves sack pressure rather than inviting it"`, `"the pass rush gets home at a
  football rate, and blitzing helps it"` (this last one measures against `CalibrationRoster`, not
  uniform `testPersonnel` — it originally passed against uniform personnel at a healthy 7% while
  the real harness read 10.6 sacks/team-game against scattered rosters; a pass-rush model is a
  statement about *unequal* players, and a fixture that makes them equal can't test it — keep that
  pattern for the variance probe above). `runGameFingerprintProbe` (`--game-fingerprints`) prints
  the two play-by-play pins for reproduction before a re-pin, same pattern as PR #9's section.
- `--snap-resolver` runs just the engine-core suite fast (also folded into `--engine`, which never
  ran it before this PR — a real coverage hole, now closed).

## Operational notes from today, worth knowing before you touch this repo

- **CI is `pull_request`-triggered but does *not* fire on `ready_for_review` alone.** Marking a
  draft PR ready produces no run by itself in this workflow config
  (`.github/workflows/tests.yml`). If a PR needs its first CI run, push something — an empty commit
  is fine (`git commit --allow-empty -m "chore: trigger CI"`).
- **`gh pr view --json mergeable,mergeStateStatus` lags for roughly 30-90 seconds after any merge
  to `main`.** It reports `UNKNOWN`, or worse, a stale `CONFLICTING`/`CLEAN` from before the merge.
  Don't trust it immediately after a merge landed elsewhere — re-check, or just attempt the
  operation and read its actual error.
- **The `full` lane (default, no flags — what CI runs) takes 30-45 minutes** on the GitHub-hosted
  macOS runner, and comparably long locally with a real toolchain. Use a narrow flag
  (`--trait-population`, `--core-contracts`, etc. — see `scripts/verify.sh`'s header comment and
  `Tests/SimTests/main.swift`'s flag list) for a fast targeted check; only the full lane is
  authoritative for a re-pin, because all the golden values need to come from one consistent run.
- **Golden pins moving is normal, not alarming**, whenever generation-affecting code changes:
  a new persisted field, a blocklist collision set that changes retry counts, anything that shifts
  what gets encoded or how many RNG draws a path consumes. The wrong response is to "fix" the
  generator to match the old pin. The right response is Phase-1 root-cause *why* it moved (deliberate
  vs. a real per-launch-hash regression — the test's own failure message names both branches), then
  re-pin from an actual deterministic run if it's deliberate.
- **Many concurrent Claude and Codex sessions are working this repo in parallel worktrees.** PR
  numbers, branch names, and `main`'s tip all move between when you read this and when you act.
  Re-list (`gh pr list --state open`) before doing anything based on a number or SHA named above —
  treat every SHA and PR number in this document as "true as of when this was written," not current
  truth.

## Everything else that was open when this was written

Checked but **not** part of this handoff's scope — no root cause taken further than what `gh pr
view` shows:

- PR #34, #37: other sessions' in-flight work (`#34` had CI running; `#37` was `CONFLICTING`).
  Not touched.
- PR #27, #26, #15, #14, #12, #11, #10, #6: long-idle, no CI ever run on any of them, mostly
  `CONFLICTING` against current `main`. Not investigated further — most are drafts and may not be
  ready for attention regardless.
