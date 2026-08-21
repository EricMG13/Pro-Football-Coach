# Team mark review — batch 01

Generated with the built-in image generation tool. The exact nickname concepts and two-colour palettes come from `Tools/TeamLogos/manifest.json`.

## Final prompt system

Each manifest prompt was normalized into the `logo-brand` use case with these shared constraints:

- one nickname subject centered in the middle 92% of a square canvas;
- genuine RGBA transparency with clear edge pixels on all four sides;
- the two manifest hex colours as exact flat fills, with the darker colour carrying the silhouette;
- at most six large filled regions, no feature or negative gap below 5% of the canvas, and one even keyline only when needed;
- immediate readability at 20 points;
- no text, real-team resemblance, scene, landscape, mockup, gradient, shading, texture, depth, lighting, or watermark.

The generated sources were mechanically fitted to a 4% safe area, resized to 256 × 256, and snapped to the exact two manifest colours while preserving alpha antialiasing. Shipped assets were not overwritten; approval is required before installation.
