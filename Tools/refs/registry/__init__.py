"""The 59 surfaces, six family modules plus entry.

59 = 74 registry numbers less the 15 that redirect. The 74 are the 62 Swift cases in
`ScreenRegistry.swift` plus twelve at 63-74 that have no case yet; the 15 aliases fold
into the canonical sibling they route to, so they are not drawn twice.

Order within a family is registry order, which is the order the identity header's
sibling links appear in.
"""

from __future__ import annotations

from surface import Surface

from . import (
    career,
    entry,
    league,
    personnel,
    pro_management,
    recruiting,
    weekly_command,
)

REGISTRY: tuple[Surface, ...] = (
    *weekly_command.SURFACES,
    *personnel.SURFACES,
    *recruiting.SURFACES,
    *pro_management.SURFACES,
    *league.SURFACES,
    *career.SURFACES,
    *entry.SURFACES,
)
