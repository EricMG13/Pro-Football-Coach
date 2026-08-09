# Open Decisions Log

Owner decisions for the rebuild program. Each entry: decision, status, date, and where it binds. The Opus 5 build run stops and asks when a blocking item here is unresolved.

## Resolved

- **OD-1 — Voice amendment.** In-fiction media voices (beat writer, columnist, radio host) carry personality license; the system voice stays sober and declarative, no exclamation marks. **Approved at gate 1 (2026-08-09, owner: "next" on the recommended defaults).** Binds `DESIGN.md` §Voice, `PRODUCT.md` §Brand.
- **OD-2 — Retro Bowl's role.** On the Field remains a third, never-required mode; the fast loop's immediacy is the management game itself. **Confirmed at gate 1 (2026-08-09).** Binds `02-GAME-DESIGN.md`, `06-PLAYED-GAME-MODE.md`.
- **OD-3 — Blocking cards.** Feed cards block the week advance only when the decision has deadline semantics in the sim (contract deadline, lineup, expiring trade offer); everything else is non-blocking. **Approved at gate 1 (2026-08-09); revisit permitted at gate 2 with mockups in hand.** Binds `04-SCREENS-UI.md` feed spec.

- **OD-4 — News-engine casting scope. Closed at gate 3 (2026-08-09).** v1 ships **salience-matched templates**, matching what `02-GAME-DESIGN.md` §11 already rules and §14 already backlogs. The Wildermyth-style casting engine (typed roles, scoring functions, re-voicing — ADJ-44) is a revisit triggered by evidence, not a blocker: if the soak's template-repetition assertion (`03-ARCHITECTURE.md` §6.5) breaches the perceptual-uniqueness bar, escalate.

## Open

- **OD-5 — Citation verification pass.** Independent spot-check of Medium/Low-confidence dossier findings was skipped at owner instruction during gate 1. The gate-3 adversarial pass independently re-verified the load-bearing *source* claims (and corrected several), so the residual risk is confined to research citations that no later document depends on numerically. **Owner to schedule or waive.**
- **OD-6 — Phase 4C test status. Largely resolved 2026-08-09.** The suite ran in a debug build: **324 tests, 18,631 checks, one failure.** Phase 4C compiles and its ~1,100 lines of arcade tests pass, so the multi-agent review that stood in for a compiler held up. The single failure is a performance assertion, not a correctness one:

  `SeasonTests.swift:218` — "advancing a week is fast enough to feel instant: 398 ms per week exceeds the 150 ms budget."

  **This is the same defect the gate-3 verification found in the docs, now confirmed in the code.** Two things are true and both need action:
  1. **The test has no build-configuration guard.** 398 ms is an *unoptimized debug* measurement; the 150 ms budget assumes release. A performance gate that silently runs under debug produces a meaningless failure — and, worse, would produce a meaningless *pass* if the budget were loose. It must skip with an explicit notice outside release builds.
  2. **The budget itself is still unverified on device.** `03-ARCHITECTURE.md` §6.6 now states the honest basis (sim-only <150 ms on the dev Mac, end-to-end <350 ms on an A15), but no one has measured the A15 number. Until someone does, treat it as a target, not a gate.

  **Remaining for OD-6:** re-run in release (`swift run -c release SimTests`) on a machine with enough memory — the earlier attempt was OOM-killed — and add the configuration guard.
