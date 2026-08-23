"""Personnel -- five canonical surfaces plus the two the squad needs and has never had.

Three of the five carry the fixes named in the plan: position chips come off commit
gold, the dossier drops from four golds to one, and Roster sits at the budget rather
than over it."""

from __future__ import annotations

STAFF_MARK = "TeamLogo_00EBE0C02B2B4988A450BB870D6D3881"

from ._shared import (
    AttributeDial, BandLegend, Chip, Chips, Col, Heat, Hero, NOTHING_MISSING, Panel,
    PlayerCard, Row, Rows, ShareBar, Split, Stack, Status, Table, blocker, desk,
    dossier, gap,
)

roster = desk(
    id="roster", number=16, name="Roster", family="personnel", status=Status.BUILT,
    body=Stack((Table(
        (Col("Player", 18, "left", False), Col("Pos", 4, "left", False), Col("Yr", 3, "left", False),
         Col("Ovr", 4, "right"), Col("Pot", 4, "right"), Col("Snaps", 6, "right"),
         Col("Form", 5, "right"), Col("Status", 9, "left", False)),
        (("Reed Vance", "QB", "Jr", Heat(84, "412 snaps"), "89", "412", "+3", "Fit"),
         ("Amos Kerr", "WR", "Sr", Heat(81, "388 snaps"), "82", "388", "+1", "Doubtful"),
         ("Milo Prasad", "RB", "So", Heat(77, "301 snaps"), "86", "301", "-2", "Fit"),
         ("Teo Marchetti", "OT", "Sr", Heat(79, "419 snaps"), "80", "419", "0", "Limited"),
         ("Ruben Sallow", "LB", "Jr", Heat(78, "no snaps this season"), "84", "0", "0", "Out"),
         ("Dara Whitlock", "CB", "So", Heat(75, "356 snaps"), "87", "356", "+4", "Fit"),
         ("Nico Barrow", "S", "Sr", Heat(80, "402 snaps"), "81", "402", "-1", "Fit"),
         ("Ilya Fenner", "DT", "Jr", Heat(76, "288 snaps"), "83", "288", "+2", "Fit"),
         ("Sable Ruiz", "TE", "Fr", Heat(68, "94 snaps"), "88", "94", "+5", "Fit")),
    ), BandLegend())),
    gaps=(
        gap("INTERACTION", "Sorting and filtering are drawn as column heads but no sort state is modelled."),
        gap("DATA", "Form is a single signed integer; the engine has no rolling window behind it."),
        gap(
            "DATA",
            "Ratings are point values. `04` 6.4 requires a rating the simulation has not "
            "earned to be drawn as a RANGE whose width is the confidence, and Unseen "
            "where nothing has been observed. The scouting-confidence model does not "
            "exist (07 GAP-06), so the gap is declared rather than the precision faked.",
        ),
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
    body=Split(
        top=Hero(
            mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881",
            headline="Amos Kerr",
            numeral="81",
            points=(),
            scale="dossier",
        ),
        bottom=Stack((
            Stack((
                AttributeDial(81, "Overall", 92),
                Stack((
                    ShareBar((86 - 40) / 59, "Hands", "86", "--heat-well-above"),
                    ShareBar((83 - 40) / 59, "Route running", "83", "--heat-above"),
                    ShareBar((78 - 40) / 59, "Separation", "78", "--heat-average"),
                    ShareBar((61 - 40) / 59, "Blocking", "61", "--heat-below"),
                )),
            ), direction="row"),
            BandLegend(),
        )),
    ),
    gaps=(
        gap("ART", "The person plate is blank: no player likeness exists and none is planned."),
        gap("DATA", "Ceiling is drawn as a point, but the model holds a range."),
        blocker(
            "RULE",
            "A Dossier that bands a rating cannot also commit at the install floor: `04` "
            "2.1 gives the head 180-220, 6.4 requires the band table beside the banded "
            "figure, and 4.5a leaves 241 pt once a commit bar is reserved. The three do "
            "not fit together. Drawn without the bar, routing to the committing surface "
            "instead -- an owner question, not a drawing choice.",
        ),
        gap(
            "DATA",
            "Ratings are point values. `04` 6.4 requires a rating the simulation has not "
            "earned to be drawn as a RANGE whose width is the confidence, and Unseen "
            "where nothing has been observed. The scouting-confidence model does not "
            "exist (07 GAP-06), so the gap is declared rather than the precision faked.",
        ),
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
    body=Stack((Panel("Staff", Stack((
        PlayerCard("", "OC", "PERRIN", "ODUYA", "2 YEARS LEFT", 82,
                   (("Development", 84),), mark=STAFF_MARK),
        PlayerCard("", "DC", "HALLE", "BRIGHT", "1 YEAR LEFT", 79,
                   (("Development", 76),), mark=STAFF_MARK),
        PlayerCard("", "RC", "CYRUS", "MBEKI", "3 YEARS LEFT", 85,
                   (("Development", 88),), mark=STAFF_MARK),
    ), direction="row")), BandLegend())),
    gaps=(
        gap("SCREEN", "Staff market and profile is an alias into this list; a coach has no dossier of their own."),
        gap("DATA", "Staff influence on development is not exposed anywhere the player can read it."),
    ),
)

# ---- New: M6, the one the source names for this family ----------------------------

compare = desk(
    id="compare", number=68, name="Compare", family="personnel",
    status=Status.MISSING, evidence="no Swift case; source inventory M6",
    body=Stack((
        Stack((
            PlayerCard("7", "WR", "AMOS", "KERR", "SR · 6'1\" · 197 LB", 81,
                       (("Hands", 86), ("Separation", 78), ("Blocking", 61)),
                       mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881"),
            PlayerCard("18", "TE", "SABLE", "RUIZ", "FR · 6'4\" · 244 LB", 68,
                       (("Hands", 72), ("Separation", 80), ("Blocking", 66)),
                       mark="TeamLogo_00EBE0C02B2B4988A450BB870D6D3881"),
        ), direction="row"),
        BandLegend(),
    )),
    gaps=(
        blocker("SCREEN", "One of Football Manager's core verbs and one of Madden's depth-chart affordances; no registry screen performs it."),
        gap("INTERACTION", "Choosing the second subject has no designed picker."),
        gap(
            "DATA",
            "Ratings are point values. `04` 6.4 requires a rating the simulation has not "
            "earned to be drawn as a RANGE whose width is the confidence, and Unseen "
            "where nothing has been observed. The scouting-confidence model does not "
            "exist (07 GAP-06), so the gap is declared rather than the precision faked.",
        ),
    ),
)

SURFACES = (roster, depth_chart, player_profile, development_plan, staff_room, compare)
