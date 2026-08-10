"""Product-frame content for the generated V3 reference sheets."""

from __future__ import annotations

from collections.abc import Iterable
from contextvars import ContextVar
from functools import wraps
from html import escape
from typing import Callable, ParamSpec

from .model import (
    BROADCAST_OCCASIONS,
    BROADCAST_RIVALRY,
    COMPONENT_STATES,
    DRAFT_LIFECYCLE,
    FIXTURES,
    MATCH_LIFECYCLE,
    BroadcastOccasion,
    FrameBody,
    FrameMeta,
    FrameSpec,
    LifecycleBadge,
    SheetSpec,
)


P = ParamSpec("P")
_ACTIVE_FACT_KEYS: ContextVar[set[str] | None] = ContextVar("active_fact_keys", default=None)


def _records_facts(renderer: Callable[P, str]) -> Callable[P, FrameBody]:
    @wraps(renderer)
    def recorded(*args: P.args, **kwargs: P.kwargs) -> FrameBody:
        fact_keys: set[str] = set()
        token = _ACTIVE_FACT_KEYS.set(fact_keys)
        try:
            html = renderer(*args, **kwargs)
        finally:
            _ACTIVE_FACT_KEYS.reset(token)
        return FrameBody(html=html, fact_keys=frozenset(fact_keys))

    return recorded


def _require_one_of(value: str, allowed: set[str], surface: str) -> None:
    if value not in allowed:
        raise ValueError(f"unsupported {surface} state {value!r}; expected one of {sorted(allowed)!r}")


REAL_COMPACT = ("real", "844x390", "compact", "dark", "default")
GUIDE_COMPACT = ("guide", "844x390", "compact", "dark", "default")
AX5_COMPACT = ("real", "844x390", "compact", "dark", "ax5")
LIGHT_COMPACT = ("real", "844x390", "compact", "light", "default")
REAL_REGULAR = ("real", "932x430", "regular", "dark", "default")
LIGHT_REGULAR = ("real", "932x430", "regular", "light", "default")


def _meta(
    frame_id: str,
    canon: str,
    fixture: str,
    flow: str,
    state: str,
    presentation: tuple[str, str, str, str, str],
) -> FrameMeta:
    status, device, width_class, appearance, type_scale = presentation
    return FrameMeta(
        frame_id=frame_id,
        canon=canon,
        fixture=fixture,
        status=status,
        device=device,
        width_class=width_class,
        appearance=appearance,
        type_scale=type_scale,
        flow=flow,
        state=state,
    )


def _frame(meta: FrameMeta, label: str, body: FrameBody) -> FrameSpec:
    if not isinstance(body, FrameBody):
        raise TypeError("frame bodies must be rendered through an explicit fact record")
    return FrameSpec(meta=meta, label=label, body=body.html, fact_keys=body.fact_keys)


def _fact(fixture_name: str, key: str, *, class_name: str = "") -> str:
    value = FIXTURES[fixture_name].fact(key)
    collector = _ACTIVE_FACT_KEYS.get()
    if collector is None:
        raise RuntimeError("fixture facts may only render inside a recorded frame body")
    collector.add(key)
    class_attribute = f' class="{escape(class_name)}"' if class_name else ""
    return f'<span data-fact-key="{escape(key)}"{class_attribute}>{escape(value)}</span>'


def _button(
    label: str,
    *,
    kind: str = "primary",
    disabled: bool = False,
    commitment: bool = False,
) -> str:
    disabled_attribute = " disabled aria-disabled=\"true\"" if disabled else ""
    role_attribute = ' data-action-role="primary"' if kind == "primary" else ""
    commitment_attribute = ' data-commitment="true"' if commitment else ""
    return (
        f'<button class="button {escape(kind)}"{role_attribute}{commitment_attribute}'
        f'{disabled_attribute}>{escape(label)}</button>'
    )


def _actions(*buttons: str, class_name: str = "") -> str:
    classes = "pane-actions"
    if class_name:
        classes += f" {escape(class_name)}"
    return f'<div class="{classes}">{"".join(buttons)}</div>'


def _screen(
    title: str,
    content: str,
    *,
    nav: str | None = None,
    tier: str = "college",
    class_name: str = "",
) -> str:
    navigation = _destination_bar(nav, tier=tier) if nav else ""
    screen_classes = ["app-screen", "with-destination" if nav else "without-destination"]
    if class_name:
        screen_classes.append(class_name)
    return (
        f'<div class="{escape(" ".join(screen_classes))}">'
        '<div class="status-bar"><span>9:41</span><span>86%</span></div>'
        f'<header class="app-header"><h2>{escape(title)}</h2></header>'
        f'<div class="app-content">{content}</div>{navigation}'
        '<div class="home-indicator" aria-hidden="true"></div></div>'
    )


def _destination_bar(selected: str, *, tier: str = "college") -> str:
    _require_one_of(tier, {"college", "pro"}, "destination tier")
    items = ("Week", "Team", "Recruit" if tier == "college" else "Front office", "League", "Career")
    rendered = []
    for item in items:
        selected_class = " selected" if item == selected else ""
        selected_attribute = ' aria-current="page"' if item == selected else ""
        rendered.append(
            f'<button class="destination{selected_class}"{selected_attribute}>'
            f'<span class="destination-mark" aria-hidden="true"></span>{item}</button>'
        )
    return f'<nav class="destination-bar" aria-label="Destinations">{"".join(rendered)}</nav>'


def _panel(title: str, content: str, *, class_name: str = "") -> str:
    return f'<section class="panel {escape(class_name)}"><h3>{escape(title)}</h3>{content}</section>'


def _state_tag(text: str, *, live: bool = False) -> str:
    live_attributes = ' data-role="live" class="state-tag is-live"' if live else ' class="state-tag"'
    return f'<span{live_attributes}>{escape(text)}</span>'


def _lifecycle_tag(state: str, presentation: LifecycleBadge) -> str:
    current_attributes = ' data-role="live" class="state-tag is-live"' if presentation.current else ' class="state-tag"'
    return f'<span data-lifecycle-state="{escape(state)}"{current_attributes}>{escape(presentation.label)}</span>'


@_records_facts
def _inbox_body(*, ax5: bool = False) -> str:
    fixture = "college-week"
    first = (
        '<article class="inbox-item selected"><div><strong>Set Saturday plan</strong>'
        f'<p>{_fact(fixture, "plan_cost")}</p></div><span class="cost">ANSWER</span></article>'
    )
    if ax5:
        return _screen("Week", first + '<p class="ax5-note">One decision at a time. The cost remains visible.</p>', nav="Week", class_name="ax5-layout")
    second = (
        '<article class="inbox-item"><div><strong>Recruiting visit</strong>'
        f'<p>{_fact(fixture, "recruit_cost")}</p></div><span class="cost">DECIDE</span></article>'
    )
    detail = _panel(
        "Set Saturday plan",
        f'<p class="verdict">{_fact(fixture, "college_opponent")} gives ground between the tackles.</p>'
        f'<p>{_fact(fixture, "evidence")}</p>{_actions(_button("Open game plan"))}',
    )
    return _screen("Week", f'<div class="two-pane"><div class="rail">{first}{second}</div>{detail}</div>', nav="Week")


@_records_facts
def _game_plan_body(mode: str, *, ax5: bool = False, evidence: str = "teaching") -> str:
    _require_one_of(mode, {"teach", "reuse", "compare", "manual"}, "game-plan")
    _require_one_of(evidence, {"teaching", "screens", "squad", "accessibility"}, "game-plan evidence")
    fixture = "college-week"
    evidence_copy = {
        "teaching": "Choose after the trade-off is visible.",
        "screens": "Two defensible plans, one Saturday commitment.",
        "squad": "The selected plan sets this week’s practice allocation.",
        "accessibility": "The recommendation and cost remain together at the largest text size.",
    }[evidence]
    recommendation = ""
    if not ax5 and mode in {"teach", "reuse", "compare"}:
        recommendation = (
            '<article class="choice selected"><span class="selection-mark" aria-hidden="true"></span>'
            f'<div><strong>{_fact(fixture, "plan")}</strong><p>{_fact(fixture, "plan_cost")}</p></div></article>'
        )
    alternative = '<article class="choice"><div><strong>Attack the edge</strong><p>Inside runs lose 5 practice reps</p></div></article>'
    if mode == "teach":
        content = (
            '<p class="eyebrow">RECOMMENDED FOR THIS OPPONENT</p>'
            f'{recommendation}<p class="teaching-copy">Start with the recommendation. You can compare or adjust once its trade-off is clear.</p>'
            f'{_actions(_button("Use recommendation"), _button("Compare options", kind="secondary"), _button("Adjust manually", kind="quiet"))}'
        )
    elif mode == "reuse":
        content = (
            '<p class="eyebrow">LAST WEEK, REUSED</p>'
            f'{recommendation}<p>Reusing saves setup time; {_fact(fixture, "college_opponent")} has already seen these tendencies.</p>'
            f'{_actions(_button("Reuse last week"), _button("Compare options", kind="secondary"))}'
        )
    elif mode == "compare":
        content = f'<div class="choice-grid">{recommendation}{alternative}</div>{_actions(_button("Commit selected plan"))}'
    else:
        content = (
            '<div class="manual-grid"><label>Run focus<select><option>Inside</option><option>Edge</option></select></label>'
            '<label>Pressure<select><option>Balanced</option><option>Aggressive</option></select></label></div>'
            f'<p class="cost-line">{_fact(fixture, "plan_cost")}</p>{_actions(_button("Commit manual plan"))}'
        )
    class_name = "ax5-layout" if ax5 else ""
    if ax5:
        content = (
            '<article class="ax5-plan-reduction" data-authored-reduction="single-recommendation">'
            f'<strong>{_fact(fixture, "plan")}</strong><p>{_fact(fixture, "plan_cost_short")}</p></article>'
            f'{_actions(_button("Commit plan"))}'
        )
    else:
        content = f'<p class="domain-evidence">{evidence_copy}</p>{content}'
    return _screen("Game plan", content, nav="Week", class_name=class_name)


@_records_facts
def _offer_body() -> str:
    fixture = "new-career"
    content = (
        '<p class="eyebrow">THE OFFER</p>'
        f'<h1>{_fact(fixture, "college_programme")}</h1>'
        '<dl class="terms">'
        f'<div><dt>Role</dt><dd>{_fact(fixture, "college_role")}</dd></div><div><dt>Term</dt><dd>{_fact(fixture, "offer_term")}</dd></div>'
        f'<div><dt>Expectation</dt><dd>{_fact(fixture, "expectation")}</dd></div><div><dt>Patience</dt><dd>{_fact(fixture, "patience")}</dd></div></dl>'
        '<p class="cost-line">Accepting closes the other two jobs.</p>'
        f'{_actions(_button("Accept appointment", commitment=True), _button("Go back", kind="secondary"))}'
    )
    return _screen("Your offer", content)


@_records_facts
def _board_body() -> str:
    fixture = "new-career"
    choices = (
        '<article class="job"><strong>' + _fact(fixture, "college_programme") + '</strong>'
        '<dl class="job-dimensions"><div data-dimension="roster"><dt>Roster</dt><dd>85 scholarships</dd></div>'
        '<div data-dimension="resources"><dt>Resources</dt><dd>Balanced</dd></div>'
        f'<div data-dimension="expectation"><dt>Expectation</dt><dd>{_fact(fixture, "expectation")}</dd></div>'
        f'<div data-dimension="patience"><dt>Patience</dt><dd>{_fact(fixture, "patience")}</dd></div></dl>'
        f'{_actions(_button("Review offer", kind="secondary"))}</article>'
        f'<article class="job"><strong>{_fact(fixture, "board_alternative")}</strong>'
        '<dl class="job-dimensions"><div data-dimension="roster"><dt>Roster</dt><dd>Thin</dd></div>'
        '<div data-dimension="resources"><dt>Resources</dt><dd>Strong</dd></div>'
        '<div data-dimension="expectation"><dt>Expectation</dt><dd>Reach a bowl</dd></div>'
        '<div data-dimension="patience"><dt>Patience</dt><dd>Three seasons</dd></div></dl>'
        f'{_actions(_button("Review offer", kind="secondary"))}</article>'
        f'<article class="job"><strong>{_fact(fixture, "board_third")}</strong>'
        '<dl class="job-dimensions"><div data-dimension="roster"><dt>Roster</dt><dd>Veteran</dd></div>'
        '<div data-dimension="resources"><dt>Resources</dt><dd>Limited</dd></div>'
        '<div data-dimension="expectation"><dt>Expectation</dt><dd>Win now</dd></div>'
        '<div data-dimension="patience"><dt>Patience</dt><dd>One season</dd></div></dl>'
        f'{_actions(_button("Review offer", kind="secondary"))}</article>'
    )
    return _screen("Choose your first job", f'<p class="verdict">Three jobs. Compare every cost before choosing.</p><div class="job-board">{choices}</div>')


@_records_facts
def _appointment_body() -> str:
    fixture = "new-career"
    content = (
        '<p class="eyebrow">APPOINTED</p>'
        f'<h1>Welcome to {_fact(fixture, "college_programme")}</h1>'
        f'<blockquote>“Win the room before you win the league.”<cite>{_fact(fixture, "first_stakeholder")}, athletic director</cite></blockquote>'
        f'{_actions(_button("Meet your staff"))}'
    )
    return _screen("The appointment", content, class_name="team-surface")


@_records_facts
def _continue_body(*, exact_match: bool = False) -> str:
    fixture = "match-resume" if exact_match else "new-career"
    if exact_match:
        detail = (
            f'<strong>Resume {_fact(fixture, "college_programme")} at {_fact(fixture, "college_opponent")}</strong>'
            f'<p>{_fact(fixture, "clock")} left · {_fact(fixture, "situation")} · saved after leaving the match</p>'
        )
    else:
        detail = '<strong>No career yet</strong><p>Build a coach and choose from three open jobs.</p>'
    return _screen("Pro Football Coach", f'<article class="continue-card">{detail}</article>{_actions(_button("Continue" if exact_match else "Start a new career"))}')


@_records_facts
def _opponent_report_body() -> str:
    fixture = "college-week"
    bars = (
        f'<div class="opposed"><span>{_fact(fixture, "college_programme")} 4.8</span><div><i style="--value:48%"></i></div><span>{_fact(fixture, "college_opponent")} 5.1</span></div>'
        f'<div class="opposed"><span>{_fact(fixture, "college_programme")} 7.2</span><div><i style="--value:72%"></i></div><span>{_fact(fixture, "college_opponent")} 6.4</span></div>'
    )
    content = (
        f'<p class="verdict">{_fact(fixture, "verdict")}.</p>'
        f'<p>{_fact(fixture, "evidence")}.</p>{bars}'
    )
    return _screen("Opponent report", content, nav="Week")


def _attribute_row(label: str, value: int | str, tier: str, width: int, polarity: str) -> str:
    return (
        f'<div class="attribute-row" data-tier="{escape(tier)}">'
        f'<span class="attribute-label">{escape(label)}</span><span class="attribute-track">'
        f'<i class="rating-fill {escape(tier)}" style="--value:{width}%"></i></span>'
        f'<span class="rating-value {escape(tier)} {escape(polarity)}">{value}</span></div>'
    )


@_records_facts
def _player_body(*, ax5: bool = False, evidence: str = "player") -> str:
    _require_one_of(evidence, {"player", "throughput"}, "player evidence")
    fixture = "college-week"
    rows = (
        _attribute_row("Vision", 91, "elite", 91, "light-text")
        + _attribute_row("Burst", _fact(fixture, "player_rating"), "good", 84, "light-text")
        + _attribute_row("Balance", 76, "average", 76, "light-text")
        + _attribute_row("Hands", 67, "poor", 67, "dark-text")
        + _attribute_row("Discipline", 58, "bad", 58, "dark-text")
    )
    if ax5:
        rows = _attribute_row("Burst", _fact(fixture, "player_rating"), "good", 84, "light-text")
        content = f'<p class="ax5-reduction">{_fact(fixture, "player_short")} · WR</p><div class="ax5-attribute">{rows}</div>'
    else:
        content = (
            f'<p class="domain-evidence">{("Five coachable traits set the development priority." if evidence == "player" else "Track, fill, and numeral stay bound while the list scrolls.")}</p>'
            f'<div class="player-title"><div><h1>{_fact(fixture, "player")}</h1><p>WR · Junior · rating {_fact(fixture, "player_rating")}</p></div></div>{rows}'
        )
    return _screen("Player", content, nav="Team", class_name="ax5-layout" if ax5 else "")


@_records_facts
def _roster_body(*, batch: bool = False, ax5: bool = False, evidence: str = "roster") -> str:
    _require_one_of(evidence, {"roster", "throughput", "appearance"}, "roster evidence")
    fixture = "college-week"
    controls = (
        '<div class="list-controls"><button>Position: LB</button><button>Sort: rating</button>'
        '<label>Search <input value=""></label><button>Columns: coaching</button></div>'
    )
    if ax5:
        controls = '<button class="button secondary">Filter and sort</button><p>11 of 105 · LB · by rating</p>'
    rows = []
    names: tuple[str | None, ...] = (None, "Dara Okoro-Vance", "Cai Vanders", "Milo Kest", "Ari Tolland", "Noa Serrin")
    for index, name in enumerate(names[:3] if ax5 else names):
        checked = " checked" if batch and index < 2 else ""
        rendered_name = _fact(fixture, "player") if name is None else escape(name)
        rows.append(
            f'<article class="roster-row"><input type="checkbox" aria-label="Select roster player"{checked}>'
            f'<strong>{rendered_name}</strong><span>{91 - index * 4}</span></article>'
        )
    action = '<div class="batch-bar">2 selected · Release both, 2 scholarships back</div>' if batch else ""
    evidence_copy = {
        "roster": "Six players visible with persistent controls.",
        "throughput": "One filter grammar supports selection and batch consequence.",
        "appearance": "Regular width keeps the dense roster and controls together in light appearance.",
    }[evidence]
    return _screen("Roster", f'<p class="domain-evidence">{evidence_copy}</p>' + controls + "".join(rows) + action, nav="Team", class_name="ax5-layout" if ax5 else "")


def _field_marks() -> str:
    numbered = (
        ("12", 38, 50, "home"), ("22", 44, 24, "home"), ("83", 47, 67, "home"),
        ("18", 53, 18, "home"), ("33", 56, 78, "home"), ("1", 64, 40, "opponent"),
        ("7", 66, 58, "opponent"), ("4", 71, 14, "opponent"), ("9", 73, 86, "opponent"),
        ("21", 78, 31, "opponent"), ("28", 81, 69, "opponent"), ("41", 86, 45, "opponent"),
        ("55", 89, 56, "opponent"),
    )
    blanks = (
        (50, 44, "home"), (50.9, 47, "home"), (51.8, 50, "home"), (52.7, 53, "home"),
        (53.6, 56, "home"), (59, 44, "opponent"), (59.9, 47, "opponent"),
        (60.8, 50, "opponent"), (61.7, 53, "opponent"),
    )
    marks = [
        f'<span class="player-mark numbered {side}" data-numbered="true" data-side="{side}" style="--x:{x}%;--y:{y}%">{number}</span>'
        for number, x, y, side in numbered
    ]
    marks.extend(
        f'<span class="player-mark interior {side}" data-numbered="false" data-side="{side}" aria-hidden="true" style="--x:{x}%;--y:{y}%"></span>'
        for x, y, side in blanks
    )
    return "".join(marks)


def _score_bug(state: str) -> str:
    fixture = "match-resume"
    lifecycle = MATCH_LIFECYCLE[state]
    return (
        f'<div class="score-bug" data-match-state="{escape(state)}"><span>{_fact(fixture, "college_abbreviation")}</span>'
        f'<strong>{_fact(fixture, "home_score")}</strong><strong>{_fact(fixture, "away_score")}</strong>'
        f'<span>{_fact(fixture, "opponent_abbreviation")}</span><span>{_fact(fixture, "clock")}</span>'
        f'{_lifecycle_tag(state, lifecycle)}</div>'
    )


@_records_facts
def _match_body(state: str, *, ax5: bool = False, evidence: str = "match") -> str:
    _require_one_of(
        state,
        {"live", "awaiting-input", "background-paused", "foreground-resumed", "resolved-deferred", "exit", "resumable-return", "aftermath"},
        "match",
    )
    _require_one_of(evidence, {"match", "appearance"}, "match evidence")
    fixture = "match-resume"
    is_live = MATCH_LIFECYCLE[state].current
    overlay = ""
    if state == "awaiting-input":
        overlay = (
            '<section class="call-in" data-role="live"><p class="eyebrow">OFFENSIVE COORDINATOR</p>'
            f'<h2>{_fact(fixture, "call")}</h2><p>{_fact(fixture, "call_cost")}</p>'
            f'{_actions(_button("Accept call"), _button("Choose another", kind="secondary"), class_name="broadcast-actions")}</section>'
        )
    elif state == "background-paused":
        overlay = '<section class="call-in paused"><h2>Clock paused</h2><p>Time resumes when the app returns.</p></section>'
    elif state == "foreground-resumed":
        overlay = f'<section class="call-in" data-role="live"><h2>Call resumed</h2><p>{_fact(fixture, "call_duration")} remain.</p></section>'
    elif state == "resolved-deferred":
        overlay = f'<section class="lower-third"><strong>{_fact(fixture, "call")} selected</strong><p>The clock expired; your coordinator’s highest-ranked legal call was used.</p></section>'
    elif state == "exit":
        overlay = (
            '<section class="exit-sheet"><h2>Leave the match?</h2><p>The result is already decided.</p>'
            f'{_actions(_button("Keep watching"), _button("Leave and resume here later", kind="secondary"), _button("Simulate the rest", kind="quiet"), class_name="broadcast-actions")}'
            '<small>Remaining calls resolve to your coordinator.</small></section>'
        )
    elif state == "resumable-return":
        overlay = (
            '<section class="exit-sheet"><h2>Resume where you left</h2>'
            f'<p>{_fact(fixture, "clock")} · {_fact(fixture, "situation")}</p>{_actions(_button("Resume match"), class_name="broadcast-actions")}</section>'
        )
    elif state == "aftermath":
        overlay = (
            '<section class="lower-third aftermath"><strong>Fourth-quarter adjustment held</strong>'
            f'<p>{_fact(fixture, "match_result")}. Your inside-run commitment created the winning drive.</p></section>'
        )
    lower = ""
    if state == "live":
        lower = f'<section class="lower-third"><strong>{_fact(fixture, "player_short")} · +23</strong>'
        lower += '' if ax5 else '<p>Won the leverage matchup and crossed midfield.</p>'
        lower += '</section>'
    live_pip_attribute = ' data-role="live"' if is_live else ""
    return (
        f'<div class="match-screen" data-evidence="{escape(evidence)}">'
        f'<div class="field" aria-hidden="true"><div class="line-of-scrimmage"></div>{_field_marks()}</div>'
        f'{_score_bug(state)}'
        f'<div class="direction"><span aria-hidden="true">→</span> {_fact(fixture, "direction")}</div>'
        '<button class="match-exit">Leave match</button>'
        f'<div class="moment-pips" aria-label="Two key moments remain"><i></i><i></i><i{live_pip_attribute}></i><i{live_pip_attribute}></i></div>'
        f'{lower}{overlay}<div class="home-indicator"></div></div>'
    )


@_records_facts
def _save_body(state: str, *, ax5: bool = False, evidence: str = "persistence") -> str:
    _require_one_of(state, {"saving", "saved", "failed", "continuing-warning", "recovered"}, "save")
    _require_one_of(evidence, {"persistence", "appearance"}, "save evidence")
    fixture = "match-resume"
    if state == "saving":
        content = f'{_state_tag("SAVING", live=True)}<h1>Saving your decision</h1><p>{_fact(fixture, "last_save")}</p><div class="progress"><i style="--value:62%"></i></div>'
    elif state == "saved":
        content = f'{_state_tag("SAVED")}<h1>Decision saved</h1><p>{_fact(fixture, "last_save")}</p>'
    elif state == "failed":
        copy = f'<div class="ax5-save-summary" data-authored-reduction="compact-summary"><h1>Save failed</h1><p>Last: {_fact(fixture, "week")}.</p></div>' if ax5 else f'<h1>Your career could not be saved</h1><p>There is not enough storage. Nothing is lost while this decision is open. Last successful save was {_fact(fixture, "week")}.</p>'
        retry_label, storage_label, continue_label = ("Retry", "Storage", "Continue unsaved") if ax5 else ("Try again", "Manage storage", "Continue without saving")
        content = copy + _actions(
            _button(retry_label),
            _button(storage_label, kind="secondary"),
            _button(continue_label, kind="quiet"),
            class_name="ax5-save-actions" if ax5 else "",
        )
    elif state == "continuing-warning":
        content = f'<div class="warning-banner"><strong>Changes are not being saved</strong><p>Last successful save: {_fact(fixture, "week")}.</p><button>Try again</button><button>Manage storage</button></div><h1>Week</h1><p>You can keep playing. This warning remains until a save succeeds.</p>'
    else:
        content = f'{_state_tag("RECOVERED")}<h1>Saving restored</h1><p>Your latest decision is safe.</p>{_actions(_button("Return to Week"))}'
    classes = ["ax5-layout"] if ax5 else []
    if evidence == "appearance":
        classes.append("appearance-continuity")
    return _screen("Career save", content, nav="Week" if state == "continuing-warning" else None, class_name=" ".join(classes))


@_records_facts
def _map_body(lens: str, *, evidence: str = "league") -> str:
    fixture = FIXTURES["college-week"]
    lens_config = {
        "reach": ("Reach", "reach"),
        "talent": ("Talent", "talent"),
        "rivalries": ("Rivalries", "rivalry"),
    }
    label, value_attribute = lens_config[lens]
    _require_one_of(evidence, {"league", "appearance"}, "map evidence")
    dots = "".join(
        f'<i class="map-dot market-{programme.market_size} value-{escape(getattr(programme, value_attribute).lower())}" '
        f'data-map-program-index="{index}" data-map-x="{programme.x}" data-map-y="{programme.y}" '
        f'data-market-size="{programme.market_size}" style="--x:{programme.x / 10:.1f}%;--y:{programme.y / 7:.1f}%"></i>'
        for index, programme in enumerate(fixture.programmes)
    )
    entries_by_region: dict[str, list[str]] = {}
    for index, programme in enumerate(fixture.programmes):
        value = getattr(programme, value_attribute)
        entry = (
            f'<li data-program-index="{index}" data-map-x="{programme.x}" data-map-y="{programme.y}" '
            f'data-market-size="{programme.market_size}"><span>{escape(programme.name)}</span><span>{escape(value)}</span></li>'
        )
        entries_by_region.setdefault(programme.region, []).append(entry)
    groups = [
        f'<section class="region-group" data-region="{escape(region)}"><h3>{escape(region)}</h3><ol>{"".join(entries)}</ol></section>'
        for region, entries in entries_by_region.items()
    ]
    return _screen(
        "League map",
        f'<div class="lens-row"><button class="selected">{label}</button><button>Other lenses</button></div>'
        f'<div class="map-layout evidence-{escape(evidence)}"><div class="league-map" data-lens="{lens}" aria-hidden="true">{dots}<p>{label} lens · all 134 programmes</p></div>'
        f'<div class="semantic-twin" data-lens="{lens}" data-total-programmes="134" aria-label="All programmes grouped by region">{"".join(groups)}</div></div>',
        nav="League",
    )


@_records_facts
def _draft_body(state: str) -> str:
    _require_one_of(state, {"live-pick", "background-paused", "foreground-resumed", "user-selection", "expiry-auto-pick"}, "draft")
    fixture = "draft"
    lifecycle = DRAFT_LIFECYCLE[state]
    clock = f'<span class="draft-clock">{_fact(fixture, "draft_clock")}</span>{_lifecycle_tag(state, lifecycle)}'
    if state == "background-paused":
        decision = '<h1>Clock paused</h1><p>Your remaining time is preserved while the app is away.</p>'
    elif state == "foreground-resumed":
        decision = f'<h1>Clock resumed</h1><p>The same {_fact(fixture, "draft_clock")} remains. No board position changed while paused.</p>'
    elif state == "user-selection":
        decision = f'<h1>{_fact(fixture, "draft_prospect")} selected</h1><p>{_fact(fixture, "draft_position")} · projection {_fact(fixture, "draft_projection")}</p>{_actions(_button("Confirm selection"), class_name="broadcast-actions")}'
    elif state == "expiry-auto-pick":
        decision = f'<h1>{_fact(fixture, "draft_prospect")} is the pick</h1><p>{_fact(fixture, "draft_reason")}.</p><span class="state-tag">AUTO-PICK SHOWN</span>'
    else:
        decision = (
            f'<p class="eyebrow">{_fact(fixture, "draft_coordinator")} RECOMMENDS</p><h1>{_fact(fixture, "draft_prospect")}</h1>'
            f'<p>{_fact(fixture, "draft_position")} · floor {_fact(fixture, "draft_floor")} · projection {_fact(fixture, "draft_projection")}</p>'
            f'{_actions(_button("Make the pick"), _button("Open board", kind="secondary"), class_name="broadcast-actions")}'
        )
    return (
        '<div class="draft-screen"><header class="draft-bug">'
        f'<span>{_fact(fixture, "pro_organisation")}</span><strong>{_fact(fixture, "draft_round")}</strong>'
        f'<span>{_fact(fixture, "draft_pick")}</span>{clock}</header><main>{decision}</main><div class="home-indicator"></div></div>'
    )


@_records_facts
def _promotion_body(state: str) -> str:
    _require_one_of(state, {"offered", "declined", "accepted", "pro-arrival"}, "promotion")
    fixture = "pro-arrival" if state == "pro-arrival" else "promotion"
    if state == "offered":
        content = (
            '<p class="eyebrow">PRO OFFER</p>'
            f'<h1>{_fact(fixture, "pro_organisation")}</h1><p>{_fact(fixture, "pro_role")} · {_fact(fixture, "inherited_cap")}</p>'
            f'<p class="cost-line">{_fact(fixture, "promotion_cost")}</p>'
            f'{_actions(_button("Accept promotion"), _button("Decline and stay", kind="secondary"))}'
        )
    elif state == "declined":
        content = f'<h1>You are staying at {_fact(fixture, "college_programme")}</h1><p>{_fact(fixture, "decline_cost")}.</p>{_actions(_button("Return to Career"))}'
    elif state == "accepted":
        content = f'<h1>Promotion accepted</h1><p>You join {_fact(fixture, "pro_organisation")} after the bowl.</p>{_actions(_button("Review arrival brief"))}'
    else:
        content = (
            '<div class="arrival-summary"><p class="eyebrow">YOUR PRO ARRIVAL</p>'
            f'<h1>{_fact(fixture, "pro_organisation")}</h1><dl class="terms">'
            f'<div><dt>Role</dt><dd>{_fact(fixture, "pro_role")}</dd></div><div><dt>Inherited constraint</dt><dd>{_fact(fixture, "inherited_cap")}</dd></div>'
            f'<div><dt>First stakeholder</dt><dd>{_fact(fixture, "pro_stakeholder")}</dd></div><div><dt>Next decision</dt><dd>{_fact(fixture, "first_decision")}</dd></div></dl></div>'
            f'<blockquote>“{_fact(fixture, "owner_voice")}.”</blockquote>{_actions(_button("Enter preseason"))}'
        )
    tier = "pro" if state in {"accepted", "pro-arrival"} else "college"
    class_name = "arrival-layout" if state == "pro-arrival" else ""
    return _screen("Career", content, nav="Career", tier=tier, class_name=class_name)


def _stamp_component_state(visual: str, component: str, state: str) -> str:
    opening, separator, body = visual.partition(">")
    class_marker = ' class="'
    if not separator or class_marker not in opening:
        raise ValueError(f"{component} specimen must have a classed root element")
    class_start = opening.index(class_marker) + len(class_marker)
    class_end = opening.index('"', class_start)
    state_classes = f"component-visual visual-{escape(component.lower())} state-{escape(state)}"
    stamped_opening = opening[:class_end] + f" {state_classes}" + opening[class_end:]
    return f'{stamped_opening} data-component-state="{escape(state)}">{body}'


def _component_sample(component: str, state: str, fixture: str) -> str:
    state_label = escape(state.replace("-", " ").upper())
    if component == "Card":
        visual = f'<article class="mini-card"><strong>{_fact(fixture, "week")}</strong><small>Saturday · {_fact(fixture, "college_opponent")}</small></article>'
    elif component == "Row":
        visual = f'<div class="mini-row"><span>WR</span><strong>{_fact(fixture, "player")}</strong><span>{_fact(fixture, "player_rating")}</span></div>'
    elif component == "StatCell":
        visual = f'<div class="mini-stat"><strong>{_fact(fixture, "player_rating")}</strong><small>Overall</small></div>'
    elif component == "Chip":
        visual = '<span class="mini-chip">QB1 · Starter</span>'
    elif component == "Meter":
        over = state == "over-capacity"
        meter_label = "63 of 60 contacts, 3 over" if over else "42 of 60 contacts"
        visual = (
            f'<div class="mini-meter{" over" if over else ""}" aria-label="{meter_label}"><i style="--value:{105 if over else 70}%"></i></div>'
            f'<strong>{"63 of 60 · 3 over" if over else "42 of 60 contacts"}</strong>'
        )
    elif component == "Badge":
        live = state == "live"
        active_class = " active" if live else ""
        live_attribute = ' data-role="live"' if live else ""
        label = "LIVE" if live else "NEW"
        visual = f'<span class="mini-badge{active_class}"{live_attribute}>{label}</span>'
    elif component == "SegmentedControl":
        selected_class = ' class="selected"' if state == "selected" else ""
        disabled_attribute = ' disabled aria-disabled="true"' if state == "disabled" else ""
        visual = f'<div class="mini-segments"><button{selected_class}{disabled_attribute}>Balanced</button><button{disabled_attribute}>Aggressive</button></div>'
    elif component == "PrimaryButton":
        disabled = ' disabled aria-disabled="true"' if state == "disabled" else ""
        busy = ' aria-busy="true"' if state == "loading" else ""
        pressed = ' aria-pressed="true"' if state == "pressed" else ""
        visual = f'<button class="mini-primary"{disabled}{busy}{pressed}>{"Advancing week" if state == "loading" else "Commit plan"}</button>'
    elif component == "DestructiveButton":
        disabled = ' disabled aria-disabled="true"' if state == "disabled" else ""
        visual = f'<button class="mini-destructive"{disabled}>{"Release both · confirm" if state == "confirmation" else "Release player"}</button>'
    elif component == "InboxItem":
        status = "ANSWER" if state == "unread" else "DONE"
        visual = f'<article class="mini-inbox"><i></i><div><strong>Set Saturday plan</strong><small>{_fact(fixture, "plan_cost")}</small></div><span>{status}</span></article>'
    elif component == "CallInCard":
        live = state == "awaiting"
        call_text = f'{_fact(fixture, "call")} · {_fact(fixture, "call_duration")}' if live else state.title()
        paused_class = " paused" if state == "paused" else ""
        live_attribute = ' data-role="live"' if live else ""
        visual = f'<article class="mini-call{paused_class}"{live_attribute}><small>COORDINATOR</small><strong>{call_text}</strong></article>'
    elif component == "FieldCanvas":
        visual = f'<div class="mini-field"><i></i><i></i><i></i><span>{dict(formation="Set", **{"key-moment": "Matchup", "outcome": "First down"})[state]}</span></div>'
    elif component == "EmptyState":
        action = '<button>Advance to Monday</button>' if state == "action" else ""
        visual = f'<div class="mini-empty"><strong>No offers yet</strong>{action}</div>'
    elif component == "ErrorBanner":
        if state == "error":
            visual = '<div class="mini-error"><strong>Could not save</strong><button>Try again</button></div>'
        else:
            visual = '<div class="mini-error recovered"><strong>Saving restored</strong><button>Return</button></div>'
    elif component == "OpposedBar":
        visual = f'<div class="mini-opposed"><span>{_fact(fixture, "college_programme")} 5.1</span><i><b class="{"outlier" if state == "outlier" else ""}"></b></i><span>{_fact(fixture, "college_opponent")} 4.2</span></div>'
    elif component == "Sparkline":
        heights = (72, 54, 88, 63, 94) if state == "positive" else (74, 38, 52, 31, 47)
        visual = '<div class="mini-spark" aria-label="Five game form">' + "".join(f'<i style="--value:{height}%"></i>' for height in heights) + '</div>'
    elif component == "LowerThird":
        context = "" if state == "ax5-reduced" else '<small>Won the leverage matchup</small>'
        visual = f'<div class="mini-lower"><strong>{_fact(fixture, "player_short")} · +23</strong>{context}</div>'
    elif component == "ScoreBug":
        live = state == "live"
        live_badge = '<i data-role="live">LIVE</i>' if live else ""
        clock = f'<span>{_fact(fixture, "clock")}</span>' if state != "compact" else ""
        visual = f'<div class="mini-score"><span>{_fact(fixture, "college_abbreviation")}</span><strong>{_fact(fixture, "home_score")}</strong><strong>{_fact(fixture, "away_score")}</strong><span>{_fact(fixture, "opponent_abbreviation")}</span>{clock}{live_badge}</div>'
    elif component == "StakeholderCard":
        visual = f'<blockquote class="mini-stakeholder"><strong>Boosters</strong><span>{"Patience falling" if state == "dissatisfied" else "Expect a bowl"}</span></blockquote>'
    elif component == "MapCanvas":
        if state == "list-twin":
            visual = (
                '<ul class="mini-map-list" aria-label="Programmes grouped by region">'
                f'<li><span>Aven Reach</span><strong>{_fact(fixture, "college_programme")} Wardens · National</strong></li>'
                '<li><span>Briar March</span><strong>Bellweather Wardens · Regional</strong></li>'
                '<li><span>Cinder Vale</span><strong>Cinderhall Wardens · Local</strong></li></ul>'
            )
        else:
            visual = '<div class="mini-map" aria-hidden="true">' + "".join(f'<i style="--x:{8 + index * 17}%;--y:{18 + (index * 31) % 65}%"></i>' for index in range(6)) + f'<span>{state.title()} · 134 programmes</span></div>'
    elif component == "ListControls":
        visual = f'<div class="mini-controls"><button>{"Filter and sort" if state == "collapsed" else "LB"}</button><button>{"2 selected" if state == "multi-select" else "Rating"}</button></div>'
    else:
        value = dict(elite=91, good=84, average=76, poor=67, bad=58)[state]
        polarity = "light-text" if state in {"elite", "good", "average"} else "dark-text"
        display_value = _fact(fixture, "player_rating") if state == "good" else value
        visual = _attribute_row("Vision", display_value, state, value, polarity)
    visual = _stamp_component_state(visual, component, state)
    return (
        f'<div class="specimen" data-specimen="{escape(component)}" data-specimen-state="{escape(state)}">'
        f'<span class="specimen-state">{state_label}</span>'
        f'{visual}</div>'
    )


@_records_facts
def _component_inventory_body(components: Iterable[str], fixture: str) -> str:
    specimens = []
    for component in components:
        specimens.extend(_component_sample(component, state, fixture) for state in COMPONENT_STATES[component])
    return f'<div class="component-grid">{"".join(specimens)}</div>'


@_records_facts
def _tokens_body(kind: str, *, appearance: str = "dark", ax5: bool = False) -> str:
    if kind == "colour":
        roles = (
            ("PAGE", "page", ""),
            ("RESTING SURFACE", "card", ""),
            ("RAISED", "raised", ""),
            ("SELECTED", "selected", ""),
            ("PRIMARY", "primary", ""),
            ("SECONDARY", "secondary", ""),
            ("TERTIARY", "tertiary", ""),
            ("ACCENT", "accent", ""),
            ("LIVE", "live", ' data-role="live" data-token-role="live"'),
            ("POSITIVE", "positive", ""),
            ("WARNING", "warning", ""),
            ("NEGATIVE", "negative", ""),
            ("INFO", "info", ""),
            ("TEAM PRIMARY", "team-primary", ""),
            ("TEAM SECONDARY", "team-secondary", ""),
            ("ON TEAM", "team-on", ""),
        )
        swatches = "".join(
            f'<div class="swatch swatch-{css_class}"{attributes}><span>{label}</span></div>'
            for label, css_class, attributes in roles
        )
        return f'<div class="token-grid">{swatches}</div>'
    if kind == "rating":
        return '<div class="rating-token-list">' + "".join(
            _attribute_row(label, _fact("college-week", "player_rating") if tier == "good" else value, tier, value, "light-text" if tier in {"elite", "good", "average"} else "dark-text")
            for label, value, tier in (("Elite", 91, "elite"), ("Good", 84, "good"), ("Average", 76, "average"), ("Poor", 67, "poor"), ("Bad", 58, "bad"))
        ) + '</div>'
    if kind == "type":
        fixture = "college-week"
        if ax5:
            return (
                '<div class="type-ramp ax5-type-ramp" data-authored-reduction="two-column-role-grid">'
                '<p class="display-type" data-type-role="display">Fourth &amp; 2</p>'
                '<p class="title-type" data-type-role="title">Saturday</p>'
                '<p class="headline-type" data-type-role="headline">Decision</p>'
                '<p class="body-type" data-type-role="body">Visible cost</p>'
                '<p class="callout-type" data-type-role="callout">Commit</p>'
                '<p class="caption-type" data-type-role="caption">WEEK</p>'
                f'<p class="numeral-type" data-type-role="numeral">{_fact(fixture, "college_record")}</p></div>'
            )
        return (
            '<div class="type-ramp">'
            '<p class="display-type" data-type-role="display">Fourth and two</p>'
            f'<p class="title-type" data-type-role="title">Saturday at {_fact(fixture, "college_opponent")}</p>'
            '<p class="headline-type" data-type-role="headline">Decision</p>'
            '<p class="body-type" data-type-role="body">Commitments carry a visible cost.</p>'
            '<p class="callout-type" data-type-role="callout">Commit selected plan</p>'
            '<p class="caption-type" data-type-role="caption">WEEK</p>'
            f'<p class="numeral-type" data-type-role="numeral">{_fact(fixture, "college_record")} · {_fact(fixture, "week")}</p></div>'
        )
    if kind == "cvd":
        tiers = ("elite", "good", "average", "poor", "bad")
        filters = (
            '<svg class="cvd-definitions" aria-hidden="true" focusable="false"><defs>'
            '<filter id="cvd-deuteranopia" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values=".625 .375 0 0 0 .7 .3 0 0 0 0 .3 .7 0 0 0 0 0 1 0"/></filter>'
            '<filter id="cvd-protanopia" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values=".567 .433 0 0 0 .558 .442 0 0 0 0 .242 .758 0 0 0 0 0 1 0"/></filter>'
            '<filter id="cvd-tritanopia" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values=".95 .05 0 0 0 0 .433 .567 0 0 0 .475 .525 0 0 0 0 0 1 0"/></filter>'
            '</defs></svg>'
        )
        lanes = "".join(
            f'<section class="cvd-lane cvd-{mode}" data-cvd="{mode}"><strong>{label}</strong><div>'
            + "".join(f'<i class="{tier}"><span>{tier.title()}</span></i>' for tier in tiers)
            + "</div></section>"
            for mode, label in (("deuteranopia", "Deuteranopia"), ("protanopia", "Protanopia"), ("tritanopia", "Tritanopia"))
        )
        return f'{filters}<div class="cvd-grid">{lanes}</div>'
    if kind == "elevation":
        mechanism = "shadow" if appearance == "light" else "surface-hairline-scrim"
        scrim = '<span class="elevation-scrim" aria-hidden="true"></span>' if appearance == "dark" else ""
        return (
            f'<div class="elevation-grid" data-elevation-mechanism="{mechanism}">'
            '<article class="elevation-one"><strong>Elevation 1</strong><span>Resting surface</span></article>'
            '<article class="elevation-two"><strong>Elevation 2</strong><span>Decision over content</span></article>'
            f'<article class="elevation-three">{scrim}<strong>Elevation 3</strong><span>Confirmation over scrim</span></article></div>'
        )
    return '<div class="spacing-ramp"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div><div class="radius-ramp"><i></i><i></i><i></i></div>'


@_records_facts
def _front_office_body(kind: str) -> str:
    _require_one_of(kind, {"free-agency", "cap-plan", "contract-offer"}, "front-office")
    fixture = "draft"
    if kind == "free-agency":
        content = (
            f'<p class="verdict">Coverage is the only starting-grade need in range.</p><h1>{_fact(fixture, "free_agent")}</h1>'
            f'<p>{_fact(fixture, "free_agent_position")} · asks {_fact(fixture, "free_agent_ask")}</p>'
            f'{_actions(_button("Open negotiation"), _button("Keep searching", kind="secondary"))}'
        )
    elif kind == "cap-plan":
        content = (
            f'<p class="verdict">One starter fits; two remove the injury reserve.</p><h1>{_fact(fixture, "cap_space")}</h1>'
            f'<div class="security-meter"><i style="--value:72%"></i></div><p>{_fact(fixture, "contract_cost")}.</p>'
            f'{_actions(_button("Review roster moves"))}'
        )
    else:
        content = (
            f'<p class="eyebrow">CONTRACT DECISION</p><h1>{_fact(fixture, "free_agent")}</h1>'
            f'<p>{_fact(fixture, "free_agent_ask")} · {_fact(fixture, "contract_guarantee")}</p>'
            f'<p class="cost-line">{_fact(fixture, "contract_cost")}.</p>{_actions(_button("Submit offer"), _button("Walk away", kind="secondary"))}'
        )
    return _screen("Front office", content, nav="Front office", tier="pro")


@_records_facts
def _broadcast_body(occasion_key: str) -> str:
    rivalry = occasion_key == "college-rivalry"
    occasion: BroadcastOccasion = BROADCAST_RIVALRY if rivalry else BROADCAST_OCCASIONS[occasion_key]
    fixture = "match-resume" if occasion.house == "college" else "draft"
    name_key = "college_programme" if occasion.house == "college" else "pro_organisation"
    clock_key = "clock" if occasion.house == "college" else "draft_clock"
    rivalry_seam = ""
    if rivalry:
        rivalry_seam = (
            '<div class="rivalry-seam" aria-label="Rivalry occasion">'
            f'<strong>{_fact(fixture, "rivalry_name")}</strong><span>{_fact(fixture, "rivalry_meeting")}</span></div>'
        )
    return (
        f'<div class="broadcast-screen {occasion.house} {occasion.escalation}{" rivalry" if rivalry else ""}" '
        f'data-broadcast-occasion="{escape(occasion_key)}"><div class="broadcast-frame">'
        f'<span class="occasion">{escape(occasion.label)}</span><strong>{_fact(fixture, name_key)}</strong>'
        f'{_state_tag("LIVE", live=True)}<span class="broadcast-clock">{_fact(fixture, clock_key)}</span></div>'
        f'<div class="broadcast-field" aria-hidden="true"><div class="line-of-scrimmage"></div>{_field_marks()}'
        '<div class="broadcast-down">3RD &amp; 7 · ATTACKING RIGHT →</div></div>'
        f'{rivalry_seam}<section class="broadcast-overlay"><strong>Inside run wins leverage</strong><span>+23 · first down</span></section></div>'
    )


@_records_facts
def _system_body(kind: str) -> str:
    if kind == "progress":
        fixture = "match-resume"
        return _screen("Advance week", f'{_state_tag("LIVE RESULTS", live=True)}<p class="eyebrow">{_fact(fixture, "week")}</p><h1>87 of 134 programmes complete</h1><div class="progress"><i style="--value:65%"></i></div><ol class="result-list"><li>{_fact(fixture, "match_result")}</li><li>Rookhaven 16 · Varrowmere 14</li></ol>')
    if kind == "confirm":
        fixture = "new-career"
        return _screen("Start over?", f'<h1>Delete {_fact(fixture, "coach")}’s 12-season career?</h1><p>This cannot be undone.</p>{_actions(_button("Keep career"), _button("Delete 12 seasons", kind="destructive"))}')
    fixture = "college-week"
    return _screen("Settings", f'<div class="settings-list"><label>Call-ins per match <input type="range" min="12" max="40" value="25"></label><label>Appearance <select><option>System</option><option>Dark</option><option>Light</option></select></label><div><strong>Last saved</strong><span>{_fact(fixture, "week")} · after game plan</span></div></div>', nav="Career")


@_records_facts
def _failure_misc(kind: str) -> str:
    if kind == "refusal":
        return _screen("Roster move", f'<h1>Roster full</h1><p>85 scholarships are already committed.</p>{_actions(_button("Review roster"), _button("Cancel", kind="secondary"))}')
    fixture = "college-week"
    return _screen("Job offers", f'<h1>No offers this week</h1><p>Your {_fact(fixture, "college_record")} record keeps the carousel open. New roles arrive Monday.</p>{_actions(_button("Advance to Monday"))}')


@_records_facts
def _career_security(*, ax5: bool = False) -> str:
    fixture = "college-week"
    content = (
        '<p class="verdict">Ahead of the bar.</p>'
        f'<p>{_fact(fixture, "college_record")} through {_fact(fixture, "week")}. Boosters are the only group falling.</p>'
        '<div class="security-meter"><i style="--value:78%"></i></div>'
        '<article class="stakeholder-row negative"><strong>Boosters</strong><span>Patience falling</span></article>'
    )
    return _screen("Where you stand", content, nav="Career", class_name="ax5-layout" if ax5 else "")


@_records_facts
def _appearance_body(appearance: str, device: str) -> str:
    fixture = "college-week"
    content = (
        f'<p class="verdict">{_fact(fixture, "verdict")}.</p><div class="choice selected"><span class="selection-mark"></span>'
        f'<strong>{_fact(fixture, "plan")}</strong><p>{_fact(fixture, "plan_cost")}</p></div>{_actions(_button("Commit plan"))}'
    )
    return _screen("Game plan", content, nav="Week", class_name=f"appearance-{appearance} device-{device.replace("x", "-")}")


@_records_facts
def _aftermath_body() -> str:
    fixture = "match-resume"
    content = f'<p class="verdict">Your fourth-quarter adjustment held.</p><h1>{_fact(fixture, "match_result")}</h1><p>Inside runs produced 68 yards after the commitment.</p>{_actions(_button("Advance to Monday"))}'
    return _screen("Aftermath", content, nav="Week")


@_records_facts
def _practice_body() -> str:
    fixture = "college-week"
    return _screen("Practice allocation", f'<h1>16 reps remain</h1><div class="allocation"><label>Inside run <input type="range" value="10"></label><label>Deep pass <input type="range" value="6"></label></div><p class="cost-line">{_fact(fixture, "plan_cost")}</p>{_actions(_button("Commit practice"))}', nav="Week")


@_records_facts
def _standings_body() -> str:
    fixture = "college-week"
    content = f'<p class="verdict">Second. {_fact(fixture, "college_opponent")} holds the head-to-head.</p><ol class="standings"><li><strong>{_fact(fixture, "college_opponent")}</strong><span>{_fact(fixture, "opponent_record")}</span></li><li class="selected"><strong>{_fact(fixture, "college_programme")}</strong><span>{_fact(fixture, "college_record")}</span></li><li><strong>{_fact(fixture, "board_alternative")}</strong><span>6-3</span></li></ol>'
    return _screen("Standings", content, nav="League")


def build_sheets() -> tuple[SheetSpec, ...]:
    components = tuple(COMPONENT_STATES)
    sheets = (
        SheetSpec(
            "Accessibility",
            "Accessibility in the binding cases",
            "AX5 is drawn as changed geometry and typography, beside VoiceOver, target, and reduced-motion evidence.",
            (
                _frame(_meta("ax5-inbox", "04 §6 Dynamic Type", "college-week", "accessibility", "ax5-inbox", AX5_COMPACT), "Inbox at AX5", _inbox_body(ax5=True)),
                _frame(_meta("ax5-plan", "04 §6 Dynamic Type", "college-week", "accessibility", "ax5-game-plan", AX5_COMPACT), "Game plan at AX5", _game_plan_body("compare", ax5=True, evidence="accessibility")),
                _frame(_meta("ax5-save", "04 §6 Errors", "match-resume", "persistence", "failed", AX5_COMPACT), "Save failure at AX5", _save_body("failed", ax5=True)),
                _frame(_meta("ax5-match", "04 §5.4", "match-resume", "match", "live", AX5_COMPACT), "Match at AX5 and reduced motion", _match_body("live", ax5=True)),
            ),
            ("Every action remains at least 44 by 44 points.", "The field is hidden from assistive reading; the composed snap sentence carries the same outcome."),
        ),
        SheetSpec(
            "Appearance",
            "One system, two equal appearances",
            "Dark is native; light is equal across the high-risk map, match, continuity, and dense roster surfaces at regular width.",
            (
                _frame(_meta("appearance-dark-floor", "04 §2.1", "college-week", "appearance", "dark-floor", REAL_COMPACT), "Dark · compact · floor", _appearance_body("dark", "844x390")),
                _frame(_meta("appearance-light-floor", "04 §2.1", "college-week", "appearance", "light-floor", LIGHT_COMPACT), "Light · compact · floor", _appearance_body("light", "844x390")),
                _frame(_meta("appearance-dark-ceiling", "04 §4.1", "college-week", "appearance", "dark-ceiling", REAL_REGULAR), "Dark · regular · ceiling", _appearance_body("dark", "932x430")),
                _frame(_meta("appearance-light-ceiling", "04 §4.1", "college-week", "appearance", "light-ceiling", LIGHT_REGULAR), "Light · regular · ceiling", _appearance_body("light", "932x430")),
                _frame(_meta("appearance-light-map-regular", "04 §3 Map", "college-week", "map", "reach", LIGHT_REGULAR), "Light · regular map", _map_body("reach", evidence="appearance")),
                _frame(_meta("appearance-light-match-regular", "04 §5", "match-resume", "match", "resumable-return", LIGHT_REGULAR), "Light · regular match return", _match_body("resumable-return", evidence="appearance")),
                _frame(_meta("appearance-light-continuity-regular", "04 §4.2", "match-resume", "persistence", "continuing-warning", LIGHT_REGULAR), "Light · regular continuity", _save_body("continuing-warning", evidence="appearance")),
                _frame(_meta("appearance-light-roster-regular", "04 §4 Team", "college-week", "screens", "roster", LIGHT_REGULAR), "Light · regular dense roster", _roster_body(evidence="appearance")),
            ),
        ),
        SheetSpec(
            "Broadcast",
            "Broadcast houses and escalation",
            "College uses cut geometry; pro uses orthogonal furniture. Escalation adds without rearranging.",
            tuple(
                _frame(
                    _meta(f"broadcast-{occasion}", "04 §2.4", "match-resume" if occasion.startswith("college") else "draft", "broadcast", occasion, GUIDE_COMPACT if occasion.startswith("pro") else REAL_COMPACT),
                    occasion.replace("-", " ").title(),
                    _broadcast_body(occasion),
                )
                for occasion in (
                    "college-regular",
                    "college-rivalry",
                    "college-conference-championship",
                    "college-playoff",
                    "college-final",
                    "pro-regular",
                    "pro-elimination",
                    "pro-final",
                )
            ),
        ),
        SheetSpec(
            "Career",
            "Jeopardy, promotion, and arrival",
            "Promotion is a decision with a decline, followed by a named pro-arrival handoff rather than an ordinary root.",
            (
                _frame(_meta("career-security", "04 §4 Career", "college-week", "career", "job-security", REAL_COMPACT), "Job security", _career_security()),
                _frame(_meta("promotion-offer", "04 §4 Promotion", "promotion", "promotion", "offered", GUIDE_COMPACT), "Promotion offered", _promotion_body("offered")),
                _frame(_meta("promotion-declined", "04 §4 Promotion", "promotion", "promotion", "declined", GUIDE_COMPACT), "Promotion declined", _promotion_body("declined")),
                _frame(_meta("promotion-accepted", "04 §4 Promotion", "promotion", "promotion", "accepted", GUIDE_COMPACT), "Promotion accepted", _promotion_body("accepted")),
                _frame(_meta("pro-arrival", "04 §4 Promotion", "pro-arrival", "promotion", "pro-arrival", GUIDE_COMPACT), "Pro arrival", _promotion_body("pro-arrival")),
                _frame(_meta("career-security-ax5", "04 §6 Dynamic Type", "college-week", "career", "job-security-ax5", AX5_COMPACT), "Job security at AX5", _career_security(ax5=True)),
            ),
        ),
        SheetSpec(
            "Components",
            "The complete 22-entry registry",
            "Each specimen enumerates only the states that apply. Canonical names stay in this specification chrome.",
            tuple(
                _frame(
                    _meta(f"components-{index + 1}", "04 §3", fixture, "components", "state-inventory", REAL_COMPACT),
                    " · ".join(group),
                    _component_inventory_body(group, fixture),
                )
                for index, (group, fixture) in enumerate(
                    (
                        (components[:6], "college-week"),
                        (("FieldCanvas", "PrimaryButton", "SegmentedControl"), "match-resume"),
                        (("DestructiveButton", "InboxItem", "CallInCard", "EmptyState", "ErrorBanner"), "match-resume"),
                        (("AttributeRow", "MapCanvas", "ListControls"), "college-week"),
                        (("OpposedBar", "Sparkline", "LowerThird", "ScoreBug", "StakeholderCard"), "match-resume"),
                    )
                )
            ),
            ("Registry: " + ", ".join(components),),
        ),
        SheetSpec(
            "Continuity",
            "Leave, return, and resume without punishment",
            "The exact surface returns. Timers pause off-screen, and leaving a seeded match never changes its result.",
            (
                _frame(_meta("continue-exact", "04 §4.2", "match-resume", "entry", "continue-exact", REAL_COMPACT), "Cold-launch continuation", _continue_body(exact_match=True)),
                _frame(_meta("match-background-paused", "04 §3 Call-in", "match-resume", "match", "background-paused", REAL_COMPACT), "Call clock paused", _match_body("background-paused")),
                _frame(_meta("match-foreground-resumed", "04 §3 Call-in", "match-resume", "match", "foreground-resumed", REAL_COMPACT), "Call clock resumed", _match_body("foreground-resumed")),
                _frame(_meta("match-exit", "04 §5.2", "match-resume", "match", "exit", REAL_COMPACT), "Visible match exit", _match_body("exit")),
                _frame(_meta("match-return", "04 §4.2", "match-resume", "match", "resumable-return", REAL_COMPACT), "Resumable return", _match_body("resumable-return")),
                _frame(_meta("match-deferred", "04 §3 Call-in", "match-resume", "match", "resolved-deferred", REAL_COMPACT), "Expired call resolves", _match_body("resolved-deferred")),
                _frame(_meta("saving", "04 §4.2", "match-resume", "persistence", "saving", REAL_COMPACT), "Saving", _save_body("saving")),
                _frame(_meta("saved", "04 §4.2", "match-resume", "persistence", "saved", REAL_COMPACT), "Saved", _save_body("saved")),
            ),
        ),
        SheetSpec(
            "Failure",
            "Failure ends in a decision",
            "Save failure exposes all three recovery choices and continuing installs a persistent warning.",
            (
                _frame(_meta("save-failed", "04 §4.2", "match-resume", "persistence", "failed", REAL_COMPACT), "Save failed", _save_body("failed")),
                _frame(_meta("save-warning", "04 §4.2", "match-resume", "persistence", "continuing-warning", REAL_COMPACT), "Continue without saving", _save_body("continuing-warning")),
                _frame(_meta("save-recovered", "04 §4.2", "match-resume", "persistence", "recovered", REAL_COMPACT), "Persistence recovered", _save_body("recovered")),
                _frame(_meta("roster-refusal", "04 §7", "college-week", "failure", "refusal", REAL_COMPACT), "Specific refusal", _failure_misc("refusal")),
                _frame(_meta("offers-empty", "04 §3 Empty state", "college-week", "failure", "empty", REAL_COMPACT), "Empty state with a door forward", _failure_misc("empty")),
            ),
        ),
        SheetSpec(
            "FirstRun",
            "Choice before identity",
            "The board exposes all four stakes for three jobs, the offer only restates its terms, and Accept is the sole commitment.",
            (
                _frame(_meta("entry-no-career", "04 §4 Entry", "new-career", "entry", "no-career", REAL_COMPACT), "No career", _continue_body()),
                _frame(_meta("entry-board", "04 §4 Entry", "new-career", "entry", "board", REAL_COMPACT), "The board", _board_body()),
                _frame(_meta("entry-offer", "04 §4 Entry", "new-career", "entry", "offer", REAL_COMPACT), "The offer · terms restated", _offer_body()),
                _frame(_meta("entry-appointment", "04 §4 Entry", "new-career", "entry", "accepted-appointment", REAL_COMPACT), "Accepted appointment", _appointment_body()),
            ),
        ),
        SheetSpec(
            "League",
            "Spatial readout with a complete semantic twin",
            "Each lens applies to the map and to the same complete, region-grouped list of all 134 programmes.",
            (
                _frame(_meta("map-reach", "04 §3 Map", "college-week", "map", "reach", REAL_COMPACT), "Reach lens and list twin", _map_body("reach")),
                _frame(_meta("map-talent", "04 §3 Map", "college-week", "map", "talent", REAL_COMPACT), "Talent lens and list twin", _map_body("talent")),
                _frame(_meta("map-rivalries", "04 §3 Map", "college-week", "map", "rivalries", REAL_COMPACT), "Rivalries lens and list twin", _map_body("rivalries")),
                _frame(_meta("league-standings", "04 §4 League", "college-week", "league", "standings", REAL_COMPACT), "Standings with verdict", _standings_body()),
            ),
        ),
        SheetSpec(
            "Offseason",
            "Timed decisions and the full front office",
            "The draft makes pause, resume, and expiry visible; free agency, cap planning, and contracts expose the choices around it.",
            tuple(
                _frame(
                    _meta(f"draft-{state}", "04 §4 Draft", "draft", "draft", state, GUIDE_COMPACT),
                    state.replace("-", " ").title(),
                    _draft_body(state),
                )
                for state in ("live-pick", "background-paused", "foreground-resumed", "user-selection", "expiry-auto-pick")
            )
            + (
                _frame(_meta("free-agency-board", "04 §4 Front office", "draft", "front-office", "free-agency", GUIDE_COMPACT), "Free-agency board", _front_office_body("free-agency")),
                _frame(_meta("cap-plan", "04 §4 Front office", "draft", "front-office", "cap-plan", GUIDE_COMPACT), "Cap plan", _front_office_body("cap-plan")),
                _frame(_meta("contract-offer", "04 §4 Front office", "draft", "front-office", "contract-offer", GUIDE_COMPACT), "Contract offer", _front_office_body("contract-offer")),
            ),
        ),
        SheetSpec(
            "Screens",
            "The five key surfaces, repaired",
            "Each destination states its decision or verdict; the match carries a visible exit and redundant drive direction.",
            (
                _frame(_meta("screen-inbox", "04 §4 Week", "college-week", "screens", "inbox", REAL_COMPACT), "Inbox", _inbox_body()),
                _frame(_meta("screen-report", "04 §4 Week", "college-week", "screens", "opponent-report", REAL_COMPACT), "Opponent report", _opponent_report_body()),
                _frame(_meta("screen-plan", "04 §4 Week", "college-week", "screens", "game-plan", REAL_COMPACT), "Game plan", _game_plan_body("compare", evidence="screens")),
                _frame(_meta("screen-roster", "04 §4 Team", "college-week", "screens", "roster", REAL_COMPACT), "Roster", _roster_body(evidence="roster")),
                _frame(_meta("match-live", "04 §5", "match-resume", "match", "live", REAL_COMPACT), "Live match", _match_body("live")),
                _frame(_meta("match-call", "04 §5", "match-resume", "match", "awaiting-input", REAL_COMPACT), "Call awaiting input", _match_body("awaiting-input")),
            ),
        ),
        SheetSpec(
            "Squad",
            "Preparation becomes consequence",
            "The plan, practice, player attributes, and aftermath use the same weekly facts.",
            (
                _frame(_meta("squad-plan", "04 §4 Week", "college-week", "squad", "game-plan", REAL_COMPACT), "Game plan", _game_plan_body("compare", evidence="squad")),
                _frame(_meta("squad-practice", "04 §4 Week", "college-week", "squad", "practice", REAL_COMPACT), "Practice allocation", _practice_body()),
                _frame(_meta("squad-player", "04 §4 Team", "college-week", "squad", "player", REAL_COMPACT), "Player attributes", _player_body(evidence="player")),
                _frame(_meta("match-aftermath", "04 §4 Week", "match-resume", "match", "aftermath", REAL_COMPACT), "Aftermath", _aftermath_body()),
            ),
        ),
        SheetSpec(
            "System",
            "System states that explain themselves",
            "Known work is determinate, destructive decisions name the loss, and settings expose the saved cadence.",
            (
                _frame(_meta("system-progress", "04 §3 Progress", "match-resume", "system", "advancing-week", REAL_COMPACT), "Determinate week advance", _system_body("progress")),
                _frame(_meta("system-confirm", "04 §3 Confirmation", "new-career", "system", "confirmation", REAL_COMPACT), "Safe action first", _system_body("confirm")),
                _frame(_meta("system-settings", "04 §4 Settings", "college-week", "system", "settings", REAL_COMPACT), "Settings", _system_body("settings")),
            ),
        ),
        SheetSpec(
            "Teaching",
            "Teach, then expand",
            "The first plan teaches one recommendation, then exposes reuse, comparison, and manual control without changing screens.",
            (
                _frame(_meta("teaching-recommended", "04 §4 Week", "college-week", "teaching", "recommended", REAL_COMPACT), "Recommended path", _game_plan_body("teach")),
                _frame(_meta("teaching-reuse", "04 §4 Week", "college-week", "teaching", "reuse", REAL_COMPACT), "Reuse path", _game_plan_body("reuse")),
                _frame(_meta("teaching-compare", "04 §4 Week", "college-week", "teaching", "compare", REAL_COMPACT), "Compare path", _game_plan_body("compare")),
                _frame(_meta("teaching-manual", "04 §4 Week", "college-week", "teaching", "manual", REAL_COMPACT), "Manual path", _game_plan_body("manual")),
            ),
        ),
        SheetSpec(
            "Throughput",
            "Density without a maze",
            "One control grammar serves every long list; attributes bind track, fill, and numeral into one readable row.",
            (
                _frame(_meta("throughput-controls", "04 §3 List controls", "college-week", "throughput", "controls", REAL_COMPACT), "Filter, sort, search", _roster_body(evidence="throughput")),
                _frame(_meta("throughput-batch", "04 §3 List controls", "college-week", "throughput", "batch", REAL_COMPACT), "Multi-select consequence", _roster_body(batch=True, evidence="throughput")),
                _frame(_meta("throughput-attributes", "04 §3 Attribute row", "college-week", "throughput", "attributes", REAL_COMPACT), "Attribute rows", _player_body(evidence="throughput")),
                _frame(_meta("throughput-ax5", "04 §6 Dynamic Type", "college-week", "throughput", "roster-ax5", AX5_COMPACT), "Roster at AX5", _roster_body(ax5=True, evidence="throughput")),
                _frame(_meta("throughput-attributes-ax5", "04 §6 Dynamic Type", "college-week", "throughput", "attributes-ax5", AX5_COMPACT), "Attributes at AX5", _player_body(ax5=True, evidence="throughput")),
            ),
        ),
        SheetSpec(
            "Tokens",
            "Tokens measured on their landing surfaces",
            "The sheet renders both appearances, real type growth, and the complete spacing/radius scales.",
            (
                _frame(_meta("tokens-colour-dark", "04 §2.1", "college-week", "tokens", "colour-dark", REAL_COMPACT), "Colour · dark", _tokens_body("colour")),
                _frame(_meta("tokens-colour-light", "04 §2.1", "college-week", "tokens", "colour-light", LIGHT_COMPACT), "Colour · light", _tokens_body("colour", appearance="light")),
                _frame(_meta("tokens-rating-dark", "04 §2.1", "college-week", "tokens", "rating-dark", REAL_COMPACT), "Rating ladder · dark", _tokens_body("rating")),
                _frame(_meta("tokens-rating-light", "04 §2.1", "college-week", "tokens", "rating-light", LIGHT_COMPACT), "Rating ladder · light", _tokens_body("rating", appearance="light")),
                _frame(_meta("tokens-rating-cvd", "04 §2.1", "college-week", "tokens", "rating-cvd", REAL_COMPACT), "Rating ladder · colour-vision simulations", _tokens_body("cvd")),
                _frame(_meta("tokens-elevation-dark", "04 §2.3", "college-week", "tokens", "elevation-dark", REAL_COMPACT), "Elevation · dark", _tokens_body("elevation")),
                _frame(_meta("tokens-elevation-light", "04 §2.3", "college-week", "tokens", "elevation-light", LIGHT_COMPACT), "Elevation · light", _tokens_body("elevation", appearance="light")),
                _frame(_meta("tokens-type", "04 §2.2", "college-week", "tokens", "type-default", REAL_COMPACT), "Type · default", _tokens_body("type")),
                _frame(_meta("tokens-type-ax5", "04 §2.2", "college-week", "tokens", "type-ax5", AX5_COMPACT), "Type · AX5", _tokens_body("type", ax5=True)),
                _frame(_meta("tokens-spacing", "04 §2.3", "college-week", "tokens", "spacing-radius", REAL_COMPACT), "Spacing and radius", _tokens_body("spacing")),
            ),
        ),
    )
    return sheets
