# Duplicate team-mark remake — batch 01

Status: candidate generation and targeted small-size hardening complete; awaiting cross-batch approval; not approved for installation.

This batch exhausts the duplicate occurrences of the catalogue's two most repeated motifs. It preserves one exemplar of each motif and remakes the other twelve marks across all five approved replacement families.

## Retained exemplars

- Palisade: `TeamLogo_25EDC7BB3D5F46E4B8C0B1B22D5D190C` — Waurika Maritime Iron Palisades. Its compact shield and three driven stakes give it the strongest 20-point silhouette among the seven palisades.
- Shield boss: `TeamLogo_46D018BB3BD9422A91A91971012E8834` — Nacogdoches Poly Verdant Bulwarks. Its broad circular mass and heavy bilateral straps remain clearest at 20 points among the seven shield bosses.

## Approved target briefs

Stable IDs, asset names, filenames, abbreviations, and canonical colours come directly from `Tools/TeamLogos/manifest.json` and remain unchanged.

| Asset | Current team | Palette | New family | Candidate brief | Proposed public name |
|---|---|---|---|---|---|
| `TeamLogo_613F7CE6DAB84D80ABBEDCD2C886A10C` | Camden Shale Palisades (`CAM`) | `#7F2A1F`, `#DC5EED` | `celestialPhenomenon` | An asymmetric four-arm nova with an offset diamond counter; no regular star badge or enclosing frame. | Camden Shale Novas |
| `TeamLogo_6E0B4A63CA6848CD8F9D61626462A2B8` | Davenport Agricultural Gale Lamplighters (`DAV`) | `#429A32`, `#420A29` | `extremeWeather` | One angular tornado funnel built from three broad tapering bands; no cloud, horizon, or rain. | Davenport Agricultural Gale Tornadoes |
| `TeamLogo_2DF9A813792342959AD954DBC61EC67C` | Lakeview Regional River Palisades (`LAK`) | `#E193AD`, `#1C1957` | `predator` | A full-body alligator gar in a top-down S-turn, with a broad striking snout and hooked tail. | Lakeview Regional River Gars |
| `TeamLogo_95192BA1E5B645A494ED5D44E395EA15` | Millinocket Coastal Flint Wainwrights (`MIL`) | `#0505D1`, `#59E8D0` | `mythicalCreature` | A full-body sea serpent descending in an open C-coil, with one horned jaw and one broad dorsal fin. | Millinocket Coastal Flint Sea Serpents |
| `TeamLogo_80E65D18532E4D94839D9F2E6DBB81DB` | Ogallala Coastal Obsidian Wheelwrights (`OGA`) | `#6D40CE`, `#A6D7E2` | `celestialPhenomenon` | An offset solar core driving one broad hooked flare through open negative space; no ring or star field. | Ogallala Coastal Obsidian Solar Flares |
| `TeamLogo_954025C43FE546BAAC1F62CF09765A0F` | Webster City Coastal Meridian Tanners (`WEB`) | `#D080EF`, `#2B320C` | `letterform` | The exact letters `WEB` interlock as one asymmetric wedge: W base, E cuts, and B lobes; no frame or extra type. | — |
| `TeamLogo_612FD3E74D0142E9A010EF4B485965F7` | Abingdon Tidal Bulwarks (`ABI`) | `#D1F68E`, `#840DA5` | `mythicalCreature` | A full-body kelpie leaping in a tight diagonal curl, with fin-like mane and tail; no water scene. | Abingdon Tidal Kelpies |
| `TeamLogo_1046C3255F27488E8D1FEFF7F0D1AD41` | Goshen Shale Bulwarks (`GOS`) | `#ECE3A2`, `#87591C` | `letterform` | The exact letters `GOS` form one stepped angular glyph with a hooked G, central O counter, and diagonal S; no roundel. | — |
| `TeamLogo_E8D76C2DF87A4503A1B5B80193FC4F5B` | Ketchikan Meridian Bulwarks (`KET`) | `#A6E2C6`, `#240953` | `predator` | A full-body orca banking downward in a crescent attack posture; no waves or side-profile head template. | Ketchikan Meridian Orcas |
| `TeamLogo_911BB08E62454715A15EA6851AD2F303` | Lapeer State Amber Wheelwrights (`LAP`) | `#7790E9`, `#10321C` | `letterform` | The exact letters `LAP` form one rising asymmetric spike: L spine, A counter, and P upper mass; no frame. | — |
| `TeamLogo_C0A6908AFD4D408AB0BE70A2298C0B70` | Moberly Thunder Bulwarks (`MOB`) | `#6C1456`, `#D1F490` | `extremeWeather` | One compact supercell rotation built from three broad staggered masses and one lightning-shaped negative rupture. | Moberly Thunder Supercells |
| `TeamLogo_4D2BD12BF3B746FE8863CD6973A66EB1` | Red Wing State Cobalt Bulwarks (`RED`) | `#72DFC5`, `#1A4210` | `predator` | A crocodile lunging toward the viewer, with a top-down body and one wide negative-space jaw; no side profile. | Red Wing State Cobalt Crocodiles |

Family allocation: three predators, three letterforms, two extreme-weather marks, two mythical creatures, and two celestial phenomena.

## Production contract

- Treat these as high-fidelity final review candidates: regenerate anatomy, letter construction, proportion, or edge-quality defects instead of relying on downscaling to hide them.
- Generate one isolated subject per target using the approved brief and exact manifest palette.
- Normalize to 256 × 256, 8-bit RGBA, a 4% safe area, transparent edge pixels, and less than 192 KB.
- Keep features and negative gaps at or above 5% of the canvas, use at most six filled regions, and use one even 2–2.5% keyline only where needed.
- Reject candidates that fail at 20 points, repeat the old motif grammar, conflict with the nickname or approved abbreviation, or resemble a real team identity.
- Return candidates under exact manifest filenames, `decisions.json`, and six grouped review sheets at 20, 32, and 44 points on light and dark surfaces.
- Do not alter shipped assets or canonical team data before review approval.

## Generation record

Mode: built-in image generation, followed by image-to-image simplification where the first pass carried illustration-level detail. Every final prompt framed the mark as an original American-football identity for helmet decals, midfield graphics, broadcasts, scoreboards, and 20-point UI use. The shared final prompt required one compact subject, an aggressive athletics silhouette, the exact manifest palette, broad negative space, a heavy dark keyline, genuine transparency, and no real-team reference, scene, mock-up, frame, gradient, or shading.

Target-specific final prompt subjects were: four-arm nova (`CAM`), three-band tornado (`DAV`), S-turn alligator gar (`LAK`), open-coil sea serpent (`MIL`), hooked solar flare (`OGA`), interlocked `WEB`, leaping kelpie (`ABI`), interlocked `GOS`, crescent-breach orca (`KET`), interlocked `LAP`, rotating supercell (`MOB`), and three-quarter crocodile lunge (`RED`). `LAK`, `MIL`, `OGA`, `ABI`, `KET`, `MOB`, and `RED` received dedicated simplification passes. Grouped 20-point review then replaced the weak `CAM`, `LAK`, `OGA`, `WEB`, and `ABI` selections; `LAK` received one final v4 edit to remove repeated scale cuts while preserving its broad snout, eye, four fins, and bright dark-surface mass.

## Candidate package

- `final-candidates/`: twelve exact-name 256 × 256 RGBA PNGs using only the manifest palette and transparent outer edges.
- `final-review/`: grouped 20, 32, and 44 point sheets on light and dark surfaces.
- `decisions.json`: one review-only replacement decision per target.

Mechanical checks pass for dimensions, RGBA mode, transparent pixels on all four edges, minimum 4% canvas margin, exact palette membership, the 192 KB per-candidate limit, light/dark surface contrast, and perceptual near-duplication against all 166 shipped marks plus the other candidates. No shipped logo, manifest entry, or canonical team record was changed.
