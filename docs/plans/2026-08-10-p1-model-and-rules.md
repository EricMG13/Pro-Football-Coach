# P1 — Model and Rules Implementation Plan

**Goal:** the value types every later phase reads, and the two rules modules that own every constant
`02` and `03` name. No engine, no generation, no AI, no view.

**Gates:** G1 build green, G2 tests green, G4 scope.

**Prerequisite done first:** `02` §11 did not exist. P1 needed league structure, scholarship limits,
eligibility clocks, roster sizes, the cap and the draft shape, and canon named none of them. Per the
doc-first amendment rule they were written into `docs/02-GAME-DESIGN.md` §11 before any code.

## Constraints beyond the global ones

- Ratings are 40 to 99 `Int`, enforced by the type rather than by discipline.
- Money is integer dollars. No `Double` anywhere near a contract or a cap.
- No constant inline outside `Rules/`. The contract suite does not yet scan for this; the reviewer
  and the rules-completeness test below are what enforce it.
- Model types are `Codable`, `Equatable`, `Sendable` value types. They carry no behaviour that needs
  an RNG, a calendar or a league lookup — that is the engine's, and putting it here is how a model
  starts simulating.
- `Model/` is the one directory the ambient-identity scan exempts, so `id: UUID = UUID()` as a
  default parameter is legal here and only here.

## Files

| Path | Responsibility |
|---|---|
| `Model/Position.swift` | Positions, units, position groups, decline ages |
| `Model/Rating.swift` | The 40 to 99 clamped `Int`, and the attribute set keyed by attribute |
| `Model/Trait.swift` | Behavioural traits, each with the system it bites in |
| `Model/Scheme.swift` | Offensive and defensive scheme identity, and fit scoring inputs |
| `Model/Player.swift` | The player, both tiers, with the tier-specific parts optional |
| `Model/Eligibility.swift` | The college eligibility clock |
| `Model/Contract.swift` | The pro contract, integer dollars, proration and dead money |
| `Model/Staff.swift` | Coach roles and coach ratings |
| `Model/Programme.swift` | A college programme |
| `Model/ProTeam.swift` | A pro team |
| `Model/League.swift` | Tier, conference, division, league |
| `Rules/SharedRules.swift` | Constants both tiers share |
| `Rules/CollegeRules/CollegeRules.swift` | `02` §11.1 |
| `Rules/ProRules/ProRules.swift` | `02` §11.2 |
| `Tests/SimTests/Suites/ModelTests.swift` | Behaviour: clamping, eligibility, proration, roster legality |
| `Tests/SimTests/Suites/RulesTests.swift` | Every constant `02` §11 names is present and correct |

## Tasks

- [ ] **1. Canon first.** `02` §11 written. *(Done before this plan was saved.)*
- [ ] **2. Rules modules, test first.** `RulesTests` asserts each `02` §11 row by value, and asserts
      the derived season lengths equal the sum of their parts rather than being written twice.
- [ ] **3. Ratings and positions, test first.** Clamping at both ends, at the boundary, and through
      `Codable` — a rating that arrives out of range from a save must clamp, not trap.
- [ ] **4. Player, eligibility, traits, scheme.** Eligibility advance, redshirt spend, exhaustion.
- [ ] **5. Contract.** Proration capped at 5 years, dead money on release, integer-dollar arithmetic
      with no rounding drift.
- [ ] **6. Staff, programme, pro team, league.** Roster-legality predicates only; enforcement is P7
      and P8.
- [ ] **7. Gates and close.** `./scripts/verify.sh`, scope check, adversarial review, `STATUS.md`.

## Explicitly not in P1

Generation of any of these (P2), anything that resolves a snap (P3), scholarship or cap
*enforcement* (P7, P8), the recruiting interest model (P7), job security (P9). P1 gives those phases
types to work on and constants to work from, and nothing else.
