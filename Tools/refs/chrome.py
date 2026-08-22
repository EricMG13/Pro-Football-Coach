"""Frame chrome: everything a surface does not choose.

A surface declares its register, family, fixture and (optionally) one committing
action. Everything else -- the identity header, the sibling tabs, the icon rail, the
plate geometry, the gold seam, the committing bar and the usable height -- is derived
here. That is deliberate: the cell budget and the 44 pt bar both read
`tokens.viewport_height()`, so a surface can never reserve the bar without paying for
it, and no one can adjust one without the other.
"""

from __future__ import annotations

from html import escape

import marks
import tokens
from screens import BY_ID, siblings

REGISTERS = ("BROADCAST", "DESK", "DOSSIER", "MATCH_DAY")

#: Head-band height per register. Desk is the 19 px identity mark; Broadcast and
#: Dossier are the height of the head the frame opens with. See
#: `checks.MARK_HEIGHT_RANGE` for the contract these are measured against, and
#: `docs/refs/DECISIONS.md` for why Dossier is 96 rather than `04` 6.5's 180.
MARK_HEIGHT = {
    "DESK": 19,
    "BROADCAST": 200,
    "DOSSIER": 96,
    "MATCH_DAY": 19,
}


def _header(surface) -> str:
    club, _ = marks.fixture(surface.fixture)
    tier = "college" if surface.fixture == "college" else "pro"
    tier_name = "College" if tier == "college" else "Pro"
    screen = BY_ID.get(surface.id)
    family = screen.family if screen else surface.family
    tabs = "".join(
        f'<span class="fl-tab{" fl-tab--here" if s.id == surface.id else ""}">'
        f"{escape(s.name)}</span>"
        for s in siblings(family)
    )
    return (
        '<header class="fl-header">'
        '<div class="fl-header__primary">'
        f'<img class="fl-header__mark" src="{marks.mark_uri(marks.FIXTURES[surface.fixture][0])}" alt="">'
        f'<span class="fl-header__club">{escape(club.name)}</span>'
        f'<span class="fl-header__tier fl-header__tier--{tier}">{tier_name}</span>'
        "</div>"
        f'<div class="fl-header__secondary">{tabs}</div>'
        "</header>"
    )


def _rail(surface) -> str:
    """The icon column. Title, Job Board and Offer carry no rail (frame.css)."""
    if surface.id in ("titleContinue", "jobBoard", "offer"):
        return ""
    screen = BY_ID.get(surface.id)
    here = screen.family if screen else surface.family
    buttons = "".join(
        f'<div class="fl-rail__button{" fl-rail__button--here" if f == here else ""}">'
        f"{escape(f[:3])}</div>"
        for f in ("weeklyCommand", "personnel", "recruiting", "proManagement", "league", "career")
    )
    return f'<nav class="fl-rail">{buttons}</nav>'


def frame(surface, body_html: str) -> str:
    """One reference frame at the install floor."""
    committing = surface.commit is not None
    height = tokens.viewport_height(committing)
    commit = (
        f'<div class="fl-commit">{escape(surface.commit)}</div>' if committing else ""
    )
    return (
        f'<div class="fl-frame" data-surface="{surface.id}" data-number="{surface.number}"'
        f' data-register="{surface.register}" data-status="{surface.status_name}"'
        f' data-viewport="{height:g}" data-cells="{surface.cells}"'
        f' data-mark-height="{MARK_HEIGHT[surface.register]}">'
        f"{_header(surface)}{_rail(surface)}"
        f'<div class="fl-plate" style="height: {height:g}px">{body_html}</div>'
        f"{commit}"
        '<div class="fl-frame__grain" aria-hidden="true"></div>'
        "</div>"
    )
