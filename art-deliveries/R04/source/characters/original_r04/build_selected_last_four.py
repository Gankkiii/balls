"""R04 selected visual review. Reuses accepted editable geometry, never screenshot/image inputs."""
from pathlib import Path
import argparse,json,math,hashlib
from PIL import Image,ImageDraw,ImageFont
from pixel_base import Art,cactus,turtle,shell,crab,crow,nail,dummy,feather,rgba,INK,CREAM,CORAL,METAL,GOLD,PURPLE,CYAN,LEAF,FONT

ROOT=None
def font(n):return ImageFont.truetype(FONT,n,index=2)
def label(im,xy,s,n=14):
 # R04 review is media-first: all labels belong to HTML, no text baked in media.
 return None
def place(im,a,x,y,scale=2):
 im.alpha_composite(a.image().resize((96*scale,96*scale),Image.Resampling.NEAREST),(int(x),int(y)))
def selected_cactus(blink=False,flower=False):
 a=cactus('a')
 a.ops=[o for o in a.ops if not(o[0]=='r' and o[1] in [[24,21,3,4],[24,21,1,1],[25,28,3,1]])]
 for x in [21,26]:
  a.box(x,22 if blink else 21,2,1 if blink else 3,INK)
  if not blink:a.box(x,21,1,1,CREAM)
 a.box(23,28,3,1,INK)
 if flower:
  a.box(21,6,3,5,'#FFE08A');a.box(18,8,9,2,'#FFD375');a.box(22,8,2,2,'#FFFBE4')
 return a
def thorn_object():
 a=Art();a.poly([(22,12),(31,35),(17,35)],INK);a.poly([(23,17),(28,32),(20,32)],'#E7C77D');a.box(23,22,2,10,CREAM);return a
def selected(id,blink=False,stored=False):
 if id=='cactus':return selected_cactus(blink)
 if id=='shell_turtle':return turtle('a','blink' if blink else 'idle')
 if id=='magnet_crab':
  a=crab('a')
  if blink:
   remove=[[15,15,5,5],[17,16,2,3],[28,15,5,5],[30,16,2,3]]
   a.ops=[o for o in a.ops if not(o[0]=='r' and o[1] in remove)]
   for x in [15,28]:a.box(x,15,5,5,CORAL);a.box(x,17,5,1,INK)
  return a
 return crow('b','blink' if blink else 'feather' if stored else 'idle')
def shell_pattern(i):
 # Rim and shell stay fixed. Only existing shell marking spokes change angle.
 a=shell('a');a.ops=[o for o in a.ops if o[0]!='l']
 for j in range(6):
  ang=j*math.tau/6+i*math.tau/12
  a.line([(24,24),(round(24+math.cos(ang)*12),round(24+math.sin(ang)*8))],'#427863',1)
 return a
def card():return Image.new('RGBA',(512,320),rgba(CREAM))
def scene():
 im=card();d=ImageDraw.Draw(im);d.rectangle((14,34,497,276),fill=rgba('#F0E4C7'),outline=rgba('#D2B58A'),width=2)
 return im
def main_image(id):
 im=card()
 if id in ['shell_turtle','crow']:
  place(im,selected(id),24,68,2);place(im,shell('a') if id=='shell_turtle' else dummy('b'),272,68,2)
  label(im,(70,38),'本体',16);label(im,(325,38),'独立壳' if id=='shell_turtle' else '拼布草人',16)
 else:place(im,selected(id),112,0,3)
 label(im,(20,288),{'cactus':'仙人掌 · 两个眼睛','shell_turtle':'脱壳乌龟','magnet_crab':'磁铁蟹','crow':'乌鸦'}[id],16)
 return im
def hurt(id,i):
 im=scene();place(im,selected(id,blink=i in [1,2,4]),160,48,2)
 label(im,(20,6),'普通受击 · 眨眼',16)
 label(im,(20,289),'仅实际掉血' if id!='shell_turtle' else '仅裸身掉血；隐藏／壳不演受伤',13)
 return im
def cactus_thorns(i):
 im=scene();d=ImageDraw.Draw(im);place(im,selected_cactus(),160,48,2)
 pts=[(88,222),(130,247),(390,240),(426,184),(383,91)]
 for x,y in pts if i>0 else []:
  d.polygon([(x,y-9),(x+5,y+4),(x-5,y+4)],fill=rgba('#E7C77D'),outline=rgba(INK))
  if i in [1,2,3]:
   # Short local landing glint, not a damage aura or a flying thorn.
   c=rgba('#FFFBE4' if i==2 else GOLD)
   d.line([(x-8,y+7),(x+8,y+7)],fill=c,width=2)
   d.line([(x-8,y-2),(x-11,y-5)],fill=c,width=2);d.line([(x+8,y-2),(x+11,y-5)],fill=c,width=2)
 label(im,(20,6),'落刺 · 短亮',16);return im
def cactus_regrow(i):
 im=scene();x=40 if i<6 else 282
 # Position changes once, only flower changes brightness at that real reposition moment.
 place(im,selected_cactus(flower=i in [6,7]),x,72,2)
 label(im,(20,6),'换位 · 仅花冠短亮',16);return im
def crab_nails(i):
 im=scene();d=ImageDraw.Draw(im);place(im,crab('a'),158,66,2)
 xs=[98,98,210,310,460,380,310,254,345,432,432,432]
 ys=[232,232,232,232,232,225,205,178,171,164,164,164]
 x,y=xs[i],ys[i];moving=2<=i<=9
 p=nail(moving).image().resize((48,48),Image.Resampling.NEAREST);im.alpha_composite(p,(x-24,y-24))
 if moving:
  dx=x-xs[i-1];dy=y-ys[i-1];norm=max(1,math.hypot(dx,dy))
  for j in range(3):
   t=13+j*7;tx=x-dx/norm*t;ty=y-dy/norm*t
   d.line([(tx,ty),(tx-dx/norm*5,ty-dy/norm*5)],fill=rgba(GOLD),width=2)
 d.line((480,72,480,255),fill=rgba('#D2B58A'),width=3)
 label(im,(20,6),'移动钉 · 短轨迹',16);label(im,(20,289),'静止无害，无危险拖尾',13);return im
def turtle_spin(i):
 im=scene();place(im,turtle('a'),34,99,1);place(im,shell_pattern(i),240,64,2)
 label(im,(20,6),'仅壳纹旋转',16);label(im,(20,289),'独立壳位置固定，无弧光／自动冲刺',13);return im
def turtle_hide(i):
 im=scene();place(im,shell('a'),234,74,2)
 # An illustrative approach then hidden body; no guaranteed exit timing shown.
 if i<6:place(im,turtle('a'),[20,65,110,155,200,236][i],104,1)
 label(im,(20,6),'寻壳 → 入壳',16);label(im,(20,289),'隐藏后只见壳；未演掉血或强制出壳',13);return im
def crow_swap(i):
 im=scene();d=ImageDraw.Draw(im);left,right=(50,350) if i<6 else (350,50)
 place(im,crow('b','feather'),left,125,1);place(im,dummy('b',True),right,125,1)
 if i in [6,7]:
  for x in [98,398]:
   for j in range(3):
    length=4+(i%2)*3;d.line([(x-10+j*8,189-j*7),(x-10+j*8+length,189-j*7-length)],fill=rgba(PURPLE if j%2 else '#FFFBE4'),width=3)
 label(im,(20,6),'换位 · 两端短羽光',16);label(im,(20,289),'两端不连线；不消耗储羽',13);return im
def crow_repair(i):
 im=scene();crow_x=[80,110,140,176,196,196,196,196,196,196,196,196][i]
 place(im,crow('b','feather' if i<4 else 'idle'),crow_x,108,1)
 place(im,dummy('b',damaged=i<4),236,108,1)
 label(im,(20,6),'储羽 · 接触修复',16);label(im,(20,289),'近身修复自家受伤草人，不是飞羽伤害',13);return im
NAMES={'magnet_crab':'磁铁蟹','cactus':'仙人掌','shell_turtle':'脱壳乌龟','crow':'乌鸦'}
def write_animation(folder,id,title,fn,count=12,ms=120):
 frames=[fn(i) for i in range(count)];frames[0].save(folder/(id+'.gif'),save_all=True,append_images=frames[1:],duration=ms,loop=0,disposal=2)
 frames[min(2,count-1)].save(folder/(id+'.png'))
 with Image.open(folder/(id+'.gif')) as gif:
  total=0
  for i in range(gif.n_frames):gif.seek(i);total+=gif.info.get('duration',0)
  encoded=gif.n_frames
 return {'id':id,'title':title,'image':id+'.png','animation':id+'.gif','logical_frames':count,'encoded_frames':encoded,'loop_duration_ms':total,'note':'无声概念编排，非游戏时序'}
def build():
 decisions=json.loads((ROOT/'DECISIONS.json').read_text())
 for id in ['magnet_crab','cactus','shell_turtle','crow']:
  folder=ROOT/'characters'/id;folder.mkdir(parents=True,exist_ok=True)
  selected(id).save(folder,'selected_sprite');main_image(id).save(folder/'selected.png')
  media=[]
  if id=='magnet_crab':
   nail(False).save(folder,'nail_rest');nail(True).save(folder,'nail_moving')
   media.append(write_animation(folder,'moving_nails','移动钉迹',crab_nails))
   confirmed=['横向马蹄钳','移动钉短轨迹，静钉无害','普通受击眨眼']
  elif id=='cactus':
   selected_cactus(flower=True).save(folder,'flower_lit_sprite')
   thorn_object().save(folder,'object_thorn')
   media.append(write_animation(folder,'thorns_landing','落刺短亮',cactus_thorns))
   media.append(write_animation(folder,'regrow_flower','换位花亮',cactus_regrow))
   confirmed=['高柱花冠、两个眼睛','落刺短亮；真实换位仅花冠亮','不回血；普通受击眨眼']
  elif id=='shell_turtle':
   shell('a').save(folder,'object_shell')
   media.append(write_animation(folder,'shell_spin','壳纹旋转',turtle_spin))
   media.append(write_animation(folder,'hide_in_shell','寻壳隐藏',turtle_hide))
   confirmed=['长颈短足、独立圆拱壳','仅壳纹旋转，无弧光／自动冲刺','仅裸身掉血眨眼；壳与隐藏态不伤']
  else:
   dummy('b').save(folder,'object_dummy');dummy('b',True).save(folder,'object_dummy_damaged');feather().save(folder,'object_feather')
   media.append(write_animation(folder,'swap_feathers','两端羽光',crow_swap))
   media.append(write_animation(folder,'contact_repair','近身修复',crow_repair))
   confirmed=['宽身披翼、拼布草人','两端短羽光，不连弹道','储羽近身修复，非飞羽伤害；受击眨眼']
  media.append(write_animation(folder,'hurt_blink','受击眨眼',lambda i,id=id:hurt(id,i),count=8,ms=90))
  result={'id':id,'name':NAMES[id],'image':'selected.png','animation':media[0]['animation'],'media':media,'confirmed':confirmed,'awaiting':['新版音效试听确认','本轮动图表现复核'],'setting_path':'SETTING.md','status':'已确认方向 · 新音效待试听','details':{'choices':decisions['characters'][id],'hurt':'仅实际HP减少，保持位置不变；保护/免伤分支不播放普通受击','native_source_size':[96,96],'body_origin':[48,56],'foot_anchor':[48,80],'source':'../../sources/build_selected_last_four.py','geometry_source':'../../sources/pixel_base.py','validation':'PNG/SVG/GIF本轮导出自检；未游戏接入、真机或人工听审','source_image_inputs':False}}
  (folder/'review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
  print(id,'R04 selected written')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--root',type=Path,required=True);args=p.parse_args();ROOT=args.root.resolve();build()
