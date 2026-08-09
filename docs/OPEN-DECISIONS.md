# Open Decisions Log

Owner decisions for the rebuild program. Each entry: decision, status, date, and where it binds. The Opus 5 build run stops and asks when a blocking item here is unresolved.

## Resolved

- **OD-1 — Voice amendment.** In-fiction media voices (beat writer, columnist, radio host) carry personality license; the system voice stays sober and declarative, no exclamation marks. **Approved at gate 1 (2026-08-09, owner: "next" on the recommended defaults).** Binds `DESIGN.md` §Voice, `PRODUCT.md` §Brand.
- **OD-2 — Retro Bowl's role.** On the Field remains a third, never-required mode; the fast loop's immediacy is the management game itself. **Confirmed at gate 1 (2026-08-09).** Binds `02-GAME-DESIGN.md`, `06-PLAYED-GAME-MODE.md`.
- **OD-3 — Blocking cards.** Feed cards block the week advance only when the decision has deadline semantics in the sim (contract deadline, lineup, expiring trade offer); everything else is non-blocking. **Approved at gate 1 (2026-08-09); revisit permitted at gate 2 with mockups in hand.** Binds `04-SCREENS-UI.md` feed spec.

- **OD-4 — News-engine casting scope. Closed at gate 3 (2026-08-09).** v1 ships **salience-matched templates**, matching what `02-GAME-DESIGN.md` §11 already rules and §14 already backlogs. The Wildermyth-style casting engine (typed roles, scoring functions, re-voicing — ADJ-44) is a revisit triggered by evidence, not a blocker: if the soak's template-repetition assertion (`03-ARCHITECTURE.md` §6.5) breaches the perceptual-uniqueness bar, escalate.

## Open

- **OD-5 — Citation verification pass. CLOSED 2026-08-09.** Seven load-bearing claims — the ones R2 actually builds rulings on — were checked against their cited sources by opening them. **Five hold as written. Three corrections were made:**
  1. **MAD-14** (the program's largest finding) — substance verified, but the quoted phrase "lifeless and sterile" was sourced to the wrong Operation Sports article. The verbatim quote exists in a different piece, now cited as [S75].
  2. **ADJ-35** — the staging half is airtight. The *haptics* half rested on a 403 paywall plus a source that partly cuts against it; the claim is true but was mis-cited, now sourced to a reachable review and downgraded from "reviewers single out" to one review's observation.
  3. **FM-27** — Jacobson's kill-decision playtest was about **two** hours, not one. R1c already said "one-to-two"; R2 had tightened it to "one hour". Corrected — our one-hour cold-play gate stands as our own choice of dose, marked `NOVEL`, rather than as a borrowed number.

  Dead or unreachable URLs noted for future cleanup: one BBC link 404s, an Operation Sports forum thread 403s, two x.com links are unfetchable, and two sources return truncated bodies. None is the sole support for a ruling.
- **OD-6 — Phase 4C test status. CLOSED 2026-08-09.** `swift run -c release SimTests`: **324 tests, 18,631 checks, all passed.** Phase 4C compiles and its full arcade suite is green, so the multi-agent review that stood in for a compiler in the session that wrote it held up under a real toolchain.

  A debug run first reported one failure — `SeasonTests.swift:218`, 398 ms/week against a 150 ms budget. That was the unoptimized measurement, not a regression: the release run passes it. The test now guards its build configuration (measures in both, asserts only in release), because a perf gate that runs under debug reports a meaningless failure — and would report a meaningless *pass* if the budget were ever loosened.

  **One residual, tracked in the checklist rather than here:** the end-to-end week-advance budget has still only been measured on a Mac. `03-ARCHITECTURE.md` §6.6 states <350 ms on an A15 as a target; nobody has run it on device.
