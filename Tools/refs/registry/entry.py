"""Entry -- the surfaces that reach the world before a coaching week exists.

One canonical member. Appointment is an alias into Career Hub, and Title / Continue
sits in Career because that is where `ScreenRegistry.swift` puts it."""

from __future__ import annotations

from ._shared import (
    Chip, Chips, Panel, Row, Rows, Stack, Status, Surface, blocker, desk, gap,
)
from surface import Register

new_career = desk(
    id="newCareerCoachIdentity", number=2, name="New Career & Coach Identity",
    family="entry", status=Status.BUILT, commit="Start the career",
    body=Stack((
        Panel("Coach", Rows((
            Row("Name", ("Aurelia Vance",), "Shown on every surface you own"),
            Row("Background", ("Coordinator",), "Starts with offensive credibility"),
        ), kind="tappable")),
    )),
    gaps=(
        gap("SCREEN", "NewCareerSetupView.errorMessage is one of four failure states in the whole codebase and has no design."),
        gap("INTERACTION", "No move from here into the first Coaching HQ is designed."),
    ),
)

# ---- Overlay layer: no screen ID, rendered over any surface -----------------------

first_run = Surface(
    id="firstRun", number=71, name="First Run", family="entry",
    register=Register.DESK, status=Status.OVERLAY,
    evidence="FirstRun-v3.dc.html on the design-references branch; no registry entry",
    body=Panel("Your first week", Rows((
        Row("What a coach does", ("Prepare, decide",), "You never control a player"),
        Row("Where the week lives", ("Coaching HQ",), "Everything starts there"),
    ), kind="readout")),
    gaps=(
        blocker("SCREEN", "Carries no CoachWorldScreenID. The first hour of a management game is where it is lost, and nothing owns it."),
        gap("INTERACTION", "No move from here into the first Coaching HQ is designed."),
    ),
)

SURFACES = (new_career, first_run)
