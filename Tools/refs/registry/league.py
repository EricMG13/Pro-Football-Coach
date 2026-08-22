"""League -- eleven canonical surfaces plus the two the competition needs.

Every surface here that names a competition wants a competition mark, and none exists:
`CompetitionBrandKind` and `CompetitionLogoCatalog` appear in no Swift file on any
branch. Those gaps are the placement spec Stream A's Phase 2 builds against."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, Panel, Row, Rows, Split, Stack, Status, Table,
    blocker, broadcast, desk, dossier, gap,
)

MARK_GAP = "Wants a competition mark at 24 px beside the title; none exists on any branch."

world_search = desk(
    id="worldSearch", number=7, name="World Search", family="league", status=Status.BUILT,
    body=Stack((
        Panel("Results", Rows((
            Row("Zumbrota Central Marsh Lodestars", ("Programme",), "Conference rival, 6-1"),
            Row("Kalen Ruthers", ("Prospect",), "Quarterback, four stars"),
            Row("Perrin Oduya", ("Staff",), "Our offensive coordinator"),
        ), kind="tappable")),
    )),
    gaps=(
        gap("INTERACTION", "The query field has no designed empty, typing or no-results state."),
    ),
)

league_map = desk(
    id="leagueMap", number=41, name="League Map", family="league", status=Status.BUILT,
    body=Panel("Conference", Table(
        (Col("Programme", 23, "left", False), Col("City", 16, "left", False),
         Col("Record", 7, "right"), Col("Distance", 9, "right")),
        (("Union Maritime Meridian", "New Bedford", "7-0", "--"),
         ("Zumbrota Central Marsh", "Zumbrota", "6-1", "410 mi"),
         ("Pecos Bramble", "Pecos", "4-3", "980 mi"),
         ("Edgartown Cedar", "Edgartown", "3-4", "60 mi"),
         ("Ephraim Maritime River", "Ephraim", "2-5", "1,240 mi")),
    )),
    gaps=(
        gap("SCREEN", "There is no map. Real geography exists in the world model but nothing plots it."),
        gap("ART", MARK_GAP),
    ),
)

team_profile = dossier(
    id="teamProgrammeProfile", number=42, name="Team / Programme Profile",
    family="league", status=Status.BUILT,
    body=Split(
        top=Hero(mark="TeamLogo_0017F958E7D04FFC9EA801A252B40FD6",
                 headline="Zumbrota Central Marsh", numeral="6-1",
                 points=("Zumbrota, second in conference",),
                 scale="dossier", side="opponent"),
        bottom=Table(
            (Col("Measure", 18, "left", False), Col("Value", 8, "right"),
             Col("Rank", 6, "right"), Col("Against us", 20, "left", False)),
            (("Points per game", "31.4", "3", "Last five: 3-2"),
             ("Points allowed", "18.9", "7", "We won the last two"),
             ("Yards per play", "6.1", "2", "Week 7, 24-21")),
        ),
    ),
    gaps=(
        gap("ART", MARK_GAP),
    ),
)

standings = desk(
    id="standings", number=43, name="Standings", family="league", status=Status.BUILT,
    body=Panel("Conference", Table(
        (Col("Programme", 23, "left", False), Col("Conf", 6, "right"), Col("All", 6, "right"),
         Col("PF", 5, "right"), Col("PA", 5, "right"), Col("Diff", 6, "right"), Col("Strk", 5, "right")),
        (("Union Maritime Meridian", "5-0", "7-0", "231", "129", "+102", "W7"),
         ("Zumbrota Central Marsh", "4-1", "6-1", "220", "132", "+88", "W2"),
         ("Pecos Bramble", "3-2", "4-3", "178", "171", "+7", "L1"),
         ("Edgartown Cedar", "2-3", "3-4", "159", "188", "-29", "W1"),
         ("Ephraim Maritime River", "1-4", "2-5", "141", "209", "-68", "L3"),
         ("Kirksville State Cedar", "0-5", "1-6", "118", "218", "-100", "L6")),
    )),
    gaps=(
        gap("ART", MARK_GAP),
        gap("DATA", "Tiebreakers are computed but the order they were applied in is not shown."),
    ),
)

schedule = desk(
    id="schedule", number=44, name="Schedule", family="league", status=Status.BUILT,
    body=Panel("Season", Table(
        (Col("Wk", 3, "right"), Col("Opponent", 22, "left", False),
         Col("H/A", 4, "left", False), Col("Result", 9, "left", False)),
        (("5", "Kirksville State Cedar", "H", "W 34-10"),
         ("6", "Edgartown Cedar", "A", "W 21-17"),
         ("7", "Zumbrota Central Marsh", "A", "W 24-21"),
         ("8", "Pecos Bramble", "H", "Sat 15:30"),
         ("9", "Ephraim Maritime River", "A", "Sat 12:00"),
         ("10", "Weiser Valley Flint", "H", "Sat 19:00")),
    )),
    gaps=(
        gap("ART", MARK_GAP),
    ),
)

rankings = desk(
    id="rankingsPlayoffPicture", number=45, name="Rankings & Playoff Picture",
    family="league", status=Status.WRAPPER, parent="CompetitionOverviewView",
    evidence="Sources/ProFootballCoachUI/CompetitionOverviewView.swift",
    body=Stack((
        Panel("Top eight", Table(
            (Col("#", 3, "right"), Col("Programme", 26, "left", False), Col("Record", 7, "right")),
            (("1", "Hood River Maritime Iron", "8-0"), ("2", "Oneonta Slate Lamplighters", "7-0"),
             ("3", "New London Valley Iron", "7-1"), ("4", "Union Maritime Meridian", "7-0")),
        )),
        Panel("Our position", Rows((
            Row("In the field", ("Yes",), "Fourth seed if the season ended today"),
        ), kind="readout")),
    )),
    gaps=(
        gap("ART", MARK_GAP),
        gap("DATA", "Ranking movement week to week is not retained, so no delta can be drawn."),
    ),
)

bracket = desk(
    id="bracketPostseason", number=46, name="Bracket / Postseason", family="league",
    status=Status.WRAPPER, parent="CompetitionOverviewView",
    evidence="Sources/ProFootballCoachUI/CompetitionOverviewView.swift",
    body=Panel("Quarter-finals", Table(
        (Col("Seed", 5, "right"), Col("Programme", 26, "left", False),
         Col("vs", 4, "center", False), Col("Opponent", 24, "left", False)),
        (("1", "Hood River Maritime Iron", "v", "Kirkwall Reach Iron"),
         ("2", "Oneonta Slate Lamplighters", "v", "Watertown Coastal Marsh"),
         ("3", "New London Valley Iron", "v", "Cambridge A&M Peat"),
         ("4", "Union Maritime Meridian", "v", "Weiser Valley Flint")),
    )),
    gaps=(
        blocker("ART", "A bracket without a competition mark is unbranded; the surface cannot say which competition it is."),
        gap("SCREEN", "No bracket geometry -- the postseason is a table of pairings."),
    ),
)

statistics = desk(
    id="statisticsLeaders", number=48, name="Statistics & Leaders", family="league",
    status=Status.BUILT,
    body=Panel("Conference leaders", Table(
        (Col("Player", 18, "left", False), Col("Programme", 20, "left", False),
         Col("Category", 12, "left", False), Col("Value", 7, "right")),
        (("Reed Vance", "Union Maritime", "Pass yards", "2,104"),
         ("Ovie Adeyemi", "Zumbrota Central", "Rec yards", "884"),
         ("Milo Prasad", "Union Maritime", "Rush yards", "701"),
         ("Nico Barrow", "Union Maritime", "Tackles", "62"),
         ("Sanjay Rooke", "Pecos Bramble", "Sacks", "9.5")),
    )),
    gaps=(
        gap("INTERACTION", "Category is a column, not a control; the player cannot change what is ranked."),
    ),
)

awards = broadcast(
    id="awardsHonours", number=49, name="Awards & Honours", family="league",
    status=Status.BUILT,
    body=Hero(mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
              headline="Reed Vance, Player of the Year",
              numeral="2104",
              points=("Junior quarterback", "First since the rebuild"),
              scale="broadcast"),
    gaps=(
        gap("ART", MARK_GAP),
    ),
)

news = desk(
    id="news", number=50, name="News", family="league", status=Status.PARTIAL,
    evidence="Sources/ProFootballCoachUI/NewsView.swift:124 -- the detail pane is a deliberate dead end",
    body=Panel("This week", Rows((
        Row("Union Maritime hold on the road", ("Week 7",), "Third one-score win in five"),
        Row("Rooke reaches nine and a half", ("Week 7",), "Pecos edge rusher leads the conference"),
        Row("Portal window opens in three weeks", ("Notice",), "Conference-wide"),
    ), kind="tappable")),
    gaps=(
        blocker("SCREEN", "Tapping a story reaches a pane that deliberately shows nothing (NewsView.swift:124)."),
        gap("RULE", "The feed has no stated bound, and unbounded feeds took the prior build's saves to 8.3 MB."),
    ),
)

realignment = broadcast(
    id="realignmentEvent", number=51, name="Realignment Event", family="league",
    status=Status.PARTIAL, evidence="swaps.prefix(2) caps the event at two moves",
    body=Hero(
        mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
        headline="The conference changes shape",
        numeral="2",
        points=("Cambridge A&M Peat Ferrymen join", "Kirksville State leave"),
        scale="broadcast",
    ),
    gaps=(
        blocker("DATA", "Capped at swaps.prefix(2); a realignment larger than two moves cannot be shown."),
        gap("ART", MARK_GAP),
    ),
)

# ---- New: M2, the one the source names for this family ----------------------------

championship = broadcast(
    id="championshipResult", number=64, name="Championship Result", family="league",
    status=Status.MISSING, evidence="no Swift case; source inventory M2",
    body=Hero(
        mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
        headline="Union Maritime, conference champions",
        numeral="31",
        points=("Hood River Maritime beaten 31-24", "First since the rebuild"),
        scale="broadcast",
    ),
    gaps=(
        blocker("SCREEN", "The fifth sanctioned ceremony has no registry case at all."),
        blocker("ART", "The surface exists to show a competition, and no competition mark exists on any branch."),
        gap("DATA", "EventBadge is constructed nowhere, so a final cannot be distinguished from week 3."),
    ),
)

SURFACES = (world_search, league_map, team_profile, standings, schedule, rankings,
            bracket, statistics, awards, news, realignment, championship)
