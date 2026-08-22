# Claude Design refinement prompt

You are reviewing an existing original American-sports logo set. Improve only marks that need improvement; keep an approved source when a new version is not clearly better.

## Inputs

- Read `manifest/manifest.json` for the stable UUID, family, concept, palette, and exact filename.
- Use `previews/contact-sheet-light.png` and `previews/contact-sheet-dark.png` for set-level distinctiveness.
- Use `previews/size-proof-light.png` and `previews/size-proof-dark.png` for compact readability.

## Per-logo brief

For each selected record, create one replacement PNG using the existing `assetName` and `filename`.

- Canvas: exactly 1024 × 1024, transparent background and transparent edge pixels.
- Style: bold, simplified professional or minor-league sports identity; clean hard edges and a strong silhouette.
- Palette: the manifest's `primaryColorHex` and `secondaryColorHex`; neutral black or white only for separation.
- Concept: honor the stored family and concept while allowing any outer silhouette.
- Legibility: the mark must survive 20 pt, 32 pt, and 44 pt rendering on light and dark surfaces.

## Hard exclusions

No words, letters, initials, numbers, slogans, uniforms, league marks, watermarks, mockups, photorealism, gradients that muddy at small sizes, or resemblance to any real team, school, conference, trophy, bowl, or professional league identity.

Do not change stable IDs, filenames, asset names, team names, abbreviations, family assignments, palettes, or app code. Real city/town names are generic location descriptors; they do not authorize a real school identity. Bowl badges use only a host place plus a generic descriptor such as `Classic`, `Showcase`, `Championship`, or `Football Classic`.

## Return format

Return changed PNGs with their exact existing filenames. For each changed mark, include a small JSON decision record using `review-template.json` and explain the visual improvement in one sentence. If no improvement is justified, return `keep` and leave the source PNG unchanged.
