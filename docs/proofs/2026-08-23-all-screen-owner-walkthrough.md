# Owner walkthrough — all-screen migration, manual and device matrix

Date: 2026-08-23
Scope: the manual half of the Task 4 / ID 14 gates. Everything here is an **owner** action.

`CLAUDE.md` section "Process" is explicit: *"Simulator demonstration is an owner action — hand off a
written walkthrough script, never claim it happened."* This document is that hand-off. Nothing in it
has been performed by the agent, and no result below may be filled in by anyone who did not sit in
front of the device.

## What is already proven, and by what

Do not re-do these by hand; they are automated and green.

| Claim | Proof |
|---|---|
| Every control on screens 8-13 meets the 44-point floor, both sizes | `testEveryControlMeetsTheTouchFloorAt{Default,AX5}` |
| 21 UI tests across both content sizes | `xcodebuild test`, two passes, 0 failures |
| Design, core, tactical, screen read-model contracts | `swift run SimTests --<lane>` |
| Match Day draws 22 actors, 11 a side | `testMatchDayExportsDistinctFieldLandmarksAt{Default,AX5}` |
| Every committing action inside the initial viewport | `testWeeklyCommandContentStaysInsideTheViewportAtDefault` |
| Match Day on a real retained game in the production navigator | captured 2026-08-23, see the Task 4 report |
| Personnel destinations 16-20 each render exactly one canonical identity | `testPersonnelFamilyExposesItsCanonicalDestinationsAt{Default,AX5}`, loop over the id range |
| The Coaching HQ to Roster to Player Profile route, at both content sizes | `testCoachingHQRosterPlayerProfileVerticalSlice{,AtAX5}` |

## Setup

Device: an iPhone 15-generation or newer handset, **not** the simulator. `04` section 7 records the
17e landscape insets as unsourced, so a real 17-class device is the one that settles them.

1. Install the branch build.
2. Landscape, both ways up. Portrait is not a supported orientation.
3. Start a new career with seed `424242` so the world matches every capture in the report.

## A. The route that produced the Match Day capture

Reproduces the agent's own path. Expect it to work; the point is to feel it on hardware.

1. Coaching HQ. Resolve the four redshirt decisions: pick a choice, then **Commit decision**.
2. **Delegate balanced preparation**.
3. **Advance** — the gold action, bottom right.
4. Match Day opens on the played week.

Record: does Advance stay disabled until the last obligation clears? Does the receipt sit below the
scorebug rather than across its clock? Is the committing action reachable with the thumb of the hand
holding the device, both ways up?

## B. Assistive technology — one pass per row, on the device

For each, record tester, device, OS, and the result verbatim. A row is not passed by inspection.

| Check | What to look for |
|---|---|
| VoiceOver order on Match Day | world context, then dominant object, then evidence, then actions, then local navigation. The 22 actors each speak side, position, number and yard. |
| VoiceOver on the weekly command screens | the dominant reads before the choices; the committing action names the option it would send |
| Voice Control | every control addressable by its visible label |
| Switch Control | the committing action reachable without passing through the field diagram |
| Reduce Motion | Match Day replaces travel with discrete state changes; no dot animates |
| Reduce Transparency | the floodlit grain overlay drops; no furniture becomes unreadable |
| Increase Contrast | **Expect this to fail — pre-checked.** No source file reads `colorSchemeContrast`, so nothing in the app responds to the setting. Confirm on device, then treat as the canon question below, not a bug to patch on the spot. |
| Differentiate Without Colour | Nothing reads `accessibilityDifferentiateWithoutColor` either. The field may still pass on merit: every actor carries a position label and offense/defense differ by more than hue. Judge whether always-on redundancy satisfies the contract, or whether the setting must be read. |
| ~~Dynamic Type, no control under 44 points~~ | **Now automated** -- `testEveryControlMeetsTheTouchFloorAt{Default,AX5}` walks every button screens 8-13 expose at both sizes. It found and fixed three violations. Check clipped labels by eye; the target floor is covered. |
| Sound and haptics | every cue has a visual and a spoken equivalent |

## C1. A canon question found while automating this matrix

`docs/superpowers/plans/2026-08-22-all-screen-shell-and-hierarchy.md` asks to "Verify Increase
Contrast" and to produce "seven-family 852/956/Increase Contrast proof". `simctl` can set Increase
Contrast, so this row looked automatable -- but a grep of `Sources` finds **no reference to
`colorSchemeContrast`, `accessibilityDifferentiateWithoutColor`, or any contrast-responsive
branch**. Only `accessibilityReduceTransparency` is read, in two places.

So the app does not respond to Increase Contrast at all. That is not a Task 4 regression; it is an
app-wide gap against a stated requirement, and it cannot be closed by an agent, because the
doc-first rule applies: what an increased-contrast Floodlit palette *is* has to be answered in
`04` before it is implemented. Raised here rather than patched.

## C2. The two insets the agent would not decide

Both are recorded in the Task 4 report as open. They need a real device.

1. **Bottom inset.** The build keeps 25 points (home indicator 21 plus 4) where reference 1a draws
   16. Hold the device and try to press the committing action. If 25 is comfortable and 16 would
   collide with the home gesture, the build is right and 1a's 16 is a mock artefact. Record which.
2. **Trailing inset.** Match Day furniture now uses 16 per 1a, while management surfaces keep the
   shared gutter of 20. Check the trailing edge on a 17-class device in both landscape orientations
   and record the measured safe inset, which `04` section 7 currently lists as unsourced.

## D. Rubric

Score the touched surfaces against `docs/04b-AUDIT-RUBRIC.md`: eight dimensions, 0-5 each, the bar
being **at least 31/40 with zero P0 or P1**. Record the score per surface, not one aggregate.

## Recording the result

Append findings to `.superpowers/sdd/all-screen-task-4-report.md` under a new "Owner walkthrough"
heading, with tester, device, OS and date. Until that section exists and every row above carries a
real result, all-screen Task 4 stays `pending` in `.superpowers/sdd/progress.md`.
