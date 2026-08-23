# Regional Symbols and Land Predators Football Logo Design

## Objective

Add two separately reviewed families to the approved football-logo project:

- **Batch 2:** ten Regional Symbol marks already defined in the original two-family design.
- **Batch 3:** ten new terrestrial Predator marks chosen for varied silhouettes and no subject overlap with the uploaded examples.

The deliverable adds exactly 20 independent 256 x 256 PNG logos. Phone contact sheets and QA sheets are auxiliary artifacts and do not count toward that total.

## Shared Visual Direction

Every mark must match the approved reference sheet's construction language without copying any depicted subject:

- polished college/pro American-football identity rather than a pictogram or illustration;
- compact asymmetric silhouette with forward motion;
- refined curved and angular contours;
- one dominant dark outer mass with broad interlocking interior colour shapes;
- deliberate negative-space cuts and sharp directional points;
- two or three flat visible inks with unrestricted team colours;
- no text, letters, numbers, badges, secondary objects, gradients, shading, texture, lighting, depth, bevels, or sketch detail.

The exact subject must remain recognizable at approximately 27 x 27 pixels. Defining anatomy takes priority over decorative motion marks.

## Batch 2: Regional Symbols

1. **Volcano** — steep asymmetric cone, broad crater, and one lava cut.
2. **Canyon** — two interlocking cliff masses defining a wide central gorge.
3. **Mesa** — stepped caprock silhouette with one deep undercut.
4. **Glacier** — forward-moving ice tongue with two broad crevasse cuts.
5. **Waterfall** — hard cliff lip and one broad descending water mass.
6. **Geyser** — forceful upward burst anchored by a low geometric base.
7. **Sand Dune** — sweeping crescent ridge with one large shadow cut.
8. **Fjord** — opposing cliff faces creating a deep descending inlet.
9. **Sea Cliff** — sheared rock face with a broad wave-shaped negative cut.
10. **Badlands** — three joined eroded spires forming one compact skyline mass.

## Batch 3: Land Predators

The roster deliberately spans mammals, reptiles, and arthropods so the family does not become ten similar animal-head profiles.

1. **Cougar** — forward-thrust three-quarter head with swept ears and one cheek slash.
2. **Grizzly Bear** — heavy charging head with broad brow, short muzzle, and one shoulder cut.
3. **Wolverine** — low aggressive head with compact ears, flared jaw, and one neck slash.
4. **Spotted Hyena** — sloped-neck head with rounded ears, blunt muzzle, and one mane cut; no spots smaller than the house minimum.
5. **Jackal** — narrow forward-facing head with tall ears and a sharp muzzle wedge.
6. **Komodo Dragon** — low side-profile head with heavy jaw, swept neck, and one tongue or throat cut.
7. **King Cobra** — raised hood and angular head forming one compact S-curve; no detached body coil.
8. **Scorpion** — forward pincers, compact body, and one arcing stinger silhouette with no tiny legs.
9. **Tarantula** — compact frontal body with eight legs merged into four broad paired angular masses.
10. **Praying Mantis** — triangular head and two folded striking forelegs forming one sharp compact silhouette.

Predator final filenames are fixed as `cougar.png`, `grizzly-bear.png`, `wolverine.png`, `spotted-hyena.png`, `jackal.png`, `komodo-dragon.png`, `king-cobra.png`, `scorpion.png`, `tarantula.png`, and `praying-mantis.png`.

## Production Rules

Each subject receives its own built-in image-generation call with the approved uploaded sheet supplied as a style reference. Generated high-resolution results are inspected before reduction; weak or ambiguous subjects are regenerated rather than redrawn as primitive polygons.

Final PNG requirements:

- exactly 256 x 256, 8-bit RGBA;
- genuinely transparent background and fully transparent canvas edges;
- one centred nickname-only subject with at least 11 pixels of safe margin;
- two or three intended flat inks;
- at most six deliberate filled regions;
- no meaningful retained feature or gap below 13 pixels;
- visually consistent dark keyline around five to six pixels;
- smooth antialiased boundary pixels are allowed for fidelity, but interior inks remain flat;
- no gradients, shading, texture, lighting, depth, or incidental raster fragments.

## Review and Delivery Sequence

1. Generate, normalize, audit, and display all ten Regional Symbols on a 1080-pixel-wide phone sheet.
2. Continue to Land Predators after the Regional Symbols review is accepted.
3. Generate, normalize, audit, and display all ten Land Predators on a separate phone sheet.
4. Run a final cross-batch audit and create a combined phone sheet plus a 27-pixel recognition sheet.
5. Commit only the new logo assets, QA sheets, and approved design/plan documents on `codex/two-family-logo-batches`, then push that branch.

## Output Layout

- `output/logos/two-families-20/regional-symbols/` — ten Batch 2 finals.
- `output/logos/two-families-20/raw/regional-symbols/` — selected Batch 2 sources.
- `output/logos/land-predators-10/` — ten Batch 3 finals.
- `output/logos/land-predators-10/raw/` — selected Batch 3 sources.
- `output/logos/land-predators-10/qa/` — Predator QA artifacts.
- `output/logos/batch-2-regional-symbols-phone-preview.png` — Batch 2 mobile sheet.
- `output/logos/batch-3-land-predators-phone-preview.png` — Batch 3 mobile sheet.
- `output/logos/regional-and-predators-phone-preview.png` — combined final mobile sheet.

Application code, the canonical logo manifest, and asset catalogues remain unchanged.
