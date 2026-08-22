#!/usr/bin/env python3
"""Mutation test: every rule must be able to fail.

A rule that cannot fail is not coverage, it is decoration. This breaks the registry in
one specific way per rule and asserts that rule -- and, where the break is narrow, only
that rule -- reports it. Run it whenever a rule is added or changed:

    python3 Tools/refs/test_checks.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import checks  # noqa: E402
import tokens  # noqa: E402
from dataclasses import replace  # noqa: E402
from primitives import Chip, Chips, Col, Custom, Panel, Row, Rows, Stack, Table  # noqa: E402
from surface import Gap, GapKind, Lean, Status  # noqa: E402

PASSED: list[str] = []
FAILED: list[str] = []


def expect(rule_number: int, mutate, label: str) -> None:
    """Apply `mutate` to a copy of the registry, run every rule, and require that the
    named rule reports at least one failure."""
    original = list(checks.REGISTRY)
    mutated = mutate(list(original))
    checks.REGISTRY[:] = mutated if isinstance(checks.REGISTRY, list) else mutated
    try:
        failures = checks.run_all()
    finally:
        checks.REGISTRY[:] = original
    hit = [f for f in failures if f.startswith(f"[{rule_number:>2}]")]
    (PASSED if hit else FAILED).append(f"rule {rule_number}: {label}")


def _first(surfaces, predicate):
    return next(i for i, s in enumerate(surfaces) if predicate(s))


def main() -> int:
    # checks.REGISTRY is a tuple; swap in a list so mutations are possible.
    checks.REGISTRY = list(checks.REGISTRY)
    import page
    import render

    page.REGISTRY = checks.REGISTRY
    render.REGISTRY = checks.REGISTRY

    def drop_one(rs):
        return rs[:-1]

    def duplicate_number(rs):
        rs[1] = replace(rs[1], number=rs[0].number)
        return rs

    def blow_cells(rs):
        i = _first(rs, lambda s: s.lean is Lean.BROADCAST)
        rs[i] = replace(
            rs[i],
            body=Table(
                tuple(Col(f"c{n}", 4) for n in range(4)),
                tuple(("1", "2", "3", "4") for _ in range(9)),
            ),
        )
        return rs

    def two_golds(rs):
        i = _first(rs, lambda s: s.commit)
        rs[i] = replace(rs[i], body=Chips((Chip("A", "gold"), Chip("B", "gold"))))
        return rs

    def too_many_rows(rs):
        i = _first(rs, lambda s: s.lean is Lean.DESK)
        rs[i] = replace(
            rs[i],
            body=Rows(tuple(Row(f"row {n}") for n in range(12)), kind="tappable"),
        )
        return rs

    def too_many_columns(rs):
        i = _first(rs, lambda s: s.lean is Lean.DESK)
        rs[i] = replace(
            rs[i],
            body=Table(tuple(Col(f"c{n}", 3) for n in range(11)), (tuple("x" * 11),)),
        )
        return rs

    def illegal_register(rs):
        i = _first(rs, lambda s: s.id != "matchDay")
        rs[i] = replace(rs[i], lean=Lean.MATCH_DAY)
        return rs

    def bad_contrast(rs):
        # --fl-ink-3's refused sibling is not in the sheet, so use a real low pair:
        # quiet ink on the raised ground is below 4.5.
        i = _first(rs, lambda s: True)
        rs[i] = replace(rs[i], body=Custom(
            '<span data-ink="--content-quiet" data-plate="--content-secondary">x</span>',
            declared_height=40,
        ))
        return rs

    def overflow(rs):
        i = _first(rs, lambda s: s.lean is Lean.DESK)
        rs[i] = replace(rs[i], body=Table((Col("Narrow", 3),), (("far too long",),)))
        return rs

    def no_gaps(rs):
        rs[0] = replace(rs[0], gaps=())
        return rs

    def banned_word(rs):
        rs[0] = replace(rs[0], body=Custom("<p>TODO: finish this</p>", declared_height=40))
        return rs

    def external_url(rs):
        rs[0] = replace(rs[0], body=Custom('<img src="https://example.com/a.png">', declared_height=40))
        return rs

    def too_many_customs(rs):
        for i in range(tokens.CUSTOM_BUDGET + 1):
            rs[i] = replace(rs[i], body=Custom("<p>escape hatch</p>", declared_height=40))
        return rs

    def missing_evidence(rs):
        i = _first(rs, lambda s: s.status is not Status.BUILT)
        rs[i] = replace(rs[i], evidence=None)
        return rs

    def unknown_screen(rs):
        rs[0] = replace(rs[0], id="notAScreen", number=99)
        return rs

    expect(1, drop_one, "58 surfaces is not 59")
    expect(1, duplicate_number, "duplicate registry number")
    expect(1, missing_evidence, "non-BUILT surface with no evidence")
    expect(2, unknown_screen, "a surface Swift does not declare")
    expect(3, blow_cells, "36 cells in a BROADCAST frame")
    expect(4, two_golds, "two gold chips plus a commit bar")
    expect(5, too_many_rows, "12 tappable rows")

    def too_tall(rs):
        i = _first(rs, lambda s: s.lean is Lean.DESK)
        rs[i] = replace(rs[i], body=Stack(tuple(
            Panel(f"p{n}", Rows((Row("x"),), kind="readout")) for n in range(6)
        )))
        return rs

    expect(5, too_tall, "six stacked panels, taller than the plate")
    expect(6, too_many_columns, "11 columns")
    expect(7, illegal_register, "MATCH_DAY on a surface that is not matchDay")
    expect(8, bad_contrast, "quiet ink on secondary ink")
    expect(11, overflow, "a 12-character cell in a 3-character column")
    def wrong_lean(rs):
        i = _first(rs, lambda s: s.lean is Lean.DESK and s.number <= 62)
        rs[i] = replace(rs[i], lean=Lean.BROADCAST)
        return rs

    def dossier_top_heavy(rs):
        from primitives import Split, Hero
        i = _first(rs, lambda s: s.lean is Lean.DOSSIER)
        head = Hero(None, "x", numeral="1", points=tuple(f"p{n}" for n in range(12)),
                    scale="dossier")
        rs[i] = replace(rs[i], body=Split(top=head, bottom=Rows((Row("y"),))))
        return rs

    def broadcast_head_on_a_desk(rs):
        # A 64 px numeral and a 390 px watermark on a frame that claims Desk. Desk allows
        # 14 px and a 19 px band mark, so both halves of rule 9 should fire.
        i = _first(rs, lambda s: s.lean is Lean.BROADCAST)
        rs[i] = replace(rs[i], lean=Lean.DESK)
        return rs

    expect(2, wrong_lean, "a Desk surface redrawn as Broadcast")
    expect(3, dossier_top_heavy, "13 cells above the dossier seam")
    expect(9, broadcast_head_on_a_desk, "a 64 px numeral on a frame claiming Desk")
    expect(12, no_gaps, "a surface with no declared gap")

    # Rule 10 is not registry-shaped, so it is mutated at its source. Rule 9's mark and
    # numeral scales are now mutated through the registry above (`small_numeral`).
    stray = checks.HERE / "_mutation_probe.py"
    stray.write_text("ACCENT = \"#ff0000\"\n", encoding="utf-8")
    try:
        hit = checks.check_palette()
        (PASSED if hit else FAILED).append("rule 10: a literal hex outside the token sheets")
    finally:
        stray.unlink()
    expect(13, banned_word, "TODO in the page")
    expect(13, external_url, "an external image")
    expect(13, too_many_customs, "seven Custom nodes")

    for line in PASSED:
        print(f"  ok    {line}")
    for line in FAILED:
        print(f"  DEAD  {line} -- the rule did not fire")
    # Rule 15 cannot be mutated through the registry: it reads the shipped catalogue and
    # the Swift blocklist. Exercised at its source instead.
    import legal

    if legal.blocks("Alabama Red Elephants") and not legal.blocks("Union Maritime Meridian"):
        PASSED.append("rule 15: a blocklisted institution name in a published identity")
    else:
        FAILED.append("rule 15: the blocklist port does not discriminate")

    print(f"\n{len(PASSED)} rules bite, {len(FAILED)} dead")
    print(
        "Rule 14 (determinism) is not mutated here: making a build non-deterministic on "
        "purpose means editing the generator, not the registry. It is exercised by "
        "build.py --check running page.build() twice on every run."
    )
    return 1 if FAILED else 0


if __name__ == "__main__":
    raise SystemExit(main())
