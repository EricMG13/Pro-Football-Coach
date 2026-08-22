# Claude Design — Team Logo Refinement Handoff

This package contains the approved 166-logo canonical set for visual refinement. It is a design handoff, not an app-code change: preserve the mapping and return replacement artwork only when a mark materially improves.

## Source of truth

- Naming implementation: `66b95f3` (`feat: standardize generic team naming`)
- Canonical world seed: `20_260_812`
- Manifest: `manifest/manifest.json`
- Stable mapping: `manifest/TeamLogoCatalog.generated.swift`
- Canonical visual specification: `references/canonical-team-logo-set-design.md`

The set contains 166 approved records:

| Family | Count |
| --- | ---: |
| animalCreature | 28 |
| regionalSymbol | 28 |
| equipmentVehicle | 28 |
| originalCharacter | 28 |
| framedEmblem | 27 |
| abstractMotion | 27 |

## What is included

- `assets/TeamLogos.xcassets/` — all 166 source PNGs and image-set metadata.
- `manifest/manifest.json` — complete record, prompt, palette, family, stable UUID, and approval data.
- `manifest/logo-index.csv` — review-friendly one-row-per-logo index.
- `manifest/SHA256SUMS.txt` — file integrity list.
- `manifest/TeamLogoCatalog.generated.swift` — stable UUID → asset-name mapping for reference only.
- `previews/contact-sheet-light.png` and `previews/contact-sheet-dark.png` — full-set review boards.
- `previews/size-proof-light.png` and `previews/size-proof-dark.png` — compact/medium/large readability samples.
- `references/canonical-team-logo-set-design.md` — product and visual direction.
- `references/team-name-conventions-design.md` — approved real-place, generic descriptor, and bowl naming rules.
- `references/team-name-and-trademark-screen.md` — research-backed product screen and legal limitations.
- `research/Safe Generic Alternative.txt` — supplied naming research, included as research rather than legal advice.

## Refinement contract

Refine the artwork, not the identity contract.

- Keep `stableID`, `assetName`, `filename`, team name, abbreviation, family, and palette unchanged.
- Return a replacement with the exact existing filename. Do not rename files or create a second logo for a team.
- Keep the output a 1024 × 1024 PNG with transparent edge pixels.
- Preserve the assigned family and concept. A family may use any outer silhouette; it need not be a shield, circle, or mascot head.
- Use the manifest's two colours as the dominant palette. Neutral black or white is allowed only for separation.
- Keep the mark original, bold, simplified, and legible at 20/32/44 pt.
- No words, letters, initials, numbers, slogans, uniforms, league marks, watermarks, mockups, photorealism, or real-team trade dress.
- Do not introduce a real school, professional club, conference, trophy, or official event identity.

If a candidate is weaker than the approved source, keep the source. A refinement is accepted only when it improves silhouette, small-size clarity, palette discipline, family fit, and distinctiveness together.

## Place and postseason naming guardrail

Team names use real U.S. city/town names with state abbreviations plus generic institution or club descriptors. College forms include `University`, `State University`, `A&M University`, and generic technical, research, agricultural, institute, and college variants. Pro forms use place plus a generic plural nickname. That is a generic location convention, not permission to reproduce a real school identity.

Projected bowl badges must use a host place plus a generic descriptor such as `Classic`, `Showcase`, `Championship`, or `Football Classic`. Do not use real bowl names or near-miss names intended to evoke them. The engine's single safe helper is `NameGrammar.bowlName(place:using:)`.

The supplied `Safe Generic Alternative.txt` is useful research, not legal clearance. Final originality, common-law, and trade-dress review remains human counsel work.

## Review handback

Return only changed PNGs plus a small decision file if useful:

```json
{
  "assetName": "TeamLogo_<stable-id-without-dashes>",
  "decision": "keep" | "replace" | "reject",
  "notes": "Short visual reason",
  "changes": ["silhouette", "palette", "small-size clarity"]
}
```

Do not edit the app, generated catalogue, stable UUIDs, or manifest approval fields as part of a visual pass. Those are reconciled after the design review.
