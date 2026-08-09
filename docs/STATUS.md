# Build Status

The honest picture: what exists, what is verified, what is not.

**Read this first, before believing any other document about the state of the build.**

---

## Where the project actually is

**The spec package is complete. No line of the rebuild has been written.**

The v4 brief (`docs/reviews/2026-08-09-spec-prompt-v4.md`) has been executed: research, design,
architecture, plan, decisions and the build prompt all exist and are internally consistent. Phase P0
of `docs/05-IMPLEMENTATION-PLAN.md` has not started, and it is **blocked** — see D11 below.

The previous build's source is still in the tree (`Sources/`, `Tests/`, `App/`). Under Tier C it has
**no authority**. It has not been deleted, because deleting it is P0's business and P0 has not run.
Do not treat anything in `Sources/` as canon; `docs/DOC-MANIFEST.md` is the authority on what is.

---

## What exists, and what verified it

| Artefact | State | Verified by |
|---|---|---|
| `CLAUDE.md` | Rewritten as Deliverable 0 | Read by hand; consistent with `08` |
| `docs/DOC-MANIFEST.md` + archival | Done; anti-canon moved to `docs/archive/` | `git status` shows the moves; `README.md` repointed |
| `docs/01-RESEARCH.md` | 7,300 lines, §6.0–§6.5 plus carried-forward §A–§H | Adversarial completeness critic; two defects found and fixed |
| `docs/04b-AUDIT-RUBRIC.md` | Reconstructed from `AUDIT.md` evidence | **Not** extracted from the tool — see caveat below |
| `docs/02-GAME-DESIGN.md` | Written | Not independently reviewed |
| `docs/03-MATCH-ENGINE.md` | Written | Not independently reviewed |
| `docs/03b-ARCHITECTURE.md` | Written | Not independently reviewed |
| `docs/04-UX-AND-DESIGN-SYSTEM.md` | Written | Not independently reviewed |
| `docs/05-IMPLEMENTATION-PLAN.md` | Written | Not independently reviewed |
| `docs/06-AUDIT-DISPOSITION.md` | 25 P0/P1s + 5 patterns dispositioned | Finding titles extracted mechanically from `AUDIT.md` |
| `docs/OPEN-DECISIONS.md` | D1–D14, each with an instrumented falsifier | D11 escalated, not decided |
| `docs/PRE-DEPLOYMENT-CHECKLIST.md` | Authored | — |
| `docs/08-OPUS5-BUILD-PROMPT.md` | Written as a phase-entry prompt | — |
| `PRODUCT.md` | Rewritten from the §6.3 gap argument | — |

**Nothing in this table has been compiled, because there is nothing to compile yet.**

---

## Blocking: D11 — test strategy under the real toolchain

**P0 cannot start until the owner decides this.**

Verified in this container, not assumed:

```
swift: NOT FOUND    swiftc: NOT FOUND    xcodebuild: NOT FOUND
xcrun: NOT FOUND    simctl: NOT FOUND    uname: Linux
```

The historical record is the same: no agent environment in this project has had a Swift toolchain,
neither XCTest nor swift-testing ships with the Command Line Tools, and `download.swift.org` is
refused by the organisation's egress policy with a 403 on `CONNECT`. **Phase 4C of the previous
build shipped having never been compiled as a direct result** — and the failure was not the missing
toolchain, it was claiming otherwise.

Every "tests green" gate in `05`, and the whole machine-verifiable half of the definition of done,
depend on the answer. The options and a recommendation are in `docs/OPEN-DECISIONS.md` D11.

---

## Decisions made without owner input

The owner was asked and did not answer, so these were decided during execution and are marked
reversible. They are called out here because they are the ones most worth overturning if wrong:

- **D14 build order: college first.** The player starts there and both unsolved risks live there.
- **D14 league size: ~134 programmes**, with an explicit fallback to ~64 if D4's week-advance ceiling
  cannot be met at that scale.

---

## Caveats on the spec package itself

Stated plainly so nothing here is mistaken for more than it is.

1. **`04b` is reconstructed, not extracted.** The rubric was reverse-engineered from `AUDIT.md`'s
   evidence because `/impeccable` was not available. Re-run the tool and paste its rubric verbatim to
   make it authoritative.
2. **Three accessibility premises are UNVERIFIED.** The 44 pt touch-target floor, Apple's exact
   Reduce Motion semantics, and the SwiftUI API for suppressing `TimelineView` updates were cited
   from memory — `developer.apple.com` returned no readable body through the proxy. Confirm against
   the HIG before implementing D12.
3. **D1's timing constants are proposals, not measurements.** The seconds-per-call-in and
   seconds-per-drive-summary figures that the gate-zero arithmetic multiplies by need the owner
   protocol in `01-RESEARCH.md` §6.0 §8 and one layout measurement in Xcode.
4. **Recruiting-AI cost across ~134 programmes has never been measured.** D4's dominant
   week-advance term is an estimate. P5 of the plan is where it gets tested, and where D14's
   fallback fires if it fails.
5. **The engagement post-mortem's experiential half is unrun.** §6.0's static census is complete and
   its findings are strong — one mandatory decision per week, zero inbound events, jeopardy frozen
   for a season, 22 of 24 skill nodes inert. The play-session protocol is written but needs the owner
   and a running build.
6. **Most of the design documents have not been independently reviewed.** Only `01-RESEARCH.md` went
   through an adversarial critic.

---

## What the previous build was

Retained as Tier B evidence, not as a mandate. Its engine was calibrated, had 224 tests and 13,226
assertions, a ten-season soak, cross-process determinism (fixed the hard way — `UUID.hashValue` is
salted per launch), and bounded save growth (8.3 MB → 2.3 MB). Its UI scored 9/20. Its management
week contained one mandatory decision.

Full detail in `docs/AUDIT.md` and `docs/01-RESEARCH.md` §6.0.
