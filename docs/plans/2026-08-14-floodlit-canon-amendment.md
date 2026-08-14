# Phase 0 — Adopt Floodlit in canon

**Phase:** the documentation prerequisite to `05` P11a/P11, and to the whole M8 production-UI block.
**Scope:** documentation only. No Swift is written in this phase and nothing is compiled.

`CLAUDE.md` requires each phase plan to be produced by `superpowers:writing-plans` and saved here.
**That skill is not present in this container** — there is no `.claude/skills/` directory and
`docs/superpowers/` holds only past plans and specs. This plan is therefore hand-written in the style
of its neighbours, and the deviation is recorded rather than hidden.

---

## Why this phase exists

The owner has adopted **Floodlit** as the design direction for all 62 screen families. Floodlit is a
single committed dark world — lit turf, glass panels held at depth under one light, arc gauges, film
grain, condensed display type and asymmetrically cut panels. Canon currently describes a different
system: a matte, opaque, violet dual-appearance desk language whose values are written into `04` §6.1
and shipped in `Sources/ProFootballCoachUI/DesignTokens.swift`.

Two rules make documentation the first task rather than an afterthought:

1. **`CLAUDE.md`'s doc-first amendment rule** — a design or gameplay question gets answered in canon
   first, then implemented. Never encode a decision only in code.
2. **`DesignContractTests` reads canon at run time.** `DesignContractTests.swift:136` computes
   `shipped.subtracting(canonValues)` over the hex literals in `DesignTokens.swift` and fails if the
   set is non-empty. A Floodlit colour that is not written into `04` §6.1 with its measured ratio is
   a red build, not a style debate. `:238` applies the same rule to the eight reference sheets.

So canon moves first, and Phase 1 implements against it.

## What is *not* changing

- The product premise stays **The Coach's World** (`04:12`). Floodlit is registered as its visual
  language. No `CoachWorld*` type is renamed, so `04:477`'s 1:1 registry contract and the
  `ContractTests` source scans survive intact.
- **Both appearances stay** (owner decision, this session). D12, `04` §7 and `04` §10 are unchanged;
  a light "day register" is derived rather than dropped.
- The `04` §4.5 density budget governs where it conflicts with Floodlit's sparseness (owner decision,
  this session). Floodlit supplies the visual language; it does not lower the density bar.
- The spacing scale stays `4, 6, 8, 12, 16, 20`. Floodlit's 7/9/11/14/15/21 snap to it — cheaper
  than amending, and it keeps `ContractTests.swift:691`.
- The eight `*-v3.dc.html` sheets stay at the repository root. They keep the authority the manifest
  already gives them — composition, states and the density model applied — and lose only their value
  authority, which `04` always owned.

---

## Task 1 — Derive the palette and measure it *(done)*

Method: WCAG 2.2 relative luminance, the same method `04` §6.1 already uses. Floors 4.5:1 for body
text, 3:1 for large text and non-text indicators.

**Three findings that change what gets written, none of which were visible by inspection.**

**F1 — Floodlit's quiet ink fails the body floor.** `Palette.ink3 #65788F` measures **4.37 / 3.85 /
3.32** on page / work / raised. It is below 4.5 on all three surfaces and barely above the non-text
floor on `raised`. Lifted to **`#8496AC`** it measures 6.55 / 5.76 / 4.97 and passes. This is a
defect in Floodlit as delivered, corrected here rather than shipped.

**F2 — a standard glass panel cannot carry body text over a lit world.** `GlassPanel`'s standard
fill is white at 0.055; over the brightest point of the lit pitch (`turfHot #37A868`) it composites
to `#42AD70`, on which `content.primary` measures **2.69** and `content.secondary` **1.42**. The deep
panel is the fix, but Floodlit's deep fill of `#08070E` at **0.70** still leaves `content.quiet` at
**4.30** over that worst case. At **0.78** it reaches 5.03 and clears the floor over every world:

| Deep panel at 0.78 over | composite | primary | secondary | quiet |
|---|---|---|---|---|
| lit turf, brightest point | `#122A22` | 14.52 | 7.68 | 5.03 |
| turf | `#0C1E19` | 16.49 | 8.72 | 5.71 |
| facility | `#0A0C18` | 18.58 | 9.83 | 6.43 |
| night | `#08080F` | 19.05 | 10.08 | 6.60 |
| film room | `#0A0910` | 18.91 | 10.01 | 6.55 |

Canon therefore states the deep fill at **≥0.78** and makes the panel-depth choice a contrast rule
rather than a taste one: **body text over a lit world requires the deep panel.**

**F3 — the state roles need Floodlit's own fill/ink split written down.** `live #FF3B54` measures
5.67 / 4.98 / **4.30** — a non-text and large-text value, not a body-text one, exactly like canon's
existing 4.23 violet case. Floodlit already ships the answer as `liveInk #FF8E9C` (9.06 / 7.96 /
6.87). Canon records both: the fill colours chips and indicators, the ink carries text.

### The derived surfaces

| Role | Dark | Light |
|---|---|---|
| `world.page` | `#060A12` — Floodlit `night` | `#EDF1F6` |
| `world.work` | `#141A26` | `#FAFBFD` |
| `world.raised` | `#1E2735` | `#DCE3EC` |

The dark values sit on Floodlit's own composites: white at 0.055 over `night` resolves to `#14171F`,
which `world.work` rounds to a usable step. These are the **opaque equivalents** — what a panel
measures as for contrast purposes, and the flat fallback when the blur budget is exceeded.

### The derived roles — worst pairing in each appearance

Every role clears 4.5:1 against all three surfaces in both appearances. Worst pairing: **4.97 dark**
(`content.quiet` on `raised`), **4.78 light** (same role, same surface).

| Role | Dark | on page / work / raised | Light | on page / work / raised |
|---|---|---|---|---|
| `content.primary` | `#F6FAFF` | 18.90 / 16.62 / 14.34 | `#0B111C` | 16.66 / 18.25 / 14.62 |
| `content.secondary` | `#A9BACE` | 10.00 / 8.79 / 7.59 | `#414B5C` | 7.76 / 8.50 / 6.81 |
| `content.quiet` | `#8496AC` | 6.55 / 5.76 / 4.97 | `#566274` | 5.45 / 5.97 / 4.78 |
| `action.primary` | `#FFC53D` | 12.55 / 11.04 / 9.53 | `#7A5200` | 6.10 / 6.68 / 5.35 |
| `action.secondary` | `#A9BACE` | 10.00 / 8.79 / 7.59 | `#414B5C` | 7.76 / 8.50 / 6.81 |
| `action.destructive` | `#FF8E9C` | 9.06 / 7.96 / 6.87 | `#A3202F` | 6.60 / 7.23 / 5.79 |
| `state.live` | `#FF8E9C` | 9.06 / 7.96 / 6.87 | `#A3202F` | 6.60 / 7.23 / 5.79 |
| `state.positive` | `#7DF0B6` | 14.16 / 12.45 / 10.75 | `#14653C` | 6.26 / 6.86 / 5.49 |
| `state.warning` | `#FFB03A` | 10.87 / 9.56 / 8.25 | `#704C00` | 6.80 / 7.45 / 5.97 |
| `state.negative` | `#FF8E9C` | 9.06 / 7.96 / 6.87 | `#A3202F` | 6.60 / 7.23 / 5.79 |
| `state.info` | `#9CC8EE` | 11.24 / 9.88 / 8.53 | `#1E5A8C` | 6.39 / 7.00 / 5.61 |
| `college.identity` | `#C79AE4` | 8.65 / 7.61 / 6.57 | `#6A3E9C` | 6.65 / 7.29 / 5.84 |
| `pro.identity` | `#9CC8EE` | 11.24 / 9.88 / 8.53 | `#26608D` | 5.90 / 6.46 / 5.17 |

State **fills**, which colour chips and indicators rather than text: `live/negative #FF3B54`
(5.67 / 4.98 / 4.30 — non-text and large text only), `positive #37E08A` (11.50 / 10.11 / 8.73),
`warning #FFB03A` (10.87 / 9.56 / 8.25), `info #6FA8DC` (7.84 / 6.89 / 5.95), `college #B07BD6`
(6.27 / 5.52 / 4.76). A filled control inks with the ground: `goldInk #150F02` on the gold fill
measures 12.08, on positive 11.07, on warning 10.47, on live 5.45.

### Field roles

| Role | Dark | on turf / band | Light | on turf / band |
|---|---|---|---|---|
| `field.turf` | `#1C6E42` | — | `#D9E7DD` | — |
| `field.turfBand` | `#1F764A` | 1.12 on turf | `#D0E0D5` | 1.07 on turf |
| `field.line` | `#F5F7FA` | 5.83 / 5.22 | `#0E1218` | 14.69 / 13.68 |
| `field.annotation` | `#FFC53D` | 3.96 / 3.55 | `#7A5200` | 5.41 / 5.04 |
| `field.live` | `#C6F24E` | 4.83 / 4.32 | `#3F6300` | 5.48 / 5.11 |

`field.annotation` at 3.96 is a **non-text indicator** — the first-down rule — and clears the 3:1
floor for that use. Any *label* drawn on the field takes `goldLight #FFE196` (4.90 on turf), and
canon must say so, because the same gold cannot do both jobs.

### Hairlines

Structural rule — `world.raised` over `work`: 1.16 dark, 1.25 light, deliberately near-invisible.
Legible seam — `content.quiet` on `raised`: 4.97 dark, 4.78 light. The mandatory team-fill boundary
stays `content.secondary`. Unchanged in kind from canon; only the values move.

---

## Tasks 2–8 — the amendments

Ordered by dependency: §6.1 first, because the sheets' annotations and Phase 1's `DesignTokens.swift`
both read from it.

| # | File and section | What it must say |
|---|---|---|
| 2 | `04` §6.1 | The tables above. Rewrite the measured-constraints list around F1–F3. Rewrite the closing clause at `:347` — glass, sheen and grain are the system; fake paper, leather, cork and arbitrary decorative shadow remain out; name the blur budget and the deep-panel rule |
| 3 | `04` §6.2, §6.3 | Map Floodlit's `Face` onto the existing ramp; condensed display for Display/Title/Headline. **`Label3` ships at 9 pt and must move to 10–11 pt Caption** — `04b` §8 machine-checks that no authored type falls below 12 pt and §6.2 floors Caption at 10. §6.3 takes `CutCorner`'s radii (panel 4/22/4/22, row 3/14/3/14, action 22/22/22/5) |
| 4 | `04` §5, §6.5, §6.6, §7, §9 | Gold is `action.primary`, never team colour; the six team-colour slots stand. Registry gains Floodlit's primitives at 1:1 Swift naming. Floodlit's drawn marks become a capped closed vocabulary. `Metrics.device` is recorded as a preview reference frame, never a layout constraint. §9 gains the G-06 anchor contract |
| 5 | `04` §8 | Price all 62 families in §4.5's five currencies. Canon says a surface the inventory does not price is a finding; today it prices none |
| 6 | `02`, `03`, `03b` | The new systems as gameplay, the G-06/G-04/G-02 computation contracts as simulation truth, and the persistence and intent-surface consequences |
| 7 | `DOC-MANIFEST.md` §4a + the eight sheets | Record the bounded authority; update the in-sheet ratio annotations to the amended §6.1 |
| 8 | `CLAUDE.md`, `02`, `STATUS.md` | Three stale cross-references, then an honest phase record |

## Gates

G4 (scope) only. G1 and G2 are **not claimable**: this container has no `swift` and the egress policy
refuses `download.swift.org`. No code is written in this phase, so nothing is owed a compiler — but
the phase is not "done" in the `05` sense either, because `DesignContractTests` cannot be run here to
prove the amended canon and the shipped tokens agree. That check runs on the host at the end of
Phase 1, and `STATUS.md` records it as outstanding until it does.

## Risk carried into Phase 1

The sheet lint (`DesignContractTests.swift:238`) rejects any contrast ratio in a sheet that canon does
not state. Amending §6.1 without updating all eight sheets in the same phase turns the suite red.
Task 7 is therefore not optional and not deferrable.
