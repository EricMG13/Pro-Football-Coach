"""Rule checks over the registry + emitted HTML. Pure Python, no browser."""
import re, json, sys, tokens
D=json.load(open("data.json")); S=D["surfaces"]
H=open("surface-register.html",encoding="utf-8").read()
B=re.sub(r'data:image/png;base64,[A-Za-z0-9+/=]+','MARK',H)
fails=[]
def chk(n,ok,d=""):
    print(f"  {'PASS' if ok else 'FAIL'}  {n}" + (f"  -- {d}" if d and not ok else ""))
    if not ok: fails.append(n)

def L(h):
    h=h.lstrip('#'); c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    c=[v/12.92 if v<=.03928 else ((v+.055)/1.055)**2.4 for v in c]
    return .2126*c[0]+.7152*c[1]+.0722*c[2]
def R(a,b):
    l1,l2=sorted([L(a),L(b)],reverse=True); return (l1+.05)/(l2+.05)
def hue(h):
    import colorsys; h=h.lstrip('#')
    r,g,b=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return colorsys.rgb_to_hls(r,g,b)[0]*360

print("Floodlit Surface Register -- checks\n")
# 1 inventory
chk("1  inventory: 59 surfaces, unique ids and numbers",
    len(S)==59 and len({x['id'] for x in S})==59 and len({x['number'] for x in S})==59)
# 2 canon parity
canon=open("../../docs/04-UX-AND-DESIGN-SYSTEM.md",encoding="utf-8").read()
chk("2  canon amended (4 markers, 0 three-band rule)",
    canon.count("2026-08-22 amendment")==4 and "red below 70, amber from 70" not in canon)
# 3 gold once
bad=[(x['id'],n) for x in S if (n:=len(re.findall(r'--fl-gold\b',x['html'])))>(2 if x['register']=="MATCH_DAY" else 1)]
chk("3  gold used at most once per surface (2 on Match Day)",not bad,str(bad[:3]))
# 4 warning left the yellow band
d=min(abs(hue(tokens.WARNING)-hue(tokens.GOLD)),360-abs(hue(tokens.WARNING)-hue(tokens.GOLD)))
chk("4  state.warning >=24 deg from gold",d>=24,f"{d:.1f} deg")
chk("4b old #FFB03A absent from output","#FFB03A" not in B)
# 5 heat bands
ok=len(tokens.HEAT)==5
for n,lo,hi,v in tokens.HEAT:
    dd=min(abs(hue(v)-hue(tokens.GOLD)),360-abs(hue(v)-hue(tokens.GOLD)))
    if min(R(v,tokens.PAGE),R(v,tokens.RAISED),R(v,tokens.PANEL))<4.5 or dd<24: ok=False
chk("5  five heat bands, each >=4.5:1 on 3 grounds and >=24 deg from gold",ok)
chk("5b average band is neutral, not amber",dict((n,v) for n,_,_,v in tokens.HEAT)["average"]=="#A9BACE")
# 6 cell budgets
over=[(x['id'],x['cells'],tokens.CELLS[x['register']]) for x in S
      if x['cells']>tokens.CELLS.get(x['register'],72)]
chk("6  cell budget per lean",not over,str(over[:3]))
# 7 lean declared
chk("7  every surface declares a lean",all(x['register'] in tokens.CELLS for x in S))
# 8 identity band replaced header+rail
chk("8  identity band on every frame",B.count('class="fl-band"')==59)
chk("8b old header/rail gone",'class="fl-header">' not in B and 'class="fl-rail"' not in B)
# 9 alias closure -- no duplicate literal hex across roles
lits=[v for v in tokens.BASE.values()]
dup=[v for v in set(lits) if lits.count(v)>1]
chk("9  no duplicate literal hex across base tokens",not dup,str(dup))
# 10 palette closure in body.
#    Club colours are world data, not palette: 04 5.2 makes the mark and its pair a
#    per-programme fact, and 6.1a requires a team fill to carry its own hairline. They
#    are therefore passed as inline --club/--club-line and exempt. Everything else in
#    the body must reach colour through a token.
body=B[B.rfind("</style>"):]
CLUB=re.compile(r'--club(?:-line)?:\s*(#[0-9A-Fa-f]{6})')
clubvals={m.group(1) for m in CLUB.finditer(body)}
stray=[c for c in re.findall(r'#[0-9A-Fa-f]{6}\b|rgba?\([^)]*\)',CLUB.sub('',body))]
chk("10 palette closure: no literal colour in body except --club/--club-line",
    not stray, f"{len(stray)} stray, e.g. {stray[:3]}")
chk("10b every club colour arrives as --club/--club-line",
    all(c in clubvals for c in re.findall(r'#[0-9A-Fa-f]{6}\b',body)))
# 11 gaps declared
chk("11 every non-BUILT surface declares a gap",
    all(x['gaps'] for x in S if x['status']!="BUILT"))
# 12 self-contained
# The published page is wrapped in claude.ai's runtime; only content below <title> is ours.
own=B[B.find("<title>"):] if "<title>" in B else B
ext=[u for u in re.findall(r'https?://[^"\')\s]+',own) if "fonts.g" not in u]
chk("12 self-contained (fonts only)",not ext,str(ext[:2]))
# 13 banned vocabulary
chk("13 no TODO/lorem/placeholder",not re.search(r'\bTODO\b|lorem|placeholder',body,re.I))
print(f"\n{len(fails)} failure(s)" + ("" if not fails else ": "+", ".join(fails)))
sys.exit(1 if fails else 0)
