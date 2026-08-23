"""League -- eleven canonical surfaces plus the two the competition needs.

Every surface here that names a competition wants a competition mark, and none exists:
`CompetitionBrandKind` and `CompetitionLogoCatalog` appear in no Swift file on any
branch. Those gaps are the placement spec Stream A's Phase 2 builds against."""

from __future__ import annotations

from ._shared import (
    Bracket, Chip, Chips, Col, FormLine, Hero, Panel, Row, Rows, ShareBar, Split,
    Stack,
    StatCompare, Status, Table, blocker, broadcast, desk, dossier, gap,
)

#: Five conference games played, so a record is a proportion of a stated whole.
CONFERENCE_GAMES = 5


def WINS(won: int, played: int, label: str):
    from primitives import ShareBar

    return ShareBar(won / played, "Conference record", label, inline=True)


def LEAD(share: float, figure: str):
    from primitives import ShareBar

    return ShareBar(share, "Share of the category leader", figure, inline=True)


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
         Col("Record", 12, "right"), Col("Distance", 9, "right")),
        (("Union Maritime Meridian", "New Bedford", WINS(7, 7, "7-0"), "--"),
         ("Zumbrota Central Marsh", "Zumbrota", WINS(6, 7, "6-1"), "410 mi"),
         ("Pecos Bramble", "Pecos", WINS(4, 7, "4-3"), "980 mi"),
         ("Edgartown Cedar", "Edgartown", WINS(3, 7, "3-4"), "60 mi"),
         ("Ephraim Maritime River", "Ephraim", WINS(2, 7, "2-5"), "1,240 mi")),
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
        bottom=StatCompare("UNI", "ZUM", (
            ("Points per game", "28.7", "31.4", True),
            ("Points allowed", "16.4", "18.9", False),
            ("Yards per play", "5.9", "6.1", True),
        )),
    ),
    gaps=(
        gap("ART", MARK_GAP),
    ),
)

standings = desk(
    id="standings", number=43, name="Standings", family="league", status=Status.BUILT,
    body=Panel("Conference", Table(
        (Col("Programme", 23, "left", False), Col("Conf", 11, "right"),
         Col("All", 6, "right"), Col("PF", 5, "right"), Col("PA", 5, "right"),
         Col("Diff", 6, "right"), Col("Strk", 5, "right")),
        (("Union Maritime Meridian", WINS(5, 5, "5-0"), "7-0", "231", "129", "+102", "W7"),
         ("Zumbrota Central Marsh", WINS(4, 5, "4-1"), "6-1", "220", "132", "+88", "W2"),
         ("Pecos Bramble", WINS(3, 5, "3-2"), "4-3", "178", "171", "+7", "L1"),
         ("Edgartown Cedar", WINS(2, 5, "2-3"), "3-4", "159", "188", "-29", "W1"),
         ("Ephraim Maritime River", WINS(1, 5, "1-4"), "2-5", "141", "209", "-68", "L3"),
         ("Kirksville State Cedar", WINS(0, 5, "0-5"), "1-6", "118", "218", "-100", "L6")),
    )),
    gaps=(
        gap("ART", MARK_GAP),
        gap("DATA", "Tiebreakers are computed but the order they were applied in is not shown."),
    ),
)

schedule = desk(
    id="schedule", number=44, name="Schedule", family="league", status=Status.BUILT,
    body=Stack((
        Panel("Played", FormLine((
            ("W", "24-13", "KIR"), ("W", "31-17", "WAT"), ("W", "20-14", "EPH"),
            ("W", "34-10", "KIR"), ("W", "21-17", "EDG"), ("W", "24-21", "ZUM"),
        ))),
        Panel("To come", Table(
            (Col("Wk", 3, "right"), Col("Opponent", 22, "left", False),
             Col("H/A", 4, "left", False), Col("Kickoff", 9, "left", False)),
            (("8", "Pecos Bramble", "H", "Sat 15:30"),
             ("9", "Ephraim Maritime River", "A", "Sat 12:00"),
             ("10", "Weiser Valley Flint", "H", "Sat 19:00")),
        )),
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
            (Col("#", 3, "right"), Col("Programme", 26, "left", False),
             Col("Record", 12, "right")),
            (("1", "Hood River Maritime Iron", WINS(8, 8, "8-0")),
             ("2", "Oneonta Slate Lamplighters", WINS(7, 7, "7-0")),
             ("3", "New London Valley Iron", WINS(7, 8, "7-1")),
             ("4", "Union Maritime Meridian", WINS(7, 7, "7-0"))),
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
    body=Bracket((
        (("1", "HOO", "31"), ("8", "KIR", "17"), ("4", "UNI", "24"), ("5", "WEI", "21"),
         ("2", "ONE", "20"), ("7", "WAT", "27"), ("3", "NEW", "14"), ("6", "CAM", "10")),
        (("1", "HOO", "28"), ("4", "UNI", "31"), ("7", "WAT", "13"), ("3", "NEW", "24")),
        (("4", "UNI", "31"), ("3", "NEW", "24")),
        (("4", "UNI", None),),
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
         Col("Category", 12, "left", False), Col("Share of best", 13, "right")),
        (("Reed Vance", "Union Maritime", "Pass yards", LEAD(1.00, "2,104")),
         ("Ovie Adeyemi", "Zumbrota Central", "Rec yards", LEAD(0.91, "884")),
         ("Milo Prasad", "Union Maritime", "Rush yards", LEAD(0.78, "701")),
         ("Nico Barrow", "Union Maritime", "Tackles", LEAD(0.86, "62")),
         ("Sanjay Rooke", "Pecos Bramble", "Sacks", LEAD(1.00, "9.5"))),
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
