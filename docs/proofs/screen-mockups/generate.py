"""Emit 04 §8 landscape screen mockups. Run from this directory: python3 generate.py"""
from __future__ import annotations

from pathlib import Path

from _common import (
    ACQUIRE,
    OFFICE,
    PERSONNEL,
    card,
    local_routes,
    page,
    pair,
    world_strip,
)

OUT = Path(__file__).resolve().parent


def rb(n):
    cls = "g" if n >= 85 else "a" if n >= 70 else "r"
    return f'<span class="rb {cls}">{n}</span>'


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




EXAMPLES = [
    (8, "Coaching HQ", "current week plan and next obligation", "Coach's Office",
     "chrome-v3, week-v3, readout-v3",
     "Three regions: identity rail, week plan + due decision, desk wire. Continue disabled while 2 obligations are due.",
     s8, True),
    (16, "Roster", "sortable legal team sheet", "Personnel Room",
     "table-v3, chrome-v3",
     "24–28 pt tracks, rating badges, status chips. Fit prints as a word. P51 remains suspended and legible.",
     s16, False),
    (18, "Player Profile", "role, story, form, confidence and history", "Personnel Room",
     "person-v3, readout-v3, table-v3",
     "Player Fourteen's shared-world numbers: 84 overall, Good fit, form 78/81/74/86/83, market as a band.",
     s18, False),
    (24, "Recruiting Board", "ranked live target board", "Acquisition Room",
     "table-v3, chrome-v3, readout-v3",
     "Hours remaining is a meter. Confidence is High/Med/Low, not an invented scouting novel.",
     s24, True),
    (14, "Match Day", "full field, score, current cause and call-ins", "Broadcast",
     "broadcast-v3, chrome-v3",
     "No world strip. Scorebug EXC 13–EXS 10, Q3 07:26, 1st and 10. Five primary controls. 22 actors. Route vectors not drawn (G-06).",
     s14, True),
]


def render_card(spec):
    num, name, dominant, register, sheets, honest, fn, both = spec
    frames = pair(fn("dk"), fn("lt") if both else None)
    return card(num, name, dominant, register, sheets, honest, frames)


def main():
    toc = (
        '<div class="toc">'
        + "".join(f'<a href="#s{c[0]}">{c[0]} {c[1]}</a>' for c in EXAMPLES)
        + "</div>"
    )
    intro = f"""<p style="margin-top:10px">Five first-example landscape mockups — the <span class="mono">04</span> §10 proof-gate trio plus the personnel pair already used as example proofs. Not the full 62-family inventory. Install-floor frames are <b>844 × 390</b>. Dark is the desk default; HQ, Recruiting Board and Match Day also render light.</p>
<p>These files are <b>not canon</b> and are <b>not</b> a ninth design-reference sheet. <span class="mono">docs/04-UX-AND-DESIGN-SYSTEM.md</span> owns every value.</p>
<p>Shared world: Week 9, preparation day, Example State 6-2, next Example Coastal (away), Coach Sample, Coordinator Sample, Player Fourteen–Fifty-Four. All names pending generator output.</p>
{toc}"""
    cards_html = "\n".join(render_card(c) for c in EXAMPLES)
    html = page(
        "Screen mockups — five first examples",
        "docs/proofs/screen-mockups · 2026-08-13 · not canon",
        intro,
        cards_html,
    )
    (OUT / "index.html").write_text(html, encoding="utf-8")
    print("wrote index.html")


if __name__ == "__main__":
    main()
