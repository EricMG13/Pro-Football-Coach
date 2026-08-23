"""Declaration helpers. No rendering and no rules live here -- only the boilerplate
that would otherwise be repeated 59 times."""

from __future__ import annotations

from primitives import (
    AttributeDial, BandLegend, Chip, Chips, Col, Custom, Field, FormLine, Heat,
    Hero, Meter, OpposedBar, Panel, PlayerCard, Row, Rows, ScoreBug, ShareBar, Split, Stack,
    StatCompare, Table, ValueRing,
)
from surface import Gap, GapKind, NOTHING_MISSING, Lean, Status, Surface

__all__ = [
    "AttributeDial", "BandLegend", "FormLine", "Heat", "Meter", "OpposedBar",
    "PlayerCard", "ScoreBug", "ShareBar", "StatCompare", "ValueRing",
    "Chip", "Chips", "Col", "Custom", "Field", "Hero", "Panel", "Row", "Rows",
    "Split", "Stack", "Table", "Gap", "GapKind", "NOTHING_MISSING", "Lean",
    "Status", "Surface", "desk", "dossier", "broadcast", "gap", "blocker",
]


def gap(kind: str, text: str) -> Gap:
    return Gap(GapKind[kind], text, False)


def blocker(kind: str, text: str) -> Gap:
    return Gap(GapKind[kind], text, True)


def desk(**kw) -> Surface:
    kw.setdefault("lean", Lean.DESK)
    return Surface(**kw)


def dossier(**kw) -> Surface:
    kw.setdefault("lean", Lean.DOSSIER)
    return Surface(**kw)


def broadcast(**kw) -> Surface:
    kw.setdefault("lean", Lean.BROADCAST)
    return Surface(**kw)
