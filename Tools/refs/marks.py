"""Team marks as data URIs, and the identities they belong to.

Isolated from every other module for one reason: the marks are ~430 KB of PNG, and a
base64 blob in a file that also holds registry declarations makes every registry diff
unreadable. Nothing here is authored -- the bytes come from `assets/`, the identities
from the pinned baseline's generated catalogue.
"""

from __future__ import annotations

import base64
import re
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

ASSETS = Path(__file__).parent / "assets"

#: The commit this generator resolves identities against. Recorded in
#: `docs/refs/BASELINE.md`; check 2 fails the build if the catalogue at HEAD no longer
#: agrees with what the frames were drawn from.
BASELINE_SHA = "10fcc56"

CATALOGUE = (
    Path(__file__).resolve().parents[2]
    / "Sources"
    / "ProFootballCoachUI"
    / "TeamLogoCatalog.generated.swift"
)

_ENTRY = re.compile(
    r'CoachWorldTeamReference\(stableID: "([^"]+)", name: "([^"]+)", '
    r'abbreviation: "([^"]+)".*?primaryColorHex: "([^"]+)", secondaryColorHex: "([^"]+)"\)'
)


@dataclass(frozen=True)
class Identity:
    stable_id: str
    name: str
    abbreviation: str
    primary: str
    secondary: str
    asset_key: str


@lru_cache(maxsize=1)
def catalogue() -> dict[str, Identity]:
    """Every team in the baseline catalogue, keyed by stableID.

    The name/colour table sits inside `#if DEBUG` in the generated Swift, so this
    reads the source text rather than linking the module."""
    text = CATALOGUE.read_text(encoding="utf-8")
    out: dict[str, Identity] = {}
    for stable_id, name, abbr, primary, secondary in _ENTRY.findall(text):
        out[stable_id] = Identity(
            stable_id=stable_id,
            name=name,
            abbreviation=abbr,
            primary=primary,
            secondary=secondary,
            asset_key="TeamLogo_" + stable_id.replace("-", ""),
        )
    return out


_ASSET = re.compile(r'"([0-9A-F-]{36})": "(TeamLogo_[0-9A-F]{32})"')


@lru_cache(maxsize=1)
def asset_owners() -> dict[str, str]:
    """asset key -> stableID, read out of the catalogue's unconditional map.

    Do NOT slice the stableID back out of the filename. `9e50b57` re-keyed the
    manifest onto the world the merge generates, which decoupled the two: the file
    named `TeamLogo_0213C958...` now belongs to team `073A0F70-...`, and the hex in
    the name is a fossil of the team it was drawn for. Deriving the id from the name
    resolves 11 of the 13 vendored marks to the wrong team and the other 2 to none."""
    text = CATALOGUE.read_text(encoding="utf-8")
    return {asset: stable_id for stable_id, asset in _ASSET.findall(text)}


@lru_cache(maxsize=1)
def available() -> dict[str, str]:
    """asset key -> stableID, for the marks actually vendored here."""
    owners = asset_owners()
    return {
        path.stem: owners[path.stem]
        for path in sorted(ASSETS.glob("TeamLogo_*.png"))
        if path.stem in owners
    }


@lru_cache(maxsize=64)
def mark_uri(key: str) -> str:
    """A vendored mark as a `data:` URI. The page must be self-contained, so there is
    no other way for an image to reach it."""
    path = ASSETS / f"{key}.png"
    if not path.exists():
        raise KeyError(f"no vendored mark {key}; run Tools/refs/build.py --check")
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def identity(key: str) -> Identity:
    """The team a vendored mark belongs to, resolved against the baseline catalogue.

    Raises if the key is not vendored or the stableID is absent from the catalogue --
    the point of check 2. A mark whose identity cannot be resolved must fail the build
    rather than render under a stale name."""
    stable_id = available().get(key)
    if stable_id is None:
        raise KeyError(f"{key} is not a vendored mark")
    found = catalogue().get(stable_id)
    if found is None:
        raise KeyError(
            f"{key} resolves to {stable_id}, which is absent from the catalogue at "
            f"{CATALOGUE}. Baseline drift -- see docs/refs/BASELINE.md."
        )
    return found


# --------------------------------------------------------------------------
# The fixtures the frames are drawn with. Keys, never names: the name is looked up,
# so a baseline that renames a team fails the build instead of relabelling a frame.
# --------------------------------------------------------------------------

COLLEGE_CLUB = "TeamLogo_00EBE0C02B2B4988A450BB870D6D3881"
COLLEGE_OPPONENT = "TeamLogo_0017F958E7D04FFC9EA801A252B40FD6"
PRO_CLUB = "TeamLogo_0D81D2F903834BD5A74176604D277691"
PRO_OPPONENT = "TeamLogo_0F05F4F368CA4674B2109DD7B75E1088"

FIXTURES = {
    "college": (COLLEGE_CLUB, COLLEGE_OPPONENT),
    "pro": (PRO_CLUB, PRO_OPPONENT),
}


def fixture(kind: str) -> tuple[Identity, Identity]:
    club, opponent = FIXTURES[kind]
    return identity(club), identity(opponent)
