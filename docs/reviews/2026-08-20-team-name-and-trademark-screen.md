# Team name and trademark screen

Date: 2026-08-20  
Scope: 166 generated team names in `Tools/TeamLogos/manifest.json`
Purpose: product naming coherence and pre-clearance risk screen before public or merchandise use.

## Executive result

The canonical set now uses real U.S. city/town names qualified by state abbreviation, combined with generic institution or club descriptors. Stable UUIDs and approved logo assets are unchanged. No current full team name is an exact match for a current NFL, NBA, MLB, NHL, or MLS club name in the official league reference lists below. This is not a trademark clearance opinion.

The place pool is 570 incorporated U.S. cities and towns from the 2024 U.S. Census Gazetteer, rendered as `City, ST`. College-style names use generic descriptors such as `Technical Institute`, `Regional College`, or `Maritime Institute`; pro-style names keep the place and a generic plural nickname. The blocklist and generated-world sweep still screen exact and component collisions.

## Naming pattern reference

Official professional lists consistently use a location plus a distinctive club name: `Arizona Cardinals`, `New York Giants`, and `Kansas City Chiefs` in the NFL; `Boston Celtics`, `Denver Nuggets`, and `San Antonio Spurs` in the NBA; `Atlanta Braves`, `Seattle Mariners`, and `Texas Rangers` in MLB; and `Carolina Hurricanes`, `Colorado Avalanche`, and `Seattle Kraken` in the NHL. MLS also mixes location plus nickname with institutional-style constructions such as `Atlanta United`, `Austin FC`, and `New York City Football Club`.

Official sources:

- NFL teams: https://www.nfl.com/teams/
- NBA teams: https://www.nba.com/teams
- MLB teams: https://www.mlb.com/team
- NHL teams: https://www.nhl.com/info/teams/
- MLS clubs: https://www.mlssoccer.com/clubs/
- NCAA member-school directory: https://www.ncaa.org/about-us/membership-directory/

Recommended product rule: choose one presentation per team—college-style `[real place, ST] [generic institute/college descriptor]` or pro-style `[real place, ST] [distinctive plural nickname]`. A real place is not a real school identity; the combined name, colors, logo, roster, and presentation still require clearance.

## Bowl-game naming

The attached `Safe Generic Alternative.txt` is useful research, not legal authority. Its generic replacements are applied as a narrow rule: a projected bowl badge may use the host place plus `Classic`, `Showcase`, `Championship`, or `Football Classic`. The generator must not use `Rose Bowl`, `Sugar Bowl`, `Fiesta Bowl`, `Orange Bowl`, or near-miss substitutes intended to evoke them. The engine currently persists postseason stage rather than a bowl-title field; `NameGrammar.bowlName(place:using:)` is the single safe title helper for a future read-model badge, so no save schema changed.

## Risk tiers

### Medium-high: rename before merchandise clearance

The `Harrow` root is also used by an active sports-equipment, apparel, and custom-uniform business. Rename the five Harrow-root names to `Harlowe` before external merchandise use, preserving the `HAR` abbreviation and stable UUIDs:

- Harrow Springs West → Harlowe Springs West
- Harrow Bluff Thunder Otters → Harlowe Bluff Thunder Otters
- Central Harrow Gate → Central Harlowe Gate
- Harrow Harbor West → Harlowe Harbor West
- Harrow Basin Kindled Ironsides → Harlowe Basin Kindled Ironsides

Reference: https://www.harrowsports.com/

### Medium: scoped clearance or optional root rename

- `Jessup` appears in the current NCAA directory as Jessup University and has an active Warriors athletics program. Consider `Jespin` if the game will ship with merchandise or external marketing. Keep stable `JES` IDs if changed.
- `Kestrel` is a common bird term and an active bicycle/sports brand. The fictional place-root use is likely more differentiated, but search `Kestrel` and phonetic variants before merchandise. Optional neutral root: `Kestren`.
- `Fairbank` is one letter from Fairbanks, including the University of Alaska Fairbanks/Nanooks context. Keep for game-only use; consider `Farrenbank` for merchandise.

### Medium-low / low: retain, but search if shortened

`Dunmore` and `Larkin` have active school athletics references, but the full fictional names are not current pro/college team matches. `Thunder` appears in Oklahoma City Thunder, but the full compound names here create a different commercial impression. `Wexford` and `Kirkwall` are geographic names outside the U.S. sample; search relevant countries before international release. `Lamphier` is the only unanchored one-word name; use `Lamphier Institute` or `Lamphier Landing [nickname]` if it needs a clearer identity.

## Legal requirements and limits

USPTO guidance treats a trademark as a word, phrase, symbol, design, or combination identifying the source of goods/services. Rights can arise through use even without federal registration, while registration provides broader nationwide protection: https://www.uspto.gov/trademarks/basics/what-trademark

Before any public launch, filing, licensing, or merchandise sale, run a comprehensive clearance search—not only exact strings—in the USPTO database, state databases, internet/common-law sources, and relevant international databases. Search the full name, each dominant root, phonetic/spelling variants, and the logo/design. USPTO explains that confusion can arise from similarity in sound, appearance, meaning, or commercial impression when goods/services are related: https://www.uspto.gov/trademarks/search/federal-trademark-searching and https://www.uspto.gov/trademarks/search/likelihood-confusion

This screen is not legal advice or a finding of availability. A trademark attorney should make the final jurisdiction-specific clearance decision before filing or selling.

Place-source reference: U.S. Census 2024 Gazetteer Files, National Places, https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.2024.html

## Current action

Keep the stable UUIDs and generated logo assets. Review the real-place display names for local/common-law conflicts before public release or merchandise. Apply the same place-plus-generic rule to any future bowl badge; do not add official or near-miss legacy bowl names.
