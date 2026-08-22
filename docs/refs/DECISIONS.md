# Reference-frame decisions

Where this generator departs from a number written down elsewhere, and why.

**Rewritten 2026-08-22 after an adversarial review against the source.** The first version
of this file recorded seven "open questions". Five of them were not open — they were
answered in the source artifact's specification table, which the first build had not read.
They are kept below, marked as errors, because a decision register that quietly deletes its
wrong entries teaches nothing.

The source is `claude.ai/code/artifact/34b9992d-8d69-40f0-a2f3-b8e1c15b3311` ("Two
Registers"). Where it states a value, it wins.

## Resolved — and previously recorded wrong

### 1. The viewport is 291 pt, not 319. ~~Open.~~ **The first version had this backwards.**

The source: *"Geometry gives a 709 × 319 pt content box, but the running app measures the
usable scroll viewport at 291 pt, and 241 once a commit bar is reserved outside the
scroll."*

Those are two quantities, not two claims about one. `frame.css` and
`docs/ux/00-GATE-ZERO.md:164` both say 319 because 319 *is* the geometric box; 291 is what
scrolls inside it. The first build read the pair as a contradiction, kept the geometric
number, and wrote the disagreement up as settled. Measured against 291/241, **24 of 59
frames overflowed the plate they are actually drawn into** — including the height check
added specifically to catch clipping, which was calibrated to the wrong plate and passed
them all.

`tokens.CONTENT_BOX_H` is the geometry; `tokens.VIEWPORT_H` / `VIEWPORT_H_COMMITTING` are
the measurement; `SCROLL_CHROME` is the 28 pt difference, asserted so a token change that
moves the box without a fresh measurement is visible.

### 2. Row budgets are 9 / 6 / 5. ~~Derived.~~ **Derivation from the wrong box.**

The source: *"Nine readout rows at 32 pt, six tappable at 44, five once the bar is
reserved. Eight columns. That is where 72 comes from, and why a committing surface gets
40."* The first build derived (9, 7) and (8, 6) from the 319 pt box and defended the
derivation as drift-proof. It was drift-proof against the wrong number.

### 3. Cell budgets. Broadcast ≤ 12 · Desk ≤ 72 · Dossier ≤ 8 above the seam, ≤ 40 below.

The dossier figure is a **split**, not one number. The first build used a flat 48, which
let a dossier print 48 cells above the seam — in the register whose whole point is that the
head is a broadcast moment and the body is a working table.

The `docs/ux/06-TOKENS-AND-DENSITY.md` DENSE-72 / COMFORTABLE-56 pair remains a genuine
disagreement with the source's four-register table. The source is the later document and is
followed; the dossier is flagged for the owner.

### 4. A Dossier head is 180–220 px. ~~"Unachievable."~~ **The mark is a watermark.**

The first build argued 180 could not fit and drew 96 — reasoning from the 275 pt plate that
§1 shows was wrong, and then widening `MARK_HEIGHT_RANGE` to (96, 220) so its own output
would pass. Loosening a bound to fit the artefact is the coverage-boundary failure
`CLAUDE.md` names.

The mark is a **watermark behind the head**, not an inline image beside it, which is what
makes 390 px fit inside a 291 pt plate at all. The source's own drawn dossier: *"opponent
colour flooding a 132 pt head, a 212 px watermark, the name at 38 and the ceiling at 40
points."*

### 5. The twelve missing surfaces are named by the source.

M1 Responsibilities · M2 Championship Result · M3 Season Expectations · M4 Season Review ·
M5 While You Were Away · M6 Compare · M7 Save & Continuity · M8 Appearance, plus four
overlay layers that carry no screen ID at all: O1 First run · O2 Teaching · O3 Failure ·
O4 System state.

The first build invented nine of the twelve and gave each one fabricated `file:line`
evidence in the same format as the real entries. `source_inventory.SOURCE_MISSING` now
holds the list and check 1 counts against it.

## Standing

### 6. Row heights are measured, not derived

`primitives._ROW` holds four measured numbers rather than padding-plus-line-height
arithmetic. Deriving them under-read by about a fifth — an inline run inside a flex row
occupies its line box, not its line-height. Captured 2026-08-22 in the Browser pane at
1280 × 720. Re-measure with `build.py --only <id>` if `chrome.css` changes a padding or a
face. **Nothing enforces the re-measurement**; that is a known weakness.

### 7. Aliases are not drawn

59 = 74 registry numbers less the 15 that redirect. Check 2 requires every canonical Swift
case to have exactly one entry and no alias to have any.

### 8. Status is Swift build state; Gap is design state

`Coach World.dc.html` routes all 62 registry surfaces, so almost everything is *drawn*
while far less is *built*. `Status` answers "does this exist in `Sources/`"; `Gap` answers
"what is missing from it". The source classifies by line count (Built ≥180, Thin 100–179,
Stub under 100); that reading is recorded in `source_inventory` for comparison and is not
used, because line count is not build state.

### 9. Only one of the two legal tests is ported

`legal.py` ports the institution-kind blocklist (`Blocklist.blocks`) to Python, because
this generator publishes generated identities to a hosted page the Swift suite never sees.
**The ΔE trade-dress check is not ported** — it needs the real programme colour table and a
colour space, and the Swift suite owns it. That is a stated limit, not coverage.

### 10. Density is thinner than the source's, and the row primitive is why

Every frame now fits its plate, but several sit well under budget: Coaching HQ prints 4
cells where the source's This Week carries roughly eight items in the same 241 pt.

The cause is `Rows`, which measures **64 pt tappable / 52 pt readout** — a lead line, a
meta line and a values column, plus `--pad-row`. The source's list items are compact lines
closer to the 32/44 pt tracks the specification names. So the budget is now right and the
primitive is fat, which spends the budget on chrome instead of data.

Fixing it means retuning `.fl-row` and re-measuring `primitives._ROW`, and is the next
thing worth doing to this generator. Recorded rather than hidden: a frame that fits by
being empty is not the same as a frame that fits.
