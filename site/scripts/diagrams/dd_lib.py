"""Diagram-design helpers for the astragentic site (profile: ~/.diagram-design/profiles/astragentic.md).

Type ramp is set against the rendered width: every diagram is drawn on an 800-unit-wide
viewBox, so 1 unit = 1 CSS px when the SVG renders 800 px wide (the docs column). Floors
from PRD section 5: 13 px node names, 10.5 px sublabels/tags/arrow labels/legend.
"""
import sys
INK="#14161A";MUT="#4D5056";SOFT="#5B5E63";RULE="rgba(20,22,26,0.10)";ACC="#C92D1F";TINT="#FBE9E6";PAPER="#FFFFFF"
SANS="'Inter Variable','Inter',system-ui,sans-serif";MONO="'JetBrains Mono Variable','JetBrains Mono',ui-monospace,monospace"
SERIF="'Source Serif 4 Variable','Source Serif 4',Georgia,serif"
W=800
FS_NAME=14; FS_SUB=11; FS_TAG=11; FS_LAB=11; FS_LEG=11   # units == px at 800 wide
CW_MONO=0.62; CW_SANS=0.62
def tw(s,fs,mono=False,ls=0): return len(s)*fs*((CW_MONO if mono else CW_SANS)+ls)
def g4(v): return int(-(-v//4)*4)
KINDS={'focal':(TINT,ACC,None),'backend':(PAPER,INK,None),'input':("rgba(77,80,86,0.10)",SOFT,None),
 'store':("rgba(20,22,26,0.05)",MUT,None),'optional':("rgba(20,22,26,0.02)","rgba(20,22,26,0.40)","4,3"),
 'security':("rgba(201,45,31,0.05)","rgba(201,45,31,0.50)","4,4")}
def tagw(t): return g4(tw(t,FS_TAG,True,0.06)+12)
class D:
    def __init__(s,slug,lang,title,desc,eyebrow):
        s.slug,s.lang,s.W,s.H,s.title,s.desc,s.eyebrow=slug,lang,W,0,title,desc,eyebrow
        s.zones=[];s.arr=[];s.lab=[];s.nodes=[];s.leg=[];s.kinds=[]
    def warn(s,m): print(f"WARN {s.slug}/{s.lang} {m}",file=sys.stderr)
    def zone(s,x,y,w,h,text=None,key=None,lx=12):
        o=(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{PAPER}"/>'
           f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="rgba(20,22,26,0.02)" stroke="rgba(20,22,26,0.10)" stroke-width="0.8"/>')
        if text:
            lw=g4(tw(text,FS_TAG,True,0.12)+12)
            o+=(f'<rect x="{x+lx}" y="{y+4}" width="{lw}" height="16" rx="2" fill="{PAPER}"/>'
                f'<text x="{x+lx+lw/2:g}" y="{y+16}" fill="{SOFT}" font-family="{MONO}" font-size="{FS_TAG}" text-anchor="middle" letter-spacing="0.12em">{text}</text>')
        s.zones.append(f'<g data-node="{key}">{o}</g>' if key else o)
    def path(s,pts,kind='mut',dash=False,start=False,end=True):
        r=8;d=f"M {pts[0][0]} {pts[0][1]}"
        for i in range(1,len(pts)):
            x0,y0=pts[i-1];x1,y1=pts[i]
            if i<len(pts)-1:
                x2,y2=pts[i+1]
                def un(ax,ay,bx,by):
                    dx,dy=bx-ax,by-ay;L=abs(dx)+abs(dy);return (dx/L,dy/L)
                ux,uy=un(x0,y0,x1,y1);vx,vy=un(x1,y1,x2,y2)
                d+=f" L {x1-ux*r:g} {y1-uy*r:g} Q {x1} {y1} {x1+vx*r:g} {y1+vy*r:g}"
            else: d+=f" L {x1} {y1}"
        col=ACC if kind=='acc' else MUT
        m='arrow-accent' if kind=='acc' else 'arrow'
        a=' stroke-dasharray="5,4"' if dash else ''
        ms=f' marker-start="url(#{m})"' if start else ''
        me=f' marker-end="url(#{m})"' if end else ''
        s.arr.append(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="1.2"{a}{ms}{me}/>')
    def label(s,cx,cy,t):
        w=g4(tw(t,FS_LAB,True,0.04)+12)
        s.lab.append(f'<rect x="{cx-w/2:g}" y="{cy-9}" width="{w}" height="18" fill="{PAPER}"/><text x="{cx:g}" y="{cy+4}" fill="{MUT}" font-family="{MONO}" font-size="{FS_LAB}" text-anchor="middle" letter-spacing="0.04em">{t}</text>')
        return w
    def lab_h(s,x1,x2,y,t):   # mask centred on a horizontal segment; must fit the gap
        w=s.label((x1+x2)/2,y,t)
        if w+16>abs(x2-x1): s.warn(f"label '{t}' {w}+16 > gap {abs(x2-x1)}")
    def lab_v(s,x,y1,y2,t):   # mask centred on a vertical segment
        w=s.label(x,(y1+y2)/2,t)
        if 24>abs(y2-y1): s.warn(f"label '{t}' vertical gap {abs(y2-y1)}")
    def node(s,key,x,y,w,h,kind,tag,name,sub):
        fill,stroke,dash=KINDS[kind]
        if kind not in s.kinds: s.kinds.append(kind)
        tc=ACC if kind=='focal' else MUT
        tgw=tagw(tag)
        lines=sub.split('\n')
        need=g4(tw(name,FS_NAME)+16)
        if tw(name,FS_NAME)+16>w: s.warn(f"name too wide: {name} {tw(name,FS_NAME)+16:.0f}>{w}")
        for l in lines:
            if tw(l,FS_SUB,True)+16>w: s.warn(f"sub too wide: {l} {tw(l,FS_SUB,True)+16:.0f}>{w}")
        if tgw+16>w: s.warn(f"tag too wide: {tag}")
        if 64+14*(len(lines)-1)+8>h: s.warn(f"node {name} too short: h={h}")
        d=f' stroke-dasharray="{dash}"' if dash else ''
        g=(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{PAPER}"/>'
          f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{fill}" stroke="{stroke}"{d}/>'
          f'<rect x="{x+8}" y="{y+8}" width="{tgw}" height="16" rx="2" fill="none" stroke="{tc}" opacity="0.55"/>'
          f'<text x="{x+8+tgw/2:g}" y="{y+20}" fill="{tc}" font-family="{MONO}" font-size="{FS_TAG}" text-anchor="middle" letter-spacing="0.06em">{tag}</text>'
          f'<text x="{x+w/2:g}" y="{y+46}" fill="{INK}" font-family="{SANS}" font-size="{FS_NAME}" font-weight="600" text-anchor="middle">{name}</text>')
        for i,l in enumerate(lines):
            g+=f'<text x="{x+w/2:g}" y="{y+64+14*i}" fill="{MUT}" font-family="{MONO}" font-size="{FS_SUB}" text-anchor="middle">{l}</text>'
        s.nodes.append(f'<g data-node="{key}">{g}</g>' if key else f'<g>{g}</g>')
    def band(s,y,tag,name,sub,key,x=24,w=752,h=96):
        tgw=tagw(tag)
        if tw(sub,FS_SUB,True)+16>200: s.warn(f"band sub too wide: {sub}")
        s.zones.append(f'<g data-node="{key}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{PAPER}"/>'
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="rgba(20,22,26,0.02)" stroke="rgba(20,22,26,0.10)" stroke-width="0.8"/>'
         f'<rect x="{x+16}" y="{y+16}" width="{tgw}" height="16" rx="2" fill="none" stroke="{SOFT}" opacity="0.55"/>'
         f'<text x="{x+16+tgw/2:g}" y="{y+28}" fill="{SOFT}" font-family="{MONO}" font-size="{FS_TAG}" text-anchor="middle" letter-spacing="0.06em">{tag}</text>'
         f'<text x="{x+16}" y="{y+56}" fill="{INK}" font-family="{SANS}" font-size="{FS_NAME}" font-weight="600">{name}</text>'
         f'<text x="{x+16}" y="{y+74}" fill="{MUT}" font-family="{MONO}" font-size="{FS_SUB}">{sub}</text></g>')
    def legend(s,items,y):
        s.H=y+14+24
        o=f'<line x1="24" y1="{y-20}" x2="{s.W-24}" y2="{y-20}" stroke="{RULE}"/>'
        lx=24
        for k,txt in items:
            f,st,d=KINDS[k];dd=f' stroke-dasharray="{d}"' if d else ''
            o+=f'<rect x="{lx}" y="{y}" width="16" height="14" rx="2" fill="{f}" stroke="{st}"{dd}/><text x="{lx+24}" y="{y+11}" fill="{MUT}" font-family="{MONO}" font-size="{FS_LEG}">{txt}</text>'
            lx+=g4(24+tw(txt,FS_LEG,True)+28)
        if lx-28>s.W-24: s.warn(f"legend too wide {lx}")
        s.leg.append(o)
    def html(s):
        sl=f"{s.slug}-{s.lang}"
        svg=(f'<svg viewBox="0 0 {s.W} {s.H}" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="{sl}-title {sl}-desc">'
         f'<title id="{sl}-title">{s.title}</title><desc id="{sl}-desc">{s.desc}</desc>'
         f'<rect width="{s.W}" height="{s.H}" fill="{PAPER}"/>'
         f'<defs><marker id="arrow" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto-start-reverse"><polygon points="0 0,8 3,0 6" fill="{MUT}"/></marker>'
         f'<marker id="arrow-accent" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto-start-reverse"><polygon points="0 0,8 3,0 6" fill="{ACC}"/></marker></defs>'
         +"\n".join(s.zones+s.arr+s.lab+s.nodes+s.leg)+'</svg>')
        return f'''<!DOCTYPE html><html lang="{s.lang}"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>{s.title}</title>
<style>*,*::before,*::after{{box-sizing:border-box;margin:0;padding:0}}body{{font-family:{SANS};background:{PAPER};color:{INK};padding:48px 32px}}.frame{{max-width:{s.W+64}px;margin:0 auto}}.eyebrow{{font-family:{MONO};font-size:11px;font-weight:600;letter-spacing:.18em;text-transform:uppercase;color:{MUT};margin-bottom:8px}}h1{{font-family:{SERIF};font-size:32px;font-weight:400;line-height:1.1;margin-bottom:24px}}.scroll{{overflow-x:auto}}svg{{width:100%;min-width:{s.W}px;display:block}}</style></head>
<body><div class="frame"><p class="eyebrow">{s.eyebrow}</p><h1>{s.title}</h1><div class="scroll">
{svg}
</div></div></body></html>'''
LEG={'en':{'focal':'focal','backend':'step','input':'actor','store':'state or store','optional':'optional','security':'refused · never a pass'},
     'vi':{'focal':'trọng tâm','backend':'bước','input':'tác nhân','store':'trạng thái hoặc kho','optional':'tùy chọn','security':'bị từ chối · không bao giờ là pass'}}
