"""Shared, non-canonical scenario data for generated design references.

Nothing in this module is a shipping game rule.  The fixtures keep repeated facts
coherent across sheets; canon remains docs/04-UX-AND-DESIGN-SYSTEM.md.
"""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
import re
from string import Formatter


@dataclass(frozen=True)
class LeagueProgramme:
    name: str
    region: str
    reach: str
    talent: str
    rivalry: str


@dataclass(frozen=True)
class ScenarioFixture:
    name: str
    facts: tuple[tuple[str, str], ...]
    derived_facts: tuple[tuple[str, str], ...] = ()
    tokens: tuple[tuple[str, str], ...] = ()
    programmes: tuple[LeagueProgramme, ...] = ()

    def __post_init__(self) -> None:
        direct_keys = [key for key, _ in self.facts]
        derived_keys = [key for key, _ in self.derived_facts]
        token_keys = [key for key, _ in self.tokens]
        if len(direct_keys) != len(set(direct_keys)) or len(derived_keys) != len(set(derived_keys)):
            raise ValueError(f"fixture {self.name!r} contains duplicate fact keys")
        if set(direct_keys) & set(derived_keys):
            raise ValueError(f"fixture {self.name!r} defines a fact both directly and derivationally")
        required_tokens = {"team.primary", "team.secondary", "team.onTeam", "opponent.primary", "opponent.onTeam"}
        if set(token_keys) != required_tokens or len(token_keys) != len(set(token_keys)):
            raise ValueError(f"fixture {self.name!r} must define the exact semantic team token set")
        for key, value in self.tokens:
            if not re.fullmatch(r"#[0-9A-F]{6}", value):
                raise ValueError(f"fixture {self.name!r} token {key!r} is not a six-digit hex colour")
        for key in derived_keys:
            self.fact(key)

    def fact(self, key: str) -> str:
        return self._fact(key, frozenset())

    def _fact(self, key: str, resolving: frozenset[str]) -> str:
        if key in resolving:
            raise ValueError(f"fixture {self.name!r} has a derived-fact cycle at {key!r}")
        direct = dict(self.facts)
        if key in direct:
            return direct[key]
        templates = dict(self.derived_facts)
        try:
            template = templates[key]
        except KeyError as error:
            raise KeyError(f"fixture {self.name!r} has no fact {key!r}") from error
        fields = {
            field_name: self._fact(field_name, resolving | {key})
            for _, field_name, _, _ in Formatter().parse(template)
            if field_name is not None
        }
        return template.format(**fields)

    def fact_keys(self) -> frozenset[str]:
        return frozenset(dict(self.facts)) | frozenset(dict(self.derived_facts))

    def token(self, key: str) -> str:
        try:
            return dict(self.tokens)[key]
        except KeyError as error:
            raise KeyError(f"fixture {self.name!r} has no token {key!r}") from error

    def project(
        self,
        fact_keys: Iterable[str],
        *,
        include_programmes: bool = False,
        include_tokens: bool = False,
    ) -> dict[str, object]:
        projection: dict[str, object] = {
            "name": self.name,
            "facts": {key: self.fact(key) for key in sorted(set(fact_keys))},
        }
        if include_tokens:
            projection["tokens"] = dict(self.tokens)
        if include_programmes:
            projection["programmes"] = [programme.__dict__ for programme in self.programmes]
        return projection


@dataclass(frozen=True)
class FrameBody:
    html: str
    fact_keys: frozenset[str]


@dataclass(frozen=True)
class FrameMeta:
    frame_id: str
    canon: str
    fixture: str
    status: str
    device: str
    width_class: str
    appearance: str
    type_scale: str
    flow: str
    state: str

    def __post_init__(self) -> None:
        _validate_frame_meta(self)

    def attributes(self) -> dict[str, str]:
        return {
            "data-frame": self.frame_id,
            "data-canon": self.canon,
            "data-fixture": self.fixture,
            "data-status": self.status,
            "data-device": self.device,
            "data-width-class": self.width_class,
            "data-appearance": self.appearance,
            "data-type-scale": self.type_scale,
            "data-flow": self.flow,
            "data-state": self.state,
        }


@dataclass(frozen=True)
class FrameSpec:
    meta: FrameMeta
    label: str
    body: str
    fact_keys: frozenset[str]


@dataclass(frozen=True)
class SheetSpec:
    name: str
    title: str
    purpose: str
    frames: tuple[FrameSpec, ...]
    notes: tuple[str, ...] = ()


SHARED_COLLEGE_FACTS = {
    "coach": "Mara Voss",
    "college_programme": "Ashgrove",
    "college_abbreviation": "ASH",
    "college_role": "Head coach",
    "college_opponent": "Wexmoor",
    "opponent_abbreviation": "WEX",
    "conference": "Northstar Conference",
    "college_record": "7-2",
    "week": "Week 10",
    "coordinator": "Nico Sorrell",
    "plan": "Balanced pressure",
    "plan_cost": "Deep passing loses 6 practice reps",
    "player": "Ronan Ashfield-Pell",
    "player_short": "R. Ashfield-Pell",
    "player_rating": "84",
    "board_alternative": "Marlowe State",
}

COLLEGE_TOKENS = {
    "team.primary": "#14294B",
    "team.secondary": "#C8A24A",
    "team.onTeam": "#FFFFFF",
    "opponent.primary": "#7A1F2B",
    "opponent.onTeam": "#FFFFFF",
}

SHARED_PRO_FACTS = {
    "pro_organisation": "Verrick Foundry",
    "pro_role": "Head coach",
    "inherited_cap": "$6.4M over the cap",
    "pro_stakeholder": "Iris Valecourt",
    "first_decision": "Name the offensive coordinator",
}

PRO_TOKENS = {
    "team.primary": "#102A3F",
    "team.secondary": "#7FB2E5",
    "team.onTeam": "#FFFFFF",
    "opponent.primary": "#5A2433",
    "opponent.onTeam": "#FFFFFF",
}


def _facts(*groups: dict[str, str], **extra: str) -> tuple[tuple[str, str], ...]:
    merged: dict[str, str] = {}
    for group in groups:
        merged.update(group)
    merged.update(extra)
    return tuple(sorted(merged.items()))


def _tokens(values: dict[str, str]) -> tuple[tuple[str, str], ...]:
    return tuple(sorted(values.items()))


def _league_programmes() -> tuple[LeagueProgramme, ...]:
    regions = (
        "Aven Reach",
        "Briar March",
        "Cinder Vale",
        "Dunmere Coast",
        "Elder Basin",
        "Fallow Ridge",
        "Gloam Prairie",
        "Harrow Sound",
    )
    roots = (
        "Ashgrove",
        "Bellweather",
        "Cinderhall",
        "Dunmere",
        "Everset",
        "Foxbarrow",
        "Grayhaven",
        "Highmere",
        "Ironvale",
        "Juniper",
        "Kestrel",
        "Larkspur",
        "Morrowfen",
        "Northcross",
        "Oakhurst",
        "Redwater",
        "Stonewick",
    )
    identities = (
        "Wardens",
        "Navigators",
        "Lanterns",
        "Rooks",
        "Forge",
        "Comets",
        "Stags",
        "Watch",
    )
    programmes: list[LeagueProgramme] = []
    for index in range(134):
        region = regions[index % len(regions)]
        root = roots[index % len(roots)]
        identity = identities[(index // len(roots)) % len(identities)]
        programmes.append(
            LeagueProgramme(
                name=f"{root} {identity}",
                region=region,
                reach=("National", "Regional", "Local")[index % 3],
                talent=("Deep", "Balanced", "Developing")[(index * 5 + index // 7) % 3],
                rivalry=("Primary", "Secondary", "None")[(index * 7 + index // 5) % 3],
            )
        )
    if len({programme.name for programme in programmes}) != 134:
        raise AssertionError("league reference names must be unique")
    return tuple(programmes)


FIXTURES: dict[str, ScenarioFixture] = {
    "new-career": ScenarioFixture(
        name="new-career",
        facts=_facts(
            SHARED_COLLEGE_FACTS,
            offer_term="Three-year appointment",
            expectation="Win 6 games",
            patience="Two seasons",
            board_third="Northcross",
            first_stakeholder="Elian Sorrell",
        ),
        derived_facts=(("plan_commitment", "Commit to {plan} for Saturday"),),
        tokens=_tokens(COLLEGE_TOKENS),
    ),
    "college-week": ScenarioFixture(
        name="college-week",
        facts=_facts(
            SHARED_COLLEGE_FACTS,
            opponent_record="8-1",
            verdict="Their run front is the weakness",
            evidence="They allow 5.1 yards a carry; the league average is 4.2",
            recruit="Tavian Quell",
            recruit_cost="18 of 60 weekly contacts",
        ),
        derived_facts=(("plan_commitment", "Commit to {plan} for Saturday"),),
        tokens=_tokens(COLLEGE_TOKENS),
        programmes=_league_programmes(),
    ),
    "match-resume": ScenarioFixture(
        name="match-resume",
        facts=_facts(
            SHARED_COLLEGE_FACTS,
            home_score="17",
            away_score="20",
            clock="3:12",
            situation="3rd and 7",
            field_position="Wexmoor 34",
            direction="Attacking right",
            call="Inside zone",
            call_cost="Passing tendency rises next drive",
            last_save_time="14:32",
            final_home_score="24",
        ),
        derived_facts=(
            ("last_save", "{week}, {last_save_time}"),
            ("match_result", "{college_programme} {final_home_score}, {college_opponent} {away_score}"),
            ("plan_commitment", "Commit to {plan} for Saturday"),
        ),
        tokens=_tokens(COLLEGE_TOKENS),
    ),
    "draft": ScenarioFixture(
        name="draft",
        facts=_facts(
            SHARED_PRO_FACTS,
            draft_round="Round 2",
            draft_pick="Pick 41",
            draft_clock="1:18",
            draft_coordinator="Lena Varro",
            draft_prospect="Tavian Quell",
            draft_position="Edge",
            draft_floor="74",
            draft_projection="82",
            draft_reason="Highest-ranked legal option at the biggest need",
            free_agent="Oren Vale",
            free_agent_position="Cornerback",
            free_agent_ask="$8.2M for two years",
            cap_space="$11.6M available",
            contract_guarantee="$5.4M guaranteed",
            contract_cost="A signing leaves $3.4M for injury cover",
        ),
        tokens=_tokens(PRO_TOKENS),
    ),
    "promotion": ScenarioFixture(
        name="promotion",
        facts=_facts(
            SHARED_COLLEGE_FACTS,
            SHARED_PRO_FACTS,
            decline_cost="The offer closes this week",
        ),
        derived_facts=(
            ("promotion_cost", "Leave {college_programme} after the bowl"),
            ("plan_commitment", "Commit to {plan} for Saturday"),
        ),
        tokens=_tokens(PRO_TOKENS),
    ),
    "pro-arrival": ScenarioFixture(
        name="pro-arrival",
        facts=_facts(
            SHARED_COLLEGE_FACTS,
            SHARED_PRO_FACTS,
            arrival_week="Preseason, Week 1",
            owner_voice="Stabilise the cap before you chase the division",
        ),
        derived_facts=(("plan_commitment", "Commit to {plan} for Saturday"),),
        tokens=_tokens(PRO_TOKENS),
    ),
}


FLOW_STATES: dict[str, frozenset[str]] = {
    "accessibility": frozenset({"ax5-inbox", "ax5-game-plan"}),
    "appearance": frozenset({"dark-floor", "light-floor", "dark-ceiling", "light-ceiling"}),
    "broadcast": frozenset({"college-regular", "college-elimination", "college-final", "pro-regular", "pro-final"}),
    "career": frozenset({"job-security", "job-security-ax5"}),
    "components": frozenset({"state-inventory"}),
    "draft": frozenset({"live-pick", "background-paused", "foreground-resumed", "user-selection", "expiry-auto-pick"}),
    "entry": frozenset({"no-career", "board", "offer", "accepted-appointment", "continue-exact"}),
    "failure": frozenset({"refusal", "empty"}),
    "front-office": frozenset({"free-agency", "cap-plan", "contract-offer"}),
    "league": frozenset({"standings"}),
    "map": frozenset({"reach", "talent", "rivalries"}),
    "match": frozenset({"live", "awaiting-input", "background-paused", "foreground-resumed", "resolved-deferred", "exit", "resumable-return", "aftermath"}),
    "persistence": frozenset({"saving", "saved", "failed", "continuing-warning", "recovered"}),
    "promotion": frozenset({"offered", "declined", "accepted", "pro-arrival"}),
    "screens": frozenset({"inbox", "opponent-report", "game-plan", "roster"}),
    "squad": frozenset({"game-plan", "practice", "player"}),
    "system": frozenset({"advancing-week", "confirmation", "settings"}),
    "teaching": frozenset({"recommended", "reuse", "compare", "manual"}),
    "throughput": frozenset({"controls", "batch", "attributes", "roster-ax5", "attributes-ax5"}),
    "tokens": frozenset({"colour-dark", "colour-light", "rating-dark", "rating-light", "rating-cvd", "elevation-dark", "elevation-light", "type-default", "type-ax5", "spacing-radius"}),
}

FLOW_FIXTURES: dict[str, frozenset[str]] = {
    "accessibility": frozenset({"college-week"}),
    "appearance": frozenset({"college-week"}),
    "broadcast": frozenset({"match-resume", "draft"}),
    "career": frozenset({"college-week"}),
    "components": frozenset({"college-week", "match-resume"}),
    "draft": frozenset({"draft"}),
    "entry": frozenset({"new-career", "match-resume"}),
    "failure": frozenset({"college-week"}),
    "front-office": frozenset({"draft"}),
    "league": frozenset({"college-week"}),
    "map": frozenset({"college-week"}),
    "match": frozenset({"match-resume"}),
    "persistence": frozenset({"match-resume"}),
    "promotion": frozenset({"promotion", "pro-arrival"}),
    "screens": frozenset({"college-week"}),
    "squad": frozenset({"college-week"}),
    "system": frozenset({"match-resume", "new-career", "college-week"}),
    "teaching": frozenset({"college-week"}),
    "throughput": frozenset({"college-week"}),
    "tokens": frozenset({"college-week"}),
}


def _validate_frame_meta(meta: FrameMeta) -> None:
    if meta.fixture not in FIXTURES:
        raise ValueError(f"unknown fixture {meta.fixture!r}")
    if meta.status not in {"real", "guide"}:
        raise ValueError(f"invalid status {meta.status!r}")
    if meta.appearance not in {"dark", "light"}:
        raise ValueError(f"invalid appearance {meta.appearance!r}")
    if meta.type_scale not in {"default", "ax5"}:
        raise ValueError(f"invalid type scale {meta.type_scale!r}")
    device_widths = {"844x390": "compact", "932x430": "regular"}
    if device_widths.get(meta.device) != meta.width_class:
        raise ValueError(f"device {meta.device!r} cannot use width class {meta.width_class!r}")
    if not re.fullmatch(r"04 §\S(?:.*\S)?", meta.canon):
        raise ValueError(f"invalid canon anchor {meta.canon!r}")
    if meta.flow not in FLOW_STATES or meta.state not in FLOW_STATES[meta.flow]:
        raise ValueError(f"state {meta.state!r} does not belong to flow {meta.flow!r}")
    if meta.fixture not in FLOW_FIXTURES[meta.flow]:
        raise ValueError(f"fixture {meta.fixture!r} does not belong to flow {meta.flow!r}")
    if meta.type_scale == "ax5" and "ax5" not in meta.frame_id:
        raise ValueError("AX5 frames must identify the binding type-scale case in their frame id")
    if meta.appearance == "light" and "light" not in meta.frame_id:
        raise ValueError("light-appearance frames must identify light appearance in their frame id")


COMPONENT_STATES: dict[str, tuple[str, ...]] = {
    "Card": ("default", "selected"),
    "Row": ("default", "selected", "disabled"),
    "StatCell": ("default", "selected"),
    "Chip": ("default", "selected", "disabled"),
    "Meter": ("default", "over-capacity"),
    "Badge": ("default", "live"),
    "SegmentedControl": ("default", "selected", "disabled"),
    "PrimaryButton": ("default", "pressed", "disabled", "loading"),
    "DestructiveButton": ("default", "confirmation", "disabled"),
    "InboxItem": ("unread", "resolved"),
    "CallInCard": ("awaiting", "accepted", "deferred", "paused"),
    "FieldCanvas": ("formation", "key-moment", "outcome"),
    "EmptyState": ("empty", "action"),
    "ErrorBanner": ("error", "recovery"),
    "OpposedBar": ("neutral", "outlier"),
    "Sparkline": ("positive", "negative"),
    "LowerThird": ("default", "ax5-reduced"),
    "ScoreBug": ("full", "compact", "live"),
    "StakeholderCard": ("default", "dissatisfied"),
    "MapCanvas": ("reach", "talent", "rivalries", "list-twin"),
    "ListControls": ("default", "active", "multi-select", "collapsed"),
    "AttributeRow": ("elite", "good", "average", "poor", "bad"),
}


REQUIRED_FLOW_STATES: dict[str, frozenset[str]] = {
    "entry": frozenset({"no-career", "board", "offer", "accepted-appointment", "continue-exact"}),
    "match": frozenset(
        {
            "live",
            "awaiting-input",
            "background-paused",
            "foreground-resumed",
            "resolved-deferred",
            "exit",
            "resumable-return",
            "aftermath",
        }
    ),
    "draft": frozenset(
        {"live-pick", "background-paused", "foreground-resumed", "user-selection", "expiry-auto-pick"}
    ),
    "map": frozenset({"reach", "talent", "rivalries"}),
    "persistence": frozenset({"saving", "saved", "failed", "continuing-warning", "recovered"}),
    "promotion": frozenset({"offered", "declined", "accepted", "pro-arrival"}),
}


LIVE_FLOW_STATES = frozenset(
    {
        ("match", "live"),
        ("match", "awaiting-input"),
        ("match", "foreground-resumed"),
        ("draft", "live-pick"),
        ("draft", "foreground-resumed"),
        ("persistence", "saving"),
        ("system", "advancing-week"),
        ("components", "state-inventory"),
        ("broadcast", "college-regular"),
        ("broadcast", "college-elimination"),
        ("broadcast", "college-final"),
        ("broadcast", "pro-regular"),
        ("broadcast", "pro-final"),
    }
)


BANNED_FRAME_VOCABULARY = (
    "PlayCall.",
    "DriveEnding",
    "fieldGoal",
    "missedFieldGoal",
    "endOfQuarter",
    "endOfHalf",
    "ARCHETYPE",
    "ScenarioFixture",
    "FrameMeta",
    "SwiftUI",
    "data-canon",
    "data-fixture",
    "TODO",
    "lorem ipsum",
    "placeholder",
)
