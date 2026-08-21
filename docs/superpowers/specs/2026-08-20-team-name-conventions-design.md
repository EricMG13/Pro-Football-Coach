# Canonical Team-Name Conventions

**Amended 2026-08-21.** Two changes, both after the owner read the generated set back.

1. **Every member shows a nickname.** `Programme` carried one from the beginning and never
   displayed it, so 134 of the 166 public names were a school directory entry with no team in them.
   The public name is now `place + short qualifier + nickname` for a programme and
   `place + nickname` for a club.
2. **The public name drops the state abbreviation and the registrar's head noun.** No league writes
   a state into a team name, and a programme is called "Kent State", not "Kent State University".
   `cityName` stays state-qualified because the map needs it to tell same-named towns apart; only
   the public name is shortened. The descriptor pool is now the short forms a scoreboard carries:
   `State`, `A&M`, `Tech`, `Poly`, `Valley`, `Coastal`, `Maritime`, `Agricultural`, `Regional`,
   `Central`, and one case in four takes none at all.

The nickname pools grew from 18 x 22 to 32 x 40 in the same pass, because a nickname that had been
visible on 32 members was suddenly visible on all 166 and 396 pairs was not enough to go round.

**Two properties this rests on, and how each is held.** Draw counts are unchanged: the four-way
branch and the single pick are both still there, `pick` costs one draw whatever the pool size, and
the stable IDs were compared before and after -- all 166 identical, so the logo catalogue did not
de-key. And the whole cross product of 570 places, 11 school forms, 32 adjectives and 40 nouns --
**8,025,600 public names** -- was swept against `Blocklist` before the vocabulary landed, with no
collisions; the 200-world legal sweep is green on top of that.

`institutionName` and `nickname` now step to the next pool entry rather than redrawing when a
pairing is blocked. Nothing collides today, but the blocklist is refreshed per release, and without
the step a new entry would quietly move the random stream and generate a different world.

**Still a product screen, not clearance.** Two real programmes -- Akron and Butler -- appear in the
place list and are absent from `Blocklist.institutions`. That predates this change and is unaffected
by it, since a single-word entry blocks the same either way, but the list refresh should pick them
up, and the step above is what makes adding them safe.


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
