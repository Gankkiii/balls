#!/usr/bin/env python3
"""R04 selected left/right UI concept review. Not game code or an integration package.
Frozen actual-simulation state and R04 selected original images, no old candidate boards.
"""
from pathlib import Path
from html import escape
import json,math,base64,subprocess,hashlib
from PIL import Image
R=Path(__file__).resolve().parents[1]
(R/'images').mkdir(parents=True,exist_ok=True)
INK='#243746';PAPER='#FFF7E4';CREAM='#F7EBCD';WOOD='#D9BA8C';BLUE='#67AFC9';GOLD='#EFC65B';PURPLE='#B89ACF';CORAL='#E77D65';MINT='#8FBDB1'
PRIMARY=json.loads((R/'data/shared_sample.json').read_text());STRESS=json.loads((R/'data/stress_sample.json').read_text());BLINK=False
class Page:
 def __init__(self):self.svg=[];self.texts=[]
 def add(self,s):self.svg.append(s)
 def rect(self,x,y,w,h,c,opacity=1):self.add(f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" fill="{c}" opacity="{opacity:g}"/>')
 def line(self,x1,y1,x2,y2,c=INK,w=2,dash=None):self.add(f'<line x1="{x1:g}" y1="{y1:g}" x2="{x2:g}" y2="{y2:g}" stroke="{c}" stroke-width="{w:g}"'+(f' stroke-dasharray="{dash}"' if dash else '')+'/>')
 def circle(self,x,y,r,fill,stroke=None,width=2,opacity=1):self.add(f'<circle cx="{x:g}" cy="{y:g}" r="{r:g}" fill="{fill}" opacity="{opacity:g}"'+(f' stroke="{stroke}" stroke-width="{width:g}"' if stroke else '')+'/>')
 def poly(self,ps,fill,stroke=None,width=2,opacity=1):self.add('<polygon points="'+' '.join(f'{x:g},{y:g}' for x,y in ps)+f'" fill="{fill}" opacity="{opacity:g}"'+(f' stroke="{stroke}" stroke-width="{width:g}"' if stroke else '')+'/>')
 def frame(self,x,y,w,h,fill=CREAM,edge=INK):
  self.poly([(x+4,y),(x+w-4,y),(x+w-4,y+4),(x+w,y+4),(x+w,y+h-4),(x+w-4,y+h-4),(x+w-4,y+h),(x+4,y+h),(x+4,y+h-4),(x,y+h-4),(x,y+4),(x+4,y+4)],edge)
  self.rect(x+3,y+4,w-6,h-8,fill);self.rect(x+4,y+4,w-8,2,PAPER);self.rect(x+4,y+h-6,w-8,2,WOOD)
 def text(self,value,x,y,size=18,color=INK,kind='hud',anchor='start'):
  self.add(f'<text id="hud_{len(self.texts)}" x="{x:g}" y="{y:g}" font-family="Noto Sans CJK SC, DejaVu Sans, sans-serif" font-size="{size:g}" fill="{color}" text-anchor="{anchor}">{escape(str(value))}</text>')
  if kind=='hud':self.texts.append({'value':str(value),'position':[x,y],'element_id':'hud_'+str(len(self.texts))})
 def image(self,name,x,y,w=None,h=None,flip=False):
  path=R/'assets'/name;im=Image.open(path);w=w or im.width;h=h or im.height;uri='data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode()
  self.add((f'<g transform="translate({x+w:g} {y:g}) scale(-1 1)">' if flip else '')+f'<image x="{0 if flip else x:g}" y="{0 if flip else y:g}" width="{w:g}" height="{h:g}" href="{uri}" style="image-rendering:pixelated"/>'+('</g>' if flip else ''))
 def save(self,name,caption):
  content=''.join(self.svg)
  svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="804" viewBox="0 0 1100 804"><title>{escape(caption)}</title><rect width="1100" height="24" fill="{CREAM}"/><text x="16" y="17" font-family="Noto Sans CJK SC, sans-serif" font-size="12" fill="{INK}">{escape(caption)}</text><g transform="translate(0 24)">{content}</g></svg>\n'
  dst=R/'images'/f'{name}.svg';dst.write_text(svg)
  subprocess.run(['inkscape',str(dst),'--export-type=png',f'--export-filename={dst.with_suffix(".png")}','--export-background-opacity=0'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  return {'image':'images/'+dst.with_suffix('.png').name,'svg':'images/'+dst.name,'default_text':{'strings':[x['value'] for x in self.texts],'non_whitespace_characters':sum(sum(not c.isspace() for c in x['value']) for x in self.texts),'count_method':'Exact rendered HUD strings in source, including numeric object levels; outside concept caption excluded; not OCR.','elements':self.texts}}

def glyph(p,kind,x,y,size=24,color=INK):
 # Distinct review glyphs; descriptions live in review text, not permanent labels.
 sc=size/24;p.add(f'<g transform="translate({x:g} {y:g}) scale({sc:g})">')
 if kind in ['heart','pause','speed','replay','new_seed','sound_on','roster','info']:
  p.image('icon_'+kind+'.png',0,0,24,24)
 elif kind=='bubble':
  for cx,cy,r in [(7,15,5),(16,8,5),(18,19,3)]:p.circle(cx,cy,r,'none',color,2)
 elif kind=='vacuum':
  p.circle(12,12,9,'none',color,2);p.poly([(0,9),(6,9),(6,5),(12,12),(6,19),(6,15),(0,15)],color)
 elif kind=='eight':
  for i in range(8):
   t=i*math.tau/8;p.circle(12+9*math.cos(t),12+9*math.sin(t),2,color)
 elif kind=='wall':
  p.rect(18,1,4,22,color);p.line(0,12,15,12,color,3);p.poly([(10,5),(17,12),(10,19)],color)
 elif kind=='wool':
  for cx,cy in [(7,11),(12,7),(17,11)]:p.circle(cx,cy,5,CREAM,color,1.5)
  p.line(12,15,12,22,color,2);p.poly([(8,19),(12,24),(16,19)],color)
 elif kind=='bolt':p.poly([(12,0),(21,0),(15,9),(23,9),(5,24),(9,14),(2,14)],color)
 elif kind=='shell':
  p.poly([(1,18),(3,10),(8,4),(16,4),(21,10),(23,18)],MINT,color,2);p.line(2,20,22,20,color,2)
 elif kind=='spin':
  p.circle(12,12,8,'none',color,2);p.poly([(16,0),(24,5),(15,8)],color)
 elif kind=='dummy':
  p.circle(12,6,4,GOLD,color,1.5);p.line(12,10,12,23,color,3);p.line(2,13,22,13,color,3)
 elif kind=='feather':
  p.poly([(3,23),(7,8),(16,1),(22,3),(20,11),(9,20)],PAPER,color,2);p.line(4,22,19,4,color,1.5)
 elif kind=='swap':
  p.line(1,7,21,7,color,2);p.poly([(17,3),(23,7),(17,11)],color);p.line(23,17,3,17,color,2);p.poly([(7,13),(1,17),(7,21)],color)
 p.add('</g>')

def num(v,dec=1):
 if dec==0:return str(math.ceil(v-1e-7))
 v=math.ceil(max(0,v)*10-1e-7)/10
 return f'{v:.1f}'

def worldxy(v):return 200+v[0],90+v[1]

def actor(p,name,pos,flip=False):
 x,y=worldxy(pos);p.image(name+('_blink.png' if name=='bubble_fish' and BLINK and PRIMARY['fish_ordinary_hp_decreased'] else '_selected.png'),x-48,y-56,96,96,flip)

def hp(p,x,y,width,health,maxhp,color):
 glyph(p,'heart',x,y-20,20);p.text(num(health,0),x+28,y-3,20)
 p.rect(x,y+7,width,9,WOOD);p.rect(x+2,y+9,(width-4)*min(1,max(0,health/maxhp)),5,color)

def skill(p,kind,x,y,cd,compact=False,color=BLUE):
 size=28 if compact else 56
 if compact:
  glyph(p,kind,x,y,20,color);p.text(num(cd),x+26,y+17,16)
 else:
  p.frame(x,y,size,size,PAPER);glyph(p,kind,x+14,y+9,28,color)
  ratio=min(1,max(0,cd/{'vacuum':7,'eight':9,'wall':5,'wool':7,'shell':9,'spin':8,'swap':7,'feather':6}[kind]))
  if ratio:p.rect(x+4,y+4,size-8,(size-8)*ratio,INK,0.24)
  if cd>0:p.text(num(cd),x+size/2,y+size+19,16,anchor='middle')
  else:p.rect(x+4,y+size-8,size-8,3,MINT)

def controls(p,scheme):
 if scheme=='B':start=320;step=52;size=44;p.frame(308,706,484,58,WOOD)
 else:start=488;step=None;size=48;p.frame(480,706,600,58,WOOD)
 specs=[('pause',None),('speed','1×'),('speed','2×'),('speed','3×'),('replay',None),('new_seed',None),('sound_on',None),('roster',None),('info',None)]
 offsets=[0,56,112,168,236,292,360,416,480]
 for i,(icon,label) in enumerate(specs):
  x=start+(i*step if step else offsets[i]);p.frame(x,711,size,size,PAPER);icon_size=20 if label else 24
  p.image('icon_'+icon+'.png',x+(size-icon_size)/2,715 if label else 723,icon_size,icon_size)
  if label:p.text(label,x+size/2,746 if scheme=='B' else 748,12,anchor='middle')

def floor(p):
 p.image('screen_surround.png',0,0,1100,780);p.image('arena_floor.png',200,90,700,600);p.image('arena_wood_frame.png',190,80,720,620)

def stats(s,stress):
 if not stress:return [dict(name='bubble_fish',actor=s['fish'],resource_kind='bubble',resource=str(len(s['bubbles'])),skills=['vacuum','eight'],color=BLUE),dict(name='electric_sheep',actor=s['sheep'],resource_kind='bolt',resource=num(s['charge']),skills=['wall','wool'],color=GOLD)]
 return [dict(name='shell_turtle',actor=s['turtle'],resource_kind='shell',resource=num(s['turtle_action_left']),skills=['shell','spin'],color=MINT),dict(name='crow',actor=s['crow'],resource_kind='dummy',resource=str(len(s['dummies'])),skills=['swap','feather'],color=PURPLE)]

def sidebars(p,s,stress):
 for i,a in enumerate(stats(s,stress)):
  x=10 if i==0 else 930;p.frame(x,90,160,600);p.image(a['name']+'_selected.png',x+56,110,48,48)
  hp(p,x+14,215,132,a['actor']['health'],a['actor']['max_health'],a['color'])
  glyph(p,a['resource_kind'],x+14,279,28,a['color']);p.text(a['resource'],x+54,303,22)
  if not stress and i==1:p.rect(x+14,322,132,5,WOOD);p.rect(x+14,322,132*s['charge']/100,5,GOLD)
  if stress and i==1 and s['feather']:glyph(p,'feather',x+18,330,24)
  skill(p,a['skills'][0],x+12,420,a['actor']['cd_one'],color=a['color']);skill(p,a['skills'][1],x+88,420,a['actor']['cd_two'],color=a['color'])
def blend_color(a,b,t):
 aa=[int(a[i:i+2],16) for i in (1,3,5)];bb=[int(b[i:i+2],16) for i in (1,3,5)]
 return '#'+''.join(f'{round(x+(y-x)*t):02x}' for x,y in zip(aa,bb))
def world(p,s,stress):
 if not stress:
  if s['wool_active']:
   x,y=worldxy(s['wool_position']);p.image('object_wool.png',x-48,y-56,96,96)
  for b in s['bubbles']:
   x,y=worldxy(b['position']);t=math.exp(-0.19*math.log2(max(1,b['level'])))
   light=(158,205,214);deep=(10,44,61);rim='#'+''.join(f'{round(d+(l-d)*t):02x}' for l,d in zip(light,deep))
   # One thickened rim only, all exact level numbers retained including level1.
   p.circle(x,y,b['radius'],'none',rim,2 if b['level']==1 else 4,1);p.text(str(b['level']),x,y+5,13,anchor='middle')
  if s['zapping']:
   x1,y1=worldxy(s['sheep']['position']);x2,y2=worldxy(s['fish']['position'])
   p.line(x1,y1,(x1+x2)/2+8,(y1+y2)/2-4,GOLD,3);p.line((x1+x2)/2+8,(y1+y2)/2-4,x2,y2,GOLD,3)
  actor(p,'bubble_fish',s['fish']['position']);actor(p,'electric_sheep',s['sheep']['position'],True)
 else:
  for dummy in s['dummies']:
   x,y=worldxy(dummy['position']);p.image('object_dummy.png',x-48,y-56,96,96);p.rect(x-22,y+30,44,5,WOOD);p.rect(x-21,y+31,42*dummy['health']/dummy['max_health'],3,CORAL)
  x,y=worldxy(s['shell_position']);p.image('object_shell.png',x-48,y-56,96,96)
  # No glow/spin ring. Hidden turtle body is actually absent.
  if not s['turtle_hidden']:actor(p,'shell_turtle',s['turtle']['position'])
  actor(p,'crow',s['crow']['position'],True)
  if s['feather']:
   x,y=worldxy(s['crow']['position']);glyph(p,'feather',x-9,y-55,18)
def draw(name,stress=False,blink=False):
 global BLINK
 BLINK=blink;s=STRESS if stress else PRIMARY;p=Page();floor(p);world(p,s,stress);sidebars(p,s,stress);controls(p,'A')
 meta=p.save(name,'概念预览');return meta
primary=draw('primary');stress=draw('stress',True);blink=draw('primary_blink',False,True)
frames=[Image.open(R/primary['image']).convert('RGB'),Image.open(R/blink['image']).convert('RGB'),Image.open(R/primary['image']).convert('RGB')]
frames[0].save(R/'images/primary_feedback.gif',save_all=True,append_images=frames[1:],duration=[240,120,480],loop=0,disposal=2,optimize=False)
assert PRIMARY['fish_ordinary_hp_decreased'] and PRIMARY['fish_hp_before_step']>PRIMARY['fish']['health']
review={
 'cycle':'R04','version':'R04-selected-ui-1','selected':True,'layout':'A_left_right_light_minimal','label':'随机对战','status':'已选布局的概念复核；非游戏实录/接入包',
 'image':primary['image'],'animation':'images/primary_feedback.gif','primary':primary,'stress':stress,
 'media':[{'id':'primary','title':'随机对战','image':primary['image'],'animation':'images/primary_feedback.gif'},{'id':'stress','title':'多物件','image':stress['image']}],
 'details':{
  'game_canvas':[1100,780],'review_image':[1100,804],'outside_caption_height':24,'caption_only':'概念预览',
  'world_rect':[200,90,700,600],'physics_changed':False,'old_ui_changed':False,
  'primary_state':'同一真实样例：seed3103指定合法鱼羊组合，5.258秒；鱼110HP、羊120HP、11泡泡/最大3级、17.5电/一羊毛/实际放电。非声称此seed随机抽到这对。',
  'stress_state':'seed3108指定龟鸦组合，7.008秒；龟hidden仅显独立A壳、2个B拼布草人、乌鸦有储羽。无壳外发光圈。',
  'shape':'仅R04已选：鱼A，羊A且两短腿，龟A，乌鸦B。前4取selected.png，后4取selected_sprite.png，不裁展示图。',
  'palette':'与R04角色岗完全同一映射：t=exp(-0.19*log2(level))；浅RGB(158,205,214)至深RGB(10,44,61)逐通道round渐近；不在特定level截断。','numbers':'保留所有泡泡等级数字，包括1；每泡泡1级浅色2px单圈、融合等级4px单圈；随level加深、没有等级封顶。故主图41个非空白字符，其中大量是必要等级数字，无长说明。',
  'hurt':'动图只演示本次实际HP下降110.1667→110之后的普通受击眨眼。循环是这一次反馈的概念回放，不增加伤害、不表示角色自行持续眨眼。吸收/隐藏/保护不套普通伤害眨眼。',
  'position_assumption':'96图用(48,56)作概念挂位假设，不是8角色已验Godot接入锚点。',
  'retained_controls':'暂停、1×2×3×、重看、新随机、声音、全部角色、信息。每人2技能仅自动状态CD，非点击施法。main有10角色随机池；当前showcase固定鸭兔，未被本轮改动。',
  'limits':'无游戏改动/接入包；动态事件绑定、真机、性能与听感未由此静态图证明。声音另行重做待试听；本UI动图无声，不引用旧R03音频。'
 },
 'source_state':['data/shared_sample.json','data/stress_sample.json','data/capture.log'],
 'sources':['source/build_selected_ui.py','source/capture_state.gd','data/asset_sources.json'],
 'baseline_commit':'3134f2b8dd0fe250b01e1e7d3c829da5c54aaa47',
 'default_hud_characters':primary['default_text']['non_whitespace_characters'],
 'awaiting':['本轮动图表现复核；新音频在各角色页试听确认'],
 'not_reopened':['左右布局','浅色场地','鸭兔既有设计']
}
(R/'review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n')
print('R04 selected UI built:primary+stress+blink concept GIF;one selected layout;HUD chars',review['default_hud_characters'])

palette={}
for level in [1,2,3,4,8,16,32,64,128,1024]:
 t=math.exp(-0.19*math.log2(level));palette[str(level)]=[round(d+(l-d)*t) for l,d in zip((158,205,214),(10,44,61))]
(R/'data/bubble_palette.json').write_text(json.dumps({'function':'round(deep+(light-deep)*exp(-0.19*log2(level)))','light':[158,205,214],'deep':[10,44,61],'source':'R04 source/build_selected_front.py bubble()','levels':palette,'no_level_cap':True},ensure_ascii=False,indent=2)+'\n')
