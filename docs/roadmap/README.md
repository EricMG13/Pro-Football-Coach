# Pro Football Coach — Master Build Documentation Pack

This pack was produced from:
- the current repository architecture and status
- the backend-first direction
- the product goal of becoming the “Football Manager of American football”
- the latest UI design pass, including blank face cards and FM-style 2D circle match presentation

## Recommended reading order
1. `00-MASTER-BUILD-BLUEPRINT.md`
2. `01-SYSTEM-DEPENDENCY-MAP.md`
3. `02-DOMAIN-MODEL-AND-DATA-CONTRACTS.md`
4. `03-SIMULATION-BACKEND-PLAN.md`
5. `04-AI-AND-DELEGATION-ARCHITECTURE.md`
6. `05-PERSISTENCE-PERFORMANCE-TESTING.md`
7. `06-BUILD-ROADMAP-AND-GATES.md`
8. `07-FUTURE-SIMULATION-CONTRACT.md`
9. `08-UI-ADVERSARIAL-AUDIT.md`
10. `09-UI-BACKEND-SURFACE-CONTRACT.md`

## Core recommendation
Do not expand UI implementation or bolt new management features directly onto the current model.

First add:
1. root authoritative `GameState`
2. ordered deterministic `WorldScheduler`
3. persistent `DomainEventLedger`
4. read-model / intent boundary

Those four pieces are the structural difference between a collection of football systems and a coherent multi-decade management world.
