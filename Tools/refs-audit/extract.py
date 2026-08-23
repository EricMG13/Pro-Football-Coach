"""One-time: lift the 59 frames + gaps out of the prior artifact into data.json.
The prior generator enforced palette closure (0 literal hexes in body), so the
frame HTML is token-only and survives a token amendment unchanged."""
import re, json, html, sys

SRC = sys.argv[1]
s = open(SRC, encoding="utf-8", errors="replace").read()
marks = re.findall(r'data:image/png;base64,[A-Za-z0-9+/=]+', s)
mark = marks[0] if marks else ""

fams = [(m.start(), html.unescape(m.group(1))) for m in re.finditer(r'<section><h2>([^<]+)</h2>', s)]
def fam_of(p):
    f = "?"
    for pos, n in fams:
        if pos < p: f = n
        else: break
    return f

out = []
for m in re.finditer(r'<section class="entry" id="s-([A-Za-z]+)">(.*?)(?=<section class="entry"|<section><h2>|\Z)', s, re.S):
    sid, blk = m.group(1), m.group(2)
    h3 = re.search(r'<h3>(\d+)\.\s*([^<]+)</h3>', blk)
    fr = re.search(r'(<div class="fl-frame".*?)(?=</div>\s*</div>\s*(?:<details|</section>))', blk, re.S)
    if not (h3 and fr): continue
    frame = fr.group(1)
    head = frame[:frame.find(">") + 1]
    attrs = dict(re.findall(r'data-([a-z-]+)="([^"]*)"', head))
    gaps = []
    for g in re.finditer(r'<li><span class="badge">([A-Z]+)</span>\s*(.*?)</li>', blk, re.S):
        t = html.unescape(re.sub(r'<[^>]+>', '', g.group(2)))
        gaps.append({"kind": g.group(1), "blocks": 'class="blocks"' in g.group(2),
                     "text": re.sub(r'\s+', ' ', t).replace(" blocks", "").strip()})
    out.append({"id": sid, "number": int(h3.group(1)), "name": html.unescape(h3.group(2)).strip(),
                "family": fam_of(m.start()),
                "register": attrs.get("register", "").replace("Register.", ""),
                "status": attrs.get("status", ""),
                "cells": int(attrs.get("cells") or 0),
                "commit": 'class="fl-commit"' in frame,
                "gaps": gaps, "html": frame})
json.dump({"mark": mark, "surfaces": out}, open("data.json", "w"))
print(f"extracted {len(out)} surfaces, {sum(len(x['gaps']) for x in out) if out and 'gaps' in out[0] else 0} gaps")
