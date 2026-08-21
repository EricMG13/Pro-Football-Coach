# Canonical Team-Name Conventions

**Date:** 2026-08-20
**Status:** Approved continuation of the canonical-logo/name plan

## Problem

The generator already uses real U.S. places for college programme names and for pro-team markets, but the two tiers do not have one consistent public-facing convention. A `ProTeam` stores only its market in `name` while a nickname lives beside it, and the college descriptor pool overuses `Institute`/`College`. That makes some surfaces read like a place list rather than American football identities.

Official professional team directories consistently use **location + distinctive nickname** (for example, Arizona Cardinals, Boston Celtics, Seattle Mariners, and Colorado Avalanche). The NCAA directory shows the college tier is institution-shaped and uses a broad mix of University, State, A&M, College, Institute, and technical/polytechnic constructions. The product should borrow those naming shapes, not any protected name, mascot, logo, conference, or trade dress.

## Chosen approach

Use one central, deterministic naming rule with no save-schema change:

1. College programmes keep a real, state-qualified place and draw from a broader generic descriptor pool: `University`, `State University`, `A&M University`, `Technical University`, `Polytechnic University`, `Research University`, `Agricultural Institute`, `Maritime College`, `Technical College`, `Regional College`, `City College`, and existing generic institute forms.
2. Pro teams store the full public name as `place + nickname` at generation time. A computed compatibility display name still combines `cityName + nickname` for older decoded saves whose stored `name` is market-only.
3. Existing stable UUIDs, colours, logo assets, asset names, and persisted field shapes remain unchanged. Only generated string values and display composition change.
4. Bowl titles continue to use the existing generic `place + Classic/Showcase/Championship/Football Classic` helper. No official or near-miss bowl names are added.

This is preferable to a new `displayName` save field: it fixes new worlds, keeps older saves readable, and avoids a migration. It is also preferable to a UI-only patch because engine history/news/rivalry read models must all show the same public name.

## Legal screen

- Real places are location descriptors, not permission to reproduce a real school or club identity.
- The generated full string and its dominant root remain subject to the existing blocklist and 200-world sweep.
- Do not emit NFL/NBA/MLB/NHL/NCAA/CFP/conference names, real school names, official trophy/event/bowl names, or real team nicknames as generated strings.
- The USPTO standard is a comprehensive clearance search: similarity in sound, appearance, meaning, or commercial impression can matter for related goods/services. This code pass is a product screen, not legal clearance.

## Verification

- Generation tests assert every college name begins with its qualified place and ends in an approved descriptor.
- Generation tests assert every generated pro public name contains its market and nickname, and older market-only values render through the compatibility display property.
- Legal tests sweep the combined pro names, college names, conferences, venues, traditions, and bowl titles for blocked strings.
- Manifest review reports the count of location-qualified institutional names and the descriptor distribution; stable IDs/assets are byte-equivalent.
- Existing focused generation, legal, manifest, and asset gates remain required. The full release/XCUITest matrix stays deferred per the owner decision.

## Reference sources

- NFL official teams: https://www.nfl.com/teams/
- NBA official teams: https://www.nba.com/teams
- NCAA official membership directory: https://www.ncaa.org/about-us/membership-directory/
- USPTO trademark definition: https://www.uspto.gov/trademarks/basics/what-trademark
- USPTO likelihood-of-confusion guidance: https://www.uspto.gov/trademarks/search/likelihood-confusion
- Supplied research: `Downloads/Safe Generic Alternative.txt` (research only, not legal advice)
