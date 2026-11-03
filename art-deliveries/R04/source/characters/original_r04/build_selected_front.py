#!/usr/bin/env python3
"""R04 confirmed visual choices: webpage concepts only, never writes game code."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,math,sys
sys.dont_write_bytecode=True
from selected_base_shapes import C,P,puff,fish,eye,egg
ROOT=Path(__file__).resolve().parent.parent
FONT='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'
def f(n):return ImageFont.truetype(FONT,n,index=2)
NAMES={'puffer':'充气球','chicken':'炸弹母鸡','bubble_fish':'泡泡鱼','electric_sheep':'触电羊'}

def segmented(c,r=18,phase=0):
 for i in range(32):
  if i%4 in [0,1]:
   a=i*math.tau/32;x=24+math.cos(a)*r;y=24+math.sin(a)*r
   c.rect((x,y,x+1,y+2),'blue' if phase%2==0 else 'blue_hi')
def puffer(phase=0,absorb=False,blink=False):
 c=C();puff(c,'a',phase%4)
 if absorb:segmented(c,21 if phase==3 else 18,phase)
 if blink:
  for x in [19,28]:c.rect((x,21,x+3,24),'mint');c.rect((x,22,x+3,23),'ink')
 return c
def chicken(phase=0,run=False,lay=False,blink=False):
 c=C();q=phase%4 if run else 0;dx=[-2,0,2,0][q] if run else 0;tail=[-1,0,1,0][q] if run else 0;sq=3 if lay else 0
 # Exactly the selected long-neck fan-tail silhouette; motion is legs/tail,
 # not extra world movement or an invented dash.
 if not lay:
  for x,side in [(18,-1),(25,1)]:
   tip=x+dx*side;yy=41+([0,1,0,-1][q]*side)
   c.poly([(x,33),(x+2,33),(tip+2,yy),(tip,yy)],'ink');c.rect((tip-1,yy,tip+4,yy+2),'orange')
 c.poly([(14,29+sq),(7+tail,16+sq),(8+tail,11+sq),(12+tail,15+sq),(14,22+sq),(13+tail,12+sq),(16+tail,9+sq),(19,22+sq),(21+tail,16+sq),(24+tail,17+sq),(21,30+sq)],'ink')
 c.poly([(14,26+sq),(9+tail,16+sq),(10+tail,15+sq),(16,23+sq),(15+tail,13+sq),(17+tail,13+sq),(19,26+sq)],'coral')
 c.ball(22,28+sq,9,'ink');c.ball(22,27+sq,7,'cream');c.rect((27,15+sq,32,29+sq),'ink');c.rect((28,16+sq,31,27+sq),'gold')
 hx,hy=30,14+sq;c.ball(hx,hy,7,'ink');c.ball(hx,hy,5,'cream')
 c.poly([(hx-4,hy-7),(hx-5,hy-12),(hx-1,hy-10),(hx+1,hy-13),(hx+4,hy-7)],'coral')
 c.poly([(hx+5,hy-1),(hx+10,hy+1),(hx+5,hy+3)],'ink');c.poly([(hx+6,hy),(hx+8,hy+1),(hx+6,hy+2)],'orange')
 if blink:c.rect((hx+1,hy-1,hx+4,hy),'ink')
 else:eye(c,hx+1,hy-2)
 c.rect((hx+2,hy+5,hx+4,hy+8),'coral')
 return c
def bubble(c,x,y,r,level):
 # Each doubling remains visibly deeper in the review examples; no level cap.
 # Eventually 8-bit display quantisation limits colour distinction, never level.
 t=math.exp(-0.19*math.log2(max(1,level)));light=(158,205,214);deep=(10,44,61)
 rgb=tuple(round(d+(a-d)*t) for a,d in zip(light,deep));col='#%02x%02x%02x'%rgb
 # One continuous annulus, not dotted/multiple concentric bands. Composite
 # independently so transparent interiors never erase the fish underneath.
 layer=C();pts=lambda radius:[(x+math.cos(i*math.tau/40)*radius,y+math.sin(i*math.tau/40)*radius) for i in range(40)]
 layer.poly(pts(r),col);layer.poly(pts(max(0,r-(1 if level==1 else 2))),'#00000000')
 layer.rect((x-r+2,y-r+2,x-r+5,y-r+3),'cream')
 c.im.alpha_composite(layer.im);c.d=ImageDraw.Draw(c.im)
def bubble_fish(phase=0,blink=False,eight=False):
 c=C();fish(c,'a',0)
 if blink:c.rect((31,22,34,25),'blue');c.rect((31,23,34,24),'ink')
 if eight:
  for i in range(8):
   a=i*math.tau/8;bubble(c,24+math.cos(a)*(18+phase%2),24+math.sin(a)*(18+phase%2),2,1)
 return c
def sheep(phase=0,blink=False):
 c=C()
 # Two short legs with a visible cream shaft and dark hoof below the fleece.
 for x in [14,27]:
  c.rect((x,33,x+5,43),'ink');c.rect((x+1,34,x+4,41),'wool');c.rect((x,41,x+6,44),'ink')
 for x,y in [(14,16),(23,12),(31,15),(33,24),(25,30),(16,29),(10,23)]:c.ball(x,y,8,'ink');c.ball(x,y,6,'wool')
 c.ball(21,22,12,'wool');c.rect((14,16,18,18),'cream');c.rect((23,12,27,14),'cream')
 c.ball(32,26,7,'ink');c.ball(32,26,5,'face');c.poly([(33,19),(35,14),(39,15),(36,21)],'ink')
 if blink:c.rect((32,25,35,26),'cream')
 else:c.rect((32,24,35,27),'cream');c.rect((34,24,35,27),'ink')
 return c
def wool():
 c=C()
 for x,y in [(18,22),(25,20),(30,25),(24,30),(16,28)]:c.ball(x,y,6,'ink');c.ball(x,y,4,'wool')
 c.rect((18,22,21,23),'cream');return c
def export(c,dest,rel):c.save(dest/rel);return c.im.resize((96,96),Image.Resampling.NEAREST)
def display(im,title='',note=''):
 out=Image.new('RGB',(480,320),'#F7EBCD');d=ImageDraw.Draw(out)
 if title:d.text((14,8),title,font=f(18),fill=P['ink'])
 art=im.resize((288,288),Image.Resampling.NEAREST);out.paste(art,(96,30),art)
 # Mechanics and caveats belong in collapsed page details, not image captions.
 return out
def gif(frames,path,ms=180):
 frames[0].save(path,save_all=True,append_images=frames[1:],duration=ms,loop=0,optimize=False,disposal=2)
def main():
 makers={'puffer':puffer,'chicken':chicken,'bubble_fish':bubble_fish,'electric_sheep':sheep}
 for ident,maker in makers.items():
  dest=ROOT/'characters'/ident;dest.mkdir(parents=True,exist_ok=True)
  im=export(maker(),dest,'selected.png');display(im,NAMES[ident]).save(dest/'selected_display.png')
  hurt=[]
  for i,b in enumerate([False,True,True,False]):
   im=export(maker(blink=b),dest,f'frames/blink_{i}.png');hurt.append(display(im,'眨眼','仅真实HP下降；不加无敌/击退/停顿'))
  (dest/'blink.png').write_bytes((dest/'frames/blink_1.png').read_bytes());gif(hurt,dest/'hurt.gif',140)
  media=[]
  if ident=='puffer':
   frames=[]
   for i in range(4):
    c=puffer(i);im=export(c,dest,f'frames/gas_{i}.png');frames.append(display(im,['原形','充气','充气','放气'][i],'概念动作；大小变化不改碰撞体'))
   gif(frames,dest/'motion.gif',240)
   frames=[]
   for i in range(4):
    c=puffer(i,absorb=True);im=export(c,dest,f'frames/absorb_{i}.png');frames.append(display(im,'分段吸收','免伤可与放气并存；不假掉血'))
   gif(frames,dest/'absorb.gif',240);media=[{'id':'absorb','title':'分段吸收','animation':'absorb.gif'}]
  if ident=='chicken':
   frames=[]
   for i in range(4):
    c=chicken(i,run=True);im=export(c,dest,f'frames/run_{i}.png');frames.append(display(im,'腿尾摆惊跑','姿态概念；不是新增运动规则'))
   gif(frames,dest/'motion.gif',120)
   c=C();egg(c,12,27,False,False,'a');egg(c,34,26,True,False,'a');im=export(c,dest,'spotted_eggs.png');display(im,'斑点蛋').save(dest/'eggs_display.png')
   frames=[]
   for i in range(4):
    c=chicken(lay=True)
    if i>=2:egg(c,12,33,True,i==3,'a')
    im=export(c,dest,f'frames/lay_{i}.png');frames.append(display(im,'蹲蛋','小蛋敌触引信；大蛋落地引信'))
   gif(frames,dest/'lay.gif',220);media=[{'id':'eggs','title':'斑点蛋','image':'eggs_display.png'},{'id':'lay','title':'蹲蛋','animation':'lay.gif'}]
  if ident=='bubble_fish':
   frames=[]
   for i in range(4):
    c=bubble_fish(i,eight=True);im=export(c,dest,f'frames/eight_{i}.png');frames.append(display(im,'八个分离小泡','8个1级泡；1级接敌无伤'))
   gif(frames,dest/'motion.gif',220)
   levels=[1,2,4,8,16,32,64,128];gradeframes=[]
   board=Image.new('RGB',(512,432),'#F7EBCD');bd=ImageDraw.Draw(board)
   for j,lvl in enumerate(levels):
    c=C();bubble(c,24,24,16,lvl);im=export(c,dest,f'grades/level_{lvl}.png');stage=display(im)
    dd=ImageDraw.Draw(stage);num=str(lvl);w=dd.textlength(num,font=f(28));dd.text((240-w/2,150),num,font=f(28),fill=P['ink']);gradeframes.append(stage)
    bx=(j%4)*128;by=44+(j//4)*174;thumb=im.resize((112,112),Image.Resampling.NEAREST);board.paste(thumb,(bx+8,by),thumb);w=bd.textlength(num,font=f(24));bd.text((bx+64-w/2,by+116),num,font=f(24),fill=P['ink'])
   bd.text((14,394),'…',font=f(24),fill=P['ink']);board.save(dest/'grades.png');gif(gradeframes,dest/'grades.gif',400)
   media=[{'id':'grades','title':'等级色深','image':'grades.png','animation':'grades.gif'}]
  if ident=='electric_sheep':
   frames=[]
   for i in range(4):
    c=sheep(i);im=export(c,dest,f'frames/legs_{i}.png');frame=display(im,['两条小短腿','留羊毛','羊毛放电','本体放电'][i])
    if i in [1,2,3]:
     patch=wool().im.resize((112,112),Image.Resampling.NEAREST);frame.paste(patch,(2,185),patch)
    if i in [2,3]:
     dd=ImageDraw.Draw(frame);path=[(91,245),(111,237),(103,247),(132,235)] if i==2 else [(357,186),(382,177),(373,191),(407,179)]
     dd.line(path,fill=P['gold'],width=3)
    frames.append(frame)
   gif(frames,dest/'motion.gif',220)
   im=export(wool(),dest,'wool.png');display(im,'圆团羊毛','无脸无腿；一个羊毛点，共享电量').save(dest/'wool_display.png');media=[{'id':'wool','title':'圆团羊毛','image':'wool_display.png'}]
  confirmed={'puffer':['A圆薄荷软刺','B分段吸收','受击眨眼'],'chicken':['B长颈扇尾','A斑点蛋','腿尾摆惊跑','受击眨眼'],'bubble_fish':['A流线叉尾','单层加粗边','等级浅→深且数字保留','八个分离小泡','受击眨眼'],'electric_sheep':['A圆团云绒','两条可见小短腿','A圆团无脸腿羊毛','受击眨眼']}[ident]
  data={'id':ident,'name':NAMES[ident],'cycle':'R04','image':'selected_display.png','source_image':'selected.png','animation':'motion.gif','media':media+[{'id':'hurt','title':'眨眼','animation':'hurt.gif'}],'confirmed':confirmed,'awaiting':['本轮全新声音待试听；旧R03音色全部作废。'],'setting_path':'SETTING.md','status':'已确认视觉方向的概念复核；网页ONLY，非游戏录像/完整接入动画/接入包','details':{'canvas':'96×96透明原图；展示图由原图nearest放大','timing':'GIF仅演示已选表现，播放速度不是技能CD或战斗时序','audio':'不复制、复用或链接R03试听文件；声音由本轮音效岗重做','game':'没有修改任何游戏代码/玩法/物理/团队配置'}}
  if ident=='bubble_fish':data['details']['grade_color']='以exp(-0.19*log2(level))在浅青(158,205,214)与深蓝(10,44,61)间渐近映射；1/2/4/8/16/32/64/128每档加深，非在16或128截断。更高等级继续保留数字，最终仅显示色域/8bit量化限制可见色差，不限制level。'
  (dest/'review.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 print('R04 front four selected concepts generated')
if __name__=='__main__':main()
