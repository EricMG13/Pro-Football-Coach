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

#: The identity mark in the Desk band. Every register carries this one; Broadcast and
#: Dossier carry a watermark on top of it, whose size is a property of the `Hero` that
#: draws it rather than a second table here. Holding two tables for one concept is what
#: let the stamped size and the drawn size disagree in the first build.
BAND_MARK_HEIGHT = 19


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


def head_mark_height(surface) -> float:
    """The largest mark the frame draws: a Hero's watermark if it has one, else the
    19 px band mark. This is what the mark-scale rule is measured against."""
    from primitives import Hero, walk

    heads = [n for n in walk(surface.body) if isinstance(n, Hero) and n.mark]
    return max((n.WATERMARK[n.scale] for n in heads), default=float(BAND_MARK_HEIGHT))


def frame(surface, body_html: str) -> str:
    """One reference frame at the install floor."""
    committing = surface.commit is not None
    height = tokens.viewport_height(committing)
    # The one control the design system says must be unmistakable, stamped like every
    # other text run so its contrast is actually scored. The first build left it bare.
    commit = (
        '<div class="fl-commit">'
        f'<span data-ink="--ink-on-gold" data-plate="--fl-gold"'
        f' style="color: var(--ink-on-gold)">{escape(surface.commit)}</span></div>'
        if committing
        else ""
    )
    return (
        f'<div class="fl-frame" data-surface="{surface.id}" data-number="{surface.number}"'
        f' data-register="{surface.register}" data-status="{surface.status_name}"'
        f' data-viewport="{height:g}" data-cells="{surface.cells}"'
        f' data-mark-height="{head_mark_height(surface):g}">'
        f"{_header(surface)}{_rail(surface)}"
        f'<div class="fl-plate" style="height: {height:g}px">{body_html}</div>'
        f"{commit}"
        '<div class="fl-frame__grain" aria-hidden="true"></div>'
        "</div>"
    )
