# P12 — Entry title and the playable week screens

**Phase:** `05` P12 (Entry, office and the playable week), executed as U-6's first family slice.
**Against:** the eight `*-v3.dc.html` sheets; `04` still owns every value.
**Not this slice:** Job Board / Offer / Appointment (the shipped start still takes the lowest-prestige job; screen 3 replaces that later), Match Day (blocked on G-06/G-11), the other 49 families.

## Why this slice

Coaching HQ, Roster, Player Profile and Recruiting Board already exist and are career-wired.
P12's remaining week families have no production view. Each is a destination in `04` §8, not a
mode of HQ. The design references that govern them are `chrome-v3` (WorldStrip, routes, actions),
`week-v3` (AgendaRow, meters, hub chronology), `readout-v3` (Meter, OpposedBar), `failure-v3`
(empty / error), and `table-v3` (Team Health rows).

## What lands

| Family | File | Dominant object | Engine backing |
|---|---|---|---|
| 1 Title / Continue | `TitleContinueView.swift` | career boundary | save presence, generate/load |
| 9 Inbox | `InboxView.swift` | commitments with cost | mandatory decisions; correspondence empty (no inbox system) |
| 10 Opponent Report / Film Room | `OpponentReportFilmRoomView.swift` | observed tendencies | opponent + `OpponentScoutingSnapshot` rates; no G-02 verdict |
| 11 Game Plan | `GamePlanView.swift` | weekly keys | `TacticalPlan` / `CareerSessionIntent.tacticalPlan` |
| 12 Practice Plan | `PracticePlanView.swift` | 60-minute buckets | `TacticalPracticePlan`; no G-14 day grid |
| 13 Team Health | `TeamHealthView.swift` | availability and injury | `PlayerLifecycleState` |
| 15 Aftermath | `AftermathView.swift` | last result and review | last `ScheduledGame.result` + `TacticalGamePlanReview` |

Shared chrome promoted from three existing production uses: `CoachWorldWorldStrip`,
`CoachWorldOfficeRoutes`, `CoachWorldAgendaRow`, `CoachWorldMeter`, `CoachWorldEmptyState`,
`CoachWorldErrorBanner` in `CoachWorldChrome.swift`. HQ gains the office local-route row so the
new destinations are reachable. Existing HQ/Roster/Recruiting world strips are not rewritten.

## Truth rule

`04` §4.4: a surface without engine backing ships without the claim. `--screen-read-models` pins
every blank (empty correspondence, empty week grid, nil staff verdict on Film). Filling one later
deletes an assertion that names the register item which justifies it.

## Verification

- AX5 contract: each new `*View.swift` declares `dynamicTypeSize.isAccessibilitySize` and
  `accessibilitySortPriority`.
- Symbol register: only §6.6 members.
- Design-token scan: no literal spacing/radius/lineWidth.
- Legal sweep: no real identities in sample copy.
- Full `./scripts/verify.sh` if a toolchain is present; otherwise STATUS records
  **unverified — never compiled**.
