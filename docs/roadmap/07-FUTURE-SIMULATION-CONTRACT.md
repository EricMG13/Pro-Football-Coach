# Future Simulation Contract
## Features the current backend cannot yet truthfully support

Nothing in this file is a promise of immediate implementation.
It is a protection against deleting valuable product ideas because the backend is not ready.

| Capability | Current blocker | Why it is worth building | Dependency |
|---|---|---|---|
| Player career memory | no comprehensive historical player event model | creates attachment and legends | event ledger + stats |
| Coaching tree | staff careers/relationships not fully simulated | uniquely strong American-football long-save identity | staff lifecycle |
| Dynamic rival coaches | persistent coach philosophies/careers incomplete | creates recurring antagonists | staff + career |
| Squad planner 2–3 years forward | future departures/portal/draft behavior incomplete | makes roster construction strategic | lifecycle projections |
| Deep opponent data hub | detailed per-player/per-concept stats missing | powers scouting/game-plan loop | stats + match tags |
| Adaptive scouting verdicts | knowledge model and opponent AI incomplete | turns data into uncertain decisions | scouting + AI |
| Recruiting relationship history | recruit/programme event history incomplete | enables grudges and future stories | recruiting + events |
| Recruit revenge storylines | no semantic event linkage across years | free emergent narrative | history |
| Assistant personalities | staff AI tendencies shallow | makes delegation human-readable and consequential | staff AI |
| Full playbook editor | engine concept vocabulary still limited | high ceiling for tactical players | match model |
| Formation/personnel analytics | tracking incomplete | essential football analysis layer | match stats |
| Development plans | practice-development resolution not deep enough | produces long-term player attachment | development |
| Advanced pro negotiation | pro systems not built | differentiates pro tier | contracts/market |
| Agent system | no agent/preferences model | adds negotiation uncertainty | relationships |
| Media ecosystem | no world event synthesis | makes fictional world feel observed | events/history |
| Historical database | current saves not structured around queryable decades | record chasing / immersion | history/index |
| Hall of Fame | no career-evaluation model | long-save aspiration | history |
| Dynamic institution evolution | limited long-run programme state | prevents static world | world evolution |
| Realignment narratives | realignment not yet connected to history/stakes | major world-changing event | competitions/history |
| Advanced analytics hub | metrics not generated | gives expert players endless discovery | stats |
| Rich 2D key-highlight choreography | engine lacks complete spatial anchors | makes match theories visible | match-frame output |
| Modded fictional worlds | no import/schema/security design | extends longevity without real-IP use | future tooling |
| Cloud saves | offline-only architecture | portability for long saves | product-policy change |
| Multiplayer | single-player deterministic design | possible future mode, huge complexity | separate architecture |

### State labels used in design work
- **SUPPORTED** — backend can produce truthful data now.
- **DERIVABLE** — data exists; read model/index required.
- **REQUIRES SIMULATION** — backend lacks the causal system.
- **PRODUCT POLICY CHANGE** — possible technically but contradicts current product constraints.
