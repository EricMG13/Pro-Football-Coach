"""What a registry entry is.

`Status` is the SWIFT build state, not the drawing state, and the two disagree today:
`Coach World.dc.html` routes all 62 registry surfaces, while far fewer are actually
built. Keeping the two axes apart is deliberate -- `Status` answers "does this exist in
`Sources/`", `Gap` answers "what is missing from it". Collapsing them into one field is
what made the published inventory wrong in both directions.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

from primitives import Node, custom_count


class Lean(str, Enum):
    """The presentation lean, `04` section 2.1 (2026-08-22 amendment).

    Orthogonal to canon's nine registers, which say what a screen is ABOUT; the lean says
    how much presentation it may spend. Every surface carries one of each. This generator
    models the lean only -- the nine-register assignment is not derivable from the
    amendment and is declared as a gap rather than invented.

    The axis is whether the player is being told something or working something out.
    Frequency does not set it: a frequency-first rule classifies Match Day as a working
    surface because it is seen fifteen times a season, which is plainly wrong."""

    BROADCAST = "BROADCAST"
    DESK = "DESK"
    DOSSIER = "DOSSIER"
    #: Match Day is the only surface carrying two leans at once -- a Broadcast ground with
    #: a Desk plate on it. Not an exception to be tolerated; the product's central claim.
    MATCH_DAY = "MATCH_DAY"


class Status(str, Enum):
    #: Has its own view with its own read model.
    BUILT = "BUILT"
    #: Routes to a parent view's `switch focus`. Not a stub -- the parent is real.
    WRAPPER = "WRAPPER"
    #: A view exists but does not serve this concept: no focus parameter, a capped
    #: collection, a missing read model, a dead-end detail pane.
    PARTIAL = "PARTIAL"
    #: No Swift case and no view. The twelve numbered 63-74.
    MISSING = "MISSING"
    #: Presented over another surface rather than routed to.
    OVERLAY = "OVERLAY"


class GapKind(str, Enum):
    DATA = "DATA"
    SCREEN = "SCREEN"
    INTERACTION = "INTERACTION"
    ART = "ART"
    RULE = "RULE"


@dataclass(frozen=True)
class Gap:
    kind: GapKind
    text: str
    #: True when this gap stops the surface being usable, rather than merely unfinished.
    blocks: bool = False


#: The sentinel for a surface with genuinely nothing outstanding. Explicit, so that
#: "no gaps declared" and "nothing missing" cannot be confused -- check 12 rejects the
#: first and accepts the second.
NOTHING_MISSING = (Gap(GapKind.RULE, "Nothing outstanding on this surface.", False),)


@dataclass(frozen=True)
class Surface:
    id: str
    number: int
    name: str
    family: str
    lean: Lean
    status: Status
    body: Node
    #: The single gold action. Also reserves the 44 pt bar, which is why it is the one
    #: field that changes the usable viewport.
    commit: str | None = None
    fixture: str = "college"
    #: file:line evidence for the status. Required when status is not BUILT.
    evidence: str | None = None
    #: The parent view a WRAPPER routes through.
    parent: str | None = None
    gaps: tuple[Gap, ...] = ()

    @property
    def status_name(self) -> str:
        return self.status.value

    @property
    def cells(self) -> int:
        return self.body.cells()

    @property
    def readout_rows(self) -> int:
        return self.body.readout_rows()

    @property
    def tappable_rows(self) -> int:
        return self.body.tappable_rows()

    @property
    def columns(self) -> int:
        return self.body.columns_count()

    @property
    def golds(self) -> int:
        """Gold nodes plus the committing bar. The rule is one per surface, total."""
        return self.body.golds() + (1 if self.commit else 0)

    @property
    def customs(self) -> int:
        return custom_count(self.body)
