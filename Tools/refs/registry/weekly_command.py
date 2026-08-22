"""This week -- nine canonical surfaces plus the two Match Day states that were never
drawn. The week is the game's spine: everything here either prepares Saturday or reads
what Saturday did."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Field, Hero, NOTHING_MISSING, Panel, Register, Row, Rows,
    Split, Stack, Status, Surface, Table, blocker, broadcast, desk, gap,
)

coaching_hq = desk(
    id="coachingHQ", number=8, name="Coaching HQ", family="weeklyCommand",
    status=Status.BUILT,
    commit="Advance to Saturday",
    body=Stack((
        Panel("This week", Rows((
            Row("Week 7 at Zumbrota Central", ("Sat 15:30",), "Away, conference"),
            Row("Practice plan", ("Set",), "Emphasis: red zone"),
            Row("Game plan", ("Draft",), "Two personnel groups short"),
        ), kind="tappable")),
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
            Row("Booster collective", ("Mon",), "NIL pool for the spring"),
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
             ("Outside zone, own half", "1st", "44%", "4.9"),
             ("Empty backfield", "3rd", "61%", "6.1"),
             ("Two-high shell", "2nd", "72%", "5.2"),
             ("Blitz off the slot", "3rd", "29%", "3.8")),
        )),
        Rows((
            Row("Slow safety rotation", ("High",), "Six explosives off it this season"),
            Row("Late motion checks", ("Medium",), "Two sacks conceded"),
        ), kind="readout"),
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
            Row("Third and long", ("Empty",), "Kerr's route tree if he clears"),
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
        Panel("Allocation", Table(
            (Col("Block", 16, "left", False), Col("Mon", 5, "right"), Col("Tue", 5, "right"),
             Col("Wed", 5, "right"), Col("Thu", 5, "right")),
            (("Red zone", "30", "20", "20", "10"),
             ("Situational", "10", "20", "20", "20"),
             ("Recovery", "20", "10", "10", "30")),
        )),
        Rows((
            Row("Fatigue", ("+6",), "Above the line for a road week"),
            Row("Injury risk", ("Low",), "Two full-pad sessions"),
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
        Panel("Load", Rows((
            Row("Squad fatigue", ("Amber",), "Sixth straight week without a bye"),
            Row("Snap concentration", ("High",), "Four players over 90 percent"),
        ), kind="readout")),
    )),
    gaps=(
        gap("DATA", "Return weeks are point estimates; no confidence is modelled or drawn."),
    ),
)

match_day = Surface(
    id="matchDay", number=14, name="Match Day", family="weeklyCommand",
    register=Register.MATCH_DAY, status=Status.BUILT,
    body=Stack((
        Field(
            home="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
            away="TeamLogo_0017F958E7D04FFC9EA801A252B40FD6",
            overlays=("2nd and 7", "Own 34", "11 personnel"),
        ),
        Rows((
            Row("Union Maritime", ("17",), "3 timeouts, ball on the 34"),
            Row("Zumbrota Central", ("14",), "2 timeouts, Q3 6:42"),
        ), kind="readout"),
    )),
    gaps=(
        blocker("DATA", "EventBadge is constructed on no branch, so every fixture paints as a regular-season game."),
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
        points=("Kerr's hamstring held for 38 snaps", "Third down 9 of 14", "Next: home to Pecos, week 8"),
    ),
    gaps=(
        gap("ART", "No competition mark exists, so a conference win and a non-conference win look identical."),
    ),
)

box_score = desk(
    id="gameDetailBoxScore", number=47, name="Game Detail / Box Score",
    family="weeklyCommand", status=Status.BUILT,
    body=Stack((
        Panel("Scoring", Table(
            (Col("Team", 18, "left", False), Col("Q1", 4, "right"), Col("Q2", 4, "right"),
             Col("Q3", 4, "right"), Col("Q4", 4, "right"), Col("T", 4, "right")),
            (("Union Maritime", "7", "3", "7", "7", "24"),
             ("Zumbrota Central", "0", "14", "0", "7", "21")),
        )),
        Panel("Leaders", Table(
            (Col("Player", 18, "left", False), Col("Line", 20, "left", False)),
            (("Reed Vance", "19/28, 246 yds, 2 TD"),
             ("Amos Kerr", "6 rec, 94 yds, 1 TD"),
             ("Milo Prasad", "18 car, 71 yds")),
        )),
    )),
    gaps=(
        gap("SCREEN", "No drive chart; the engine records drive outcomes but nothing draws them."),
    ),
)

# ---- New: the two Match Day states beyond one drive ----------------------------

halftime = desk(
    id="halftimeAdjustments", number=63, name="Halftime Adjustments",
    family="weeklyCommand", status=Status.MISSING,
    evidence="no Swift case; Match Day ends at the end of a drive",
    commit="Send them back out",
    body=Stack((
        Panel("First half", Table(
            (Col("Measure", 20, "left", False), Col("Us", 7, "right"), Col("Them", 7, "right")),
            (("Yards per play", "5.4", "6.8"), ("Third down", "3/7", "5/8"), ("Explosives", "2", "4")),
        )),
        Rows((
            Row("Safety help over Kerr's side", ("Cost: box",)),
            Row("Slow the tempo", ("Cost: drives",), "Keeps their offence off the field"),
        ), kind="tappable"),
    )),
    gaps=(
        blocker("SCREEN", "Halftime does not exist: the match view has no break state between drives."),
        blocker("DATA", "No half-boundary summary is produced by the engine."),
        gap("RULE", "An adjustment's cost is drawn but not defined anywhere in canon."),
    ),
)

end_of_game = broadcast(
    id="endOfGame", number=64, name="End of Game", family="weeklyCommand",
    status=Status.MISSING, evidence="no Swift case; Aftermath is the nearest built surface",
    body=Hero(
        mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
        headline="Final: Union Maritime 24, Zumbrota Central 21",
        numeral="24-21",
        points=("Seventh straight", "Kerr, 94 yards on a hamstring"),
    ),
    gaps=(
        blocker("SCREEN", "The final whistle cuts straight to Aftermath with no held final state."),
        gap("ART", "A final needs the corner marks the v3 set specified; no competition mark exists to draw them from."),
    ),
)

SURFACES = (
    coaching_hq, inbox, film_room, game_plan, practice_plan, team_health,
    match_day, aftermath, box_score, halftime, end_of_game,
)
