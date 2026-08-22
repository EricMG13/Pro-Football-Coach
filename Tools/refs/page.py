"""The single-document shell: fonts, index rail, frames, gap roll-up, JSON manifest.

The missing-items lean is rendered three ways from one loop -- a `<details>` under
each frame, a document-level roll-up grouped by kind, and a manifest entry -- because a
gap that only appears in one of the three is a gap someone will miss.
"""

from __future__ import annotations

from collections import defaultdict
from html import escape

import tokens
from pathlib import Path
from registry import REGISTRY
from render import render_surface
from screens import FAMILIES
from surface import GapKind, Status

#: Stable across redeploys -- the artifact is found by this name. Do not rename it
#: as a side effect of renaming a symbol; a blanket Register->Lean pass already did
#: that once.
TITLE = "Floodlit Surface Register"

FAMILY_NAMES = {
    "weeklyCommand": "This week",
    "personnel": "Personnel",
    "recruiting": "Recruiting",
    "proManagement": "Pro management",
    "league": "League",
    "career": "Career",
    "entry": "Entry",
}

_PAGE_CSS = """
body {
  margin: 0;
  padding: 24px;
  background: var(--fl-room-deep);
  color: var(--content-secondary);
  font: var(--type-body);
}
.doc { max-width: 940px; margin: 0 auto; display: flex; flex-direction: column; gap: 28px; }
h1 { font: var(--weight-bold) var(--size-screen)/1.1 var(--font-display); color: var(--content-primary); margin: 0; }
h2 { font: var(--weight-bold) var(--size-title)/1.1 var(--font-display); color: var(--content-primary); margin: 0 0 4px; }
h3 { font: var(--weight-semibold) var(--size-lead)/1.2 var(--font-display); color: var(--content-primary); margin: 0; }
p { margin: 0 0 10px; max-width: 68ch; }
a { color: var(--pro-identity); }
.lede { color: var(--content-quiet); }
.index { display: flex; flex-wrap: wrap; gap: 6px; }
.index a {
  font: var(--weight-semibold) var(--size-pill)/1.2 var(--font-display);
  letter-spacing: var(--track-micro);
  text-decoration: none;
  padding: 4px 8px;
  border-radius: var(--radius-row);
  background: var(--surface-panel);
}
.entry { display: flex; flex-direction: column; gap: 8px; }
.entry__head { display: flex; align-items: baseline; gap: 10px; flex-wrap: wrap; }
.badge {
  font: var(--weight-bold) var(--size-flag)/1.1 var(--font-display);
  letter-spacing: var(--track-label);
  text-transform: uppercase;
  padding: 3px 7px;
  border-radius: var(--radius-row);
  background: var(--surface-panel);
  color: var(--content-quiet);
}
.badge--BUILT { color: var(--state-positive); }
.badge--WRAPPER { color: var(--state-info); }
.badge--PARTIAL { color: var(--state-warning); }
.badge--MISSING { color: var(--state-negative); }
.badge--OVERLAY { color: var(--college-identity); }
.scroller { overflow-x: auto; padding-bottom: 4px; }
details { border-top: 1px solid var(--rule-structural); padding-top: 8px; }
summary { cursor: pointer; font: var(--weight-semibold) var(--size-action-small)/1.3 var(--font-display); }
ul { margin: 8px 0 0; padding-left: 18px; }
li { margin-bottom: 4px; }
.blocks { color: var(--state-negative); font-weight: 700; }
.evidence { font-family: var(--font-figure); font-size: var(--size-pill); color: var(--content-quiet); }
table.rollup { border-collapse: collapse; width: 100%; font-size: var(--size-action-small); }
table.rollup td, table.rollup th { text-align: left; padding: 5px 8px; border-bottom: 1px solid var(--rule-structural); vertical-align: top; }
"""


def _gap_list(surface) -> str:
    items = "".join(
        f'<li><span class="badge">{g.kind.value}</span> {escape(g.text)}'
        + (' <span class="blocks">blocks</span>' if g.blocks else "")
        + "</li>"
        for g in surface.gaps
    )
    return (
        f"<details><summary>{len(surface.gaps)} declared "
        f"{'gap' if len(surface.gaps) == 1 else 'gaps'}</summary><ul>{items}</ul></details>"
    )


def _entry(surface) -> str:
    evidence = (
        f'<span class="evidence">{escape(surface.evidence)}</span>'
        if surface.evidence
        else ""
    )
    return (
        f'<section class="entry" id="s-{surface.id}">'
        '<div class="entry__head">'
        f"<h3>{surface.number}. {escape(surface.name)}</h3>"
        f'<span class="badge badge--{surface.status_name}">{surface.status_name}</span>'
        f'<span class="badge">{surface.lean.value}</span>'
        f'<span class="badge">{surface.cells} cells</span>'
        f"{evidence}</div>"
        f'<div class="scroller">{render_surface(surface)}</div>'
        f"{_gap_list(surface)}</section>"
    )


def _rollup() -> str:
    by_kind: dict[str, list[tuple[str, object]]] = defaultdict(list)
    for s in REGISTRY:
        for g in s.gaps:
            by_kind[g.kind.value].append((s.name, g))
    rows = []
    for kind in (k.value for k in GapKind):
        entries = by_kind.get(kind, [])
        blocking = sum(1 for _, g in entries if g.blocks)
        items = "".join(
            f"<li>{escape(name)} &mdash; {escape(g.text)}"
            + (' <span class="blocks">blocks</span>' if g.blocks else "")
            + "</li>"
            for name, g in entries
        )
        rows.append(
            f"<tr><th>{kind}</th><td>{len(entries)} declared, "
            f'<span class="blocks">{blocking} blocking</span><ul>{items}</ul></td></tr>'
        )
    return f'<table class="rollup">{"".join(rows)}</table>'


def _counts() -> str:
    by_status = defaultdict(int)
    for s in REGISTRY:
        by_status[s.status_name] += 1
    cells = "".join(
        f"<tr><th>{status.value}</th><td>{by_status.get(status.value, 0)}</td></tr>"
        for status in Status
    )
    return (
        f'<table class="rollup"><tr><th>Surfaces</th><td>{len(REGISTRY)}</td></tr>{cells}</table>'
    )


#: Characters that must leave the document as entities. The published artifact is wrapped
#: with a charset declaration; a plain file server supplies none, the browser guesses
#: Latin-1, and every multi-byte character mojibakes. Entities read the same either way.
_ENTITIES = {
    "\u00b7": "&middot;", "\u2014": "&mdash;", "\u2013": "&ndash;",
    "\u00b0": "&deg;", "\u2212": "&minus;", "\u00a7": "&sect;",
    "\u00d7": "&times;", "\u2265": "&ge;", "\u2264": "&le;",
}


def _ascii(html: str) -> str:
    for char, entity in _ENTITIES.items():
        html = html.replace(char, entity)
    return html.encode("ascii", "xmlcharrefreplace").decode("ascii")


def build(only: tuple[str, ...] | None = None) -> str:
    """The whole set, or a named subset.

    A subset is for looking at, not for shipping: the deliverable is the whole page.
    The 59-frame document is ~30,000 px tall and a browser will happily fail to
    composite it, which is the only reason this parameter exists."""
    surfaces = [s for s in REGISTRY if only is None or s.id in only]
    index = "".join(
        f'<a href="#s-{s.id}">{s.number}. {escape(s.name)}</a>' for s in surfaces
    )
    families = []
    for family in FAMILIES:
        members = [s for s in surfaces if s.family == family]
        if not members:
            continue
        families.append(
            f'<section><h2>{escape(FAMILY_NAMES[family])}</h2>'
            + "".join(_entry(s) for s in members)
            + "</section>"
        )
    return _ascii(
        f"<title>{TITLE}</title>\n"
        f"<style>{tokens.emit_css()}\n"
        f"{(Path(__file__).parent / 'chrome.css').read_text(encoding='utf-8')}\n"
        f"{_PAGE_CSS}</style>\n"
        '<div class="doc">'
        f"<h1>{TITLE}</h1>"
        '<p class="lede">Every surface in the Coach World registry, drawn at the install '
        f"floor of {tokens.FLOOR_W:g}&times;{tokens.FLOOR_H:g}, with what is not built "
        "declared beneath it. Generated; do not hand-edit.</p>"
        f'<div class="index">{index}</div>'
        + (
            f"<section><h2>Build state</h2>{_counts()}</section>"
            f"<section><h2>Not produced</h2>{_rollup()}</section>"
            if only is None
            else ""
        )
        + "".join(families)
        + "</div>"
    )


def manifest() -> dict:
    return {
        "floor": [tokens.FLOOR_W, tokens.FLOOR_H],
        "viewport": [tokens.VIEWPORT_H, tokens.VIEWPORT_H_COMMITTING],
        "surfaces": [
            {
                "id": s.id,
                "number": s.number,
                "name": s.name,
                "family": s.family,
                "lean": s.lean.value,
                "status": s.status_name,
                "cells": s.cells,
                "commit": s.commit,
                "evidence": s.evidence,
                "gaps": [
                    {"kind": g.kind.value, "text": g.text, "blocks": g.blocks}
                    for g in s.gaps
                ],
            }
            for s in REGISTRY
        ],
    }
