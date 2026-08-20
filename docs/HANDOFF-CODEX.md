# Codex handoff — open items

This file collects pointers to open handoffs from different sessions. Each session's item is its
own dated section below; don't assume an earlier section is still current — check the PR/branch it
names before acting on it. `docs/STATUS.md` is still the truth about the build.

## 2026-08-20 — coach career record and seatless-staff pruning

[PR #43](https://github.com/EricMG13/Pro-Football-Coach/pull/43) (career-transition seat handling,
five defects) is **merged**. Two owner-approved decisions from the same session are not: a coach
season-record feature with code in progress and a failing test, and a seatless-staff pruning rule
with canon written and no code at all. Full detail, root-cause trail, and a patch file for the
in-progress work: `docs/plans/2026-08-20-coach-career-record-handoff.md`.

## 2026-08-20 — PR #9 generation re-pin

PR #9 ([`claude/game-name-equivalents-qczn9r`](https://github.com/EricMG13/Pro-Football-Coach/pull/9))
was re-based on current `main` and its downstream deterministic pins were updated in commit
`bbfabb9` (`test: re-pin generation fingerprints after trade-dress blocklist`). The root cause was
confirmed: the 30 real NFL colour pairs added by the legal blocklist cause bounded collision
retries, which legitimately shifts the seeded RNG stream. This is a test-only correction; the
production blocklist change remains intact.

Verified locally in release mode after rebuilding the merged PR #9 tree:

- `--generation-only`: 35 tests / 42,330 checks, passed.
- `--architecture-only`: 29 tests / 245 checks, passed twice.
- `--trait-population`: 8 tests / 610 checks, passed.
- `--career-portal-decisions`: 1 test / 8 checks, passed.

The replacement full CI run is `32371185706` and was queued at handoff time; its result is the
remaining merge gate. The local `--season-rollover` release process produced no result before the
host session expired, so it is intentionally not claimed as a local pass.

After CI is green, merge PR #9, then leave this entry as historical. The remaining handoff items
are the coach season-record/seatless-staff work above, lifecycle owner decisions in
`docs/HANDOFF-CODEX-LIFECYCLE.md`, and calibration owner decisions in
`docs/HANDOFF-CODEX-CALIBRATION.md`.

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
