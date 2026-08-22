"""Declaration helpers. No rendering and no rules live here -- only the boilerplate
that would otherwise be repeated 59 times."""

from __future__ import annotations

from primitives import Chip, Chips, Col, Custom, Field, Hero, Panel, Row, Rows, Split, Stack, Table
from surface import Gap, GapKind, NOTHING_MISSING, Register, Status, Surface

__all__ = [
    "Chip", "Chips", "Col", "Custom", "Field", "Hero", "Panel", "Row", "Rows",
    "Split", "Stack", "Table", "Gap", "GapKind", "NOTHING_MISSING", "Register",
    "Status", "Surface", "desk", "dossier", "broadcast", "gap", "blocker",
]


def gap(kind: str, text: str) -> Gap:
    return Gap(GapKind[kind], text, False)


def blocker(kind: str, text: str) -> Gap:
    return Gap(GapKind[kind], text, True)


def desk(**kw) -> Surface:
    kw.setdefault("register", Register.DESK)
    return Surface(**kw)


def dossier(**kw) -> Surface:
    kw.setdefault("register", Register.DOSSIER)
    return Surface(**kw)


def broadcast(**kw) -> Surface:
    kw.setdefault("register", Register.BROADCAST)
    return Surface(**kw)
