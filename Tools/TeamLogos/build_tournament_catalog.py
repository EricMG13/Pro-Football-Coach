#!/usr/bin/env python3
"""Build the local logo-tournament catalog from worktrees and Git history."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


IMAGE_SUFFIXES = {".png", ".webp", ".svg"}
LOGO_ROOTS = (
    "Sources/ProFootballCoachUI/Resources/TeamLogos.xcassets",
    "exports/Claude-Design-Team-Logo-Handoff-2026-08-20/assets/TeamLogos.xcassets",
    "artifacts/team-mark-review",
    "output/logos",
    "exports/logo-batches",
    ".superpowers/brainstorm",
)
COMPOSITE_TERMS = (
    "all-logos",
    "canvas",
    "contact-sheet",
    "final-review",
    "phone-preview",
    "preview",
    "proof",
    "raw-review",
    "review-screenshot",
    "shipped-vs-candidate",
    "size-proof",
)
ASSET_NAME = re.compile(r"TeamLogo_([0-9A-Fa-f]{32})")


def normalized(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def is_composite_path(path: str) -> bool:
    label = path.lower().replace("_", "-")
    return any(term in label for term in COMPOSITE_TERMS) or bool(
        re.search(r"(?:^|[-_/])(?:20|32|44)pt(?:[-_/]|$)", label)
    )


def stage_for(path: str) -> str:
    label = path.lower()
    if "/raw/" in label or "-raw" in label:
        return "raw"
    if "normal" in label:
        return "normalized"
    if "candidate" in label:
        return "candidate"
    if "handoff" in label:
        return "handoff"
    if label.startswith("sources/profootballcoachui/resources/teamlogos.xcassets"):
        return "canonical"
    if "generated" in label or "/output/" in label:
        return "generated"
    return "historic"


def asset_name_in(path: str) -> str | None:
    match = ASSET_NAME.search(path)
    return f"TeamLogo_{match.group(1).upper()}" if match else None


def load_teams(manifest_path: Path) -> list[dict[str, str]]:
    manifest = json.loads(manifest_path.read_text())
    teams = manifest["teams"]
    stable_ids = [team["stableID"] for team in teams]
    asset_names = [team["assetName"] for team in teams]
    if len(teams) != 166 or len(stable_ids) != len(set(stable_ids)) or len(asset_names) != len(set(asset_names)):
        raise ValueError("manifest must contain 166 unique stable IDs and asset names")
    return [
        {
            "stableID": team["stableID"],
            "name": team["name"],
            "abbreviation": team["abbreviation"],
            "assetName": team["assetName"],
            "family": team["family"],
        }
        for team in teams
    ]


def team_for_path(path: str, teams: Iterable[dict[str, str]]) -> dict[str, str] | None:
    team_list = list(teams)
    asset_name = asset_name_in(path)
    if asset_name:
        return next((team for team in team_list if team["assetName"] == asset_name), None)
    stem = normalized(Path(path).stem)
    return next((team for team in team_list if normalized(team["name"]) == stem), None)


def should_scan(path: str) -> bool:
    candidate = path.replace("\\", "/").lstrip("./")
    if Path(candidate).suffix.lower() not in IMAGE_SUFFIXES:
        return False
    if candidate.startswith(LOGO_ROOTS):
        return True
    return candidate.startswith("exports/") and any(term in candidate.lower() for term in ("logo", "mark"))


def archive_bytes(data: bytes, digest: str, suffix: str, archive: Path) -> str:
    suffix = suffix.lower() if suffix.lower() in IMAGE_SUFFIXES else ".png"
    archive.mkdir(parents=True, exist_ok=True)
    destination = archive / f"{digest}{suffix}"
    if destination.exists():
        if hashlib.sha256(destination.read_bytes()).hexdigest() != digest:
            raise RuntimeError(f"refusing to overwrite non-matching archive file: {destination}")
    else:
        destination.write_bytes(data)
    return destination.name


def approved_replacement_assets(repo: Path) -> set[str]:
    decision_paths = [
        *repo.glob("artifacts/team-mark-review/batch-*/decisions.json"),
        *repo.glob("artifacts/team-mark-review/duplicate-remake/batch-*/decisions.json"),
    ]
    approved = set()
    for decision_path in decision_paths:
        payload = json.loads(decision_path.read_text())
        records = payload if isinstance(payload, list) else payload.get("assets", [])
        for record in records:
            if record.get("decision", "").lower() == "replace" or record.get("reviewOutcome") == "PASS":
                approved.add(record["assetName"])
    return approved


def is_reviewed_replacement(candidate: dict, approved_assets: set[str]) -> bool:
    asset_name = candidate["assetName"]
    return bool(asset_name and asset_name in approved_assets and any(
        f"/candidates/{asset_name}.png" in f"/{origin['path']}" for origin in candidate["origins"]
    ))


@dataclass
class Origin:
    kind: str
    path: str
    stage: str
    worktree: str | None = None
    branch: str | None = None
    object_id: str | None = None

    def as_dict(self) -> dict[str, str]:
        return {key: value for key, value in self.__dict__.items() if value is not None}


class CandidateCollector:
    def __init__(self, teams: list[dict[str, str]], archive: Path):
        self.teams = teams
        self.archive = archive
        self.records: dict[str, dict] = {}

    def add(self, data: bytes, path: str, origin: Origin) -> None:
        digest = hashlib.sha256(data).hexdigest()
        team = team_for_path(path, self.teams)
        record = self.records.get(digest)
        if record is None:
            image_name = archive_bytes(data, digest, Path(path).suffix, self.archive)
            record = {
                "id": digest,
                "sha256": digest,
                "imagePath": f"tournament-assets/{image_name}",
                "teamStableID": team["stableID"] if team else None,
                "assetName": team["assetName"] if team else None,
                "stages": set(),
                "origins": [],
            }
            self.records[digest] = record
        elif team and record["teamStableID"] not in (None, team["stableID"]):
            record["teamStableID"] = None
            record["assetName"] = None
        record["stages"].add(origin.stage)
        origin_data = origin.as_dict()
        if origin_data not in record["origins"]:
            record["origins"].append(origin_data)

    def entries(self) -> list[dict]:
        rank = {"canonical": 0, "handoff": 1, "candidate": 2, "normalized": 3, "generated": 4, "raw": 5, "historic": 6}
        entries = []
        for record in self.records.values():
            stages = sorted(record["stages"], key=lambda stage: rank.get(stage, 99))
            entries.append({**record, "stage": stages[0], "stages": stages})
        return sorted(entries, key=lambda item: (item["assetName"] is None, item["assetName"] or "", item["sha256"]))


def worktrees(repo: Path) -> list[dict[str, str | None]]:
    output = subprocess.run(
        ["git", "worktree", "list", "--porcelain"], cwd=repo, check=True, capture_output=True, text=True
    ).stdout
    entries, current = [], {}
    for line in [*output.splitlines(), ""]:
        if not line:
            if current:
                entries.append({"path": current["worktree"], "branch": current.get("branch"), "available": str(Path(current["worktree"]).is_dir()).lower()})
                current = {}
        elif " " in line:
            key, value = line.split(" ", 1)
            if key in {"worktree", "branch"}:
                current[key] = value.removeprefix("refs/heads/")
    return entries


def local_sources(entry: dict[str, str | None]) -> Iterable[tuple[bytes, str, Origin]]:
    root = Path(str(entry["path"]))
    for relative_root in LOGO_ROOTS:
        source_root = root / relative_root
        if not source_root.is_dir():
            continue
        for source in source_root.rglob("*"):
            if not source.is_file() or not should_scan(str(source.relative_to(root))):
                continue
            relative = source.relative_to(root).as_posix()
            if relative.startswith("artifacts/team-mark-review/tournament-assets/"):
                continue
            origin = Origin("worktree", relative, stage_for(relative), str(root), entry.get("branch"))
            yield source.read_bytes(), relative, origin


def history_sources(repo: Path) -> Iterable[tuple[bytes, str, Origin]]:
    output = subprocess.run(
        ["git", "rev-list", "--objects", "--all"], cwd=repo, check=True, capture_output=True, text=True
    ).stdout
    objects = []
    for line in output.splitlines():
        object_id, separator, path = line.partition(" ")
        if separator and should_scan(path):
            objects.append((object_id, path))
    with subprocess.Popen(
        ["git", "cat-file", "--batch"], cwd=repo, stdin=subprocess.PIPE, stdout=subprocess.PIPE
    ) as process:
        assert process.stdin and process.stdout
        process.stdin.write("".join(f"{object_id}\n" for object_id, _ in objects).encode())
        process.stdin.close()
        for object_id, path in objects:
            header = process.stdout.readline().decode().split()
            if len(header) != 3 or header[1] != "blob":
                raise RuntimeError(f"unable to read historical logo object {object_id}")
            data = process.stdout.read(int(header[2]))
            process.stdout.read(1)
            yield data, path, Origin("history", path, stage_for(path), object_id=object_id)
        if process.wait() != 0:
            raise RuntimeError("git cat-file --batch failed")


def build(repo: Path, output: Path) -> dict:
    teams = load_teams(repo / "Tools/TeamLogos/manifest.json")
    archive = output / "tournament-assets"
    collector = CandidateCollector(teams, archive)
    excluded: list[dict[str, str]] = []
    worktree_entries = worktrees(repo)
    for entry in worktree_entries:
        if entry["available"] != "true":
            continue
        for data, path, origin in local_sources(entry):
            if is_composite_path(path):
                excluded.append({**origin.as_dict(), "reason": "composite review image"})
            else:
                collector.add(data, path, origin)
    for data, path, origin in history_sources(repo):
        if is_composite_path(path):
            excluded.append({**origin.as_dict(), "reason": "composite review image"})
        else:
            collector.add(data, path, origin)
    candidates = collector.entries()
    approved_assets = approved_replacement_assets(repo)
    for candidate in candidates:
        candidate["selectionEligible"] = is_reviewed_replacement(candidate, approved_assets)
        candidate["qualityStatus"] = "reviewed" if candidate["selectionEligible"] else (
            "unassigned" if candidate["teamStableID"] is None else "held"
        )
    covered = {candidate["assetName"] for candidate in candidates if candidate["assetName"]}
    missing = sorted(team["assetName"] for team in teams if team["assetName"] not in covered)
    if missing:
        raise ValueError(f"canonical candidates missing for {len(missing)} teams: {', '.join(missing[:3])}")
    eligible_covered = {candidate["assetName"] for candidate in candidates if candidate["selectionEligible"]}
    missing_reviewed = sorted(team["assetName"] for team in teams if team["assetName"] not in eligible_covered)
    if missing_reviewed:
        raise ValueError(f"reviewed replacement candidates missing for {len(missing_reviewed)} teams: {', '.join(missing_reviewed[:3])}")
    fingerprint_source = json.dumps({"teams": teams, "candidates": candidates}, sort_keys=True, separators=(",", ":")).encode()
    catalog = {
        "schemaVersion": 1,
        "fingerprint": hashlib.sha256(fingerprint_source).hexdigest(),
        "teams": teams,
        "candidates": candidates,
        "reviewPolicy": "Only documented reviewed replacement candidates advance; held and unassigned variants remain in the audit.",
        "unassignedCandidateIDs": [candidate["id"] for candidate in candidates if candidate["teamStableID"] is None],
        "heldCandidateIDs": [candidate["id"] for candidate in candidates if not candidate["selectionEligible"]],
        "excluded": sorted(excluded, key=lambda item: (item["path"], item.get("object_id", ""))),
        "worktrees": worktree_entries,
    }
    output.mkdir(parents=True, exist_ok=True)
    (output / "tournament-catalog.json").write_text(json.dumps(catalog, indent=2) + "\n")
    return catalog


def main() -> None:
    repo = Path(__file__).resolve().parents[2]
    catalog = build(repo, repo / "artifacts/team-mark-review")
    print(f"Built {len(catalog['candidates'])} unique candidates for {len(catalog['teams'])} teams.")


if __name__ == "__main__":
    main()
