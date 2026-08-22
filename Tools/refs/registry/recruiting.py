"""Recruiting -- seven canonical surfaces plus two the class needs.

Four registry numbers in this family are aliases into College Offseason: Portal Hub,
Retention Decisions, Portal Market and NIL Allocation all route there, and
`CollegeOffseasonView` has no focus parameter, so all four render the same screen."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, Panel, Row, Rows, Split, Stack, Status, Table,
    blocker, broadcast, desk, dossier, gap,
)

recruiting_board = desk(
    id="recruitingBoard", number=24, name="Recruiting Board", family="recruiting",
    status=Status.BUILT,
    body=Panel("Board", Table(
        (Col("Prospect", 18, "left", False), Col("Pos", 4, "left", False),
         Col("Stars", 6, "right"), Col("Interest", 9, "right"),
         Col("Distance", 9, "right"), Col("Rivals", 6, "right"),
         Col("Status", 10, "left", False)),
        (("Kalen Ruthers", "QB", "4", "High", "90 mi", "3", "Visiting"),
         ("Ovie Adeyemi", "WR", "4", "Medium", "410 mi", "5", "Contacted"),
         ("Bram Teasdale", "OT", "3", "High", "35 mi", "1", "Committed"),
         ("Sanjay Rooke", "DT", "4", "Low", "620 mi", "6", "Cold"),
         ("Emory Salk", "CB", "3", "Medium", "150 mi", "2", "Contacted"),
         ("Wren Kovalik", "LB", "3", "High", "70 mi", "2", "Visiting"),
         ("Isolde Grange", "K", "2", "High", "20 mi", "0", "Committed")),
    )),
    gaps=(
        gap("DATA", "Interest is a three-band label; the engine holds a continuous value nothing surfaces."),
        gap("INTERACTION", "No board reordering or shortlisting gesture is designed."),
    ),
)

prospect_profile = dossier(
    id="prospectProfile", number=25, name="Prospect Profile", family="recruiting",
    status=Status.BUILT, commit="Offer a scholarship",
    body=Split(
        top=Hero(mark="TeamLogo_0017F958E7D04FFC9EA801A252B40FD6",
                 headline="Kalen Ruthers", numeral="68-89",
                 points=("Quarterback, Pecos, 90 miles",),
                 scale="dossier", side="opponent"),
        bottom=Table(
            (Col("Measure", 17, "left", False), Col("Value", 8, "right"),
             Col("Note", 22, "left", False)),
            (("Scheme fit", "88", "Fits the empty package"),
             ("Projected ceiling", "86", "Three programmes in")),
        ),
    ),
    gaps=(
        gap("ART", "Blank photo plate; prospects have no likeness and will not get one."),
        gap("DATA", "Rival interest is a count, not a named set, so the pressure is unreadable."),
        gap("RULE", "A committing dossier has 241 pt: a 160 pt head, the seam, and 67 pt of evidence -- two rows."),
    ),
)

shortlist = desk(
    id="shortlist", number=26, name="Shortlist", family="recruiting", status=Status.BUILT,
    body=Panel("Shortlisted", Rows((
        Row("Kalen Ruthers", ("QB", "4"), "Visit booked for week 9"),
        Row("Bram Teasdale", ("OT", "3"), "Committed, hold the place"),
        Row("Wren Kovalik", ("LB", "3"), "Wants a defensive coordinator meeting"),
    ), kind="tappable")),
    gaps=(
        gap("INTERACTION", "Removing from the shortlist has no designed confirmation."),
    ),
)

contact_visit = desk(
    id="contactVisitPlanner", number=27, name="Contact & Visit Planner",
    family="recruiting", status=Status.BUILT, commit="Book the week",
    body=Stack((
        Panel("This week", Table(
            (Col("Prospect", 18, "left", False), Col("Action", 14, "left", False),
             Col("Cost", 6, "right"), Col("Window", 10, "left", False)),
            (("Kalen Ruthers", "Official visit", "3", "Week 9"),
             ("Wren Kovalik", "Home visit", "2", "Week 8")),
        )),
        Panel("Budget", Rows((
            Row("Contacts left", ("6 of 12",), "Resets at the dead period"),
        ), kind="readout")),
    )),
    gaps=(
        gap("RULE", "Contact cost is drawn but the rules module does not define a per-action tariff."),
    ),
)

class_overview = desk(
    id="classOverview", number=28, name="Class Overview", family="recruiting",
    status=Status.BUILT,
    body=Stack((
        Panel("Committed", Table(
            (Col("Prospect", 18, "left", False), Col("Pos", 4, "left", False),
             Col("Stars", 6, "right"), Col("Signed", 8, "left", False)),
            (("Bram Teasdale", "OT", "3", "Pending"),
             ("Isolde Grange", "K", "2", "Pending")),
        )),
        Rows((
            Row("Places", ("2 of 22",), "Twenty still open"),
            Row("Average stars", ("2.5",), "Conference average is 3.1"),
            Row("Positions unfilled", ("QB, WR, DT",), "Three of the four priorities"),
        ), kind="readout"),
    )),
    gaps=(
        gap("DATA", "Conference average is drawn but no cross-programme aggregate is computed."),
    ),
)

signing_day = broadcast(
    id="signingDay", number=29, name="Signing Day", family="recruiting",
    status=Status.PARTIAL, parent="CollegeOffseasonView",
    evidence="Sources/ProFootballCoachUI/CollegeOffseasonView.swift -- no focus parameter",
    body=Hero(
        mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
        headline="Bram Teasdale signs",
        numeral="3",
        points=("Offensive tackle, Blackmere", "Second of the class",
                "Twenty places still open"),
        scale="broadcast",
    ),
    gaps=(
        blocker("SCREEN", "Delegates to CollegeOffseasonView, which takes no focus, so this number renders the offseason hub."),
        blocker("DATA", "Nothing fires signing day, and nothing guarantees nothing fires on a routine week."),
        gap("ART", "The jersey lockup replaces the portrait the product may never draw; no lockup component exists."),
    ),
)

college_offseason = desk(
    id="collegeOffseason", number=61, name="College Offseason", family="recruiting",
    status=Status.BUILT,
    body=Stack((
        Panel("Offseason", Rows((
            Row("Portal", ("14 in",), "Four at positions of need"),
            Row("Retention", ("3 decisions",), "Two seniors, one transfer risk"),
            Row("NIL pool", ("$410,000",), "Unallocated"),
        ), kind="tappable")),
        Chips((Chip("Signing day closed", "positive"), Chip("Spring in 6 weeks", "quiet"))),
    )),
    gaps=(
        blocker("SCREEN", "Four registry numbers alias here and the view takes no focus, so all four are this screen."),
    ),
)

SURFACES = (recruiting_board, prospect_profile, shortlist, contact_visit,
            class_overview, signing_day, college_offseason)
