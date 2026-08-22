# Reference-frame decisions

Where this generator departs from a number written down elsewhere, and why. Each is a
question for the owner, not a resolved point.

## 1. The usable viewport is 319 pt, not 291

`~/.claude/plans/1-refine-polish-and-curious-trinket.md` records a correction that the
usable content height is **291 pt, not 319**. The generator derives **319** and does not
apply that correction, because both other sources agree on 319 and neither is reconcilable
with 291:

- `docs/ux/00-GATE-ZERO.md:164` — `390 − 46 − 25 = 319`
- `tokens/frame.css` — `--floor-height: 390`, `--content-top: 46`, `--bottom-inset: 25`

`tokens.viewport_height()` computes it from those three token values rather than writing
any of the three down, so if an inset moves the arithmetic follows. **If 291 is right,
one of the three insets is wrong and the token sheet needs the change, not this module.**

## 2. Row budgets are derived, not the plan's 9 / 6 / 5

The plan states at most 9 readout rows, 6 tappable, and 5 tappable when a surface commits.
`tokens.row_budget()` derives `(9, 7)` and `(8, 6)` instead — what 319 and 275 pt divide
into at the 32 and 44 pt tracks. The readout figure agrees; the tappable figures differ by
one in each case. Deriving them means an inset change cannot leave a stale budget behind.

## 3. Cell budgets: COMFORTABLE 56 split into 48 and 40

`docs/ux/06-TOKENS-AND-DENSITY.md:128` gives two tiers, DENSE 72 and COMFORTABLE 56, the
latter justified at :131 as "7 interactive rows x 8 columns". The plan gives four:
Dense 72, Working 48, Committing 40, Broadcast 12.

The generator takes the plan's four, mapped to registers, and treats the committing limit
as a **minimum with the register's own** rather than a fifth tier — a surface that reserves
the 44 pt bar has visibly less room than one that does not, and one number cannot describe
both. **The dossier is the committed artefact and this disagrees with it; the owner should
settle which taxonomy is canon.**

## 4. A Dossier head band is 96, not `04` 6.5's 180-220

180 is unachievable on a committing dossier at the install floor: 180 head + 2 seam + 12
gap + a 44 pt bar leaves 37 pt for the evidence half, which is less than one panel's own
chrome (25 head + 22 padding). Drawn at 96. `checks.MARK_HEIGHT_RANGE` accepts 96-220 so
the rule still bites on a genuinely wrong size.

Either the band figure is not a head-band height, or a dossier cannot carry a committing
action. Both readings are defensible and this is the owner's call.

## 5. Row heights are measured, not derived

`primitives._ROW` holds four measured numbers rather than padding-plus-line-height
arithmetic. Deriving them under-read by about a fifth — an inline run inside a flex row
occupies its line box, not its line-height — and six frames passed their row-count budget
while visibly clipping. Captured 2026-08-22 in the Browser pane at 1280x720. Re-measure
with `build.py --only <id>` if `chrome.css` changes a padding or a face.

## 6. Aliases are not drawn

59 = 74 registry numbers less the 15 that redirect. Check 2 requires every canonical Swift
case to have exactly one entry and no alias to have any: an alias renders its canonical
sibling's screen, so drawing it twice would misreport coverage. `Status.WRAPPER` is a
different axis — a canonical surface whose *view* routes through a parent's `switch focus`.

## 7. Status is Swift build state; Gap is design state

`Coach World.dc.html` routes all 62 registry surfaces, so almost everything is *drawn*
while far less is *built*. Collapsing the two axes is what made the published inventory
wrong in both directions. `Status` answers "does this exist in `Sources/`"; `Gap` answers
"what is missing from it".
