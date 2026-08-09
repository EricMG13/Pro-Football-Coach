# Open Decisions Log

Owner decisions for the rebuild program. Each entry: decision, status, date, and where it binds. The Opus 5 build run stops and asks when a blocking item here is unresolved.

## Resolved

- **OD-1 — Voice amendment.** In-fiction media voices (beat writer, columnist, radio host) carry personality license; the system voice stays sober and declarative, no exclamation marks. **Approved at gate 1 (2026-08-09, owner: "next" on the recommended defaults).** Binds `DESIGN.md` §Voice, `PRODUCT.md` §Brand.
- **OD-2 — Retro Bowl's role.** On the Field remains a third, never-required mode; the fast loop's immediacy is the management game itself. **Confirmed at gate 1 (2026-08-09).** Binds `02-GAME-DESIGN.md`, `06-PLAYED-GAME-MODE.md`.
- **OD-3 — Blocking cards.** Feed cards block the week advance only when the decision has deadline semantics in the sim (contract deadline, lineup, expiring trade offer); everything else is non-blocking. **Approved at gate 1 (2026-08-09); revisit permitted at gate 2 with mockups in hand.** Binds `04-SCREENS-UI.md` feed spec.

- **OD-4 — News-engine casting scope. Closed at gate 3 (2026-08-09).** v1 ships **salience-matched templates**, matching what `02-GAME-DESIGN.md` §11 already rules and §14 already backlogs. The Wildermyth-style casting engine (typed roles, scoring functions, re-voicing — ADJ-44) is a revisit triggered by evidence, not a blocker: if the soak's template-repetition assertion (`03-ARCHITECTURE.md` §6.5) breaches the perceptual-uniqueness bar, escalate.

## Open

- **OD-5 — Citation verification pass.** Independent spot-check of Medium/Low-confidence dossier findings was skipped at owner instruction during gate 1. The gate-3 adversarial pass independently re-verified the load-bearing *source* claims (and corrected several), so the residual risk is confined to research citations that no later document depends on numerically. **Owner to schedule or waive.**
- **OD-6 — Phase 4C test status.** The all-22 arcade work now compiles (first build, 2026-08-09), but `swift run -c release SimTests` was not completed in that session — the release build was killed for memory. **Run the suite before trusting 4C**, per its own note in `docs/STATUS.md`.
