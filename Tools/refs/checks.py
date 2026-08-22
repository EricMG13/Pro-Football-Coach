"""Every rule the reference set has to satisfy. Pure Python, no browser.

Two design decisions worth stating, because both were arrived at by getting them wrong
first:

1. **Budgets are measured on the registry, not on emitted HTML.** A leaf-text count
   over-reports badly -- it cannot tell a column head from a value, or a caption from a
   fact. Measured that way the published artifact reads Roster at 78 and Signing day at
   17 while counting prose. The primitives report `cells()` from their declaration
   instead, so the number means what it says.

2. **Checks that read Swift re-parse it.** `screens.py` is a frozen transcription;
   check 2 parses `ScreenRegistry.swift` independently and compares. A check that
   consumed the same parse the registry consumed would agree with itself forever.

Nothing imports this module. It imports everything.
"""

from __future__ import annotations

import re
from html.parser import HTMLParser
from pathlib import Path

import legal
import marks
import tokens
from primitives import Chips, Col, Custom, Table, walk
from registry import REGISTRY
from screens import BY_ID, FAMILIES
from source_inventory import SOURCE_LEAN
from surface import Lean, Status

HERE = Path(__file__).parent
REPO = HERE.resolve().parents[1]
SWIFT_REGISTRY = REPO / "Sources" / "ProFootballCoachUI" / "ScreenRegistry.swift"

#: Surfaces the registry must hold: 47 canonical Swift cases plus the twelve numbered
#: 63-74 that have no case yet. The 15 aliases fold into their canonical parent.
EXPECTED_SURFACES = 59

#: Cells per DENSITY TIER, `04` section 4.5a (2026-08-22 amendment). The tier is set by
#: row height and by whether a commit bar is reserved -- it is NOT the lean. The first
#: version of this module keyed the budget off the lean and gave every Dossier 48
#: whatever it drew.
TIER_CELLS = {"dense": 72, "working": 48, "committing": 40, "broadcast": 12}

#: The Dossier lean's own split, `04` section 2.1: <=8 above the seam, <=40 below. This
#: bounds the halves; the tier above bounds the surface.
DOSSIER_ABOVE_CELLS = 8
DOSSIER_BELOW_CELLS = 40

#: Team mark and largest numeral per lean, `04` section 2.1's table. A Broadcast or
#: Dossier mark is a WATERMARK behind the head, not an inline image beside it, which is
#: what makes 390 pt fit inside a 291 pt plate at all.
MARK_HEIGHT_RANGE = {
    "DESK": (19, 19),
    "BROADCAST": (200, 390),
    "DOSSIER": (180, 220),
    "MATCH_DAY": (19, 19),
}

NUMERAL_RANGE = {
    "BROADCAST": (40, 72),
    "DESK": (11, 14),
    "DOSSIER": (40, 40),
    "MATCH_DAY": (11, 14),
}

#: The five heat bands, `04` section 6.4. Token names only -- the hexes are resolved from
#: the sheet and the contract is COMPUTED in check_heat_bands, never asserted from a
#: constant written next to them.
HEAT_BANDS = (
    ("--heat-well-below", 40, 59),
    ("--heat-below", 60, 69),
    ("--heat-average", 70, 79),
    ("--heat-above", 80, 84),
    ("--heat-well-above", 85, 99),
)

#: Grounds every heat band must be legible on.
HEAT_GROUNDS = ("--world-page", "--world-raised", "--surface-panel")

#: Gold, and the hue separation every other role must keep from it (6.1a(ii)).
GOLD = "--action-primary"
MIN_HUE_SEPARATION = 24.0


def tier(s) -> str:
    """The density tier a surface is composed against.

    Interactivity is bought with rows: a tappable row takes the 44 pt control floor, so
    nine readout rows become six, and reserving a commit bar takes six to five."""
    if s.lean is Lean.BROADCAST:
        return "broadcast"
    if s.commit:
        return "committing"
    return "working" if s.tappable_rows else "dense"


def cell_budget(s) -> int:
    return TIER_CELLS[tier(s)]


# ---------------------------------------------------------------------------
# Colour resolution, for the contrast check
# ---------------------------------------------------------------------------

_VAR = re.compile(r"var\((--[a-z0-9-]+)\)")


def resolve_color(name: str, depth: int = 0) -> tuple[float, float, float] | None:
    """A token name to sRGB, following var() chains. None when the token is a gradient
    or otherwise not a flat colour -- the contrast check skips those and says so."""
    if depth > 8:
        return None
    raw = tokens.VALUES.get(name)
    if raw is None:
        return None
    raw = raw.strip()
    chained = _VAR.fullmatch(raw)
    if chained:
        return resolve_color(chained.group(1), depth + 1)
    if raw.startswith("#"):
        h = raw[1:]
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        if len(h) < 6:
            return None
        return tuple(int(h[i : i + 2], 16) / 255 for i in (0, 2, 4))  # type: ignore[return-value]
    rgba = re.fullmatch(r"rgba?\(([^)]+)\)", raw)
    if rgba:
        parts = [p.strip() for p in rgba.group(1).split(",")]
        if len(parts) < 3:
            return None
        return tuple(float(p) / 255 for p in parts[:3])  # type: ignore[return-value]
    return None


def hue(rgb: tuple[float, float, float]) -> float:
    """HSL hue in degrees. Needed because 6.1a(ii)'s rule is about hue separation, and
    contrast was never the defect -- gold and the old warning both passed contrast."""
    r, g, b = rgb
    high, low = max(rgb), min(rgb)
    if high == low:
        return 0.0
    d = high - low
    if high == r:
        h = ((g - b) / d) % 6
    elif high == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    return h * 60.0


def hue_gap(a: str, b: str) -> float | None:
    """Smallest angle between two token hues, or None if either is not a flat colour."""
    ca, cb = resolve_color(a), resolve_color(b)
    if ca is None or cb is None:
        return None
    delta = abs(hue(ca) - hue(cb)) % 360.0
    return min(delta, 360.0 - delta)


def _linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(rgb: tuple[float, float, float]) -> float:
    r, g, b = (_linear(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: tuple[float, float, float], b: tuple[float, float, float]) -> float:
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


# ---------------------------------------------------------------------------
# Emitted-HTML readers
# ---------------------------------------------------------------------------


class _Pairs(HTMLParser):
    """Every data-ink / data-plate pair the generator stamped, with its text."""

    def __init__(self) -> None:
        super().__init__()
        self.pairs: list[tuple[str, str, str]] = []
        self._pending: tuple[str, str] | None = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "data-ink" in a and "data-plate" in a:
            self._pending = (a["data-ink"], a["data-plate"])

    def handle_data(self, data):
        if self._pending and data.strip():
            self.pairs.append((*self._pending, data.strip()))
            self._pending = None


def ink_pairs(html: str) -> list[tuple[str, str, str]]:
    parser = _Pairs()
    parser.feed(html)
    return parser.pairs


def css_px(css: str, selector: str, prop: str) -> float | None:
    """Read a length out of the emitted CSS, so a row-height rule cannot be asserted
    against a Python constant that has drifted from the stylesheet."""
    block = re.search(re.escape(selector) + r"\s*\{([^}]*)\}", css)
    if not block:
        return None
    found = re.search(re.escape(prop) + r"\s*:\s*([^;]+);", block.group(1))
    if not found:
        return None
    value = found.group(1).strip()
    chained = _VAR.fullmatch(value)
    if chained:
        return tokens.px(chained.group(1))
    literal = re.fullmatch(r"(-?[\d.]+)px", value)
    return float(literal.group(1)) if literal else None


# ---------------------------------------------------------------------------
# The rules
# ---------------------------------------------------------------------------

RULES: list = []


def rule(number: int, title: str):
    def wrap(fn):
        fn.number = number
        fn.title = title
        RULES.append(fn)
        return fn

    return wrap


def _fail(fn, message: str) -> str:
    return f"[{fn.number:>2}] {fn.title}: {message}"


@rule(1, "Inventory")
def check_inventory() -> list[str]:
    out = []
    if len(REGISTRY) != EXPECTED_SURFACES:
        out.append(f"expected {EXPECTED_SURFACES} surfaces, registry holds {len(REGISTRY)}")
    ids = [s.id for s in REGISTRY]
    numbers = [s.number for s in REGISTRY]
    for label, seq in (("id", ids), ("number", numbers)):
        dupes = {v for v in seq if seq.count(v) > 1}
        if dupes:
            out.append(f"duplicate {label}: {sorted(dupes)}")
    for s in REGISTRY:
        if s.family not in FAMILIES:
            out.append(f"{s.id} has family {s.family!r}, which is not a family")
        if s.status is not Status.BUILT and not s.evidence:
            out.append(f"{s.id} is {s.status_name} with no evidence")
        if s.status is Status.WRAPPER and not s.parent:
            out.append(f"{s.id} is WRAPPER with no parent named")
    return out


@rule(2, "Baseline parity")
def check_baseline() -> list[str]:
    """Re-parse the Swift and the catalogue; disagreement is a build failure, not a
    stale document."""
    out = []
    src = SWIFT_REGISTRY.read_text(encoding="utf-8")
    enum = re.search(r"public enum CoachWorldScreenID.*?\n\n", src, re.S)
    if not enum:
        return ["cannot find CoachWorldScreenID in ScreenRegistry.swift"]
    swift_cases = dict(
        (cid, int(num)) for cid, num in re.findall(r"^    case (\w+) = (\d+)$", enum.group(0), re.M)
    )
    # The block regex ends at the first blank line. If a blank line ever lands inside the
    # case list, the forward comparison below would silently check a subset -- so assert
    # the block holds every numbered case in the file before trusting it.
    in_file = len(re.findall(r"^    case (\w+) = (\d+)$", src, re.M))
    if len(swift_cases) != in_file:
        out.append(
            f"parsed {len(swift_cases)} enum cases but the file declares {in_file}; "
            "the CoachWorldScreenID block regex no longer spans the whole case list"
        )

    name_matches = re.findall(r'case \.(\w+): return "([^"]+)"', src)
    swift_names = dict(name_matches)
    # dict() keeps the last of any duplicate. Today exactly one switch has this shape; a
    # second one would silently overwrite names rather than disagree with them.
    if len(name_matches) != len(swift_names):
        out.append(
            "more than one switch returns a string per case; canonicalName can no "
            "longer be read unambiguously"
        )

    fam_block = re.search(
        r"public var family: CoachWorldSurfaceFamily \{(.*?)\n    \}", src, re.S
    )
    swift_family = {}
    if fam_block:
        for ids, fam in re.findall(
            r"case ((?:\s*\.\w+,?\s*)+):\s*\n\s*return \.(\w+)", fam_block.group(1)
        ):
            for i in re.findall(r"\.(\w+)", ids):
                swift_family[i] = fam

    disp = re.search(
        r"public var routeDisposition: CoachWorldRouteDisposition \{(.*?)\n    \}", src, re.S
    )
    swift_alias = set()
    if disp:
        for ids, _ in re.findall(
            r"case ((?:\s*\.\w+,?\s*)+):\s*\n\s*return \.alias\(\.(\w+)\)", disp.group(1)
        ):
            swift_alias.update(re.findall(r"\.(\w+)", ids))

    # The frozen transcription must still describe the Swift.
    for cid, num in swift_cases.items():
        frozen = BY_ID.get(cid)
        if frozen is None:
            out.append(f"screens.py is missing Swift case .{cid}")
            continue
        if frozen.number != num:
            out.append(f".{cid}: screens.py says {frozen.number}, Swift says {num}")
        if frozen.name != swift_names.get(cid):
            out.append(
                f".{cid}: screens.py says {frozen.name!r}, Swift says {swift_names.get(cid)!r}"
            )
        if frozen.family != swift_family.get(cid):
            out.append(
                f".{cid}: screens.py says family {frozen.family!r}, "
                f"Swift says {swift_family.get(cid)!r}"
            )
        if (cid in swift_alias) != (not frozen.is_canonical):
            out.append(f".{cid}: alias disposition disagrees with Swift")
    for cid in BY_ID:
        if cid not in swift_cases:
            out.append(f"screens.py has .{cid}, which Swift no longer declares")

    # Every canonical Swift case is drawn; no alias is. That is the 59: 74 registry
    # numbers (62 Swift cases plus the twelve at 63-74) less the 15 that redirect.
    drawn = {s.id for s in REGISTRY}
    for cid, screen in BY_ID.items():
        if screen.is_canonical and cid not in drawn:
            out.append(f"canonical .{cid} has no registry entry")
        if not screen.is_canonical and cid in drawn:
            out.append(
                f"alias .{cid} is drawn; it should fold into "
                f".{screen.alias_of}, which is the surface it routes to"
            )
    # The lean a surface takes is the source artifact's decision, not this
    # generator's. Checked here so a lean cannot be quietly reassigned to make a frame
    # easier to draw -- which is how three of the four ceremony surfaces were demoted to
    # Desk in the first build, emptying the lean the design set is named after.
    for s in REGISTRY:
        want = SOURCE_LEAN.get(s.number)
        if want and s.lean.value != want[0]:
            out.append(
                f"{s.id} is drawn {s.lean.value}; the source inventory says "
                f"{want[0]} (registry number {s.number})"
            )

    for s in REGISTRY:
        if s.number <= 62 and s.id not in BY_ID:
            out.append(f"{s.id} claims registry number {s.number} but Swift has no such case")
        if s.number > 62 and s.id in BY_ID:
            out.append(f"{s.id} is numbered {s.number} as new, but Swift already declares it")

    # Fixtures resolve against the pinned catalogue, by KEY and by NAME. The keys were
    # never the exposure: on the pre-merge trunk all 13 keys resolved while every name
    # attached to them differed.
    for kind in marks.FIXTURES:
        try:
            club, opponent = marks.fixture(kind)
        except KeyError as exc:
            out.append(str(exc))
            continue
        for side in (club, opponent):
            if not side.name.strip():
                out.append(f"{kind} fixture {side.stable_id} resolves to an empty name")
    for key in marks.available():
        try:
            marks.identity(key)
        except KeyError as exc:
            out.append(str(exc))
    return out


@rule(3, "Cell budget")
def check_cells() -> list[str]:
    from primitives import Split

    out = []
    for s in REGISTRY:
        if s.cells > cell_budget(s):
            out.append(
                f"{s.id} prints {s.cells} cells, budget {cell_budget(s)} "
                f"({s.lean.value}{', committing' if s.commit else ''})"
            )
        # A dossier's budget is split by the seam: the head is a broadcast moment and the
        # body is a working table, so one flat number describes neither.
        if s.lean is Lean.DOSSIER and isinstance(s.body, Split):
            above, below = s.body.top.cells(), s.body.bottom.cells()
            if above > DOSSIER_ABOVE_CELLS:
                out.append(
                    f"{s.id} prints {above} cells above the seam, budget "
                    f"{DOSSIER_ABOVE_CELLS}"
                )
            if below > DOSSIER_BELOW_CELLS:
                out.append(
                    f"{s.id} prints {below} cells below the seam, budget "
                    f"{DOSSIER_BELOW_CELLS}"
                )
    return out


@rule(4, "Gold once")
def check_gold() -> list[str]:
    return [
        f"{s.id} carries {s.golds} gold marks; the rule is at most one per surface"
        for s in REGISTRY
        if s.golds > 1
    ]


@rule(5, "Row and height budget")
def check_rows() -> list[str]:
    out = []
    for s in REGISTRY:
        readout, tappable = tokens.row_budget(s.commit is not None)
        note = " (committing)" if s.commit else ""
        if s.readout_rows > readout:
            out.append(f"{s.id} has {s.readout_rows} readout rows, budget {readout}{note}")
        if s.tappable_rows > tappable:
            out.append(f"{s.id} has {s.tappable_rows} tappable rows, budget {tappable}{note}")
        # Row counts alone let a surface pass while clipping: panel heads, padding and
        # stack gaps are real height that no row count sees. Six frames in the first
        # build counted inside their row budget and still ran off the plate.
        height = s.body.height()
        plate = tokens.viewport_height(s.commit is not None)
        if height > plate:
            out.append(
                f"{s.id} declares {height:.0f} px of body, plate is {plate:g}{note}"
            )
    return out


@rule(6, "Column budget and row tracks")
def check_columns() -> list[str]:
    out = [
        f"{s.id} draws {s.columns} columns, budget {tokens.COLUMN_BUDGET}"
        for s in REGISTRY
        if s.columns > tokens.COLUMN_BUDGET
    ]
    css = (HERE / "chrome.css").read_text(encoding="utf-8")
    dense = css_px(css, ".fl-table--dense .fl-tr", "min-height")
    tappable = css_px(css, ".fl-row--tappable", "min-height")
    readout = css_px(css, ".fl-row--readout", "min-height")
    if dense != tokens.px("--track-row-dense"):
        out.append(f"dense track is {dense} in CSS, {tokens.px('--track-row-dense')} in tokens")
    if tappable != tokens.MIN_TARGET:
        out.append(f"tappable row is {tappable} in CSS, {tokens.MIN_TARGET} in tokens")
    if readout != tokens.ROW_MIN_HEIGHT:
        out.append(f"readout row is {readout} in CSS, {tokens.ROW_MIN_HEIGHT} in tokens")
    return out


@rule(7, "Lean legality")
def check_registers() -> list[str]:
    from primitives import Split

    out = []
    for s in REGISTRY:
        if s.lean is Lean.MATCH_DAY and s.id != "matchDay":
            out.append(f"{s.id} claims MATCH_DAY; only matchDay may")
        if s.lean is Lean.DOSSIER and not isinstance(s.body, Split):
            out.append(f"{s.id} is DOSSIER but its body is {type(s.body).__name__}, not Split")
        if s.lean is Lean.BROADCAST:
            tables = [n for n in walk(s.body) if isinstance(n, Table)]
            if tables:
                out.append(f"{s.id} is BROADCAST and carries {len(tables)} table(s)")
    return out


@rule(8, "Contrast")
def check_contrast() -> list[str]:
    import chrome

    out = []
    unresolved: set[str] = set()
    for s in REGISTRY:
        html = chrome.frame(s, s.body.render())
        for ink_name, plate_name, text in ink_pairs(html):
            ink = resolve_color(ink_name)
            plate = resolve_color(plate_name)
            if ink is None or plate is None:
                unresolved.add(f"{ink_name} on {plate_name}")
                continue
            ratio = contrast(ink, plate)
            if ratio < 4.5:
                out.append(
                    f"{s.id}: {ink_name} on {plate_name} measures {ratio:.2f}, needs 4.5 "
                    f"({text[:24]!r})"
                )
    for pair in sorted(unresolved):
        out.append(f"cannot resolve the pair {pair} to flat colours; contrast unverified")
    return out


@rule(9, "Type and mark scales")
def check_type() -> list[str]:
    import chrome

    out = []
    if tokens.TYPE_AUTHORED_FLOOR < 12:
        out.append(f"authored floor is {tokens.TYPE_AUTHORED_FLOOR}, contract says 12")
    if tokens.TYPE_MICRO_FLOOR < 9:
        out.append(f"micro-label floor is {tokens.TYPE_MICRO_FLOOR}, contract says 9")
    from primitives import Hero, Split, walk

    for s in REGISTRY:
        # The head's watermark and numeral, measured where they are actually drawn.
        for node in walk(s.body):
            if not isinstance(node, Hero):
                continue
            if node.mark:
                drawn = node.WATERMARK[node.scale]
                low, high = MARK_HEIGHT_RANGE[s.lean.value]
                if not low <= drawn <= high:
                    out.append(
                        f"{s.id}: head watermark is {drawn:g} px; "
                        f"{s.lean.value} allows {low}-{high}"
                    )
            if node.numeral:
                size = node.NUMERAL[node.scale]
                low, high = NUMERAL_RANGE[s.lean.value]
                if not low <= size <= high:
                    out.append(
                        f"{s.id}: head numeral is {size:g} px; "
                        f"{s.lean.value} allows {low}-{high}"
                    )

    for s in REGISTRY:
        html = chrome.frame(s, s.body.render())
        declared = re.search(r'data-mark-height="([\d.]+)"', html)
        low, high = MARK_HEIGHT_RANGE[s.lean.value]
        if not declared:
            out.append(f"{s.id} stamps no mark height")
            continue
        height = float(declared.group(1))
        if not low <= height <= high:
            out.append(
                f"{s.id} stamps mark height {height}; {s.lean.value} allows {low}-{high}"
            )
    # The stylesheet has to agree with the stamp, or the frame draws one size and
    # declares another.
    css = (HERE / "chrome.css").read_text(encoding="utf-8")
    drawn = css_px(css, ".fl-band__mark", "height")
    low, high = MARK_HEIGHT_RANGE["DESK"]
    if drawn is None or not low <= drawn <= high:
        out.append(f".fl-band__mark draws at {drawn}; DESK allows {low}-{high}")
    # `04` 6.1d fixes the band's own height, and the band is the sanctioned seventh mark
    # placement -- if it moves, the mark inside it is no longer the size canon states.
    band = css_px(css, ".fl-band", "height")
    if band != 34:
        out.append(f".fl-band is {band} pt tall; 6.1d says 34")
    return out


@rule(10, "Palette closure")
def check_palette() -> list[str]:
    """No literal colour outside the vendored token sheets. `marks.py` is exempt only
    because its colours are read out of the catalogue, never authored."""
    out = []
    literal = re.compile(r"#[0-9A-Fa-f]{3,8}\b|rgba?\(\s*\d")
    for path in sorted(HERE.rglob("*.py")) + sorted(HERE.rglob("*.css")):
        if path.name == "marks.py" or path.parent.name == "tokens":
            continue
        if path.name in ("checks.py", "test_checks.py"):
            continue  # both hold colour-shaped strings that are patterns, not paint
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if literal.search(line):
                rel = path.relative_to(HERE)
                out.append(f"{rel}:{lineno} authors a literal colour: {line.strip()[:60]}")
    return out


@rule(11, "Column overflow")
def check_overflow() -> list[str]:
    out = []
    for s in REGISTRY:
        for node in walk(s.body):
            if not isinstance(node, Table):
                continue
            for index, col in enumerate(node.columns):
                longest = max(
                    (
                        len(str(getattr(row[index], "rating", row[index])))
                        for row in node.rows
                        if index < len(row)
                    ),
                    default=0,
                )
                if longest > col.chars:
                    out.append(
                        f"{s.id}: column {col.label!r} is {col.chars} chars, "
                        f"longest cell is {longest}"
                    )
            # Same expression the track is emitted from, so the check and the render can
            # never disagree about how wide a column is.
            width = sum(c.width_px for c in node.columns)
            gaps = tokens.px("--gap-md") * max(len(node.columns) - 1, 0)
            if width + gaps > tokens.CONTENT_W:
                out.append(
                    f"{s.id}: table needs {width + gaps:.0f}px, plate is "
                    f"{tokens.CONTENT_W:g}px"
                )
    return out


@rule(12, "Gaps declared")
def check_gaps() -> list[str]:
    return [f"{s.id} declares no gap and no NOTHING_MISSING sentinel" for s in REGISTRY if not s.gaps]


@rule(13, "Vocabulary, self-containment and the escape hatch")
def check_vocabulary() -> list[str]:
    import page

    out = []
    banned = ("TODO", "FIXME", "lorem", "Lorem", "placeholder", "Placeholder", "XXX")
    html = page.build()
    for word in banned:
        if word in html:
            out.append(f"the page contains banned vocabulary {word!r}")
    for match in re.findall(r'(?:src|href)="([^"]+)"', html):
        if match.startswith(("#", "data:")):
            continue
        if match.startswith("https://fonts.googleapis.com") or match.startswith(
            "https://fonts.gstatic.com"
        ):
            continue
        out.append(f"the page reaches an external URL: {match}")
    if re.search(r'<img[^>]+src="(?!data:)', html):
        out.append("an <img> is not a data: URI")
    used = sum(s.customs for s in REGISTRY)
    if used > tokens.CUSTOM_BUDGET:
        out.append(f"{used} Custom nodes, budget {tokens.CUSTOM_BUDGET}")
    return out


@rule(16, "Heat bands")
def check_heat_bands() -> list[str]:
    """Five bands, each legible on every ground and each clear of gold.

    Computed from the resolved token values, not asserted from a table written beside
    them -- a rule that reads the number it is checking cannot fail."""
    out = []
    if len(HEAT_BANDS) != 5:
        out.append(f"{len(HEAT_BANDS)} heat bands declared; `04` 6.4 says five")

    covered: list[tuple[int, int]] = []
    for token, low, high in HEAT_BANDS:
        covered.append((low, high))
        colour = resolve_color(token)
        if colour is None:
            out.append(f"{token} does not resolve to a flat colour")
            continue
        for ground in HEAT_GROUNDS:
            plate = resolve_color(ground)
            if plate is None:
                out.append(f"{ground} does not resolve to a flat colour")
                continue
            ratio = contrast(colour, plate)
            if ratio < 4.5:
                out.append(f"{token} measures {ratio:.2f} on {ground}, needs 4.5")
        gap = hue_gap(token, GOLD)
        if gap is None:
            out.append(f"cannot measure {token} against gold")
        elif gap < MIN_HUE_SEPARATION:
            out.append(
                f"{token} sits {gap:.1f} degrees from gold, needs {MIN_HUE_SEPARATION:g}"
            )

    # The bands must tile 40-99 with no hole and no overlap.
    covered.sort()
    if covered[0][0] != 40 or covered[-1][1] != 99:
        out.append(f"the bands span {covered[0][0]}-{covered[-1][1]}, not 40-99")
    for (_, end), (start, _) in zip(covered, covered[1:]):
        if start != end + 1:
            out.append(f"the bands leave a gap or overlap between {end} and {start}")

    # 70-79 is neutral ink, never amber. That is the whole point of the amendment.
    average = resolve_color("--heat-average")
    neutral = resolve_color("--content-secondary")
    if average != neutral:
        out.append("--heat-average is not --content-secondary; average must read neutral")
    return out


@rule(17, "Alias closure")
def check_aliases() -> list[str]:
    """No two role tokens may carry the same literal hex.

    6.1a(ii) lets identical roles stay identical, but as declared aliases, so a future
    divergence is a deliberate edit and not an accident."""
    literals: dict[str, list[str]] = {}
    sheet = tokens._sheet("colors")
    for prop, value in re.findall(r"(--[a-z0-9-]+)\s*:\s*(#[0-9A-Fa-f]{3,8})\s*;", sheet):
        literals.setdefault(value.lower(), []).append(prop)
    return [
        f"{sorted(names)} all declare the literal {value}; alias one to the other"
        for value, names in literals.items()
        if len(names) > 1
    ]


@rule(18, "Band table present")
def check_band_table() -> list[str]:
    """A surface that bands a rating prints the band table on that surface.

    Without it the player cannot answer "is 74 good?" without a live percentile, which a
    save with no league history cannot supply."""
    from primitives import AttributeDial, BandLegend, Heat, ShareBar, walk

    def is_banded(n) -> bool:
        if isinstance(n, (Heat, AttributeDial)):
            return True
        # a share bar tinted with a heat token is reading the same scale
        return isinstance(n, ShareBar) and n.tint.startswith("--heat-")

    out = []
    for s in REGISTRY:
        nodes = list(walk(s.body))
        bands = any(is_banded(n) for n in nodes)
        legend = any(isinstance(n, BandLegend) for n in nodes)
        if bands and not legend:
            out.append(f"{s.id} bands a rating and prints no band table")
        if legend and not bands:
            out.append(f"{s.id} prints a band table and bands nothing")
    return out


@rule(21, "Arcs are proportions")
def check_arcs() -> list[str]:
    """geometry.css: "An arc is permitted ONLY where the datum is a proportion. An arc
    that encodes a rank or a count is a lie about the shape of the number."

    The primitives raise on a value outside 0-1, so this cannot fail through the front
    door. What it catches is the back door: an arc drawn with no printed figure beside it,
    which makes the shape the only reading of the number."""
    from primitives import AttributeDial, FormLine, Meter, OpposedBar, ShareBar, ValueRing, walk

    out = []
    for s in REGISTRY:
        for node in walk(s.body):
            if isinstance(node, (ValueRing, ShareBar)):
                if not str(node.figure).strip():
                    out.append(f"{s.id}: {type(node).__name__} {node.label!r} prints no figure")
                if not 0.0 <= node.proportion <= 1.0:
                    out.append(f"{s.id}: {type(node).__name__} {node.label!r} is not a proportion")
            if isinstance(node, AttributeDial) and not 40 <= node.rating <= 99:
                out.append(f"{s.id}: dial {node.title!r} is off the 40-99 scale")
            if isinstance(node, Meter) and node.capacity <= 0:
                out.append(f"{s.id}: meter {node.label!r} has no capacity to be a proportion of")
            if isinstance(node, OpposedBar) and node.home + node.away <= 0:
                out.append(f"{s.id}: opposed bar {node.label!r} has no total")
            if isinstance(node, FormLine) and not node.results:
                out.append(f"{s.id}: form line is empty")
    return out


@rule(20, "Pure ASCII output")
def check_ascii() -> list[str]:
    """The document must be ASCII.

    It is served two ways -- wrapped by the artifact host, which declares a charset, and
    from a plain file server, which does not. Without a declaration the browser guesses
    Latin-1 and every multi-byte character mojibakes; `7-0 . #9` rendered as `7-0 A. #9`
    on the served copy while looking correct in the artifact."""
    import page

    html = page.build()
    stray = sorted({ch for ch in html if ord(ch) > 127})
    return (
        [f"the page emits non-ASCII: {stray!r}; add them to page._ENTITIES"]
        if stray
        else []
    )


@rule(19, "Class ownership")
def check_class_ownership() -> list[str]:
    """No CSS class may be emitted by both chrome.py and primitives.py.

    `.fl-band` was briefly claimed by the identity band and by the heat legend's
    swatches; the swatches inherited the band's absolute positioning and gradient and
    smeared across every frame that printed a legend. Two owners for one class is the
    cascade collision the design rules warn about, and nothing caught it but the eye."""
    #: Typographic utilities that carry no layout and are meant to be shared.
    shared = {"fl-figure", "fl-label3"}
    emitted = {}
    for name in ("chrome", "primitives"):
        source = (HERE / f"{name}.py").read_text(encoding="utf-8")
        for cls in re.findall(r'class="(fl-[a-z0-9_ -]+)"', source):
            for token in cls.split():
                emitted.setdefault(token, set()).add(name)
    return [
        f"class {cls} is emitted by both {' and '.join(sorted(owners))}"
        for cls, owners in sorted(emitted.items())
        if len(owners) > 1 and cls not in shared
    ]


@rule(15, "Legal guardrail")
def check_legal() -> list[str]:
    """No published identity may contain a blocklisted institution name.

    `CLAUDE.md` makes this a test, not a review item, and this generator publishes
    identities to a hosted page the Swift suite never sees. Only the institution limb is
    checked here; the trade-dress delta-E test stays Swift-side and is named in
    docs/refs/DECISIONS.md as a limit rather than covered by silence."""
    out = list(legal.check_lists_match_swift())
    seen: set[str] = set()
    for key in marks.available():
        identity = marks.identity(key)
        for field in (identity.name, identity.abbreviation):
            if field in seen:
                continue
            seen.add(field)
            hit = legal.blocks(field)
            if hit:
                out.append(
                    f"{key} publishes {field!r}, which contains the blocked entry "
                    f"{hit!r}"
                )
    # Copy this generator authors is held to the same rule as generated names.
    for s in REGISTRY:
        hit = legal.blocks(s.name)
        if hit:
            out.append(f"surface name {s.name!r} contains the blocked entry {hit!r}")
    return out


@rule(14, "Determinism")
def check_determinism() -> list[str]:
    import page

    first, second = page.build(), page.build()
    return [] if first == second else ["two builds differ"]


def run_all() -> list[str]:
    failures: list[str] = []
    for fn in RULES:
        for message in fn():
            failures.append(_fail(fn, message))
    return failures
