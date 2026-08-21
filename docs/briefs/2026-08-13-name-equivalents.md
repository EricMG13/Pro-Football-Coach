# Close-but-protected name equivalents

Written 2026-08-13, in answer to an IP note offered to this project and to the instruction to
"construct a list of close but legally protected equivalents for the game".

**Status.** A working brief, not canon. `docs/DOC-MANIFEST.md` §4 lists what carries authority and
`docs/briefs/` is not on it. The doctrine this brief argues for landed in canon at
`docs/02-GAME-DESIGN.md` §11.3.5; the list itself landed in
`Sources/FootballSimCore/Generation/Blocklist.swift`, where tests can read it. This file is the
reasoning and the provenance behind both.

**Not legal advice, and the brief it reviews says the same.** Everything here is a denylist
proposal for the owner and for counsel. Registration status is asserted from general knowledge and
has not been checked against USPTO records by anyone; the entries whose basis is weaker than that
are labelled below.

---

## 1. Review of the suggestion

### What holds, and is already how this project works

- **Geography is public domain, team marks are not.** This matches the owner decision of
  2026-08-12 already recorded in `CLAUDE.md`: real cities and regions are permitted, generator
  included, and `Blocklist.blocksPlaceName` is the check a caller uses for a place. The suggestion
  and canon agree.
- **Trade dress is real and extends to colour combinations.** Also already canon:
  `02` §11.3.5 fixes CIE76 ΔE 25 on *both* members of a pair, checked in both orientations, and
  `LegalTests` asserts it over 200 generated leagues.
- **"Generic + real city + exact brand colours" can still identify a real programme.** Correct, and
  it is the one limb of the guardrail that is not a test. `CLAUDE.md` and `02` §11.3.5 both record
  it as a review obligation and a counsel question. Nothing in this change alters that.

### What is wrong, and is the reason this brief exists

**The "Safe Alternative" column is the failure mode, not the mitigation.** All four of its
suggestions are the mark itself or one word away from it:

| Proposed as safe | What it actually is |
|---|---|
| "Southeastern Conference" for SEC | The SEC's own registered name. Already on this project's blocklist as a real name before the suggestion was made. |
| "Atlantic Coast" for ACC | The ACC's name with "Conference" removed. Also already on the blocklist. |
| "National Collegiate Association" for NCAA | The NCAA's name with "Athletic" removed. |
| "National Pro Football" for NFL | The NFL's name reordered. |
| "American Conference" for AFC | The ordinary short form *of* the American Football Conference. |

Two of the four were already refused by this repository as real names at the moment they were
offered as alternatives to themselves. That is the sharpest available evidence for the rule this
brief proposes: **the dangerous name is not the one nobody would reach for, it is the one a careful
person reaches for while trying to be safe.**

**Part B — community mods, real-name packs, "safe harbor" — is out of scope by standing rule and
overstates the protection.** `CLAUDE.md` is explicit: "Any route around it — bundled 'community'
real-name files, a roster importer pointed at a scraped source, a wink in the store listing — is out
of scope and must not be proposed." `02` §12 lists custom universe import/export as not in v1 and
escalated to counsel (`01-RESEARCH.md` §6.2B §3.2), and the checklist carries it as an open counsel
item. Separately, the legal claim is weaker than stated: hosting safe harbours protect a service
provider from what users upload, and they do not obviously reach a developer who designs, documents
and markets an import path whose evident purpose is loading infringing packs. That is a contributory
and inducement question, not a hosting one. It is not a route this project may take, and it should
not be relied on as a description of the risk either.

**"Generic animal and job names are fine" is true and beside the point here.** No single school owns
"Tigers". This repository blocks them anyway, for the reason its own source states: the generator
has no need of any of them, so a denylist that errs generous costs a few nouns. The place that
argument fails is when the generous entry is a word the generator is *already using* — see §2.9.

### What it misses

Six categories, all of them names a designer would plausibly reach for:

1. Acronym and numeral forms of marks whose spelled form is already blocked.
2. Conference names outside the top division — the slice the blocklist was built from.
3. Rivalry-trophy marks, which are exactly the shape this game's tradition grammar emits.
4. Bowl-game marks that read as ordinary nouns.
5. Award marks and their namesakes.
6. Competitor product marks, which reach a player through shipped copy and a store listing rather
   than through the generator.

And one it could not have known: **seven real college nicknames were live in this project's own
generator pools** while both legal tests were green.

---

## 2. The list

Grouped by why each entry is *close*. Every entry below is now in `Blocklist.swift`. The list grew
from 274 entries to 482.

### 2.1 Leagues and governing bodies, with the near-miss coinages beside them

National Football League, National Football Conference, American Football Conference, American
Conference, National Conference, American Football League, All-America Football Conference, United
States Football League, United Football League, Arena Football League, Canadian Football League,
National Collegiate Athletic Association, Collegiate Athletic Association, National Collegiate
Association, National Pro Football, Pro Football Hall of Fame, NFL, NFC, AFC, NCAA, USFL, XFL, CFL,
NAIA, NJCAA.

Three of these — "Collegiate Athletic Association", "National Collegiate Association", "National
Pro Football" — are **not registrations**. They are refused as near-misses, which is a different
claim and is stated as such in the source.

### 2.2 College postseason and governance

College Football Playoff, Bowl Championship Series, Football Bowl Subdivision, Football
Championship Subdivision, New Year's Six, National Signing Day, National Letter of Intent,
Collegiate Licensing Company, Learfield, CFP, BCS, FBS, FCS, Scouting Combine, Hall of Fame Game.

Note the deliberate lengths. "National Signing Day" is blocked and "Signing Day" is not, because
`ScreenRegistry` already ships a screen called Signing Day. "Scouting Combine" is blocked and
"Combine" is not.

### 2.3 Conference marks in the forms the marks are actually written in

Big 12, Big XII, Big 10, B1G, Pac-12, Pac 12, Pac-10, Pac Ten, Pacific 12, Pacific Twelve, Atlantic
10, Atlantic Ten, Empire 8, Empire Eight, SEC, ACC, AAC, MAC, MWC, CUSA, WAC.

The list already held "Big Twelve", "Big Ten" and "Pac-Twelve". `Blocklist.normalised` keeps digits,
so those entries said nothing at all about the numeral forms the conferences themselves use. A test
now derives one form from the other across the whole list.

### 2.4 Conference names outside the top division

Southern Conference, Frontier Conference, Summit League, Horizon League, Patriot League, Colonial
Athletic, Coastal Athletic, Missouri Valley, Ohio Valley, Northeast Conference, Metro Atlantic,
Western Athletic, America East, Big West, Big South, Great Lakes Valley, Great Lakes
Intercollegiate, Gulf South, Lone Star, Peach Belt, Sunshine State Conference, Mountain East,
Northern Sun, Sooner Athletic, Great Plains Athletic, California Collegiate Athletic, Midwest
Conference, Central Intercollegiate Athletic, Southern Intercollegiate Athletic, Southwestern
Athletic, Mid-Eastern Athletic, Pennsylvania State Athletic, Old Dominion Athletic, Centennial
Conference, Liberty League, Landmark Conference, Skyline Conference, American Rivers, College
Conference of Illinois, Prairie College Conference, Heartland Conference.

**The two that matter most are the first two.** `NameGrammar` records removing "Southern" and
"Frontier" from the region pool because crossed with "Conference" they spell two real bodies, and
the generator had produced them 63 and 58 times across a 200-league sweep. The fix was the pool
edit alone — neither name was ever added to the blocklist — so the gate that missed them still
could not see them. A pool word removed protects today's pool. A blocklist entry protects every
pool after it.

### 2.5 Bowl-game marks that read as ordinary nouns

Gator Bowl, Citrus Bowl, Sun Bowl, Alamo Bowl, Holiday Bowl, Liberty Bowl, Outback Bowl, ReliaQuest
Bowl, Music City Bowl, Independence Bowl, Las Vegas Bowl, Cactus Bowl, Pinstripe Bowl, Fenway Bowl,
Armed Forces Bowl, Gasparilla Bowl, Birmingham Bowl, Texas Bowl, First Responder Bowl, Guaranteed
Rate Bowl, Super Bowl, Pro Bowl, Senior Bowl, Shrine Bowl, East-West Shrine, Hula Bowl.

These go in the venue limb, which means they are swept against generated **place** names too. That
is correct rather than incidental: a bowl's name is routinely also a building's, which is why the
list already held Rose Bowl and Cotton Bowl, and `NameGrammar.venueWords` contains "Bowl" so
`<Place> Bowl` is a shape every save produces.

### 2.6 Rivalry and trophy marks

Iron Bowl, Egg Bowl, Apple Cup, Red River, Holy War, Backyard Brawl, Territorial Cup, Little Brown
Jug, Old Oaken Bucket, Victory Bell, Golden Egg, Golden Hat, Iron Skillet, Jeweled Shillelagh, Paul
Bunyan's Axe, Floyd of Rosedale, Commander-in-Chief's Trophy, Land Grant Trophy, Bayou Bucket,
Governor's Cup, Keg of Nails, Illibuck, Megaphone Trophy, Sweet Sioux, Platypus Trophy, Milk Can.

**This is the category with the worst prior coverage: none.** `TraditionGrammar` emits
`<rivalry adjective> <trophy noun>` from the pools `Iron, Bitter, Old, Border, Founders, Quarry` and
`Trophy, Cup, Bell, Axe, Spade, Chain, Keystone`. Those names are swept as institution-kind names,
against a blocklist that contained no trophy at all — so that limb of the sweep could not have
failed. "Victory Bell" is one pool word away from reachable; "Iron Bowl" is one venue word away.

### 2.7 Broadcast marks

College GameDay, Monday Night Football, Sunday Night Football, Thursday Night Football, Big Noon
Kickoff, Hard Knocks, Sunday Ticket, ESPN.

"NFL RedZone" is deliberately absent, and §3 explains why.

### 2.8 Award marks and their namesakes

Marks: Heisman, Maxwell Award, Bednarik Award, Butkus Award, Outland Trophy, Thorpe Award,
Biletnikoff, Rimington Trophy, Mackey Award, Ray Guy Award, Wuerffel Trophy, Broyles Award, Lombardi
Trophy.

People: John Heisman, Walter Camp, Amos Alonzo Stagg, Chuck Bednarik, Dick Butkus, Bronko Nagurski,
Doak Walker, Davey O'Brien, Lou Groza, Ray Guy.

A trophy named for a person is two marks at once. The namesakes go in the people limb because that
limb also sweeps generated place names, so a generated city called Bednarik is refused.

### 2.9 Real nicknames that were live in our own generator pools

This is the finding, rather than a list of things to avoid one day.

| Word | Real programme | Division | Pool it sat in |
|---|---|---|---|
| Beacons | Valparaiso | **I** | `nicknameNouns` |
| Marauders | Mary | II | `nicknameNouns` |
| Otters | Cal State Monterey Bay | II | `nicknameNouns` |
| Foresters | Lake Forest | III | `nicknameNouns` |
| Herons | William Smith | III | `nicknameNouns` |
| Drovers | Science and Arts of Oklahoma | NAIA | `nicknameNouns` |
| Harriers | Miami Hamilton | USCAA | `nicknameNouns` |
| Storm | Simpson (football), Lake Erie | III, II | `nicknameAdjectives` |

Every one of them was being emitted, and both legal tests were green, because the nickname limb was
an FBS-and-NFL slice and none of these schools is in that slice. It is the same shape as "Crimson",
which the repository caught only because Harvard happened to be listed, and as the Southern and
Frontier Conferences, which were caught by reading rather than by a gate.

"Storm" is the instructive one. It is an *adjective* in the pool, so it never appears alone in a
generated name — but "Storm Wardens" contains it, and containment is what `Blocklist.blocks`
evaluates. An adjective pool feels safe and is not.

All eight are now blocked, and all eight were replaced in their pools one-for-one — Shrikes,
Draymen, Sawyers, Wheelwrights, Bitterns, Martens, Lamplighters, Basalt — so the pool counts stay 22
and 18 and `rng.pick` draws the same index it drew before. A swap changes the names in a save and
nothing else about it. Each replacement was searched for as a college nickname before it was used
and none was found.

Confidence differs across the eight. Beacons, Marauders, Otters, Foresters, Herons and Drovers are
confirmed NCAA or NAIA programmes; Harriers is USCAA only, which is weaker; Storm is confirmed at
two NCAA schools, one of which plays football.

### 2.10 Competitor and adjacent products

Madden, NCAA Football, EA Sports College Football, Football Manager, Out of the Park Baseball,
Front Office Football, Draft Day Sports, Pro Strategy Football, Retro Bowl, Wolverine Studios,
Maximum Football, Axis Football, Legend Bowl, Backbreaker, College Dynasty.

These never reach a player through the generator. They reach one through shipped copy and a store
listing, which is what `LegalTests`' shipped-copy scan covers.

### 2.11 Trade dress: the professional tier

Thirty-two professional pairs added. The list was a college slice while the generator dresses both
tiers, so every pro identity in every save was checked against the wrong sport's palette. Seventeen
of the thirty-two already sat within ΔE 25 of a college entry, which is why the omission was
survivable rather than harmless; fifteen were unguarded.

---

## 3. What is deliberately not blocked

A denylist that errs generous costs a few nouns until it starts costing words the game has to say,
and then it gets weakened instead of obeyed. These are refused entry, and a test asserts they stay
sayable:

- **"Red Zone".** The sharpest case. `normalised` drops spaces, so "RedZone" and "red zone" are one
  token — blocking the broadcast mark alone would block the sport's term for the twenty-yard line
  in. Every entry covering a mark built from ordinary football words is longer than the descriptive
  phrase on purpose.
- **"The Game".** A mark for one rivalry and a phrase this application uses constantly.
- **"Head Coach".** Proposed and dropped: it is a job title, it is an EA product name, and it is
  already in `ScreenReadModels` copy. The scan caught it, which is the scan working.
- **"NIL", "Transfer Portal", "Signing Day", "Combine", "Playoff", "Draft Board", "Bowl Game",
  "Conference Championship", "Two-Minute Warning".** Descriptive vocabulary. Where a mark is built
  from them, the entry carries the qualifying word: National Signing Day, Scouting Combine, College
  Football Playoff.

---

## 4. Open items for the owner and counsel

1. **The joint-identification risk is unchanged and untestable here.** A fictional programme in a
   real city wearing that city's real programme's colours can identify the real one even though
   every part is individually clean. The ΔE test catches the colours. The combination is a review
   obligation, already recorded in `CLAUDE.md`, `01` §7 and `02` §11.3.5.
2. **Registration status is unverified.** No entry here was checked against a trademark register.
   The three near-miss coinages in §2.1 are explicitly *not* claimed to be registered.
3. **"Pro Football Coach" is close to a competitor's title.** `docs/01-RESEARCH.md` §B is built on
   the Achi Jones "Football Coach" lineage, and the reference app in §A is "College Football
   Simulator". The project's own working title cannot be blocklisted — but a title decision is a
   counsel question this brief is the right place to raise, and the pairing of "Pro Football" with a
   coaching sim is the part worth asking about.
4. **Nicknames below Division I are a maintenance problem, not a solved one.** Eight were found by
   searching the pools against every division. There are roughly 1,900 college nicknames in the
   United States and the pool holds 22 nouns and 18 adjectives; the ones found are the ones searched
   for. The durable fix is the one the name grammar already uses everywhere else — build nicknames
   from morphemes rather than from a pool of real English nouns — and it is not attempted here.
5. **The trade-dress list is still hand-maintained.** 71 pairs against a sport with thousands of
   programmes.

---

## 5. Provenance

The nickname findings in §2.9 and the conference findings in §2.4 came through the search layer,
which `01-RESEARCH.md`'s standing caveats already flag as summarisation rather than primary reading.
The programme attributions:

- Lake Forest Foresters — <https://en.wikipedia.org/wiki/Lake_Forest_Foresters_football>
- Cal State Monterey Bay Otters — <https://en.wikipedia.org/wiki/Cal_State_Monterey_Bay_Otters>
- Mary Marauders — <https://en.wikipedia.org/wiki/Mary_Marauders>
- Valparaiso Beacons — <https://en.wikipedia.org/wiki/Valparaiso_Beacons>
- UMass Boston Beacons — <https://en.wikipedia.org/wiki/UMass_Boston_Beacons_football>
- Science and Arts of Oklahoma Drovers — <https://www.usaoathletics.com/general/2023-24/releases/20240712sxyg9u>
- William Smith Herons — <https://bvmsports.com/ncaa/william-smith-college-herons/>
- Simpson Storm football — <https://en.wikipedia.org/wiki/Simpson_Storm_football>
- Lake Erie Storm — <https://en.wikipedia.org/wiki/Lake_Erie_Storm>
- Prairie College Conference — <https://en.wikipedia.org/wiki/Prairie_College_Conference>

---

## 6. Verification

**There is no Swift toolchain and no `xcodebuild` in this environment. Nothing here has been
compiled, and no test in this repository has been run.** `docs/STATUS.md` carries the same statement
against the files this change touches.

What *was* checked, and how: a Python mirror of `Blocklist.normalised`, `words` and the sliding-window
matcher, together with a hand-mirrored enumeration of every name shape the generator can emit —
570 places, the four institution shapes, 396 nicknames, 72 conference and 72 division names, every
`<place> <venue>` and `<surname> <venue>`, every tradition and rivalry name, and 237,000 person
names. The mirror was validated by reproducing the eight dual-use cities `LegalTests` asserts, from
the lists rather than from the expectation. Against it:

- every new entry: zero collisions with the reachable institution-kind set, the place-kind set and
  the person set;
- zero emittable words blocked, after the eight pool replacements;
- the eight dual-use cities unchanged;
- the shipped-copy scan re-run over `Sources`: one hit, "Head Coach", which is why that entry was
  dropped;
- the new assertions in `LegalTests` re-run through the mirror: all hold, including the
  numeral-form derivation over all 482 entries and the prefix/suffix check over all of them;
- for trade dress, a mirror of `SeededRandom`, `Colour(hue:saturation:lightness:)`, the WCAG
  contrast pair and `ColourGenerator.pair`, reproducing `GenerationTests`' colour cases. Before the
  change: 0 collisions at seed 99 over 2,000 pairs, 0 fallbacks and 499 distinct primaries at seed
  4242 — which matches what the suite asserts today and is what validates the mirror. After: the
  same three numbers with 71 pairs on the list.

A mirror is not a compiler. It shares this brief's assumptions about the pools by hand and will
drift the moment they do.
