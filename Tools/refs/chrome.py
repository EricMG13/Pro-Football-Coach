"""Frame chrome: everything a surface does not choose.

A surface declares its lean, family, fixture and (optionally) one committing
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

LEANS = ("BROADCAST", "DESK", "DOSSIER", "MATCH_DAY")

#: The family name the band prints, `04` 6.1d's second row.
FAMILY_LABEL = {
    "weeklyCommand": "This week",
    "personnel": "Personnel",
    "recruiting": "Recruiting",
    "proManagement": "Pro management",
    "league": "League",
    "career": "Career",
    "entry": "Entry",
}

#: The identity mark in the Desk band. Every lean carries this one; Broadcast and
#: Dossier carry a watermark on top of it, whose size is a property of the `Hero` that
#: draws it rather than a second table here. Holding two tables for one concept is what
#: let the stamped size and the drawn size disagree in the first build.
BAND_MARK_HEIGHT = 19


def _band(surface) -> str:
    """The identity band, `04` section 6.1d (2026-08-22 amendment).

    One band that ENCLOSES the whole navigation row -- mark, club name, record and rank,
    family name, sibling tabs and the context slot all sit inside it. It is not a pill
    beside the navigation; the navigation is inside it. 6.1c's header-plus-icon-rail is
    replaced, and the rail is gone: the band is the only place a Desk surface spends club
    colour, which is what stops a football game reading as a database.

    Gradient from the club's primary to `world.page`, hairline of the club's secondary.
    6.1a's team-fill rule applies unchanged -- the gradient is a team fill and therefore
    always carries its boundary."""
    club, _ = marks.fixture(surface.fixture)
    tier = "college" if surface.fixture == "college" else "pro"
    screen = BY_ID.get(surface.id)
    family = screen.family if screen else surface.family
    tabs = "".join(
        f'<span class="fl-tab{" fl-tab--here" if s.id == surface.id else ""}">'
        f"{escape(s.name)}</span>"
        for s in siblings(family)
    )
    return (
        f'<header class="fl-band" style="--club: {club.primary};'
        f' --club-line: {club.secondary}">'
        f'<img class="fl-band__mark" src="{marks.mark_uri(marks.FIXTURES[surface.fixture][0])}" alt="">'
        f'<span class="fl-band__club">{escape(club.name)}</span>'
        f'<span class="fl-band__record fl-figure">7-0 · #9</span>'
        '<span class="fl-band__rule" aria-hidden="true"></span>'
        f'<span class="fl-band__family">{escape(FAMILY_LABEL[family])}</span>'
        f'<nav class="fl-band__tabs">{tabs}</nav>'
        f'<span class="fl-band__context fl-figure">{tier.upper()} · WK 7</span>'
        "</header>"
    )


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
        f' data-lean="{surface.lean}" data-status="{surface.status_name}"'
        f' data-viewport="{height:g}" data-cells="{surface.cells}"'
        f' data-mark-height="{head_mark_height(surface):g}">'
        f"{_band(surface)}"
        f'<div class="fl-plate" style="height: {height:g}px">{body_html}</div>'
        f"{commit}"
        '<div class="fl-frame__grain" aria-hidden="true"></div>'
        "</div>"
    )
