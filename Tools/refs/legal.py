"""The legal guardrail, applied to what this generator actually publishes.

`CLAUDE.md` makes two of the guardrail's clauses tests rather than review items, and both
are Swift-side. This module ports the institution-kind sweep to Python for one reason: the
generator embeds real generated identities into a page it publishes to a hosted service,
and the Swift tests never see that page. A blocklisted name reaching the catalogue would
have shipped with nothing in the path to stop it.

This is the institution-kind check (`Blocklist.blocks`), which is the right limb for a
programme name. It is a port, not a reimplementation: the word-sequence rule and the entry
lists are read out of `Blocklist.swift` at build time so the two cannot drift.

Not ported: the ΔE trade-dress check. It needs the real programme colour table and a colour
space; the Swift suite owns it and this module records that limit rather than pretending.
"""

from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path

BLOCKLIST = (
    Path(__file__).resolve().parents[2]
    / "Sources"
    / "FootballSimCore"
    / "Generation"
    / "Blocklist.swift"
)

#: The lists `Blocklist.entries` is built from -- institutions, nicknames, conferences,
#: venues, people. If that expression gains a list, this tuple has to gain it too, which
#: `check_lists_match_swift()` asserts rather than trusts.
_LISTS = ("institutions", "nicknames", "conferences", "venues", "people", "marks")


def _normalise(text: str) -> str:
    return re.sub(r"[^a-z]", "", text.lower())


@lru_cache(maxsize=1)
def _source() -> str:
    return BLOCKLIST.read_text(encoding="utf-8")


@lru_cache(maxsize=1)
def entries() -> tuple[tuple[str, ...], ...]:
    """Every blocked entry as a tuple of normalised words."""
    out: list[tuple[str, ...]] = []
    for name in _LISTS:
        block = re.search(
            rf"private static let {name} = \[(.*?)\n    \]", _source(), re.S
        )
        if block is None:
            continue
        for value in re.findall(r'"([^"]+)"', block.group(1)):
            words = tuple(_normalise(w) for w in value.split() if _normalise(w))
            if words:
                out.append(words)
    return tuple(out)


def check_lists_match_swift() -> list[str]:
    """`Blocklist.entries` must be built from exactly the lists this module reads."""
    expr = re.search(r"public static let entries: \[\[String\]\] = \((.*?)\)", _source(), re.S)
    if expr is None:
        return ["cannot find Blocklist.entries in the Swift source"]
    named = set(re.findall(r"\b([a-z][A-Za-z]*)\b", expr.group(1))) - {"map", "words"}
    missing = named - set(_LISTS)
    return (
        [f"Blocklist.entries also draws on {sorted(missing)}, which legal.py does not read"]
        if missing
        else []
    )


def blocks(name: str) -> str | None:
    """The blocked entry a name contains, or None.

    Word sequences, not substring containment -- the Swift comment is explicit that raw
    containment blocks original names on sight ("Thibo Jacksonville" contains `bojackson`)
    and that a gate which fails on original names is one that gets weakened."""
    words = [_normalise(w) for w in name.split()]
    words = [w for w in words if w]
    table = entries()
    longest = max((len(e) for e in table), default=1)
    blocked = {"".join(e) for e in table}
    for size in range(1, longest + 1):
        for start in range(len(words) - size + 1):
            run = "".join(words[start : start + size])
            if run in blocked:
                return run
    return None
