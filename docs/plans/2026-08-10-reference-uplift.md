# Reference uplift plan — target 37/40

> **EXECUTED 2026-08-10.** All four phases done. Phase A closed the palette, budget, ceiling,
> ScoreBug and send-back divergences; B added `ListControls` and `AttributeRow`; C added the
> persistence, match-exit and call-in rules; D took AX5 from 2 renders to 8 and light from 1 to 3.
> **Reached 37/40.** Owner decisions taken during execution: light ships as an equal appearance,
> and the all-22 field is kept with the frame redrawn at true 1.15 yd spacing — which showed the
> nine interior linemen can be counted but not numbered, at any supported device.

Written 2026-08-10 after a six-lens adversarial review of the v2 design reference library
(37 agents; 46 raw findings, 31 rated P0/P1, **10 confirmed** after independent refutation).
**Not canon.** `docs/04-UX-AND-DESIGN-SYSTEM.md` remains the only home for the design system.

---

## 1. Where the score actually is

The brief was "aim for 31 or higher". The library **is** at 31/40 — but the composition moved
under today's work, and that is the useful finding:

| # | Heuristic | Was | Now | Why it moved |
|---|---|---|---|---|
| 1 | Visibility of System Status | 3 | **4** | `ProgressState` drawn: determinate, results land during the wait |
| 2 | Match System / Real World | 4 | 4 | Holds — broadcast idiom plus engine-grounded vocabulary |
| 3 | User Control and Freedom | 2 | **2** | No undo, no match exit, no call-in pause, no cold-launch resume |
| 4 | Consistency and Standards | 3 | **2** | Review found `ScoreBug` specified four ways, the budget three ways, 18 of 22 hexes diverging from canon |
| 5 | Error Prevention | 3 | 3 | |
| 6 | Recognition Rather Than Recall | 3 | 3 | |
| 7 | Flexibility and Efficiency | 2 | **2** | Not one filter, sort, search or multi-select in fourteen files |
| 8 | Aesthetic and Minimalist | 4 | 4 | |
| 9 | Error Recovery | 4 | 4 | |
| 10 | Help and Documentation | 3 | 3 | |
| | **Total** | **31** | **31** | Status quo, by coincidence |

**Three heuristics sit at 2 and they are worth six points.** Everything below is organised around
those three, because polishing the 4s cannot move the total and fixing the 2s takes it to **37**.

---

## 2. What survived adversarial review

Ten findings, after 21 of 31 were refuted. The refutation rate is the point: what remains is not
one reviewer's taste.

**Already fixed today, before this plan was written** — three were too serious to defer:

1. **LEGAL.** The pro tier shipped as *Detroit Motors*, and `Detroit` is in the project's own
   `Blocklist.swift:149` — `blocks("Detroit Motors")` returns `true`. The reference library was
   carrying a name our own legal gate rejects, under a disclaimer saying the opposite, across four
   files. Now *Verrick Foundry* / *Calloway Sentinels*, with a full blocklist sweep of the corpus
   returning clean. **The trade dress was fine** (ΔE 32.6 against the nearest real pair) — the
   defect was the name alone.
2. **The `ScoreBug` hairline fix was arithmetically false.** `rgba(255,255,255,.22)` composites to
   `#383838` — 1.79:1, not the claimed 3.4:1. Solved rather than guessed: alpha 0.56 is the first
   value clearing 3:1 on both edges; the token is `#9E9E9E` for margin (7.84 block, 3.86 turf).
3. **The all-22 frame draws linemen at 2.17× true spacing** — 16 pt centres where 1.15 yd is
   7.4 pt — and the claim that `04` §5.2 "already required" it inverts what §5.2 says
   (*"individually numbered marks on the two lines remain geometrically impossible"*). The
   amendment request is **withdrawn** until the frame is redrawn at true spacing. This was the
   library's headline claim and it was cheating.

**Outstanding, and scheduled below:** stale send-back panels, AX5 on 2 of 18 frames, the
tautological touch-target overlay, tinted rating numerals in three files, the anisotropic ceiling.

---

## 3. Phase A — Consistency (2 → 4, +2)

The cheapest two points, and the ones that stop the library lying to P11.

| Task | Detail |
|---|---|
| **A1. One palette** | 18 of 22 colour roles in the v2 files diverge from `04` §2.1, because §2.1 still holds the *v1* values and the broadcast world replaced them. Either write the v2 palette into §2.1 or revert the files. **Decide, then make one true.** |
| **A2. One `ScoreBug` spec** | Specified four different ways across Tokens, Components, Screens and Broadcast. Collapse to one, in `04` §3, and have the others cite it. |
| **A3. One content budget** | Stated as 303, 347 and 369 in different files. All three are correct *for different chrome*; none says which. One table: match view 369, management 347 without the bar, 303 with it. |
| **A4. Purge the send-backs** | Twelve-plus items in the "SENDS BACK TO 04" panels are already canon, several verbatim. Re-derive every panel against current `04`. Genuinely-new items: `live`, `numeral`, the dark ladder, kit-clash ΔE, `Sparkline` bars-only, `ProgressState`, `ConfirmSheet`. |
| **A5. Fix the ceiling** | Drawn 873 × 398 = 7.28 across, 7.46 down. Set to 873 × 388, matching canon's own derived figure. |
| **A6. Kill tinted rating numerals** | Career, FirstRun and League render ladder colours as text — banned by `04` §2.1 rule 1, which this library wrote. Worst is 3.01:1. Replace with white on a ladder fill, as Components already does correctly. |

---

## 4. Phase B — Throughput (2 → 4, +2)

**Alex's finding, and the strongest single gap: no filter, sort, search or multi-select exists
anywhere in fourteen files or a twenty-entry registry.** FM's actual answer to list density is
column-preset views, position filters and sorting, and the library learned none of it.

| Task | Detail |
|---|---|
| **B1. `ListControls`, one component** | Position filter, sort, and a saved column preset. One primitive serving Roster, recruiting board, free agency and the draft board. Registry entry 21. |
| **B2. Multi-select and batch** | Two drawn verdicts already instruct batch operations. Cut/redshirt/shortlist in bulk on a 105-player roster. |
| **B3. The player card gets attributes** | FM's single strongest desk pattern — a tinted value bar behind each attribute row, banded numerals — and the card currently shows none at all. This is the screen Alex opens most and it is the emptiest. |
| **B4. Roster at full density** | Drawn as a 4-row fragment. Draw it at 6 rows with controls, at the floor, in a frame. |

---

## 5. Phase C — Interruption (2 → 4, +2)

**Casey's finding. The prose calls this "a commute game" twice and designs for it zero times.**

| Task | Detail |
|---|---|
| **C1. Save cadence, stated** | Implied at two different values, ruled nowhere. One sentence in `04`, one indicator in Settings. |
| **C2. Cold-launch resume** | No surface covers returning mid-week, mid-draft or mid-match. The Title screen's Continue card is the natural home and currently states only week and record. |
| **C3. The match has an exit** | ~10.5 minutes, uninterruptible, no drawn exit. Needs a leave-and-resume that cannot change the outcome (`03` §1.3). |
| **C4. The call-in clock gets a rule** | The once-a-season draft clock got an expiry rule; the ~25-per-match call-in did not. Expiry is a deferral, not a dismissal. |

---

## 6. Phase D — Coverage (holds the 4s)

Does not move the score by itself; without it Phases A–C are asserted rather than shown.

- **AX5 from 2 frames to 8**, prioritising Failure (longest copy, most constrained) and the match view.
- **Light from 1 frame to 4**, or the owner declares dark-only and `04` §6 is amended. **This is an
  owner decision and it is cheaper than the work** — ask before drawing three more.
- **A season-shape surface.** FM's calendar has no equivalent here and the schedule is 17–21 rows
  of `ScoreBug`, which the review's arithmetic says does not fit.
- **Redraw the all-22 frame at 7.4 pt centres** and report honestly what survives.

---

## 7. Sequence and cost

| Phase | Points | Effort | Blocks |
|---|---|---|---|
| A — Consistency | +2 | Low. Mostly reconciliation, no new design | Nothing. Do first |
| B — Throughput | +2 | Medium. One new component, three screens redrawn | Needs A1's palette settled |
| C — Interruption | +2 | Medium. Four rules, two new surfaces | Independent of A and B |
| D — Coverage | 0 | Medium | Needs the light decision from the owner |

**A → C → B → D.** A is free and stops the drift compounding; C is independent and closes the
persona gap that most threatens retention; B is the largest design task; D confirms.

**Target 37/40.** The three remaining 3s (Error Prevention, Recognition, Help) are held down by
things this library cannot fix on its own — they need P7–P10 mechanisms to exist first.

---

## 8. Two questions for the owner

1. **Light, or dark-only?** One frame of eleven exercises it, and drawing three more is real work.
   Dark-only is defensible for a broadcast product and needs a `04` §6 amendment, not silence.
2. **Does the all-22 field survive true spacing?** If five linemen inside 29 pt at the floor is
   illegible — and it probably is — then `04` §5.2's original conclusion was right and the
   honest answer is numbered skill positions with the line as one shape. That is a design
   reversal, and it should be decided on a redrawn frame rather than on either of our assertions.
