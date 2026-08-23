#!/usr/bin/env python3
"""Research 100 football palettes and recolor the curated logo round without changing geometry."""

from __future__ import annotations

import csv
import hashlib
import io
import json
import random
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ARTIFACTS = ROOT / "artifacts/team-mark-review"
CATALOG_PATH = ARTIFACTS / "tournament-catalog.json"
CURATION_PATH = ARTIFACTS / "final-166-curation.json"
OUTPUT_ROOT = ARTIFACTS / "final-166-colors"
REPORT_ROOT = ARTIFACTS / "color-research"
SEED = 20_260_823

NFL_URL = "https://raw.githubusercontent.com/nflverse/nflverse-pbp/master/teams_colors_logos.csv"
COLLEGE_URL = "https://raw.githubusercontent.com/CFBNumbers/logos/main/cfblogos.csv"
NFL_CODES = {
    "ARI", "ATL", "BAL", "BUF", "CAR", "CHI", "CIN", "CLE", "DAL", "DEN", "DET", "GB",
    "HOU", "IND", "JAX", "KC", "LAC", "LAR", "LV", "MIA", "MIN", "NE", "NO", "NYG",
    "NYJ", "PHI", "PIT", "SEA", "SF", "TB", "TEN", "WAS",
}
FBS_CONFERENCES = {
    "ACC", "American Athletic", "Big 12", "Big Ten", "Conference USA", "FBS Independents",
    "Mid-American", "Mountain West", "Pac-12", "SEC", "Sun Belt",
}


def fetch_text(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": "Pro-Football-Coach palette research"})
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = response.read()
    try:
        return payload.decode("utf-8")
    except UnicodeDecodeError:
        return payload.decode("cp1252")


def normalized_hex(value: str) -> str:
    text = value.strip().upper()
    if not text.startswith("#"):
        text = f"#{text}"
    if len(text) != 7 or any(character not in "#0123456789ABCDEF" for character in text):
        raise ValueError(f"invalid hex color: {value}")
    return text


def load_samples(nfl_text: str, college_text: str) -> list[dict[str, str]]:
    nfl_rows = [row for row in csv.DictReader(io.StringIO(nfl_text)) if row["team_abbr"] in NFL_CODES]
    if len(nfl_rows) != 32:
        raise ValueError(f"expected 32 current NFL teams, found {len(nfl_rows)}")
    nfl = [
        {
            "league": "NFL",
            "team": row["team_name"],
            "abbreviation": row["team_abbr"],
            "conference": row["team_conf"],
            "primary": normalized_hex(row["team_color"]),
            "secondary": normalized_hex(row["team_color2"]),
        }
        for row in nfl_rows
    ]

    college_rows = []
    for row in list(csv.reader(io.StringIO(college_text)))[1:]:
        if len(row) < 12 or row[8] not in FBS_CONFERENCES:
            continue
        try:
            primary, secondary = normalized_hex(row[10]), normalized_hex(row[11])
        except ValueError:
            continue
        if primary == secondary:
            continue
        college_rows.append({
            "league": "FBS",
            "team": row[2],
            "abbreviation": row[4],
            "conference": row[8],
            "primary": primary,
            "secondary": secondary,
        })
    college_rows.sort(key=lambda row: (row["team"], row["abbreviation"]))
    if len(college_rows) < 68:
        raise ValueError(f"expected at least 68 complete FBS palettes, found {len(college_rows)}")
    college = random.Random(SEED).sample(college_rows, 68)
    college.sort(key=lambda row: row["team"])
    return nfl + college


def color_family(value: str) -> str:
    red, green, blue = bytes.fromhex(value.removeprefix("#"))
    maximum, minimum = max(red, green, blue), min(red, green, blue)
    chroma = maximum - minimum
    saturation = chroma / maximum if maximum else 0
    lightness = maximum / 255
    if lightness < 0.18:
        return "black"
    if saturation < 0.12 and lightness > 0.9:
        return "white"
    if saturation < 0.18:
        return "gray/silver"
    if chroma == 0:
        hue = 0.0
    elif maximum == red:
        hue = (60 * ((green - blue) / chroma)) % 360
    elif maximum == green:
        hue = 60 * ((blue - red) / chroma + 2)
    else:
        hue = 60 * ((red - green) / chroma + 4)
    if hue < 15 or hue >= 330:
        return "maroon/burgundy" if lightness < 0.58 else "red"
    if hue < 40:
        return "brown/tan" if lightness < 0.48 else "orange"
    if hue < 70:
        return "gold/yellow"
    if hue < 165:
        return "green"
    if hue < 195:
        return "teal"
    if hue < 255:
        return "blue/navy"
    if hue < 315:
        return "purple"
    return "pink"


def distribution(samples: list[dict[str, str]]) -> dict[str, dict[str, int]]:
    def ordered(counter: Counter[str]) -> dict[str, int]:
        return dict(sorted(counter.items(), key=lambda item: (-item[1], item[0])))

    primary = Counter(color_family(sample["primary"]) for sample in samples)
    secondary = Counter(color_family(sample["secondary"]) for sample in samples)
    combined = primary + secondary
    family_pairs = Counter(
        f'{color_family(sample["primary"])} + {color_family(sample["secondary"])}'
        for sample in samples
    )
    exact_pairs = Counter(f'{sample["primary"]} + {sample["secondary"]}' for sample in samples)
    return {
        "primaryColorFamilies": ordered(primary),
        "secondaryColorFamilies": ordered(secondary),
        "allColorFamilies": ordered(combined),
        "orderedFamilyPairs": ordered(family_pairs),
        "exactHexPairs": ordered(exact_pairs),
    }


def relative_luminance(color: tuple[int, int, int]) -> float:
    channels = [channel / 255 for channel in color]
    linear = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4 for channel in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def otsu_threshold(luminances: list[int]) -> int:
    if not luminances or min(luminances) == max(luminances):
        return luminances[0] if luminances else 0
    histogram = Counter(luminances)
    total = len(luminances)
    total_sum = sum(level * count for level, count in histogram.items())
    background_count = 0
    background_sum = 0
    best_threshold = 0
    best_variance = -1.0
    for threshold in range(256):
        count = histogram.get(threshold, 0)
        background_count += count
        background_sum += threshold * count
        foreground_count = total - background_count
        if not background_count or not foreground_count:
            continue
        background_mean = background_sum / background_count
        foreground_mean = (total_sum - background_sum) / foreground_count
        variance = background_count * foreground_count * (background_mean - foreground_mean) ** 2
        if variance > best_variance:
            best_variance = variance
            best_threshold = threshold
    return best_threshold


def recolor_preserving_shape(source: Image.Image, primary_hex: str, secondary_hex: str) -> Image.Image:
    def pixel_luminance(pixel: tuple[int, int, int, int]) -> int:
        red, green, blue, _ = pixel
        return (54 * red + 183 * green + 19 * blue) // 256

    image = source.convert("RGBA")
    pixels = list(image.get_flattened_data())
    luminances = [pixel_luminance(pixel) for pixel in pixels if pixel[3]]
    if not luminances:
        raise ValueError("cannot recolor an empty image")
    primary = tuple(bytes.fromhex(primary_hex.removeprefix("#")))
    secondary = tuple(bytes.fromhex(secondary_hex.removeprefix("#")))
    dark, light = sorted((primary, secondary), key=relative_luminance)
    threshold = otsu_threshold(luminances)
    if min(luminances) == max(luminances):
        dark = light = primary
    recolored = []
    for pixel in pixels:
        alpha = pixel[3]
        if not alpha:
            recolored.append(pixel)
            continue
        color = dark if pixel_luminance(pixel) <= threshold else light
        recolored.append((*color, alpha))
    image.putdata(recolored)
    return image


def save_recolor(source_path: Path, output_path: Path, primary: str, secondary: str) -> str:
    with Image.open(source_path) as source:
        original = source.convert("RGBA")
        result = recolor_preserving_shape(original, primary, secondary)
    if result.size != original.size or result.getchannel("A").tobytes() != original.getchannel("A").tobytes():
        raise ValueError(f"recolor changed geometry or alpha: {source_path}")
    allowed = {tuple(bytes.fromhex(primary[1:])), tuple(bytes.fromhex(secondary[1:]))}
    if any(pixel[:3] not in allowed for pixel in result.get_flattened_data() if pixel[3]):
        raise ValueError(f"recolor introduced an unexpected visible color: {source_path}")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    result.save(output_path, format="PNG", optimize=True)
    digest = hashlib.sha256(output_path.read_bytes()).hexdigest()
    with Image.open(output_path) as saved:
        if saved.convert("RGBA").getchannel("A").tobytes() != original.getchannel("A").tobytes():
            raise ValueError(f"encoded recolor changed alpha: {output_path}")
    return digest


def markdown_report(report: dict) -> str:
    assignment_count = len(report["assignments"])
    lines = [
        "# Football primary/secondary colour research — 100-team sample",
        "",
        "Sample: all 32 current NFL teams plus 68 seeded-random FBS programs with complete primary/secondary records.",
        f"Seed: `{SEED}`. {report['methodology']['assignmentRule']}",
        f"Recolors represented here: {assignment_count}.",
        "",
    ]
    for title, key in (
        ("Primary colour families", "primaryColorFamilies"),
        ("Secondary colour families", "secondaryColorFamilies"),
        ("All 200 colour positions", "allColorFamilies"),
        ("Ordered primary + secondary family pairs", "orderedFamilyPairs"),
        ("Exact hexadecimal pairs", "exactHexPairs"),
    ):
        lines.extend([f"## {title}", "", "| Colour or pair | Count |", "|---|---:|"])
        lines.extend(f"| {name} | {count} |" for name, count in report["distribution"][key].items())
        lines.append("")
    lines.extend(["## Sample", "", "| League | Team | Conference | Primary | Secondary |", "|---|---|---|---|---|"])
    lines.extend(
        f'| {sample["league"]} | {sample["team"]} | {sample["conference"]} | `{sample["primary"]}` | `{sample["secondary"]}` |'
        for sample in report["samples"]
    )
    lines.extend(["", "## Recolor assignments", "", "| Target | Source palette | Primary | Secondary |", "|---|---|---|---|"])
    lines.extend(
        f'| `{assignment["targetID"]}` | {assignment["paletteLeague"]} — {assignment["paletteTeam"]} | `{assignment["primary"]}` | `{assignment["secondary"]}` |'
        for assignment in report["assignments"]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    nfl_text, college_text = fetch_text(NFL_URL), fetch_text(COLLEGE_URL)
    samples = load_samples(nfl_text, college_text)
    if len(samples) != 100:
        raise ValueError(f"expected 100 samples, found {len(samples)}")

    catalog = json.loads(CATALOG_PATH.read_text())
    curation = json.loads(CURATION_PATH.read_text())
    candidate_by_id = {candidate["id"]: candidate for candidate in catalog["candidates"]}
    selected_ids = curation.get("sourceSelectedCandidateIDs") or curation["selectedCandidateIDs"]
    source_fills = curation.get("sourceFillCandidates") or curation["fillCandidates"]
    if len(selected_ids) != 140 or len(source_fills) != 26:
        raise ValueError("expected the existing 140 selections and 26 final-fill candidates")
    new_fills = [fill for fill in source_fills if int(fill["id"].split(":", 1)[1][:2]) >= 5]
    if len(new_fills) != 22:
        raise ValueError(f"expected 22 wild-cat/abstract fills, found {len(new_fills)}")

    palette_deck = samples.copy()
    random.Random(SEED + 1).shuffle(palette_deck)
    palettes = [palette_deck[index % len(palette_deck)] for index in range(162)]
    assignments = []
    recolored_selected = []

    for index, (candidate_id, palette) in enumerate(zip(selected_ids, palettes[:140]), start=1):
        source_candidate = candidate_by_id[candidate_id]
        source_path = ARTIFACTS / source_candidate["imagePath"]
        relative_output = Path("final-166-colors/recolored-selected") / f"{index:03d}-{candidate_id[:12]}.png"
        digest = save_recolor(source_path, ARTIFACTS / relative_output, palette["primary"], palette["secondary"])
        target_id = f"researched-recolor:{candidate_id}"
        palette_record = {key: palette[key] for key in ("league", "team", "primary", "secondary")}
        recolored_selected.append({
            "id": target_id,
            "sha256": digest,
            "imagePath": relative_output.as_posix(),
            "name": f"Researched palette {index:03d}",
            "family": "researched palette",
            "sourceCandidateID": candidate_id,
            "palette": palette_record,
        })
        assignments.append({
            "targetID": target_id,
            "sourceImagePath": source_candidate["imagePath"],
            "outputImagePath": relative_output.as_posix(),
            "paletteLeague": palette["league"],
            "paletteTeam": palette["team"],
            "primary": palette["primary"],
            "secondary": palette["secondary"],
            "sha256": digest,
        })

    recolored_new = {}
    for fill, palette in zip(new_fills, palettes[140:]):
        source_path = ARTIFACTS / fill["imagePath"]
        relative_output = Path("final-166-colors/recolored-new") / Path(fill["imagePath"]).name
        digest = save_recolor(source_path, ARTIFACTS / relative_output, palette["primary"], palette["secondary"])
        updated = dict(fill)
        updated.update({
            "sha256": digest,
            "imagePath": relative_output.as_posix(),
            "sourceImagePath": fill["imagePath"],
            "palette": {key: palette[key] for key in ("league", "team", "primary", "secondary")},
        })
        recolored_new[fill["id"]] = updated
        assignments.append({
            "targetID": fill["id"],
            "sourceImagePath": fill["imagePath"],
            "outputImagePath": relative_output.as_posix(),
            "paletteLeague": palette["league"],
            "paletteTeam": palette["team"],
            "primary": palette["primary"],
            "secondary": palette["secondary"],
            "sha256": digest,
        })

    unchanged_large_animals = [fill for fill in source_fills if fill["id"] not in recolored_new]
    curation.update({
        "sourceSelectedCandidateIDs": selected_ids,
        "sourceFillCandidates": source_fills,
        "selectedCandidateIDs": [],
        "fillCandidates": recolored_selected + unchanged_large_animals + [recolored_new[fill["id"]] for fill in new_fills],
        "paletteResearch": "color-research/football-color-sample-100.json",
    })

    report = {
        "schemaVersion": 1,
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "methodology": {
            "sampleSize": 100,
            "professionalTeams": 32,
            "collegeTeams": 68,
            "collegePopulationWithCompletePairs": 127,
            "collegeSampleSeed": SEED,
            "assignmentRule": "Seeded shuffle; every sampled palette used once, then the first 62 shuffled palettes repeat.",
            "recolorRule": "Preserve dimensions and every alpha byte; map visible source luminance roles to the darker/lighter sampled colors.",
        },
        "sources": [
            {"name": "nflverse teams_colors_logos.csv", "url": NFL_URL, "sha256": hashlib.sha256(nfl_text.encode()).hexdigest()},
            {"name": "CFBNumbers cfblogos.csv", "url": COLLEGE_URL, "sha256": hashlib.sha256(college_text.encode()).hexdigest()},
        ],
        "samples": samples,
        "distribution": distribution(samples),
        "assignments": assignments,
    }

    REPORT_ROOT.mkdir(parents=True, exist_ok=True)
    (REPORT_ROOT / "football-color-sample-100.json").write_text(json.dumps(report, indent=2) + "\n")
    (REPORT_ROOT / "football-color-sample-100.md").write_text(markdown_report(report))
    CURATION_PATH.write_text(json.dumps(curation, indent=2) + "\n")
    print(f"PASS: sampled {len(samples)} teams and recolored {len(assignments)} logos without geometry/alpha changes")


if __name__ == "__main__":
    main()
