"""Regenerate the Floodlit Surface Register against amended canon (docs/04,
2026-08-22). Reads data.json + tokens.py, emits one self-contained page."""
import re, json, html, sys, tokens

SRC = "/Users/ericguei/.claude/projects/-Users-ericguei-Documents-Pro-Football-Coach/db98ad53-0204-4b19-9425-4414b2e6b3de/tool-results/artifact-18336868-1787416490-50d4.html"
D = json.load(open("data.json")); S = D["surfaces"]; MARK = D["mark"]

# ---- CSS: keep the prior chrome/primitive rules, drop its :root token blocks --
raw = open(SRC, encoding="utf-8", errors="replace").read()
css = raw[raw.find("<style>") + 7: raw.rfind("</style>")]
css = re.sub(r':root\s*\{[^}]*\}', '', css)                 # every old token block
css = re.sub(r'@import url\([^)]*\);', '', css)

FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
 '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
 '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
 'family=Archivo+Narrow:wght@400;500;600;700&family=IBM+Plex+Mono:wght@400;500;600;700&display=swap">')

# type/space/geometry the stripped :root blocks used to carry
SCAFFOLD = """
:root{
 --font-display:"Archivo Narrow","SF Pro Condensed",system-ui,sans-serif;
 --font-figure:"IBM Plex Mono",ui-monospace,monospace; --font-body:var(--font-display);
 --size-hero:66px;--size-name:60px;--size-score:54px;--size-score-live:40px;--size-figure:34px;
 --size-screen:25px;--size-subject:22px;--size-title:20px;--size-clock:19px;--size-lead:17px;
 --size-panel:16px;--size-row:15px;--size-action:14px;--size-action-small:12px;--size-pill:10.5px;--size-flag:9px;
 --type-display:700 var(--size-title)/1.05 var(--font-display);
 --type-title:700 var(--size-lead)/1.15 var(--font-display);
 --type-headline:600 var(--size-row)/1.25 var(--font-display);
 --type-body:400 13px/1.45 var(--font-body);--type-callout:400 var(--size-action-small)/1.4 var(--font-body);
 --type-caption:400 11px/1.35 var(--font-body);
 --weight-regular:400;--weight-medium:500;--weight-semibold:600;--weight-bold:700;
 --track-label:.2em;--track-flag:.15em;--track-micro:.08em;--track-tight:-.02em;
 --gap-hair:2px;--gap-tight:3px;--gap-xxs:4px;--gap-xs:6px;--gap-sm:7px;--gap-sm-plus:8px;
 --gap-md:9px;--gap-md-plus:11px;--gap-lg:12px;--gap-lg-plus:14px;--gap-xl:18px;--gap-xxl:20px;
 --pad-panel:11px 15px;--pad-row:10px 12px;--pad-card:12px 13px;--pad-band:14px 16px;
 --track-row-dense:24px;--row-min-height:32px;--min-target:44px;
 --radius-panel:4px 22px 4px 22px;--radius-row:3px 14px 3px 14px;--radius-action:22px 22px 22px 5px;
 --radius-card:4px 18px 4px 18px;--radius-block:4px 20px 4px 20px;
 --floor-width:844px;--floor-height:390px;--sensor-housing:59px;--gutter:20px;
 --leading-inset:63px;--bottom-inset:25px;--top-inset:12px;
 --rail-leading:59px;--rail-width:44px;--rail-top:46px;--rail-gap:2px;
 --content-leading:115px;--content-top:46px;--content-width:709px;
 --header-top:3px;--header-primary-row:22px;--header-secondary-row:16px;
 --hairline:1px;--grain-opacity:.5;
 --rule-structural:rgba(122,138,158,.20);--rule-legible:rgba(122,138,158,.38);--rule-row:rgba(255,255,255,.14);
 --shadow-panel:0 18px 40px rgba(0,0,0,.62);
 --inset-panel:inset 0 1px 0 rgba(246,250,255,.09),inset 0 0 0 1px rgba(122,138,158,.26);
 --gold-field:linear-gradient(135deg,var(--fl-gold-light),var(--fl-gold) 52%,var(--fl-gold-deep));
 --glow-gold:0 2px 24px rgba(255,197,61,.42);
}
/* 6.1d The identity band — encloses the WHOLE navigation row. */
.fl-band{position:absolute;top:var(--header-top);left:var(--leading-inset);right:var(--gutter);
 height:var(--band-height);display:flex;align-items:center;gap:var(--gap-md);padding:0 var(--gap-lg) 0 var(--gap-xxs);
 border-radius:var(--radius-row);
 background:linear-gradient(90deg,var(--fl-club-field),var(--world-page) 78%);
 box-shadow:inset 0 0 0 1px var(--rule-legible);overflow:hidden}
.fl-band__mark{width:19px;height:19px;object-fit:contain;flex:none}
.fl-band__club{font:var(--weight-bold) var(--size-action)/1.1 var(--font-display);color:var(--fl-club-ink);white-space:nowrap}
.fl-band__tier{font:var(--weight-bold) var(--size-flag)/1.1 var(--font-display);letter-spacing:var(--track-label);text-transform:uppercase}
.fl-band__div{width:1px;height:16px;background:var(--rule-legible);flex:none}
.fl-band__tabs{display:flex;gap:var(--gap-md);overflow:hidden;min-width:0}
/* 6.4 five heat bands */
.heat-well-below{color:var(--heat-well-below)}.heat-below{color:var(--heat-below)}
.heat-average{color:var(--heat-average)}.heat-above{color:var(--heat-above)}
.heat-well-above{color:var(--heat-well-above)}
.fl-legend{display:flex;gap:1px;margin-top:var(--gap-sm);border-radius:var(--radius-row);overflow:hidden}
.fl-legend div{flex:1;padding:3px 6px;background:var(--surface-panel)}
.fl-legend b{display:block;font:var(--weight-bold) 8px/1.1 var(--font-display);letter-spacing:var(--track-micro);text-transform:uppercase}
.fl-legend span{font-family:var(--font-figure);font-size:8.5px;color:var(--content-quiet)}
"""

# ---- 6.1d: header + rail -> one enclosing band -------------------------------
TIER = lambda s: "pro" if s["family"].lower().startswith("pro") else "college"
def band(s):
    tabs = re.findall(r'<span class="fl-tab([^"]*)">([^<]*)</span>', s["html"])
    t = "".join(f'<span class="fl-tab{c}">{html.escape(n)}</span>' for c, n in tabs)
    return (f'<div class="fl-band"><img class="fl-band__mark" src="{MARK}" alt="">'
            f'<span class="fl-band__club">Union Maritime Meridian Ironsides</span>'
            f'<span class="fl-band__tier fl-header__tier--{TIER(s)}">{TIER(s).title()}</span>'
            f'<span class="fl-band__div"></span>'
            f'<span class="fl-label3">{html.escape(s["family"])}</span>'
            f'<span class="fl-band__div"></span><div class="fl-band__tabs">{t}</div></div>')

def frame(s):
    h = s["html"]
    h = re.sub(r'<header class="fl-header">.*?</header>', band(s), h, flags=re.S)
    h = re.sub(r'<nav class="fl-rail">.*?</nav>', '', h, flags=re.S)
    h = h.replace('left: var(--content-leading)', 'left: var(--leading-inset)')
    h = re.sub(r'--content-leading', '--leading-inset', h)
    h = h.replace('data-register="Register.', 'data-register="')
    return h

# ---- page --------------------------------------------------------------------
BADGE = lambda k, t: f'<span class="badge badge--{k}">{t}</span>'
def entry(s):
    g = "".join(f'<li><span class="badge">{x["kind"]}</span> {html.escape(x["text"])}'
                + ('<span class="blocks">blocks</span>' if x["blocks"] else '') + '</li>' for x in s["gaps"])
    det = (f'<details><summary>Not produced — {len(s["gaps"])}</summary><ul>{g}</ul></details>') if g else ""
    return (f'<section class="entry" id="s-{s["id"]}"><div class="entry__head">'
            f'<h3>{s["number"]}. {html.escape(s["name"])}</h3>{BADGE(s["status"], s["status"])}'
            f'{BADGE("LEAN", s["register"])}<span class="badge">{s["cells"]} cells</span></div>'
            f'<div class="scroller">{frame(s)}</div>{det}</section>')

order, seen = [], set()
for s in S:
    if s["family"] not in seen: seen.add(s["family"]); order.append(s["family"])
body = ""
for f in order:
    body += f'<section><h2>{html.escape(f)}</h2>' + "".join(entry(s) for s in S if s["family"] == f) + '</section>'

from collections import Counter
st = Counter(x["status"] for x in S); ln = Counter(x["register"] for x in S)
kinds = Counter(g["kind"] for x in S for g in x["gaps"])
blk = Counter(g["kind"] for x in S for g in x["gaps"] if g["blocks"])
roll = "".join(f'<tr><th>{k}</th><td>{v}</td></tr>' for k, v in st.items())
roll += "".join(f'<tr><th>lean {k}</th><td>{v}</td></tr>' for k, v in ln.items())
gap = "".join(f'<tr><th>{k}</th><td>{v} declared, <span class="blocks">{blk[k]} blocking</span></td></tr>'
              for k, v in kinds.most_common())
idx = "".join(f'<a href="#s-{s["id"]}">{s["number"]}. {html.escape(s["name"])}</a>' for s in S)

out = (f'<title>Floodlit Surface Register</title>{FONTS}<style>{tokens.emit_css()}{SCAFFOLD}{css}</style>'
 f'<div class="doc"><h1>Floodlit Surface Register</h1>'
 f'<p class="lede">Every surface in the Coach World registry, drawn at the install floor of 844&times;390, '
 f'with what is not built declared beneath it. Regenerated against the 2026-08-22 amendments to '
 f'<code>docs/04</code>: the presentation lean (&sect;2.1), the measured budget (&sect;4.5a), gold as the '
 f'committing action alone (&sect;6.1a(ii)), the identity band (&sect;6.1d) and five heat bands (&sect;6.4). '
 f'Generated; do not hand-edit.</p>'
 f'<div class="index">{idx}</div>'
 f'<section><h2>Build state</h2><table class="rollup"><tr><th>Surfaces</th><td>{len(S)}</td></tr>{roll}</table></section>'
 f'<section><h2>Not produced</h2><table class="rollup">{gap}</table></section>'
 f'{body}</div>')
open("surface-register.html", "w", encoding="utf-8").write(out)
print(f"built surface-register.html  {len(out)/1048576:.2f} MB  {len(S)} surfaces")
