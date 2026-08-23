# Regional Symbols and Land Predators Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add twenty high-fidelity football athletics marks: ten Regional Symbols and ten Land Predators, with separate phone review sheets and a final combined deliverable.

**Architecture:** Generate every subject independently with the approved uploaded logo sheet as a style reference. Select and preserve the best high-resolution candidate, use a fidelity-preserving flat-ink/antialiased-edge finishing pass, then audit each final 256px PNG and build one phone preview per family. The existing Equipment & Vehicles outputs remain untouched.

**Tech Stack:** Built-in image generation, Pillow, FFmpeg, GitNexus change detection, git.

## Global Constraints

- Work only in `/Users/ericguei/Documents/Pro-Football-Coach/.worktrees/two-family-logo-batches` on `codex/two-family-logo-batches`.
- Reference image: `/tmp/codex-remote-attachments/01a02a6e-6b5c-7a40-a0e7-9cfb204a78af/6236B3F6-7329-44FF-8332-976BC2216757/1-Photo-1.jpg`; use it as style reference only, never copy a depicted subject.
- Every final asset is exactly 256 x 256, 8-bit RGBA with a genuinely transparent background and alpha zero on every canvas edge pixel.
- Every mark depicts only its named nickname; no text, badges, field, ball, scenery, character, or secondary object.
- Use two or three intended flat inks. Smooth antialiased boundary pixels are permitted; no gradients, shading, texture, lighting, depth, bevels, or sketch effects.
- Use polished college/pro American-football identity construction: compact asymmetric silhouette, refined curves and angular cuts, broad interlocking colour masses, a dominant dark exterior silhouette, and a visually even five-to-six-pixel dark keyline.
- Maintain at least an 11px transparent safe margin, no meaningful feature or gap under 13px, and no more than six deliberate thresholded filled regions.
- Every subject must be nameable from an unlabeled 27 x 27px render on a light background.
- Keep only the new assets, QA sheets, and plan/spec documents in commits. Do not change application code, the canonical logo manifest, or asset catalogues.
- Stage explicit paths only. Run GitNexus `detect_changes` before every commit and push only after the final approved review.

## Shared Generation Prompt Frame

Use this structure once for every distinct subject, replacing `<subject>` and `<construction>`:

```text
Use case: logo-brand
Asset type: original college/pro American-football helmet decal and midfield identity
Input image: uploaded sheet is a style reference only; match its polish, compact custom silhouette, contour rhythm, broad layered flat masses, dark outline, and sharp negative-space cuts; never copy any depicted subject
Primary request: one original <subject> football logo
Subject: only <construction>; no secondary object
Visual priority: literal defining anatomy must remain instantly nameable at 27px, then add energetic forward motion and sophisticated interlocking curves
Composition: centered isolated subject with generous transparent safe area
Colour: exactly two or three flat ink colours, darkest ink owns the full exterior silhouette
Construction: maximum six broad deliberate regions, heavy even dark keyline, no feature/gap below 13px at 256px
Background: truly transparent
Avoid: text, letters, numbers, wordmarks, badges, ball, field, scenery, people, gradients, glow, shadows, shading, texture, lighting, bevels, clip art, existing sports marks, watermark
```

---

### Task 1: Produce and Review the Regional Symbols Family

**Files:**
- Create: `output/logos/two-families-20/raw/regional-symbols/{volcano,canyon,mesa,glacier,waterfall,geyser,sand-dune,fjord,sea-cliff,badlands}.png`
- Create: `output/logos/two-families-20/regional-symbols/{volcano,canyon,mesa,glacier,waterfall,geyser,sand-dune,fjord,sea-cliff,badlands}.png`
- Create: `output/logos/two-families-20/qa/regional-symbols-27px-review.png`
- Create: `output/logos/batch-2-regional-symbols-phone-preview.png`

**Interfaces:**
- Consumes: the shared constraints and prompt frame above.
- Produces: ten final Regional Symbol PNGs plus raw selections, audit data, and a phone preview for Task 3.

- [ ] **Step 1: Create one high-fidelity candidate for each exact subject**

Use one built-in generation call for every row and pass the reference image as `referenced_image_paths`. Preserve the selected generator original before making a project copy.

| Filename | Construction |
|---|---|
| `volcano.png` | steep asymmetric cone, broad crater, one lava cut |
| `canyon.png` | two interlocking cliff masses defining one wide central gorge |
| `mesa.png` | stepped caprock silhouette and one deep undercut |
| `glacier.png` | forward-moving ice tongue with two large crevasse cuts |
| `waterfall.png` | hard cliff lip and one broad descending water mass |
| `geyser.png` | forceful upward burst anchored by one low geometric base |
| `sand-dune.png` | sweeping crescent ridge with one large shadow cut |
| `fjord.png` | opposing cliff faces creating one deep descending inlet |
| `sea-cliff.png` | sheared rock face with one broad wave-shaped negative cut |
| `badlands.png` | three joined eroded spires forming one compact skyline mass |

Expected: ten distinct, label-free raw candidates with no copied reference subject.

- [ ] **Step 2: Finish each selected candidate without flattening its contour quality**

At high resolution, remove any baked checkerboard/background, map the art to two or three flat inks, remove incidental fragments, and consolidate interior masks to no more than six deliberate regions. Preserve the refined outer contour; do not replace it with primitive polygons. Downsample once to 256 x 256 with Lanczos antialiasing, keep canvas edges alpha zero, and save both the selected raw and final output paths.

Expected: finals have smooth edges, flat interiors, 11px+ margins, and a dark five-to-six-pixel exterior keyline.

- [ ] **Step 3: Audit exact file properties and recognition**

For every final, use Pillow to assert size `(256, 256)`, mode `RGBA`, edge-alpha maxima `0`, visible alpha bounding-box margins `>= 11`, two or three intended interior inks, `<= 6` thresholded regions, and no retained component bounding dimension `< 13`. Create `qa/regional-symbols-27px-review.png` by rendering each final at 27 x 27 with Lanczos, enlarging it for inspection, and placing labels outside each asset.

Expected: all ten numeric checks pass and every subject is nameable from the unlabeled 27px row.

- [ ] **Step 4: Build and inspect the Batch 2 mobile preview**

Create a 1080px-wide portrait PNG with ten large cards on a light neutral background, the logo centered in each card, and a label outside the mark. Save it as `output/logos/batch-2-regional-symbols-phone-preview.png`. Inspect the family together beside the reference and reject/rework any generic scenery or ambiguous silhouette.

Expected: a phone-readable family sheet whose marks look like football identities rather than landscape illustrations.

- [ ] **Step 5: Commit the reviewed Regional Symbols assets**

Run GitNexus `detect_changes` with the linked worktree and confirm no application symbols/processes changed. Stage only the explicit raw, final, QA, and phone-preview paths. Commit:

```text
assets: add regional symbols logo batch

Co-Authored-By: Codex Opus 4.8 <noreply@anthropic.com>
```

Expected: a clean worktree and one asset-only commit.

---

### Task 2: Produce and Review the Land Predators Family

**Files:**
- Create: `output/logos/land-predators-10/raw/{cougar,grizzly-bear,wolverine,spotted-hyena,jackal,komodo-dragon,king-cobra,scorpion,tarantula,praying-mantis}.png`
- Create: `output/logos/land-predators-10/{cougar,grizzly-bear,wolverine,spotted-hyena,jackal,komodo-dragon,king-cobra,scorpion,tarantula,praying-mantis}.png`
- Create: `output/logos/land-predators-10/qa/land-predators-27px-review.png`
- Create: `output/logos/batch-3-land-predators-phone-preview.png`

**Interfaces:**
- Consumes: the shared prompt frame and finalization rules from Task 1.
- Produces: ten final Land Predator PNGs and separate review artifacts for Task 3.

- [ ] **Step 1: Generate exact land-predator silhouettes**

Use one built-in generation call per subject with the reference style image. Use these subject constructions exactly:

| Filename | Construction |
|---|---|
| `cougar.png` | forward-thrust three-quarter head with swept ears and one cheek slash |
| `grizzly-bear.png` | heavy charging head with broad brow, short muzzle, and one shoulder cut |
| `wolverine.png` | low aggressive head with compact ears, flared jaw, and one neck slash |
| `spotted-hyena.png` | sloped-neck head, rounded ears, blunt muzzle, one mane cut; no small spots |
| `jackal.png` | narrow forward-facing head with tall ears and a sharp muzzle wedge |
| `komodo-dragon.png` | low side-profile head with heavy jaw, swept neck, and one tongue or throat cut |
| `king-cobra.png` | raised hood and angular head forming one compact S-curve; no detached coil |
| `scorpion.png` | forward pincers, compact body, one arcing stinger, and no tiny legs |
| `tarantula.png` | frontal body with eight legs merged into four broad paired angular masses |
| `praying-mantis.png` | triangular head and two folded striking forelegs in one sharp compact silhouette |

Expected: broad variety in silhouette families, with no tiger, marten, raptor, otter, heron, or wyvern overlap from the uploaded examples.

- [ ] **Step 2: Apply the same high-fidelity flat-ink finish**

Follow Task 1's high-resolution cleanup and one-pass Lanczos downsampling process. Keep the dark outer silhouette intact, retain only two or three flat inks and no more than six deliberate regions, and remove any feature/gap under 13px without turning the subject into a generic animal icon.

Expected: ten 256px final PNGs that are both faithful to the reference style and exactly nameable at 27px.

- [ ] **Step 3: Run the Predator audit and make the phone preview**

Run the exact Task 1 image checks against all ten Predator finals. Build `qa/land-predators-27px-review.png`, then make a 1080px-wide two-column card sheet at `output/logos/batch-3-land-predators-phone-preview.png`. Inspect on light and dark backgrounds and regenerate any silhouette that loses the named animal at 27px.

Expected: 10/10 technical pass and 10/10 label-free 27px recognition pass.

- [ ] **Step 4: Commit the reviewed Predator assets**

Run GitNexus `detect_changes`, stage only the explicit Predator raw/final/QA/preview paths, then commit:

```text
assets: add land predators logo batch

Co-Authored-By: Codex Opus 4.8 <noreply@anthropic.com>
```

Expected: a clean worktree with the existing batches untouched.

---

### Task 3: Create the Cross-Batch Review and Push

**Files:**
- Create: `output/logos/regional-and-predators-phone-preview.png`
- Create: `output/logos/qa/regional-and-predators-27px-review.png`

**Interfaces:**
- Consumes: the twenty final PNGs and per-family QA from Tasks 1–2.
- Produces: the final combined review assets and remote branch update.

- [ ] **Step 1: Verify exact final asset inventory**

Require exactly ten final PNGs under `output/logos/two-families-20/regional-symbols/` and exactly ten final PNGs directly under `output/logos/land-predators-10/`. Exclude `raw/`, `qa/`, and preview PNGs. Confirm all required filenames from Tasks 1–2 exist and there are no extras.

Expected: exactly 20 final new marks.

- [ ] **Step 2: Build the combined 27px and phone review sheets**

Create `output/logos/qa/regional-and-predators-27px-review.png` with labelled enlarged 27px reductions of all twenty finals. Create `output/logos/regional-and-predators-phone-preview.png` as a 1080px-wide portrait sheet with separately labelled Regional Symbols and Land Predators sections. Inspect both at actual mobile scale.

Expected: all twenty names are recoverable and both families have consistent high-fidelity football identity treatment.

- [ ] **Step 3: Run the final audit, commit the combined QA, and push**

Repeat the Task 1 numerical audit across all twenty new final marks. Run GitNexus `detect_changes`; the expected impact is zero changed application symbols and zero affected processes. Stage only the two combined QA sheets, commit:

```text
assets: add regional and predator review sheets

Co-Authored-By: Codex Opus 4.8 <noreply@anthropic.com>
```

Then push `codex/two-family-logo-batches` to its configured remote with upstream tracking if needed.

Expected: the branch is clean, all commits are pushed, and no user WIP is staged.
