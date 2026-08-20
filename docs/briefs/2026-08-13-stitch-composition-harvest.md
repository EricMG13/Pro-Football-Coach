# Stitch composition harvest — 2026-08-13

**Status: proposal to the owner, not a decision.** Nothing here has been applied to `04`, to the eight
`*-v3.dc.html` sheets, or to any view. Under the `CLAUDE.md` doc-first amendment rule, each adopted
item below has to land in `04` before it is drawn or built. The `*-v3.dc.html` sheets remain
owner-approved as of 2026-08-12 and are not modified by this brief.

**What was run.** Google Stitch (remote MCP, `stitch.withgoogle.com`) was connected and asked to
redesign each of the eight design-reference sheets, for **composition and UX ideas only** — never for
values. A `DESIGN.md` derived from `04` §6.1–§6.3 production values seeded a Stitch design system so
the output would sit in the right visual world. Boards and their per-board verdicts are in
`docs/proofs/stitch-2026-08-13/`.

**Headline judgement.** The tool is not competitive with the v3 sheets as a producer of finished
references — three of eight boards failed outright on density, appearance or legibility, and the
values it prints are untrustworthy. It is, however, useful as an idea generator: **nineteen ideas
below survive scrutiny, and five of them are better than what the sheets currently do.** The five are
marked **[P1]**.

---

## 1. Adopt — the five that beat what we have

### 1.1 [P1] The verdict line is a band, not a card — `sheet5-readout.png`

Stitch drew registry 13 `VerdictLine` as a single full-width strip immediately under the world strip:

```
(i)  Opponent pass defense is vulnerable to deep explosives.  | SC O'MALLEY (240 snaps, HIGH CONFIDENCE)   [INSPECT]
```

One band carries the judgement, the staff member who produced it, the sample size, the confidence and
the one-tap route to the evidence. That is the entire `04` §6.5 verdict contract in roughly 22 pt of
vertical space, and it costs a fraction of the points a card costs. The current sheets spend
considerably more height on the same obligation.

**Why it is better:** §4.5 says pixels are spent before taps and working memory is never spent. A band
pinned under the world strip means the verdict is never off-screen while the reader works the readout
beneath it, so the comparison and its judgement stay on one surface.

### 1.2 [P1] Shipping form and target form as two adjacent slots — `sheet5-readout.png`

The §6.5 verdict-state rule ("draw both states and label them") was drawn as two side-by-side slots
of identical geometry:

- **SHIPPING FORM** — an empty verdict slot reading `no engine baseline yet [B-404]`
- **TARGET FORM** — the populated verdict with staff, sample and confidence

Same width, same height, same position. The reader sees that the populated form is a *fill* of the
shipping form, not a different component. This is the cheapest possible way to make the rule
unmissable, and it makes the gap identifier a first-class printed value rather than a footnote.

**Amendment needed in `04` §6.5** if adopted: state that the two forms share geometry and that the gap
ID prints inside the empty slot.

### 1.3 [P1] The ink rule taught by showing the failure — `sheet1-tokens.png`

Two identical violet `action.primary` buttons stacked:

- `CORRECT (5.02)` — dark `world.page` ink
- `LARGE TEXT ONLY (3.61)` — white ink

The `04` §6.1 filled-control ink rule currently lives as prose. Drawing the passing and the failing
pairing adjacently, each printing its own measured ratio, converts a paragraph into a two-second read
and makes the 3.61 case impossible to reach for by accident.

**Note:** 5.02 and 3.61 are the real measured values from `04` §6.1. This is the one place Stitch
printed correct numbers, because they were given to it. Everything it derived itself was wrong — see
§4.

### 1.4 [P1] Confidence drawn as one element carrying both band and count — `sheet4-person.png`

Stitch collapsed registry 12 `ConfidenceTag` into a single filled track sitting in the attribute row,
whose fill width *is* the confidence and whose printed label *is* the observation count:

```
SPEED    94 ↗   [████████████  MAX (24 OBS)  ]
```

One element, two facts, survives greyscale, costs one column. The current treatment separates the
band from the count. The four-state escalation it drew beneath — `--` / `62-84` / `71-77` / `74`, each
with its count — is also cleaner than a tinted tag ladder, because the **range width does the work and
the tint is decoration**, which is exactly the §6.3 boundary-value-spoken posture.

### 1.5 [P1] Over-capacity as a geometric breach — `sheet5-readout.png`

The over-capacity `Meter` state was drawn as the fill **physically overrunning its track boundary**,
with `+20` printed at the break. Shape carries the state; colour is redundant. Registry 14 requires a
"defined over-capacity state" but does not say it must differ in shape. It should.

---

## 2. Adopt — worth taking, not revolutionary

| # | Idea | Board | Registry |
|---|---|---|---|
| 2.1 | World strip, column-set segment, sort, filter and search collapsed into **one two-row header band** — tighter than three separate rows | 3 | 5, 8, 9 |
| 2.2 | Capacity meter parked at the **top of the trailing rail** (`SCHOLARSHIPS 82 / 85`) with position counts beneath, the selected position row cross-highlighted with the table | 3 | 14 |
| 2.3 | Depth slot as a **small square swatch in a leading `D` column**, not a text chip — scannable, leaves the name column wide | 3 | 7 |
| 2.4 | Selection as a **full-height leading bar plus boundary**, no fill — satisfies §6.3 without spending colour | 3 | 7 |
| 2.5 | `ColumnSet` taught as **two side-by-side mini-tables of the same rows** under different column sets — identity stays, facts rotate | 3 | 8 |
| 2.6 | Status as a **dedicated trailing column** rather than chips floating inside the row | 3 | 17 |
| 2.7 | A state chip **carrying its own value inline** — `INJURED · 3 WK` — value beside state, per §6.1 | 3 | 17 |
| 2.8 | Delta rows printing **the VoiceOver sentence visibly beside the mark** ("Speed 94, up 2 since Week 4"), including the no-change row captioned "absence is a state, not a blank" | 4 | 11 |
| 2.9 | `FormLine` as ten discrete blocks with a thin rating thread beneath and a printed summary (`6-3-1, AVG 7.2`) | 4 | 16 |
| 2.10 | Content roles shown as **the same three-line specimen repeated on each of the three surfaces**, ratio triple printed at the foot of each block, dark and light side by side | 1 | — |
| 2.11 | Type ramp printing the **size/leading pair right-aligned on each specimen line** (`Display 20 … 20/24`) | 1 | — |
| 2.12 | Hairline jobs as **two literal hairlines with their ratio pair beneath each** (structural 1.10/1.18, legible seam 4.96/5.12) | 1 | — |
| 2.13 | Touch target as a **44 pt square drawn over a deliberately undersized control** | 1 | — |
| 2.14 | **Register-contrast block**: a DESK button (radius 8, "APPROVE ROSTER") beside a BROADCAST button (radius 0, "SNAP BALL"), captioned with their radii — a teaching device the library currently lacks | 7 | 2 |
| 2.15 | `ScoreBug` as three hard blocks (home / away / clock) drawn in a **pre-snap and live state pair** so the clock difference is visible | 7 | 20 |
| 2.16 | Error banner drawn as an **inline row replacing the ninth table row**, headers and controls still live above it | 8 | 23 |
| 2.17 | Interrupted state as **progress statement + done/pending checklist + RESUME** ("Tactical review 60% complete / Offense scouted ✓ / Defense pending ○") rather than a spinner | 8 | 23 |
| 2.18 | Delegated state carrying **a RECLAIM control and a report-back date** ("SC Scudder (DC) / Staff evaluation / report in 2 days / RECLAIM") — the take-it-back affordance does not exist today | 8 | 19, 23 |
| 2.19 | Empty state carrying **the resolving control inside it** (`NO PLAYERS FOUND` → `CLEAR FILTERS`) | 8 | 23 |

---

## 3. Reject

- **The five-step rating-badge colour ladder** (sheet 3). `04` §6.1 gives heat fills as
  positive/warning/negative only. A five-step ladder is a new colour vocabulary with no owner
  decision behind it, and §4.5 names vocabulary growth as the leak detector.
- **Full-width saturated status bars** (sheet 3). Registry 17 is a compact chip, at most three per
  row. Stitch drew twelve full-width bars, which is a second dominant object.
- **The week grid as drawn** (sheet 6). One filled cell out of 28. Nothing to take.
- **The field as drawn** (sheets 1, 7). Mow bands at data-level contrast, five players instead of
  twenty-two, lower third illegible. Rejected wholesale.
- **Any networked failure state** (sheet 8). No network exists. See §4.

---

## 4. What the tool got wrong that matters

Four of these are worth recording beyond this brief, because they are the failure modes to expect from
any generative design tool pointed at this project:

1. **It fabricates measured values.** Sheet 1 printed five state-role contrast ratios that are not the
   measured values in `04` §6.1. It printed them in the same tabular style as the five correct ratios
   it was handed, with no distinction. **A ratio in a generated board is decoration until it is
   re-measured.**
2. **It assumes a networked product.** Sheet 8 built its whole failure model around data sync, fetch
   and retry-connection. The product is offline by owner constraint with zero network of any kind. A
   generative tool will default to the industry's architecture, not ours, and the failure sheet is
   exactly where that surfaces.
3. **It drifts the palette on import.** The uploaded `DESIGN.md` carried the shipped values; Stitch
   re-derived a Material-style palette around them, pushing `action.primary` from `#9964E8` toward
   `#d6baff` and the ground from `#080A14` to `#11131d`. The override fields held the correct hexes
   while the rendered palette did not. **Composition only. Never values.** This is the concrete reason
   for that rule, not a theoretical one.
4. **It invents authority furniture.** "CONFIDENTIAL", "SYS.VER 4.2.1", "DESK REGISTER V2.4", a 2023
   date. §4.4 rejects invented authority; a generated board will manufacture it by default because it
   reads as professional.

A fifth, less serious: three of eight boards left panels half empty despite an explicit density
instruction in the prompt. Density had to be forced by naming a row count and writing "no empty space"
in capitals, and even then it held only about half the time.

---

## 5. Recommended next step

Take §1 (five items) and §2 (nineteen items) as a single amendment pass on `04` §6.1, §6.3 and §6.5,
then re-render the affected `*-v3.dc.html` sheets from the amended canon by hand. **Do not regenerate
the sheets from Stitch.** The evidence of this run is that it produces ideas at a useful rate and
finished references at an unusable one.

Owner decision needed on:

- whether §1.2 (shared geometry for the two verdict forms) becomes binding in §6.5, since it
  constrains every surface that carries a verdict;
- whether §1.5 (over-capacity must differ in shape) becomes binding in registry 14;
- whether §2.18 (delegated work is reclaimable) is a design commitment, since it implies engine
  support for withdrawing a delegated task, not just a control.
