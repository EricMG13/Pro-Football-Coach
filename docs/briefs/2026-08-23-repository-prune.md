# Repository prune, 2026-08-23

Written 2026-08-23, in answer to the owner instruction to "prune outstanding worktrees and branches
which are not active or outdated across claude and codex", and to the follow-ups it produced.

**Status.** An operational record, not canon. `docs/DOC-MANIFEST.md` §4 lists what carries
authority and `docs/briefs/` is not on it. Nothing here decides anything about the game; it
records what was removed from the repository's refs and working directories on one day, and what
was deliberately kept, so that a later reader who cannot find a branch knows why.

---

## 1. What the repository looked like

Two agent families had been working the same repository for two weeks without anyone clearing up
after them, and the leftovers had accumulated in three separate places: `.claude/worktrees/` for one
family, `.worktrees/` and `~/.codex/worktrees/` for the other, and a scattering of one-off
checkouts under `/private/tmp` from merge and verification runs.

| | before | removed | left of the original set |
|---|---|---|---|
| worktrees | 31 | 19 | 12 |
| local branches | 87 | 63 | 24 |
| remote branches | 61 | 46 | 15 plus `main` |

Those are counts of the set that existed when the prune started. The repository's live counts were
higher at every point and kept moving, because other sessions created new worktrees and branches
throughout the day; four worktrees appeared during the prune itself.

## 2. The test that decided each case

One test did nearly all the work: **is this commit an ancestor of `origin/main`?**
(`git merge-base --is-ancestor <sha> origin/main`). If it is, the branch holds nothing that `main`
does not already have, and deleting it cannot lose work. That test, not the branch's age or its
name, is what separated the safe deletions from the rest.

Age was used only to sort the survivors into "active" and "outdated", and only where the ancestor
test had already said the work was unmerged.

Three further rules applied:

- **A worktree is not a branch.** Removing a worktree deletes uncommitted changes and nothing else;
  the branch and its commits survive. So worktree removal was gated on uncommitted state, and branch
  deletion on the ancestor test. They are different questions and were asked separately.
- **An open pull request pins its head branch.** Deleting a PR's head branch closes the PR, so every
  remote deletion was checked against `gh pr list --state open` first. All open PRs survived.
- **Back up before removing, then verify the backup.** Uncommitted work was captured as patches plus
  tarballs of untracked files; unmerged branch tips were captured as `git bundle`s and checked with
  `git bundle verify` before anything was deleted.

## 3. What was removed

**19 worktrees.** Every `/private/tmp` checkout, two stale `~/.codex` trees, five under
`.claude/worktrees/`, five under `.worktrees/`. Nine held uncommitted modifications to tracked
sources; those were captured as patches first.

**63 local branches**, in two passes: 50 that the ancestor test placed inside `origin/main`, then 13
whose upstream had been deleted (11 of which had an identical copy under a `restored/` prefix, so
the risk was smaller than it first appeared). One was skipped because a live worktree had it checked
out and git refuses to delete a branch in that state. Two further deletions were `restored/` copies
that duplicated a live branch exactly; the other thirteen `restored/` refs were renamed back to
their original names, being by then the only copy of what they held.

**46 remote branches**, in four passes: 30 merged into `origin/main`, then 13 unmerged with no open
PR, then the last 2 unmerged ones once the owner confirmed, and finally one branch pushed that same
day by another session, after PR #82 merged it into `main`. The remote finished as `main` plus the
open-PR heads, which is its floor.

## 4. What was kept, and why

- **Every open PR head.** Seventeen of them at the close.
- **`main` on the remote.** It is the default branch; the forge refuses to delete it. A request for
  "zero remote branches" cannot be met and was reported as such rather than half-attempted.
- **Worktrees belonging to live sessions.** Four appeared during the prune itself, and two others
  were merged into `main` but had commits from within the hour. Merged-and-recent is not stale;
  removing them would have pulled the floor out from under work in progress. One was removed on the
  owner's explicit instruction after being flagged, and it was clean.

## 5. `main` was diverged, not behind

Local `main` had drifted 13 commits ahead and 17 behind `origin/main` — a local merge of the logo
branch that was never meant to be `main`'s history, while `origin/main` had taken the surface-
reference sweep. There was no fast-forward available.

Resetting local `main` to `origin/main` was lossless here, but only because the 13 commits were
independently reachable from `origin/codex/redesign-football-team-logos`, which is PR #78. That was
checked before the reset, not assumed. The reset itself used `git update-ref` with the old value
supplied, so a concurrent move by another session would have failed the update rather than silently
overwriting it.

## 6. What is not recoverable

The backups were working files, not archives, and the owner deleted both directories once satisfied.
Everything removed by the ancestor test is reproducible from `main` and needs no archive.

Three branches are the exception. Their upstreams had already been deleted before this session,
the usual sign of a squash merge but not proof of one, and each carried a commit that is not an
ancestor of `main`:

| branch | tip |
|---|---|
| `claude/hopeful-liskov-37edb2` | `82a0060` |
| `claude/sad-heisenberg-45fed4` | `e123bde` |
| `docs/handoff-codex-calibration` | `5908a15` |

At the time of writing all three objects are still loose in the local object store and can be
recovered by SHA. That is a window, not a guarantee: `git gc` will eventually prune them, and no
copy exists anywhere else. If any of that work is wanted, recover it now.

## 7. The thing to fix, so this is not needed again

Thirty-one worktrees and eighty-seven branches is not a cleanup problem, it is the absence of a
convention. Every worktree removed here had served its purpose days earlier; nothing deleted them
because nothing owned deleting them.

The cheap fix is that whoever finishes a piece of work removes its worktree in the same breath, and
that merged branches are deleted at merge time rather than swept up later. The forge can do the
second half automatically. Neither is a decision this record can make.
