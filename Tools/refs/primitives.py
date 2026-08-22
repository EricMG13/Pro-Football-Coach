"""Body primitives: the counting vocabulary.

The design system ships 39 components. These eight are not a replacement for them --
they are the *countable* subset. A frame is declared as a tree of these, so the cell
budget can be measured on the declaration rather than on emitted HTML, where chrome,
labels and captions are indistinguishable from data.

Every node answers three questions the checks ask: how many data cells does it print,
how many rows can be tapped, and which ink sits on which plate. Rendering is a
consequence of the declaration, never a place to add content.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from html import escape
from typing import Protocol, runtime_checkable

import tokens

# Heights, read out of the token sheets so a primitive cannot claim a size the CSS
# does not draw. These are the reason a frame either fits its plate or is caught.
_GAP_HAIR = tokens.px("--gap-hair")
_GAP_MD = tokens.px("--gap-md")
_GAP_SM = tokens.px("--gap-sm")
_GAP_LG = tokens.px("--gap-lg")
_GAP_XS = tokens.px("--gap-xs")
_PANEL_HEAD = 25.0                       # .fl-panel__head, measured
_PANEL_PAD = 11.0 * 2                    # --pad-panel, vertical
_LABEL3 = 9.0 * 1.1 + tokens.px("--gap-xxs")   # a column-head row
_CHIP = 10.5 * 1.2 + tokens.px("--gap-tight") * 2
_FIELD = 200.0                           # .fl-field height
_SEAM = 2.0
# Row heights are MEASURED, not derived. Deriving them from padding plus line-height
# under-reads by about a fifth: an inline run inside a flex row does not occupy its
# line-height, it occupies its line box, and modelling that in Python is a worse use of
# effort than reading it off the page once. Captured 2026-08-22 in the Browser pane at
# 1280x720 against docs/refs/subset.html; re-measure with
# `build.py --only <id>` if chrome.css changes a padding or a face.
# Two constants, not four: a row measures the same with or without its meta line, because
# the line box of the values column sets the height either way. The first version branched
# on meta and was wrong about why rows are tall.
_ROW = {"tappable": 64.0, "readout": 52.0}

# --------------------------------------------------------------------------
# What a node has to answer
# --------------------------------------------------------------------------


@runtime_checkable
class Node(Protocol):
    def cells(self) -> int: ...
    def readout_rows(self) -> int: ...
    def tappable_rows(self) -> int: ...
    def columns_count(self) -> int: ...
    def golds(self) -> int: ...
    def height(self) -> float: ...
    def render(self) -> str: ...


def _walk(children: tuple[Node, ...], attr: str) -> int:
    return sum(getattr(c, attr)() for c in children)


def _ink(text: str, ink: str, plate: str, cls: str = "") -> str:
    """A text run that declares the pair the contrast check will score."""
    klass = f' class="{cls}"' if cls else ""
    return (
        f'<span{klass} data-ink="{ink}" data-plate="{plate}"'
        f" style=\"color: var({ink})\">{escape(text)}</span>"
    )


# --------------------------------------------------------------------------
# Leaf content
# --------------------------------------------------------------------------


#: Character advance at 12 px (`--type-callout`), MEASURED in the two faces the table
#: actually renders in. The distinction is not pedantry: a `ch` track resolves against the
#: CONTAINER's font, and a figure cell renders in a different one, so `12ch` bought 66 px
#: of Archivo Narrow for a value that needed 79 px of IBM Plex Mono and the money columns
#: in Contract Negotiation collided. Tracks are now computed in px from the face the cell
#: is drawn in.
MONO_ADVANCE = 7.2 / 12.0        # IBM Plex Mono, per px of font size
DISPLAY_ADVANCE = 5.472 / 12.0   # Archivo Narrow digits -- wider than its letters, so
                                 # using it for a text column is the conservative bound
CELL_FONT_PX = 12.0


@dataclass(frozen=True)
class Col:
    """A table column, declared in CHARACTERS.

    Characters are what makes the overflow check possible without a browser -- a declared
    px width tells you nothing about the content. The px track is derived from the advance
    of the face this column renders in, which `figure` selects."""

    label: str
    chars: int
    align: str = "left"
    figure: bool = True

    @property
    def advance(self) -> float:
        return (MONO_ADVANCE if self.figure else DISPLAY_ADVANCE) * CELL_FONT_PX

    @property
    def width_px(self) -> float:
        """Wide enough for `chars` of the face the cell is drawn in, and for its own
        column head, which is Label3 at 9 px."""
        return max(self.chars * self.advance, len(self.label) * 9.0 * DISPLAY_ADVANCE)


@dataclass(frozen=True)
class Row:
    """One line of a `Rows`. `lead` identifies, `values` are the facts on it."""

    lead: str
    values: tuple[str, ...] = ()
    meta: str | None = None


#: The five bands of `04` section 6.4, as (ceiling, token). Average is neutral ink.
_HEAT = (
    (59, "--heat-well-below"),
    (69, "--heat-below"),
    (79, "--heat-average"),
    (84, "--heat-above"),
    (99, "--heat-well-above"),
)


def heat_token(rating: int) -> str:
    for ceiling, token in _HEAT:
        if rating <= ceiling:
            return token
    return _HEAT[-1][1]


@dataclass(frozen=True)
class Heat:
    """A rating drawn with its band colour as a SECOND reading of the printed figure.

    Never colour alone: the number is always printed, and `04` 6.4 requires a spoken band
    too. A surface carrying one of these must also carry a `BandLegend` -- checked."""

    rating: int
    #: What the simulation has actually observed. `04` 6.4 forbids a band without a
    #: recorded observation, so this is not optional.
    observed: str

    @property
    def band(self) -> str:
        return heat_token(self.rating)

    @property
    def label(self) -> str:
        return {
            "--heat-well-below": "Well below",
            "--heat-below": "Below",
            "--heat-average": "Average",
            "--heat-above": "Above",
            "--heat-well-above": "Well above",
        }[self.band]

    def render(self) -> str:
        return (
            f'<span class="fl-heat fl-figure" style="color: var({self.band})"'
            f' data-ink="{self.band}" data-plate="--surface-panel"'
            f' aria-label="{self.rating}, {self.label}">{self.rating}</span>'
        )


@dataclass(frozen=True)
class BandLegend:
    """The printed band table. Answers "is 74 good?" without a live percentile, and
    degrades correctly in a save with no league history yet."""

    def cells(self) -> int:
        return 0  # a legend is chrome, not data

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return 22.0

    def render(self) -> str:
        cells = "".join(
            f'<span class="fl-heatkey"><i style="background: var({token})"></i>'
            f'{_ink(label, "--content-quiet", "--surface-panel")}'
            f'<b class="fl-figure">{low}-{high}</b></span>'
            for (token, label, low, high) in (
                ("--heat-well-below", "Well below", 40, 59),
                ("--heat-below", "Below", 60, 69),
                ("--heat-average", "Average", 70, 79),
                ("--heat-above", "Above", 80, 84),
                ("--heat-well-above", "Well above", 85, 99),
            )
        )
        return f'<div class="fl-bands">{cells}</div>'


# --------------------------------------------------------------------------
# The arc family. `04` 6.4 permits a compact gauge for stamina, roster fit,
# development progress, portal interest or scouting confidence; geometry.css bounds it:
#
#   "An arc is permitted ONLY where the datum is a proportion. An arc that encodes a
#    rank or a count is a lie about the shape of the number."
#
# Enforced by construction -- every one of these takes a proportion of a stated whole and
# raises on anything outside 0-1, so a rank cannot be drawn as an arc even by mistake.
# One idea at four scales: ShareBar 4 -> ValueRing 26 -> ArcGauge 64 -> AttributeDial 212.
# --------------------------------------------------------------------------

_RING_STROKE_RATIO = tokens.VALUES["--ring-stroke-ratio"]
_ARC_START = 150.0
_ARC_SWEEP = 240.0


def _proportion(value: float, what: str) -> float:
    if not 0.0 <= value <= 1.0:
        raise ValueError(
            f"{what} is {value}; an arc takes a proportion of a stated whole. "
            "A rank or a count is not one -- print it."
        )
    return value


def _arc(diameter: float, stroke: float, proportion: float, tint: str,
         sweep: float = 360.0, start: float = -90.0) -> str:
    """One SVG ring, used at every scale. A dash offset around a circle is the whole of
    the arc family; three separate shapes would drift apart."""
    r = (diameter - stroke) / 2
    circumference = 2 * 3.141592653589793 * r
    length = circumference * (sweep / 360.0)
    return (
        f'<svg class="fl-arc" width="{diameter:g}" height="{diameter:g}"'
        f' viewBox="0 0 {diameter:g} {diameter:g}" aria-hidden="true">'
        f'<circle cx="{diameter / 2:g}" cy="{diameter / 2:g}" r="{r:g}" fill="none"'
        f' stroke="var(--rule-structural)" stroke-width="{stroke:g}"'
        f' stroke-dasharray="{length:g} {circumference:g}"'
        f' transform="rotate({start:g} {diameter / 2:g} {diameter / 2:g})"/>'
        f'<circle cx="{diameter / 2:g}" cy="{diameter / 2:g}" r="{r:g}" fill="none"'
        f' stroke="var({tint})" stroke-width="{stroke:g}" stroke-linecap="butt"'
        f' stroke-dasharray="{length * proportion:g} {circumference:g}"'
        f' transform="rotate({start:g} {diameter / 2:g} {diameter / 2:g})"/></svg>'
    )


@dataclass(frozen=True)
class ValueRing:
    """Arc family step 2 (26 pt). A proportion beside its printed figure."""

    proportion: float
    figure: str
    label: str
    diameter: float = 26.0
    tint: str = "--action-secondary"

    def __post_init__(self) -> None:
        _proportion(self.proportion, f"ValueRing {self.label!r}")

    def cells(self) -> int:
        return 1

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return self.diameter

    def render(self) -> str:
        stroke = max(self.diameter * float(_RING_STROKE_RATIO), 2.0)
        return (
            f'<span class="fl-ring" style="width: {self.diameter:g}px">'
            + _arc(self.diameter, stroke, self.proportion, self.tint)
            + f'<b class="fl-figure">{escape(self.figure)}</b>'
            f'<span class="fl-sr">{escape(self.label)}</span></span>'
        )


@dataclass(frozen=True)
class AttributeDial:
    """Arc family step 4 (212 pt hero), on the 40-99 scale.

    The shipped component's own doc still says "red below 70, amber 70-84, green 85+" --
    the three-band scale `04` 6.4 retired on 2026-08-22. This uses the five bands, so a
    dial and a table cell never disagree about the same number."""

    rating: int
    title: str
    diameter: float = 212.0

    def __post_init__(self) -> None:
        if not 40 <= self.rating <= 99:
            raise ValueError(f"AttributeDial {self.title!r} is {self.rating}; the scale is 40-99")

    @property
    def proportion(self) -> float:
        return (self.rating - 40) / 59

    def cells(self) -> int:
        return 1

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return self.diameter

    def render(self) -> str:
        stroke = tokens.px("--dial-stroke") * (self.diameter / 212.0)
        band = heat_token(self.rating)
        return (
            f'<span class="fl-dial" style="width: {self.diameter:g}px;'
            f' height: {self.diameter:g}px">'
            + _arc(self.diameter, stroke, self.proportion, band, _ARC_SWEEP,
                   _ARC_START - 90.0)
            + f'<b class="fl-figure" data-ink="{band}" data-plate="--surface-panel"'
            f' style="color: var({band}); font-size: {self.diameter * 0.30:g}px">'
            f"{self.rating}</b>"
            f'<span class="fl-label3">{escape(self.title)}</span></span>'
        )


@dataclass(frozen=True)
class ShareBar:
    """Arc family step 1 (4 pt). The same idea flattened into a table track."""

    proportion: float
    label: str
    figure: str
    tint: str = "--action-secondary"

    def __post_init__(self) -> None:
        _proportion(self.proportion, f"ShareBar {self.label!r}")

    def cells(self) -> int:
        return 1

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return 18.0

    def render(self) -> str:
        return (
            '<span class="fl-share">'
            f'{_ink(self.label, "--content-secondary", "--surface-panel")}'
            f'<span class="fl-share__track"><i style="width: {self.proportion * 100:g}%;'
            f' background: var({self.tint})"></i></span>'
            f'<b class="fl-figure">{escape(self.figure)}</b></span>'
        )


@dataclass(frozen=True)
class Meter:
    """A capacity track with a defined over-capacity state.

    Over capacity is the interesting case -- a cap sheet that cannot show itself breached
    is not a cap sheet -- so the bar overruns its track rather than clamping."""

    value: float
    capacity: float
    label: str
    unit: str = ""

    def cells(self) -> int:
        return 2  # the value and the capacity are both printed

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return 30.0

    @property
    def over(self) -> bool:
        return self.value > self.capacity

    def render(self) -> str:
        filled = min(self.value / self.capacity, 1.0) * 100 if self.capacity else 0
        tint = "--state-negative" if self.over else "--action-secondary"
        overrun = (
            f'<i class="fl-meter__over" style="width: '
            f'{min((self.value / self.capacity - 1) * 100, 40):g}%"></i>'
            if self.over
            else ""
        )
        return (
            '<span class="fl-meter">'
            f'<span class="fl-label3">{escape(self.label)}</span>'
            f'<span class="fl-meter__track"><i style="width: {filled:g}%;'
            f' background: var({tint})"></i>{overrun}</span>'
            f'<b class="fl-figure">{escape(f"{self.value:g}{self.unit}")}'
            f' / {escape(f"{self.capacity:g}{self.unit}")}</b></span>'
        )


@dataclass(frozen=True)
class OpposedBar:
    """Two teams on one shared track. Both fills carry the mandatory hairline."""

    label: str
    home: float
    away: float
    home_name: str
    away_name: str

    def cells(self) -> int:
        return 2

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return 30.0

    def render(self) -> str:
        total = self.home + self.away
        share = (self.home / total * 100) if total else 50
        return (
            '<span class="fl-opposed">'
            f'<span class="fl-label3">{escape(self.label)}</span>'
            '<span class="fl-opposed__track">'
            f'<i class="fl-opposed__home" style="width: {share:g}%"></i>'
            f'<i class="fl-opposed__away" style="width: {100 - share:g}%"></i></span>'
            f'<b class="fl-figure">{escape(f"{self.home:g}")}'
            f' &ndash; {escape(f"{self.away:g}")}</b>'
            f'<span class="fl-sr">{escape(self.home_name)} against '
            f"{escape(self.away_name)}</span></span>"
        )


@dataclass(frozen=True)
class FormLine:
    """Bounded last-N results. A shape for a sequence, which a column of letters is not."""

    results: tuple[tuple[str, str, str], ...]  # (outcome W/L/D, score, opponent)

    def cells(self) -> int:
        return len(self.results)

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return 30.0

    def render(self) -> str:
        tint = {"W": "--state-positive", "L": "--state-negative", "D": "--content-quiet"}
        cells = "".join(
            f'<span class="fl-form__result" style="--tint: var({tint[outcome]})">'
            f'<b>{escape(outcome)}</b>'
            f'<span class="fl-sr">{escape(score)} against {escape(opponent)}</span>'
            f'<em class="fl-figure">{escape(opponent)}</em></span>'
            for outcome, score, opponent in self.results
        )
        return f'<span class="fl-form">{cells}</span>'


@dataclass(frozen=True)
class Chip:
    text: str
    tone: str = "quiet"  # quiet | live | positive | warning | negative | gold


# --------------------------------------------------------------------------
# The eight
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class Table:
    columns: tuple[Col, ...]
    rows: tuple[tuple[str, ...], ...]
    density: str = "dense"  # dense | comfortable
    #: A dense row is 24 px (`--track-row-dense`), below the 44 pt tap target, so a
    #: dense table is a readout grid whatever it is wired to. Only a comfortable
    #: table -- 44 pt tracks -- counts against the tappable budget.
    tappable: bool = False

    def __post_init__(self) -> None:
        if self.tappable and self.density != "comfortable":
            raise ValueError("a tappable table must be comfortable: 44 pt tracks")

    def cells(self) -> int:
        return len(self.columns) * len(self.rows)

    def readout_rows(self) -> int:
        return 0 if self.tappable else len(self.rows)

    def tappable_rows(self) -> int:
        return len(self.rows) if self.tappable else 0

    def columns_count(self) -> int:
        return len(self.columns)

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        track = (
            tokens.px("--track-row-dense")
            if self.density == "dense"
            else tokens.MIN_TARGET
        )
        n = len(self.rows)
        return _LABEL3 + n * track + max(n - 1, 0) * _GAP_HAIR

    def render(self) -> str:
        track = " ".join(f"{c.width_px:.1f}px" for c in self.columns)
        head = "".join(
            f'<div class="col-{c.align}">'
            f'{_ink(c.label, "--content-quiet", "--surface-panel", "fl-label3")}</div>'
            for c in self.columns
        )
        body = []
        for cells in self.rows:
            body.append(
                "".join(
                    f'<div class="col-{c.align}{" fl-figure" if c.figure else ""}">'
                    + (
                        v.render()
                        if isinstance(v, Heat)
                        else _ink(
                            v,
                            "--content-primary" if i == 0 else "--content-secondary",
                            "--surface-panel",
                        )
                    )
                    + "</div>"
                    for i, (c, v) in enumerate(zip(self.columns, cells))
                )
            )
        rows = "".join(f'<div class="fl-tr">{r}</div>' for r in body)
        return (
            f'<div class="fl-table fl-table--{self.density}"'
            f' style="--fl-track: {track}">'
            f'<div class="fl-th">{head}</div>{rows}</div>'
        )


@dataclass(frozen=True)
class Rows:
    items: tuple[Row, ...]
    kind: str = "readout"  # readout | tappable

    def cells(self) -> int:
        return sum(1 + len(i.values) for i in self.items)

    def readout_rows(self) -> int:
        return len(self.items) if self.kind == "readout" else 0

    def tappable_rows(self) -> int:
        return len(self.items) if self.kind == "tappable" else 0

    def columns_count(self) -> int:
        return max((1 + len(i.values) for i in self.items), default=0)

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        """Per item, not per row: a row carrying a meta line is half as tall again as
        the min-height its track declares, and the first build clipped because this
        used the track alone."""
        n = len(self.items)
        return n * _ROW[self.kind] + max(n - 1, 0) * _GAP_HAIR

    def render(self) -> str:
        out = []
        for item in self.items:
            values = "".join(
                f'<span class="fl-figure">{_ink(v, "--content-secondary", "--surface-panel-deep")}</span>'
                for v in item.values
            )
            meta = (
                f'<div class="fl-row__meta">{_ink(item.meta, "--content-quiet", "--surface-panel-deep")}</div>'
                if item.meta
                else ""
            )
            out.append(
                f'<div class="fl-row fl-row--{self.kind}">'
                f'<div class="fl-row__lead">{_ink(item.lead, "--content-primary", "--surface-panel-deep")}{meta}</div>'
                f'<div class="fl-row__values">{values}</div></div>'
            )
        return f'<div class="fl-rows">{"".join(out)}</div>'


@dataclass(frozen=True)
class Panel:
    """The house glass panel. A title is a label, not data, so it costs no cell."""

    title: str
    child: Node
    meta: str | None = None

    def cells(self) -> int:
        return self.child.cells()

    def readout_rows(self) -> int:
        return self.child.readout_rows()

    def tappable_rows(self) -> int:
        return self.child.tappable_rows()

    def columns_count(self) -> int:
        return self.child.columns_count()

    def golds(self) -> int:
        return self.child.golds()

    def height(self) -> float:
        return _PANEL_HEAD + _PANEL_PAD + self.child.height()

    def render(self) -> str:
        meta = (
            f'<span class="fl-panel__meta">{_ink(self.meta, "--content-quiet", "--world-raised", "fl-label3")}</span>'
            if self.meta
            else ""
        )
        return (
            '<section class="fl-panel">'
            f'<header class="fl-panel__head">{_ink(self.title, "--content-quiet", "--world-raised", "fl-label3")}{meta}</header>'
            f'<div class="fl-panel__body">{self.child.render()}</div>'
            "</section>"
        )


@dataclass(frozen=True)
class Field:
    """The Match Day field. `overlays` are the only data on it -- the turf, the lines
    and the hash marks are drawing, and drawing is not a readout."""

    home: str  # mark key
    away: str
    overlays: tuple[str, ...] = ()

    def cells(self) -> int:
        return len(self.overlays)

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        return _FIELD

    def render(self) -> str:
        from marks import mark_uri

        chips = "".join(
            f'<span class="fl-field__overlay">{_ink(o, "--field-annotation", "--fl-turf-mid")}</span>'
            for o in self.overlays
        )
        return (
            '<div class="fl-field">'
            '<div class="fl-field__turf" aria-hidden="true"></div>'
            f'<img class="fl-field__mark fl-field__mark--home" src="{mark_uri(self.home)}" alt="">'
            f'<img class="fl-field__mark fl-field__mark--away" src="{mark_uri(self.away)}" alt="">'
            f'<div class="fl-field__overlays">{chips}</div>'
            "</div>"
        )


@dataclass(frozen=True)
class Hero:
    """A Broadcast or Dossier head.

    The source spends a whole section on why this exists: the product may never draw a
    face, so "the mark, huge" and "the numeral, huge" carry the drama a portrait would.
    That makes three things load-bearing here and none of them optional -- the mark runs
    as a WATERMARK behind the text rather than as an inline image beside it, the numeral
    runs at 40-72, and the ground is flooded with club or opponent colour.

    The first build drew a 96 px inline mark, a 34 px numeral and a neutral ground, which
    is a Desk frame with a bigger headline."""

    mark: str | None
    headline: str
    numeral: str | None = None
    points: tuple[str, ...] = ()
    #: "broadcast" floods the plate; "dossier" is the band above the seam.
    scale: str = "broadcast"
    #: Whose colour floods -- "club" or "opponent".
    side: str = "club"

    #: Watermark size and head height per scale, from the source's specification table
    #: (Broadcast mark 200-390, Dossier 180-220 above the seam) and its drawn examples
    #: (Signing day: 72 pt headline, 390 px watermark; Prospect dossier: 132 pt head,
    #: 212 px watermark, name at 38, ceiling at 40).
    WATERMARK = {"broadcast": 390.0, "dossier": 212.0}
    HEADLINE = {"broadcast": 72.0, "dossier": 38.0}
    NUMERAL = {"broadcast": 64.0, "dossier": 40.0}
    #: A dossier head is a fixed band above the seam. A broadcast head is the whole
    #: plate, so it flexes to whatever the frame gives it and reports only the height its
    #: content actually needs -- declaring 291 made every committing broadcast surface
    #: overflow its own 241 pt plate.
    #: Chrome around the head's text, MEASURED per scale like the row heights above.
    #: Broadcast is the 28 pt of --pad-band; a dossier head measures 48.5, and chasing the
    #: extra 20 through the flex box is a worse use of effort than reading it off the page.
    #: Captured 2026-08-22 at 1280x720; `--only <id>` plus the DOM probe in the README
    #: re-measures it.
    CHROME = {"broadcast": 28.0, "dossier": 48.5}
    #: Line box of one point in the head's list, plus the list's own 4 pt.
    POINT = 16.8
    POINTS_PAD = 4.0

    def cells(self) -> int:
        return (1 if self.numeral else 0) + len(self.points)

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return 0

    def height(self) -> float:
        total = self.CHROME[self.scale] + self.HEADLINE[self.scale] * 1.02
        if self.numeral:
            total += self.NUMERAL[self.scale] + _GAP_XS
        if self.points:
            total += len(self.points) * self.POINT + self.POINTS_PAD + _GAP_XS
        return total

    def render(self) -> str:
        from marks import mark_uri

        mark = (
            f'<img class="fl-hero__watermark" src="{mark_uri(self.mark)}" alt=""'
            f' style="height: {self.WATERMARK[self.scale]:g}px">'
            if self.mark
            else ""
        )
        ground = "--fl-club-field" if self.side == "club" else "--fl-opponent-field"
        ink = "--fl-club-ink" if self.side == "club" else "--fl-opponent-ink"
        numeral = (
            f'<div class="fl-hero__numeral fl-figure"'
            f' style="font-size: {self.NUMERAL[self.scale]:g}px">'
            f"{_ink(self.numeral, ink, ground)}</div>"
            if self.numeral
            else ""
        )
        points = "".join(
            f"<li>{_ink(p, ink, ground)}</li>" for p in self.points
        )
        # The head takes the height its content needs; a broadcast head then flexes to
        # fill the plate it is the whole of.
        band = "flex: none" if self.scale == "dossier" else "flex: 1 1 auto"
        return (
            f'<div class="fl-hero fl-hero--{self.scale}"'
            f' style="--fl-flood: var({ground}); {band}">'
            f"{mark}"
            '<div class="fl-hero__text">'
            f'<div class="fl-hero__headline"'
            f' style="font-size: {self.HEADLINE[self.scale]:g}px">'
            f'{_ink(self.headline, ink, ground)}</div>'
            f"{numeral}"
            f'<ul class="fl-hero__points">{points}</ul></div></div>'
        )


@dataclass(frozen=True)
class Split:
    """Two stacked halves with the 2 px gold seam between them. The Dossier register's
    only legal body: a dossier is a subject above and its evidence below."""

    top: Node
    bottom: Node
    seam: bool = True

    def _kids(self) -> tuple[Node, ...]:
        return (self.top, self.bottom)

    def cells(self) -> int:
        return _walk(self._kids(), "cells")

    def readout_rows(self) -> int:
        return _walk(self._kids(), "readout_rows")

    def tappable_rows(self) -> int:
        return _walk(self._kids(), "tappable_rows")

    def columns_count(self) -> int:
        return max(self.top.columns_count(), self.bottom.columns_count())

    def golds(self) -> int:
        return _walk(self._kids(), "golds")

    def height(self) -> float:
        return self.top.height() + (_SEAM if self.seam else 0) + _GAP_LG + self.bottom.height()

    def render(self) -> str:
        seam = '<div class="fl-seam" aria-hidden="true"></div>' if self.seam else ""
        return (
            '<div class="fl-split">'
            f'<div class="fl-split__top">{self.top.render()}</div>'
            f"{seam}"
            f'<div class="fl-split__bottom">{self.bottom.render()}</div></div>'
        )


@dataclass(frozen=True)
class Stack:
    children: tuple[Node, ...]
    direction: str = "column"  # column | row

    def cells(self) -> int:
        return _walk(self.children, "cells")

    def readout_rows(self) -> int:
        return _walk(self.children, "readout_rows")

    def tappable_rows(self) -> int:
        return _walk(self.children, "tappable_rows")

    def columns_count(self) -> int:
        return max((c.columns_count() for c in self.children), default=0)

    def golds(self) -> int:
        return _walk(self.children, "golds")

    def height(self) -> float:
        heights = [c.height() for c in self.children]
        if self.direction == "row":
            return max(heights, default=0.0)
        return sum(heights) + max(len(heights) - 1, 0) * _GAP_MD

    def render(self) -> str:
        kids = "".join(c.render() for c in self.children)
        return f'<div class="fl-stack fl-stack--{self.direction}">{kids}</div>'


@dataclass(frozen=True)
class Chips:
    items: tuple[Chip, ...]

    def cells(self) -> int:
        return len(self.items)

    def readout_rows(self) -> int:
        return 0

    def tappable_rows(self) -> int:
        return 0

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return sum(1 for c in self.items if c.tone == "gold")

    def height(self) -> float:
        return _CHIP

    def render(self) -> str:
        out = []
        for chip in self.items:
            ink = {
                "quiet": "--content-quiet",
                "live": "--state-live",
                "positive": "--state-positive",
                "warning": "--state-warning",
                "negative": "--state-negative",
                "gold": "--ink-on-gold",
            }[chip.tone]
            # --gold-field is a gradient; --fl-gold is its mid stop and the
            # darkest ground the ink actually sits on.
            plate = "--fl-gold" if chip.tone == "gold" else "--surface-panel"
            out.append(
                f'<span class="fl-chip fl-chip--{chip.tone}">'
                f"{_ink(chip.text, ink, plate)}</span>"
            )
        return f'<div class="fl-chips">{"".join(out)}</div>'


@dataclass(frozen=True)
class Custom:
    """The escape hatch, budgeted at six uses across the whole registry. Anything more
    and the primitives have quietly rotted back into per-surface renderers.

    Cell and row counts are declared, because the checks cannot read arbitrary HTML.
    Declaring them low to duck a budget is possible; that is what review is for."""

    html: str
    declared_cells: int = 0
    declared_readout: int = 0
    declared_tappable: int = 0
    declared_golds: int = 0
    declared_height: float = 0.0

    def __post_init__(self) -> None:
        # A Custom that declares nothing costs nothing against every budget, which makes
        # the escape hatch a way out of all of them. Six are allowed; each has to say what
        # it weighs.
        if self.declared_height <= 0:
            raise ValueError(
                "Custom must declare a height; the checks cannot measure arbitrary HTML"
            )

    def cells(self) -> int:
        return self.declared_cells

    def readout_rows(self) -> int:
        return self.declared_readout

    def tappable_rows(self) -> int:
        return self.declared_tappable

    def columns_count(self) -> int:
        return 0

    def golds(self) -> int:
        return self.declared_golds

    def height(self) -> float:
        return self.declared_height

    def render(self) -> str:
        return self.html


def walk(node: Node):
    """Depth-first over a body tree, for checks that need every node.

    Table rows hold cell VALUES, not nodes, but a `Heat` is a value that carries a rule
    with it -- so they are yielded too, or the band-table check cannot see the thing it
    exists to pair with."""
    yield node
    if isinstance(node, Table):
        for row in node.rows:
            for value in row:
                if isinstance(value, Heat):
                    yield value
    for name in ("child", "top", "bottom"):
        kid = getattr(node, name, None)
        if kid is not None:
            yield from walk(kid)
    for kid in getattr(node, "children", ()):
        yield from walk(kid)


def custom_count(node: Node) -> int:
    return sum(1 for n in walk(node) if isinstance(n, Custom))
