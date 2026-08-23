# Duplicate Team-Mark Batch 01 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, normalize, validate, and present twelve replacement team-mark candidates for the duplicate palisade and shield-boss occurrences approved in batch 01.

**Architecture:** Artwork is generated offline with one built-in image-generation call per target, then mechanically normalized into an isolated review directory. A single batch validation pass checks the manifest contract, PNG structure, transparency, byte budget, palette, contrast evidence, and perceptual distance before creating the six required review sheets and decision records. Shipped assets and canonical team data remain untouched.

**Tech Stack:** Built-in image generation, Python 3.14, Pillow 12, JSON, the existing manifest and TeamLogoTests perceptual-hash rules.

## Global Constraints

- Work only under `artifacts/team-mark-review/duplicate-remake/batch-01/`, except for this plan.
- Never modify `Tools/TeamLogos/manifest.json` or `Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets` during candidate review.
- Generate exactly one team mark per image-generation call and use the target's exact manifest asset name and filename.
- Request high-fidelity final-review artwork and regenerate anatomy, letter construction, proportion, or edge-quality defects before normalization.
- Final candidates are exactly 256 × 256, 8-bit RGBA PNGs under 192 KB with zero alpha on every canvas-edge pixel.
- Keep the mark inside the middle 92%, use two manifest colours plus at most one neutral separator, and retain flat hard-edged artwork.
- Judge at 20 points first; review sheets render 20, 32, and 44 points as 60, 96, and 132 device pixels at 3×.
- Use no words, dates, slogans, numerals, uniforms, watermarks, real-team references, or copied trade dress. Only `WEB`, `GOS`, and `LAP` may contain letters.
- Require perceptual-hash distance greater than the repository threshold of 8 against every shipped mark and every other candidate; manually review any distance below 16.
- Do not install or continue to batch 02 before owner approval.

---

### Task 1: Freeze the Current Target Inventory

**Files:**
- Read: `Tools/TeamLogos/manifest.json`
- Read: `artifacts/team-mark-review/duplicate-remake/batch-01/README.md`

**Interfaces:**
- Consumes: the twelve approved asset names in the batch brief.
- Produces: an in-memory ordered list of the matching manifest records.

- [ ] **Step 1: Resolve and verify all target records**

Run a read-only Python assertion that the brief contains twelve target asset names, each resolves exactly once in the manifest, each filename is `<assetName>.png`, and the family allocation is 3 predator / 3 letterform / 2 extreme weather / 2 mythical / 2 celestial.

Expected: `12 targets resolved; manifest contract OK`.

- [ ] **Step 2: Create isolated output directories**

Run:

```bash
mkdir -p artifacts/team-mark-review/duplicate-remake/batch-01/candidates
mkdir -p artifacts/team-mark-review/duplicate-remake/batch-01/review
```

Expected: both directories exist and shipped asset paths remain unchanged.

### Task 2: Generate Twelve Independent Source Marks

**Files:**
- Read: `artifacts/team-mark-review/duplicate-remake/batch-01/README.md`
- Create: twelve temporary built-in image-generation outputs

**Interfaces:**
- Consumes: exact team name, abbreviation, colours, new family, and candidate brief from the approved README.
- Produces: one transparent source PNG per target for normalization.

- [ ] **Step 1: Invoke the image-generation skill**

Use built-in mode, `logo-brand`, one call per target, and genuine transparency. Do not use the CLI fallback.

- [ ] **Step 2: Generate each source with the shared prompt contract**

Use the following literal target fields, then append the shared constraints below.

| Asset | Primary request | Palette and letter constraint |
|---|---|---|
| `TeamLogo_613F7CE6DAB84D80ABBEDCD2C886A10C` | Create one original mark for Camden Shale Novas: an asymmetric four-arm nova with an offset diamond counter, no regular star badge or enclosing frame. | `#7F2A1F`, `#DC5EED`; no letters. |
| `TeamLogo_6E0B4A63CA6848CD8F9D61626462A2B8` | Create one original mark for Davenport Agricultural Gale Tornadoes: one angular tornado funnel built from three broad tapering bands, no cloud, horizon, or rain. | `#429A32`, `#420A29`; no letters. |
| `TeamLogo_2DF9A813792342959AD954DBC61EC67C` | Create one original mark for Lakeview Regional River Gars: a full-body alligator gar in a top-down S-turn, with a broad striking snout and hooked tail. | `#E193AD`, `#1C1957`; no letters. |
| `TeamLogo_95192BA1E5B645A494ED5D44E395EA15` | Create one original mark for Millinocket Coastal Flint Sea Serpents: a full-body sea serpent descending in an open C-coil, with one horned jaw and one broad dorsal fin. | `#0505D1`, `#59E8D0`; no letters. |
| `TeamLogo_80E65D18532E4D94839D9F2E6DBB81DB` | Create one original mark for Ogallala Coastal Obsidian Solar Flares: an offset solar core driving one broad hooked flare through open negative space, with no ring or star field. | `#6D40CE`, `#A6D7E2`; no letters. |
| `TeamLogo_954025C43FE546BAAC1F62CF09765A0F` | Create one original interlocking letterform mark for Webster City Coastal Meridian Tanners using exactly the letters `WEB` as one asymmetric wedge: W base, E cuts, and B lobes, with no frame or extra type. | `#D080EF`, `#2B320C`; render exactly `WEB`. |
| `TeamLogo_612FD3E74D0142E9A010EF4B485965F7` | Create one original mark for Abingdon Tidal Kelpies: a full-body kelpie leaping in a tight diagonal curl, with fin-like mane and tail and no water scene. | `#D1F68E`, `#840DA5`; no letters. |
| `TeamLogo_1046C3255F27488E8D1FEFF7F0D1AD41` | Create one original interlocking letterform mark for Goshen Shale Bulwarks using exactly the letters `GOS` as one stepped angular glyph with a hooked G, central O counter, and diagonal S, with no roundel. | `#ECE3A2`, `#87591C`; render exactly `GOS`. |
| `TeamLogo_E8D76C2DF87A4503A1B5B80193FC4F5B` | Create one original mark for Ketchikan Meridian Orcas: a full-body orca banking downward in a crescent attack posture, with no waves or side-profile head template. | `#A6E2C6`, `#240953`; no letters. |
| `TeamLogo_911BB08E62454715A15EA6851AD2F303` | Create one original interlocking letterform mark for Lapeer State Amber Wheelwrights using exactly the letters `LAP` as one rising asymmetric spike: L spine, A counter, and P upper mass, with no frame. | `#7790E9`, `#10321C`; render exactly `LAP`. |
| `TeamLogo_C0A6908AFD4D408AB0BE70A2298C0B70` | Create one original mark for Moberly Thunder Supercells: one compact supercell rotation built from three broad staggered masses and one lightning-shaped negative rupture. | `#6C1456`, `#D1F490`; no letters. |
| `TeamLogo_4D2BD12BF3B746FE8863CD6973A66EB1` | Create one original mark for Red Wing State Cobalt Crocodiles: a crocodile lunging toward the viewer, with a top-down body and one wide negative-space jaw, not a side profile. | `#72DFC5`, `#1A4210`; no letters. |

Append these shared lines verbatim to every target request, replacing only the palette sentence with that target's literal palette row:

```text
Use case: logo-brand
Asset type: fictional athletics team-mark review candidate
Style/medium: high-fidelity professional vector-style logo mark; exact anatomy or letter construction; two team colours; optically balanced hard edges; minimal geometric construction
Composition/framing: one centered subject filling the middle 92% of a square transparent canvas; strong silhouette at 20 points
Color palette: use the target's two literal hex colours as the dominant flat fills; the darker team colour carries the main silhouette; one neutral white separator only if required for the dark review surface
Constraints: at most six filled regions; no feature or negative gap below 5% of the canvas; one even 5–6 px keyline/separator; obey the target row's exact letter constraint; genuinely transparent background
Avoid: the old palisade, shield-boss, human-profile, generic bird-head, square-on tool, framed crest, or crossed-implement grammar; gradients; shading; texture; depth; lighting; scenery; horizon; mockup; photograph; 3D; extra text; numerals; watermark; real-team resemblance
```

Expected: twelve separate source images, each depicting only its approved subject.

- [ ] **Step 3: Inspect and selectively regenerate**

Reject any source with an opaque background, wrong subject, extra letters, fragile detail, more than one subject, prohibited old grammar, or obvious real-team resemblance. Iterate with one targeted correction while repeating all invariants.

Expected: twelve visually acceptable source images before mechanical normalization.

### Task 3: Normalize Candidates Without Touching Shipped Assets

**Files:**
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/candidates/<exact manifest filename>` for twelve targets

**Interfaces:**
- Consumes: the twelve accepted source PNGs and manifest palettes.
- Produces: twelve final candidate PNGs satisfying the output contract.

- [ ] **Step 1: Normalize each accepted source with Pillow**

For each image: convert to RGBA; reject missing alpha; clear alpha values at or below 8; crop to the nonzero-alpha bounds; fit the art and any required separator inside a 10 px margin; resize with Lanczos; snap opaque artwork pixels to the nearest of the two manifest colours; retain at most one white separator; and save with `optimize=True` under the exact manifest filename.

Expected: twelve 256 × 256 RGBA candidates in `candidates/` and no writes under the shipped asset catalogue.

- [ ] **Step 2: Run structural assertions**

Assert for every candidate: PNG format, RGBA mode, 256 × 256 dimensions, all four complete edge rows/columns have alpha zero, alpha bounding box has at least 10 px clearance, file size is below 196,608 bytes, and every fully opaque non-neutral RGB value is one of the two manifest colours.

Expected: `12/12 candidate PNG contracts passed`.

### Task 4: Run Distinctness, Contrast, and Identity Review

**Files:**
- Read: all twelve candidates
- Read: all 166 shipped marks

**Interfaces:**
- Consumes: normalized candidates and repository comparison marks.
- Produces: acceptance/rejection findings used by `decisions.json`.

- [ ] **Step 1: Run the repository-equivalent perceptual-distance check**

Composite each image on black, area-resample to 9 × 8, build the 192-bit per-channel horizontal difference hash used by `TeamLogoTests.swift`, and compare every candidate with all shipped marks and all other candidates.

Expected: no pair at distance 8 or below. Inspect pairs from 9 through 15 manually; regenerate a candidate when the shared silhouette is material rather than incidental.

- [ ] **Step 2: Inspect both review grounds at 20 points**

Composite each mark at 60 device pixels on `#F3F0E8` and `#10151E`. Reject marks whose silhouette, key subject, approved letters, or outer separation disappears on either ground.

Expected: all twelve subjects and the three exact monograms read without enlargement.

- [ ] **Step 3: Check identity and legal constraints**

Confirm each non-letterform subject matches its proposed public name, each letterform contains only its exact approved abbreviation, no candidate repeats another batch silhouette, and no candidate recalls a recognizable real team combination of palette, construction, pose, or outline.

Expected: twelve accepted review candidates or targeted regeneration of each failure.

### Task 5: Create Decision Records and Review Sheets

**Files:**
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/decisions.json`
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/review/batch-01-20pt-light.png`
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/review/batch-01-20pt-dark.png`
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/review/batch-01-32pt-light.png`
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/review/batch-01-32pt-dark.png`
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/review/batch-01-44pt-light.png`
- Create: `artifacts/team-mark-review/duplicate-remake/batch-01/review/batch-01-44pt-dark.png`

**Interfaces:**
- Consumes: final accepted candidates and approved batch briefs.
- Produces: twelve schema-compliant decisions and six grouped visual-review sheets.

- [ ] **Step 1: Write `decisions.json`**

Write one record per target using its exact manifest `assetName`, `decision: "replace"`, approved `newFamily`, proposed public name only where changed, and a one-sentence note explaining how the palisade or shield-boss grammar was eliminated. Use `changes: ["silhouette", "small-size clarity", "distinctiveness"]` unless a recorded palette proposal is genuinely required.

Expected: JSON parses, contains twelve unique records, and every asset name matches a candidate filename.

- [ ] **Step 2: Render the six review sheets**

Use a consistent 4 × 3 grid. Each card includes the proposed nickname or approved abbreviation and family label. Render candidates at 60, 96, and 132 device pixels on the exact light and dark grounds without scaling the sheet after composition.

Expected: six 1120 × 620 RGB PNG review sheets with twelve cards each.

- [ ] **Step 3: Re-run the complete candidate contract**

Repeat structural, palette, distance, identity, and JSON assertions after creating the final sheets.

Expected: `batch-01 validation passed: 12 candidates, 12 decisions, 6 review sheets`.

### Task 6: Final Review Handoff

**Files:**
- Read: all final batch outputs
- Modify: `artifacts/team-mark-review/duplicate-remake/batch-01/README.md`

**Interfaces:**
- Consumes: completed batch outputs and validation results.
- Produces: a review-ready batch that remains uninstalled.

- [ ] **Step 1: Record generation method and validation summary**

Append the built-in generation method, final prompt contract, validation result, and any intentional palette proposal to the batch README. Do not mark owner approval or installation.

- [ ] **Step 2: Run required pre-completion reviews**

Because this task changes artifacts and documentation but no production code, skip rewrite-tournament. Run the repository-required confidence-review against every uncertain visual or validation point, patch confirmed issues, and run GitNexus `detect_changes(scope: "compare", base_ref: "main")` before committing.

- [ ] **Step 3: Commit only batch output paths and stop**

Stage the plan and `artifacts/team-mark-review/duplicate-remake/batch-01/` explicitly, commit them without unrelated workspace changes, present the review sheets and candidate paths, and stop for owner approval before installation or batch 02.
