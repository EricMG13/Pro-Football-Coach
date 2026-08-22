"""Career -- nine canonical surfaces plus the five missing screens and three overlays the
source assigns to this family.

Four of the nine are wrappers into `CareerHubView` or `LegacyHistoryView`. Legacy History
is the sharpest case: four concepts in 175 lines with two record kinds supplied, so Record
Book, Rivalries, Career Line and Coaching Tree are one screen.

The overlays carry no `CoachWorldScreenID` at all -- they render over any surface, which is
why the registry never caught their absence. The family assignment below is an artefact of
a registry that only models screens, and each one declares that as a gap."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, Panel, Row, Rows, Split, Stack, Status, Surface, Table,
    blocker, broadcast, desk, dossier, gap,
)
from surface import Lean

LEGACY = "Sources/ProFootballCoachUI/LegacyHistoryView.swift -- 175 lines, four concepts, two record kinds"
OVERLAY_GAP = (
    "Carries no CoachWorldScreenID. The registry enumerates screens by construction and is "
    "airtight for screens; it never modelled a surface that is not one."
)

title_continue = broadcast(
    id="titleContinue", number=1, name="Title / Continue", family="career",
    status=Status.PARTIAL, evidence="no read model; two bare ProgressViews are the only states",
    commit="Continue",
    body=Hero(
        mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
        headline="Union Maritime Meridian",
        numeral="7-0",
        points=("Year three, week 7", "College"),
        scale="broadcast",
    ),
    gaps=(
        blocker("DATA", "No read model backs this surface; what it shows is assembled in the view."),
        gap("SCREEN", "Loading is a bare ProgressView and failure has no state at all."),
    ),
)

settings = desk(
    id="settingsAccessibility", number=6, name="Settings & Accessibility",
    family="career", status=Status.PARTIAL, evidence="no read model",
    body=Panel("Accessibility", Rows((
        Row("Text size", ("System",), "AX5 reflows rather than shrinking"),
        Row("Reduce motion", ("Follow system",), "Entrance and pulse both honour it"),
        Row("Increase contrast", ("Off",), "Hairlines move to the legible value"),
    ), kind="tappable")),
    gaps=(
        blocker("DATA", "No read model; every value here is a view-local default."),
        gap("SCREEN", "Screen 6 covers accessibility only. Appearance -- theme, density, identity display -- is a separate sheet with no surface."),
    ),
)

career_hub = desk(
    id="careerHub", number=52, name="Career Hub", family="career", status=Status.BUILT,
    body=Stack((
        Panel("Opportunities", Rows((
            Row("Oneonta Slate Lamplighters", ("Pro",), "Head coach, contacted"),
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
    evidence="Sources/ProFootballCoachUI/CareerHubView.swift -- switch focus, sixty lines",
    body=Panel("Who is watching", Table(
        (Col("Stakeholder", 18, "left", False), Col("Mood", 10, "left", False),
         Col("Wants", 36, "left", False)),
        (("Athletic director", "Pleased", "A conference title inside five years"),
         ("Boosters", "Warm", "A win over Zumbrota, delivered"),
         ("Faculty", "Neutral", "Academic standing held"),
         ("Players", "Warm", "Snap distribution kept honest")),
    )),
    gaps=(
        blocker("DATA", "Mood is a label with no model; nothing changes it and nothing reads it back."),
        gap("SCREEN", "Sixty lines, and no moment where expectations are actually set."),
    ),
)

promotion = broadcast(
    id="promotionDecision", number=55, name="Promotion Decision", family="career",
    status=Status.WRAPPER, parent="CareerHubView",
    evidence="Sources/ProFootballCoachUI/CareerHubView.swift -- switch focus",
    commit="Accept the pro job",
    body=Hero(
        mark="TeamLogo_0D81D2F903834BD5A74176604D277691",
        headline="Oneonta Slate want you",
        numeral="5",
        points=("Head coach, professional tier", "Five years, full roster authority"),
        scale="broadcast", side="opponent",
    ),
    gaps=(
        blocker("SCREEN", "One of the four ceremony surfaces the source calls unbuilt."),
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
        (Col("Programme", 24, "left", False), Col("W-L", 7, "right"),
         Col("Last", 10, "left", False), Col("Streak", 7, "right")),
        (("Zumbrota Central Marsh", "3-2", "W 24-21", "W2"),
         ("Edgartown Cedar", "2-1", "W 21-17", "W1"),
         ("Pecos Bramble", "1-2", "L 17-28", "L1")),
    )),
    gaps=(
        blocker("DATA", "No rivalry record kind exists; this is derived from the schedule at read time."),
        gap("DATA", "No stored series, so no form and no 'their last five'."),
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
        Row("Perrin Oduya", ("Coordinator",), "Still with us, year 3"),
        Row("Wendell Task", ("Head coach",), "Kirksville State, left year 2"),
    ), kind="readout")),
    gaps=(
        blocker("DATA", "No tree structure is modelled; staff moves are not retained across seasons."),
    ),
)

# ---- The five missing screens the source assigns to career ------------------------

responsibilities = desk(
    id="responsibilities", number=63, name="Responsibilities", family="career",
    status=Status.MISSING, evidence="no Swift case; source inventory M1",
    commit="Set the thresholds",
    body=Panel("Ownership", Table(
        (Col("Area", 20, "left", False), Col("Owner", 16, "left", False),
         Col("Yields", 22, "left", False)),
        (("Recruiting calls", "Cyrus Mbeki", "+2 contacts a week"),
         ("Injury clearance", "Ines Fallon", "One day faster"),
         ("Practice script", "Perrin Oduya", "Costs a red-zone block")),
    )),
    gaps=(
        blocker("DATA", "No area enum, no assignment, no persistence, no surface. Every ownership line drawn in this system is unbacked without it."),
        blocker("RULE", "The interrupt thresholds that end a cruise are undefined, so delegation cannot be handed back."),
        gap("DATA", "Declining a coordinator costs nothing, so the ownership model is theatre."),
    ),
)

season_expectations = dossier(
    id="seasonExpectations", number=65, name="Season Expectations", family="career",
    status=Status.MISSING, evidence="no Swift case; source inventory M3",
    body=Split(
        top=Hero(mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
                 headline="What year three owes", numeral="8",
                 points=("Eight wins, or the board asks why",),
                 scale="dossier"),
        bottom=Table(
            (Col("Constituency", 16, "left", False), Col("Now", 8, "right"),
             Col("At season start", 15, "right")),
            (("Board", "Secure", "Watchful"), ("Boosters", "Warm", "Cool"),
             ("Players", "Warm", "Neutral")),
        ),
    ),
    gaps=(
        blocker("SCREEN", "Set at season start, judged at season end; Stakeholders has no moment where expectations are actually set."),
        blocker("DATA", "No approval rating persists between seasons, and no board request is modelled."),
    ),
)

season_review = broadcast(
    id="seasonReview", number=66, name="Season Review", family="career",
    status=Status.MISSING, evidence="no Swift case; source inventory M4",
    body=Hero(
        mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
        headline="Year three: 11-1, champions",
        numeral="11",
        points=("Best finish since the rebuild", "Reed Vance, player of the year"),
        scale="broadcast",
    ),
    gaps=(
        blocker("SCREEN", "Aftermath is per-match. A season has no ending -- no wrap, no verdict, no record delta."),
        gap("RULE", "For a career game whose whole arc is college to pro, this is the most conspicuous hole in the loop."),
    ),
)

save_continuity = desk(
    id="saveContinuity", number=69, name="Save & Continuity", family="career",
    status=Status.MISSING, evidence="no Swift case; source inventory M7",
    body=Panel("Saves", Table(
        (Col("Save", 20, "left", False), Col("Week", 8, "left", False),
         Col("Build", 10, "left", False), Col("Size", 8, "right")),
        (("Union Maritime, y3", "Week 7", "Current", "2.3 MB"),
         ("Union Maritime, y2", "Week 14", "Older", "2.1 MB")),
    )),
    gaps=(
        blocker("SCREEN", "A Continuity-v3 design sheet exists on the design-references branch with no screen to land on."),
        blocker("RULE", "What happens when a save is from an older build is undefined; GameState.schemaVersion is 13 and migration has no surface."),
    ),
)

appearance = desk(
    id="appearance", number=70, name="Appearance", family="career",
    status=Status.MISSING, evidence="no Swift case; source inventory M8",
    body=Panel("Display", Rows((
        Row("Density", ("Dense",), "Comfortable expands rows to 44"),
        Row("Identity display", ("Mark and name",), "Mark only on narrow surfaces"),
    ), kind="tappable")),
    gaps=(
        blocker("SCREEN", "Appearance-v3 is a separate sheet from Accessibility-v3; nothing owns theme, density and identity display."),
        gap("RULE", "The palette is dark only, so a theme control has nothing to switch between yet."),
    ),
)

# ---- Overlay layers: no screen ID, rendered over any surface ----------------------

teaching = Surface(
    id="teaching", number=72, name="Teaching", family="career",
    lean=Lean.DESK, status=Status.OVERLAY,
    evidence="Teaching-v3.dc.html on the design-references branch; no registry entry",
    body=Panel("Explosive play", Rows((
        Row("Definition", ("16+ yards",), "A run or pass gaining sixteen or more"),
        Row("Yours this season", ("2 per game",), "Conference average is 3.4"),
    ), kind="readout")),
    gaps=(
        blocker("SCREEN", OVERLAY_GAP),
        gap("INTERACTION", "The benchmark is a browsable encyclopedia with its own back and forward navigation and a live panel showing your own instance of the concept."),
    ),
)

failure = Surface(
    id="failure", number=73, name="Failure", family="career",
    lean=Lean.DESK, status=Status.OVERLAY,
    evidence="failure-v3.dc.html is one of the eight canon sheets; no registry screen corresponds",
    body=Panel("Could not advance the week", Rows((
        Row("What happened", ("Save refused",), "The disk is full"),
        Row("What to do", ("Free space",), "Then advance again; nothing was lost"),
    ), kind="readout")),
    gaps=(
        blocker("SCREEN", OVERLAY_GAP + " A whole canon design sheet describes a class of surface the product cannot navigate to."),
        gap("DATA", "The codebase has four failure states in total, and only one of them has a designed equivalent."),
    ),
)

system_state = Surface(
    id="systemState", number=74, name="System State", family="career",
    lean=Lean.DESK, status=Status.OVERLAY,
    evidence="CoachWorldSystemState exists with empty, loading and error kinds; no surface owns them",
    body=Panel("Kinds", Rows((
        Row("Empty", ("Drawn once",), "CollegeOffseasonView.emptyState"),
        Row("Loading", ("Two ProgressViews",), "TitleContinueView, undesigned"),
        Row("Error", ("One string",), "NewCareerSetupView.errorMessage, undesigned"),
    ), kind="readout")),
    gaps=(
        blocker("SCREEN", OVERLAY_GAP),
        blocker("RULE", "No sheet governs when each kind appears, so the component ships with no policy behind it."),
    ),
)

SURFACES = (title_continue, settings, career_hub, stakeholders, promotion,
            record_book, rivalries, career_line, coaching_tree,
            responsibilities, season_expectations, season_review,
            save_continuity, appearance, teaching, failure, system_state)
