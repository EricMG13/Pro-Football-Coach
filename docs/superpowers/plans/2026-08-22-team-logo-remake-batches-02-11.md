# Team Logo Remake Batches 02–11 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan batch-by-batch. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace or harden the remaining 112 weak, duplicated, identity-mismatched, or dark-surface-failing football team marks after Batch 01.

**Architecture:** Work only in candidate batch folders until each mark passes identity, football-scale, light/dark, and distinctness review. Resolve every filename, team, abbreviation, and palette from the current manifest; use the target ledger below for subject direction, then install canonical assets only after the full candidate set passes.

**Tech Stack:** Built-in image generation, PNG/RGBA assets, Pillow-based mechanical normalization, existing team-logo manifest and review tooling.

## Global Constraints

- The positive design-language reference is `output/logos/batch-2/batch-2-phone-preview.png`.
- The explicit negative reference is `exports/logo-batches/2026-08-22-batch-01-predators-house-style/batch-01-predators-house-style-mobile-review.png`.
- Use the positive reference's compact professional football language: flat team-colour fills, dark structural outline, confident curves, expressive motion/anatomy, purposeful layered cuts, and one clear idea per mark.
- Reject the negative reference's crude polygon language: blunt animal blobs, oversized empty masses, generic construction-paper geometry, and weak anatomy.
- Also reject the opposite failure mode: gradients in final candidates, illustrative/esports clutter, tiny teeth/scales/toes, scenery, texture, 3D lighting, or fragile internal slivers.
- Final candidates are 256×256 8-bit RGBA PNGs with genuine transparency, at least 10 px edge clearance, no feature/gap below approximately 13 px, no more than six filled regions, and literal current-manifest palette colours.
- One neutral separator is permitted only when it is even, purposeful, and required for both-surface separation.
- The darker team colour owns the structural silhouette; the brighter team colour supplies broad accents.
- Every mark must remain recognizable at 20 points and distinct from every shipped and candidate mark.
- Do not modify shipped assets, canonical names, stable IDs, or manifest records before candidate approval.
- Do not introduce a single repeated silhouette template across unrelated teams.

## Per-batch execution checklist

For each exact batch table below:

- [ ] Resolve all row mappings against `Tools/TeamLogos/manifest.json`; fail on a missing, duplicate, or palette-mismatched asset.
- [ ] Reuse an existing approved-quality source only when it belongs to the same asset or depicts the exact approved subject without creating a league duplicate.
- [ ] Generate one independent transparent source per remaining target with the positive and negative references named explicitly in the prompt.
- [ ] Normalize accepted sources to exact filename, palette, dimensions, alpha, margin, region, and byte-budget contracts without touching shipped assets.
- [ ] Render 20-, 32-, and 44-point grouped sheets on both light and dark surfaces.
- [ ] Review every mark for subject identity, professional football character, positive-reference fit, negative-reference avoidance, two-surface separation, and set-level heterogeneity.
- [ ] Regenerate or repair every failure; do not waive a mark merely because its PNG contract passes.
- [ ] Record the final decision, family, proposed identity where applicable, source provenance, and review outcome.
- [ ] Run the batch structural assertions and cross-catalogue near-duplicate audit before advancing.

---

## Authority and reconciliation

`Tools/TeamLogos/manifest.json` is authoritative for `assetName`, current team name, abbreviation, palette, concept, and review state. The HTML repetition audit supplies only its motif-normalisation algorithm. Batch 15 is a candidate draft: its names and all 38 palettes are stale, so this plan reuses only useful composition-family grammar and re-keys every target to the current manifest.

The scopes are distinct:

| Scope | Catalogue total | Covered by batch 01 | Remaining contribution |
|---|---:|---:|---:|
| Duplicate occurrences after keeping one of each of 48 recurring motifs | 92 | 12 | 80 |
| Current `Re-brief outstanding` records | 52 | 5 | 47 |
| Current explicit dark-surface `Outstanding:` records | 43 | 2 | 41 |

The naive 80 is not a completion inventory. Ten recurring motifs have **no identity-coherent exemplar**: beacon brazier, harrier, stand of three pines, drove-road gate, heron, compass rose, crossed hook and blade, otter, riveted plate, and stalking-cat head. Every occurrence of each is `Re-brief outstanding`. Keeping one would satisfy the arithmetic of 92 while knowingly retaining artwork for the wrong current nickname. This plan therefore replaces those ten would-be exemplars too.

The authoritative remaining union is:

- 90 recurring-motif targets after batch 01: the original 80 plus the ten incoherent would-be exemplars;
- four one-off re-brief targets outside recurring motifs;
- 18 additional dark-surface repairs not already in those 94 targets.

**Total: 112 targets in batches 02–11: nine batches of 12 and a final batch of four.** The historical “64 dark failures” is not added: it predates the re-key and is superseded at asset level by the current manifest's 43 explicit dark exceptions. Style findings without an asset-level current flag inform briefs and acceptance criteria; they do not create invented targets.

Reason codes below: `D<n>` = replace a duplicate occurrence of a motif occurring `<n>` times; `R` = current re-brief mismatch; `K` = current dark-surface failure. `X` means construction-only repair of a retained or one-off identity. All other family codes are replacement briefs: `P` predator, `L` letterform, `W` extreme weather, `M` mythical creature, `C` celestial, `A` aquatic life, `B` botanical life, `T` atmospheric phenomenon, `I` invertebrate life, and `G` geological form.

The six ecological families (`A/B/T/C/I/G`) are justified extensions from the drafted batch-15 grammar and the design review's call for aquatic life, insects, plants, weather, geology, and regional ecology. They retain the approved construction contract while expanding silhouettes beyond profiles, generic bird heads, tools, and crests. They are used only as composition grammar; batch 15's stale identities and palettes are not adopted.

## Retained-exemplar ledger for all 48 recurring motifs

Retention rule after the two explicitly approved batch-01 choices: the retained mark must match the current nickname; prefer a current light/dark separation pass; among equally eligible marks, retain the lexically earliest `assetName` as the deterministic review candidate. A retained dark-failing exemplar remains in the ledger but receives a construction-only `K` repair below. “None” is deliberate and means all occurrences must be replaced.

| Motif | Retained exemplar | Rationale |
|---|---|---|
| Palisade line ×7 | `TeamLogo_25EDC7BB3D5F46E4B8C0B1B22D5D190C` — Waurika Maritime Iron Palisades | Batch 01 explicitly approves its compact shield and three driven stakes as the clearest 20-point palisade. |
| Shield boss ×7 | `TeamLogo_46D018BB3BD9422A91A91971012E8834` — Nacogdoches Poly Verdant Bulwarks | Batch 01 explicitly approves its broad circular mass and bilateral straps as the clearest 20-point boss. |
| Beacon brazier ×6 | **None** | All six are `R`; no mark depicts its current nickname. |
| Three fletched arrows ×6 | `TeamLogo_65AC24FD9E0B4C56A06A53A589DAADD4` — Clayton Poly Gale Fletchers | Identity-coherent, current surface pass, deterministic tie-break. |
| Harrier ×5 | **None** | All five are `R`; no mark depicts its current nickname. |
| Crossed sledge and chisel ×4 | `TeamLogo_DCE1435BDA29499895625FEE1BFDE221` — Waynesboro Poly Basalt Quarrymen | Identity-coherent, current surface pass, deterministic tie-break. |
| Hovering kestrel ×4 | `TeamLogo_05BCBD14EF5E47F3926166202C01D839` — Milford Coastal Gale Kestrels | Identity-coherent and the only current clean-pass candidate. |
| Lodestone compass ×4 | `TeamLogo_0017F958E7D04FFC9EA801A252B40FD6` — Zumbrota Central Marsh Lodestars | Identity-coherent, current surface pass, deterministic tie-break. |
| Miner's lamp ×4 | `TeamLogo_D4F46917036A4BBC9FA198D66B8F1819` — Ada Harbor Colliers | Identity-coherent and the only current clean-pass candidate. |
| Stand of three pines ×4 | **None** | All four are `R`; no mark depicts its current nickname. |
| Anchor ×3 | `TeamLogo_4F7B667410DE489087A97ECA11DDFBC3` — Escanaba Coastal Meridian Anchors | Identity-coherent and the only current clean-pass candidate. |
| Barrel hoop and adze ×3 | `TeamLogo_99FD7E6AC4764FA297F389E767D8D29F` — Spencer Maritime Flint Coopers | Identity-coherent; earliest eligible exemplar, retained after its `K` repair. |
| Boundary post and chain ×3 | `TeamLogo_A30D0E61D95A4C4CB20CF43A6943E341` — Ocean City Agricultural Tidal Wardens | Identity-coherent and the only current clean-pass candidate. |
| Cooper under flat cap ×3 | `TeamLogo_5318644DEB7C460194AB8E44598540FF` — Calexico Regional Iron Coopers | Identity-coherent clean pass; selected over the dark-failing alternative. |
| Drove-road gate ×3 | **None** | All three are `R`; no mark depicts its current nickname. |
| Turned goshawk ×3 | `TeamLogo_34D637F4069E4AFF9A76DCE65F6FE606` — Binghamton Hearth Goshawks | Identity-coherent, current surface pass, deterministic tie-break. |
| Goshawk head ×3 | `TeamLogo_88D0FB28B8354C949FEE25FB63D497FF` — Barre Coastal Frost Goshawks | Identity-coherent, current surface pass, deterministic tie-break. |
| Gun port ×3 | `TeamLogo_343AE8DE59CC401796B246AE69E744BE` — Parkersburg Poly Sable Bastions | Identity-coherent, current surface pass, deterministic tie-break. |
| Headland light ×3 | `TeamLogo_ABD2FF259964494B86E34B89E24B5348` — Kerrville Timber Voyagers | Identity-coherent and the only current clean-pass candidate. |
| Striking heron ×3 | **None** | All three are `R`; no mark depicts its current nickname. |
| Arched marten ×3 | `TeamLogo_12F8D33688BE4F10A59A048E58538175` — Pella Flint Martens | Identity-coherent and the only current clean-pass candidate. |
| Marten head ×3 | `TeamLogo_9BBB69C94FBA4C26BFDF8BAEF98A8682` — Lebanon Regional Harbor Martens | Identity-coherent; earliest eligible exemplar, retained after its `K` repair. |
| Hooked-beak shrike ×3 | `TeamLogo_80E36CC98576453EA822ECBB145E94DD` — Bristol Cedar Shrikes | Identity-coherent and the only current clean-pass candidate. |
| Compass rose ×2 | **None** | Both are `R`; neither mark depicts its current nickname. |
| Crescent knife over hide ×2 | `TeamLogo_633D4024B8D748B6A7CC4D7682EDD614` — Gillette Maritime Slate Tanners | Identity-coherent, current surface pass, deterministic tie-break. |
| Crossed hook and blade ×2 | **None** | Both are `R`; neither mark depicts its current nickname. |
| Curlew head ×2 | `TeamLogo_BF72B12052D042A59152136626721018` — Bridgeport Poly Bramble Curlews | Identity-coherent and the only current clean-pass candidate. |
| Cut field ridge ×2 | `TeamLogo_73490D9265A64A96BAFF0C67F093918F` — Camas Poly Verdant Reapers | Identity-coherent, current surface pass, deterministic tie-break. |
| Fletcher under hood ×2 | `TeamLogo_1894B47A15D14F0DB847A3B274E237F4` — Watertown Coastal Marsh Fletchers | Identity-coherent; earliest eligible exemplar, retained after its `K` repair. |
| Furnace stack ×2 | `TeamLogo_A0D5378A462C4791AE53952A79FCCD62` — Buckeye State Bramble Smelters | Identity-coherent, current surface pass, deterministic tie-break. |
| Ironclad prow ×2 | `TeamLogo_9F0787A83784407FBCDA8A2CDEB855FC` — Cohoes Coastal Flint Ironsides | Only identity-coherent candidate; retain after its `K` repair. |
| Face-plate ironside ×2 | `TeamLogo_0D81D2F903834BD5A74176604D277691` — Rexburg A&M Cedar Ironsides | Identity-coherent and the only current clean-pass candidate. |
| Kestrel head ×2 | `TeamLogo_900EF64D9234456EAA4ED488C78B968E` — Payson A&M Cobalt Kestrels | Only identity-coherent candidate; retain after its `K` repair. |
| Crossroads milestone ×2 | `TeamLogo_7DEF46FB180544A39484F2589F1712ED` — Wilber Shale Wayfarers | Identity-coherent, current surface pass, deterministic tie-break. |
| Open-jaw otter ×2 | **None** | Both are `R`; neither mark depicts its current nickname. |
| Pouring crucible ×2 | `TeamLogo_64F5B014D4BE4297A8F1026ACA25D4A6` — Carlin A&M Verdant Smelters | Identity-coherent, current surface pass, deterministic tie-break. |
| Wide-hat prospector ×2 | `TeamLogo_2558D27E577244D8B37D80260FB47E61` — Sitka Poly Thunder Prospectors | Identity-coherent, current surface pass, deterministic tie-break. |
| Rigger in knit cap ×2 | `TeamLogo_30283F8523334C579A31DADB683D35CA` — San Angelo A&M Copper Riggers | Identity-coherent; earliest eligible exemplar, retained after its `K` repair. |
| Riveted hull plate ×2 | `TeamLogo_5C4CE91F969D4A748E1A7E672C9631AB` — Hermann Coastal River Ironsides | Identity-coherent, current surface pass, deterministic tie-break. |
| Riveted plate ×2 | **None** | Both are `R`; neither mark depicts its current nickname. |
| Shore of broken spars ×2 | `TeamLogo_74CBDAB262B04A15B1C5547E005A7E4F` — Burlington A&M Sable Wreckers | Identity-coherent and the only current clean-pass candidate. |
| Stack of cut timber ×2 | `TeamLogo_759E356409AA496B9037952E6830FA52` — Rapid City Central Obsidian Sawyers | Identity-coherent; earliest eligible exemplar, retained after its `K` repair. |
| Stalking-cat body ×2 | `TeamLogo_77090443FFE541F884EFD0184B6F7441` — Zeeland Kiln Stalkers | Identity-coherent, current surface pass, deterministic tie-break. |
| Stalking-cat head ×2 | **None** | Both are `R`; neither mark depicts its current nickname. |
| Tanner in apron and cap ×2 | `TeamLogo_35A88873B49C4A9CB99A47F75AD6D35F` — Dagsboro Basalt Tanners | Identity-coherent, current surface pass, deterministic tie-break. |
| Travelling-hat wayfarer ×2 | `TeamLogo_4135CA8D38DC4CDEAC7CF4951BC6E52E` — Dalhart Cedar Wayfarers | Identity-coherent and the only current clean-pass candidate. |
| Jaw-forward wrecker ×2 | `TeamLogo_161EBDA6B0924127B535359070BDEFBE` — Kirksville State Cedar Wreckers | Identity-coherent and the only current clean-pass candidate. |
| Coiled wyvern ×2 | `TeamLogo_29A6A1DC04F249E78BF6D6793812399E` — Aberdeen Regional Anvil Wyverns | Only identity-coherent candidate; retain after its `K` repair. |

## Batch sequence

Each replacement uses the exact manifest palette shown. Proposed public names are review-only. `X` rows keep the current public name and subject; they simplify the silhouette and add the single construction-system keyline needed on both surfaces. Subjects intentionally alternate viewpoint and geometry so the league does not become another run of aggressive side-profile heads.

### Batch 02 — six beacons, two arrows, four harriers

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_2FDA20B506DE405986CC44F5E4835558` | Laurel Tech Hollow Bargemen | `#5DD11F`, `#463902` | D6 + R | M; **Laurel Tech Hollow Krakens**; top-down full-body kraken, four broad tentacles forming a broken pinwheel. |
| `TeamLogo_5EB19F56878143B29200BB201482D59D` | Petoskey Regional Verdant Smelters | `#29138B`, `#EE46F1` | D6 + R | A; **Petoskey Regional Verdant Needlefish**; full body bending into a fast crescent, long beak leading. |
| `TeamLogo_5F09D018DCA941F78ACD040A07230254` | Sedalia Hearth Millwrights | `#265610`, `#D1DB99` | D6 + R | C; **Sedalia Hearth Meteors**; three fused fragments driving one broad diagonal trail. |
| `TeamLogo_7767AA6A6FA7440298D6B02EEA82AF5F` | Smithfield Central Tidal Bargemen | `#8EDCF6`, `#244102` | D6 + R | T; **Smithfield Central Tidal Aurora**; three broad ribbons folded into an angular crown. |
| `TeamLogo_A6B3C25FD8C2410D99818F260720A790` | Redding Slate Millwrights | `#26A659`, `#0D3436` | D6 + R | A; **Redding Slate Paddlefish**; top-down full body in an S-turn, paddle snout and forked tail opposed. |
| `TeamLogo_CBDF8F99B7C64B27B545E5FDC61EB999` | Canandaigua Tech Silver Tanners | `#97D590`, `#612F8E` | D6 + R | C; **Canandaigua Tech Silver Nebulae**; compact nebula knot wrapped by one broken orbital ribbon. |
| `TeamLogo_6219C3658D4946BE9C4BD302DF0A90D5` | Essex Junction Maritime Granite Wainwrights | `#5F7A1F`, `#88E78B` | D6 + R | M; **Essex Junction Maritime Granite Leviathans**; full-body sea dragon in an open C-coil with one broad fin. |
| `TeamLogo_837E01370ECF4655AA236668ED84AA03` | Iron Mountain Ember Wheelwrights | `#51E1EC`, `#153889` | D6 + R | G; **Iron Mountain Ember Monoliths**; one split stone monolith leaning forward as a heavy wedge. |
| `TeamLogo_05293748863A41259807C9C4C35E4C11` | Edgartown Cedar Millwrights | `#462D8F`, `#3CAEB9` | D5 + R | I; **Edgartown Cedar Stag Beetles**; top-down full body with oversized mandibles and one armored wing case. |
| `TeamLogo_0A036DF9329B4C20A80DD53506FCFDD6` | Ephraim Maritime River Wheelwrights | `#143838`, `#C97754` | D5 + R | M; **Ephraim Maritime River Kelpies**; full-body kelpie leaping on a tight diagonal curl. |
| `TeamLogo_4C6A9A21414A4D5E9DE291DD4198640B` | Nampa Anvil Bargemen | `#4DB125`, `#4E3613` | D5 + R | W; **Nampa Anvil Thunderbolts**; one massive forked lightning rupture with a wide central counter. |
| `TeamLogo_6A58BFEC098E40C294F6A1B551F098DD` | Lovelock Iron Lamplighters | `#F862D5`, `#43205A` | D5 + R | M; **Lovelock Iron Golems**; full-body stone golem in a low shoulder charge, fists merging into the mass. |

### Batch 03 — finish harriers; kestrels, pines, and gates

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_758174F97A5B478694E21EFF73BB3A4C` | Effingham Verdant Bargemen | `#D049AC`, `#393314` | D5 + R | M; **Effingham Verdant Basilisks**; full-body basilisk coiled around one open triangular counter. |
| `TeamLogo_69C777D146CB46EF878EC26AAD0E1F04` | Titusville Hollow Draymen | `#C04830`, `#6EED92` | D4 + R | W; **Titusville Hollow Vortices**; three broad tapering bands forming one asymmetric funnel. |
| `TeamLogo_7F6BE01D0F634FA994D30E4427168A2B` | Sharon Cobalt Wheelwrights | `#96E5E8`, `#5D761E` | D4 + R | P; **Sharon Cobalt Mosasaurs**; full-body mosasaur banking downward in a hooked crescent. |
| `TeamLogo_6CAF0BE740EB49459E4BDB5ABDD40D8A` | Chanute Marsh Wheelwrights | `#1A4699`, `#EC88C8` | D4 + R | I; **Chanute Marsh Scorpions**; top-down full body, claws wide and tail crossing the centre once. |
| `TeamLogo_78E19A7EAB7D439A9610668A56547ACC` | Johnstown Hearth Bitterns | `#2F1287`, `#B79CF2` | D4 + R | T; **Johnstown Hearth Derechos**; one bow-shaped storm front driving two blunt wind bands. |
| `TeamLogo_87497AA4AED84757B45CC5EFEBA7EBEC` | Lihue Cedar Wainwrights | `#DE1B22`, `#16F3BF` | D4 + R | G; **Lihue Cedar Lava Domes**; cracked dome cutaway with one thick rising vent. |
| `TeamLogo_8E5802E12E344C2E90F14D92567B26BD` | Janesville Central Frost Wainwrights | `#E949C6`, `#3F1F6F` | D4 + R | C; **Janesville Central Frost Eclipses**; offset dark disc with a broken corona and single flare. |
| `TeamLogo_695F21FF95444CF3886F0CB071D200A4` | Yreka Agricultural Granite Wainwrights | `#7124D6`, `#6CE166` | D3 + R | I; **Yreka Agricultural Granite Dragonflies**; top-down heavy body and four blade-like wings. |
| `TeamLogo_C9129F1DC49F4FAC8C36CEAAAA0D958F` | Rangeley Kiln Delvers | `#8D9FF6`, `#075551` | D3 + R | G; **Rangeley Kiln Caverns**; cavern-mouth cutaway with two interlocking stalactite teeth. |
| `TeamLogo_8D6C1461E8BA4C20A25E5DCD872A2A94` | Sulphur Springs A&M Meridian Delvers | `#F05C99`, `#3E170F` | D3 + R | M; **Sulphur Springs A&M Meridian Hydras**; three necks diverging from one low body, no crest. |
| `TeamLogo_AC5D9C7510594B7C9C988B557A5EAE3D` | Lewisburg Cinder Sentinels | `#BBC34B`, `#660A29` | D3 + R | G; **Lewisburg Cinder Calderas**; broken-rim caldera cutaway with one bright central vent. |
| `TeamLogo_B345E29D2F42497AABAB7385E6326173` | McCook Slate Quarrymen | `#69C74D`, `#661499` | D3 + R | G; **McCook Slate Glaciers**; one glacier face split by a deep central crevasse. |

### Batch 04 — remaining all-incoherent motifs and mixed profiles

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_B5C9CAB852854CF8951E88C55EBBA97C` | Rocky Mount A&M Slate Smelters | `#4C1020`, `#5BBE50` | D3 + R | C; **Rocky Mount A&M Slate Coronas**; offset solar core throwing one broad broken corona. |
| `TeamLogo_0F05F4F368CA4674B2109DD7B75E1088` | Oneonta Slate Lamplighters | `#3B103C`, `#54DEBC` | D3 + R | I; **Oneonta Slate Mantises**; three-quarter full body with forelegs forming two massive hooks. |
| `TeamLogo_19AD9AAA1590417499DB2C132776E7EA` | Danville Timber Millwrights | `#15DEF4`, `#046734` | D3 + R | A; **Danville Timber Mantas**; full-body manta banking upward as a broad diamond. |
| `TeamLogo_3CA5936BE1F44851995B3879C39DE729` | Wapakoneta Poly Bramble Bitterns | `#50101A`, `#D90BE0` | D3 + R | I; **Wapakoneta Poly Bramble Horseshoe Crabs**; top-down shell and tail forming a spearhead. |
| `TeamLogo_816FF11F0AE24F5980FE1639A5FB2A25` | Claremont Maritime Timber Draymen | `#8E2E6B`, `#37E6E3` | D3 + R | P; **Claremont Maritime Timber Wolverines**; full-body wolverine springing across a rising diagonal. |
| `TeamLogo_EAB0CED3A080474397CC8211C51F1CC8` | Miles City Shale Wheelwrights | `#8BD6F9`, `#441239` | D3 + R | W; **Miles City Shale Cyclones**; three interlocked wind blades around a wide eye. |
| `TeamLogo_DA7DABF5F0444E05A9064EE7AE778B78` | Oak Bluffs Tech Cinder Draymen | `#53092D`, `#13B934` | D2 + R | C; **Oak Bluffs Tech Cinder Black Holes**; broken accretion ring pulled into one offset dark core. |
| `TeamLogo_F9BD5A3A9ED548969CEF085A8A509C2D` | Carefree Amber Bargemen | `#3D0F70`, `#A3F485` | D2 + R | M; **Carefree Amber Griffins**; full-body griffin diving in a steep open V, not a head badge. |
| `TeamLogo_728B69076F6A4A50AFB2BBA9188FD49C` | Ripon Regional Meridian Wainwrights | `#EFA94D`, `#740FA3` | D2 + R | I; **Ripon Regional Meridian Hornets**; top-down full body with wings swept into a pointed kite. |
| `TeamLogo_942F47832857436584FFF3561EE629A2` | Shamokin Granite Wainwrights | `#150486`, `#778A19` | D2 + R | M; **Shamokin Granite Thunderbirds**; full-body bird descending front-on with one lightning-tail notch. |
| `TeamLogo_96CC1AF0107D42CAA9CE24F829E6018E` | Cranston Timber Draymen | `#23D750`, `#721404` | D2 + R | G; **Cranston Timber Geodes**; split cross-section with three oversized crystal teeth. |
| `TeamLogo_E43B9F36D94A406C9E630D3FA3148E39` | Falmouth Maritime Meridian Lodestars | `#7E1075`, `#DD7BE0` | D2 + R | L; **name unchanged**; exact `FAL` interlocked as a forward-leaning wedge. |

### Batch 05 — finish re-brief inventory; start dark duplicates

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_0213C958E1554E938E36AA606F8A670A` | Pecos Bramble Millwrights | `#38200A`, `#61B8FA` | D2 + R | P; **Pecos Bramble Grizzlies**; full-body bear in a low three-quarter charge. |
| `TeamLogo_7E474219E18A4091ADB2A7C4A3A5A445` | Halifax Valley Timber Lamplighters | `#63A1E9`, `#76128C` | D2 + R | T; **Halifax Valley Timber Squalls**; one hard-edged wind hook driving a compact cloud mass. |
| `TeamLogo_E9EA791F96C64B1AB9FCFFEAE9DCE398` | Williamsport A&M Tidal Lodestars | `#DFA5C6`, `#22133F` | D2 + R | C; **Williamsport A&M Tidal Pulsars**; dense core crossed by two opposing broad beams. |
| `TeamLogo_F546F1FAFFE746E8ABA4CE7943DE80C1` | Elko Amber Wainwrights | `#8AE2F0`, `#3D3899` | D2 + R | A; **Elko Amber Sailfins**; full-body fish with one towering dorsal sail and forked tail. |
| `TeamLogo_A76F3F73396A4D0AAE5F7D5A4E206897` | Wahpeton Timber Smelters | `#390E14`, `#E665DD` | D2 + R | I; **Wahpeton Timber Tarantulas**; top-down body with eight legs consolidated into four heavy pairs. |
| `TeamLogo_ADCDD8604E4C4DDEAF4AF72EDDD40FF9` | Baggs Anvil Wainwrights | `#8D06B2`, `#D9C868` | D2 + R | W; **Baggs Anvil Avalanches**; one descending slab breaking into two broad angular masses. |
| `TeamLogo_3FCE33B8F5C54D74BB41FB29886AD0C6` | Carbondale Coastal Hollow Millwrights | `#241A47`, `#93E189` | D2 + R | L; **name unchanged**; exact `CAR` locked into a broad asymmetric block. |
| `TeamLogo_E2EA9F8785EC4B2DA3076FAE41E7C490` | Eastport River Reapers | `#441F18`, `#9AF835` | R, one-off | L; **name unchanged**; exact `EAS` as an angular rising monogram. |
| `TeamLogo_0FB78D18D0894719B861DD1E9F9C2082` | Weiser Valley Flint Wainwrights | `#91F3EE`, `#0F8A69` | R, one-off | L; **name unchanged**; exact `WEI` interlocked around one wide counter. |
| `TeamLogo_ACEFC30576904402BEB83FB644C79A1E` | Springville Maritime Peat Lodestars | `#AE0473`, `#F7975F` | R, one-off | L; **name unchanged**; exact `SPR` forming a compact forward arrow. |
| `TeamLogo_BC1EBE0F069B4BC9A33B23A887CA898C` | Williston Central Sable Lodestars | `#D449B2`, `#2A0C37` | R, one-off | L; **name unchanged**; exact `WIL` as a wide base with one rising terminal. |
| `TeamLogo_CB7833BC70FE42C0943A61D73AADC350` | Waimea Coastal Anvil Quarrymen | `#040953`, `#C40EDD` | D4 + K | G; **Waimea Coastal Anvil Spires**; three fused basalt spires forming one climbing silhouette. |

### Batch 06 — dark duplicate cluster

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_DD1EA5692955458882D8C966CF42EB47` | Mesquite Thunder Lodestars | `#8B7DD4`, `#280769` | D4 + K | C; **Mesquite Thunder Comets**; dense nucleus with one broad split tail on a steep diagonal. |
| `TeamLogo_6504837E4DE44C068C9A2E818B668BC5` | Pipestone Thunder Colliers | `#E28479`, `#501499` | D4 + K | I; **Pipestone Thunder Cicadas**; top-down body and wings forming a compact shieldless kite. |
| `TeamLogo_DEC9D295AA774D578CECE3E92EFDC219` | Weatherford Shale Colliers | `#1F0958`, `#1D65E2` | D4 + K | T; **Weatherford Shale Thunderheads**; one towering cloud mass with a lightning-shaped notch. |
| `TeamLogo_E2034539439C471E82C24E04DCE73B42` | Penn Yan Meridian Colliers | `#99F5D5`, `#43093E` | D4 + K | M; **Penn Yan Meridian Nagas**; full-body horned naga descending in an open S-coil. |
| `TeamLogo_34CD7F4894904F32B21A97F2E351FACD` | Delaware City Cinder Anchors | `#6D0866`, `#797FD2` | D3 + K | A; **Delaware City Cinder Sawfish**; full body accelerating laterally, rostrum leading the wedge. |
| `TeamLogo_399815996A7A4926AF49340208D9057A` | Biddeford Central Thunder Anchors | `#2595C1`, `#184332` | D3 + K | T; **Biddeford Central Thunder Tempests**; rotating eye built from three broad interlocking bands. |
| `TeamLogo_99FD7E6AC4764FA297F389E767D8D29F` | Spencer Maritime Flint Coopers | `#081E59`, `#B9EC22` | K; retained D3 exemplar | X; **name unchanged**; preserve hoop-and-adze identity, merge thin crossings and add one compliant keyline. |
| `TeamLogo_BB6717ED25E74CE3838D9292E41AA8C1` | New Haven Meridian Coopers | `#51FB51`, `#070363` | D3 + K | B; **New Haven Meridian Morels**; three fused morel caps rising as one triangular mass. |
| `TeamLogo_789772DF0D264FCB87E66FB1B0BCAE2F` | Skowhegan Valley Harbor Wardens | `#212F69`, `#E3A1D9` | D3 + K | M; **Skowhegan Valley Harbor Oni**; original front-facing horned mask reduced to four large planes, no frame. |
| `TeamLogo_1032E7BD52E64C0285D44DC399B13B7A` | Hood River Maritime Iron Coopers | `#91DB8A`, `#540D59` | D3 + K | B; **Hood River Maritime Iron Bristlecones**; wind-bent crown rising from one twisted trunk. |
| `TeamLogo_14A2B6E262D44F68B5C899DD51B84249` | New London Valley Iron Goshawks | `#0A3D2E`, `#209CD9` | D3 + K | M; **New London Valley Iron Direwolves**; full-body direwolf lunging upward, spine and tail one arc. |
| `TeamLogo_306B310F484F48B98FC04F76DCE0F51F` | Rockland Copper Martens | `#4B205B`, `#E2A4EA` | D3 + K | A; **Rockland Copper Hammerheads**; top-down full-body shark, hammer and tail creating a strong T. |

### Batch 07 — remaining dark recurring marks

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_9BBB69C94FBA4C26BFDF8BAEF98A8682` | Lebanon Regional Harbor Martens | `#16C5C2`, `#290797` | K; retained D3 exemplar | X; **name unchanged**; preserve the marten identity, broaden jaw/ear gaps and add one compliant keyline. |
| `TeamLogo_C07AC0D116CE4510B26283DB4CAD3E38` | Terre Haute A&M Obsidian Martens | `#391004`, `#675AF2` | D3 + K | C; **Terre Haute A&M Obsidian Magnetars**; compact offset core driving two opposing magnetic arcs. |
| `TeamLogo_0FDAFFDF1E0048D68F5298BEC1B9254A` | Middlebury Coastal Marsh Shrikes | `#1A2866`, `#F38582` | D3 + K | P; **Middlebury Coastal Marsh Cobras**; full-body cobra rising front-on with one wide hood counter. |
| `TeamLogo_4025813E0EF74FBAA82187DB4A5D967F` | Carlisle Anvil Shrikes | `#6BA92D`, `#071564` | D3 + K | W; **Carlisle Anvil Hailstorms**; one oversized hail impact cracking a compact cloud mass. |
| `TeamLogo_A49BA96C86324844A9585A299EEB60A6` | Sandpoint Regional Cobalt Curlews | `#2F0E6C`, `#EA5794` | D2 + K | A; **Sandpoint Regional Cobalt Swordfish**; full body banking upward, bill and tail on opposing diagonals. |
| `TeamLogo_1894B47A15D14F0DB847A3B274E237F4` | Watertown Coastal Marsh Fletchers | `#141A8A`, `#2EA39B` | K; retained D2 exemplar | X; **name unchanged**; preserve hooded Fletcher, simplify facial cuts and add one compliant keyline. |
| `TeamLogo_2B1D0B55B4414D5895D30E4CE876BEDE` | Grangeville Poly Verdant Fletchers | `#CDDB0A`, `#940A4F` | D2 + K | L; **name unchanged**; exact `GRA` interlocked into a descending spearhead. |
| `TeamLogo_9F0787A83784407FBCDA8A2CDEB855FC` | Cohoes Coastal Flint Ironsides | `#AFDF5D`, `#450477` | K; retained D2 exemplar | X; **name unchanged**; preserve the ironclad prow, remove internal rivet noise and add one compliant keyline. |
| `TeamLogo_00EBE0C02B2B4988A450BB870D6D3881` | Union Maritime Meridian Ironsides | `#093909`, `#F2D864` | D2 + K | P; **Union Maritime Meridian Timberwolves**; full-body wolf twisting through a broad asymmetric S, not a head profile. |
| `TeamLogo_900EF64D9234456EAA4ED488C78B968E` | Payson A&M Cobalt Kestrels | `#999E10`, `#2B0A7F` | K; retained D2 exemplar | X; **name unchanged**; preserve kestrel head, consolidate feather cuts and add one compliant keyline. |
| `TeamLogo_30283F8523334C579A31DADB683D35CA` | San Angelo A&M Copper Riggers | `#63B2F2`, `#53271D` | K; retained D2 exemplar | X; **name unchanged**; preserve rigger profile, enlarge face/cap gaps and add one compliant keyline. |
| `TeamLogo_382E7342881F4EF29D3A47F0A984658D` | Houlton Valley Kindled Riggers | `#57DB5D`, `#750A45` | D2 + K | T; **Houlton Valley Kindled Downbursts**; one descending column splitting into two broad outward bands. |

### Batch 08 — finish current dark-surface inventory

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_A18D99F90C394357A01D2A968BC6B8C0` | Olney Meridian Wreckers | `#194111`, `#17C4C1` | D2 + K | W; **Olney Meridian Maelstroms**; three broad water-force blades around one wide eye, no scene. |
| `TeamLogo_759E356409AA496B9037952E6830FA52` | Rapid City Central Obsidian Sawyers | `#EFC38A`, `#620E4D` | K; retained D2 exemplar | X; **name unchanged**; preserve stacked timber, merge narrow seams and add one compliant keyline. |
| `TeamLogo_90369DB3A0EA40F68A405DEF59CFE630` | Somerset A&M Gale Sawyers | `#621D23`, `#968F08` | D2 + K | I; **Somerset A&M Gale Lobsters**; top-down full body with two massive claws and a blunt segmented tail. |
| `TeamLogo_41BE1B2FCD4B4DEFAE039AB87B565BD6` | Zanesville Valley Flint Wayfarers | `#3A053E`, `#239A39` | D2 + K | C; **Zanesville Valley Flint Heliostorms**; hooked coronal mass around an offset solar counter. |
| `TeamLogo_15C385432FBB438F9CC626BBB3DD8B38` | Hamilton Tidal Wreckers | `#B543EA`, `#86F9F5` | D2 + K | M; **Hamilton Tidal Drakes**; full-body wingless tide drake climbing in a corkscrew diagonal. |
| `TeamLogo_29A6A1DC04F249E78BF6D6793812399E` | Aberdeen Regional Anvil Wyverns | `#62EE49`, `#311311` | K; retained D2 exemplar | X; **name unchanged**; preserve full wyvern, widen wing/tail gaps and add one compliant keyline. |
| `TeamLogo_DD841C779B26440E8F870DEAD7D7B6C2` | Warrensburg Ember Delvers | `#795C06`, `#D4A3EB` | K, one-off | X; **name unchanged**; preserve crossed picks, reduce them to two heavy strokes and one wide crossing void. |
| `TeamLogo_16A673C38E4D4C59A0EA2D3047C8D6EA` | Lexington Regional Gale Curlews | `#B675D7`, `#272F77` | K, one-off | X; **name unchanged**; preserve curlew, consolidate bill/body and add one compliant keyline. |
| `TeamLogo_5ECE4678DCAA4412981D396E9EFACE56` | Natchez Maritime Granite Fletchers | `#081A45`, `#DF96D0` | K, one-off | X; **name unchanged**; preserve arrow-and-knife identity with two heavy masses and one open crossing. |
| `TeamLogo_E850EC8C04D84A14989E1DB67F263D24` | Geneseo State Timber Wreckers | `#889EE7`, `#431427` | K, one-off | X; **name unchanged**; preserve hook and spar, thicken the hook and remove small splinters. |
| `TeamLogo_4D74C0291A7448D9BF51CAEDFCCBEFA0` | Siloam Springs State Harbor Quarrymen | `#AEE0CD`, `#4A1C3A` | K, one-off | X; **name unchanged**; preserve quarryman, merge hat/head into one authoritative silhouette. |
| `TeamLogo_25ED4D95A91C4D9C9F3F108CCB6ED8C0` | Jerome Silver Reapers | `#E88CDC`, `#1D1D63` | K, one-off | X; **name unchanged**; preserve hooded reaper, enlarge face void and add one compliant keyline. |

### Batch 09 — remaining high-count clean duplicates

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_D0DAF2DB46BA42B9A89C815B542D85D3` | Elmira Marsh Reapers | `#E2A6AD`, `#3B4508` | K, one-off | X; **name unchanged**; preserve scythe and sheaf, consolidate stems and open the crossing. |
| `TeamLogo_545D878FD88145B0A7C2F1AC3B3E018E` | Ridgway Coastal Kiln Delvers | `#7AA1F0`, `#3B0C2B` | K, one-off | X; **name unchanged**; preserve short pick, broaden its head and add one compliant keyline. |
| `TeamLogo_4CACCDE7340F4E4F8869031E960CD31E` | Sturgis River Voyagers | `#0E3531`, `#CE11DF` | K, one-off | X; **name unchanged**; preserve storm-hood Voyager, merge hood/shoulders and widen the face void. |
| `TeamLogo_3D177C44C4CB4FEDBD0EFA4B5B8F71D6` | Winnemucca Agricultural Obsidian Wardens | `#94F998`, `#81081A` | K, one-off | X; **name unchanged**; preserve hooded Warden, simplify jaw/hood cuts and add one compliant keyline. |
| `TeamLogo_61B8C12C990B4E94B3EBDF2DFEDE632C` | Savanna Kindled Fletchers | `#E1F990`, `#3587B1` | D6 | W; **Savanna Kindled Sandstorms**; one dense dust spiral terminating in a blunt forward hook. |
| `TeamLogo_94D568ED1B87419BB8E4005F63171F1F` | Fairbury Obsidian Fletchers | `#64F708`, `#73661C` | D6 | M; **Fairbury Obsidian Salamanders**; full-body flame salamander curling around one open counter. |
| `TeamLogo_B495A8A8AAFA4736875BC4ECD8E1C5DF` | Derby Central Thunder Fletchers | `#4FC9A5`, `#77091B` | D6 | C; **Derby Central Thunder Quasars**; offset core with one broad jet on a rising diagonal. |
| `TeamLogo_DFD7F1984BC3417D894FAE36E22967DD` | Emporia Cedar Quarrymen | `#A839D0`, `#3E0F1E` | D4 | I; **Emporia Cedar Rhinoceros Beetles**; top-down armored body with one massive forward horn. |
| `TeamLogo_E7F41714098941A4B322379A36119847` | Gallipolis Poly Basalt Quarrymen | `#3DA7B8`, `#164A12` | D4 | G; **Gallipolis Poly Basalt Quakes**; one split fault block with opposing stepped faces. |
| `TeamLogo_48C82AECD9914D9B94201CF73B52E9C5` | Beverly Maritime Kiln Kestrels | `#D07CB9`, `#183904` | D4 | I; **Beverly Maritime Kiln Luna Moths**; top-down broad wings and twin tails forming a taper. |
| `TeamLogo_57E1B055AFBA4F86931D51D9B1769E46` | Glenwood Springs Valley Thunder Lodestars | `#F39090`, `#6B2A05` | D4 | T; **Glenwood Springs Valley Thunder Ice Halos**; broken halo with two angular light pillars. |
| `TeamLogo_E6308237BA64482D838B97CBAFC0B502` | Klamath Falls A&M Silver Lodestars | `#862CED`, `#A7DCE6` | D4 | L; **name unchanged**; exact `KLA` built as a broad interlocking bolt. |

### Batch 10 — medium- and low-count clean duplicates

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_5413AE6860094F809CAAAF6859C4171F` | Missoula Hollow Coopers | `#4ADED6`, `#604C1A` | D3 | B; **Missoula Hollow Thistles**; one bloom and three barbed leaves forming a compact crown. |
| `TeamLogo_5E9D2C1C55DD44DD8EDA81B10532E0B0` | Pinedale Tech Timber Goshawks | `#1ADEF4`, `#7F642E` | D3 | G; **Pinedale Tech Timber Geysers**; cutaway stone throat driving one thick angular plume. |
| `TeamLogo_D01A0E1378184053ABDE4C27F590D24E` | Lock Haven Regional Timber Goshawks | `#0A4C31`, `#849929` | D3 | A; **Lock Haven Regional Timber Barracudas**; full body in a tight lateral turn, jaws and tail opposed. |
| `TeamLogo_FF88B667115540338E70AEFC3087A0F0` | Delavan Tech Kindled Goshawks | `#741377`, `#9A9CF4` | D3 | M; **Delavan Tech Kindled Phoenixes**; front-on rising body, wings and tail forming one flame mass. |
| `TeamLogo_EACE3C20E05E4B7EB63BC0E56460E8EE` | Texarkana Tech Cedar Bastions | `#3D0551`, `#F263A8` | D3 | L; **name unchanged**; exact `TEX` locked into a low, wide block with no frame. |
| `TeamLogo_FCC35CCD6BB6432091909239ECE10D62` | Red Lodge State Tidal Bastions | `#09427C`, `#2FE97D` | D3 | C; **Red Lodge State Tidal Meteorites**; one tumbling angular body with a broad broken trail. |
| `TeamLogo_75EC4DC65A044142A91EB0F2F30D5ECA` | Holdrege Tech Meridian Voyagers | `#123027`, `#54E883` | D3 | I; **Holdrege Tech Meridian Fireflies**; top-down full body with two broad luminous wing shapes. |
| `TeamLogo_A3B3903E148F481A846900002BEB8BBB` | Dover A&M Verdant Tanners | `#4B2CD8`, `#A7E7AC` | D2 | W; **Dover A&M Verdant Dust Devils**; one broken zigzag funnel with a wide central gap. |
| `TeamLogo_C1E1DD214DB74A9BB72FE028B4AAA9C3` | Ellensburg Regional Granite Reapers | `#66261A`, `#59D1DE` | D2 | G; **Ellensburg Regional Granite Hoodoos**; two fused hoodoo columns forming a stepped tower. |
| `TeamLogo_B6783970BA3D485C815D9A62F25005C9` | Orangeburg A&M Gale Smelters | `#4D11A2`, `#E0796C` | D2 | T; **Orangeburg A&M Gale Typhoons**; three unequal wind bands tightening around one eye. |
| `TeamLogo_A317A3D847BE478B96991FE2861C9E2C` | Ely Poly Cinder Wayfarers | `#79204A`, `#92A9FC` | D2 | L; **name unchanged**; exact `ELY` as a rising asymmetrical monogram. |
| `TeamLogo_D851E5D2C6A440CF83085FA0947078EF` | Holly Springs Coastal Obsidian Smelters | `#D1F132`, `#576A24` | D2 | C; **Holly Springs Coastal Obsidian Supernovae**; one asymmetric blast ring with three heavy ruptures. |

### Batch 11 — final four

| Asset | Current team | Palette | Why | Family; proposed identity; subject |
|---|---|---|---|---|
| `TeamLogo_336989D4A28D41B4902A2A2EF0164C0D` | Adrian Silver Prospectors | `#1618B1`, `#79DCB6` | D2 | L; **name unchanged**; exact `ADR` interlocked into a broad descending wedge. |
| `TeamLogo_5EBFD5563D164AD8B0A96D19F8E15FCC` | Hillsboro Granite Ironsides | `#F448B2`, `#3D165F` | D2 | T; **Hillsboro Granite Sun Dogs**; two hard-edged flares bracketing one dark disc. |
| `TeamLogo_3CC89B98DB124AF5924F434FF612C1E7` | Elkins Central Thunder Stalkers | `#A6EA61`, `#2277D8` | D2 | P; **Elkins Central Thunder Black Bears**; full-body bear swiping across a descending diagonal. |
| `TeamLogo_2DBDBC5E18D2417BBC73C6596576F72B` | Shelbyville Poly Cinder Tanners | `#BF2B7D`, `#44F35E` | D2 | B; **Shelbyville Poly Cinder Sundews**; top-down seven hooked leaves around one bold core. |

## Per-batch acceptance and completion gates

Every batch is independently reviewable, but this completion run proceeds through all batches without an intermediate approval stop. Canonical installation waits until the complete candidate set passes. For each asset:

1. Resolve filename, stable ID, abbreviation, current team, and palette from the current manifest again at execution time; never derive `assetName` from `stableID`.
2. Produce one 256×256 8-bit RGBA candidate under the existing exact filename, with 4% transparent margin, no feature/gap below 5%, at most six filled regions, darker palette colour carrying the dominant silhouette, and one 2–2.5% keyline where needed.
3. Review grouped sheets at 20, 32, and 44 points on light and dark surfaces. Reject generic app-icon geometry, scenes, crests, repeated profiles, thin crossings, or any subject/nickname mismatch.
4. Confirm the mark is distinct in silhouette, viewpoint, pose, geometry, and negative space from every shipped and candidate mark; aim for at least 16 differing hash bits and reject below eight.
5. Record proposed name/family without changing canonical data. Installation occurs only after human approval and repository transparency, byte-budget, contrast, identity-coherence, and near-duplication checks pass.

Completion means all 112 rows are accepted or explicitly waived with a documented reason, all 52 original re-brief flags have identity-coherent outcomes (including the five batch-01 targets), all 43 current dark exceptions have passing two-surface replacements/repairs, and the recurring-motif ledger has either one approved exemplar or an explicit `None` with every occurrence replaced.
