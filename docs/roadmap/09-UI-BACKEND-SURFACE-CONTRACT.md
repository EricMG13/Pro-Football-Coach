# UI ↔ Backend Surface Contract

The repository's `docs/04-UX-AND-DESIGN-SYSTEM.md` §8 owns the complete 62-family screen inventory.
The table below is a read-model area summary, not a screen list. A production screen may not be
omitted because its family is compressed into one row here.

The UI also reserves optional person-photo, team-identity and venue-name/media fields for a possible
future custom-universe workflow. Those fields are nullable in the base fictional universe; no import
feature or real-world content is authorised for v1.

| Surface | Required backend read model | Status vs current backend |
|---|---|---|
| Career Start | job openings, programme state, expectations, fit evidence | REQUIRES SIMULATION |
| HQ | week state, pending decisions, stakeholders, health, inbox | REQUIRES SIMULATION |
| Scouting Room | opponent tendencies, knowledge/confidence, matchup projections | REQUIRES SIMULATION |
| Game Plan | scheme, opponent knowledge, tactical keys, practice constraints | REQUIRES SIMULATION |
| Team/Depth | full roster, packages, roles, health, future departures | PARTLY DERIVABLE |
| Player Profile | attributes, traits, role, development, career/recruit history | PARTLY DERIVABLE |
| Recruiting Board | prospects, knowledge, interest, budgets, competitors | REQUIRES SIMULATION |
| Match Center | game record plus spatial frame anchors/call-ins | PARTLY DERIVABLE |
| Career Hub | reputation, job history, events, records, coaching tree | REQUIRES SIMULATION |
| Offseason | phase scheduler, deadlines, unresolved decisions | REQUIRES SIMULATION |
| League | schedule, standings, rankings, stats, history | REQUIRES SIMULATION |
| Search | world index across entities/events/history | REQUIRES SIMULATION |

## Rule

No UI screen should invent a value that the backend cannot truthfully produce.

During prototyping, unsupported values must be visibly mock data and tagged with the intended future read-model field.

---

## Match 2D contract

The 2D view should receive:
- stadium/field geometry
- home/away identity
- current situation
- line of scrimmage
- first-down line
- ball point
- actor points
- actor display token (position ID, number)
- emphasis flags
- route/assignment annotations for key moments
- playback phase
- event commentary
- call-in state

The UI may:
- interpolate positions
- fade/highlight
- animate camera-free zoom within safe bounds
- draw stadium/field

The UI may not:
- choose routes
- alter outcome
- invent missed assignments
- infer causal matchup from animation
