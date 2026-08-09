# 09 — Craft Rubric

The scale behind owner gate O1 ("≥17/20 with zero P0/P1"). It exists because a gate nobody can score is not a gate — two runs of the same audit on the same code could otherwise return 16 and 18.

Scored **per phase, against the surfaces that phase touched** — not the whole app every time. The 9/20 baseline in `docs/AUDIT.md` is historical: it measured a UI layer this rebuild replaces.

## The five dimensions, 4 points each

Award the highest point whose criteria are fully met. Partial credit rounds **down**.

### 1. Accessibility

| Score | Criteria |
|---|---|
| 4 | Dynamic Type to XXXL with no truncation or overlap; every tappable ≥44×44pt; VoiceOver reads composed rows as sentences with labels *and* values on custom controls; Reduce Motion variant present and tested for every motion; no state by colour alone |
| 3 | All of the above except one dimension has isolated gaps (e.g. two rows lack composed labels) |
| 2 | Dynamic Type and touch targets hold, but VoiceOver or Reduce Motion is unimplemented on this surface |
| 1 | Multiple commitments from `PRODUCT.md` §Accessibility are unimplemented here |

### 2. Performance

| Score | Criteria |
|---|---|
| 4 | No main-actor I/O; no per-render aggregation over league-scale data; long collections virtualized; measured budgets met; ticking values scoped so they cannot invalidate a whole screen |
| 3 | Budgets met, one structural smell remains (e.g. an unvirtualized bounded list) |
| 2 | A measurable stall exists on a common path but is bounded and known |
| 1 | A blocking main-thread operation on a routine path |

### 3. Appearance & theming

| Score | Criteria |
|---|---|
| 4 | Every colour pairing is in the contrast suite and passes against its real composited surface in both themes; zero token bypasses (no literal spacing, radius, hex, duration, or point size); the One Band Rule holds |
| 3 | All pairings tested and passing; a handful of literals remain |
| 2 | Untested pairings exist, or raw system colours are used as text or chip tints |
| 1 | Measured contrast failures on shipped surfaces |

### 4. Platform conformance

| Score | Criteria |
|---|---|
| 4 | Stock controls throughout; navigation-primitive checklist met (search, back, where-am-I, persistent sort); destructive actions out of the cancellation slot and behind confirmation; correct modality; large titles only at top level |
| 3 | One HIG deviation, deliberate and documented |
| 2 | Several deviations, or a hand-rolled control where a stock one exists |
| 1 | A navigation trap, or an irreversible action in a cancel affordance |

### 5. Feel & staging *(replaces the old "Adaptivity" dimension — adaptivity is now scored inside Accessibility, and feel is what this rebuild exists for)*

| Score | Criteria |
|---|---|
| 4 | Every headline number on the surface has its `DESIGN.md` §2.3 staging spec implemented; feedback fires from the single owner with paired audio/haptics; the surface's first render matches its stated treatment; nothing pays in silence |
| 3 | Staging implemented, one moment lands unstaged |
| 2 | Staging specified but partially implemented; values teleport somewhere |
| 1 | The surface presents outcomes with no staging at all |

## Severity definitions

- **P0** — blocks use, loses data, or breaks the legal or offline constraint. Ships never.
- **P1** — violates a stated commitment in `PRODUCT.md` §Accessibility, `DESIGN.md` §8, or an acceptance spec in `03-ARCHITECTURE.md` §6.
- **P2** — a real defect that does not violate a written commitment.
- **P3** — polish.

O1 requires **≥17/20 and zero P0/P1**. A single P1 fails the gate regardless of score, because P1 is by definition a broken promise this project made to itself.
