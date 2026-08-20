# Handoff: coach career record and seatless-staff pruning

Branch `claude/coach-career-promotion-integrity-f10168`,
[PR #43](https://github.com/EricMG13/Pro-Football-Coach/pull/43) (**merged** to `main` as
`54bd08e`). This document covers the two items that were *not* merged: one owner-approved decision
with code in progress, one owner-approved decision with no code started. Work stopped here on
explicit request (stop all tasks, merge what's done) before either finished.

## What's already merged — not part of this handoff

Five defects in the three career transitions (promotion, resignation, firing) all leaving the
coach's chair in the world untouched after the career state moved: seat drop, seat duplication,
a `missingHeadCoach` throw on rehire, a coaching-tree UUID coin-flip crediting a contested seat to
the wrong coach, and a phantom-disciple case the branch's own coordinator-follow decision
introduced (caught by a confidence review of the branch's own diff, not by the user). Also merged:
the owner decision that the four coordinators follow a promotion (`02` §9), and a by-construction
scan requiring every `clearCollege()` call site to be answered by a world-side seat move, so a
fourth separation added later can't reintroduce the class silently. Full account in `docs/STATUS.md`
under the 2026-08-20 entries. `--career-arc` went from 8 tests / 49 checks to 19 / 333, all suites
green in debug, `--m7-gate` confirmed green in release separately (30 seasons, 2,056,499 archived
events, `weekMeanMs=4439.66`).

## Item 1: coach season record — canon written, code in progress, failing

**Owner decision, 2026-08-20:** a coach's career record is a per-season line recorded on the coach
(one line: season, organisation, wins, losses, ties), not computed — `docs/02-GAME-DESIGN.md` §9
(search "per-season line") already states the full rule, including the bound (same limit as the
assignments beside it) and the scope (played coach only, not every organisation). **Read that
section before touching this** — the canon is the spec, this document is not a substitute for it.

**Why it can't be computed:** `state.competition.standings` is rebuilt from the current schedule
each week (`CompetitionReducer.rebuildStatistics`) and holds only the season in progress.
`SeasonArchive` (`Sources/FootballSimCore/Competition/CompetitionState.swift:309`) keeps champions,
final rankings, awards and league-wide totals per archived season, but no per-organisation win-loss.
So once a season is archived there is nothing persisted to derive a coach's record from — confirmed
by reading both types directly, not inferred.

**The patch:** `docs/handoff/2026-08-20-coach-season-record-wip.patch` (355 lines) is the exact
working-tree diff at the point work stopped — recovered from `git stash show -p stash@{0}` in the
worktree this was written from; if that stash is gone, this patch file is the only copy. Apply with
`git apply docs/handoff/2026-08-20-coach-season-record-wip.patch` from a clean `main` checkout, or
read it directly, it's a normal unified diff. It adds:

- `CoachSeasonRecord` (`Sources/FootballSimCore/People/PeopleState.swift`) — the one-line-per-season
  type, with the same decode-time ordering and bound checks every other record in this file uses.
- `StaffCareerRecord.seasonRecords`, bounded by `PeopleRules.careerSeasonHistoryLimit`, decoded
  `IfPresent` so a save from before this field existed still reads.
- `PeopleState.recordCoachSeason(_:for:)` and `CareerControlSystem.recordCoachSeason(after:in:)` —
  the latter reads `state.competition.standings[tier]` for the coach's current organisation and
  writes one line.
- The call site in `Sources/FootballSimCore/Scheduling/WorldScheduler.swift`, inside the
  `completed.week == SharedRules.inSeasonWeeks` block, placed **before**
  `CareerArcSystem.evaluateSeasonEnd` rather than after — deliberately: `evaluateSeasonEnd` can fire
  the coach and clear `careerArc.currentJob` inside itself, and a season a coach was sacked at the
  end of is still a season they coached. Recording after the evaluation call was the first version
  of this fix and it was wrong for exactly that reason — don't reorder these two calls back without
  re-confirming that.
- A test in `Tests/SimTests/Suites/CareerArcTests.swift` ("the coach's season record is written and
  carries across the promotion") that drives a full season through `WorldScheduler.advanceWeek` with
  the career fully delegated (so the scheduler can abstract the controlled fixture instead of
  demanding a played match) and checks the recorded line against `state.competition.standings`
  directly, not against a guessed value.

**Where it's stuck, and what's already ruled out:** the test fails — `seasonRecords.count` is `0`
after a full 21-week season, even though the standings row is found (not `nil`) and integrity
passes. Two hypotheses were tried and both were wrong:

1. *"The write happens after `evaluateSeasonEnd` clears the job."* Moved the write before the
   evaluation call (see above) — still `0`. Ruled out, but the reordering is still correct on its
   own logic and should stay.
2. *"`standings[.college]` has no games in it because delegation abstracts the match without
   recording a result."* Not yet confirmed or ruled out — the last diagnostic print
   (`ZPROBE`/`ZPROBE2`, both left in the patch's version of `CareerArcTests.swift` — **delete both
   before continuing**, they're `print`-based scratch tests, not real coverage) showed the final
   standings row for the programme at **0 wins / 0 losses / 0 ties** even after all 21 weeks, which
   is the more basic question: did the programme play any games at all in this generated world, at
   this seed, under full delegation? A second diagnostic pass (added `state.competition
   .currentSchedule.games` counts for the programme, `careerArc.currentJob`/`career.coachID`/
   `career.college` at the end of the loop) was queued but never ran — the build was killed by
   memory pressure from concurrent work on the shared build machine before it produced output.

**Next step:** re-run that second diagnostic (it's in the patch, search `ZPROBE2` — or just add
fresh prints, the ones there are cheap to reproduce) and read whether `played.count` is `0` (no
games scheduled/entered for this programme this season — a fixture problem, fix the test's setup)
or `played.filter { $0.result != nil }.count` is `0` while `played.count` is nonzero (games
scheduled but never resolved — a real question about whether full delegation actually plays out
the season under `WorldScheduler.advanceWeek`, which would be a more interesting finding). Don't
guess past this — `superpowers:systematic-debugging` applies, one hypothesis at a time, confirmed
before moving to the next.

## Item 2: seatless-staff pruning — canon written, no code started

**Owner decision, 2026-08-20:** `docs/02-GAME-DESIGN.md` §7 (search "Staff who lose their seat are
pruned") — a coach who loses their seat (fired, resigned, or displaced by an arriving promotion) is
kept if the coaching tree names them (as a mentor with disciples, or as someone who came up under
one) and dropped otherwise. The played coach is never pruned, employed or not.

**Why this exists:** `state.staff` grows by five entries per promotion (the coach plus four
coordinators, since the coordinator-follow fix in this same branch) and one per separation, with no
pruning at all today — flagged in `docs/STATUS.md`'s 2026-08-20 entry as a `CLAUDE.md`
stated-bound violation (every collection that grows across seasons needs one; this one had none).
Small in practice against ~2,160 staff, thirty seasons run green in the `--m7-gate` soak — this is a
correctness-of-scope item, not an urgent stability one.

**No code exists for this.** Canon is written and is the full spec; nothing in
`CareerControlState.swift`, `PeopleState.swift`, or the season-rollover path implements it. The
natural point to compute "does the coaching tree name this coach" is
`CoachingTreeReadModel.build(from:)` itself (`Sources/FootballSimCore/History/
CoachingTreeReadModel.swift`) — it already builds the full mentor/disciple index every call, since
it's deliberately not `Codable` and rebuilt after load rather than persisted (see that file's own
header comment for why). Pruning, by contrast, has to happen at the point staff are dropped from
`state.staff` and `people.staffCareers` — most likely a new step in `SeasonLifecycleSystem.advance`
or `WorldScheduler`'s season-end block, run *after* a `CoachingTreeReadModel` build so the prune
decision has the same tree the coaching-tree screen would show. Building the tree once for this and
throwing it away (rather than caching it) is consistent with how everything else in that file
already treats it as a cheap rebuild, not a stored index — don't add persistence to solve this.

Start with a failing test in `CareerArcTests.swift` or a new suite: bootstrap a career, separate a
coach with no disciples and confirm they're gone from `state.staff` after a season boundary;
separate one who mentored a disciple who since became a head coach, and confirm they survive.
TDD applies here same as everywhere else in this repo (`superpowers:test-driven-development`) —
there's no existing code to extend, so this is a clean start, not a fix.

## Operational notes from this session, worth knowing before you touch this repo

- **Many concurrent sessions are working this repo in parallel worktrees, on a heavily loaded shared
  machine.** During this session, `main` moved 136 commits between when this branch was cut and
  when it merged, and moved again three more times *during* the merge itself (each requiring a
  re-merge). Re-fetch and re-check drift before assuming any SHA or PR number here is still current.
- **`gh pr view --json mergeable,mergeStateStatus` lags badly after a push** — it reported
  `CONFLICTING` against a state `git merge-tree` confirmed was clean, more than once. Don't trust it
  immediately; either wait and re-check, or trust a direct `git merge-tree
  $(git merge-base HEAD origin/main) HEAD origin/main` over it (`docs/HANDOFF-CODEX.md` already
  names the same lag from an earlier session the same day — this is a recurring property of this
  repo's current traffic, not a one-off).
- **A background build/test process can be silently OOM-killed** (exit 137) on this machine under
  concurrent load from multiple sessions' soaks and release builds running at once. An empty output
  file with no exit code is a dead process, not a slow one — check `ps` for a live PID before
  waiting longer on it.
- **Another session's process is invisible to your own `ps -ax`** in this environment — a release
  build another session started and was still running did not appear in this session's process
  list at all, which briefly looked like it had died. If a peer session reports a process is running
  and your own `ps` disagrees, trust the peer over your own visibility, or ask, rather than
  concluding it's dead and duplicating the work.
