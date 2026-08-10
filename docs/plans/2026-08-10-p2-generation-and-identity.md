# P2 — Generation and Identity Implementation Plan

**Goal:** a seeded generator that builds a whole two-tier league — map, programmes, teams, people,
colours, traditions, rivalries — with D6's endogenous identity, and the two Tier A legal tests as
gates rather than as prose.

**Gates:** G1, G2, G4, **both legal tests**, `IdentityDistributionTests`.

**Canon written first:** `02` §11.3.5 — the ΔE colour space and threshold, the contrast floor, the
retry budget, the sweep size, and what the blocklist does and does not cover. None of it existed.

## The thing this phase is really for

`docs/PORT-LOG.md` records the prior build's `NameBank.swift` as a worked example of the guardrail
failing quietly: a file header asserting "no real player is referenced" above a name cross product
that cannot guarantee it, and a `colleges` array commented "Fictional alma maters" holding six real
institutions. The lesson is written down there and is the design brief here:

- **The collision test enumerates the generated output, not the source arrays.** Reading a list and
  judging it fictional is what produced both failures.
- **Every generated field that reaches a surface is in scope** — including the alma-mater field that
  slipped.
- **A comment asserting compliance is not compliance.** Where the guardrail is claimed in a doc
  comment, the same claim is a named assertion in the legal suite, or the comment comes out.

## Files

| Path | Responsibility |
|---|---|
| `Generation/Blocklist.swift` | The maintained denylist of real names, normalised for comparison |
| `Generation/Colour.swift` | sRGB/Lab conversion, CIE76 ΔE, WCAG contrast ratio |
| `Generation/ColourGenerator.swift` | Seeded pair generation under both constraints, with the bounded retry and fallback |
| `Generation/NameGrammar.swift` | Morpheme-built place, institution, nickname and person names |
| `Generation/Archetype.swift` | The 14 archetypes and their priors |
| `Generation/GameMap.swift` | Regions, cities, coordinates, distance |
| `Generation/TraditionGrammar.swift` | Traditions, each with a mechanical hook |
| `Generation/RivalrySeeder.swift` | Geography-and-conference seeding |
| `Generation/LeagueGenerator.swift` | Assembles the whole thing from one seed |
| `Tests/.../LegalTests.swift` | The two Tier A tests, swept across 200 leagues |
| `Tests/.../GenerationTests.swift` | Determinism, structure, bounds |
| `Tests/.../IdentityDistributionTests.swift` | D6's falsifier |

## Tasks

- [ ] **1. Colour maths, test first.** Lab conversion against known values, ΔE symmetry, contrast
      ratio against the WCAG worked examples.
- [ ] **2. The blocklist**, normalised so "Northwestern" and "north western" collide.
- [ ] **3. Colour generation** under both constraints, with the bounded retry proven to terminate.
- [ ] **4. Name grammar**, built from morphemes rather than from a list of plausible names.
- [ ] **5. Map, archetypes, traditions, rivalries.**
- [ ] **6. The league generator**, and determinism across processes.
- [ ] **7. The legal tests**, swept at 200 leagues, each watched failing against a planted collision.
- [ ] **8. `IdentityDistributionTests`** — D6's falsifier, both limbs.
- [ ] **9. Gates and close.**

## Explicitly not in P2

Anything that resolves a snap (P3), schedules a season (P6), or recruits (P7). Realignment is a
simulated system in `02` §8 and belongs to the phase that has seasons to drive it; P2 generates the
starting map only, and says so in `STATUS.md`.
