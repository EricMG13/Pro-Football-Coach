"""Personnel -- five canonical surfaces plus the two the squad needs and has never had.

Three of the five carry the fixes named in the plan: position chips come off commit
gold, the dossier drops from four golds to one, and Roster sits at the budget rather
than over it."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Col, Hero, NOTHING_MISSING, Panel, Row, Rows, Split, Stack,
    Status, Table, blocker, desk, dossier, gap,
)

roster = desk(
    id="roster", number=16, name="Roster", family="personnel", status=Status.BUILT,
    body=Table(
        (Col("Player", 18, "left", False), Col("Pos", 4, "left", False), Col("Yr", 3, "left", False),
         Col("Ovr", 4, "right"), Col("Pot", 4, "right"), Col("Snaps", 6, "right"),
         Col("Form", 5, "right"), Col("Status", 9, "left", False)),
        (("Reed Vance", "QB", "Jr", "84", "89", "412", "+3", "Fit"),
         ("Amos Kerr", "WR", "Sr", "81", "82", "388", "+1", "Doubtful"),
         ("Milo Prasad", "RB", "So", "77", "86", "301", "-2", "Fit"),
         ("Teo Marchetti", "OT", "Sr", "79", "80", "419", "0", "Limited"),
         ("Ruben Sallow", "LB", "Jr", "78", "84", "0", "0", "Out"),
         ("Dara Whitlock", "CB", "So", "75", "87", "356", "+4", "Fit"),
         ("Nico Barrow", "S", "Sr", "80", "81", "402", "-1", "Fit"),
         ("Ilya Fenner", "DT", "Jr", "76", "83", "288", "+2", "Fit"),
         ("Sable Ruiz", "TE", "Fr", "68", "88", "94", "+5", "Fit")),
    ),
    gaps=(
        gap("INTERACTION", "Sorting and filtering are drawn as column heads but no sort state is modelled."),
        gap("DATA", "Form is a single signed integer; the engine has no rolling window behind it."),
    ),
)

depth_chart = desk(
    id="depthChart", number=17, name="Depth Chart", family="personnel", status=Status.BUILT,
    commit="Publish depth chart",
    body=Stack((
        Panel("Offence", Table(
            (Col("Slot", 6, "left", False), Col("First", 16, "left", False),
             Col("Second", 16, "left", False), Col("Drop", 6, "right")),
            (("QB", "Reed Vance", "Kass Oyelaran", "-11"),
             ("RB", "Milo Prasad", "Given Achebe", "-6"),
             ("WR1", "Amos Kerr", "Sable Ruiz", "-13"),
             ("LT", "Teo Marchetti", "Rune Halvorsen", "-8")),
        )),
        # Position chips are quiet, not gold: gold is the committing action and nothing
        # else. Drawing a position in gold was the published set's first rule violation.
        Chips((Chip("QB", "quiet"), Chip("RB", "quiet"), Chip("WR", "quiet"),
               Chip("OL", "quiet"), Chip("DL", "quiet"), Chip("DB", "quiet"))),
    )),
    gaps=(
        gap("DATA", "Drop is the rating gap to the backup; nothing states what an acceptable drop is."),
        gap("SCREEN", "Personnel packages is an alias, so the grouping this chart implies has no surface."),
    ),
)

player_profile = dossier(
    id="playerProfile", number=18, name="Player Profile", family="personnel",
    status=Status.BUILT,
    commit="Open development plan",
    body=Split(
        top=Hero(
            mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
            headline="Amos Kerr",
            numeral="81",
            points=("Senior wide receiver, doubtful",),
            scale="dossier",
        ),
        bottom=Table(
            (Col("Attribute", 14, "left", False), Col("Now", 4, "right"),
             Col("Ceiling", 8, "right"), Col("Season", 19, "left", False)),
            (("Hands", "86", "87", "41 receptions"),
             ("Route running", "83", "85", "612 yards")),
        ),
    ),
    gaps=(
        gap("ART", "The person plate is blank: no player likeness exists and none is planned."),
        gap("DATA", "Ceiling is drawn as a point, but the model holds a range."),
        gap("RULE", "A committing dossier has 241 pt: a 160 pt head, the seam, and 67 pt of evidence -- two rows."),
    ),
)

development_plan = desk(
    id="developmentPlan", number=19, name="Development Plan", family="personnel",
    status=Status.BUILT, commit="Commit the plan",
    body=Stack((
        Panel("Focus", Rows((
            Row("Separation", ("+6 projected",), "Two blocks a week through the bye"),
            Row("Blocking", ("+3 projected",), "Costs a recovery block"),
        ), kind="tappable")),
        Rows((
            Row("Fatigue", ("+4",), "On a squad already amber; no contact work"),
        ), kind="readout"),
    )),
    gaps=(
        gap("SCREEN", "The empty state is the only designed non-happy state in the whole app (CollegeOffseasonView.emptyState)."),
    ),
)

staff_room = desk(
    id="staffRoom", number=20, name="Staff Room", family="personnel", status=Status.BUILT,
    body=Panel("Staff", Table(
        (Col("Name", 18, "left", False), Col("Role", 22, "left", False),
         Col("Rating", 7, "right"), Col("Contract", 9, "left", False)),
        (("Perrin Oduya", "Offensive coordinator", "82", "2 years"),
         ("Halle Bright", "Defensive coordinator", "79", "1 year"),
         ("Cyrus Mbeki", "Recruiting coordinator", "85", "3 years"),
         ("Ines Fallon", "Strength", "74", "Rolling"),
         ("Tobias Renk", "Quarterbacks", "71", "1 year")),
    )),
    gaps=(
        gap("SCREEN", "Staff market and profile is an alias into this list; a coach has no dossier of their own."),
        gap("DATA", "Staff influence on development is not exposed anywhere the player can read it."),
    ),
)

# ---- New: M6, the one the source names for this family ----------------------------

compare = desk(
    id="compare", number=68, name="Compare", family="personnel",
    status=Status.MISSING, evidence="no Swift case; source inventory M6",
    body=Panel("Kerr against Ruiz", Table(
        (Col("Attribute", 14, "left", False), Col("Kerr", 6, "right"),
         Col("Ruiz", 6, "right"), Col("Delta", 6, "right")),
        (("Overall", "81", "68", "-13"), ("Ceiling", "82", "88", "+6"),
         ("Hands", "86", "72", "-14"), ("Separation", "78", "80", "+2"),
         ("Blocking", "61", "66", "+5")),
    )),
    gaps=(
        blocker("SCREEN", "One of Football Manager's core verbs and one of Madden's depth-chart affordances; no registry screen performs it."),
        gap("INTERACTION", "Choosing the second subject has no designed picker."),
        gap("DATA", "Ratings are point values, so a comparison cannot show the confidence either side carries."),
    ),
)

SURFACES = (roster, depth_chart, player_profile, development_plan, staff_room, compare)
