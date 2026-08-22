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
_ROW = {
    ("tappable", True): 64.0,
    ("tappable", False): 44.0,
    ("readout", True): 52.0,
    ("readout", False): 40.0,
}

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


@dataclass(frozen=True)
class Col:
    """A table column. Width is in CHARACTERS, which is what makes the overflow
    check possible without a browser: characters times the mono advance is a real
    pixel width, whereas a declared px width tells you nothing about the content."""

    label: str
    chars: int
    align: str = "left"
    figure: bool = True


@dataclass(frozen=True)
class Row:
    """One line of a `Rows`. `lead` identifies, `values` are the facts on it."""

    lead: str
    values: tuple[str, ...] = ()
    meta: str | None = None


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
        track = " ".join(f"{c.chars}ch" for c in self.columns)
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
                    f'{_ink(v, "--content-primary" if i == 0 else "--content-secondary", "--surface-panel")}'
                    "</div>"
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
        total = sum(_ROW[(self.kind, item.meta is not None)] for item in self.items)
        return total + max(len(self.items) - 1, 0) * _GAP_HAIR

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
    """A Broadcast or Dossier head: one mark, one headline, one numeral, a few points."""

    mark: str | None
    headline: str
    numeral: str | None = None
    points: tuple[str, ...] = ()

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

    #: Mark size in the head band. The band is 180-220 for a Dossier (`04` 6.5), and
    #: the mark sits inside it rather than above it -- stacked, a 180 px mark plus its
    #: own headline already exceeds the 275 pt a committing plate has.
    MARK = 96.0
    #: Measured band height at MARK 96: the mark plus the flex row's own line boxes.
    BAND = 107.0

    def height(self) -> float:
        text = tokens.px("--size-title") * 1.05
        if self.numeral:
            text += tokens.px("--size-figure") + _GAP_SM
        if self.points:
            text += len(self.points) * 11.0 * 1.35 + _GAP_SM
        return max(text, self.BAND if self.mark else 0.0)

    def render(self) -> str:
        from marks import mark_uri

        mark = (
            f'<img class="fl-hero__mark" src="{mark_uri(self.mark)}" alt="">'
            if self.mark
            else ""
        )
        numeral = (
            f'<div class="fl-hero__numeral fl-figure">'
            f'{_ink(self.numeral, "--content-primary", "--world-page")}</div>'
            if self.numeral
            else ""
        )
        points = "".join(
            f'<li>{_ink(p, "--content-secondary", "--world-page")}</li>' for p in self.points
        )
        return (
            f'<div class="fl-hero">{mark}'
            '<div class="fl-hero__text">'
            f'<div class="fl-hero__headline">{_ink(self.headline, "--content-primary", "--world-page")}</div>'
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
            plate = "--action-primary" if chip.tone == "gold" else "--surface-panel"
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
    """Depth-first over a body tree, for checks that need every node."""
    yield node
    for name in ("child", "top", "bottom"):
        kid = getattr(node, name, None)
        if kid is not None:
            yield from walk(kid)
    for kid in getattr(node, "children", ()):
        yield from walk(kid)


def custom_count(node: Node) -> int:
    return sum(1 for n in walk(node) if isinstance(n, Custom))
