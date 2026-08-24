# Two-Family Football Logo Set Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce 20 new football athletics marks in the approved current style: ten Equipment & Vehicle subjects and ten Regional Symbol subjects.

**Architecture:** Generate every logo independently with the built-in image-generation tool, using the uploaded image only as a style reference. Preserve the raw result, normalize a separate final PNG through the existing flat-colour pipeline, then validate every final file before assembling the mobile and 20-point review sheets.

**Tech Stack:** Built-in image generation, FFmpeg, pngquant, Python 3 with Pillow for raster QA and contact sheets.

## Global Constraints

- Exactly 20 final logo files: ten Equipment & Vehicles and ten Regional Symbols.
- Exactly 256 x 256 PNG, 8-bit RGBA.
- Transparent background and transparent edge pixels on all four sides.
- One centred subject depicting only its nickname.
- Two or three flat visible colours; no gradients, shading, texture, lighting, depth, bevels, or sketch detail.
- Maximum six connected filled regions.
- Four-percent safe area; every final margin is at least 11 pixels.
- No retained feature or gap smaller than 13 pixels.
- Heavy even dark keyline approximately five to six pixels at final size.
- The darker colour carries the outer silhouette.
- Every mark must remain recognizable after reduction to 27 x 27 pixels, approximating a 20-point display.
- The uploaded reference controls construction and visual language only; do not copy its depicted subjects.
- Do not modify application code, the canonical logo manifest, or asset catalogues.
- Leave generated review assets uncommitted until the owner explicitly requests repository integration.

---

### Task 1: Prepare the Review Workspace

**Files:**
- Create: `output/logos/two-families-20/raw/equipment-vehicles/`
- Create: `output/logos/two-families-20/raw/regional-symbols/`
- Create: `output/logos/two-families-20/equipment-vehicles/`
- Create: `output/logos/two-families-20/regional-symbols/`
- Create: `output/logos/two-families-20/qa/`

**Interfaces:**
- Consumes: approved design at `docs/superpowers/specs/2026-08-22-two-family-football-logo-set-design.md`.
- Produces: isolated raw, final, and QA destinations used by Tasks 2-6.

- [ ] **Step 1: Create the directories**

Run:

```bash
mkdir -p \
  output/logos/two-families-20/raw/equipment-vehicles \
  output/logos/two-families-20/raw/regional-symbols \
  output/logos/two-families-20/equipment-vehicles \
  output/logos/two-families-20/regional-symbols \
  output/logos/two-families-20/qa
```

Expected: exit status 0.

- [ ] **Step 2: Verify no final filenames already exist**

Run:

```bash
find output/logos/two-families-20/equipment-vehicles \
     output/logos/two-families-20/regional-symbols \
     -maxdepth 1 -type f -name '*.png'
```

Expected: no output.

### Task 2: Generate the Equipment & Vehicle Family

**Files:**
- Create: `output/logos/two-families-20/raw/equipment-vehicles/locomotive.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/biplane.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/submarine.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/bulldozer.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/snowplow.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/tugboat.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/chariot.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/cannon.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/fire-engine.png`
- Create: `output/logos/two-families-20/raw/equipment-vehicles/steamroller.png`

**Interfaces:**
- Consumes: uploaded reference image as a style reference and the subject constructions below.
- Produces: ten independent transparent raw candidates for Task 3.

- [ ] **Step 1: Generate one candidate per subject**

Use one built-in image-generation call for each subject. Apply this prompt frame verbatim, replacing `<subject>` and `<construction>` with the corresponding row:

```text
Use case: logo-brand
Asset type: original American college/pro football helmet-decal athletics mark
Input image: style reference only; copy its compact geometric construction language, not any depicted subject
Primary request: create one original <subject> football logo
Subject: only <construction>; no additional object
Style: professional flat vector-style sports identity; compact asymmetric dark silhouette; two broad interior colour masses; wide negative-space cuts; hard edges and sharp directional points
Composition: one centred subject filling the square with at least four-percent transparent safe area
Colour: exactly two or three flat visible colours; unrestricted palette; darkest colour owns the complete outer silhouette
Construction: maximum six filled regions; heavy even dark keyline; no feature or gap below five percent of canvas; readable at 20 points
Background: genuinely transparent through every edge pixel
Avoid: text, letters, numbers, wordmarks, monograms, badges, unrelated objects, gradients, shading, texture, lighting, depth, bevels, shadows, sketch lines, thin detail, photorealism, clip art, existing sports marks, watermark
```

| Subject | Construction |
|---|---|
| locomotive | a forward three-quarter boiler wedge, one broad stack, and one cowcatcher cut |
| biplane | a banking nose-first aircraft with two large wing bars and one tail cut |
| submarine | a long side-profile hull, one conning-tower block, and one stern notch |
| bulldozer | a low side profile led by one oversized blade and one continuous track mass |
| snowplow | a frontal three-quarter truck mass dominated by one wide angular plow blade |
| tugboat | a compact rising bow, one cabin block, and one stack |
| chariot | a forward-leaning body and one oversized wheel, without horse or driver |
| cannon | a low side profile with one large barrel and one wheel mass |
| fire engine | a blunt forward cab and grille silhouette with one simplified equipment block |
| steamroller | one oversized front drum joined to a compact angular cab |

Copy each generated result from its built-in output path to the exact raw filename above without deleting the generated original.

Expected: ten raw RGBA PNG candidates, one per subject.

- [ ] **Step 2: Inspect the family together**

Display all ten raw candidates. Reject and regenerate only candidates that add an object, lose the subject silhouette, copy a reference-image subject, or read as corporate clip art instead of football branding.

Expected: ten visually distinct, recognizable raw subjects.

### Task 3: Normalize and Validate Equipment & Vehicles

**Files:**
- Create: `output/logos/two-families-20/equipment-vehicles/locomotive.png`
- Create: `output/logos/two-families-20/equipment-vehicles/biplane.png`
- Create: `output/logos/two-families-20/equipment-vehicles/submarine.png`
- Create: `output/logos/two-families-20/equipment-vehicles/bulldozer.png`
- Create: `output/logos/two-families-20/equipment-vehicles/snowplow.png`
- Create: `output/logos/two-families-20/equipment-vehicles/tugboat.png`
- Create: `output/logos/two-families-20/equipment-vehicles/chariot.png`
- Create: `output/logos/two-families-20/equipment-vehicles/cannon.png`
- Create: `output/logos/two-families-20/equipment-vehicles/fire-engine.png`
- Create: `output/logos/two-families-20/equipment-vehicles/steamroller.png`

**Interfaces:**
- Consumes: ten raw Equipment & Vehicle candidates from Task 2.
- Produces: ten final house-style PNGs for the cross-family audit in Task 6.

- [ ] **Step 1: Normalize every raw candidate**

For each raw file, scale the visible mark to fit within 232 x 232 pixels, centre it on a transparent 256 x 256 canvas, quantize to transparency plus at most three visible colours without dithering, convert to RGBA, and hard-threshold alpha to 0 or 255. Preserve the raw file.

Use FFmpeg and pngquant:

```bash
for raw in output/logos/two-families-20/raw/equipment-vehicles/*.png; do
  name="$(basename "$raw")"
  base="${name%.png}"
  stage="output/logos/two-families-20/qa/${base}-equipment-stage.png"
  quant="output/logos/two-families-20/qa/${base}-equipment-quant.png"
  final="output/logos/two-families-20/equipment-vehicles/$name"
  ffmpeg -loglevel error -y -i "$raw" \
    -vf "scale=232:232:force_original_aspect_ratio=decrease:flags=lanczos,format=rgba,pad=256:256:(ow-iw)/2:(oh-ih)/2:color=0x00000000" \
    "$stage"
  pngquant --force --speed 1 --nofs --quality 0-100 --colors 4 --output "$quant" "$stage"
  ffmpeg -loglevel error -y -i "$quant" \
    -vf "format=rgba,lut=a='if(lt(val,128),0,255)'" -pix_fmt rgba "$final"
done
```

Expected: ten 256 x 256 RGBA PNGs with binary transparency.

- [ ] **Step 2: Enforce region and feature limits**

Use Pillow connected-component inspection with eight-neighbour connectivity. Recolour minor disconnected components into their most common visible boundary neighbour until the logo has no more than six filled regions. Merge any retained component whose bounding-box width or height is below 13 pixels. Never alter the largest dark outer-silhouette component.

Expected: every Equipment & Vehicle mark has at most six connected regions and no retained feature below 13 pixels.

- [ ] **Step 3: Run the family audit**

Verify size, mode, alpha values, edge transparency, margins, colour count, region count, and minimum component dimensions.

Expected: ten PASS results; no file has fewer than two or more than three visible colours, any non-zero edge alpha, a margin below 11 pixels, more than six regions, or a retained feature below 13 pixels.

### Task 4: Generate the Regional Symbol Family

**Files:**
- Create: `output/logos/two-families-20/raw/regional-symbols/volcano.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/canyon.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/mesa.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/glacier.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/waterfall.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/geyser.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/sand-dune.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/fjord.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/sea-cliff.png`
- Create: `output/logos/two-families-20/raw/regional-symbols/badlands.png`

**Interfaces:**
- Consumes: uploaded reference image as a style reference and the subject constructions below.
- Produces: ten independent transparent raw candidates for Task 5.

- [ ] **Step 1: Generate one candidate per subject**

Use one built-in image-generation call for each subject. Apply this prompt frame verbatim, replacing `<subject>` and `<construction>` with the corresponding row:

```text
Use case: logo-brand
Asset type: original American college/pro football helmet-decal athletics mark
Input image: style reference only; copy its compact geometric construction language, not any depicted subject
Primary request: create one original <subject> football logo
Subject: only <construction>; no additional object
Style: professional flat vector-style sports identity; compact asymmetric dark silhouette; two broad interior colour masses; wide negative-space cuts; hard edges and sharp directional points
Composition: one centred subject filling the square with at least four-percent transparent safe area
Colour: exactly two or three flat visible colours; unrestricted palette; darkest colour owns the complete outer silhouette
Construction: maximum six filled regions; heavy even dark keyline; no feature or gap below five percent of canvas; readable at 20 points
Background: genuinely transparent through every edge pixel
Avoid: text, letters, numbers, wordmarks, monograms, badges, unrelated objects, gradients, shading, texture, lighting, depth, bevels, shadows, sketch lines, thin detail, photorealism, clip art, existing sports marks, watermark
```

| Subject | Construction |
|---|---|
| volcano | a steep asymmetric cone with one broad crater and one lava cut |
| canyon | two interlocking cliff masses defining one wide central gorge |
| mesa | a stepped caprock silhouette with one deep undercut |
| glacier | a forward-moving ice tongue with two large crevasse cuts |
| waterfall | a hard cliff lip and one broad descending water mass |
| geyser | one forceful upward burst anchored by a low geometric base |
| sand dune | a sweeping crescent ridge with one large shadow cut |
| fjord | opposing cliff faces creating one deep descending inlet |
| sea cliff | one sheared rock face with a broad wave-shaped negative cut |
| badlands | three joined eroded spires forming one compact skyline mass |

Copy each generated result to its exact raw filename without deleting the generated original.

Expected: ten raw RGBA PNG candidates, one per subject.

- [ ] **Step 2: Inspect the family together**

Display all ten raw candidates. Reject and regenerate only candidates that add an object, become generic scenery, copy a reference-image subject, or fail to resemble a compact football mark.

Expected: ten visually distinct, recognizable raw natural-feature symbols.

### Task 5: Normalize and Validate Regional Symbols

**Files:**
- Create: all ten final PNGs under `output/logos/two-families-20/regional-symbols/` using the Task 4 filenames.

**Interfaces:**
- Consumes: ten raw Regional Symbol candidates from Task 4.
- Produces: ten final house-style PNGs for the cross-family audit in Task 6.

- [ ] **Step 1: Normalize every Regional Symbol candidate**

Run:

```bash
for raw in output/logos/two-families-20/raw/regional-symbols/*.png; do
  name="$(basename "$raw")"
  base="${name%.png}"
  stage="output/logos/two-families-20/qa/${base}-regional-stage.png"
  quant="output/logos/two-families-20/qa/${base}-regional-quant.png"
  final="output/logos/two-families-20/regional-symbols/$name"
  ffmpeg -loglevel error -y -i "$raw" \
    -vf "scale=232:232:force_original_aspect_ratio=decrease:flags=lanczos,format=rgba,pad=256:256:(ow-iw)/2:(oh-ih)/2:color=0x00000000" \
    "$stage"
  pngquant --force --speed 1 --nofs --quality 0-100 --colors 4 --output "$quant" "$stage"
  ffmpeg -loglevel error -y -i "$quant" \
    -vf "format=rgba,lut=a='if(lt(val,128),0,255)'" -pix_fmt rgba "$final"
done
```

Inspect all connected colour components with Pillow using eight-neighbour connectivity. Recolour minor disconnected components into their most common visible boundary neighbour until every logo has no more than six filled regions. Merge any retained component whose bounding-box width or height is below 13 pixels, while preserving the largest dark outer-silhouette component.

Expected: ten 256 x 256 RGBA final PNGs.

- [ ] **Step 2: Run the family audit**

Verify all ten files are 256 x 256 RGBA; alpha contains only 0 and 255; all four edge-alpha maxima are 0; every visible bounding-box margin is at least 11 pixels; each logo contains two or three visible RGB colours, no more than six eight-connected filled regions, and no retained component narrower or shorter than 13 pixels.

Expected: ten PASS results.

### Task 6: Cross-Family Review and Mobile Delivery

**Files:**
- Create: `output/logos/two-families-20/two-families-20-phone-preview.png`
- Create: `output/logos/two-families-20/qa/20pt-review.png`

**Interfaces:**
- Consumes: all 20 final PNGs from Tasks 3 and 5.
- Produces: the final user-review presentation and complete audit result.

- [ ] **Step 1: Verify the exact final file set**

Expected filenames are the ten Equipment & Vehicle names from Task 3 and the ten Regional Symbol names from Task 4. Exclude `raw/`, `qa/`, and preview files from the final-logo count.

Expected: exactly 20 final logo PNGs, with no missing or unexpected final names.

- [ ] **Step 2: Build the 20-point audit sheet**

Reduce every final logo to 27 x 27 pixels with Lanczos, enlarge that result with nearest-neighbour scaling for inspection, label it outside the logo, and arrange all 20 on a portrait review sheet.

Expected: every nickname remains identifiable from silhouette and dominant internal cuts.

- [ ] **Step 3: Build the phone preview**

Create a 1024-pixel-wide portrait contact sheet with two clearly labelled family sections and large cards. Labels remain outside the logo assets.

Expected: a legible phone-scrolling preview showing all 20 marks at high fidelity.

- [ ] **Step 4: Perform the final audit**

Run the Task 3 technical checks across all 20 final logo files and visually inspect both review sheets.

Expected: `20/20 PASS`; no duplicate subjects, reference-subject copies, generic corporate marks, or unreadable 20-point silhouettes.

- [ ] **Step 5: Report the deliverables**

Provide clickable paths to both family folders, the phone preview, and the 20-point audit. Report the final prompt set and confirm that built-in image generation was used.

Expected: the user can open every individual PNG and both review sheets from a phone or desktop.
