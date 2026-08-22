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

---

## Canon amendments, 2026-08-22

`docs/04` gained six amendments. All are applied; three of them settle entries above.

### 11. §4.5a settles §1 and §2 — they were already right, now they are canon

The measured 291 / 241 viewport and the 9 / 6 / 5 row budgets are no longer inferred from
the design source: `04` §4.5a states them. §1 and §2 above stand as written.

What did change is that the cell budget keys off the **density tier**, not the lean. Dense
72 · Working 48 · Committing 40 · Broadcast 12, where the tier is set by row height and by
whether a commit bar is reserved. The previous build gave every Dossier 48 whatever it
drew.

### 12. §2.1 renames the axis this generator was already modelling

What this module called `Register` is the **presentation lean** — a second axis orthogonal
to canon's nine registers. Renamed. **The nine-register assignment is not modelled**: it is
not derivable from the amendment, and inventing it is what produced nine fabricated
surfaces last time.

### 13. §6.1d replaces the header and the icon rail with one identity band

34 pt, gradient from club primary to `world.page`, hairline of club secondary, mark 19 pt,
enclosing the whole navigation row. The icon rail is gone. The plate keeps its 115 pt
leading so the content box stays the canon 709 — the rail's space is simply vacated.

### 14. §6.4's five bands are computed, not asserted

`check_heat_bands` resolves each band and computes its contrast on page / raised / panel and
its hue separation from gold. Independently reproduces canon's table to two decimals:
5.67 / 4.64 / 5.26 · 5.57 / 4.56 / 5.16 · 10.00 / 8.20 / 9.28 · 10.32 / 8.46 / 9.57 ·
10.13 / 8.30 / 9.39, at 49.7 / 24.1 / 170.4 / 102.4 / 106.3 degrees.

### 15. A banded Dossier cannot also commit at the install floor

§2.1 gives the Dossier head 180–220, §6.4 requires the band table beside a banded figure,
and §4.5a leaves 241 pt once a commit bar is reserved. The three do not fit. Player Profile
and Prospect Profile are drawn **without the bar**, routing to their committing surface, and
each declares the conflict as a blocking `RULE` gap. **This is an owner question.**

### 16. Ranged ratings are declared, not faked

§6.4 requires an unearned rating drawn as a range with `Unseen` where nothing is observed.
The scouting-confidence model does not exist (`07` GAP-06), so surfaces render point values
and declare the gap — four of them do.

### 17. Canon now leads `DesignTokens.swift`

`--fl-warning` is `#C9704A` per §6.1a(ii); `DesignTokens.swift` still ships the retired hex,
and its `Heat` enum still has three bands. The vendored token sheet no longer mirrors the
Swift, and says so at the top. **The app carries both gaps.**

### 18. Two defects this pass introduced and caught

- A blanket `Register` → `Lean` rename rewrote the page **title**. Rule: the title is stable
  across redeploys because the artifact is found by it; it is now commented as such.
- `.fl-band` was claimed by both the identity band and the heat legend's swatches, so the
  swatches inherited the band's absolute positioning and smeared across every frame with a
  legend. Rule 19 makes a second owner for one class a build failure.
- The standalone file carries no charset, so a plain file server mojibaked every multi-byte
  character while the artifact host rendered it correctly. Rule 20 requires ASCII output.
