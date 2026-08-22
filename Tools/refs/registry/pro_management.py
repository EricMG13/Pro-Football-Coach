"""Pro management -- five canonical surfaces plus the two the transactions model owes.

This family carries the plan's sharpest build-state finding: Cap & Contracts and Roster
Cuts render byte-identical screens, because `ProManagementView` takes a title and no
focus, and `ProManagementReadModel` has no transactions collection at all."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, Panel, Row, Rows, Split, Stack, Status, Table,
    blocker, desk, dossier, gap,
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
        top=Hero(mark=None, headline="Lowell Pryce", numeral="$22.4m",
                 points=("Two years remaining", "Agent has asked for a fifth year")),
        bottom=Panel("On the table", Table(
            (Col("Term", 12, "left", False), Col("Ours", 12, "right"),
             Col("Theirs", 12, "right"), Col("Standing", 20, "left", False)),
            (("Years", "3", "5", "Warm, no dispute"),
             ("Per year", "$24,000,000", "$28,500,000", "Two seasons together"),
             ("Guaranteed", "$40,000,000", "$72,000,000", "The gap that matters")),
        )),
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
             ("Tomas Ekwueme", "WR", "$2,800,000", "$0"),
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

draft_room = desk(
    id="draftRoom", number=39, name="Draft Room", family="proManagement",
    status=Status.WRAPPER, parent="ProOffseasonView", fixture=FIXTURE,
    evidence="Sources/ProFootballCoachUI/ProOffseasonView.swift",
    commit="Make the pick",
    body=Stack((
        Panel("On the clock", Table(
            (Col("Pick", 5, "right"), Col("Team", 20, "left", False),
             Col("Selection", 18, "left", False), Col("Pos", 4, "left", False)),
            (("12", "Oneonta Slate", "Wilder Cassano", "EDGE"),
             ("13", "Ephraim Maritime", "Yusuf Danko", "CB"),
             ("14", "Rexburg A&M", "-- on the clock --", "--")),
        )),
        Rows((
            Row("Bo Fairweather", ("QB", "91")),
            Row("Alden Ruhl", ("OT", "88"), "Falls further than projected"),
        ), kind="tappable"),
    )),
    gaps=(
        gap("INTERACTION", "The clock is drawn but no timed state exists; a pick cannot expire."),
        gap("SCREEN", "Trading a pick has no surface, though three registry numbers alias into this parent."),
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

# ---- New -----------------------------------------------------------------------

transactions_ledger = desk(
    id="transactionsLedger", number=67, name="Transactions Ledger",
    family="proManagement", status=Status.MISSING, fixture=FIXTURE,
    evidence="no Swift case; ProManagementReadModel has no transactions collection",
    body=Panel("This offseason", Table(
        (Col("Date", 8, "left", False), Col("Move", 10, "left", False),
         Col("Player", 18, "left", False), Col("Cap effect", 12, "right")),
        (("14 Mar", "Released", "Rafe Coombe", "+$4,100,000"),
         ("14 Mar", "Released", "Bry Landover", "+$1,950,000"),
         ("11 Mar", "Re-signed", "Kofi Ellwood", "-$18,900,000"),
         ("09 Mar", "Signed", "Odalys Prieto", "-$7,200,000"),
         ("02 Mar", "Traded", "Pick 47", "+$0")),
    )),
    gaps=(
        blocker("DATA", "No transactions collection exists anywhere in the pro read model."),
        gap("RULE", "Nothing states how long a ledger is retained, and every unbounded collection has cost this project save size before."),
    ),
)

contract_comparison = desk(
    id="contractComparison", number=68, name="Contract Comparison",
    family="proManagement", status=Status.MISSING, fixture=FIXTURE,
    evidence="no Swift case; negotiation shows one contract with no market context",
    body=Panel("At this position", Table(
        (Col("Player", 18, "left", False), Col("Team", 18, "left", False),
         Col("Per year", 12, "right"), Col("Age", 4, "right")),
        (("Lowell Pryce", "Rexburg A&M", "$22,400,000", "29"),
         ("Wilmot Cray", "Oneonta Slate", "$27,000,000", "27"),
         ("Faisal Oyinlola", "Hood River", "$25,500,000", "31"),
         ("Nkosi Brandt", "Kirksville", "$19,000,000", "26")),
    )),
    gaps=(
        blocker("SCREEN", "A negotiation has no market context at any registry number."),
        blocker("DATA", "League-wide contract data is not aggregated by position anywhere."),
    ),
)

SURFACES = (cap_contracts, contract_negotiation, roster_cuts, draft_room,
            pro_offseason, transactions_ledger, contract_comparison)
