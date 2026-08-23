# Starting prompt — duplicate team-mark remake

Paste this into a surface that can generate images. The review pages hold the target inventory and visual decisions; the image surface creates the artwork.

---

## The job

Remake the 92 duplicate occurrences identified across the 166-mark athletics catalogue. Preserve the strongest single exemplar of each of the 48 recurring motifs; replace the remaining occurrences with genuinely different designs drawn from five new families.

Produce one flat-vector 256 × 256 PNG per target on a transparent background. These are review candidates: do not overwrite shipped assets or canonical team data until approved.

## Read first

- **Repetition review:** `artifacts/team-mark-review/repetition-review.html`
- **Design and quality review:** `artifacts/team-mark-review/design-quality-review.md`
- **Source of truth:** `Tools/TeamLogos/manifest.json` — `stableID`, `assetName`, `filename`, `name`, `abbreviation`, `primaryColorHex`, `secondaryColorHex`, `concept`, and `prompt`

The review identifies the recurring motifs, including palisades, shield bosses, beacon braziers, fletched arrows, harriers, repeated human profiles, birds, tools, and fortification devices.

## Why these marks are being replaced

The catalogue is technically coherent but visually repetitive. Of 166 marks, 140 belong to 48 recurring motifs. After one strongest exemplar of each motif is retained, 92 duplicate occurrences remain.

Colour changes alone are not enough. Every replacement must introduce a different central idea, silhouette, pose, geometry, and negative-space pattern.

## House style — applies to every replacement

Safe area: 4 per cent. No feature or gap under 5 per cent of the canvas. One keyline at 2 to 2.5 per cent. At most six filled regions. The darker team colour carries the silhouette. **20 pt is the design size, not the smallest size.**

Use one subject filling the frame. Use two or three flat colours only. No gradient, shading, texture, depth, lighting, or sketch outline. Every shape has a hard edge and one heavy dark keyline of even weight. Use a few large shapes, wide negative space, angular cuts, and sharp points. Remove every detail that disappears at 20 points. Centre the mark on a transparent square canvas.

**Do not create:** a scene, landscape, horizon, background scenery, photograph, 3D render, crowded emblem, watercolour, airbrush, drop shadow, bevel, glow, halftone, uniform, shirt mock-up, or helmet mock-up.

## The five new families

The families are distinct composition systems. Do not reuse the old human-profile, generic bird-head, square-on tool, framed crest, palisade, shield-boss, or crossed-implement templates.

### 1. Predators

A powerful predator reduced to one unmistakable attacking silhouette. Use a head, full-body coil, crouch, pounce, talon, jaw, or hunting posture according to the species. Vary viewpoint and body language; do not make every predator another side-profile head.

Possible subjects include big cats, bears, wolves, sharks, crocodilians, raptors, snakes, deep-sea hunters, and prehistoric predators. Do not reproduce the catalogue's existing bird-head template.

### 2. Letterforms and monograms

A custom athletics letterform using only the exact team abbreviation or a deliberate subset of its letters. The letters themselves form the dominant silhouette through interlocking geometry, cuts, counters, and negative space.

Use no words, slogans, dates, numbers, or extra typography. Do not imitate a real school's monogram. Repeated abbreviations must receive clearly different construction, silhouette, and letter interaction.

### 3. Extreme weather

One weather phenomenon isolated as a compact symbol rather than a scene. Possible subjects include a tornado funnel, cyclone eye, lightning rupture, supercell rotation, hail impact, blizzard spiral, dust devil, heat burst, ice fracture, or thunderhead crown.

No horizon, landscape, cloud scene, rain background, or collection of tiny weather elements. The phenomenon must read as one central mass at 20 points.

### 4. Mythical creatures

One original mythical creature shown through a strong head, body, wing, coil, claw, horn, or mask silhouette. Possible subjects include dragons, griffins, manticores, hydras, basilisks, thunderbirds, sea serpents, phoenixes, oni-like masks, and invented regional creatures.

Avoid generic heraldry and existing sports-logo poses. Do not place the creature inside a shield, roundel, pennant, hexagon, or diamond.

### 5. Celestial and space phenomena

One celestial form reduced to a bold athletics mark. Possible subjects include an eclipse, comet, nova, meteor, crescent, orbit, aurora fold, solar flare, black-hole ring, planetary storm, or starburst.

Do not create a space scene or star field. Use one dominant form with broad negative space and no small decorative stars.

## Team identity and naming

For predator, weather, mythical, and celestial families, the proposed nickname must match the depicted subject. A team may receive a proposed new nickname or public name when necessary. Record the proposal; do not alter canonical data during the visual-review stage.

For the letterform family, use the current manifest abbreviation unless the decision record explicitly proposes a new abbreviation.

Stable IDs, asset names, and filenames never change.

## Colours

Use the manifest's two palette hexes as the default dominant flats. If the existing combination fails contrast or creates a poor result, propose a replacement palette in the decision record rather than silently changing canonical data.

Black or white may appear only when required for the keyline or separation. The finished outer edge must separate cleanly on both light and dark surfaces.

## Output contract

- Exactly 256 × 256 PNG, 8-bit RGBA.
- Transparent edge pixels on all four sides; no checkerboard baked into the image and no nonzero edge-alpha specks.
- Use the target's exact filename and asset name.
- Never combine two teams in one mark.
- Under 192 KB per file; the full catalogue remains under 20 MB.
- Judge every mark at 20 points first. If it does not read there, it is unfinished.

## Legal — non-negotiable

No words, dates, slogans, numerals, competition marks, uniforms, or watermarks. Letters are permitted **only** in the letterform and monogram family and must use the team's approved abbreviation or approved subset.

Do not reference or resemble any real school, club, conference, trophy, or event identity. Do not reproduce a real team's combination of colour, letter construction, mascot pose, or silhouette.

## How to work

Work twelve targets at a time, beginning with the highest-repeat motifs. The first batch must cover all five new families so the complete replacement system is visible early.

After each batch, create grouped review sheets at 20, 32, and 44 points on both light and dark surfaces. Stop for approval before installing or continuing to the next batch.

## Accept or reject

A replacement is accepted only when all of these hold together:

- its silhouette reads at 20 points;
- it no longer repeats the old motif's central design grammar;
- it is visibly distinct from every other mark in the batch;
- its subject matches its proposed nickname, or it uses the approved abbreviation as a letterform;
- it uses two or three flat colours plus one consistent keyline;
- it separates on light and dark surfaces;
- its palette is matched or its proposed palette change is recorded;
- its outer edges are genuinely transparent;
- it contains no prohibited lettering or other legal conflict.

If a candidate is weaker than the shipped mark, keep the source. A replacement is worthwhile only when it improves silhouette, small-size clarity, palette discipline, design consistency, and distinctiveness together.

## Return

Return candidate PNGs under their exact filenames, grouped review sheets, and one decision record per target:

```json
{
  "assetName": "TeamLogo_<stable-id-without-dashes>",
  "decision": "replace",
  "newFamily": "predator | letterform | extremeWeather | mythicalCreature | celestialPhenomenon",
  "proposedName": "optional revised public team name",
  "proposedAbbreviation": "optional revised abbreviation",
  "proposedPrimaryColorHex": "optional replacement hex",
  "proposedSecondaryColorHex": "optional replacement hex",
  "notes": "one sentence describing how the duplicate motif was eliminated",
  "changes": ["silhouette", "small-size clarity", "distinctiveness"]
}
```

Do not install a candidate until it has passed the grouped visual review and the repository's size, transparency, contrast, nickname-coherence, and near-duplication checks.
