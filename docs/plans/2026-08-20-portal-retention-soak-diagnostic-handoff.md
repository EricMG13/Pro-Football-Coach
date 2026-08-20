# Handoff: portal-window retention bound

Branch: `claude/hopeful-liskov-37edb2` in `.claude/worktrees/hopeful-liskov-37edb2`.
The earlier portal fix is already in merged PR #39; this follow-up contains the verified
all-live-event rule and its portal-integrity boundary.

## Implemented rule

`SeasonLifecycleSystem.retainedIdentityIDs` protects every career record belonging to a
`(targetSeason, window)` named by any still-hot portal event: entry, retention resolution, offer,
transfer, or completion. It does not protect every career that ever touched the portal, and it does
not guess from the current season. The bounded event journal is the portal system's retention
authority; once no hot portal event names a window, its departed identities become evictable.

`WorldIntegrity` continues to recount live-window events and current portal offers/scouting
knowledge. Historical career records are not used as a live capacity ledger, so pruning one member
of an old window cannot make a later portal commit fail on a partial historical capacity aggregate.

## Verification

- TDD focused release suite: **17 tests, 124 checks, all passed**.
- Fresh release `--m2-soak` on a clean `origin/main` base: **20 seasons in 3,867.623 seconds**.
- No `portalCommitFailed` occurred.
- No `departed identities are unbounded` check failed; the requested
  `departedPlayers.count <= 8,192` invariant passed through season 20.
- The soak exited nonzero only for 20 unrelated pre-existing checks: tier-gap calibration in
  seasons 4 and 5–20, low professional decline-share checks in seasons 5 and 7, and the final
  expected-player-count check (`18,368` vs `15,766`). It is not an overall green soak result.

The temporary diagnostic invocation was closed with exit code 1 after interruption and produced no
final issue list; it is not evidence and should not be rerun as part of this handoff.

## Files in this follow-up

- `Sources/FootballSimCore/People/SeasonLifecycleSystem.swift`
- `Sources/FootballSimCore/Integrity/WorldIntegrity.swift`
- `Tests/SimTests/Suites/PortalTransactionTests.swift`
- `docs/02-GAME-DESIGN.md`
- `docs/STATUS.md`

Before commit, run the required confidence review, post-edit rewrite tournament, `git diff --check`,
and GitNexus `detect_changes()` from the portal-retention worktree. Push this branch and open the
GitHub PR only after those checks; merge only if the PR contains the portal-scoped diff above.
