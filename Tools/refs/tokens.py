"""Design tokens, read from the authored CSS rather than transcribed.

`tokens/*.css` is the design system's own export (Coach World Floodlit, 2026-08-22),
vendored verbatim. Re-authoring those values in Python would create a second source
that silently drifts from the first, so this module parses them instead: `VALUES` is
the parse, `emit_css()` is the concatenation, and both come from the same bytes.

The only numbers authored *here* are the ones the CSS does not state -- the cell and
row budgets, which are a rule about composition rather than a drawn value.
"""

from __future__ import annotations

import re
from pathlib import Path

TOKENS_DIR = Path(__file__).parent / "tokens"

# styles.css names the load order; _index.css is that file, vendored under a name
# that keeps it from being mistaken for a token sheet.
_ORDER = (
    "fonts",
    "colors",
    "typography",
    "spacing",
    "geometry",
    "material",
    "motion",
    "frame",
)

_DECL = re.compile(r"(--[a-z0-9-]+)\s*:\s*([^;]+);")


def _sheet(name: str) -> str:
    return (TOKENS_DIR / f"{name}.css").read_text(encoding="utf-8")


def _parse() -> dict[str, str]:
    out: dict[str, str] = {}
    for name in _ORDER:
        for prop, value in _DECL.findall(_sheet(name)):
            out[prop] = value.strip()
    return out


VALUES: dict[str, str] = _parse()


def emit_css() -> str:
    """The stylesheet the page links. Same bytes the parse read."""
    return "\n".join(_sheet(name) for name in _ORDER)


def px(name: str) -> float:
    """A token whose value is a single px length."""
    raw = VALUES[name]
    match = re.fullmatch(r"(-?[\d.]+)px", raw.strip())
    if match is None:
        raise KeyError(f"{name} is not a single px length: {raw!r}")
    return float(match.group(1))


def hex_colors() -> set[str]:
    """Every literal hex in the token sheets, lowercased, for the closure check."""
    found: set[str] = set()
    for name in _ORDER:
        found.update(m.lower() for m in re.findall(r"#[0-9A-Fa-f]{3,8}\b", _sheet(name)))
    return found


# ---------------------------------------------------------------------------
# Frame arithmetic. Derived from frame.css so it cannot drift from the drawing.
# ---------------------------------------------------------------------------

FLOOR_W = px("--floor-width")            # 844
FLOOR_H = px("--floor-height")           # 390
CONTENT_LEADING = px("--content-leading")  # 115
CONTENT_TOP = px("--content-top")        # 46
CONTENT_W = px("--content-width")        # 709
BOTTOM_INSET = px("--bottom-inset")      # 25
MIN_TARGET = px("--min-target")          # 44
ROW_MIN_HEIGHT = px("--row-min-height")  # 32

# frame.css derives --content-width as floor - leading - gutter; assert it, because
# a hand-edit to any of the three should fail here rather than silently reflow.
assert CONTENT_W == FLOOR_W - CONTENT_LEADING - px("--gutter"), "content width drifted"

#: The GEOMETRIC content box: 390 - 46 - 25. Not the usable height -- see below.
CONTENT_BOX_H = FLOOR_H - CONTENT_TOP - BOTTOM_INSET

#: Usable scroll viewport, MEASURED in the running app.
#:
#: The source states both numbers and they are not in conflict: "Geometry gives a
#: 709 x 319 pt content box, but the running app measures the usable scroll viewport at
#: 291 pt, and 241 once a commit bar is reserved outside the scroll." The first build of
#: this module read that as a contradiction, kept the geometric 319, and wrote the
#: disagreement up as settled -- at which point 24 of 59 frames overflowed the plate they
#: are actually drawn into. 319 is the box; 291 is what scrolls inside it.
VIEWPORT_H = 291.0

#: Usable height once the committing bar is reserved OUTSIDE the scroll. The 50 pt gap
#: from 291 is the bar plus its clearance, which is why this is not 291 - 44.
VIEWPORT_H_COMMITTING = 241.0

#: How much of the geometric box the scroll container does not get. Asserted rather than
#: assumed, so a token change that moves the box without a fresh measurement is visible.
SCROLL_CHROME = CONTENT_BOX_H - VIEWPORT_H  # 28


def viewport_height(committing: bool) -> float:
    """The one expression the budget and the bar both read."""
    return VIEWPORT_H_COMMITTING if committing else VIEWPORT_H


# ---------------------------------------------------------------------------
# Composition budgets. Authored here: they are rules, not drawn values.
# ---------------------------------------------------------------------------

#: Cells a register may print in one viewport.
#:
#: DENSE 72 and the 44 pt interactive track are the dossier's
#: (`docs/ux/06-TOKENS-AND-DENSITY.md` section 3.1); the split of its single
#: COMFORTABLE 56 into WORKING 48 and COMMITTING 40 is this generator's, because a
#: surface that reserves the committing bar has visibly less room than one that does
#: not and a single number cannot describe both. See `docs/refs/DECISIONS.md`.
CELL_BUDGET = {
    "DESK": 72,
    "DOSSIER": 48,
    "MATCH_DAY": 40,
    "BROADCAST": 12,
}

#: Cells a surface may print once it reserves the committing bar.
CELL_BUDGET_COMMITTING = 40

#: (readout, tappable) rows per the source: "Nine readout rows at 32 pt, six tappable at
#: 44, five once the bar is reserved. Eight columns. That is where 72 comes from, and why
#: a committing surface gets 40."
#:
#: Stated, not derived. The first build derived them -- from the geometric box -- and got
#: (9, 7) and (8, 6): drift-proof against the wrong number.
ROW_BUDGET = {False: (9, 6), True: (8, 5)}


def row_budget(committing: bool) -> tuple[int, int]:
    return ROW_BUDGET[committing]

#: Columns in a dense table, and the character grid the overflow check uses.
COLUMN_BUDGET = 8
MONO_CHAR_PX = 6.6          # IBM Plex Mono at 11.5 px
MONO_SIZE_PX = 11.5

#: Type floors, read back out of the CSS so the contract has one home.
TYPE_AUTHORED_FLOOR = px("--type-authored-floor")   # 12
TYPE_MICRO_FLOOR = px("--size-flag")                # 9

#: How many surfaces may reach for the escape hatch before the primitives have rotted.
CUSTOM_BUDGET = 6
