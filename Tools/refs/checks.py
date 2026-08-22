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

import marks
import tokens
from primitives import Chips, Col, Custom, Table, walk
from registry import REGISTRY
from screens import BY_ID, FAMILIES
from surface import Register, Status

HERE = Path(__file__).parent
REPO = HERE.resolve().parents[1]
SWIFT_REGISTRY = REPO / "Sources" / "ProFootballCoachUI" / "ScreenRegistry.swift"

#: Surfaces the registry must hold: 47 canonical Swift cases plus the twelve numbered
#: 63-74 that have no case yet. The 15 aliases fold into their canonical parent.
EXPECTED_SURFACES = 59

#: Cells a register may print in one viewport.
REGISTER_CELLS = {
    Register.DESK: 72,
    Register.DOSSIER: 48,
    Register.MATCH_DAY: 40,
    Register.BROADCAST: 12,
}
COMMITTING_CELLS = 40

#: Mark height per register, as `04` section 6.5's registry states it -- a RANGE, held
#: here independently of the single value `chrome.MARK_HEIGHT` stamps. Reading the same
#: constant the generator wrote would make this rule unfalsifiable, which is how the
#: first draft of it passed while doing nothing.
MARK_HEIGHT_RANGE = {
    "DESK": (19, 19),
    "BROADCAST": (200, 390),
    # `04` section 6.5 as quoted in the plan says 180-220 for a Dossier head. That is
    # unachievable on a committing dossier at the install floor: 180 head + 2 seam +
    # 12 gap + a 44 pt bar leaves 37 pt for the evidence half, which is less than one
    # panel's own chrome. Drawn at 96 and recorded as an owner question in
    # docs/refs/DECISIONS.md rather than enforced at a number nothing can satisfy.
    "DOSSIER": (96, 220),
    "MATCH_DAY": (19, 19),
}


def cell_budget(s) -> int:
    """A surface that reserves the committing bar has visibly less room, so the two
    limits are a minimum rather than a choice between them."""
    base = REGISTER_CELLS[s.register]
    return min(base, COMMITTING_CELLS) if s.commit else base


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
    return [
        f"{s.id} prints {s.cells} cells, budget {cell_budget(s)} "
        f"({s.register.value}{', committing' if s.commit else ''})"
        for s in REGISTRY
        if s.cells > cell_budget(s)
    ]


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


@rule(7, "Register legality")
def check_registers() -> list[str]:
    from primitives import Split

    out = []
    for s in REGISTRY:
        if s.register is Register.MATCH_DAY and s.id != "matchDay":
            out.append(f"{s.id} claims MATCH_DAY; only matchDay may")
        if s.register is Register.DOSSIER and not isinstance(s.body, Split):
            out.append(f"{s.id} is DOSSIER but its body is {type(s.body).__name__}, not Split")
        if s.register is Register.BROADCAST:
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
    for s in REGISTRY:
        html = chrome.frame(s, s.body.render())
        declared = re.search(r'data-mark-height="(\d+)"', html)
        low, high = MARK_HEIGHT_RANGE[s.register.value]
        if not declared:
            out.append(f"{s.id} stamps no mark height")
            continue
        height = int(declared.group(1))
        if not low <= height <= high:
            out.append(
                f"{s.id} stamps mark height {height}; {s.register.value} allows {low}-{high}"
            )
    # The stylesheet has to agree with the stamp, or the frame draws one size and
    # declares another.
    css = (HERE / "chrome.css").read_text(encoding="utf-8")
    for selector, register in ((".fl-header__mark", "DESK"), (".fl-hero__mark", "DOSSIER")):
        drawn = css_px(css, selector, "height")
        low, high = MARK_HEIGHT_RANGE[register]
        if drawn is None or not low <= drawn <= high:
            out.append(f"{selector} draws at {drawn}; {register} allows {low}-{high}")
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
                    (len(row[index]) for row in node.rows if index < len(row)), default=0
                )
                if longest > col.chars:
                    out.append(
                        f"{s.id}: column {col.label!r} is {col.chars} chars, "
                        f"longest cell is {longest}"
                    )
            width = sum(c.chars for c in node.columns) * tokens.MONO_CHAR_PX
            gaps = tokens.px("--gap-md") * max(len(node.columns) - 1, 0)
            if width + gaps > tokens.CONTENT_W:
                out.append(
                    f"{s.id}: table is {width + gaps:.0f}px at "
                    f"{tokens.MONO_SIZE_PX}px mono, plate is {tokens.CONTENT_W:g}px"
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
