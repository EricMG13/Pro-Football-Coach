"""Recruiting -- seven canonical surfaces plus two the class needs.

Four registry numbers in this family are aliases into College Offseason: Portal Hub,
Retention Decisions, Portal Market and NIL Allocation all route there, and
`CollegeOffseasonView` has no focus parameter, so all four render the same screen."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, Panel, Row, Rows, Split, Stack, Status, Table,
    blocker, desk, dossier, gap,
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
        top=Hero(mark=None, headline="Kalen Ruthers", numeral="4 stars",
                 points=("Quarterback, Pecos", "90 miles, high interest")),
        bottom=Panel("Fit", Table(
            (Col("Measure", 17, "left", False), Col("Value", 8, "right"),
             Col("Note", 22, "left", False)),
            (("Scheme fit", "88", "Fits the empty package"),
             ("Academic", "Clear", "No qualifying risk"),
             ("Projected ceiling", "86", "Three programmes in")),
        )),
    ),
    gaps=(
        gap("ART", "Blank photo plate; prospects have no likeness and will not get one."),
        gap("DATA", "Rival interest is a count, not a named set, so the pressure is unreadable."),
    ),
)

shortlist = desk(
    id="shortlist", number=26, name="Shortlist", family="recruiting", status=Status.BUILT,
    body=Panel("Shortlisted", Rows((
        Row("Kalen Ruthers", ("QB", "4"), "Visit booked for week 9"),
        Row("Bram Teasdale", ("OT", "3"), "Committed, hold the place"),
        Row("Wren Kovalik", ("LB", "3"), "Wants a defensive coordinator meeting"),
        Row("Emory Salk", ("CB", "3"), "Waiting on a second offer"),
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
             ("Ovie Adeyemi", "Call", "1", "Any"),
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

signing_day = desk(
    id="signingDay", number=29, name="Signing Day", family="recruiting",
    status=Status.PARTIAL, parent="CollegeOffseasonView",
    evidence="Sources/ProFootballCoachUI/CollegeOffseasonView.swift -- no focus parameter",
    commit="Close the class",
    body=Panel("Today", Rows((
        Row("Bram Teasdale", ("Signed",), "09:12"),
        Row("Isolde Grange", ("Signed",), "10:40"),
        Row("Kalen Ruthers", ("Deciding",), "Announces at 14:00"),
        Row("Wren Kovalik", ("Lost",), "Signed elsewhere"),
    ), kind="readout")),
    gaps=(
        blocker("SCREEN", "Delegates to CollegeOffseasonView, which takes no focus, so this number renders the offseason hub."),
        gap("INTERACTION", "No live arrival of a decision; the list is static."),
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

# ---- New -----------------------------------------------------------------------

recruiting_pitch = desk(
    id="recruitingPitch", number=71, name="Recruiting Pitch", family="recruiting",
    status=Status.MISSING, evidence="no Swift case; contact actions have no content",
    commit="Make the pitch",
    body=Stack((
        Panel("What Ruthers cares about", Table(
            (Col("Motive", 18, "left", False), Col("Weight", 7, "right"), Col("Our standing", 24, "left", False)),
            (("Early playing time", "High", "One senior ahead"),
             ("Distance from home", "High", "90 miles, strong"),
             ("Development record", "Medium", "Two quarterbacks drafted")),
        )),
        Rows((
            Row("Lead with playing time", ("Fit: high",)),
            Row("Lead with development", ("Fit: medium",), "Safer, slower"),
        ), kind="tappable"),
    )),
    gaps=(
        blocker("SCREEN", "Contact actions exist as a cost with no content; nothing is said to a prospect."),
        blocker("DATA", "Prospect motives are not modelled at all."),
        gap("RULE", "A promise made in a pitch has no representation and cannot be broken or kept."),
    ),
)

commitment_feed = desk(
    id="commitmentFeed", number=72, name="Commitment Feed", family="recruiting",
    status=Status.MISSING, evidence="no Swift case; commitments appear only as a status column",
    body=Panel("Across the conference", Rows((
        Row("Zumbrota Central", ("4 stars", "QB"), "Flipped from a rival, week 7"),
        Row("Pecos Bramble", ("3 stars", "OT"), "Local commitment"),
        Row("Union Maritime", ("2 stars", "K"), "Isolde Grange"),
        Row("Edgartown Cedar", ("4 stars", "DT"), "Sanjay Rooke, whom we wanted"),
    ), kind="readout")),
    gaps=(
        blocker("SCREEN", "Rival recruiting is invisible; a class is lost with no notice."),
        gap("ART", "Each row wants the rival's mark, which resolves, and its conference mark, which does not exist."),
    ),
)

SURFACES = (recruiting_board, prospect_profile, shortlist, contact_visit,
            class_overview, signing_day, college_offseason,
            recruiting_pitch, commitment_feed)
