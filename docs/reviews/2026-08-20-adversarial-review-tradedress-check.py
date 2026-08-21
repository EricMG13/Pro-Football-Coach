import json,math
def lin(c):
    c=c/255.0
    return c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4
def curve(t): return t**(1/3) if t>0.00885645 else (t*903.2963+16)/116
def lab(h):
    h=h.lstrip('#')
    if len(h)!=6: h='000000'
    v=int(h,16); r,g,b=(v>>16)&255,(v>>8)&255,v&255
    R,G,B=lin(r),lin(g),lin(b)
    x=0.4124564*R+0.3575761*G+0.1804375*B
    y=0.2126729*R+0.7151522*G+0.0721750*B
    z=0.0193339*R+0.1191920*G+0.9503041*B
    fx,fy,fz=curve(x/0.950489),curve(y/1.0),curve(z/1.088840)
    return (116*fy-16, 500*(fx-fy), 200*(fy-fz))
def dE(h1,h2):
    a,b=lab(h1),lab(h2)
    return math.dist(a,b)
NFL={"Seahawks":("002244","69BE28"),"Rams":("003594","FFA300"),"Panthers":("0085CA","101820"),
"Ravens":("241773","000000"),"Raiders":("000000","A5ACAF"),"Chiefs":("E31837","FFB81C"),
"Bills":("00338D","C60C30"),"Packers":("203731","FFB612"),"Cowboys":("003594","869397"),
"Steelers":("FFB612","101820"),"Patriots":("002244","C60C30"),"49ers":("AA0000","B3995D"),
"Bengals":("FB4F14","000000"),"Dolphins":("008E97","FC4C02"),"Vikings":("4F2683","FFC62F"),
"Bears":("0B162A","C83803"),"Broncos":("FB4F14","002244"),"Eagles":("004C54","A5ACAF"),
"Giants":("0B2265","A71930"),"Jets":("125740","FFFFFF"),"Saints":("D3BC8D","101820"),
"Buccaneers":("D50A0A","FF7900"),"Titans":("0C2340","4B92DB"),"Colts":("002C5F","A2AAAD"),
"Jaguars":("101820","D7A22A"),"Texans":("03202F","A71930"),"Browns":("311D00","FF3C00"),
"Lions":("0076B6","B0B7BC"),"Falcons":("A71930","000000"),"Cardinals":("97233F","000000"),
"Chargers":("0080C6","FFC20E"),"Commanders":("5A1414","FFB612")}
T=25.0
d=json.load(open('/Users/ericguei/Documents/Pro-Football-Coach/Tools/TeamLogos/manifest.json'))
hits=[]
for t in d['teams']:
    p,s=t['primaryColorHex'],t['secondaryColorHex']
    for nm,(np_,ns) in NFL.items():
        straight = dE(p,np_)<T and dE(s,ns)<T
        swapped  = dE(p,ns)<T and dE(s,np_)<T
        if straight or swapped:
            hits.append((t['name'],p,s,nm,np_,ns,round(min(dE(p,np_),dE(p,ns)),1),round(min(dE(s,ns),dE(s,np_)),1)))
print("manifest identities within deltaE 25 of an NFL pair:",len(hits))
for h in hits: print("  %-38s %s/%s  ~  %-11s %s/%s   dE %.1f/%.1f"%h)
