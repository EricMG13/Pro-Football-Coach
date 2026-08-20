# Codex handoff — PR #9 re-pin

Checkpoint from a Claude session that spent 2026-08-19 22:00 UTC through 2026-08-20 ~11:00 UTC
draining a CI backlog on this repo (many PRs merged: #8, #13, #25, #29, #30, #33, #35, #36).
One item is left unfinished, fully diagnosed but not applied. This file is a pointer, not a
substitute — `docs/STATUS.md` is still the truth about the build.

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
