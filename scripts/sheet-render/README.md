# Sheet render script

Renders a `*-v4.dc.html` reference sheet headless and screenshots it, for
inspection during authoring — this is not part of the shipped app or the
Swift build.

```
export NODE_PATH=/opt/node22/lib/node_modules   # Playwright is installed globally here
node render_sheet.js ../../tokens-v4.dc.html /tmp/tokens-v4.png
```

Recipe matches `docs/proofs/README.md`: 1600 pt wide, full content height,
screenshotted at 1x. The committed proofs additionally crop/downscale to
1280 px; that step is cosmetic and not reproduced here.
