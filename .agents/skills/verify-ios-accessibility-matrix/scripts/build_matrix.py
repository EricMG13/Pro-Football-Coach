#!/usr/bin/env python3
"""Build the accessibility coverage manifest from the canonical screen table."""

import argparse
import json
import re
from pathlib import Path


SCREEN_ROW = re.compile(r"^\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|")
SWIFT_CASE = re.compile(r"^\s*case\s+(\w+)\s*=\s*(\d+)\s*$")
SWIFT_NAME = re.compile(r'^\s*case\s+\.(\w+):\s+return\s+"([^"]+)"\s*$')
AXES = {
    "viewport": ["844x390", "932x430"],
    "appearance": ["light", "dark"],
    "typeSize": ["default", "AX5"],
    "sensorSide": ["left", "right"],
    "voiceOver": ["off", "on"],
    "reduceMotion": ["off", "on"],
    "state": ["normal", "error"],
}


def canonical_screens(document: Path) -> list[dict[str, object]]:
    _, inventory_heading, remainder = document.read_text(encoding="utf-8").partition(
        "## 8. Canonical v1 screen inventory"
    )
    if not inventory_heading:
        raise ValueError("canonical screen inventory heading is missing")
    section, match_day_heading, _ = remainder.partition("## 9. Match Day")
    if not match_day_heading:
        raise ValueError("canonical screen inventory end heading is missing")
    screens = [
        {"number": int(match.group(1)), "name": match.group(2).strip()}
        for line in section.splitlines()
        if (match := SCREEN_ROW.match(line))
    ]
    numbers = [screen["number"] for screen in screens]
    if numbers != list(range(1, 63)):
        raise ValueError(f"screen numbers must be exactly 1...62; found {numbers}")
    if len({screen["name"] for screen in screens}) != 62:
        raise ValueError("screen names must be unique")
    return screens


def registered_screens(registry: Path) -> list[dict[str, object]]:
    lines = registry.read_text(encoding="utf-8").splitlines()
    cases = [
        (match.group(1), int(match.group(2)))
        for line in lines
        if (match := SWIFT_CASE.match(line))
    ]
    names = {
        match.group(1): match.group(2)
        for line in lines
        if (match := SWIFT_NAME.match(line))
    }
    numbers = [number for _, number in cases]
    if numbers != list(range(1, 63)):
        raise ValueError(f"Swift screen numbers must be exactly 1...62; found {numbers}")
    symbols = [symbol for symbol, _ in cases]
    if len(set(symbols)) != 62:
        raise ValueError("Swift screen case names must be unique")
    if set(symbols) != set(names):
        missing = sorted(set(symbols) - set(names))
        extra = sorted(set(names) - set(symbols))
        raise ValueError(f"Swift screen names do not cover cases; missing={missing}, extra={extra}")
    return [{"number": number, "name": names[symbol]} for symbol, number in cases]


def manifest(document: Path, registry: Path) -> dict[str, object]:
    screens = canonical_screens(document)
    registered = registered_screens(registry)
    if registered != screens:
        raise ValueError("Swift screen registry does not exactly match the canonical document")
    cases_per_screen = 1
    for values in AXES.values():
        cases_per_screen *= len(values)
    return {
        "source": str(document),
        "registrySource": str(registry),
        "screenCount": len(screens),
        "componentCount": 0,
        "axes": AXES,
        "casesPerScreen": cases_per_screen,
        "totalScreenCases": len(screens) * cases_per_screen,
        "automatedEvidence": {"status": "not-run"},
        "manualEvidence": {"status": "manual-required"},
        "screens": screens,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--document",
        type=Path,
        default=Path("docs/04-UX-AND-DESIGN-SYSTEM.md"),
    )
    parser.add_argument(
        "--registry",
        type=Path,
        default=Path("Sources/ProFootballCoachUI/ScreenRegistry.swift"),
    )
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    output = json.dumps(manifest(args.document, args.registry), indent=2) + "\n"
    if args.output:
        args.output.write_text(output, encoding="utf-8")
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
