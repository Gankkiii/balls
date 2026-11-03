#!/usr/bin/env python3
"""Compose new deliverable assets for review. 1100x780 game canvas +48px outside caption.
No game code or original asset geometry is changed. Not a game screenshot.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
R=Path(__file__).resolve().parents[1];S=R.parent
(R/'preview').mkdir(parents=True,exist_ok=True)
F='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def font(size):return ImageFont.truetype(F,size)
def pic(name):return Image.open(R/'png'/f'{name}.png').convert('RGBA')
def nine(name,size,margins):
 src=pic(name);w,h=src.size;W,H=size;l,t,r,b=margins
 out=Image.new('RGBA',size)
 xs=[0,l,w-r,w];ys=[0,t,h-b,h];Xs=[0,l,W-r,W];Ys=[0,t,H-b,H]
 for j in range(3):
  for i in range(3):
   tile=src.crop((xs[i],ys[j],xs[i+1],ys[j+1]))
   if tile.width and tile.height:out.alpha_composite(tile.resize((Xs[i+1]-Xs[i],Ys[j+1]-Ys[j]),Image.Resampling.NEAREST),(Xs[i],Ys[j]))
 return out
visible=[]
def text(canvas,xy,value,size=18):
 ImageDraw.Draw(canvas).text(xy,value,font=font(size),fill='#243746')
 visible.append({'text':value,'at':list(xy),'font_size':size})
def captioned(canvas,caption):
 # Caption is outside the original game canvas. It never counts as gameplay HUD text.
 result=Image.new('RGBA',(1100,828),'#243746')
 ImageDraw.Draw(result).text((16,14),caption,font=font(15),fill='#FFF7E4')
 result.alpha_composite(canvas,(0,48));return result
out=Image.new('RGBA',(1100,780),'#E8DDC2')
for path,at in [('screen_surround.png',(0,0)),('arena_floor.png',(200,90)),('arena_wood_frame.png',(190,80))]:
 p=S/'environment'/path
 assert p.exists(),f'Preview requires sibling environment asset: {p.name}'
 out.alpha_composite(Image.open(p).convert('RGBA'),at)
for side,x,c,health,icons,stateicon,value in [('left',10,'gold','88',['timer','rod'],'cloud','2.4'),('right',930,'purple','104',['forge','temper'],'stored_damage','48')]:
 out.alpha_composite(nine('status_panel',(160,600),(12,16,12,12)),(x,90))
 char=S/'characters'/('duck' if side=='left' else 'rabbit')/'default.png'
 assert char.exists(),'Preview requires sibling characters source exports'
 avatar=Image.open(char).convert('RGBA').resize((48,48),Image.Resampling.NEAREST)
 out.alpha_composite(avatar,(x+56,116))
 out.alpha_composite(pic('icon_heart'),(x+16,190));text(out,(x+52,190),health,22)
 out.alpha_composite(nine('hp_track',(136,20),(4,4,4,4)),(x+12,226))
 fill=pic('hp_fill_'+c).resize((128,10),Image.Resampling.NEAREST)
 frac=88/120 if side=='left' else 104/120
 out.alpha_composite(fill.crop((0,0,int(128*frac),10)),(x+16,231))
 out.alpha_composite(nine('hp_frame',(136,20),(4,4,4,4)),(x+12,226))
 out.alpha_composite(pic('icon_status_'+stateicon),(x+12,274));text(out,(x+52,275),value,22)
 if side=='left':
  # Two rod icons encode current stock1/2 without a permanent text label.
  out.alpha_composite(pic('icon_skill_rod'),(x+20,322))
  ghost=pic('icon_skill_rod');ghost.putalpha(ghost.getchannel('A').point(lambda a:a//4))
  out.alpha_composite(ghost,(x+76,322))
 else:
  # Temper active is a distinct flame/blade icon plus ready border; no "1.5x" prose.
  out.alpha_composite(pic('icon_skill_temper'),(x+20,322))
 for j,icon in enumerate(icons):
  localx=12+72*j
  out.alpha_composite(pic('skill_slot_ready' if j==0 else 'skill_slot_normal'),(x+localx,414))
  out.alpha_composite(pic('icon_skill_'+icon),(x+localx+16,430))
  if j==0:
   out.alpha_composite(pic('badge_ready'),(x+localx+44,458))
  else:
   out.alpha_composite(pic('cooldown_overlay').crop((0,0,56,28)),(x+localx+4,418))
   text(out,(x+localx+13,490),'3.2',16)
empty_scene=out.copy()
for who,world,flip in [('duck',(190,300),False),('rabbit',(500,300),True)]:
 im=Image.open(S/'characters'/who/'default.png').convert('RGBA')
 if flip:im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
 out.alpha_composite(im,(200+world[0]-48,90+world[1]-56))
out.alpha_composite(nine('control_strip',(600,58),(12,12,12,12)),(480,706))
controls=[(8,'pause',None),(64,'speed','1×'),(120,'speed','2×'),(176,'speed','3×'),(244,'replay',None),(300,'new_seed',None),(368,'sound_on',None),(424,'roster',None),(488,'info',None)]
for x,icon,label in controls:
 out.alpha_composite(pic('button_normal'),(480+x,711))
 out.alpha_composite(pic('icon_'+icon),(480+x+12,723 if label is None else 714))
 if label:text(out,(480+x+14,739),label,12)
captioned(out,'R02 revised text-light HUD / sample state / composited assets, not live gameplay').save(R/'preview/layout_preview.png')
# Edge proof uses same unchanged UI geometry and actual actor frames.
edge_base=out.copy();edge_base.alpha_composite(empty_scene.crop((170,0,930,706)),(170,0))
frames=[]
for p in sorted((S/'characters/rabbit').rglob('frame_*.png')):
 im=Image.open(p).convert('RGBA');frames.append((p,im,im.getbbox()))
assert frames
wide=max(frames,key=lambda x:x[2][2]);top=min(frames,key=lambda x:x[2][1]);bottom=max(frames,key=lambda x:x[2][3])
for (p,im,bbox),world,flip in [(wide,(24,300),True),(wide,(676,300),False),(top,(350,24),False),(bottom,(350,576),False)]:
 art=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else im
 dx,dy=200+world[0]-48,90+world[1]-56;edge_base.alpha_composite(art,(dx,dy))
 bx=art.getbbox();ImageDraw.Draw(edge_base).rectangle((dx+bx[0],dy+bx[1],dx+bx[2]-1,dy+bx[3]-1),outline='#E77D65',width=1)
captioned(edge_base,'Static edge alpha-bound proof / unchanged physics / not live gameplay').save(R/'preview/edge_safety_preview.png')
# Actual drawn HUD strings are counted directly; no OCR and no outside caption.
old=['R02 / LEFT-RIGHT MINIMAL HUD','DUCK','88 / 120','2.4 s','Rod  1 / 2','READY','3.2 s','TIMER','ROD','AUTO SKILLS','RABBIT','104 / 120','48','Temper  1.5x','READY','3.2 s','FORGE','TEMPER','AUTO SKILLS','1x','2x','3x','Event text / real state','Seed / time']
def count(items):return sum(sum(not c.isspace() for c in s) for s in items)
new=[x['text'] for x in visible]
metrics={'scope':'Actual default HUD strings drawn by this preview source, excluding48px outside review caption and component labels; non-whitespace Unicode characters, not OCR. Example state only; live numeric lengths may differ.','game_canvas':[1100,780],'preview_image':[1100,828],'outside_caption_rect':[0,0,1100,48],'game_canvas_rect_in_preview':[0,48,1100,780],'previous_preview_default_strings':old,'previous_non_whitespace_characters':count(old),'current_drawn_strings':visible,'current_non_whitespace_characters':count(new),'reduction':count(old)-count(new),'status':'confirmed_delivery: user confirmed text-light handoff revision with22 sample default characters; not proof of live gameplay/device validation'}
(R/'UI_TEXT_METRICS.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n')
# Contact sheet is inspection-only, not the in-game UI or text-count target.
m=json.loads((R/'ui_manifest.json').read_text());files=[R/x['file'] for x in m['assets']]
board=Image.new('RGB',(880,((len(files)+7)//8)*120),'#E8DDC2');d=ImageDraw.Draw(board)
for i,p in enumerate(files):
 im=Image.open(p).convert('RGBA');im.thumbnail((96,72),Image.Resampling.NEAREST)
 x=(i%8)*110+(110-im.width)//2;y=(i//8)*120+6;board.paste(im,(x,y),im)
 label=p.stem.replace('cooldown','cd').replace('status_','st_').replace('skill_','sk_');d.text(((i%8)*110+3,(i//8)*120+86),label,fill='#243746')
board.save(R/'preview/component_contact_sheet.png')
print('Composed text-light HUD:',count(new),'characters vs',count(old),'prior. Review image1100x828; game canvas1100x780.')
