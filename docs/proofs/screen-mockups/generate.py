"""Emit 04 §8 landscape screen mockups. Run from this directory: python3 generate.py"""
from __future__ import annotations

from pathlib import Path

from _common import (
    ACQUIRE,
    CAREER,
    FRONT,
    LEAGUE,
    OFFICE,
    PERSONNEL,
    card,
    local_routes,
    page,
    pair,
    team_chip,
    world_strip,
)

OUT = Path(__file__).resolve().parent


def rb(n):
    cls = "g" if n >= 85 else "a" if n >= 70 else "r"
    return f'<span class="rb {cls}">{n}</span>'


# ---------------------------------------------------------------------------
# Entry and system (1–7)
# ---------------------------------------------------------------------------

def s1(a="dk"):
    return f"""<div class="screen">
  <div class="body full" style="flex-direction:column;justify-content:center;gap:16px">
    <div class="f-micro q" style="letter-spacing:.12em;text-transform:uppercase">The Coach's World</div>
    <div class="f-display">Pro Football Coach</div>
    <div class="f-body s2">One save. One coach. College, then the league.</div>
    <div class="panel raised" style="max-width:420px">
      <div class="phead">Current career<div class="k">durable boundary</div></div>
      <div class="drow">Coach Sample<span class="v">Head coach</span></div>
      <div class="drow">Example State<span class="v">6-2 · Week 9</span></div>
      <div class="drow">Last saved<span class="v">Preparation day</span></div>
    </div>
    <div class="ctlrow">
      <button class="btn primary">Continue career</button>
      <button class="btn secondary">New career</button>
    </div>
  </div>
</div>"""


def s2(a="dk"):
    return f"""<div class="screen">
  <div class="body full" style="gap:12px">
    <div class="panel fill grow">
      <div class="phead">Coach premise<div class="k">new career</div></div>
      <div class="pad" style="display:flex;flex-direction:column;gap:8px">
        <div class="f-cap q">DISPLAY NAME</div>
        <div class="field" style="width:100%">Coach Sample</div>
        <div class="f-cap q">ARCHETYPE</div>
        <div class="seg"><span class="on">Builder</span><span>Tactician</span><span>Recruiter</span></div>
        <div class="f-cap q">UNIVERSE SEED</div>
        <div class="field" style="width:100%">derived from identifier bytes — never hashValue</div>
      </div>
    </div>
    <div class="panel fill" style="width:260px">
      <div class="phead">Generated world<div class="k">preview</div></div>
      <div class="drow">College programmes<span class="v">134</span></div>
      <div class="drow">Professional clubs<span class="v">32</span></div>
      <div class="drow">Players<span class="v">15,766</span></div>
      <div class="drow empty">Identities pending generator output</div>
      <div class="pad" style="margin-top:auto"><button class="btn primary" style="width:100%">Draw three jobs</button></div>
    </div>
  </div>
</div>"""


def s3(a="dk"):
    jobs = [
        ("Recommended", "Example State", "Group of Five · 6-2 last year", "Scheme fit Strong", True),
        ("Defensible", "Example Harbor", "Rebuild · 3-9 last year", "Scheme fit Good", False),
        ("Defensible", "Example Ridge", "Mid-major · 5-7 last year", "Scheme fit Fair", False),
    ]
    cols = []
    for rank, name, line, fit, rec in jobs:
        rec_cls = " rec" if rec else ""
        cols.append(f"""<div class="job{rec_cls}">
          <div class="rank">{rank}</div>
          <div class="ident"><div class="plate" style="width:36px;height:44px"></div><div><div class="f-head">{name}</div><div class="f-cap s2">{line}</div></div></div>
          <div class="f-cap s2">{fit}</div>
          <div class="drow">Expectation<span class="v">Bowl</span></div>
          <div class="drow">Staff continuity<span class="v">Keep DC</span></div>
          <button class="btn {'primary' if rec else 'secondary'}" style="margin-top:auto">Read offer</button>
        </div>""")
    return f"""<div class="screen">
  <div class="body full">{''.join(cols)}</div>
</div>"""


def s4(a="dk"):
    return f"""<div class="screen">
  <div class="body full">
    <div class="panel fill grow">
      <div class="phead">Offer · Example State<div class="k">terms</div></div>
      <div class="drow">Length<span class="v">4 seasons</span></div>
      <div class="drow">Year-1 salary<span class="v">$850,000</span></div>
      <div class="drow">Buyout after year 2<span class="v">$400,000</span></div>
      <div class="drow">Control<span class="v">Staff · scheme · recruiting</span></div>
      <div class="drow">Decline path<span class="v">Return to Job Board</span></div>
      <div class="pad s2 f-body">Accepting writes the durable career boundary. Decline keeps the other two jobs live.</div>
    </div>
    <div class="colstack" style="width:220px;gap:8px">
      <div class="panel pad">
        <div class="f-cap q">CONSEQUENCE</div>
        <div class="f-head" style="margin-top:6px">You become head coach of Example State this week.</div>
      </div>
      <button class="btn primary">Accept</button>
      <button class="btn ghost">Decline</button>
    </div>
  </div>
</div>"""


def s5(a="dk"):
    return f"""<div class="screen">
  <div class="body full" style="flex-direction:column;justify-content:center;align-items:center;gap:16px">
    {team_chip("home")}
    <div class="f-micro col" style="letter-spacing:.12em;text-transform:uppercase">Appointment</div>
    <div class="f-display">Example State</div>
    <div class="f-head s2">Coach Sample · Head Coach</div>
    <div class="ident">
      <div class="plate" style="width:52px;height:64px"></div>
      <div>
        <div class="nm">Athletic director</div>
        <div class="f-cap s2">The building is yours. Saturday is not optional.</div>
      </div>
    </div>
    <button class="btn primary">Take the office</button>
  </div>
</div>"""


def s6(a="dk"):
    return f"""<div class="screen">
  {world_strip("office", due=0, can_advance=True)}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Device and match<div class="k">settings</div></div>
      <div class="drow">Appearance<span class="v">System</span></div>
      <div class="drow">Reduce Motion<span class="v">Off</span></div>
      <div class="drow">Match speed default<span class="v">1x</span></div>
      <div class="drow">Call-in interrupt<span class="v">On</span></div>
      <div class="drow">Haptics<span class="v">On</span></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Accessibility<div class="k">04 §7</div></div>
      <div class="drow">Dynamic Type<span class="v">Default</span></div>
      <div class="drow">VoiceOver order<span class="v">World, object, evidence, actions</span></div>
      <div class="drow">Button shapes<span class="v">System</span></div>
      <div class="drow">Differentiate without colour<span class="v">On</span></div>
      <div class="drow empty">AX5 reflows to one scrolling column</div>
    </div>
  </div>
</div>"""


def s7(a="dk"):
    rows = [
        ("Player Fourteen", "QB · Example State", "Person", True),
        ("Example Coastal", "Programme · 5-3", "Team", False),
        ("Week 8 at Example Union", "W 24-17", "Game", False),
        ("Coordinator Sample", "DC · Example State", "Person", False),
    ]
    trs = []
    for n, m, k, sel in rows:
        cls = "trow sel" if sel else "trow"
        trs.append(
            f'<div class="{cls}" style="grid-template-columns:minmax(180px,1.2fr) minmax(160px,1fr) 80px">'
            f'<span class="nm">{n}</span><span class="n">{m}</span><span class="n">{k}</span></div>'
        )
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  <div class="body" style="flex-direction:column;gap:8px">
    <div class="ctlrow">
      <div class="field" style="flex:1"><span class="sym">magnifyingglass</span> Search this save</div>
      <div class="seg"><span class="on">All</span><span>People</span><span>Teams</span><span>Games</span></div>
    </div>
    <div class="tbl grow">
      <div class="capline">Bounded index<div class="cnt">4 of 40 shown</div></div>
      <div class="thead" style="grid-template-columns:minmax(180px,1.2fr) minmax(160px,1fr) 80px"><span class="on">Name</span><span>Context</span><span>Kind</span></div>
      {''.join(trs)}
    </div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# Week and match (8–15)
# ---------------------------------------------------------------------------

def s8(a="dk"):
    days = [("Mon", "Lift"), ("Tue", "Install"), ("Wed", "Install"), ("Thu", "Red zone"), ("Fri", "Walkthrough"), ("Sat", "Travel"), ("Sun", "Game")]
    day_html = "".join(
        f'<div class="day{" today" if d=="Thu" else ""}"><div class="dayhead">{d}</div><div class="f-micro">{w}</div></div>'
        for d, w in days
    )
    return f"""<div class="screen">
  {world_strip("office", due=2)}
  {local_routes(OFFICE, "desk")}
  <div class="body">
    <div class="panel fill rail" style="width:168px;background:rgba(168,97,214,.10)">
      <div class="pad">
        <div class="f-micro col" style="font-weight:800">COACH'S OFFICE · WEEK</div>
        <div class="f-head" style="margin-top:6px">Build Saturday</div>
        <div class="f-title num" style="margin-top:4px">WEEK 9</div>
        <div class="f-cap s2" style="margin-top:6px">Game plan still open. Continue is blocked until it is set.</div>
        <div class="ident" style="margin-top:12px">
          <div class="plate" style="width:40px;height:48px"></div>
          <div><div class="f-cap" style="font-weight:700">Coordinator Sample</div><div class="f-micro s2">Defensive coordinator</div></div>
        </div>
      </div>
    </div>
    <div class="panel fill grow">
      <div class="wk">{day_html}</div>
      <div class="pad" style="display:flex;flex-direction:column;gap:8px;flex:1">
        <div style="display:flex;justify-content:space-between;align-items:baseline">
          <div>
            <div class="f-micro col" style="font-weight:800">DUE · FRIDAY 18:00</div>
            <div class="f-head">Set the Week 9 game plan</div>
            <div class="f-cap s2">Example Coastal, away. Observed pass share last four: 88 / 121 / 94 / 103 rush yards allowed.</div>
          </div>
          <div style="text-align:right" class="col"><div class="f-head num">2h</div><div class="f-micro">UNALLOCATED</div></div>
        </div>
        <div class="choice sel"><span class="mark"></span><div class="grow"><div class="f-body" style="font-weight:600">Stop the run first</div><div class="f-micro s2">Trade passing yards for front-seven rest</div></div><div class="acost">45 min</div></div>
        <div class="choice"><span class="mark"></span><div class="grow"><div class="f-body" style="font-weight:600">Take the explosive shots</div><div class="f-micro s2">Leave the edge light</div></div><div class="acost">45 min</div></div>
        <div class="ctlrow">
          <div class="receipt grow">Stop the run first · 45 min</div>
          <button class="btn secondary"><span class="sym">film</span></button>
          <button class="btn secondary"><span class="sym">person.badge.clock</span></button>
          <button class="btn primary">Set work</button>
        </div>
      </div>
    </div>
    <div class="panel fill rail" style="width:196px">
      <div class="phead">This week<div class="k">desk</div></div>
      <div class="drow">Next<div class="v">Example Coastal (A)</div></div>
      <div class="drow">Record<div class="v">6-2</div></div>
      <div class="drow">Unavailable<div class="v">P51 suspended</div></div>
      <div class="drow">Inbox<div class="v">2 due</div></div>
      <div class="drow empty">No correspondence</div>
    </div>
  </div>
</div>"""


def s9(a="dk"):
    return f"""<div class="screen">
  {world_strip("office", due=2)}
  {local_routes(OFFICE, "inbox")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Agenda<div class="k">mandatory</div></div>
      <div class="agenda" style="border:0;border-radius:0">
        <div class="arow sel">
          <div class="acheck"><span class="sym">circle</span></div>
          <div class="amain"><div class="atitle">Set Week 9 game plan</div><div class="asub">Friday 18:00 · Example Coastal (A)</div></div>
          <div class="acost">45 min<span class="c2">due</span></div>
        </div>
        <div class="arow">
          <div class="acheck"><span class="sym">circle</span></div>
          <div class="amain"><div class="atitle">Allocate practice minutes</div><div class="asub">Friday 18:00 · 60 min still open</div></div>
          <div class="acost">20 min<span class="c2">due</span></div>
        </div>
        <div class="arow">
          <div class="acheck"><span class="sym">checkmark.circle.fill</span></div>
          <div class="amain"><div class="atitle">Confirm travel party</div><div class="asub">Delegated · Coordinator Sample</div></div>
          <div class="acost"><span class="sym">person.badge.clock</span><span class="c2">receipt</span></div>
        </div>
      </div>
    </div>
    <div class="panel fill" style="width:280px">
      <div class="phead">Correspondence<div class="k">this week</div></div>
      <div class="empty">
        <span class="sym">checkmark.circle</span>
        <div class="et">No letters this week</div>
        <div class="ed">Mandatory work is on the agenda. There is no inbound correspondence until that system exists.</div>
      </div>
    </div>
  </div>
</div>"""


def s10(a="dk"):
    return f"""<div class="screen">
  {world_strip("office", due=2)}
  {local_routes(OFFICE, "film")}
  <div class="body">
    <div class="panel fill" style="width:280px;background:var(--page)">
      <div class="phead">Observed film<div class="k">last four</div></div>
      <div class="drow">Opponent<div class="v">Example Coastal</div></div>
      <div class="drow">Venue<div class="v">Away</div></div>
      <div class="drow">Rush yards allowed<div class="v num">88, 121, 94, 103</div></div>
      <div class="drow">Pass yards (us / them)<div class="v num">213 / 267</div></div>
      <div class="drow">Takeaways last week<div class="v">Example Union 3–1</div></div>
      <div class="pad">
        <div class="f-micro q" style="margin-bottom:4px">STAFF INTERPRETATION</div>
        <div class="verdict">No staff verdict. Sample and confidence wait on G-02.</div>
      </div>
    </div>
    <div class="panel fill grow" style="background:var(--turf);border-radius:0;position:relative">
      <div class="ylines" style="inset:12px;border-color:rgba(245,247,250,.35)"></div>
      <div class="f-micro" style="position:absolute;left:12px;bottom:8px;color:#F2F5F3">Play art once G-06 lands. Field is turf only.</div>
    </div>
    <div class="panel fill rail" style="width:168px">
      <div class="phead">Keys</div>
      <div class="drow">Edge<div class="v">P54</div></div>
      <div class="drow">Unavailable<div class="v">P51</div></div>
      <div class="drow empty">No invented tendency</div>
      <div class="pad" style="margin-top:auto"><button class="btn secondary" style="width:100%">Open game plan</button></div>
    </div>
  </div>
</div>"""


def s11(a="dk"):
    axis = lambda t, l, r: f"""<div class="pad" style="border-top:1px solid var(--hair)">
      <div class="f-cap" style="font-weight:700">{t}</div>
      <div class="opposed" style="margin:6px 0"><div class="h" style="flex:{l}"></div><div class="a" style="flex:{r}"></div></div>
      <div class="f-micro s2 num">Us {l} · Them {r}</div>
    </div>"""
    return f"""<div class="screen">
  {world_strip("office", due=2)}
  {local_routes(OFFICE, "plan")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Weekly tactical keys<div class="k">trade-offs</div></div>
      {axis("Run fit", 184, 92)}
      {axis("Pass yards (season sample)", 213, 267)}
      {axis("Takeaways last fixture", 1, 3)}
      <div class="pad">
        <div class="choice sel"><span class="mark"></span><div class="grow f-body" style="font-weight:600">Stop the run first</div><div class="acost">front seven</div></div>
        <div class="choice"><span class="mark"></span><div class="grow f-body" style="font-weight:600">Take the explosive shots</div><div class="acost">coverage</div></div>
      </div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Commit</div>
      <div class="drow">Opponent<div class="v">Example Coastal</div></div>
      <div class="drow">Selection<div class="v">Stop the run</div></div>
      <div class="verdict" style="margin:8px">No named-staff recommendation until G-02.</div>
      <div class="pad"><button class="btn primary" style="width:100%">Set plan</button></div>
    </div>
  </div>
</div>"""


def s12(a="dk"):
    buckets = [
        ("Offense", 60, 60, False),
        ("Defense", 60, 45, False),
        ("Special teams", 60, 30, False),
        ("Scout / install", 60, 0, True),
    ]
    rows = []
    for name, cap, used, open_ in buckets:
        pct = int(100 * used / cap)
        fill = "over" if used > cap else ("ok" if used else "")
        rows.append(f"""<div class="pad" style="border-top:1px solid var(--hair)">
          <div style="display:flex;justify-content:space-between"><div class="f-cap" style="font-weight:700">{name}</div><div class="f-micro num s2">{used} / {cap} min</div></div>
          <div class="meter" style="margin-top:6px"><div class="mfill {fill}" style="width:{pct}%"></div></div>
        </div>""")
    return f"""<div class="screen">
  {world_strip("office", due=2)}
  {local_routes(OFFICE, "practice")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Practice minutes<div class="k">this week</div></div>
      {''.join(rows)}
      <div class="pad f-micro q">Calendar grain is the week. A seven-day load grid is G-14 and is not drawn as if it ships.</div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Presets</div>
      <div class="drow">Physical<div class="v">legal</div></div>
      <div class="drow">Install<div class="v">legal</div></div>
      <div class="drow">Walkthrough<div class="v">legal</div></div>
      <div class="pad"><button class="btn primary" style="width:100%">Set minutes</button></div>
    </div>
  </div>
</div>"""


def s13(a="dk"):
    people = [
        ("51", "Player Fifty-One", "LB", "81", "Suspended", True),
        ("14", "Player Fourteen", "QB", "84", "Good", False),
        ("72", "Player Seventy-Two", "LT", "88", "Good", False),
        ("07", "Player Seven", "WR", "79", "Good", False),
        ("11", "Player Eleven", "TE", "76", "Good", False),
        ("26", "Player Twenty-Six", "CB", "77", "Good", False),
        ("09", "Player Nine", "RB", "72", "Good", False),
    ]
    cols = "44px minmax(140px,1.2fr) 40px 36px minmax(90px,1fr)"
    trs = []
    for no, name, pos, ovr, st, dis in people:
        cls = "trow dis" if dis else "trow"
        chip = '<span class="chip neg"><span class="sym">shield.slash</span> Suspended</span>' if dis else f'<span class="chip">{st}</span>'
        trs.append(
            f'<div class="{cls}" style="grid-template-columns:{cols}">'
            f'<span class="n">{no}</span><span class="nm">{name}</span><span class="n">{pos}</span>'
            f'<span>{rb(int(ovr))}</span><span>{chip}</span></div>'
        )
    return f"""<div class="screen">
  {world_strip("office", due=2)}
  {local_routes(OFFICE, "health")}
  <div class="body" style="flex-direction:column">
    <div class="tbl grow">
      <div class="capline">Availability this week<div class="cnt">1 unavailable · 63 of 70 on the sheet</div></div>
      <div class="thead" style="grid-template-columns:{cols}"><span>#</span><span class="on">Player</span><span>Pos</span><span>OVR</span><span>State</span></div>
      {''.join(trs)}
    </div>
    <div class="f-micro q">Ratings stay printed on the suspended row. There is no return-to-play intent on this surface.</div>
  </div>
</div>"""


def s14(a="dk"):
    # 22 dots — approximate formation, home left (offense left-to-right toward Coastal)
    homes = [
        (300, 90), (300, 130), (300, 170), (300, 210), (300, 250),
        (340, 140), (340, 200),
        (380, 80), (380, 160), (380, 240),
        (360, 170),
    ]
    aways = [
        (440, 90), (440, 130), (440, 170), (440, 210), (440, 250),
        (480, 110), (480, 170), (480, 230),
        (520, 90), (520, 170), (520, 250),
    ]
    dots = []
    for i, (x, y) in enumerate(homes):
        fg = " fg" if i == 10 else ""
        dots.append(f'<div class="dot home{fg}" style="left:{x}px;top:{y}px"></div>')
    for i, (x, y) in enumerate(aways):
        fg = " fg" if i == 4 else ""
        dots.append(f'<div class="dot away{fg}" style="left:{x}px;top:{y}px"></div>')
    return f"""<div class="screen">
  <div class="body match">
    <div class="fieldcanvas">
      <div class="ylines"></div>
      <div class="los"></div>
      <div class="fd"></div>
      {''.join(dots)}
      <div class="bug">
        <div class="cell" style="background:#E9E0C9;color:#18202B"><span class="poss" style="border-left-color:#6E3038"></span><span class="team">EXC</span><span class="score">13</span></div>
        <div class="cell" style="background:#14382A;color:#F2F5F3"><span class="team">EXS</span><span class="score">10</span></div>
        <div class="sit">Q3 07:26<br>1st &amp; 10</div>
      </div>
      <div class="callin">
        <div class="h">Call-in</div>
        <div class="f-cap" style="font-weight:700">Coordinator Sample</div>
        <div class="f-cap s2">Slide the protection. P54 is winning the edge.</div>
        <div class="ctlrow" style="margin-top:8px">
          <button class="btn live" style="border-radius:0;flex:1">Accept</button>
          <button class="btn ghost" style="border-radius:0">Dismiss</button>
        </div>
      </div>
      <div class="lower">
        <div class="plate" style="background:#555B66;color:#FFFFFF;border-radius:0">EXU</div>
        <div class="id"><div class="nm">P54</div><div class="f-micro s2">DE · No. 54</div></div>
        <div class="ev"><div class="f-body" style="font-weight:700">Sack · loss of 8</div><div class="f-micro s2">Edge won, protection collapsed.</div></div>
      </div>
      <div class="mcontrols">
        <button class="btn secondary">Speed</button>
        <button class="btn secondary"><span class="sym">pause.fill</span> Pause</button>
        <button class="btn secondary">Key Moments</button>
        <button class="btn primary">Take Over</button>
        <button class="btn secondary">Tactics</button>
      </div>
    </div>
  </div>
</div>"""


def s15(a="dk"):
    return f"""<div class="screen">
  {world_strip("office", due=0, can_advance=True)}
  {local_routes(OFFICE, "review")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Week 8 · at Example Union<div class="k">result</div></div>
      <div class="pad" style="display:flex;align-items:baseline;gap:16px">
        <div class="f-display num">24–17</div>
        <div class="f-head">Win</div>
        <div class="f-cap s2">Takeaways 1–3 against. Player Fourteen 83.</div>
      </div>
      <div class="drow">Turning point<div class="v">P54 sack, Q3</div></div>
      <div class="drow">Plan used<div class="v">Stop the run first</div></div>
      <div class="drow">Recovery<div class="v">P51 remains suspended</div></div>
      <div class="pad s2 f-body">Causal review is the stored plan against the recorded result. Week 9 has not been played; this is last week's fixture.</div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Next</div>
      <div class="drow">Fixture<div class="v">Example Coastal (A)</div></div>
      <div class="drow">Prep left<div class="v">2 due</div></div>
      <div class="pad"><button class="btn live" style="width:100%">Continue</button></div>
    </div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# Team and staff (16–23)
# ---------------------------------------------------------------------------

ROSTER = [
    ("14", "Player Fourteen", "QB", "SR", "84", "Good", "78 81 74 86 83", False, True),
    ("72", "Player Seventy-Two", "LT", "JR", "88", "Strong", "—", False, False),
    ("07", "Player Seven", "WR", "SO", "79", "Good", "—", False, False),
    ("51", "Player Fifty-One", "LB", "SR", "81", "Good", "—", True, False),
    ("11", "Player Eleven", "TE", "JR", "76", "Good", "—", False, False),
    ("26", "Player Twenty-Six", "CB", "SO", "77", "Good", "—", False, False),
    ("09", "Player Nine", "RB", "FR", "72", "Strong", "—", False, False),
]


def s16(a="dk"):
    cols = "36px minmax(130px,1.3fr) 36px 28px 32px 52px 88px"
    trs = []
    for no, name, pos, yr, ovr, fit, form, dis, sel in ROSTER:
        cls = "trow dis" if dis else ("trow sel" if sel else "trow")
        chip = '<span class="chip neg"><span class="sym">shield.slash</span></span>' if dis else ""
        trs.append(
            f'<div class="{cls}" style="grid-template-columns:{cols}">'
            f'<span class="n">{no}</span><span class="nm">{name}</span><span class="n">{pos}</span>'
            f'<span class="n">{yr}</span><span>{rb(int(ovr))}</span><span class="n">{fit}</span>'
            f'<span>{chip}</span></div>'
        )
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "roster")}
  <div class="body" style="flex-direction:column;gap:8px">
    <div class="ctlrow">
      <div class="seg"><span class="on">All</span><span>Offense</span><span>Defense</span><span>ST</span></div>
      <div class="field"><span class="sym">magnifyingglass</span> Filter this sheet</div>
      <div class="f-micro s2 num">63 of 70</div>
    </div>
    <div class="tbl grow">
      <div class="capline">Legal team sheet<div class="cnt">Fit prints as a word</div></div>
      <div class="thead" style="grid-template-columns:{cols}"><span>#</span><span>Name</span><span>Pos</span><span>Yr</span><span class="on">OVR</span><span>Fit</span><span>Status</span></div>
      {''.join(trs)}
    </div>
  </div>
</div>"""


def s17(a="dk"):
    def slot(role, name, no, ovr, down=False):
        dim = " style=opacity:.45" if down else ""
        return f'<div class="drow"{dim}><span class="token">{role}</span>&nbsp;{name} #{no}<span class="v">{rb(ovr)}</span></div>'
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "depth")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Base 11<div class="k">spatial roles</div></div>
      {slot("QB", "Player Fourteen", 14, 84)}
      {slot("LT", "Player Seventy-Two", 72, 88)}
      {slot("WR", "Player Seven", 7, 79)}
      {slot("TE", "Player Eleven", 11, 76)}
      {slot("RB", "Player Nine", 9, 72)}
      {slot("LB", "Player Fifty-One", 51, 81, True)}
      <div class="drow empty">P51 suspended — succession sits on the next legal LB</div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Packages<div class="k">situation</div></div>
      <div class="drow">Nickel<div class="v">P26 in</div></div>
      <div class="drow">12 personnel<div class="v">P11 stays</div></div>
      <div class="drow">Goal line<div class="v">heavy</div></div>
      <div class="pad f-micro q">Packages are assignments, not a second roster.</div>
    </div>
  </div>
</div>"""


def s18(a="dk"):
    attrs = [("Awareness", 79, "up 0"), ("Accuracy", 86, ""), ("Arm", 81, ""), ("Decision", 77, ""), ("Mobility", 68, ""), ("Composure", 83, "")]
    rows = "".join(
        f'<div class="drow">{n}<span class="v">{rb(v)}{" <span class=sym>arrow.up.right</span>" if d.startswith("up") and "2" in d else ""}</span></div>'
        for n, v, d in attrs
    )
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "profile")}
  <div class="body">
    <div class="panel fill" style="width:240px">
      <div class="pad ident">
        <div class="plate" style="width:52px;height:64px"></div>
        <div>
          <div class="nm">Player Fourteen</div>
          <div class="f-cap s2">QB · No. 14 · Senior · 22</div>
          <div style="margin-top:6px">{rb(84)} <span class="f-cap s2">Good fit</span></div>
        </div>
      </div>
      <div class="drow">Contract<div class="v">expires next season</div></div>
      <div class="drow">Remaining<div class="v">$2,400,000</div></div>
      <div class="drow">Market<div class="v">$3.0–4.5M band</div></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Form and attributes<div class="k">last five</div></div>
      <div class="pad f-cap num s2">W78 · L81 · W74 · W86 · W83 · Example Ridge, Harbor, Valley, Summit, Union</div>
      {rows}
    </div>
  </div>
</div>"""


def s19(a="dk"):
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "develop")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Current focus<div class="k">Player Seventy-Two</div></div>
      <div class="ident pad">
        <div class="plate" style="width:48px;height:56px"></div>
        <div>
          <div class="nm">Player Seventy-Two</div>
          <div class="f-cap s2">LT · Awareness 74 <span class="sym">arrow.up.right</span> 2 since Week 6</div>
        </div>
      </div>
      <div class="drow">Staff owner<div class="v">OL coach</div></div>
      <div class="drow">Opportunity cost<div class="v">P72's snaps stay first-team</div></div>
      <div class="drow">Minutes this week<div class="v">in the OL bucket</div></div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Change focus</div>
      <div class="choice sel"><span class="mark"></span><div class="f-body">Keep awareness</div></div>
      <div class="choice" style="margin-top:6px"><span class="mark"></span><div class="f-body">Pass set</div></div>
      <div class="pad"><button class="btn primary" style="width:100%">Set focus</button></div>
    </div>
  </div>
</div>"""


def s20(a="dk"):
    staff = [
        ("Coach Sample", "HC", "—", True),
        ("Coordinator Sample", "DC", "Unit 82", False),
        ("Analyst Sample", "Analyst", "G-02 silent", False),
        ("OL Coach", "OL", "P72 +2 awr", False),
    ]
    cols = "minmax(140px,1.2fr) 70px minmax(100px,1fr)"
    trs = []
    for n, r, u, sel in staff:
        cls = "trow sel" if sel else "trow"
        trs.append(
            f'<div class="{cls}" style="grid-template-columns:{cols}"><span class="nm">{n}</span><span class="n">{r}</span><span class="n">{u}</span></div>'
        )
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "staff")}
  <div class="body" style="flex-direction:column">
    <div class="tbl grow">
      <div class="capline">Assignments and continuity</div>
      <div class="thead" style="grid-template-columns:{cols}"><span class="on">Staff</span><span>Role</span><span>Unit</span></div>
      {''.join(trs)}
    </div>
  </div>
</div>"""


def s21(a="dk"):
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "staff")}
  <div class="body">
    <div class="job rec">
      <div class="rank">On staff</div>
      <div class="nm">Coordinator Sample</div>
      <div class="f-cap s2">DC · scheme continuity</div>
      <div class="drow">Contract<div class="v">through next season</div></div>
    </div>
    <div class="job">
      <div class="rank">Candidate</div>
      <div class="nm">Coordinator Harbor</div>
      <div class="f-cap s2">DC · Example Harbor staff</div>
      <div class="drow">Scheme<div class="v">odd front</div></div>
      <div class="drow">Adoption cost<div class="v">high</div></div>
    </div>
    <div class="panel fill" style="width:200px">
      <div class="phead">Compare</div>
      <div class="drow">Fit<div class="v">current scheme</div></div>
      <div class="pad f-micro q">Hiring is not on the Week 9 critical path. This is the market shape.</div>
    </div>
  </div>
</div>"""


def s22(a="dk"):
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "scheme")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Offensive identity</div>
      <div class="drow">Family<div class="v">Play action</div></div>
      <div class="drow">Personnel<div class="v">11 / 12</div></div>
      <div class="drow">Adoption<div class="v">current staff</div></div>
      <div class="pad f-micro q">Diagram marks wait on G-06 recorded routes. Shape is identity, not a copied playbook.</div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Defensive identity</div>
      <div class="drow">Family<div class="v">Even front</div></div>
      <div class="drow">Coverage<div class="v">quarters</div></div>
      <div class="drow">Adoption cost<div class="v">low — Coordinator Sample</div></div>
    </div>
  </div>
</div>"""


def s23(a="dk"):
    return f"""<div class="screen">
  {world_strip("team", due=2)}
  {local_routes(PERSONNEL, "packages")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Nickel<div class="k">3rd &amp; 7</div></div>
      <div class="drow"><span class="token">CB</span> Player Twenty-Six<span class="v">{rb(77)}</span></div>
      <div class="drow"><span class="token">LB</span> next legal LB<span class="v">P51 out</span></div>
      <div class="drow"><span class="token">S</span> first-team S<span class="v">—</span></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">12 personnel<div class="k">2nd &amp; short</div></div>
      <div class="drow"><span class="token">TE</span> Player Eleven<span class="v">{rb(76)}</span></div>
      <div class="drow"><span class="token">RB</span> Player Nine<span class="v">{rb(72)}</span></div>
      <div class="drow"><span class="token">WR</span> Player Seven<span class="v">{rb(79)}</span></div>
    </div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# College acquisition (24–33)
# ---------------------------------------------------------------------------

def s24(a="dk"):
    board = [
        ("1", "Prospect Fourteen", "QB", "88", "High", True),
        ("2", "Prospect Seventy-Two", "LT", "84", "Med", False),
        ("3", "Prospect Seven", "WR", "81", "Med", False),
        ("4", "Prospect Nine", "RB", "76", "Low", False),
        ("5", "Prospect Twenty-Six", "CB", "79", "Med", False),
        ("6", "Prospect Eleven", "TE", "74", "Low", False),
    ]
    cols = "36px minmax(140px,1.3fr) 36px 36px 70px 90px"
    trs = []
    for rk, n, p, o, c, sel in board:
        cls = "trow sel" if sel else "trow"
        trs.append(
            f'<div class="{cls}" style="grid-template-columns:{cols}">'
            f'<span class="n">{rk}</span><span class="nm">{n}</span><span class="n">{p}</span>'
            f'<span>{rb(int(o))}</span><span class="n">{c}</span>'
            f'<span class="chip"><span class="sym">binoculars</span> live</span></div>'
        )
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "board")}
  <div class="body" style="flex-direction:column;gap:8px">
    <div class="ctlrow">
      <div class="seg"><span class="on">Board</span><span>Need</span><span>Distance</span></div>
      <div class="f-micro s2">Weekly hours remaining in the meter at right.</div>
    </div>
    <div style="display:flex;gap:8px;flex:1;min-height:0">
      <div class="tbl grow">
        <div class="capline">Ranked live targets<div class="cnt">Need: QB, LT</div></div>
        <div class="thead" style="grid-template-columns:{cols}"><span class="on">Rk</span><span>Prospect</span><span>Pos</span><span>OVR</span><span>Conf</span><span>State</span></div>
        {''.join(trs)}
      </div>
      <div class="panel fill" style="width:200px">
        <div class="phead">Hours this week</div>
        <div class="pad"><div class="meter"><div class="mfill ok" style="width:62%"></div></div>
        <div class="f-micro num s2" style="margin-top:6px">14 of 40 remaining</div></div>
        <div class="drow">Next contact<div class="v">Prospect Fourteen</div></div>
        <div class="pad"><button class="btn primary" style="width:100%">Log contact</button></div>
      </div>
    </div>
  </div>
</div>"""


def s25(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "prospect")}
  <div class="body">
    <div class="panel fill" style="width:240px">
      <div class="pad ident">
        <div class="plate" style="width:52px;height:64px"></div>
        <div>
          <div class="nm">Prospect Fourteen</div>
          <div class="f-cap s2">QB · Junior · uncommitted</div>
          <div style="margin-top:6px">{rb(88)} <span class="chip">High conf</span></div>
        </div>
      </div>
      <div class="drow">Relationship<div class="v">Second visit set</div></div>
      <div class="drow">Fit<div class="v">Strong</div></div>
      <div class="drow">Worth<div class="v">band — unscouted market</div></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Evaluation<div class="k">uncertainty</div></div>
      <div class="drow">Accuracy<div class="v">fog until more film</div></div>
      <div class="drow">Arm<div class="v">{rb(86)}</div></div>
      <div class="drow">Decision<div class="v">sample thin</div></div>
      <div class="verdict" style="margin:8px">No staff verdict. Confidence is the observation count, not a flavour sentence.</div>
    </div>
  </div>
</div>"""


def s26(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "shortlist")}
  <div class="body" style="flex-direction:column">
    <div class="agenda">
      <div class="arow sel"><div class="amain"><div class="atitle">Prospect Fourteen</div><div class="asub">QB · next contact Friday</div></div><div class="acost">2h<span class="c2">budget</span></div></div>
      <div class="arow"><div class="amain"><div class="atitle">Prospect Seventy-Two</div><div class="asub">LT · monitor</div></div><div class="acost">—</div></div>
      <div class="arow"><div class="amain"><div class="atitle">Prospect Seven</div><div class="asub">WR · worth is a band</div></div><div class="acost">—</div></div>
    </div>
  </div>
</div>"""


def s27(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "contact")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Weekly contact budget</div>
      <div class="pad"><div class="meter"><div class="mfill" style="width:38%"></div></div>
      <div class="f-cap num s2" style="margin-top:6px">14 hours remaining of 40</div></div>
      <div class="drow">Official visits this week<div class="v">1 scheduled</div></div>
      <div class="drow">Prospect Fourteen<div class="v">Friday</div></div>
      <div class="drow empty">No second visit until hours exist</div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Schedule</div>
      <div class="choice sel"><span class="mark"></span><div class="f-body">Keep Friday visit</div></div>
      <div class="pad"><button class="btn primary" style="width:100%">Lock week</button></div>
    </div>
  </div>
</div>"""


def s28(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "class")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Needs vs commitments</div>
      <div class="drow">QB<div class="v">need · 0 committed</div></div>
      <div class="drow">LT<div class="v">need · 0 committed</div></div>
      <div class="drow">WR<div class="v">1 committed</div></div>
      <div class="drow">Capacity<div class="v">scholarships remaining</div></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Class history</div>
      <div class="drow">Last cycle<div class="v">signed 18</div></div>
      <div class="drow empty">History is bounded; this is not an unbounded feed</div>
    </div>
  </div>
</div>"""


def s29(a="dk"):
    return f"""<div class="screen">
  <div class="body full" style="flex-direction:column;gap:8px">
    <div style="display:flex;align-items:center;gap:12px">
      {team_chip("home")}
      <div class="f-title">Signing Day</div>
      <div class="f-head num live" style="margin-left:auto">04:12:08</div>
    </div>
    <div style="display:flex;gap:8px;flex:1;min-height:0">
      <div class="panel fill grow">
        <div class="phead">Commitment feed<div class="k">timed</div></div>
        <div class="drow">Prospect Seven<div class="v pos">Signed · WR</div></div>
        <div class="drow">Prospect Fourteen<div class="v warn">Open</div></div>
        <div class="drow">Prospect Seventy-Two<div class="v warn">Open</div></div>
      </div>
      <div class="panel fill" style="width:240px">
        <div class="phead">Unresolved</div>
        <div class="choice sel"><span class="mark"></span><div class="f-body">Hold the QB offer</div></div>
        <div class="choice" style="margin-top:6px"><span class="mark"></span><div class="f-body">Flip hours to LT</div></div>
        <div class="pad"><button class="btn primary" style="width:100%">Commit hours</button></div>
      </div>
    </div>
  </div>
</div>"""


def s30(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=0, can_advance=True)}
  {local_routes(ACQUIRE, "portal")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Portal window</div>
      <div class="drow">Phase<div class="v">Open</div></div>
      <div class="drow">Roster exposure<div class="v">P07 monitored</div></div>
      <div class="drow">Movement in<div class="v">0 this window</div></div>
      <div class="drow">Movement out<div class="v">0 this window</div></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Summary</div>
      <div class="empty"><span class="sym">list.number</span><div class="et">No portal movement yet</div><div class="ed">The window is open. Entries appear here when a player enters or lands.</div></div>
    </div>
  </div>
</div>"""


def s31(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "retain")}
  <div class="body">
    <div class="tbl grow">
      <div class="capline">Departure risk</div>
      <div class="thead" style="grid-template-columns:minmax(140px,1fr) 50px 80px 90px"><span class="on">Player</span><span>OVR</span><span>Risk</span><span>Promise</span></div>
      <div class="trow sel" style="grid-template-columns:minmax(140px,1fr) 50px 80px 90px"><span class="nm">Player Seven</span><span>{rb(79)}</span><span class="n">Watch</span><span class="n">NIL + snaps</span></div>
      <div class="trow" style="grid-template-columns:minmax(140px,1fr) 50px 80px 90px"><span class="nm">Player Nine</span><span>{rb(72)}</span><span class="n">Low</span><span class="n">Redshirt path</span></div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Trade-off</div>
      <div class="drow">NIL this player<div class="v">from the pool</div></div>
      <div class="pad"><button class="btn primary" style="width:100%">Promise</button></div>
    </div>
  </div>
</div>"""


def s32(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "market")}
  <div class="body" style="flex-direction:column">
    <div class="tbl grow">
      <div class="capline">Available players<div class="cnt">capacity still owns the add</div></div>
      <div class="thead" style="grid-template-columns:minmax(140px,1fr) 40px 40px 70px 90px"><span class="on">Player</span><span>Pos</span><span>OVR</span><span>Fit</span><span>Competition</span></div>
      <div class="trow sel" style="grid-template-columns:minmax(140px,1fr) 40px 40px 70px 90px"><span class="nm">Portal Eleven</span><span class="n">TE</span><span>{rb(78)}</span><span class="n">Good</span><span class="n">2 clubs</span></div>
      <div class="trow" style="grid-template-columns:minmax(140px,1fr) 40px 40px 70px 90px"><span class="nm">Portal Twenty-Six</span><span class="n">CB</span><span>{rb(75)}</span><span class="n">Fair</span><span class="n">1 club</span></div>
    </div>
  </div>
</div>"""


def s33(a="dk"):
    return f"""<div class="screen">
  {world_strip("recruit", due=2)}
  {local_routes(ACQUIRE, "nil")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Programme pool</div>
      <div class="pad"><div class="meter"><div class="mfill ok" style="width:54%"></div></div>
      <div class="f-cap num s2" style="margin-top:6px">Allocated 54% · remainder is unspent, not hidden</div></div>
      <div class="drow">Player Fourteen<div class="v">starter share</div></div>
      <div class="drow">Player Seven<div class="v">retention share</div></div>
      <div class="drow">Unallocated<div class="v">held</div></div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Move money</div>
      <div class="choice sel"><span class="mark"></span><div class="f-body">Hold the remainder</div></div>
      <div class="pad"><button class="btn primary" style="width:100%">Set allocation</button></div>
    </div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# Professional front office (34–40)
# ---------------------------------------------------------------------------

def s34(a="dk"):
    return f"""<div class="screen">
  {world_strip("front", due=0, can_advance=True, pro=True)}
  {local_routes(FRONT, "cap")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Legal ledger<div class="k">over capacity</div></div>
      <div class="pad">
        <div class="f-cap num">$259,997,200 committed · $255,400,000 cap</div>
        <div class="meter" style="margin-top:8px"><div class="mfill over" style="width:100%"></div></div>
        <div class="f-micro neg num" style="margin-top:6px">Overage $4,597,200 — 101.8%</div>
      </div>
      <div class="drow">Next season<div class="v">$9–15M over (band)</div></div>
      <div class="drow">Two seasons out<div class="v">$8M under to $2M over</div></div>
    </div>
    <div class="panel fill" style="width:240px">
      <div class="phead">Player Fourteen</div>
      <div class="drow">Remaining<div class="v">$2,400,000</div></div>
      <div class="drow">Market<div class="v">$3.0–4.5M</div></div>
      <div class="pad"><button class="btn secondary" style="width:100%">Open negotiation</button></div>
    </div>
  </div>
</div>"""


def s35(a="dk"):
    return f"""<div class="screen">
  {world_strip("front", due=0, can_advance=True, pro=True)}
  {local_routes(FRONT, "negotiate")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Term and guarantee<div class="k">Player Fourteen</div></div>
      <div class="drow">Years<div class="v">3</div></div>
      <div class="drow">Guarantee<div class="v">$6,000,000</div></div>
      <div class="drow">Role<div class="v">starting QB</div></div>
      <div class="drow">Cap this year<div class="v">adds to the overage</div></div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Actions</div>
      <button class="btn primary" style="margin:8px">Send offer</button>
      <button class="btn ghost" style="margin:0 8px 8px">Walk away</button>
    </div>
  </div>
</div>"""


def s36(a="dk"):
    return f"""<div class="screen">
  {world_strip("front", due=0, can_advance=True, pro=True)}
  {local_routes(FRONT, "cuts")}
  <div class="body">
    <div class="tbl grow">
      <div class="capline">Roster cuts<div class="cnt">deadline owns the action</div></div>
      <div class="thead" style="grid-template-columns:minmax(140px,1fr) 40px 40px 90px"><span class="on">Player</span><span>Pos</span><span>OVR</span><span>If cut</span></div>
      <div class="trow sel" style="grid-template-columns:minmax(140px,1fr) 40px 40px 90px"><span class="nm">Player Nine</span><span class="n">RB</span><span>{rb(72)}</span><span class="n">lose depth</span></div>
    </div>
    <div class="panel fill" style="width:200px">
      <div class="phead">Legality</div>
      <div class="drow">Current<div class="v">over cap</div></div>
      <div class="pad"><button class="btn destr" style="width:100%">Cut</button></div>
    </div>
  </div>
</div>"""


def s37(a="dk"):
    return f"""<div class="screen">
  {world_strip("front", due=0, can_advance=True, pro=True)}
  {local_routes(FRONT, "scout")}
  <div class="body" style="flex-direction:column">
    <div class="tbl grow">
      <div class="capline">Uncertain evaluations<div class="cnt">bands where the sim does not own a point</div></div>
      <div class="thead" style="grid-template-columns:minmax(140px,1fr) 40px 50px 70px"><span class="on">Prospect</span><span>Pos</span><span>Band</span><span>Conf</span></div>
      <div class="trow sel" style="grid-template-columns:minmax(140px,1fr) 40px 50px 70px"><span class="nm">Prospect Fourteen</span><span class="n">QB</span><span class="n">80–88</span><span class="n">Med</span></div>
      <div class="trow" style="grid-template-columns:minmax(140px,1fr) 40px 50px 70px"><span class="nm">Prospect Seven</span><span class="n">WR</span><span class="n">74–82</span><span class="n">Low</span></div>
    </div>
  </div>
</div>"""


def s38(a="dk"):
    return f"""<div class="screen">
  {world_strip("front", due=0, can_advance=True, pro=True)}
  {local_routes(FRONT, "dboard")}
  <div class="body" style="flex-direction:column">
    <div class="tbl grow">
      <div class="capline">Draft board<div class="cnt">needs: edge, QB depth</div></div>
      <div class="thead" style="grid-template-columns:36px minmax(140px,1fr) 40px 50px 80px"><span class="on">Rk</span><span>Prospect</span><span>Pos</span><span>Band</span><span>Need</span></div>
      <div class="trow sel" style="grid-template-columns:36px minmax(140px,1fr) 40px 50px 80px"><span class="n">1</span><span class="nm">Prospect Fifty-Four</span><span class="n">DE</span><span class="n">82–90</span><span class="n">edge</span></div>
      <div class="trow" style="grid-template-columns:36px minmax(140px,1fr) 40px 50px 80px"><span class="n">2</span><span class="nm">Prospect Fourteen</span><span class="n">QB</span><span class="n">80–88</span><span class="n">depth</span></div>
    </div>
  </div>
</div>"""


def s39(a="dk"):
    return f"""<div class="screen">
  <div class="body full" style="flex-direction:column;gap:8px">
    <div style="display:flex;align-items:center;gap:12px">
      {team_chip("third")}
      <div class="f-title">Draft Room</div>
      <div class="f-head num live" style="margin-left:auto">00:42</div>
    </div>
    <div style="display:flex;gap:8px;flex:1">
      <div class="panel fill grow">
        <div class="phead">On the clock<div class="k">Example Union · pick 18</div></div>
        <div class="drow">Board 1<div class="v">Prospect Fifty-Four · DE</div></div>
        <div class="drow">Trade offer<div class="v">none live</div></div>
      </div>
      <div class="panel fill" style="width:240px">
        <div class="phead">At the clock</div>
        <button class="btn primary" style="margin:8px;width:calc(100% - 16px)">Draft P54</button>
        <button class="btn ghost" style="margin:0 8px 8px;width:calc(100% - 16px)">Listen for trade</button>
      </div>
    </div>
  </div>
</div>"""


def s40(a="dk"):
    return f"""<div class="screen">
  {world_strip("front", due=0, can_advance=True, pro=True)}
  {local_routes(FRONT, "fa")}
  <div class="body">
    <div class="tbl grow">
      <div class="capline">Live market<div class="cnt">wave 1</div></div>
      <div class="thead" style="grid-template-columns:minmax(140px,1fr) 40px 50px 90px"><span class="on">Player</span><span>Pos</span><span>OVR</span><span>Bidders</span></div>
      <div class="trow sel" style="grid-template-columns:minmax(140px,1fr) 40px 50px 90px"><span class="nm">Player Fourteen</span><span class="n">QB</span><span>{rb(84)}</span><span class="n">2 clubs</span></div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Our offer</div>
      <div class="drow">Term<div class="v">3 years</div></div>
      <div class="pad"><button class="btn primary" style="width:100%">Bid</button></div>
    </div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# League and competition (41–51)
# ---------------------------------------------------------------------------

def s41(a="dk"):
    regions = [
        ("Example Ridge", "W · Week 4", False),
        ("Example Harbor", "L · Week 5", False),
        ("Example Valley", "W · Week 6", False),
        ("Example Summit", "W · Week 7", False),
        ("Example Union", "W · Week 8", False),
        ("Example Coastal", "Next · away", True),
        ("Example State", "Home · 6-2", False),
        ("Open sea", "—", False),
    ]
    cells = []
    for n, m, nxt in regions:
        cls = "region home" if nxt else "region"
        cells.append(f'<div class="{cls}"><div class="rn">{n}</div><div class="rm">{m}</div></div>')
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "map")}
  <div class="body" style="flex-direction:column">
    <div class="mapgrid">{''.join(cells)}</div>
    <div class="f-micro q">Place and rivalry context, not a real-world map. Distance is conference adjacency in this save.</div>
  </div>
</div>"""


def s42(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "programme")}
  <div class="body">
    <div class="panel fill" style="width:240px">
      <div class="pad ident">
        {team_chip("away")}
        <div>
          <div class="nm">Example Coastal</div>
          <div class="f-cap s2">5-3 · next opponent</div>
        </div>
      </div>
      <div class="drow">Venue<div class="v">Away for us</div></div>
      <div class="drow">Last meeting<div class="v">not this season</div></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Trajectory</div>
      <div class="drow">Pass yards<div class="v num">267 sample</div></div>
      <div class="drow">Rush allowed<div class="v num">88, 121, 94, 103</div></div>
      <div class="drow">Edge<div class="v">Player Fifty-Four</div></div>
    </div>
  </div>
</div>"""


def s43(a="dk"):
    table = [
        ("1", "Example State", "6-2", "4-1", True),
        ("2", "Example Coastal", "5-3", "3-2", False),
        ("3", "Example Union", "5-3", "3-2", False),
        ("4", "Example Valley", "4-4", "2-3", False),
        ("5", "Example Summit", "3-5", "1-4", False),
        ("6", "Example Harbor", "2-6", "1-4", False),
        ("7", "Example Ridge", "2-6", "0-5", False),
    ]
    cols = "36px minmax(140px,1.4fr) 48px 48px"
    trs = []
    for rk, n, rec, conf, sel in table:
        cls = "trow sel" if sel else "trow"
        trs.append(
            f'<div class="{cls}" style="grid-template-columns:{cols}"><span class="n">{rk}</span><span class="nm">{n}</span><span class="n">{rec}</span><span class="n">{conf}</span></div>'
        )
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "standings")}
  <div class="body" style="flex-direction:column">
    <div class="tbl grow">
      <div class="capline">Conference order<div class="cnt">tiebreak: H2H then conference record</div></div>
      <div class="thead" style="grid-template-columns:{cols}"><span class="on">#</span><span>Programme</span><span>Ovr</span><span>Conf</span></div>
      {''.join(trs)}
    </div>
  </div>
</div>"""


def s44(a="dk"):
    sked = [
        ("4", "vs Example Ridge", "W", "78"),
        ("5", "at Example Harbor", "L", "81"),
        ("6", "vs Example Valley", "W", "74"),
        ("7", "at Example Summit", "W", "86"),
        ("8", "at Example Union", "W", "83"),
        ("9", "at Example Coastal", "—", "prep"),
    ]
    items = "".join(
        f'<div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">Week {w} · {fx}</div><div class="f-micro s2">P14 {r}</div></div><div class="f-head num">{res}</div></div>'
        for w, fx, res, r in sked
    )
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "schedule")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Season chronology<div class="k">Weeks 4–9</div></div>
      <div class="timeline">{items}</div>
    </div>
  </div>
</div>"""


def s45(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "rankings")}
  <div class="body">
    <div class="tbl grow">
      <div class="capline">Selection neighbourhood<div class="cnt">path still open</div></div>
      <div class="thead" style="grid-template-columns:36px minmax(140px,1fr) 48px 80px"><span class="on">Rk</span><span>Programme</span><span>Rec</span><span>Note</span></div>
      <div class="trow" style="grid-template-columns:36px minmax(140px,1fr) 48px 80px"><span class="n">8</span><span class="nm">Example Valley</span><span class="n">4-4</span><span class="n">above</span></div>
      <div class="trow sel" style="grid-template-columns:36px minmax(140px,1fr) 48px 80px"><span class="n">9</span><span class="nm">Example State</span><span class="n">6-2</span><span class="n">us</span></div>
      <div class="trow" style="grid-template-columns:36px minmax(140px,1fr) 48px 80px"><span class="n">10</span><span class="nm">Example Coastal</span><span class="n">5-3</span><span class="n">next</span></div>
    </div>
  </div>
</div>"""


def s46(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=0, can_advance=True)}
  {local_routes(LEAGUE, "bracket")}
  <div class="body">
    <div class="bracket">
      <div class="bcol">
        <div class="bcell">Example State</div>
        <div class="bcell">Example Harbor</div>
        <div class="bcell">Example Valley</div>
        <div class="bcell">Example Ridge</div>
      </div>
      <div class="bcol">
        <div class="bcell live">Example State</div>
        <div class="bcell">Example Valley</div>
      </div>
      <div class="bcol">
        <div class="bcell">—</div>
      </div>
    </div>
  </div>
</div>"""


def s47(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "box")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Week 8 · at Example Union<div class="k">24–17 W</div></div>
      <div class="drow">Pass yards<div class="v num">213</div></div>
      <div class="drow">Rush yards<div class="v num">184</div></div>
      <div class="drow">Takeaways<div class="v">1–3</div></div>
      <div class="drow">P14 rating<div class="v">83</div></div>
      <div class="drow">Turning point<div class="v">P54 sack, Q3</div></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Drives</div>
      <div class="drow">Opening<div class="v">FG · 11 plays</div></div>
      <div class="drow">Q3 answer<div class="v">TD after sack</div></div>
      <div class="drow empty">Participation is the legal sheet, not a second box</div>
    </div>
  </div>
</div>"""


def s48(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "stats")}
  <div class="body" style="flex-direction:column">
    <div class="ctlrow"><div class="seg"><span class="on">Passing</span><span>Rushing</span><span>Defense</span></div></div>
    <div class="tbl grow">
      <div class="capline">Leaders<div class="cnt">sample is the season so far</div></div>
      <div class="thead" style="grid-template-columns:36px minmax(140px,1fr) 70px 50px"><span class="on">#</span><span>Player</span><span>Yds</span><span>TD</span></div>
      <div class="trow sel" style="grid-template-columns:36px minmax(140px,1fr) 70px 50px"><span class="n">1</span><span class="nm">Player Fourteen</span><span class="n">1,842</span><span class="n">14</span></div>
    </div>
  </div>
</div>"""


def s49(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=0, can_advance=True)}
  {local_routes(LEAGUE, "awards")}
  <div class="body full" style="flex-direction:column;justify-content:center;gap:12px">
    <div class="f-micro col" style="letter-spacing:.12em;text-transform:uppercase">Honours</div>
    <div class="f-title">Not yet awarded this season</div>
    <div class="f-body s2">Awards land after the regular season. This surface stays empty rather than inventing a trophy.</div>
  </div>
</div>"""


def s50(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=2)}
  {local_routes(LEAGUE, "news")}
  <div class="body" style="flex-direction:column">
    <div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">Example State holds at 6-2</div><div class="f-micro s2">Week 8 · bounded newest-first</div></div></div>
    <div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">Player Fifty-One will miss Week 9</div><div class="f-micro s2">Suspension · already on the sheet</div></div></div>
    <div class="empty" style="flex:none;padding:12px"><div class="ed">Editorial copy is generated news. Until that system writes, only facts the save already owns appear here.</div></div>
  </div>
</div>"""


def s51(a="dk"):
    return f"""<div class="screen">
  {world_strip("league", due=0, can_advance=True)}
  {local_routes(LEAGUE, "map")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Realignment</div>
      <div class="empty"><span class="sym">calendar.badge.exclamationmark</span><div class="et">No realignment this season</div><div class="ed">When a conference map changes, cause and consequence occupy this frame. Inventing a move would be set dressing.</div></div>
    </div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# Career and legacy (52–60)
# ---------------------------------------------------------------------------

def s52(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=2)}
  {local_routes(CAREER, "hub")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Career so far</div>
      <div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">Appointed at Example State</div><div class="f-micro s2">Season 1 · Week 0</div></div></div>
      <div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">Week 8 at Example Union, W</div><div class="f-micro s2">Record 6-2</div></div></div>
      <div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">Week 9 preparation</div><div class="f-micro s2">Example Coastal, away</div></div></div>
    </div>
  </div>
</div>"""


def s53(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=2)}
  {local_routes(CAREER, "security")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Expectation</div>
      <div class="pad"><div class="meter"><div class="mfill ok" style="width:70%"></div></div>
      <div class="f-cap s2" style="margin-top:6px">Bowl line. Record 6-2 is above it.</div></div>
      <div class="drow">Jeopardy<div class="v">not active</div></div>
      <div class="drow">Last trigger<div class="v">none this season</div></div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">Movement</div>
      <div class="drow empty">No board vote in Week 9</div>
    </div>
  </div>
</div>"""


def s54(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=2)}
  {local_routes(CAREER, "stakeholders")}
  <div class="body" style="flex-direction:column">
    <div class="ident pad panel">
      <div class="plate" style="width:48px;height:56px"></div>
      <div class="grow"><div class="nm">Athletic director</div><div class="f-cap s2">Voice on appointment day. Quiet this week.</div></div>
    </div>
    <div class="ident pad panel">
      <div class="plate" style="width:48px;height:56px"></div>
      <div class="grow"><div class="nm">Coordinator Sample</div><div class="f-cap s2">Defensive coordinator · call-ins and receipts</div></div>
    </div>
  </div>
</div>"""


def s55(a="dk"):
    return f"""<div class="screen">
  <div class="body full" style="flex-direction:column;justify-content:center;align-items:center;gap:12px">
    <div class="f-micro pro" style="letter-spacing:.12em;text-transform:uppercase">Promotion</div>
    <div class="f-display">Example Union</div>
    <div class="f-head s2">Professional head-coaching offer</div>
    <div class="panel" style="width:420px">
      <div class="drow">Length<div class="v">5 seasons</div></div>
      <div class="drow">Decline path<div class="v">Remain at Example State</div></div>
    </div>
    <div class="ctlrow">
      <button class="btn primary">Read terms</button>
      <button class="btn ghost">Stay in college</button>
    </div>
    <div class="f-micro q">Drawn as ceremony. It is not Week 9; it is the later offer with a real decline.</div>
  </div>
</div>"""


def s56(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=0, can_advance=True)}
  {local_routes(CAREER, "carousel")}
  <div class="body">
    <div class="job rec">
      <div class="rank">Interest</div>
      <div class="nm">Example Harbor</div>
      <div class="f-cap s2">Rebuild · not a dead end</div>
      <button class="btn secondary">Listen</button>
    </div>
    <div class="job">
      <div class="rank">Open</div>
      <div class="nm">Example Ridge</div>
      <div class="f-cap s2">Mid-major</div>
      <button class="btn ghost">Ignore</button>
    </div>
    <div class="panel fill" style="width:200px">
      <div class="phead">This week</div>
      <div class="drow empty">Carousel is quiet in Week 9 prep</div>
    </div>
  </div>
</div>"""


def s57(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=2)}
  {local_routes(CAREER, "records")}
  <div class="body" style="flex-direction:column">
    <div class="tbl grow">
      <div class="capline">Bounded records in this save</div>
      <div class="thead" style="grid-template-columns:minmax(180px,1.4fr) minmax(120px,1fr) 70px"><span class="on">Record</span><span>Holder</span><span>Value</span></div>
      <div class="trow" style="grid-template-columns:minmax(180px,1.4fr) minmax(120px,1fr) 70px"><span class="nm">Passing yards, game</span><span class="n">Player Fourteen</span><span class="n">—</span></div>
      <div class="trow" style="grid-template-columns:minmax(180px,1.4fr) minmax(120px,1fr) 70px"><span class="nm">Career wins, this coach</span><span class="n">Coach Sample</span><span class="n">6</span></div>
    </div>
  </div>
</div>"""


def s58(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=2)}
  {local_routes(CAREER, "rivals")}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Example Coastal<div class="k">this week</div></div>
      <div class="drow">History<div class="v">not yet a series this save</div></div>
      <div class="drow">Current stakes<div class="v">standings neighbourhood</div></div>
      <div class="drow">Accumulated strength<div class="v">thin sample</div></div>
    </div>
    <div class="panel fill grow">
      <div class="phead">Example Union<div class="k">Week 8</div></div>
      <div class="drow">Last result<div class="v">W 24-17</div></div>
      <div class="drow">Takeaways<div class="v">1–3</div></div>
    </div>
  </div>
</div>"""


def s59(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=2)}
  {local_routes(CAREER, "line")}
  <div class="body" style="flex-direction:column">
    <div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">Season 1 · Example State · HC</div><div class="f-micro s2">6-2 through Week 8</div></div></div>
    <div class="f-micro q pad">Later seasons append here. The line is chronological, not a dashboard of equal tiles.</div>
  </div>
</div>"""


def s60(a="dk"):
    return f"""<div class="screen">
  {world_strip("career", due=2)}
  {local_routes(CAREER, "tree")}
  <div class="body" style="flex-direction:column;align-items:center;justify-content:center">
    <div class="tnode">
      <div class="plate" style="width:44px;height:52px;margin:0 auto 6px"></div>
      <div class="nm">Coach Sample</div>
      <div class="f-micro s2">Example State · HC</div>
      <div class="tkids">
        <div class="tnode">
          <div class="plate" style="width:36px;height:44px;margin:0 auto 6px"></div>
          <div class="nm">Coordinator Sample</div>
          <div class="f-micro s2">DC · same staff</div>
        </div>
      </div>
    </div>
    <div class="f-micro q" style="margin-top:8px">Descendants accrue when staff leave for their own seats. None have yet.</div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# Offseason command (61–62)
# ---------------------------------------------------------------------------

def s61(a="dk"):
    steps = [
        ("Signing", "commitments unresolved", True),
        ("Portal", "window dates", False),
        ("NIL", "pool reset", False),
        ("Staff", "continuity", False),
        ("Carousel", "open jobs", False),
    ]
    items = "".join(
        f'<div class="titem{" " if not cur else ""}"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">{n}</div><div class="f-micro s2">{d}</div></div>{("<span class=chip>now</span>" if cur else "")}</div>'
        for n, d, cur in steps
    )
    return f"""<div class="screen">
  {world_strip("office", due=0, can_advance=True)}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">College offseason<div class="k">dated sequence</div></div>
      <div class="timeline">{items}</div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">This date</div>
      <div class="f-cap s2 pad">Signing still has open names. Continue walks the sequence; it does not skip a dated gate.</div>
      <div class="pad"><button class="btn live" style="width:100%">Continue</button></div>
    </div>
  </div>
</div>"""


def s62(a="dk"):
    steps = [
        ("Cuts", "legality deadline", True),
        ("Contracts", "cap ledger", False),
        ("Market", "free agency waves", False),
        ("Draft", "board then room", False),
        ("Staff", "continuity", False),
        ("Carousel", "open jobs", False),
    ]
    items = "".join(
        f'<div class="titem"><div class="tdot"></div><div class="grow"><div class="f-body" style="font-weight:600">{n}</div><div class="f-micro s2">{d}</div></div>{("<span class=chip>now</span>" if cur else "")}</div>'
        for n, d, cur in steps
    )
    return f"""<div class="screen">
  {world_strip("front", due=0, can_advance=True, pro=True)}
  <div class="body">
    <div class="panel fill grow">
      <div class="phead">Pro offseason<div class="k">dated sequence</div></div>
      <div class="timeline">{items}</div>
    </div>
    <div class="panel fill" style="width:220px">
      <div class="phead">This date</div>
      <div class="f-cap s2 pad">Cuts first because the ledger is over capacity. Draft room and market wait their dates.</div>
      <div class="pad"><button class="btn live" style="width:100%">Continue</button></div>
    </div>
  </div>
</div>"""


# ---------------------------------------------------------------------------
# Groups and index
# ---------------------------------------------------------------------------

GROUPS = [
    {
        "file": "01-entry-and-system.html",
        "title": "Entry and system — families 1–7",
        "kicker": "screen mockups · 04 §8 · Coach's World",
        "intro": """<p style="margin-top:10px">Pre-career and system surfaces. Title and Appointment are ceremony-shaped; Job Board is three ranked, defensible jobs rather than an equal card grid; Settings sits under a live world strip; World Search is a bounded index. Continue on Title is the durable save boundary, not a week advance.</p>""",
        "cards": [
            (1, "Title / Continue", "current career and durable boundary", "Ceremony / system", "chrome-v3",
             "Inside the frame: a save receipt and two 44 pt actions. No world strip — there is not yet a week to advance.", s1, False),
            (2, "New Career & Coach Identity", "coach premise and generated universe", "Ceremony / system", "chrome-v3, person-v3",
             "Universe counts are engine-owned (134 / 32 / 15,766). Identities stay labelled pending generator output in gallery chrome.", s2, False),
            (3, "Job Board", "three defensible starting jobs", "Career & Legacy", "chrome-v3, table-v3",
             "Three columns, ranked. Selection is a boundary, not a fill. Example Harbor / Ridge exist in the shared-world schedule; they are reused rather than inventing a fourth colour pair.", s3, False),
            (4, "Offer", "terms and accept/decline consequence", "Career & Legacy", "chrome-v3, readout-v3",
             "Money is integer dollars. Decline returns to the Job Board; it is not a dead end.", s4, False),
            (5, "Appointment", "stakeholder handoff and programme identity", "Ceremony", "chrome-v3, person-v3",
             "Rare, focused, minimal controls. Team chip is the dark-primary synthetic trio with the mandatory content.secondary boundary.", s5, False),
            (6, "Settings & Accessibility", "device, match and accessibility choices", "Coach's Office", "chrome-v3, tokens-v3",
             "No football task is replaced by a settings dump. World strip remains so the player never loses where they are.", s6, False),
            (7, "World Search", "bounded index across people, teams, games and history", "League & Media", "table-v3, chrome-v3",
             "Cap shown in the capacity header (4 of 40). Unbounded search is the prior-build save-bloat failure mode.", s7, False),
        ],
    },
    {
        "file": "02-week-and-match.html",
        "title": "Week and match — families 8–15",
        "kicker": "screen mockups · 04 §8 · Coach's Office / Film / Broadcast",
        "intro": """<p style="margin-top:10px">The week loop. Coaching HQ, Recruiting Board and Match Day are the 04 §10 proof-gate trio — HQ and Match Day are in this file; Recruiting Board is in college acquisition. Dark is the desk default; HQ and Match Day also render light. Honest blanks: empty G-02 verdict, empty correspondence, week-grain practice minutes, Aftermath is Week 8 because Week 9 has not been played.</p>""",
        "cards": [
            (8, "Coaching HQ", "current week plan and next obligation", "Coach's Office", "chrome-v3, week-v3, readout-v3",
             "Three regions: identity rail, week plan + due decision, desk wire. Continue disabled while 2 obligations are due. Film and Delegate are labelled icon-first utilities (04 §6.3).", s8, True),
            (9, "Inbox", "conversations and commitments with cost", "Coach's Office", "week-v3, failure-v3",
             "AgendaRows are engine-shaped mandatory work. Correspondence is an EmptyState inside the composition — no invented mail.", s9, False),
            (10, "Opponent Report / Film Room", "observed film, staff interpretation and confidence", "Film Room", "readout-v3, broadcast-v3, failure-v3",
             "Shipping form: verdict slot empty. Rush-yards-allowed series is the shared-world figure. Play art withheld until G-06.", s10, False),
            (11, "Game Plan", "weekly tactical keys and trade-offs", "Film Room / Office", "readout-v3, week-v3",
             "Opposed bars use shared-world 184/92, 213/267, 1/3. Set plan is the commit; no named-staff flavour sentence.", s11, False),
            (12, "Practice Plan", "scarce practice minutes across units", "Coach's Office", "readout-v3, week-v3",
             "Four 60-minute buckets. Session-type symbols (figure.run, film, airplane, football, moon.zzz) belong to the G-14 day grid and are not spent here.", s12, False),
            (13, "Team Health", "availability, fatigue, injury and return decisions", "Personnel Room", "table-v3, failure-v3",
             "P51 remains suspended and legible (F-08). No return-to-play intent is drawn as if it exists.", s13, False),
            (14, "Match Day", "full field, score, current cause and call-ins", "Broadcast", "broadcast-v3, chrome-v3",
             "No world strip. Scorebug EXC 13–EXS 10, Q3 07:26, 1st and 10. Five primary controls. Call-in from Coordinator Sample. 22 actors, at most three foregrounded. Route vectors not drawn (G-06).", s14, True),
            (15, "Aftermath", "result, causal review and recovery consequence", "Coach's Office", "week-v3, readout-v3",
             "Week 8 at Example Union, W 24-17, because Week 9 has not been played. P51 still suspended.", s15, False),
        ],
    },
    {
        "file": "03-team-and-staff.html",
        "title": "Team and staff — families 16–23",
        "kicker": "screen mockups · 04 §8 · Personnel Room",
        "intro": """<p style="margin-top:10px">Dense comparison and identity-led detail. Roster is the legal sheet; Depth is spatial roles; Profile is sequenced disclosure; packages are situation assignments. Fit prints as a word (Poor / Fair / Good / Strong), never a second 40–99 beside OVR.</p>""",
        "cards": [
            (16, "Roster", "sortable legal team sheet", "Personnel Room", "table-v3, chrome-v3",
             "24–28 pt tracks, rating badges, status chip vocabulary. Selection is inset boundary in action.primary, not a team-colour fill.", s16, False),
            (17, "Depth Chart", "spatial roles, packages and succession", "Personnel Room", "table-v3, person-v3",
             "P51's absence is succession, not a blank. Role tokens map the list to the diagram.", s17, False),
            (18, "Player Profile", "role, story, form, confidence and history", "Personnel Room", "person-v3, readout-v3, table-v3",
             "Player Fourteen's numbers are the shared-world table: 84/82, form 78/81/74/86/83, market as a band.", s18, False),
            (19, "Development Plan", "current focus, staff ownership and opportunity cost", "Personnel Room", "person-v3, week-v3",
             "P72 awareness +2 since Week 6 is the shared-world delta. Cost is snaps, not a flavour meter.", s19, False),
            (20, "Staff Room", "assignments, continuity and unit performance", "Personnel Room", "table-v3, person-v3",
             "Analyst Sample is present and G-02-silent rather than voicing an invented unit grade.", s20, False),
            (21, "Staff Market & Profile", "candidate comparison, contract and scheme relationship", "Personnel Room", "person-v3, table-v3",
             "Coordinator Harbor reuses a shared-world place-name as a person token rather than minting a fourth programme colour.", s21, False),
            (22, "Scheme Book", "offensive/defensive identity and adoption cost", "Film Room / Personnel", "readout-v3, broadcast-v3",
             "Identity families, not a reproduced playbook. Diagram marks wait on G-06.", s22, False),
            (23, "Personnel Packages", "situation-specific on-field assignments", "Personnel Room", "table-v3",
             "Nickel and 12 personnel as assignment lists. P51 out is carried from Health and Depth.", s23, False),
        ],
    },
    {
        "file": "04-college-acquisition.html",
        "title": "College acquisition — families 24–33",
        "kicker": "screen mockups · 04 §8 · Acquisition Room",
        "intro": """<p style="margin-top:10px">Recruiting Board is the second 04 §10 proof-gate screen and renders in both appearances. Live ranking, relationship, budget meters, Signing Day clock (nav suppressed), portal empty-until-true, NIL as a finite pool. Prospects are named Prospect Fourteen and peers so they are not confused with roster Player Fourteen.</p>""",
        "cards": [
            (24, "Recruiting Board", "ranked live target board", "Acquisition Room", "table-v3, chrome-v3, readout-v3",
             "Hours remaining is a meter, not a pie. Confidence is High/Med/Low, not an invented scouting novel.", s24, True),
            (25, "Prospect Profile", "evaluation, relationship, fit and uncertainty", "Acquisition Room", "person-v3, readout-v3",
             "Fog stays fog. Verdict slot empty (G-02). Worth is a band when the market is unscouted — same rule as Player Seven on the roster.", s25, False),
            (26, "Shortlist", "monitored prospects and next contact", "Acquisition Room", "week-v3, table-v3",
             "Agenda-shaped commitments with a next-contact cost.", s26, False),
            (27, "Contact & Visit Planner", "weekly contact budget and scheduled visits", "Acquisition Room", "week-v3, readout-v3",
             "Budget is hours. A visit that does not fit is not drawn as scheduled.", s27, False),
            (28, "Class Overview", "needs, commitments, capacity and class history", "Acquisition Room", "table-v3, readout-v3",
             "Needs are positions, not a dashboard of equal tiles.", s28, False),
            (29, "Signing Day", "timed commitment feed and unresolved choices", "Ceremony", "week-v3, chrome-v3",
             "World strip suppressed; a clock is only drawn because Signing Day is timed. Unresolved names stay open rather than auto-signed.", s29, False),
            (30, "Portal Hub", "window, roster exposure and movement summary", "Acquisition Room", "failure-v3, week-v3",
             "Empty movement is an EmptyState, not a fake ticker.", s30, False),
            (31, "Retention Decisions", "departure risk, promise and NIL trade-offs", "Acquisition Room", "table-v3, readout-v3",
             "Player Seven is the watch case, consistent with portal exposure on Hub.", s31, False),
            (32, "Portal Market", "available players, fit, competition and capacity", "Acquisition Room", "table-v3",
             "Portal Eleven / Twenty-Six are market rows, not secretly the roster TE/CB.", s32, False),
            (33, "NIL Allocation", "finite programme pool distributed across the roster", "Acquisition Room", "readout-v3, table-v3",
             "Unspent remainder is visible. The pool is finite.", s33, False),
        ],
    },
    {
        "file": "05-professional-front-office.html",
        "title": "Professional front office — families 34–40",
        "kicker": "screen mockups · 04 §8 · Front Office",
        "intro": """<p style="margin-top:10px">A labelled second moment: Coach Sample at Example Union (low-chroma trio), not Week 9 college. Cap figures are the shared-world meter ($259,997,200 against $255,400,000, 101.8%). Draft Room suppresses world navigation because the clock is real. Steel geometry, transaction receipts, clocks only when real.</p>""",
        "cards": [
            (34, "Cap & Contracts", "legal ledger, commitments and future years", "Front Office", "readout-v3, table-v3",
             "Over-capacity meter is the shared-world figure. Future years are bands because they are projections.", s34, False),
            (35, "Contract Negotiation", "term, guarantee, role and cap consequence", "Front Office", "readout-v3, person-v3",
             "Attached to Player Fourteen. Sending an offer is the object; there is no footer Commit.", s35, False),
            (36, "Roster Cuts & Transactions", "legality deadline and loss of depth", "Front Office", "table-v3, chrome-v3",
             "Cut is destructive and labelled. Depth loss is named on the row.", s36, False),
            (37, "Pro Scouting Board", "uncertain draft and market evaluations", "Front Office", "table-v3, person-v3",
             "Bands, not point OVRs, where the sim does not own a point.", s37, False),
            (38, "Draft Board", "ranked prospects, needs and scouting investment", "Front Office", "table-v3",
             "Need column is why a row is on the board.", s38, False),
            (39, "Draft Room", "timed pick sequence and trade-off at the clock", "Front Office / Ceremony", "chrome-v3, week-v3",
             "No world strip. Clock is live. Pick 18 is a labelled beat, not a copied real draft.", s39, False),
            (40, "Free Agency", "live market waves, competing bidders and offers", "Front Office", "table-v3, week-v3",
             "Wave 1. Bidders are a count the market owns; no invented rival-club drama copy.", s40, False),
        ],
    },
    {
        "file": "06-league-and-competition.html",
        "title": "League and competition — families 41–51",
        "kicker": "screen mockups · 04 §8 · League & Media",
        "intro": """<p style="margin-top:10px">Editorial hierarchy; data tied to teams, games and history. The map is conference adjacency among shared-world programmes, not a real-world geography. Awards and realignment stay empty rather than inventing a trophy or a move. News only repeats facts the save already owns.</p>""",
        "cards": [
            (41, "League Map", "place, distance, regions and rivalry context", "League & Media", "chrome-v3",
             "Example Coastal is marked as next. No real city or venue mark.", s41, False),
            (42, "Team / Programme Profile", "identity, trajectory, venue and history", "League & Media", "person-v3, readout-v3",
             "Example Coastal uses the light-primary trio. P54 is their edge, matching Match Day.", s42, False),
            (43, "Standings", "current competitive order and tiebreak meaning", "League & Media", "table-v3",
             "Tiebreak named in the capacity header: H2H then conference record.", s43, False),
            (44, "Schedule", "season chronology and preparation rhythm", "League & Media", "week-v3, person-v3",
             "Weeks 4–9 and P14 ratings are the shared-world form line.", s44, False),
            (45, "Rankings & Playoff Picture", "selection position, neighbours and path", "League & Media", "table-v3, readout-v3",
             "Neighbourhood, not a fake 25-team poll invented for density.", s45, False),
            (46, "Bracket / Postseason", "live elimination path", "League & Media", "week-v3",
             "GUIDE shape of an eight-team path. Week 9 is still regular season; captioned as such in the family note. Live cell is Example State still playing.", s46, False),
            (47, "Game Detail / Box Score", "result, drives, turning points and participation", "League & Media / Film", "table-v3, readout-v3",
             "Week 8 figures only. Turning point is the P54 sack already on Match Day's lower third.", s47, False),
            (48, "Statistics & Leaders", "bounded comparison with context and sample", "League & Media", "table-v3",
             "Sample is the season so far. One leader row rather than a scraped real-stat dump.", s48, False),
            (49, "Awards & Honours", "season and career recognition", "Ceremony", "failure-v3, chrome-v3",
             "Empty until the season awards. Inventing a trophy would be set dressing.", s49, False),
            (50, "News", "editorial world events, bounded newest-first", "League & Media", "week-v3, failure-v3",
             "Only facts already on Health and Standings. Generated news is an open M7 item.", s50, False),
            (51, "Realignment Event", "map change, cause and consequence", "League & Media", "failure-v3",
             "EmptyState: no realignment this season.", s51, False),
        ],
    },
    {
        "file": "07-career-and-legacy.html",
        "title": "Career and legacy — families 52–60",
        "kicker": "screen mockups · 04 §8 · Career & Legacy",
        "intro": """<p style="margin-top:10px">Chronological composition; earned ceremony. Promotion is the college-to-pro offer with a visible decline path — labelled as a later moment, not Week 9. Coaching Tree shows only staff who exist; descendants do not appear until they leave for seats.</p>""",
        "cards": [
            (52, "Career Hub", "chronological story of the coach", "Career & Legacy", "week-v3, person-v3",
             "Appointment, Week 8, Week 9 prep. Not a tile dashboard.", s52, False),
            (53, "Job Security", "expectation, movement, cause and jeopardy", "Career & Legacy", "readout-v3",
             "Bowl line, 6-2 above it, jeopardy not active. No invented board crisis.", s53, False),
            (54, "Stakeholders", "relationships, voices and recent triggers", "Career & Legacy", "person-v3",
             "Blank plates. Athletic director and Coordinator Sample only.", s54, False),
            (55, "Promotion Decision", "college-to-pro offer with a real decline path", "Ceremony", "chrome-v3, person-v3",
             "Example Union, decline remains at Example State. Not the Week 9 moment.", s55, False),
            (56, "Coaching Carousel", "open jobs, interest and non-dead-end outcomes", "Career & Legacy", "chrome-v3",
             "Quiet in Week 9 prep; Harbor/Ridge reused. Ignore is a real action.", s56, False),
            (57, "Record Book", "bounded records across the save", "Career & Legacy", "table-v3",
             "Career wins = 6, which the save owns. Passing-yards-game is an empty holder rather than a fake 413.", s57, False),
            (58, "Rivalries", "history, current stakes and accumulated strength", "Career & Legacy", "readout-v3, week-v3",
             "Coastal is this week's stake; Union is last week's result. Thin sample is named.", s58, False),
            (59, "Career Line", "roles, seasons, records and defining moments", "Career & Legacy", "week-v3",
             "One season so far. Later seasons append; they are not invented.", s59, False),
            (60, "Coaching Tree", "staff relationships and career descendants", "Career & Legacy", "person-v3",
             "Coordinator Sample is same-staff, not a disciple-with-inverted-dates. No descendants yet.", s60, False),
        ],
    },
    {
        "file": "08-offseason-command.html",
        "title": "Offseason command — families 61–62",
        "kicker": "screen mockups · 04 §8 · Coach's Office / Front Office",
        "intro": """<p style="margin-top:10px">Dated sequences, not menus. Continue walks the next dated gate. College links signing, portal, NIL, staff and carousel. Pro links cuts, contracts, market, draft, staff and carousel — cuts first here because the shared-world ledger is over cap.</p>""",
        "cards": [
            (61, "College Offseason", "dated sequence linking signing, portal, NIL, staff and carousel", "Coach's Office", "week-v3, chrome-v3",
             "Signing is the current gate. Continue does not skip it.", s61, False),
            (62, "Pro Offseason", "dated sequence linking cuts, contracts, market, draft, staff and carousel", "Front Office", "week-v3, chrome-v3, readout-v3",
             "Example Union, low-chroma trio. Cuts are now because 101.8% is the shared-world overage.", s62, False),
        ],
    },
]


def render_card(spec):
    num, name, dominant, register, sheets, honest, fn, both = spec
    dk = fn("dk")
    frames = pair(dk, fn("lt") if both else None)
    extra = ""
    if num == 46:
        extra = "Bracket is a GUIDE composition of postseason shape. It is not claimed as the Week 9 regular-season state."
    if num in (34, 35, 36, 37, 38, 39, 40, 55, 62):
        extra = "Pro / promotion surfaces are a labelled second moment (Example Union, low-chroma trio), not the Week 9 college desk."
    return card(num, name, dominant, register, sheets, honest, frames, extra)


def write_groups():
    for g in GROUPS:
        cards_html = "\n".join(render_card(c) for c in g["cards"])
        html = page(g["title"], g["kicker"], g["intro"], cards_html)
        (OUT / g["file"]).write_text(html, encoding="utf-8")
        print("wrote", g["file"])


def write_index():
    rows = []
    for g in GROUPS:
        rows.append(f'<h2 style="margin-top:22px">{g["title"].split("—")[0].strip()}</h2>')
        rows.append('<p class="small"><a href="' + g["file"] + '">Open this group</a></p>')
        rows.append('<table style="width:100%;border-collapse:collapse;font-size:12px;margin:8px 0 16px">')
        rows.append('<thead><tr><th style="text-align:left;border-bottom:1px solid #D8DADF;padding:6px">#</th><th style="text-align:left;border-bottom:1px solid #D8DADF;padding:6px">Family</th><th style="text-align:left;border-bottom:1px solid #D8DADF;padding:6px">Dominant object</th><th style="text-align:left;border-bottom:1px solid #D8DADF;padding:6px">Register</th></tr></thead><tbody>')
        for c in g["cards"]:
            rows.append(
                f'<tr><td class="mono" style="padding:6px;border-bottom:1px solid #D8DADF">{c[0]}</td>'
                f'<td style="padding:6px;border-bottom:1px solid #D8DADF"><a href="{g["file"]}#s{c[0]}">{c[1]}</a></td>'
                f'<td style="padding:6px;border-bottom:1px solid #D8DADF;color:#5A5F6A">{c[2]}</td>'
                f'<td style="padding:6px;border-bottom:1px solid #D8DADF;color:#5A5F6A">{c[3]}</td></tr>'
            )
        rows.append("</tbody></table>")
    intro = """<p style="margin-top:10px">Landscape iPhone mockups of every <span class="mono">04</span> §8 family, composed from the eight owner-approved <span class="mono">*-v3.dc.html</span> sheets. Install-floor frames are <b>844 × 390</b>. Dark appearance is the desk default. The proof-gate trio (Coaching HQ, Recruiting Board, Match Day) also renders light.</p>
<p>These files are <b>not canon</b> and are <b>not</b> a ninth design-reference sheet. <span class="mono">docs/04-UX-AND-DESIGN-SYSTEM.md</span> owns every value. They must not sit at repository root as <span class="mono">*-v3.dc.html</span> — <span class="mono">DesignContractTests.designSheets()</span> asserts exactly eight of those.</p>
<p>Shared world: Week 9, preparation day, Example State 6-2, next Example Coastal (away), Coach Sample, Coordinator Sample, Player Fourteen–Fifty-Four. Pro surfaces use Example Union and the shared-world cap meter as a labelled second moment. All names pending generator output.</p>
<div class="toc">""" + "".join(
        f'<a href="{g["file"]}">{g["title"].split("—")[0].strip()}</a>' for g in GROUPS
    ) + "</div>"
    html = page(
        "Screen mockups — 62 families",
        "docs/proofs/screen-mockups · 2026-08-13 · not canon",
        intro,
        "".join(rows),
        index_href="index.html",
    )
    (OUT / "index.html").write_text(html, encoding="utf-8")
    print("wrote index.html")


if __name__ == "__main__":
    write_groups()
    write_index()
