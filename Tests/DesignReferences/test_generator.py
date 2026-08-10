from __future__ import annotations

import json
import math
import re
import tempfile
import unittest
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from string import Formatter
from unittest.mock import patch

import design_refs.generator as generator_module
from design_refs.generator import OUTPUT_NAMES, STYLES, check_outputs, render_outputs, write_outputs
from design_refs.content import build_sheets, _draft_body, _game_plan_body, _match_body, _promotion_body, _save_body
from design_refs.model import (
    BANNED_FRAME_VOCABULARY,
    BROADCAST_OCCASIONS,
    COMPONENT_STATES,
    DRAFT_LIFECYCLE,
    FIXTURES,
    FrameMeta,
    LIVE_FLOW_STATES,
    MATCH_LIFECYCLE,
    REQUIRED_FLOW_STATES,
)


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
VOID_ELEMENTS = frozenset({"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"})
FRAME_ATTRIBUTES = frozenset(
    {
        "data-frame",
        "data-canon",
        "data-fixture",
        "data-status",
        "data-device",
        "data-width-class",
        "data-appearance",
        "data-type-scale",
        "data-flow",
        "data-state",
    }
)


def _channel(value: int) -> float:
    component = value / 255
    return component / 12.92 if component <= 0.04045 else ((component + 0.055) / 1.055) ** 2.4


def _luminance(hex_value: str) -> float:
    red, green, blue = (int(hex_value[index:index + 2], 16) for index in (1, 3, 5))
    return 0.2126 * _channel(red) + 0.7152 * _channel(green) + 0.0722 * _channel(blue)


def _contrast(first: str, second: str) -> float:
    lighter, darker = sorted((_luminance(first), _luminance(second)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def _lab(hex_value: str) -> tuple[float, float, float]:
    red, green, blue = (_channel(int(hex_value[index:index + 2], 16)) for index in (1, 3, 5))
    x = (red * 0.4124 + green * 0.3576 + blue * 0.1805) / 0.95047
    y = red * 0.2126 + green * 0.7152 + blue * 0.0722
    z = (red * 0.0193 + green * 0.1192 + blue * 0.9505) / 1.08883

    def transform(value: float) -> float:
        return value ** (1 / 3) if value > 0.008856 else 7.787 * value + 16 / 116

    return 116 * transform(y) - 16, 500 * (transform(x) - transform(y)), 200 * (transform(y) - transform(z))


def _delta_e(first: str, second: str) -> float:
    return math.sqrt(sum((left - right) ** 2 for left, right in zip(_lab(first), _lab(second), strict=True)))


def _normalise_fact(value: str) -> str:
    return " ".join(value.casefold().split())


def _fact_dependency_closure(fixture, key: str) -> set[str]:
    templates = dict(fixture.derived_facts)
    result = {key}
    if key not in templates:
        return result
    for _, field_name, _, _ in Formatter().parse(templates[key]):
        if field_name is not None:
            result.update(_fact_dependency_closure(fixture, field_name))
    return result


@dataclass
class Element:
    tag: str
    attrs: dict[str, str]
    parent: Element | None = None
    children: list[Element] = field(default_factory=list)
    data: list[str] = field(default_factory=list)

    def descendants(self) -> list[Element]:
        result = []
        for child in self.children:
            result.append(child)
            result.extend(child.descendants())
        return result

    def has_class(self, class_name: str) -> bool:
        return class_name in self.attrs.get("class", "").split()

    def text(self, *, include_inert: bool = False) -> str:
        pieces = list(self.data)
        for child in self.children:
            if not include_inert and child.tag in {"script", "style"}:
                continue
            pieces.append(child.text(include_inert=include_inert))
        return " ".join(" ".join(pieces).split())

    def ancestor_with_class(self, class_name: str) -> Element | None:
        node = self.parent
        while node is not None:
            if node.has_class(class_name):
                return node
            node = node.parent
        return None


class TreeParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.root = Element("document", {})
        self.stack = [self.root]

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        element = Element(tag, {key: value or "" for key, value in attrs}, self.stack[-1])
        self.stack[-1].children.append(element)
        if tag not in VOID_ELEMENTS:
            self.stack.append(element)

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.handle_starttag(tag, attrs)
        if tag not in VOID_ELEMENTS:
            self.stack.pop()

    def handle_endtag(self, tag: str) -> None:
        for index in range(len(self.stack) - 1, 0, -1):
            if self.stack[index].tag == tag:
                del self.stack[index:]
                return

    def handle_data(self, data: str) -> None:
        self.stack[-1].data.append(data)


def parse(content: str) -> Element:
    parser = TreeParser()
    parser.feed(content)
    parser.close()
    return parser.root


def elements(root: Element, *, tag: str | None = None, class_name: str | None = None) -> list[Element]:
    candidates = root.descendants()
    if tag is not None:
        candidates = [candidate for candidate in candidates if candidate.tag == tag]
    if class_name is not None:
        candidates = [candidate for candidate in candidates if candidate.has_class(class_name)]
    return candidates


class GeneratorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.outputs = render_outputs()
        cls.trees = {name: parse(content) for name, content in cls.outputs.items()}

    def test_generation_is_deterministic_and_matches_checked_in_outputs(self) -> None:
        self.assertEqual(self.outputs, render_outputs())
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            first_paths = write_outputs(Path(first))
            second_paths = write_outputs(Path(second))
            self.assertEqual([path.name for path in first_paths], list(OUTPUT_NAMES))
            self.assertEqual(
                {path.name: path.read_bytes() for path in first_paths},
                {path.name: path.read_bytes() for path in second_paths},
            )
        self.assertEqual(check_outputs(REPOSITORY_ROOT), ())

    def test_exact_v3_output_inventory(self) -> None:
        self.assertEqual(tuple(self.outputs), OUTPUT_NAMES)
        self.assertEqual(
            {path.name for path in REPOSITORY_ROOT.glob("*-v3.dc.html")},
            set(OUTPUT_NAMES),
        )
        self.assertEqual(len(OUTPUT_NAMES), 16)

    def test_every_product_frame_has_complete_valid_metadata(self) -> None:
        frame_ids = []
        for tree in self.trees.values():
            frames = elements(tree, class_name="product-frame")
            self.assertTrue(frames)
            for frame in frames:
                self.assertTrue(FRAME_ATTRIBUTES.issubset(frame.attrs), frame.attrs)
                frame_ids.append(frame.attrs["data-frame"])
                self.assertIn(frame.attrs["data-fixture"], FIXTURES)
                self.assertIn(frame.attrs["data-status"], {"real", "guide"})
                self.assertIn(frame.attrs["data-device"], {"844x390", "932x430"})
                self.assertIn(frame.attrs["data-width-class"], {"compact", "regular"})
                self.assertIn(frame.attrs["data-appearance"], {"dark", "light"})
                self.assertIn(frame.attrs["data-type-scale"], {"default", "ax5"})
                self.assertRegex(frame.attrs["data-canon"], r"^04 §")
        self.assertEqual(len(frame_ids), len(set(frame_ids)), "frame IDs must be globally unique")

    def test_displayed_facts_are_fixture_derived_and_consistent(self) -> None:
        occurrences: dict[str, set[str]] = {}
        for tree in self.trees.values():
            for fact in [node for node in tree.descendants() if "data-fact-key" in node.attrs]:
                frame = fact.ancestor_with_class("product-frame")
                self.assertIsNotNone(frame)
                fixture_name = frame.attrs["data-fixture"]
                key = fact.attrs["data-fact-key"]
                self.assertEqual(fact.text(), FIXTURES[fixture_name].fact(key))
                occurrences.setdefault(key, set()).add(fact.text())
        for shared_key in ("college_programme", "college_opponent", "plan", "plan_cost", "pro_organisation"):
            self.assertIn(shared_key, occurrences)
            self.assertEqual(len(occurrences[shared_key]), 1, f"{shared_key} drifted across sheets")

    def test_outputs_are_self_contained_and_have_only_inert_metadata(self) -> None:
        for name, tree in self.trees.items():
            for node in tree.descendants():
                self.assertNotIn("src", node.attrs, f"external source in {name}")
                if node.tag == "link":
                    self.fail(f"linked dependency in {name}")
                if node.tag == "script":
                    self.assertEqual(node.attrs.get("type"), "text/x-dc")
                    self.assertIn("data-reference-manifest", node.attrs)
                for attribute in ("href", "action", "poster"):
                    value = node.attrs.get(attribute, "")
                    self.assertFalse(value.startswith(("http://", "https://", "//")), f"external URL in {name}")
            content = self.outputs[name]
            self.assertNotRegex(content, r"(?i)@import\s|url\s*\(\s*['\"]?(?:https?:)?//|https?://")

    def test_product_copy_excludes_internal_and_component_vocabulary(self) -> None:
        for name, tree in self.trees.items():
            for frame in elements(tree, class_name="product-frame"):
                rendered_text = frame.text()
                for banned in BANNED_FRAME_VOCABULARY:
                    self.assertNotIn(banned, rendered_text, f"{banned!r} leaked into {name}")
                for component in COMPONENT_STATES:
                    self.assertIsNone(
                        re.search(rf"\b{re.escape(component)}\b", rendered_text),
                        f"canonical component name {component!r} leaked into {name}",
                    )
                self.assertIsNone(re.search(r"\b(?:REAL|GUIDE)\b", rendered_text))

    def test_component_inventory_and_applicable_states_are_exact(self) -> None:
        tree = self.trees["Components-v3.dc.html"]
        observed: dict[str, set[str]] = {}
        for specimen in [node for node in tree.descendants() if "data-specimen" in node.attrs]:
            observed.setdefault(specimen.attrs["data-specimen"], set()).add(specimen.attrs["data-specimen-state"])
        self.assertEqual(set(observed), set(COMPONENT_STATES))
        self.assertEqual(len(observed), 22)
        for component, expected_states in COMPONENT_STATES.items():
            self.assertEqual(observed[component], set(expected_states), component)

    def test_required_flow_states_are_all_rendered(self) -> None:
        observed: dict[str, set[str]] = {}
        for tree in self.trees.values():
            for frame in elements(tree, class_name="product-frame"):
                observed.setdefault(frame.attrs["data-flow"], set()).add(frame.attrs["data-state"])
        for flow, states in REQUIRED_FLOW_STATES.items():
            self.assertTrue(states.issubset(observed.get(flow, set())), f"missing {flow}: {states - observed.get(flow, set())}")

    def test_ax5_is_real_typographic_and_layout_output(self) -> None:
        ax5_frames = []
        for tree in self.trees.values():
            ax5_frames.extend(
                frame for frame in elements(tree, class_name="product-frame") if frame.attrs["data-type-scale"] == "ax5"
            )
        self.assertEqual(
            {frame.attrs["data-frame"] for frame in ax5_frames},
            {
                "ax5-inbox",
                "ax5-plan",
                "ax5-save",
                "ax5-match",
                "career-security-ax5",
                "throughput-ax5",
                "throughput-attributes-ax5",
                "tokens-type-ax5",
            },
        )
        for declaration in (
            '--display-size: 60px',
            '--title-size: 56px',
            '--headline-size: 53px',
            '--body-size: 53px',
            '--callout-size: 51px',
            '--caption-size: 43px',
            '--numeral-size: 58px',
        ):
            self.assertIn(declaration, STYLES)
        self.assertRegex(
            STYLES,
            r'\.product-frame\[data-type-scale="ax5"\] \.button \{[^}]*font-size: var\(--callout-size\)',
        )
        self.assertNotRegex(STYLES, r'data-type-scale="ax5"[^}]*\.button\s*\{[^}]*font-size:\s*\d+px')
        for frame in ax5_frames:
            self.assertGreater(len(frame.text()), 20)
            self.assertTrue(
                elements(frame, class_name="ax5-layout")
                or elements(frame, class_name="match-screen")
                or elements(frame, class_name="type-ramp"),
                frame.attrs["data-frame"],
            )
        accessibility = self.trees["Accessibility-v3.dc.html"]
        ax5_inbox = next(frame for frame in elements(accessibility, class_name="product-frame") if frame.attrs["data-frame"] == "ax5-inbox")
        self.assertEqual(len(elements(ax5_inbox, class_name="ax5-inbox-reduction")), 1)
        ax5_save = next(frame for frame in elements(accessibility, class_name="product-frame") if frame.attrs["data-frame"] == "ax5-save")
        self.assertEqual(len(elements(ax5_save, class_name="ax5-save-summary")), 1)
        self.assertEqual(len(elements(ax5_save, class_name="ax5-save-actions")), 1)
        ax5_match = next(frame for frame in elements(accessibility, class_name="product-frame") if frame.attrs["data-frame"] == "ax5-match")
        self.assertEqual(len(elements(ax5_match, class_name="match-exit")), 1)
        self.assertEqual(len(elements(ax5_match, class_name="direction")), 1)
        tokens = self.trees["Tokens-v3.dc.html"]
        type_frame = next(frame for frame in elements(tokens, class_name="product-frame") if frame.attrs["data-frame"] == "tokens-type-ax5")
        self.assertEqual(
            {node.attrs["data-type-role"] for node in type_frame.descendants() if "data-type-role" in node.attrs},
            {"display", "title", "headline", "body", "callout", "caption", "numeral"},
        )
        throughput = self.trees["Throughput-v3.dc.html"]
        ax5_roster = next(frame for frame in elements(throughput, class_name="product-frame") if frame.attrs["data-frame"] == "throughput-ax5")
        self.assertEqual(len(elements(ax5_roster, class_name="ax5-roster-reduction")), 1)
        self.assertEqual(len(elements(ax5_roster, class_name="roster-row")), 1)
        self.assertIn(FIXTURES["college-week"].fact("player_short"), ax5_roster.text())
        self.assertNotIn(FIXTURES["college-week"].fact("player"), ax5_roster.text())

    def test_attribute_rows_bind_label_track_fill_and_accessible_numeral(self) -> None:
        tiers = set()
        rows = []
        for tree in self.trees.values():
            rows.extend(elements(tree, class_name="attribute-row"))
        self.assertTrue(rows)
        for row in rows:
            tiers.add(row.attrs["data-tier"])
            self.assertEqual(len(elements(row, class_name="attribute-label")), 1)
            self.assertEqual(len(elements(row, class_name="attribute-track")), 1)
            fills = elements(row, class_name="rating-fill")
            values = elements(row, class_name="rating-value")
            self.assertEqual(len(fills), 1)
            self.assertEqual(len(values), 1)
            self.assertRegex(fills[0].attrs.get("style", ""), r"--value:\d+%")
            self.assertRegex(values[0].text(), r"^\d+$")
            self.assertTrue(values[0].has_class("light-text") or values[0].has_class("dark-text"))
        self.assertEqual(tiers, {"elite", "good", "average", "poor", "bad"})

    def test_map_lenses_have_complete_matching_region_grouped_twins(self) -> None:
        expected_names = [programme.name for programme in FIXTURES["college-week"].programmes]
        tree = self.trees["League-v3.dc.html"]
        map_frames = [frame for frame in elements(tree, class_name="product-frame") if frame.attrs["data-flow"] == "map"]
        self.assertEqual({frame.attrs["data-state"] for frame in map_frames}, {"reach", "talent", "rivalries"})
        for frame in map_frames:
            maps = elements(frame, class_name="league-map")
            self.assertEqual(len(maps), 1)
            map_marks = [node for node in maps[0].descendants() if "data-map-program-index" in node.attrs]
            self.assertEqual(len(map_marks), 134)
            self.assertEqual(
                sorted(int(mark.attrs["data-map-program-index"]) for mark in map_marks),
                list(range(134)),
            )
            self.assertEqual(maps[0].attrs["data-lens"], frame.attrs["data-state"])
            twins = elements(frame, class_name="semantic-twin")
            self.assertEqual(len(twins), 1)
            twin = twins[0]
            self.assertEqual(twin.attrs["data-lens"], frame.attrs["data-state"])
            self.assertEqual(twin.attrs["data-total-programmes"], "134")
            self.assertEqual(len(elements(twin, class_name="region-group")), 8)
            programmes = [node for node in elements(twin, tag="li") if "data-program-index" in node.attrs]
            self.assertEqual(len(programmes), 134)
            observed_indices = []
            for programme in programmes:
                index = int(programme.attrs["data-program-index"])
                observed_indices.append(index)
                self.assertEqual(elements(programme, tag="span")[0].text(), expected_names[index])
            self.assertEqual(sorted(observed_indices), list(range(134)))
        visual_classes = {
            frame.attrs["data-state"]: {
                class_name
                for mark in [node for node in elements(frame, class_name="league-map")[0].descendants() if "data-map-program-index" in node.attrs]
                for class_name in mark.attrs.get("class", "").split()
                if class_name.startswith("value-")
            }
            for frame in map_frames
        }
        self.assertEqual(visual_classes["reach"], {"value-national", "value-regional", "value-local"})
        self.assertEqual(visual_classes["talent"], {"value-deep", "value-balanced", "value-developing"})
        self.assertEqual(visual_classes["rivalries"], {"value-primary", "value-secondary", "value-none"})

    def test_live_role_is_limited_to_current_activity(self) -> None:
        live_nodes = []
        for tree in self.trees.values():
            live_nodes.extend(node for node in tree.descendants() if node.attrs.get("data-role") == "live")
        self.assertTrue(live_nodes)
        for node in live_nodes:
            frame = node.ancestor_with_class("product-frame")
            self.assertIsNotNone(frame)
            if node.attrs.get("data-token-role") == "live":
                self.assertEqual(frame.attrs["data-flow"], "tokens")
                continue
            flow_state = (frame.attrs["data-flow"], frame.attrs["data-state"])
            self.assertIn(flow_state, LIVE_FLOW_STATES, f"static live role in {frame.attrs['data-frame']}")
        for tree in self.trees.values():
            for selected in elements(tree, class_name="destination"):
                self.assertNotEqual(selected.attrs.get("data-role"), "live")

    def test_match_geometry_direction_exit_and_timed_draft_outcome(self) -> None:
        for tree in self.trees.values():
            for field in elements(tree, class_name="field"):
                marks = elements(field, class_name="player-mark")
                self.assertEqual(len(marks), 22)
                self.assertEqual(sum(mark.attrs.get("data-numbered") == "true" for mark in marks), 13)
                self.assertEqual(sum(mark.attrs.get("data-numbered") == "false" for mark in marks), 9)
                self.assertEqual({mark.attrs.get("data-side") for mark in marks}, {"home", "opponent"})
                self.assertTrue(all(mark.has_class(mark.attrs["data-side"]) for mark in marks))
                self.assertEqual(sum(mark.attrs.get("data-side") == "home" for mark in marks), 11)
                self.assertEqual(sum(mark.attrs.get("data-side") == "opponent" for mark in marks), 11)
        self.assertIn(".player-mark.home { background: var(--team-primary);", STYLES)
        self.assertIn(".player-mark.opponent { background: var(--opponent-primary);", STYLES)
        screens = self.trees["Screens-v3.dc.html"]
        live_match = next(frame for frame in elements(screens, class_name="product-frame") if frame.attrs["data-frame"] == "match-live")
        self.assertIn("Attacking right", live_match.text())
        self.assertIn("→", live_match.text())
        self.assertIn("Leave match", live_match.text())
        offseason_text = self.trees["Offseason-v3.dc.html"].text()
        self.assertIn("Highest-ranked legal option at the biggest need", offseason_text)
        self.assertIn("Tavian Quell", offseason_text)
        self.assertIn("is the pick", offseason_text)

    def test_offer_teaching_and_failure_paths_are_explicit(self) -> None:
        first_run_text = self.trees["FirstRun-v3.dc.html"].text()
        self.assertNotIn(FIXTURES["new-career"].fact("plan_commitment"), first_run_text)
        self.assertIn("Accept appointment", first_run_text)
        teaching_text = self.trees["Teaching-v3.dc.html"].text()
        for path in ("Use recommendation", "Reuse last week", "Compare options", "Commit manual plan"):
            self.assertIn(path, teaching_text)
        failure_text = self.trees["Failure-v3.dc.html"].text()
        for action in ("Try again", "Manage storage", "Continue without saving"):
            self.assertIn(action, failure_text)
        self.assertIn("Changes are not being saved", failure_text)

    def test_first_run_board_and_offer_preserve_a_single_commitment(self) -> None:
        tree = self.trees["FirstRun-v3.dc.html"]
        board = next(frame for frame in elements(tree, class_name="product-frame") if frame.attrs["data-frame"] == "entry-board")
        jobs = elements(board, class_name="job")
        self.assertEqual(len(jobs), 3)
        for job in jobs:
            dimensions = {node.attrs["data-dimension"] for node in job.descendants() if "data-dimension" in node.attrs}
            self.assertEqual(dimensions, {"roster", "resources", "expectation", "patience"})
            self.assertEqual(len(elements(job, class_name="pane-actions")), 1)
            self.assertEqual(len(elements(job, tag="button")), 1)
        offer = next(frame for frame in elements(tree, class_name="product-frame") if frame.attrs["data-frame"] == "entry-offer")
        terms = elements(offer, class_name="terms")
        self.assertEqual(len(terms), 1)
        self.assertEqual({node.text() for node in elements(terms[0], tag="dt")}, {"Role", "Term", "Expectation", "Patience"})
        self.assertNotIn(FIXTURES["new-career"].fact("plan"), offer.text())
        self.assertNotIn(FIXTURES["new-career"].fact("plan_commitment"), offer.text())
        commitments = [node for node in tree.descendants() if node.attrs.get("data-commitment") == "true"]
        self.assertEqual(len(commitments), 1)
        self.assertEqual(commitments[0].text(), "Accept appointment")
        self.assertIn("Accepting closes the other two jobs", offer.text())
        self.assertIn("Go back", offer.text())

    def test_match_and_draft_lifecycle_badges_model_every_state(self) -> None:
        observed_match_states = set()
        observed_draft_states = set()
        for tree in self.trees.values():
            for score_bug in elements(tree, class_name="score-bug"):
                state = score_bug.attrs["data-match-state"]
                observed_match_states.add(state)
                badge = next(node for node in score_bug.descendants() if "data-lifecycle-state" in node.attrs)
                expected = MATCH_LIFECYCLE[state]
                self.assertEqual(badge.attrs["data-lifecycle-state"], state)
                self.assertEqual(badge.text(), expected.label)
                self.assertEqual(badge.attrs.get("data-role") == "live", expected.current)
                if state in {"background-paused", "resumable-return", "exit", "resolved-deferred"}:
                    self.assertNotEqual(badge.text(), "FINAL")
            for draft_bug in elements(tree, class_name="draft-bug"):
                lifecycle_nodes = [node for node in draft_bug.descendants() if "data-lifecycle-state" in node.attrs]
                self.assertEqual(len(lifecycle_nodes), 1)
                badge = lifecycle_nodes[0]
                state = badge.attrs["data-lifecycle-state"]
                observed_draft_states.add(state)
                expected = DRAFT_LIFECYCLE[state]
                self.assertEqual(badge.text(), expected.label)
                self.assertEqual(badge.attrs.get("data-role") == "live", expected.current)
                if state == "expiry-auto-pick":
                    self.assertNotEqual(badge.text(), "PAUSED")
        self.assertEqual(observed_match_states, set(MATCH_LIFECYCLE) - {"aftermath"})
        self.assertEqual(observed_draft_states, set(DRAFT_LIFECYCLE))
        aftermath = parse(_match_body("aftermath").html)
        aftermath_badge = next(node for node in aftermath.descendants() if node.attrs.get("data-lifecycle-state") == "aftermath")
        self.assertEqual(aftermath_badge.text(), "FINAL")
        content_source = (REPOSITORY_ROOT / "design_refs/content.py").read_text(encoding="utf-8")
        self.assertIn("def _score_bug(state: str)", content_source)
        self.assertNotIn("def _score_bug(*, live: bool)", content_source)

    def test_primary_actions_are_pane_bottom_compositions(self) -> None:
        primary_actions = []
        for tree in self.trees.values():
            primary_actions.extend(node for node in tree.descendants() if node.attrs.get("data-action-role") == "primary")
        self.assertTrue(primary_actions)
        for action in primary_actions:
            self.assertIsNotNone(action.ancestor_with_class("pane-actions"), action.text())
        self.assertNotIn("action-row", " ".join(self.outputs.values()))
        self.assertIn(".pane-actions { position: sticky; bottom: 0;", STYLES)
        self.assertIn('data-type-scale="ax5"] .pane-actions { flex-wrap: nowrap;', STYLES)
        continuity = self.trees["Continuity-v3.dc.html"]
        exit_frame = next(frame for frame in elements(continuity, class_name="product-frame") if frame.attrs["data-frame"] == "match-exit")
        exit_container = next(node for node in exit_frame.descendants() if node.attrs.get("data-action-container") == "modal")
        self.assertTrue(exit_container.children[-1].has_class("pane-actions"))
        offseason = self.trees["Offseason-v3.dc.html"]
        draft = next(frame for frame in elements(offseason, class_name="product-frame") if frame.attrs["data-frame"] == "draft-live-pick")
        draft_container = next(node for node in draft.descendants() if node.attrs.get("data-action-container") == "pane")
        self.assertEqual(len(elements(draft_container, class_name="pane-actions")), 1)
        audit_source = (REPOSITORY_ROOT / "scripts/check-design-reference-layout.mjs").read_text(encoding="utf-8")
        self.assertIn("pane actions are not pinned to container bottom", audit_source)
        self.assertIn("getBoundingClientRect().bottom - expectedBottom", audit_source)

    def test_pro_destination_mutates_and_front_office_is_selected(self) -> None:
        career = self.trees["Career-v3.dc.html"]
        arrival = next(frame for frame in elements(career, class_name="product-frame") if frame.attrs["data-frame"] == "pro-arrival")
        arrival_destinations = elements(arrival, class_name="destination")
        self.assertEqual([destination.text() for destination in arrival_destinations], ["Week", "Team", "Front office", "League", "Career"])
        self.assertNotIn("Recruit", [destination.text() for destination in arrival_destinations])
        self.assertEqual(len([node for node in arrival.descendants() if node.attrs.get("data-action-role") == "primary" and node.text() == "Enter preseason"]), 1)
        next_decision = elements(arrival, class_name="arrival-next-decision")
        self.assertEqual(len(next_decision), 1)
        self.assertEqual(elements(next_decision[0], tag="dt")[0].text(), "Next decision")
        self.assertEqual(elements(next_decision[0], tag="dd")[0].text(), FIXTURES["pro-arrival"].fact("first_decision"))
        offseason = self.trees["Offseason-v3.dc.html"]
        for state in {"free-agency", "cap-plan", "contract-offer"}:
            frame = next(frame for frame in elements(offseason, class_name="product-frame") if frame.attrs["data-state"] == state)
            destinations = elements(frame, class_name="destination")
            self.assertEqual([destination.text() for destination in destinations], ["Week", "Team", "Front office", "League", "Career"])
            selected = [destination.text() for destination in destinations if destination.attrs.get("aria-current") == "page"]
            self.assertEqual(selected, ["Front office"])

    def test_match_call_duration_has_one_fixture_source(self) -> None:
        duration = FIXTURES["match-resume"].fact("call_duration")
        self.assertEqual(duration, "18 seconds")
        content_source = (REPOSITORY_ROOT / "design_refs/content.py").read_text(encoding="utf-8")
        self.assertNotIn("18 seconds", content_source)
        occurrences = []
        for tree in self.trees.values():
            occurrences.extend(
                node for node in tree.descendants()
                if node.attrs.get("data-fact-key") == "call_duration"
            )
        self.assertGreaterEqual(len(occurrences), 2)
        self.assertEqual({node.text() for node in occurrences}, {duration})

    def test_match_has_one_composed_voiceover_snap_sentence_at_every_scale(self) -> None:
        expected_parts = tuple(
            FIXTURES["match-resume"].fact(key)
            for key in ("clock", "situation", "field_position", "snap_matchup", "snap_gain", "snap_outcome")
        )
        match_frames = []
        for tree in self.trees.values():
            match_frames.extend(frame for frame in elements(tree, class_name="product-frame") if elements(frame, class_name="match-screen"))
        self.assertTrue(match_frames)
        for frame in match_frames:
            sentences = elements(frame, class_name="snap-voiceover")
            self.assertEqual(len(sentences), 1, frame.attrs["data-frame"])
            self.assertEqual(sentences[0].attrs.get("data-fact-key"), "snap_sentence")
            self.assertEqual(sentences[0].text(), FIXTURES["match-resume"].fact("snap_sentence"))
            for value in expected_parts:
                self.assertIn(value, sentences[0].text())
            self.assertTrue(all(field.attrs.get("aria-hidden") == "true" for field in elements(frame, class_name="field")))
        ax5 = next(frame for frame in match_frames if frame.attrs["data-frame"] == "ax5-match")
        self.assertEqual(len(elements(ax5, class_name="snap-voiceover")), 1)

    def test_invalid_authoring_states_fail_closed(self) -> None:
        renderers = (_match_body, _save_body, _draft_body, _promotion_body, _game_plan_body)
        for renderer in renderers:
            with self.subTest(renderer=renderer.__name__):
                with self.assertRaises(ValueError):
                    renderer("misspelled-state")

    def test_component_states_have_component_specific_visuals(self) -> None:
        tree = self.trees["Components-v3.dc.html"]
        for specimen in [node for node in tree.descendants() if "data-specimen" in node.attrs]:
            component = specimen.attrs["data-specimen"]
            visuals = elements(specimen, class_name="component-visual")
            self.assertEqual(len(visuals), 1, component)
            self.assertTrue(visuals[0].has_class(f"visual-{component.lower()}"), component)
            state = specimen.attrs["data-specimen-state"]
            self.assertTrue(visuals[0].has_class(f"state-{state}"), component)
            self.assertEqual(visuals[0].attrs.get("data-component-state"), state)
            self.assertFalse(specimen.has_class(f"state-{state}"), component)
            has_semantics = bool(visuals[0].text()) or bool(visuals[0].attrs.get("aria-label")) or any(
                descendant.attrs.get("aria-label") for descendant in visuals[0].descendants()
            )
            self.assertTrue(has_semantics, component)
        over_capacity = next(
            node for node in tree.descendants()
            if node.attrs.get("data-specimen") == "Meter" and node.attrs.get("data-specimen-state") == "over-capacity"
        )
        self.assertEqual(len(elements(over_capacity, class_name="mini-meter")), 1)
        self.assertIn("--value:105%", self.outputs["Components-v3.dc.html"])
        average = next(
            node for node in tree.descendants()
            if node.attrs.get("data-specimen") == "AttributeRow" and node.attrs.get("data-specimen-state") == "average"
        )
        self.assertEqual(len(elements(average, class_name="rating-fill")), 1)
        self.assertEqual(len(elements(average, class_name="rating-value")), 1)

        list_twin = next(
            node for node in tree.descendants()
            if node.attrs.get("data-specimen") == "MapCanvas" and node.attrs.get("data-specimen-state") == "list-twin"
        )
        semantic_lists = elements(list_twin, class_name="mini-map-list")
        self.assertEqual(len(semantic_lists), 1)
        semantic_list = semantic_lists[0]
        self.assertEqual(semantic_list.attrs.get("data-lens"), "reach")
        self.assertEqual(semantic_list.attrs.get("data-total-programmes"), "134")
        self.assertEqual(len(elements(semantic_list, class_name="mini-region-group")), 8)
        programmes = elements(semantic_list, tag="li")
        self.assertEqual(len(programmes), 134)
        for programme in programmes:
            fixture_programme = FIXTURES["college-week"].programmes[int(programme.attrs["data-program-index"])]
            self.assertEqual(elements(programme, tag="span")[0].text(), fixture_programme.name)
            self.assertEqual(elements(programme, tag="strong")[0].text(), fixture_programme.reach)
        self.assertIn("max-height: var(--map-visual-height); overflow: auto", STYLES)

        pressed = next(
            node for node in tree.descendants()
            if node.attrs.get("data-specimen") == "PrimaryButton" and node.attrs.get("data-specimen-state") == "pressed"
        )
        pressed_button = elements(pressed, tag="button")
        self.assertEqual(len(pressed_button), 1)
        self.assertEqual(pressed_button[0].attrs.get("aria-pressed"), "true")
        self.assertIn(".visual-primarybutton.state-pressed", STYLES)
        self.assertIn("transform: translateY(var(--space-xs))", STYLES)

        for component, expected_frame in (("FieldCanvas", "components-2"), ("AttributeRow", "components-4")):
            specimens = [node for node in tree.descendants() if node.attrs.get("data-specimen") == component]
            self.assertTrue(specimens)
            self.assertEqual(
                {node.ancestor_with_class("product-frame").attrs["data-frame"] for node in specimens},
                {expected_frame},
            )
        attribute_states = {
            node.attrs["data-specimen-state"]
            for node in tree.descendants()
            if node.attrs.get("data-specimen") == "AttributeRow"
        }
        self.assertTrue({"poor", "bad"}.issubset(attribute_states))
        self.assertIn(".component-grid", STYLES)
        self.assertIn("overflow: auto", STYLES)
        self.assertIn("repeat(auto-fit, minmax(var(--component-column-min), 1fr))", STYLES)
        self.assertIn("grid-auto-rows: max-content", STYLES)
        self.assertIn('.specimen[data-specimen="InboxItem"] { grid-column: span 2; }', STYLES)
        self.assertNotIn("--specimen-height", STYLES)

    def test_broadcast_mapping_and_football_composition_are_complete(self) -> None:
        expected = {
            "college-regular": ("college", "regular", ""),
            "college-conference-championship": ("college", "elimination", "CONFERENCE CHAMPIONSHIP"),
            "college-playoff": ("college", "elimination", "PLAYOFF"),
            "college-final": ("college", "final", "NATIONAL CHAMPIONSHIP"),
            "pro-regular": ("pro", "regular", ""),
            "pro-elimination": ("pro", "elimination", "PLAYOFF"),
            "pro-final": ("pro", "final", "LEAGUE CHAMPIONSHIP"),
        }
        self.assertEqual(
            {key: (value.house, value.escalation, value.label) for key, value in BROADCAST_OCCASIONS.items()},
            expected,
        )
        tree = self.trees["Broadcast-v3.dc.html"]
        frames = elements(tree, class_name="product-frame")
        self.assertEqual(
            {frame.attrs["data-state"] for frame in frames},
            set(expected) | {"college-rivalry"},
        )
        for frame in frames:
            fields = elements(frame, class_name="broadcast-field")
            self.assertEqual(len(fields), 1)
            self.assertEqual(len(elements(fields[0], class_name="player-mark")), 22)
            self.assertEqual(len(elements(fields[0], class_name="line-of-scrimmage")), 1)
            self.assertEqual(len(elements(fields[0], class_name="broadcast-down")), 1)
            self.assertEqual(len(elements(frame, class_name="broadcast-overlay")), 1)
            self.assertEqual(sum(mark.attrs.get("data-side") == "home" for mark in elements(fields[0], class_name="player-mark")), 11)
            self.assertEqual(sum(mark.attrs.get("data-side") == "opponent" for mark in elements(fields[0], class_name="player-mark")), 11)
            down_keys = {node.attrs["data-fact-key"] for node in elements(fields[0], class_name="broadcast-down")[0].descendants() if "data-fact-key" in node.attrs}
            overlay_keys = {node.attrs["data-fact-key"] for node in elements(frame, class_name="broadcast-overlay")[0].descendants() if "data-fact-key" in node.attrs}
            self.assertEqual(down_keys, {"situation", "direction"})
            self.assertEqual(overlay_keys, {"snap_matchup", "snap_gain", "snap_outcome"})
        pro_elimination = next(frame for frame in frames if frame.attrs["data-state"] == "pro-elimination")
        screen = elements(pro_elimination, class_name="broadcast-screen")[0]
        self.assertTrue(screen.has_class("pro"))
        self.assertTrue(screen.has_class("elimination"))
        rivalry = next(frame for frame in frames if frame.attrs["data-state"] == "college-rivalry")
        self.assertEqual(len(elements(rivalry, class_name="rivalry-seam")), 1)
        regulars = [frame for frame in frames if elements(frame, class_name="broadcast-screen")[0].has_class("regular")]
        self.assertEqual(len(regulars), 3)
        for frame in regulars:
            self.assertEqual(len(elements(frame, class_name="occasion")), 0)
            self.assertEqual(len(elements(frame, class_name="broadcast-title-bar")), 0)
        eliminations = [frame for frame in frames if elements(frame, class_name="broadcast-screen")[0].has_class("elimination")]
        self.assertEqual(len(eliminations), 3)
        for frame in eliminations:
            self.assertEqual(len(elements(frame, class_name="occasion")), 1)
            self.assertEqual(len(elements(frame, class_name="broadcast-title-bar")), 0)
        finals = [frame for frame in frames if elements(frame, class_name="broadcast-screen")[0].has_class("final")]
        self.assertEqual(len(finals), 2)
        for frame in finals:
            self.assertEqual(len(elements(frame, class_name="broadcast-corner")), 4)
            title_bars = elements(frame, class_name="broadcast-title-bar")
            self.assertEqual(len(title_bars), 1)
            self.assertEqual(len(elements(frame, class_name="occasion")), 0)
            self.assertTrue(title_bars[0].text())
        for frame in frames:
            if not elements(frame, class_name="broadcast-screen")[0].has_class("final"):
                self.assertEqual(len(elements(frame, class_name="broadcast-corner")), 0)
        for declaration in (
            "--broadcast-bug-regular: 44px",
            "--broadcast-bug-elimination: 48px",
            "--broadcast-bug-final: 52px",
            "--broadcast-title-height: 18px",
            "--college-house-angle: 9deg",
            "tan(var(--college-house-angle))",
            "border-top: 2px solid var(--team-secondary)",
            "border: 2px solid var(--team-secondary)",
            "linear-gradient(90deg,var(--team-secondary) 0 50%,var(--opponent-secondary) 50%)",
        ):
            self.assertIn(declaration, STYLES)

    def test_elevation_uses_appearance_specific_mechanisms(self) -> None:
        tree = self.trees["Tokens-v3.dc.html"]
        dark = next(frame for frame in elements(tree, class_name="product-frame") if frame.attrs["data-state"] == "elevation-dark")
        light = next(frame for frame in elements(tree, class_name="product-frame") if frame.attrs["data-state"] == "elevation-light")
        dark_grid = elements(dark, class_name="elevation-grid")[0]
        light_grid = elements(light, class_name="elevation-grid")[0]
        self.assertEqual(dark_grid.attrs["data-elevation-mechanism"], "surface-hairline-scrim")
        self.assertEqual(light_grid.attrs["data-elevation-mechanism"], "shadow")
        self.assertEqual(len(elements(dark_grid, class_name="elevation-scrim")), 1)
        self.assertEqual(len(elements(light_grid, class_name="elevation-scrim")), 0)
        self.assertEqual(len(elements(dark_grid, class_name="elevation-covered")), 1)
        self.assertEqual(len(elements(dark_grid, class_name="elevation-stage-three")), 1)
        self.assertIn("border: 1px solid rgba(158,158,158,.09)", STYLES)
        self.assertIn("border: 1px solid rgba(158,158,158,.14)", STYLES)
        self.assertIn("border: 1px solid rgba(158,158,158,.22)", STYLES)
        self.assertIn("background: rgba(0,0,0,.22)", STYLES)
        self.assertIn('[data-elevation-mechanism="shadow"] .elevation-three { box-shadow:', STYLES)

    def test_fixture_manifest_is_a_sheet_projection(self) -> None:
        for name, tree in self.trees.items():
            scripts = elements(tree, tag="script")
            self.assertEqual(len(scripts), 1)
            manifest = json.loads(scripts[0].text(include_inert=True))
            observed_keys: dict[str, set[str]] = {}
            for fact in [node for node in tree.descendants() if "data-fact-key" in node.attrs]:
                frame = fact.ancestor_with_class("product-frame")
                observed_keys.setdefault(frame.attrs["data-fixture"], set()).add(fact.attrs["data-fact-key"])
            for fixture_name, projection in manifest["fixtures"].items():
                self.assertEqual(set(projection["facts"]), observed_keys.get(fixture_name, set()))
                if name == "League-v3.dc.html" and fixture_name == "college-week":
                    self.assertEqual(len(projection["programmes"]), 134)
                else:
                    self.assertNotIn("programmes", projection, f"unrelated league data churns {name}")

    def test_cross_sheet_facts_cannot_bypass_fixture_helpers(self) -> None:
        observable_keys: dict[str, set[str]] = {}
        for tree in self.trees.values():
            for fact in [node for node in tree.descendants() if "data-fact-key" in node.attrs]:
                frame = fact.ancestor_with_class("product-frame")
                observable_keys.setdefault(frame.attrs["data-fixture"], set()).add(fact.attrs["data-fact-key"])
        for name, tree in self.trees.items():
            for frame in elements(tree, class_name="product-frame"):
                fixture = FIXTURES[frame.attrs["data-fixture"]]
                for node in [frame, *frame.descendants()]:
                    fact_key = node.attrs.get("data-fact-key")
                    programme_node = node
                    while programme_node is not None and "data-program-index" not in programme_node.attrs:
                        programme_node = programme_node.parent
                    allowed = _fact_dependency_closure(fixture, fact_key) if fact_key else fixture.fact_keys() if programme_node is not None else frozenset()
                    for text in node.data:
                        for key in observable_keys.get(fixture.name, set()):
                            value = fixture.fact(key)
                            covered_by_allowed_fact = any(
                                _normalise_fact(value) in _normalise_fact(fixture.fact(allowed_key))
                                for allowed_key in allowed
                            )
                            if _normalise_fact(value) in _normalise_fact(text) and key not in allowed and not covered_by_allowed_fact:
                                self.fail(
                                    f"{name}:{frame.attrs['data-frame']} renders {key}={value!r} "
                                    "outside its explicit fact record"
                                )

    def test_product_spacing_uses_canonical_tokens(self) -> None:
        product_css = STYLES[STYLES.index(".product-frame {"):]
        guarded_properties = {
            "font-size", "gap", "row-gap", "column-gap", "padding", "padding-top", "padding-right",
            "padding-bottom", "padding-left", "margin", "margin-top", "margin-right", "margin-bottom",
            "margin-left", "top", "right", "bottom", "left", "inset", "width", "height", "min-width",
            "min-height", "max-width", "max-height", "grid-template-columns",
        }
        illegal = []
        for selector, body in re.findall(r"([^{}]+)\{([^{}]*)\}", product_css):
            for property_name, value in re.findall(r"([a-z-]+)\s*:\s*([^;]+)", body):
                if property_name not in guarded_properties or not re.search(r"\d+px", value):
                    continue
                if selector.strip() == ".destination" and property_name == "font-size" and value.strip() == "12px":
                    continue
                illegal.append(f"{selector.strip()} {{{property_name}: {value.strip()}}}")
        self.assertEqual(illegal, [])
        for token in ("xs", "s", "sm", "m", "ml", "l", "xl", "xxl"):
            self.assertIn(f"var(--space-{token})", product_css)
        optical_uses = []
        for selector, body in re.findall(r"([^{}]+)\{([^{}]*)\}", product_css):
            for property_name, value in re.findall(r"([a-z-]+)\s*:\s*([^;]+)", body):
                if "var(--optical-" in value:
                    optical_uses.append((selector.strip(), property_name, value.strip()))
        forbidden_optical_properties = {
            "gap", "row-gap", "column-gap", "padding", "padding-top", "padding-right", "padding-bottom",
            "padding-left", "margin", "margin-top", "margin-right", "margin-bottom", "margin-left", "top",
            "right", "bottom", "left", "inset", "width", "height", "min-width", "min-height", "max-width",
            "max-height", "grid-template-columns",
        }
        self.assertFalse(
            [use for use in optical_uses if use[1] in forbidden_optical_properties],
            "optical tokens cannot define ordinary spacing or frame dimensions",
        )
        self.assertEqual(optical_uses, [(".lower-third", "border-left", "var(--optical-10) solid var(--team-secondary)")])

    def test_live_css_and_rating_tokens_cannot_leak_to_static_roles(self) -> None:
        live_uses = [line for line in STYLES.splitlines() if "var(--live)" in line]
        self.assertTrue(live_uses)
        for line in live_uses:
            self.assertIn('[data-role="live"]', line)
        self.assertIn("--rating-average: #2166A8", STYLES)
        self.assertIn("--rating-numeral-average: #1F6099", STYLES)
        self.assertIn(".rating-fill.average { background-color: var(--rating-average); }", STYLES)
        self.assertIn(".rating-value.average { background-color: var(--rating-numeral-average); }", STYLES)
        self.assertIn("--rating-average: #2E7BC4", STYLES)
        self.assertIn("--frame-info: #0B5FA8", STYLES)

    def test_accent_content_polarity_is_contrast_compliant(self) -> None:
        self.assertGreaterEqual(_contrast("#5B9DFF", "#0E1218"), 4.5)
        self.assertGreaterEqual(_contrast("#1257C7", "#FFFFFF"), 4.5)
        self.assertIn('.button { margin:', STYLES)
        self.assertIn('background: var(--frame-accent); color: #0E1218;', STYLES)
        self.assertIn('.product-frame[data-appearance="light"] .button { color: #FFFFFF; }', STYLES)
        self.assertIn('.swatch-accent { background: var(--frame-accent); color: #0E1218; }', STYLES)

    def test_state_swatches_have_compliant_content_polarity(self) -> None:
        pairs = {
            "dark-positive": ("#57D98A", "#0E1218"),
            "dark-negative": ("#FF6B5A", "#0E1218"),
            "dark-warning": ("#FFB026", "#0E1218"),
            "dark-info": ("#6DB3F2", "#0A0D14"),
            "dark-live": ("#C6F24E", "#0E1218"),
            "light-positive": ("#0B6B3F", "#FFFFFF"),
            "light-negative": ("#C0261B", "#FFFFFF"),
            "light-warning": ("#8A5A00", "#FFFFFF"),
            "light-info": ("#0B5FA8", "#EEF0F4"),
            "light-live": ("#C6F24E", "#0E1218"),
        }
        for role, (background, foreground) in pairs.items():
            with self.subTest(role=role):
                self.assertGreaterEqual(_contrast(background, foreground), 4.5)
        self.assertIn('.product-frame[data-appearance="light"] .swatch-positive', STYLES)
        self.assertIn('.swatch-live[data-role="live"]', STYLES)

    def test_team_colours_are_fixture_tokens_not_component_literals(self) -> None:
        product_css = STYLES[STYLES.index(".product-frame {"):]
        for fixture in FIXTURES.values():
            tokens = dict(fixture.tokens)
            self.assertEqual(
                set(tokens),
                {"team.primary", "team.secondary", "team.onTeam", "opponent.primary", "opponent.secondary", "opponent.onTeam"},
            )
            self.assertGreaterEqual(_contrast(tokens["team.primary"], tokens["team.onTeam"]), 4.5)
            self.assertGreaterEqual(_contrast(tokens["team.primary"], tokens["team.secondary"]), 3.0)
            self.assertGreaterEqual(_contrast(tokens["team.secondary"], "#0E1218"), 4.5)
            self.assertGreaterEqual(_contrast(tokens["opponent.secondary"], "#0E1218"), 4.5)
            self.assertGreaterEqual(_delta_e(tokens["team.primary"], tokens["opponent.primary"]), 25)
            for key in ("team.primary", "team.secondary", "opponent.primary", "opponent.secondary"):
                self.assertNotIn(tokens[key], product_css)
        for variable in ("--team-primary", "--team-secondary", "--team-on", "--opponent-primary", "--opponent-secondary", "--opponent-on"):
            self.assertIn(variable, self.outputs["Broadcast-v3.dc.html"])
        self.assertIn("font: 800 var(--field-notation-size)/1", STYLES)
        self.assertIn("Device-validated notation", STYLES)

    def test_frame_metadata_contract_rejects_invalid_relationships(self) -> None:
        base = {
            "frame_id": "screen-inbox",
            "canon": "04 §4 Week",
            "fixture": "college-week",
            "status": "real",
            "device": "844x390",
            "width_class": "compact",
            "appearance": "dark",
            "type_scale": "default",
            "flow": "screens",
            "state": "inbox",
        }
        FrameMeta(**base)
        invalid = (
            {"status": "draft"},
            {"device": "932x430"},
            {"appearance": "sepia"},
            {"type_scale": "small"},
            {"canon": "UX §4"},
            {"state": "offer"},
            {"fixture": "draft"},
            {"frame_id": "screen-inbox", "type_scale": "ax5"},
        )
        for change in invalid:
            with self.subTest(change=change), self.assertRaises(ValueError):
                FrameMeta(**(base | change))

    def test_frame_fact_records_are_explicit_and_exact(self) -> None:
        generator_source = (REPOSITORY_ROOT / "design_refs/generator.py").read_text(encoding="utf-8")
        self.assertNotIn('re.findall(r\'data-fact-key', generator_source)
        for sheet in build_sheets():
            for frame in sheet.frames:
                tree = parse(frame.body)
                observed = {
                    node.attrs["data-fact-key"]
                    for node in tree.descendants()
                    if "data-fact-key" in node.attrs
                }
                self.assertEqual(frame.fact_keys, observed, f"{sheet.name}:{frame.meta.frame_id}")

    def test_compound_fixture_displays_are_derived_from_atomic_facts(self) -> None:
        model_source = (REPOSITORY_ROOT / "design_refs/model.py").read_text(encoding="utf-8")
        self.assertNotIn('"8-1"', model_source)
        college = FIXTURES["college-week"]
        match = FIXTURES["match-resume"]
        self.assertNotIn("week", dict(college.facts))
        self.assertEqual(college.fact("week"), "Week 10")
        self.assertNotIn("opponent_record", dict(college.facts))
        self.assertEqual(college.fact("opponent_record"), "8-1")
        self.assertNotIn("field_position", dict(match.facts))
        self.assertEqual(match.fact("field_position"), f'{match.fact("college_opponent")} 34')

    def test_output_write_stages_before_atomic_replace(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            paths = write_outputs(root)
            before = {path.name: path.read_bytes() for path in paths}
            with patch.object(generator_module.os, "replace", side_effect=RuntimeError("replace stopped")):
                with self.assertRaises(RuntimeError):
                    write_outputs(root)
            self.assertEqual(before, {path.name: path.read_bytes() for path in paths})
            self.assertEqual(list(root.glob(".v3-design-stage-*")), [])

    def test_map_dimensions_are_independently_encoded(self) -> None:
        programmes = FIXTURES["college-week"].programmes
        dimensions = {
            "reach": tuple(programme.reach for programme in programmes),
            "talent": tuple(programme.talent for programme in programmes),
            "rivalry": tuple(programme.rivalry for programme in programmes),
        }
        self.assertEqual(len(set(dimensions.values())), 3)
        self.assertGreaterEqual(len(set(zip(dimensions["reach"], dimensions["talent"]))), 7)
        self.assertGreaterEqual(len(set(zip(dimensions["reach"], dimensions["rivalry"]))), 7)

    def test_map_geography_and_market_size_are_stable_across_lenses(self) -> None:
        programmes = FIXTURES["college-week"].programmes
        self.assertEqual(len(programmes), 134)
        self.assertTrue(all(0 <= programme.x <= 1000 and 0 <= programme.y <= 700 for programme in programmes))
        self.assertEqual({programme.market_size for programme in programmes}, {1, 2, 3, 4, 5})
        self.assertEqual(len({(programme.x, programme.y) for programme in programmes}), 134)

        tree = self.trees["League-v3.dc.html"]
        frames = [frame for frame in elements(tree, class_name="product-frame") if frame.attrs["data-flow"] == "map"]
        geography_by_lens = {}
        classes_by_lens = {}
        for frame in frames:
            lens = frame.attrs["data-state"]
            marks = [node for node in elements(frame, class_name="league-map")[0].descendants() if "data-map-program-index" in node.attrs]
            geography_by_lens[lens] = {
                int(mark.attrs["data-map-program-index"]): (
                    int(mark.attrs["data-map-x"]),
                    int(mark.attrs["data-map-y"]),
                    int(mark.attrs["data-market-size"]),
                )
                for mark in marks
            }
            classes_by_lens[lens] = {
                int(mark.attrs["data-map-program-index"]): tuple(
                    class_name for class_name in mark.attrs["class"].split() if class_name.startswith("value-")
                )
                for mark in marks
            }
        self.assertEqual(geography_by_lens["reach"], geography_by_lens["talent"])
        self.assertEqual(geography_by_lens["reach"], geography_by_lens["rivalries"])
        self.assertNotEqual(classes_by_lens["reach"], classes_by_lens["talent"])
        self.assertNotEqual(classes_by_lens["reach"], classes_by_lens["rivalries"])
        for selector, body in re.findall(r"([^{}]+)\{([^{}]*)\}", STYLES):
            if '.league-map[data-lens=' in selector:
                self.assertNotRegex(body, r"(?:width|height|left|top)\s*:", selector)

        league_manifest = json.loads(elements(tree, tag="script")[0].text(include_inert=True))
        projected = league_manifest["fixtures"]["college-week"]["programmes"]
        self.assertEqual(len(projected), 134)
        self.assertTrue(all({"x", "y", "marketSize"}.issubset(item) for item in projected))
        self.assertIn('.product-frame[data-width-class="compact"] .map-layout', STYLES)
        self.assertIn("flex-basis: calc(var(--space-xxl) * 4)", STYLES)

    def test_high_risk_light_regular_evidence_and_local_layout_audit_are_present(self) -> None:
        appearance = self.trees["Appearance-v3.dc.html"]
        expected = {
            "appearance-light-map-regular": ("map", "reach"),
            "appearance-light-match-regular": ("match", "resumable-return"),
            "appearance-light-continuity-regular": ("persistence", "continuing-warning"),
            "appearance-light-roster-regular": ("screens", "roster"),
        }
        frames = {frame.attrs["data-frame"]: frame for frame in elements(appearance, class_name="product-frame")}
        for frame_id, (flow, state) in expected.items():
            frame = frames[frame_id]
            self.assertEqual(frame.attrs["data-appearance"], "light")
            self.assertEqual(frame.attrs["data-device"], "932x430")
            self.assertEqual(frame.attrs["data-width-class"], "regular")
            self.assertEqual((frame.attrs["data-flow"], frame.attrs["data-state"]), (flow, state))

        audit_source = (REPOSITORY_ROOT / "scripts/check-design-reference-layout.mjs").read_text(encoding="utf-8")
        for frame_id in {
            *expected,
            "ax5-inbox", "ax5-plan", "ax5-save", "ax5-match", "career-security-ax5",
            "throughput-ax5", "throughput-attributes-ax5", "tokens-type-ax5",
            "entry-board", "entry-offer", "pro-arrival", "match-exit", "draft-live-pick", "map-reach",
            "components-1", "components-2", "components-3", "components-4", "components-5",
            "broadcast-college-regular", "broadcast-college-rivalry",
            "broadcast-college-conference-championship", "broadcast-college-playoff", "broadcast-college-final",
            "broadcast-pro-regular", "broadcast-pro-elimination", "broadcast-pro-final",
            "tokens-elevation-dark", "tokens-elevation-light",
        }:
            self.assertIn(frame_id, audit_source)
        for regression_guard in (
            "commandTimeoutMilliseconds",
            'addEventListener("close"',
            "DevTools socket error",
            "overlapChecks",
            "contrastChecks",
            "is occluded by destination bar",
            "pane actions are not pinned to container bottom",
            "broadcast bug height differs from escalation canon",
            "dark elevation hairline strengths differ",
            "stopChrome",
            'chrome.kill("SIGKILL")',
        ):
            self.assertIn(regression_guard, audit_source)
        self.assertNotRegex(audit_source.lower(), r"playwright|npm")

    def test_tokens_and_offseason_cover_the_full_requested_domains(self) -> None:
        tokens = self.trees["Tokens-v3.dc.html"]
        token_states = {frame.attrs["data-state"] for frame in elements(tokens, class_name="product-frame")}
        self.assertTrue({"rating-cvd", "elevation-dark", "elevation-light"}.issubset(token_states))
        self.assertEqual(len([node for node in tokens.descendants() if "data-cvd" in node.attrs]), 3)
        self.assertEqual(len(elements(tokens, tag="fecolormatrix")), 3)
        token_text = tokens.text()
        for label in ("LIVE", "TEAM PRIMARY", "TEAM SECONDARY", "ON TEAM"):
            self.assertIn(label, token_text)
        offseason = self.trees["Offseason-v3.dc.html"]
        states = {frame.attrs["data-state"] for frame in elements(offseason, class_name="product-frame")}
        self.assertTrue({"free-agency", "cap-plan", "contract-offer"}.issubset(states))
        for phrase in ("Open negotiation", "injury reserve", "Submit offer"):
            self.assertIn(phrase, offseason.text())

    def test_cross_sheet_frames_do_not_reuse_identical_body_evidence(self) -> None:
        locations: dict[str, set[str]] = {}
        for sheet in build_sheets():
            for frame in sheet.frames:
                locations.setdefault(frame.body, set()).add(sheet.name)
        duplicates = [sorted(sheets) for sheets in locations.values() if len(sheets) > 1]
        self.assertEqual(duplicates, [])


if __name__ == "__main__":
    unittest.main()
