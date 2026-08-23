"""This week -- nine canonical surfaces plus the two Match Day states that were never
drawn. The week is the game's spine: everything here either prepares Saturday or reads
what Saturday did."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Field, Hero, NOTHING_MISSING, OpposedBar, Panel, Lean, Row,
    Meter, Rows, ScoreBug, ShareBar, Split, Stack, StatCompare, Status, Surface,
    Table, blocker, broadcast, desk, gap,
)

coaching_hq = desk(
    id="coachingHQ", number=8, name="Coaching HQ", family="weeklyCommand",
    status=Status.BUILT,
    commit="Advance to Saturday",
    body=Stack((
        Panel("This week", Rows((
            Row("Week 7 at Zumbrota Central", ("Sat 15:30",), "Away, conference"),
            Row("Practice plan", ("Set",), "Emphasis: red zone"),
        ), kind="tappable"), meta="Game plan still a draft"),
    )),
    gaps=(
        gap("INTERACTION", "No move between HQ and any surface is designed; the mock cuts instantly."),
        gap("DATA", "Attention items are hand-listed rather than derived from what the week actually owes."),
    ),
)

inbox = desk(
    id="inbox", number=9, name="Inbox", family="weeklyCommand", status=Status.BUILT,
    body=Stack((
        Panel("Unread", Rows((
            Row("Athletic director", ("Tue",), "Scheduling for next season"),
            Row("Amos Kerr's family", ("Tue",), "Asking about the hamstring"),
            Row("Compliance", ("Mon",), "Contact log for the Pecos visit"),
        ), kind="tappable")),
    )),
    gaps=(
        gap("SCREEN", "A read message has no designed state; only the list is drawn."),
        gap("INTERACTION", "Filing, replying and marking unread are all unmodelled."),
    ),
)

film_room = desk(
    id="opponentReportFilmRoom", number=10, name="Opponent Report / Film Room",
    family="weeklyCommand", status=Status.WRAPPER, parent="OpponentFilmView",
    evidence="Sources/ProFootballCoachUI/OpponentFilmView.swift",
    body=Stack((
        Panel("Zumbrota Central Marsh Lodestars", Table(
            (Col("Tendency", 26, "left", False), Col("Down", 6, "right"),
             Col("Rate", 6, "right"), Col("Yds", 5, "right")),
            (("Play action, first down", "1st", "38%", "8.4"),
             ("Empty backfield", "3rd", "61%", "6.1"),
             ("Blitz off the slot", "3rd", "29%", "3.8")),
        )),
        Panel("Against this opponent", StatCompare("UNI", "ZUM", (
            ("Yards per play", "5.4", "6.8", True),
            ("Third down", "43%", "63%", True),
        ))),
    )),
    gaps=(
        gap("DATA", "Tendencies are static; the engine records no per-opponent play log to derive them from."),
        gap("SCREEN", "No clip or diagram view -- the 'film' in Film Room is a table."),
    ),
)

game_plan = desk(
    id="gamePlan", number=11, name="Game Plan", family="weeklyCommand", status=Status.BUILT,
    commit="Lock game plan",
    body=Stack((
        Rows((
            Row("First down", ("Run lean",), "Sets up the play action they punish"),
        ), kind="tappable"),
        Panel("Personnel groups", Table(
            (Col("Group", 14, "left", False), Col("Snaps", 6, "right"), Col("Yds/play", 9, "right")),
            (("11 personnel", "62%", "5.8"), ("12 personnel", "24%", "4.4")),
        )),
    )),
    gaps=(
        gap("RULE", "Nothing states which read models a locked plan invalidates."),
        gap("SCREEN", "The scheme book this draws from is an alias, so its own editing surface is not drawn."),
    ),
)

practice_plan = desk(
    id="practicePlan", number=12, name="Practice Plan", family="weeklyCommand",
    status=Status.BUILT, commit="Set the week",
    body=Stack((
        Panel("Allocation", Stack((
            ShareBar(0.40, "Red zone", "80 min"),
            ShareBar(0.35, "Situational", "70 min"),
            ShareBar(0.25, "Recovery", "50 min"),
        ))),
        Rows((
            Row("Fatigue", ("+6",), "Above the line; two full-pad sessions"),
        ), kind="readout"),
    )),
    gaps=(
        gap("DATA", "Fatigue and injury risk are printed but the engine exposes no per-block model behind them."),
    ),
)

team_health = desk(
    id="teamHealth", number=13, name="Team Health", family="weeklyCommand", status=Status.BUILT,
    body=Stack((
        Panel("Unavailable", Table(
            (Col("Player", 18, "left", False), Col("Pos", 4, "left", False),
             Col("Status", 10, "left", False), Col("Back", 8, "right")),
            (("Amos Kerr", "WR", "Doubtful", "Week 8"),
             ("Ruben Sallow", "LB", "Out", "Week 10"),
             ("Teo Marchetti", "OT", "Limited", "Week 7")),
        )),
        Panel("Load", Stack((
            Meter(6, 8, "Weeks without a bye", ""),
            ShareBar(4 / 53, "Over 90 percent snaps", "4 players"),
        ))),
    )),
    gaps=(
        gap("DATA", "Return weeks are point estimates; no confidence is modelled or drawn."),
    ),
)

match_day = Surface(
    id="matchDay", number=14, name="Match Day", family="weeklyCommand",
    lean=Lean.MATCH_DAY, status=Status.BUILT,
    body=Stack((
        ScoreBug(
            home="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
            home_abbr="UNI", home_score=17, home_record="7-0 · #9",
            away="TeamLogo_0017F958E7D04FFC9EA801A252B40FD6",
            away_abbr="ZUM", away_score=14, away_record="6-1 · #14",
            clock="Q3 · 6:42", situation="2nd and 7", possession="home",
        ),
        Field(
            home="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
            away="TeamLogo_0017F958E7D04FFC9EA801A252B40FD6",
            spot=34, first_down=41,
            overlays=("11 personnel", "3 timeouts"),
        ),
    )),
    gaps=(
        blocker("DATA", "EventBadge is constructed on no branch, so every fixture paints as a regular-season game."),
        gap("DATA", "The field draws the spot and the line to gain from two integers; no play state feeds them, and there are no players on it."),
        gap("ART", "Occasion branding needs three declared Broadcast variants: regular 44, elimination 48, final 52."),
        gap("SCREEN", "Halftime, end of game and opponent possession are separate surfaces; only live play is drawn."),
    ),
)

aftermath = broadcast(
    id="aftermath", number=15, name="Aftermath", family="weeklyCommand", status=Status.BUILT,
    body=Hero(
        mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
        headline="Union Maritime 24, Zumbrota Central 21",
        numeral="7-0",
        points=("Kerr held for 38 snaps", "Third down 9 of 14"),
        scale="broadcast",
    ),
    gaps=(
        gap("ART", "No competition mark exists, so a conference win and a non-conference win look identical."),
    ),
)

box_score = desk(
    id="gameDetailBoxScore", number=47, name="Game Detail / Box Score",
    family="weeklyCommand", status=Status.BUILT,
    body=Stack((
        Panel("Team stats", StatCompare("UNI", "ZUM", (
            ("Score", "24", "21", True),
            ("Total offense", "283", "246", True),
            ("Rushing yards", "37", "119", True),
            ("Passing yards", "246", "127", True),
            ("First downs", "10", "9", True),
            ("Turnovers", "1", "2", False),
        ))),
    )),
    gaps=(
        gap("SCREEN", "No drive chart; the engine records drive outcomes but nothing draws them."),
    ),
)

# ---- New: M5, the one the source names for this family ----------------------------

while_you_were_away = desk(
    id="whileYouWereAway", number=67, name="While You Were Away",
    family="weeklyCommand", status=Status.MISSING,
    evidence="no Swift case; source inventory M5",
    body=Stack((
        Panel("Handled for you", Rows((
            Row("Recruiting calls", ("9 made",), "Cyrus Mbeki, within your thresholds"),
            Row("Injury report", ("Filed",), "Ines Fallon cleared Marchetti"),
        ), kind="readout")),
        Rows((
            Row("Stopped for you", ("Kerr",), "Re-injury risk crossed your threshold"),
        ), kind="tappable"),
    )),
    gaps=(
        blocker("SCREEN", "Automation halts on a threshold and hands control back; nothing renders what happened in between."),
        blocker("DATA", "No delegation policy exists -- no area enum, no assignment, no persistence -- so every handled line here is unbacked."),
        gap("RULE", "Invisible delegation is indistinguishable from a bug, which is why this surface is not optional."),
    ),
)

SURFACES = (
    coaching_hq, inbox, film_room, game_plan, practice_plan, team_health,
    match_day, aftermath, box_score, while_you_were_away,
)
