# Claude build handoff

Checkpoint: M6 professional management plus the first M7 living-world/history slice are committed
on the current branch. Continue from this checkpoint; do not redo the green focused gates.

Verified release gates:

- `--pro-market`: 12 tests / 58 checks
- `--history-read-model`: 4 tests / 24 checks
- `--portal-scheduler`: 9 tests / 27,823 checks
- `--architecture-only`: 25 tests / 222 checks
- `--core-contracts`: 144 tests / 883 checks
- strict Swift-5 concurrency build and `git diff --check`

Implemented in this checkpoint:

- sourced professional contract seasons and deterministic expiry
- practice-squad, trade, waiver, draft/free-agent, and professional roster AI paths
- rebuildable deterministic history/search projection
- bounded rivalry-meeting strengthening in the existing relationships scheduler step
- current M6/M7 status and Future Simulation Contract updates

Next work:

1. Complete M7: live `Programme.rivalIDs` reordering after rivalry intensity changes, durable cold
   event bodies, generated news, coaching-tree/history projections, and the 30-season history gate.
2. Run the full both-tier professional soak and cap-vs-rating calibration.
3. Continue M8 UI/accessibility/simulator work only after its production-UI entry gate.
4. Before final product shipping, run the repository-wide confidence review and rewrite tournament.

Keep Swift 5 language mode and TestKit. Preserve the actor-owned `CareerSession`, sealed portal
transactions, copied-root validation, deterministic event ordering, and no SwiftUI access to
`GameState`.
