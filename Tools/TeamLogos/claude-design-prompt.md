# Starting prompt — team mark generation

Paste this into a surface that can generate images. Claude Design itself is a design-file surface
and is instructed not to draw imagery, so it holds the board and the review, not the artwork.

---

## The job

Draw 166 original athletics team marks, one per team. Flat vector artwork, one 256 × 256 PNG each,
transparent background.

## Read first

- **The board:** https://claude.ai/design/p/277d85ec-1bb6-4331-9bb9-475e4a188018?file=Team+Marks+Commission.dc.html
  Every team's public name, nickname, motif family, both palette hexes, its brief, and the exact
  output filename.
- **Source of truth:** `Tools/TeamLogos/manifest.json` — `stableID`, `assetName`, `filename`,
  `primaryColorHex`, `secondaryColorHex`, `family`, `concept`, `prompt`.

## Why the last set was replaced

Two defects, both in the brief rather than the drawing. Do not reintroduce either.

1. **The briefs described scenes.** "A bold falcon shaped by the Heath landscape of Altus" gets you
   a landscape with a bird in it. The app draws these at 20 points far more often than at 44, and at
   20 points a scene is mush.
2. **The briefs never looked at the nickname.** They were written from the programme's region, so
   the Silver Kestrels carried a compass roundel. A third of the league wore a mark for a thing it
   is not named after.

Both are fixed in the briefs you are working from. Every brief now names its own team's nickname,
and a test in the repo fails if one drifts off.

## House style — applies to all 166

A single subject filling the frame. Two or three flat colours only. No gradient, no shading, no
texture, no depth, no lighting, no outline sketch. Every shape has a hard edge and one heavy dark
keyline of even weight. Bold geometric simplification: few large shapes, wide negative space,
angular cuts, sharp points. Detail that would vanish at 20 points is left out on purpose. Centred in
a square canvas on a transparent background.

**Not:** a scene, a landscape, a horizon, scenery behind the subject, a photograph, a 3D render, an
emblem crowded with small parts, watercolour, airbrush, drop shadow, bevel, glow, halftone, or a
mock-up on a shirt or a helmet.

**Colours:** the card's two hex values as the dominant flats. Black or white only where a keyline or
a separation needs it.

The six motif families are compositions, not subjects. `animalCreature` is a head-and-shoulders
mark, `originalCharacter` a head in profile, `equipmentVehicle` an object square-on, `regionalSymbol`
a landform reduced to flat planes, `framedEmblem` a device filling a shield, roundel, pennant,
hexagon or diamond, `abstractMotion` the subject cut to its sharpest angles and swept into motion.
The subject is always the nickname.

## Output contract

- Exactly 256 × 256, PNG, 8-bit RGBA, transparent edge pixels on all four sides.
- The card's **exact** filename. Never rename, never invent an asset, never put two teams on one
  mark.
- Under 192 KB per file; the whole catalogue under 20 MB. Flat artwork lands far below both.
- Judge every mark at 20 points first. If it does not read there, it is not finished.

## Legal — non-negotiable

No words, letters, initials, numerals, dates, slogans, competition marks, uniforms or watermarks.
Do not reference or resemble any real school, club, conference, trophy or event identity, and do not
reproduce any real team's combination of colour and shape. Real city names in team names are generic
location descriptors and are not permission to reproduce a real school's identity.

Do not change stable IDs, filenames, asset names, team names, abbreviations, motif families,
palettes, or any app code. Those are reconciled after the visual review.

## How to work

Twelve at a time. After each batch, lay the marks out at 20, 32 and 44 points on both a light and a
dark surface, and stop for approval before starting the next.

Make the **first batch** cover six different nicknames across all six families — that puts the whole
system on screen early, while changing direction is still cheap.

## Accept or reject

A mark is accepted only when all of these hold together:

- the silhouette reads at 20 points;
- it depicts its own team's nickname and nothing else;
- two flat colours plus a keyline, no third treatment;
- the palette matches the card;
- the edges are transparent;
- there is no lettering anywhere.

If a candidate is weaker than the mark currently shipped, say so and keep the source. A replacement
is only worth making when it improves silhouette, small-size clarity, palette discipline and
distinctiveness together.

## Return

The changed PNGs under their exact filenames, plus one decision record each:

```json
{
  "assetName": "TeamLogo_<stable-id-without-dashes>",
  "decision": "replace",
  "notes": "one sentence on the visual improvement",
  "changes": ["silhouette", "small-size clarity"]
}
```

Once the PNGs land in `Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets/<assetName>.imageset/`,
`swift run SimTests --team-logo-manifest` and the six `--team-logo-assets <family>` lanes check size,
bytes, transparency, family balance, nickname coherence and near-duplication.
