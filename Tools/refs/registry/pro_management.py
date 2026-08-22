"""Pro management -- five canonical surfaces plus the two the transactions model owes.

This family carries the plan's sharpest build-state finding: Cap & Contracts and Roster
Cuts render byte-identical screens, because `ProManagementView` takes a title and no
focus, and `ProManagementReadModel` has no transactions collection at all."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, Panel, Row, Rows, Split, Stack, Status, Table,
    blocker, broadcast, desk, dossier, gap,
)

FIXTURE = "pro"

cap_contracts = desk(
    id="capContracts", number=34, name="Cap & Contracts", family="proManagement",
    status=Status.PARTIAL, parent="ProManagementView", fixture=FIXTURE,
    evidence="Sources/ProFootballCoachUI/ProManagementView.swift:90 -- title only, no focus",
    body=Stack((
        Panel("Cap", Table(
            (Col("Line", 20, "left", False), Col("Amount", 12, "right"), Col("Share", 7, "right")),
            (("Active contracts", "$182,400,000", "81%"),
             ("Dead money", "$14,100,000", "6%"),
             ("Space", "$28,500,000", "13%")),
        )),
        Panel("Largest", Table(
            (Col("Player", 18, "left", False), Col("Cap hit", 12, "right"), Col("Years", 6, "right")),
            (("Dez Achterberg", "$31,000,000", "3"),
             ("Lowell Pryce", "$22,400,000", "2"),
             ("Kofi Ellwood", "$18,900,000", "4")),
        )),
    )),
    gaps=(
        blocker("SCREEN", "Renders byte-identical to Roster Cuts; the view cannot tell the two numbers apart."),
        gap("DATA", "No per-year cap projection exists, so a multi-year decision has nothing behind it."),
    ),
)

contract_negotiation = dossier(
    id="contractNegotiation", number=35, name="Contract Negotiation",
    family="proManagement", status=Status.BUILT, fixture=FIXTURE,
    commit="Send the offer",
    body=Split(
        top=Hero(mark="TeamLogo_0D81D2F903834BD5A74176604D277691",
                 headline="Lowell Pryce", numeral="22.4",
                 points=("Two years left; the agent wants a fifth",),
                 scale="dossier"),
        bottom=Table(
            (Col("Term", 12, "left", False), Col("Ours", 12, "right"),
             Col("Theirs", 12, "right"), Col("Standing", 20, "left", False)),
            (("Per year", "$24,000,000", "$28,500,000", "Two seasons together"),
             ("Guaranteed", "$40,000,000", "$72,000,000", "The gap that matters")),
        ),
    ),
    gaps=(
        gap("DATA", "Agent position is drawn as a fixed counter-offer; no negotiation model produces it."),
    ),
)

roster_cuts = desk(
    id="rosterCutsTransactions", number=36, name="Roster Cuts & Transactions",
    family="proManagement", status=Status.PARTIAL, parent="ProManagementView", fixture=FIXTURE,
    evidence="Sources/ProFootballCoachUI/ProManagementView.swift:90 -- no transactions collection in the read model",
    commit="Confirm the cuts",
    body=Stack((
        Panel("To 53", Table(
            (Col("Player", 18, "left", False), Col("Pos", 4, "left", False),
             Col("Cap saved", 12, "right"), Col("Dead", 11, "right")),
            (("Rafe Coombe", "LB", "$4,100,000", "$900,000"),
             ("Bry Landover", "OG", "$1,950,000", "$450,000")),
        )),
        Panel("Position", Rows((
            Row("Squad", ("56 of 53",), "Three to release"),
        ), kind="readout")),
    )),
    gaps=(
        blocker("DATA", "ProManagementReadModel holds no transactions collection; this list cannot be real."),
        blocker("SCREEN", "Identical to Cap & Contracts for the same reason."),
    ),
)

draft_room = broadcast(
    id="draftRoom", number=39, name="Draft Room", family="proManagement",
    status=Status.WRAPPER, parent="ProOffseasonView", fixture=FIXTURE,
    evidence="Sources/ProFootballCoachUI/ProOffseasonView.swift",
    body=Hero(
        mark="TeamLogo_0D81D2F903834BD5A74176604D277691",
        headline="Rexburg take Alden Ruhl",
        numeral="14",
        points=("Offensive tackle", "Fills the need the cuts opened"),
        scale="broadcast",
    ),
    gaps=(
        blocker("SCREEN", "One of the four ceremony surfaces the source calls unbuilt; three registry numbers alias into the same parent view."),
        gap("INTERACTION", "The clock is a ceremony device and no timed state exists; a pick cannot expire."),
    ),
)

pro_offseason = desk(
    id="proOffseason", number=62, name="Pro Offseason", family="proManagement",
    status=Status.BUILT, fixture=FIXTURE,
    body=Stack((
        Panel("Offseason", Rows((
            Row("Free agency", ("Opens in 3 weeks",), "Twelve of our own out of contract"),
            Row("Draft", ("Pick 14",), "Plus a second and two fourths"),
            Row("Scouting", ("41 graded",), "Of 220 invited"),
        ), kind="tappable")),
        Chips((Chip("Cap space $28.5m", "positive"), Chip("53 under contract", "quiet"))),
    )),
    gaps=(
        blocker("SCREEN", "Three registry numbers alias here -- scouting board, draft board, free agency -- and the parent has one view."),
    ),
)

SURFACES = (cap_contracts, contract_negotiation, roster_cuts, draft_room, pro_offseason)
