"""Career -- nine canonical surfaces plus the two a career needs to end well.

Four of the nine are wrappers into `CareerHubView` or `LegacyHistoryView`. Legacy
History is the sharpest case: four concepts in 175 lines with two record kinds
supplied, so Record Book, Rivalries, Career Line and Coaching Tree are one screen."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, Panel, Row, Rows, Split, Stack, Status, Table,
    blocker, broadcast, desk, dossier, gap,
)

LEGACY = "Sources/ProFootballCoachUI/LegacyHistoryView.swift -- 175 lines, four concepts, two record kinds"

title_continue = desk(
    id="titleContinue", number=1, name="Title / Continue", family="career",
    status=Status.PARTIAL, evidence="no read model; two bare ProgressViews are the only states",
    commit="Continue",
    body=Stack((
        Panel("Saved career", Rows((
            Row("Union Maritime Meridian", ("Week 7",), "Year 3, college"),
        ), kind="tappable")),
        Chips((Chip("7-0", "positive"), Chip("Ranked 9th", "quiet"))),
    )),
    gaps=(
        blocker("DATA", "No read model backs this surface; what it shows is assembled in the view."),
        gap("SCREEN", "Loading is a bare ProgressView and failure has no state at all."),
    ),
)

settings = desk(
    id="settingsAccessibility", number=6, name="Settings & Accessibility",
    family="career", status=Status.PARTIAL, evidence="no read model",
    body=Stack((
        Panel("Accessibility", Rows((
            Row("Text size", ("System",), "AX5 reflows rather than shrinking"),
            Row("Reduce motion", ("Follow system",), "Entrance and pulse both honour it"),
            Row("Increase contrast", ("Off",), "Hairlines move to the legible value"),
        ), kind="tappable")),
        Rows((
            Row("Autosave", ("Every week",), "Last saved Tuesday"),
        ), kind="readout"),
    )),
    gaps=(
        blocker("DATA", "No read model; every value here is a view-local default."),
        gap("SCREEN", "One type scale is drawn across the whole project; AX5 has a single artefact."),
    ),
)

career_hub = desk(
    id="careerHub", number=52, name="Career Hub", family="career", status=Status.BUILT,
    body=Stack((
        Panel("Opportunities", Rows((
            Row("Oneonta Slate Lamplighters", ("Pro",), "Head coach, contacted"),
            Row("Hood River Maritime Iron", ("College",), "Offensive coordinator, declined"),
            Row("Our extension", ("Offered",), "Four years, decide by week 12"),
        ), kind="tappable")),
        Rows((
            Row("Board confidence", ("Secure",), "Seven straight wins, reputation rising"),
        ), kind="readout"),
    )),
    gaps=(
        blocker("SCREEN", "Five registry numbers alias here -- job board, offer, job security, carousel, appointment -- served by one switch."),
    ),
)

stakeholders = desk(
    id="stakeholders", number=54, name="Stakeholders", family="career",
    status=Status.WRAPPER, parent="CareerHubView",
    evidence="Sources/ProFootballCoachUI/CareerHubView.swift -- switch focus",
    body=Panel("Who is watching", Table(
        (Col("Stakeholder", 18, "left", False), Col("Mood", 10, "left", False),
         Col("Wants", 36, "left", False)),
        (("Athletic director", "Pleased", "A conference title inside five years"),
         ("Boosters", "Warm", "A win over Zumbrota, delivered"),
         ("Faculty", "Neutral", "Academic standing held"),
         ("Players", "Warm", "Snap distribution kept honest")),
    )),
    gaps=(
        gap("DATA", "Mood is a label with no model; nothing changes it and nothing reads it back."),
    ),
)

promotion = dossier(
    id="promotionDecision", number=55, name="Promotion Decision", family="career",
    status=Status.WRAPPER, parent="CareerHubView",
    evidence="Sources/ProFootballCoachUI/CareerHubView.swift -- switch focus",
    commit="Accept the pro job",
    body=Split(
        top=Hero(mark="TeamLogo_0D81D2F903834BD5A74176604D277691",
                 headline="Oneonta Slate Lamplighters", numeral="Head coach",
                 points=("Professional tier", "Five years, full authority over the roster")),
        bottom=Panel("What you leave", Rows((
            Row("An unbeaten season", ("Week 7",), "Seven from seven"),
            Row("A signed class", ("2 of 22",), "Twenty places open"),
        ), kind="readout")),
    ),
    gaps=(
        gap("RULE", "The promotion arc is a v1 feature and this is its only surface; what carries across tiers is not stated."),
    ),
)

record_book = desk(
    id="recordBook", number=57, name="Record Book", family="career",
    status=Status.WRAPPER, parent="LegacyHistoryView", evidence=LEGACY,
    body=Panel("Programme records", Table(
        (Col("Record", 21, "left", False), Col("Holder", 18, "left", False),
         Col("Value", 8, "right"), Col("Year", 5, "right")),
        (("Passing yards, season", "Reed Vance", "2,104", "3"),
         ("Receptions, season", "Amos Kerr", "41", "3"),
         ("Wins, season", "This squad", "7", "3")),
    )),
    gaps=(
        blocker("DATA", "LegacyHistoryView supplies two record kinds for four concepts."),
    ),
)

rivalries = desk(
    id="rivalries", number=58, name="Rivalries", family="career",
    status=Status.WRAPPER, parent="LegacyHistoryView", evidence=LEGACY,
    body=Panel("Standing", Table(
        (Col("Programme", 26, "left", False), Col("W-L", 7, "right"),
         Col("Last", 10, "left", False), Col("Streak", 7, "right")),
        (("Zumbrota Central Marsh", "3-2", "W 24-21", "W2"),
         ("Edgartown Cedar", "2-1", "W 21-17", "W1"),
         ("Pecos Bramble", "1-2", "L 17-28", "L1")),
    )),
    gaps=(
        blocker("DATA", "No rivalry record kind exists; this is derived from the schedule at read time."),
    ),
)

career_line = desk(
    id="careerLine", number=59, name="Career Line", family="career",
    status=Status.WRAPPER, parent="LegacyHistoryView", evidence=LEGACY,
    body=Panel("Seasons", Table(
        (Col("Year", 5, "right"), Col("Programme", 23, "left", False),
         Col("Record", 7, "right"), Col("Finish", 20, "left", False)),
        (("1", "Union Maritime Meridian", "4-8", "Sixth in conference"),
         ("2", "Union Maritime Meridian", "8-4", "Third, bowl eligible"),
         ("3", "Union Maritime Meridian", "7-0", "In progress")),
    )),
    gaps=(
        blocker("DATA", "No career record kind; the line is assembled in the view from season state."),
        gap("SCREEN", "There is no line -- the career arc is a table."),
    ),
)

coaching_tree = desk(
    id="coachingTree", number=60, name="Coaching Tree", family="career",
    status=Status.WRAPPER, parent="LegacyHistoryView", evidence=LEGACY,
    body=Panel("Where they went", Rows((
        Row("Perrin Oduya", ("Offensive coordinator",), "Still with us, year 3"),
        Row("Wendell Task", ("Head coach",), "Kirksville State, departed year 2"),
        Row("Halle Bright", ("Defensive coordinator",), "Joined from Pecos, year 3"),
    ), kind="readout")),
    gaps=(
        blocker("DATA", "No tree structure is modelled; staff moves are not retained across seasons."),
    ),
)

# ---- New -----------------------------------------------------------------------

season_review = broadcast(
    id="seasonReview", number=73, name="Season Review", family="career",
    status=Status.MISSING, evidence="no Swift case; a season ends into the offseason hub",
    body=Hero(mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
              headline="Year three: 11-1, conference champions",
              numeral="11-1",
              points=("Best finish since the rebuild", "Reed Vance, player of the year")),
    gaps=(
        blocker("SCREEN", "A season ends by advancing into the offseason with nothing held up to read."),
        gap("ART", "Wants the competition mark it is celebrating; none exists."),
    ),
)

hall_of_honour = desk(
    id="hallOfHonour", number=74, name="Hall of Honour", family="career",
    status=Status.MISSING, evidence="no Swift case; Record Book is the nearest wrapper",
    body=Panel("Inducted", Table(
        (Col("Name", 18, "left", False), Col("Role", 14, "left", False),
         Col("Years", 8, "right"), Col("For", 26, "left", False)),
        (("Reed Vance", "Quarterback", "1-4", "Two conference titles"),
         ("Amos Kerr", "Receiver", "1-3", "Programme receiving record"),
         ("Perrin Oduya", "Coordinator", "1-6", "Six seasons, four rankings")),
    )),
    gaps=(
        blocker("SCREEN", "No surface recognises a career after it ends."),
        blocker("DATA", "Nothing retains a person once they leave the roster or the staff."),
        gap("RULE", "Induction has no criteria in canon; the doc-first rule says that is answered before it is built."),
    ),
)

SURFACES = (title_continue, settings, career_hub, stakeholders, promotion,
            record_book, rivalries, career_line, coaching_tree,
            season_review, hall_of_honour)
