"""Entry -- the surfaces that reach the world before a coaching week exists.

One canonical member. Appointment is an alias into Career Hub, and Title / Continue
sits in Career because that is where `ScreenRegistry.swift` puts it."""

from __future__ import annotations

from ._shared import Chip, Chips, Panel, Row, Rows, Stack, Status, desk, gap

new_career = desk(
    id="newCareerCoachIdentity", number=2, name="New Career & Coach Identity",
    family="entry", status=Status.BUILT, commit="Start the career",
    body=Stack((
        Panel("Coach", Rows((
            Row("Name", ("Aurelia Vance",), "Shown on every surface you own"),
            Row("Background", ("Coordinator",), "Starts with offensive credibility"),
            Row("Starting tier", ("College",), "Promotion to the pro game is earned"),
        ), kind="tappable")),
        Chips((Chip("Fictional world", "quiet"), Chip("One save", "quiet"))),
    )),
    gaps=(
        gap("SCREEN", "NewCareerSetupView.errorMessage is one of four failure states in the whole codebase and has no design."),
        gap("INTERACTION", "No move from here into the first Coaching HQ is designed."),
    ),
)

SURFACES = (new_career,)
