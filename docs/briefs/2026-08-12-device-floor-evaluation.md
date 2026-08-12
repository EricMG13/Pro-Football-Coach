# Device-floor evaluation — what moving to "iPhone 15 Pro and newer" actually buys

**Destination:** `docs/briefs/2026-08-12-device-floor-evaluation.md`. **Working input, not canon.**
Carries Outcome 3 of the brief. §6 is a **proposed `docs/OPEN-DECISIONS.md` entry (D15)** in the
register's format; it is a proposal only and the decision is the owner's. This file presents the
case and the cost and **does not close it**.

Verification state, per the brief's instruction to verify what is used and mark what cannot be:
**no device point size, safe-area inset, or chip assignment below is verified.** Canon marks them
ASSUMPTION (`01-RESEARCH.md` AS-6.5-01; the superseded `04` §5.2, recoverable at
`git show a60f4d9:docs/04-UX-AND-DESIGN-SYSTEM.md`, whose numbers this file reuses), and this
session ran no retrieval. The verification queries are rows Q4–Q5 of
`docs/briefs/2026-08-12-sourcing-log.md`, pending owner approval. The one tree-evidenced size is
956 × 440 for the iPhone 17 Pro Max viewport, asserted by `docs/proofs/README.md` against captures
that exist in `docs/proofs/personnel/`. The 44 pt touch floor remains UNVERIFIED (AS-6.5-08) and is
used here as canon uses it.

---

## 1. The levers, separated

Three separable things travel under "raise the device floor," and the proposal moves them
differently:

| Lever | Today (canon) | Under the proposal |
|---|---|---|
| **Deployment target** | iOS 26+ (`CLAUDE.md`, `docs/STATUS.md` baseline) | Unchanged. No API is gated on device here |
| **Design window** (layout floor/ceiling) | 844 × 390 through 932 × 430 (`04` §7) | Floor 852 × 393 *only if* the e-class leaves the promise; ceiling must move regardless — see §2 |
| **Support promise** (release-tested, performance-evidenced) | iPhone 15-generation and newer (`docs/STATUS.md` 2026-08-11 baseline), floor kept at 844 × 390 because the later compact `e` models are smaller than the base iPhone 15 | iPhone 15 Pro and newer — which excludes the base 15/15 Plus and, on one reading, the `e` line |

**The proposal is ambiguous on the reading that decides everything.** "iPhone 15 Pro and newer" by
release date includes the `e` models (844 × 390-class, currently sold); by class it excludes them.
If the `e` line stays in the promise, **the layout floor does not move at all** and the proposal
changes only the performance baseline. This is returned as an owner question rather than resolved.

## 2. The window is already wrong, independent of the proposal

`04` §7's window tops out at 932 × 430. The support promise is 15-generation **and newer**, and the
tree's own proofs render at **956 × 440** (`docs/proofs/README.md`;
`docs/superpowers/plans/2026-08-12-fm-touch-personnel-examples.md` names that device as the primary
proof target). The Pro-class sizes from the 16 generation onward (874 × 402 and 956 × 440, both
UNVERIFIED from memory) sit outside the declared window. So whichever way the floor decision goes,
the ceiling needs re-deriving from a verified device table — the window as written excludes devices
the promise includes, and the tree has already walked through the gap. This is register entry G-09.

## 3. The arithmetic

Baseline numbers from the superseded `04` §5.2 (insets ~59 pt sensor edge, ~21 pt home edge, both
ASSUMPTION; management screens keep a 22 pt status bar; the match view hides it):

| Device class | Points | Usable match canvas | Field scale | Management height (status bar on) |
|---|---|---|---|---|
| `e` / old base class — current floor | 844 × 390 | 785 × 369 | 6.54 pt/yd | 347 pt |
| 15/16 base and Pro class — proposed floor | 852 × 393 | 793 × 372 | 6.61 pt/yd | 350 pt |
| Plus/Max class — current ceiling | 932 × 430 | 873 × 409 | 7.28 pt/yd | 387 pt |
| 17 Pro Max class — tree's proof device | 956 × 440 | 897 × 419 | 7.48 pt/yd | 397 pt |

What the floor move (844 × 390 → 852 × 393) is worth, axis by axis:

- **Field scale:** 6.54 → 6.61 pt/yd, **+1.1 %**. Line-of-scrimmage clustering is unchanged in kind
  (adjacent linemen ~7.5 → ~7.6 pt centres); nothing that was illegible becomes legible.
- **Management rows:** 347 → 350 pt of working height. At the `04` §6.3 dense-row tracks that is
  12.4 → 12.5 rows at 28 pt and 14.5 → 14.6 at 24 pt — **zero additional rows** at either track.
- **Width:** 785 → 793 pt usable, **+8 pt** — under half of one narrow fact column; the six-to-nine
  column budget in the density model is unchanged.
- **AX5 height budget:** +3 pt on a single-column reflow — about one line of nothing. AX5 remains
  the binding constraint it was, and it binds identically at both floors.
- **Render matrix:** unchanged in structure. The landscape compact/regular width-class split remains
  inside the set (852 × 393 compact, 932 × 430 and up regular), light/dark and default/AX5 remain,
  and the install-floor tier remains testable (§4). If the proof matrix moves from
  {844 × 390, 932 × 430} to {852 × 393, 956 × 440} it stays at 8 renders per screen; adding the old
  floor as a third size (the honest option while the `e` class can install) makes it 12.
- **Performance baseline:** the real content. D4's budgets are stated against the oldest supported
  device, currently the A16-class iPhone 15 (`docs/OPEN-DECISIONS.md` D4). "15 Pro and newer" moves
  the worst case to the A17-Pro class — except that if the `e` line stays in the promise, its
  A18-class chip is not the worst case either and the baseline question collapses back to which
  devices are promised, not which chip is newest. Chip assignments here are UNVERIFIED memory.
  Nothing measured today gets easier: no D4 budget has ever been measured on any device
  (`docs/STATUS.md`), so the proposal relaxes margins nobody has consumed.

**The one-sentence verdict the brief asked for:** moving the layout floor from 844 × 390 to
852 × 393 buys about one percent of linear scale and not one additional table row, so if the
proposal is worth anything it is worth it in the performance baseline and in promise clarity, not in
density — and the rest of this document is written so as not to imply otherwise.

## 4. What cannot move regardless

- **Below-floor devices still install.** There is no App Store mechanism to exclude a device by
  screen size (canon holds this in the superseded `04` §4.1 §3 and the current `docs/STATUS.md`
  baseline note). An 844 × 390 `e`-class device — currently sold, iOS 26-capable — will install the
  game whatever the promise says. The layout must therefore *run* at 844 × 390 forever; the floor
  decision only moves where it must run *well*. `SmallestDeviceLayoutTest` stays two-tier
  (promise floor asserted strictly; install floor asserted for no-clipping and reachability).
- **AX5 stays the binding constraint** at every candidate floor; the density budget's AX5 column is
  floor-independent.
- **The engine and save architecture** are untouched; no gap-register entry depends on this
  decision.

## 5. Relation to Outcome 1

The density model finds that depth lives in stated judgement, honest uncertainty, visible change and
throughput — none of which is bought with 8 × 3 pt. The floor change contributes nothing to D1–D5 of
that model and one percent to the pixel axis of D6's replacement. The ceiling correction (§2)
contributes comfort on large devices the player already owns, and legitimises proofs the tree has
already produced at 956 × 440 — worth doing for honesty, not for depth.

## 6. Proposed `docs/OPEN-DECISIONS.md` entry — D15 (not applied)

> ## D15 — Device floor, support promise and the design window *(added 2026-08-12; ESCALATED — owner decision)*
>
> **Options.**
> (a) **Status quo, corrected ceiling:** promise stays iPhone 15-generation and newer; window
> becomes 844 × 390 through 956 × 440 once sizes are verified. Floor unchanged; `e` class stays
> promised.
> (b) **Owner proposal, class reading:** promise becomes iPhone 15 Pro and newer, `e` class
> excluded; window 852 × 393 through 956 × 440; performance baseline A17-Pro class.
> (c) **Owner proposal, date reading:** promise becomes 15 Pro and newer by release date, `e` class
> included; window unchanged at the floor (844 × 390) — the proposal then moves only the
> performance narrative for the dropped base-15 devices.
>
> **The arithmetic** (2026-08-12 evaluation, `docs/briefs/2026-08-12-device-floor-evaluation.md`):
> the floor move buys +1.1 % field scale, +3 pt of management height, zero additional table rows at
> the canonical 24–28 pt tracks, and no change to the AX5 or width-class structure. Density is not
> bought here. The material contents are the performance baseline and which currently-sold devices
> the promise names — including that (b) drops the `e` line, a **currently sold** device class,
> which is a market decision, not a design one.
>
> **What holds under every option:** below-floor devices install regardless (no store mechanism
> excludes by screen size), so the install floor 844 × 390 must render un-clipped and reachable
> forever; AX5 remains binding; deployment target stays iOS 26.
>
> **Falsifier — instruments, fixed in advance.**
> - `SmallestDeviceLayoutTest`, two-tier: every registry surface renders at the install floor
>   (844 × 390) with no clipping and all controls reachable, and at the promise floor at full
>   budget. Red at either tier falsifies the chosen window.
> - `PerformanceBudgetTests` plus the D4 Instruments trace on the *oldest promised* device at
>   shipping scale. If (b) is chosen on performance grounds and the budgets then fail on A17-Pro
>   class, the choice bought nothing and is falsified.
> - The density claim: one proof screen rendered at 844 × 390 and 852 × 393 side by side. If any
>   surface fits at least one additional data row or sheds a disclosure level at the higher floor,
>   the "worthless in pixels" verdict above is falsified and this entry must be re-argued.
> - Every point size and inset used is UNVERIFIED until the approved sourcing queries (Q4–Q5) run;
>   the window is not written into `04` §7 before that verification.
>
> **Cost of reversal: low before the `04` §7 window is rewritten and the P11/M8 proof matrix is
> re-rendered; medium after** — the artefacts that would churn are the proof captures, the two-tier
> layout test, D4's baseline sentence and the `docs/STATUS.md` platform note. No save, engine or
> schema cost in any direction.

## 7. Questions this file returns rather than resolves

Consolidated with the other deliverables' questions in
`docs/briefs/2026-08-12-gap-register.md` §4: the class-vs-date reading of "iPhone 15 Pro and
newer"; whether dropping the `e` line from the promise is acceptable as a market matter; and which
proof-matrix shape (8 renders on the new window, or 12 keeping the install floor visible) the owner
wants once verified sizes exist.
