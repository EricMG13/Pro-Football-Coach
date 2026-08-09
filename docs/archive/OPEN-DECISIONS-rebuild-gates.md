# Open Decisions Log

Owner decisions for the rebuild program. Each entry: decision, status, date, and where it binds. The Opus 5 build run stops and asks when a blocking item here is unresolved.

## Resolved

- **OD-1 — Voice amendment.** In-fiction media voices (beat writer, columnist, radio host) carry personality license; the system voice stays sober and declarative, no exclamation marks. **Approved at gate 1 (2026-08-09, owner: "next" on the recommended defaults).** Binds `DESIGN.md` §Voice, `PRODUCT.md` §Brand.
- **OD-2 — Retro Bowl's role.** On the Field remains a third, never-required mode; the fast loop's immediacy is the management game itself. **Confirmed at gate 1 (2026-08-09).** Binds `02-GAME-DESIGN.md`, `06-PLAYED-GAME-MODE.md`.
- **OD-3 — Blocking cards.** Feed cards block the week advance only when the decision has deadline semantics in the sim (contract deadline, lineup, expiring trade offer); everything else is non-blocking. **Approved at gate 1 (2026-08-09); revisit permitted at gate 2 with mockups in hand.** Binds `04-SCREENS-UI.md` feed spec.

## Open

- **OD-4 — News-engine casting scope.** v1 floor: salience-matched templates (R1d ADJ-48). Option: Wildermyth-style casting engine (typed roles, scoring functions, personality re-voicing — ADJ-44). **Decide at gate 3 (architecture) with template-library sizing math in hand.**
- **OD-5 — Citation verification pass.** Independent spot-check of Medium/Low-confidence dossier findings was skipped at owner instruction during gate 1. Recommended as a background pass before gate 3 locks engine acceptance specs. **Owner to schedule or waive.**
