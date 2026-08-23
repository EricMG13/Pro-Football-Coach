#!/usr/bin/env python3
"""Tools/refs -- reference frames for the Coach World surface registry.

    python3 Tools/refs/build.py            write the artifact
    python3 Tools/refs/build.py --check    run every rule, non-zero exit on failure
    python3 Tools/refs/build.py --both     check, then write

The deliverable is a single self-contained HTML file plus a JSON manifest of gaps, so
gaps diff across builds rather than being re-read by eye.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import checks  # noqa: E402
import page  # noqa: E402

OUT_DIR = Path(__file__).resolve().parents[2] / "docs" / "refs"
OUT_HTML = OUT_DIR / "surface-references.html"
OUT_JSON = OUT_DIR / "gaps.json"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="run the rules only")
    parser.add_argument("--both", action="store_true", help="check, then write")
    parser.add_argument(
        "--only",
        metavar="ID",
        nargs="+",
        help="write a subset page beside the full one, for looking at a few frames",
    )
    args = parser.parse_args(argv)

    if args.check or args.both:
        failures = checks.run_all()
        for failure in failures:
            print(f"FAIL  {failure}", file=sys.stderr)
        print(
            f"{len(checks.RULES)} rules, {len(failures)} failure(s)",
            file=sys.stderr,
        )
        if failures:
            return 1
        if args.check:
            return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if args.only:
        subset = page.build(tuple(args.only))
        target = OUT_DIR / "subset.html"
        target.write_text(subset, encoding="utf-8")
        print(f"wrote {target} ({len(subset):,} bytes, {len(args.only)} frames)")
        return 0
    html = page.build()
    OUT_HTML.write_text(html, encoding="utf-8")
    OUT_JSON.write_text(json.dumps(page.manifest(), indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT_HTML} ({len(html):,} bytes)")
    print(f"wrote {OUT_JSON}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
