#!/usr/bin/env python3
"""Repair contrast and baked light backgrounds for user-flagged curated logos."""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageOps

if __package__:
    from Tools.TeamLogos.research_and_recolor_curated_logos import ARTIFACTS, markdown_report, recolor_preserving_shape
else:
    from research_and_recolor_curated_logos import ARTIFACTS, markdown_report, recolor_preserving_shape

CATALOG_PATH = ARTIFACTS / "tournament-catalog.json"
CURATION_PATH = ARTIFACTS / "final-166-curation.json"
REPORT_PATH = ARTIFACTS / "color-research/football-color-sample-100.json"
OUTPUT_ROOT = ARTIFACTS / "final-166-colors/remediated"

# One high-contrast palette from the existing 100-team study per user-flagged mark.
PALETTE_SAMPLE_INDEX = {
    "291dc796b97fa5049020990c95c62a742883f8f02fdb0408b56f3f20ec6e2d03": 63,
    "42dfa4bd4bdf8b880fae2d22159a6788416a36c3ce57ff0a11e5b623d611b2ab": 12,
    "2fb1174af027caa5d3c64687826fc9b1e2652f228b231a60fb7a88b9d4dd7046": 18,
    "4870414d159134c0133c30f972db1562fea2f58cbeca37a46b0ba5a710d819a3": 21,
    "ac45a402d755db97e12bfaf8ea1a5f2b581ff21c73918a9c6881aac3b622ca47": 27,
    "1180b416b83ccb131ae4a3c2b17435779443b54e126eb447e1ee3d46026ef426": 28,
    "8fbb35dcb185807c2c179336725e0a4e95921e113d7e895a7143bdd2c7e3d4a0": 32,
    "9f5a451b826bac5b4109e37918d7abab6f4cce14f5659608c7ef79168fe39ed6": 33,
    "8c519f5fd86187e8a236a94d0cbfcac48fb6921f0da8dd6e582ed907734046a9": 27,
    "0eff5b3e900c4c574d628f944112c77c4d23792b8905dc9ca86bba630e741f8d": 39,
    "3475d19c117d95a9a1dff33d878370736d33304dfbb4fe32f8cf85bc26d63dc8": 43,
    "5818a2bdb8f7796bd099cd26a719ad1ef2d2b47d3fca7d7d2bbae7cbadcb45c5": 46,
    "1218585dfe5d478bd45e53346ac39bf94b03b0609df256510148d76bcd7063f8": 49,
    "19a4fea85c955cd476d3911066c60ca5db8d65b5c49a737a73baafda2dbcffdd": 50,
    "2b13f193550a37526c709aecc171f118e6622dc0acc21728b9150c3782b31e68": 51,
    "2ee505e43ef469a8f6132e2dbb7ce603ec9b8cb50284ebc636c2b37a751fdd05": 53,
    "30b5767ef3badf32a97086f15fc85c4b688a70d178aaf680740dc68810ad3238": 54,
    "40bda80c556dbb848778c38aeccee08a853a557ba3adf87a011386991d2ef378": 55,
    "5c3fabe169af7c73c6d8989cfd87af0183f92186f8751c61ee5df6216d3efb5c": 56,
    "769a26c17cd84d9c5955cdea6e07c424e1b93944ba5cc04256006090d3511892": 60,
    "852c35cd842413d85ae766b4e9f015af34ddb7a16477c95244078f80ada39277": 62,
    "abc928f8ec12f63312772ce45ec1beebc79cee8a56d03e8668c7dd88b1743a00": 63,
    "b2d2751b4b0af46fa4e3ad906b9884e4d342c3c9f6c6c6f0b75d5936670f53d9": 64,
    "c33cd82aefb39ccc9856deb7036d6ebd09e9c0be19b7faaf6606a7c242997cba": 65,
    "e13eb18965b8d02edb002c5931510d16d4d786c890b992834508f52decbed23a": 66,
    "ed73518aa566397bea31282da43ba77fa3d68078c216ff39d4035459f9f2db38": 69,
    "fb043ca18d390b0c1475da6b172d7f1bd8c72bf2c47f26a67075f588feaff663": 72,
    "final-fill:03-giraffe": 75,
    "b9142a8ca3c664e706b2a22dac2d6eac8ee0f52e4b5047969a48765c8191fc31": 17,
    "97f929f34b64344911984c18bd43416e70d8cb9471c7139a73ac460bff401dcc": 10,
    "final-fill:17-split-prism": 35,
    "final-fill:19-signal-spire": 47,
    "final-fill:21-orbit-knot": 38,
    "final-fill:22-fracture-crest": 41,
    "final-fill:24-delta-coil": 48,
}

INVERT_LUMINANCE_KEYS = {
    "291dc796b97fa5049020990c95c62a742883f8f02fdb0408b56f3f20ec6e2d03",
    "8c519f5fd86187e8a236a94d0cbfcac48fb6921f0da8dd6e582ed907734046a9",
    "97f929f34b64344911984c18bd43416e70d8cb9471c7139a73ac460bff401dcc",
}
REFINED_SOURCE_PATHS = {
    "final-fill:17-split-prism": "final-166-colors/refined-source/17-split-prism.png",
    "final-fill:19-signal-spire": "final-166-colors/refined-source/19-signal-spire.png",
    "final-fill:21-orbit-knot": "final-166-colors/refined-source/21-orbit-knot.png",
    "final-fill:22-fracture-crest": "final-166-colors/refined-source/22-fracture-crest.png",
    "final-fill:24-delta-coil": "final-166-colors/refined-source/24-delta-coil.png",
}


def light_neutral(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    return alpha == 255 and min(red, green, blue) >= 212 and max(red, green, blue) - min(red, green, blue) <= 20


def remove_light_edge_background(source: Image.Image) -> tuple[Image.Image, int]:
    """Make only edge-connected light neutral pixels transparent; retain enclosed highlights."""
    image = source.convert("RGBA")
    if image.getextrema()[3][0] < 255:
        return image, 0

    width, height = image.size
    pixels = image.load()
    pending: list[int] = []
    removed_count = 0

    def enqueue(index: int) -> None:
        nonlocal removed_count
        y, x = divmod(index, width)
        pixel = pixels[x, y]
        if not light_neutral(pixel):
            return
        red, green, blue, _ = pixel
        pixels[x, y] = (red, green, blue, 0)
        pending.append(index)
        removed_count += 1

    for x in range(width):
        enqueue(x)
        enqueue((height - 1) * width + x)
    for y in range(1, height - 1):
        enqueue(y * width)
        enqueue(y * width + width - 1)

    while pending:
        index = pending.pop()
        y, x = divmod(index, width)
        for next_y in range(max(0, y - 1), min(height, y + 2)):
            for next_x in range(max(0, x - 1), min(width, x + 2)):
                if next_x != x or next_y != y:
                    enqueue(next_y * width + next_x)
    return image, removed_count


def fit_transparent_square(image: Image.Image, size: int = 1024, padding: int = 72) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("cannot fit an empty image")
    cropped = image.crop(bbox)
    scale = min((size - 2 * padding) / cropped.width, (size - 2 * padding) / cropped.height)
    resized = cropped.resize((round(cropped.width * scale), round(cropped.height * scale)), Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (size, size))
    result.alpha_composite(resized, ((size - resized.width) // 2, (size - resized.height) // 2))
    return result


def write_repaired(
    source_path: Path,
    output_path: Path,
    palette: dict[str, str],
    *,
    invert_luminance: bool = False,
    refined: bool = False,
) -> tuple[str, int]:
    with Image.open(source_path) as source:
        cleaned, removed = remove_light_edge_background(source)
    if invert_luminance:
        alpha = cleaned.getchannel("A")
        cleaned = ImageOps.invert(cleaned.convert("RGB")).convert("RGBA")
        cleaned.putalpha(alpha)
    if refined:
        if source_path.name == "24-delta-coil.png":
            cleaned.putalpha(cleaned.getchannel("A").point(lambda alpha: 255 if alpha >= 240 else 0))
        cleaned = fit_transparent_square(cleaned)
    result = recolor_preserving_shape(cleaned, palette["primary"], palette["secondary"])
    if result.size != cleaned.size:
        raise ValueError(f"repair changed dimensions: {source_path}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    result.save(output_path, format="PNG", optimize=True)
    return hashlib.sha256(output_path.read_bytes()).hexdigest(), removed


def main() -> None:
    catalog = json.loads(CATALOG_PATH.read_text())
    curation = json.loads(CURATION_PATH.read_text())
    report = json.loads(REPORT_PATH.read_text())
    source_candidates = {candidate["id"]: candidate for candidate in catalog["candidates"]}
    source_fills = {fill["id"]: fill for fill in curation.get("sourceFillCandidates", [])}
    samples = report["samples"]
    assignments = {assignment["targetID"]: assignment for assignment in report["assignments"]}
    repaired = []

    for fill in curation["fillCandidates"]:
        target_key = fill.get("sourceCandidateID") or fill["id"]
        sample_index = PALETTE_SAMPLE_INDEX.get(target_key)
        if sample_index is None:
            continue
        palette = samples[sample_index - 1]
        source_entry = source_candidates.get(target_key) or source_fills.get(target_key)
        if source_entry is None:
            raise ValueError(f"missing original source for {target_key}")
        original_source_path = ARTIFACTS / source_entry["imagePath"]
        refined_source = REFINED_SOURCE_PATHS.get(target_key)
        source_path = ARTIFACTS / refined_source if refined_source else original_source_path
        filename = f'{len(repaired) + 1:02d}-{Path(source_path).name}'
        relative_output = Path("final-166-colors/remediated") / filename
        digest, removed = write_repaired(
            source_path,
            ARTIFACTS / relative_output,
            palette,
            invert_luminance=target_key in INVERT_LUMINANCE_KEYS,
            refined=refined_source is not None,
        )
        fill.update({
            "sha256": digest,
            "imagePath": relative_output.as_posix(),
            "palette": {key: palette[key] for key in ("league", "team", "primary", "secondary")},
        })
        if not fill.get("sourceCandidateID"):
            fill["sourceImagePath"] = original_source_path.relative_to(ARTIFACTS).as_posix()
        if refined_source:
            fill["refinementSourceImagePath"] = refined_source
        assignments[fill["id"]] = {
            "targetID": fill["id"],
            "sourceImagePath": original_source_path.relative_to(ARTIFACTS).as_posix(),
            "outputImagePath": relative_output.as_posix(),
            "paletteLeague": palette["league"],
            "paletteTeam": palette["team"],
            "primary": palette["primary"],
            "secondary": palette["secondary"],
            "sha256": digest,
            "backgroundPixelsRemoved": removed,
        }
        if refined_source:
            assignments[fill["id"]]["refinementSourceImagePath"] = refined_source
        repaired.append(fill["id"])

    if len(repaired) != len(PALETTE_SAMPLE_INDEX):
        raise ValueError(f"expected {len(PALETTE_SAMPLE_INDEX)} repaired marks, found {len(repaired)}")
    report["createdAt"] = datetime.now(timezone.utc).isoformat()
    report["methodology"]["visibilityRemediation"] = {
        "targets": len(repaired),
        "rule": "Replace low-contrast assignments with high-contrast palettes from the 100-team sample; remove only edge-connected light-neutral pixels from fully opaque assets.",
    }
    report["methodology"]["assignmentRule"] = (
        f"Seeded assignment of 162 palettes from the sample, then {len(PALETTE_SAMPLE_INDEX)} user-flagged marks "
        "were reassigned to high-contrast palettes from that same sample; the giraffe is now also recolored."
    )
    report["assignments"] = [assignments[key] for key in sorted(assignments)]
    CURATION_PATH.write_text(json.dumps(curation, indent=2) + "\n")
    REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n")
    REPORT_PATH.with_suffix(".md").write_text(markdown_report(report))
    print(f"PASS: remediated {len(repaired)} selected logos")


if __name__ == "__main__":
    main()
