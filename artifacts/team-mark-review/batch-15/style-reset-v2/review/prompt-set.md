# Batch 15 image-generation prompt set

Mode: built-in `imagegen`, one image call per team mark.

Accepted house-style references:

- `batch-01/candidates/TeamLogo_0213C958E1554E938E36AA606F8A670A.png`
- `batch-01/candidates/TeamLogo_837E01370ECF4655AA236668ED84AA03.png`
- `batch-01/candidates/TeamLogo_25EDC7BB3D5F46E4B8C0B1B22D5D190C.png`
- `batch-01/candidates/TeamLogo_6CAF0BE740EB49459E4BDB5ABDD40D8A.png`

The team name, subject, family rule, and exact colors below were injected from
`batch-15/rebrand-plan.json` for each separate call.

```text
Use case: logo-brand.
Create one production-candidate sports team mark for "{proposedName}".
Subject: {subject}.
Family composition rule: {familyRule}
The four reference images are accepted house-style marks. Match their extreme
geometric restraint, broad flat shapes, friendly abstract character, and instant
small-size readability. Do not copy their subjects or compositions.

HARD CONSTRUCTION CONTRACT:
- exactly one isolated subject centered on a fully transparent canvas; no scene,
  ground, horizon, frame, shield, circle badge, crest, or background tile
- exactly two uniform flat colors: dark anchor {primaryColorHex} and bright accent
  {secondaryColorHex}; no other visible color
- the dark anchor must form the continuous outer silhouette and a consistent
  roughly 5px keyline at final 256px
- at most six filled regions total; use as few as possible
- every intentional feature, cutout, and gap must be at least 13px wide at final 256px
- no tiny spots, dots, scales, veins, repeated texture, or decorative fragments
- hard vector-like edges; no gradient, shading, lighting, glow, blur, texture,
  depth, shadow, white highlight, black halo, gray, or transparency inside the subject
- recognizable by silhouette at 20pt; bold enough for 32pt and 44pt
- no letters, numerals, words, monograms, or resemblance to a real team logo
- export as RGBA PNG with genuinely transparent outer background and clear edge pixels

Preserve the specific subject geometry. This is a flat symbol, not an illustration.
```

Targeted correction calls kept the same contract and references while explicitly
locking the filled-region count and removing the failed read: Downbursts (tree),
Geysers (lightning), Fireweed (wheat), Aurora (crystals), Glaciers (shield),
Perihelions (comet), plus excess-detail reductions for Horseshoe Crabs,
Lanternfish, Thistles, Dragonflies, Pitcherplants, Mantises, Morels, Gar, Cicadas,
Sundews, and Sawfish.

Generated sources are retained in `generated/` and `generated-v4/` through
`generated-v7/`. Review candidates were mechanically normalized to exact plan
colors, a 10px minimum safe area, transparent edges, and a dark outer keyline.
