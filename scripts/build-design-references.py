#!/usr/bin/env python3
"""Build or check the generated V3 design-reference library."""

from __future__ import annotations

import sys
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPOSITORY_ROOT))

from design_refs.generator import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
