#!/usr/bin/env python3
"""R02 newly authored UI source. No existing image or screenshot is read."""
from pathlib import Path
import json,hashlib,subprocess,math
ROOT=Path(__file__).resolve().parents[1]
P={'ink':'#243746','cream':'#F7EBCD','paper':'#FFF7E4','wood':'#D9BA8C','shadow':'#A98463','gold':'#EFC65B','gold_light':'#FFF0A2','coral':'#E77D65','purple':'#B89ACF','mint':'#8FBDB1','muted':'#A7A99F'}
assets=[]
def rect(x,y,w,h,c,opacity=None):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{P.get(c,c)}"'+(f' opacity="{opacity}"' if opacity is not None else '')+'/>'
def poly(points,c):return '<polygon points="'+' '.join(f'{x},{y}' for x,y in points)+'" fill="'+P.get(c,c)+'"/>'
def path(d,c):return f'<path d="{d}" fill="{P.get(c,c)}"/>'
def frame(w,h,fill='cream',edge='ink',inset=4):
 return poly([(4,0),(w-4,0),(w-4,4),(w,4),(w,h-4),(w-4,h-4),(w-4,h),(4,h),(4,h-4),(0,h-4),(0,4),(4,4)],edge)+rect(4,4,w-8,h-8,fill)+rect(4,4,w-8,2,'paper')+rect(4,h-6,w-8,2,'shadow')
def asset(name,w,h,body,use,nine=None,notes=None):
 s=f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges"><title>{name}</title>{body}</svg>\n'
 p=ROOT/'source'/f'{name}.svg';p.write_text(s)
 dst=ROOT/'png'/f'{name}.png'
 subprocess.run(['inkscape',str(p),'--export-type=png',f'--export-filename={dst}','--export-background-opacity=0'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 item={'id':name,'source':'source/'+p.name,'file':'png/'+dst.name,'width':w,'height':h,'format':'RGBA PNG','usage':use,'newly_authored':True,'nine_slice_margins':nine,'notes':notes or ''}
 item['sha256']=hashlib.sha256(dst.read_bytes()).hexdigest();assets.append(item)
asset('status_panel',64,64,frame(64,64)+rect(8,10,48,4,'wood'),'左右角色信息面板', [12,16,12,12], '建议显示160x600；仅中心拉伸，所有文字/角色图标实时叠加。')
asset('control_strip',64,40,frame(64,40,'wood')+rect(8,8,48,2,'cream'),'公共操作条底板',[12,12,12,12])
asset('inset_panel',48,32,frame(48,32,'paper')+rect(8,8,32,2,'cream'),'数值/状态小面板',[8,8,8,8])
asset('hp_track',128,16,frame(128,16,'ink')+rect(4,4,120,8,'shadow'),'生命值轨道',[4,4,4,4], '内填充范围x4,y4,w120,h8；只绑定health/max_health。')
asset('hp_frame',128,16,path('M4 0H124V4H128V12H124V16H4V12H0V4H4ZM4 4V12H124V4Z','ink')+rect(4,2,120,2,'cream'),'生命值上层边框',[4,4,4,4])
for n,c,hl in [('gold','gold','gold_light'),('purple','purple','paper')]:
 asset('hp_fill_'+n,120,8,rect(0,0,120,8,c)+rect(0,0,120,2,hl)+rect(0,6,120,2,'shadow'),'生命值填充，使用TextureProgressBar横向裁切',None,'不用于无上限的兔蓄伤；health/max_health归一化。')
for n,fill,accent in [('normal','cream','wood'),('ready','paper','mint'),('disabled','#D8D3C4','muted')]:
 body=frame(64,64,fill)+rect(6,6,52,4,accent)+rect(6,54,52,4,accent)
 if n=='ready':body+=rect(4,26,4,12,'mint')+rect(56,26,4,12,'mint')
 asset('skill_slot_'+n,64,64,body,'自动技能状态槽：'+n,[12,12,12,12], '这不是手动施法按钮；ready仅表示CD归零。')
asset('cooldown_overlay',56,56,rect(0,0,56,56,'ink',0.68),'技能图标上的冷却遮罩；由TextureProgressBar裁切/径向填充',None,'进度=clamp(cd_remaining/cd_duration,0,1)；不要按绘制帧累加。')
asset('cooldown_ring_track',40,40,poly([(12,0),(28,0),(28,4),(36,4),(36,12),(40,12),(40,28),(36,28),(36,36),(28,36),(28,40),(12,40),(12,36),(4,36),(4,28),(0,28),(0,12),(4,12),(4,4),(12,4)],'shadow')+path('M12 4H28V8H32V12H36V28H32V32H28V36H12V32H8V28H4V12H8V8H12ZM12 8V12H8V28H12V32H28V28H32V12H28V8Z','cream'),'可选径向冷却轨道')
asset('cooldown_ring_fill',40,40,path('M12 0H28V4H36V12H40V28H36V36H28V40H12V36H4V28H0V12H4V4H12ZM12 4V8H8V12H4V28H8V32H12V36H28V32H32V28H36V12H32V8H28V4Z','gold'),'可选径向冷却填充纹理；用TextureProgressBar径向裁切')
asset('badge_ready',16,16,frame(16,16,'mint')+poly([(4,8),(6,8),(6,10),(10,6),(12,6),(12,8),(6,14),(2,10),(2,8)],'ink'),'就绪辅助符号，不能代替忙碌状态')
asset('badge_busy',16,16,rect(2,0,12,2,'ink')+rect(2,14,12,2,'ink')+poly([(4,2),(12,2),(12,4),(10,6),(10,10),(12,12),(12,14),(4,14),(4,12),(6,10),(6,6),(4,4)],'wood')+rect(6,6,4,4,'coral'),'动作忙碌/不可打断提示，CD归零时仍可显示')
for n,fill in [('normal','cream'),('hover','paper'),('pressed','wood'),('disabled','#D8D3C4')]:
 asset('button_'+n,48,48,frame(48,48,fill),'公共操作按钮'+n,[8,8,8,8],'图标独立叠加；触控区域至少44参考像素，文字实时绘制。')
glyphs={
 'pause':rect(4,3,5,18,'ink')+rect(15,3,5,18,'ink'),
 'play':poly([(6,2),(6,22),(10,22),(22,14),(22,10),(10,2)],'ink'),
 'replay':poly([(3,4),(17,4),(17,7),(21,7),(21,18),(17,18),(17,21),(7,21),(7,18),(17,18),(17,10),(7,10),(7,14),(0,7),(7,0),(7,4)],'ink'),
 'new_seed':poly([(4,0),(20,0),(20,4),(24,4),(24,20),(20,20),(20,24),(4,24),(4,20),(0,20),(0,4),(4,4)],'ink')+rect(4,4,16,16,'cream')+rect(5,5,4,4,'coral')+rect(15,5,4,4,'coral')+rect(10,10,4,4,'coral')+rect(5,15,4,4,'coral')+rect(15,15,4,4,'coral'),
 'speed':poly([(1,4),(5,4),(13,10),(13,14),(5,20),(1,20),(9,12)],'ink')+poly([(11,4),(15,4),(23,10),(23,14),(15,20),(11,20),(19,12)],'ink'),
 'sound_on':rect(0,8,6,8,'ink')+poly([(6,8),(14,2),(14,22),(6,16)],'ink')+rect(17,7,3,10,'ink')+rect(21,3,3,18,'ink'),
 'sound_off':rect(0,8,6,8,'ink')+poly([(6,8),(14,2),(14,22),(6,16)],'ink')+poly([(15,5),(18,5),(24,17),(24,20),(21,20),(15,8)],'coral')+poly([(21,5),(24,5),(24,8),(18,20),(15,20),(15,17)],'coral'),
 'roster':rect(1,2,8,8,'ink')+rect(15,2,8,8,'ink')+rect(1,14,8,8,'ink')+rect(15,14,8,8,'ink'),
 'info':rect(9,1,6,5,'ink')+rect(9,9,6,14,'ink'),
 'clock':poly([(6,0),(18,0),(18,3),(21,3),(21,6),(24,6),(24,18),(21,18),(21,21),(18,21),(18,24),(6,24),(6,21),(3,21),(3,18),(0,18),(0,6),(3,6),(3,3),(6,3)],'ink')+rect(5,5,14,14,'cream')+rect(10,5,3,9,'ink')+rect(10,11,8,3,'ink'),
 'heart':poly([(0,4),(4,4),(4,0),(10,0),(10,4),(14,4),(14,0),(20,0),(20,4),(24,4),(24,12),(20,12),(20,16),(16,16),(16,20),(12,24),(8,20),(8,16),(4,16),(4,12),(0,12)],'coral')+rect(5,4,4,4,'paper')}
for name,body in glyphs.items():asset('icon_'+name,24,24,body,'公共UI图标：'+name,None,'24x24源图，建议显示24x24或48x48整数倍，触控由父按钮提供。')
def bolt(x=0,y=0,c='gold'):
 return poly([(x+14,y),(x+24,y),(x+18,y+10),(x+26,y+10),(x+8,y+30),(x+12,y+17),(x+5,y+17)],c)
def blade(x=0,y=0):
 return poly([(x+12,y),(x+20,y),(x+20,y+4),(x+24,y+4),(x+24,y+18),(x+20,y+18),(x+20,y+22),(x+12,y+22),(x+12,y+18),(x+8,y+18),(x+8,y+4),(x+12,y+4)],'ink')+rect(x+12,y+4,8,14,'mint')+rect(x+14,y+4,4,14,'purple')+rect(x+6,y+20,20,4,'coral')+rect(x+14,y+24,4,8,'wood')
special={
 'skill_timer':poly([(8,0),(24,0),(24,4),(28,4),(28,8),(32,8),(32,24),(28,24),(28,28),(24,28),(24,32),(8,32),(8,28),(4,28),(4,24),(0,24),(0,8),(4,8),(4,4),(8,4)],'ink')+rect(5,5,22,22,'cream')+rect(13,6,4,12,'ink')+rect(13,14,11,4,'ink')+poly([(22,0),(30,0),(26,8),(32,8),(20,21),(23,12),(18,12)],'gold'),
 'skill_rod':rect(12,12,6,14,'ink')+rect(8,26,14,4,'ink')+rect(4,30,22,2,'ink')+rect(14,10,2,16,'mint')+poly([(6,4),(10,4),(10,10),(22,10),(22,4),(26,4),(26,14),(18,14),(18,24),(12,24),(12,14),(6,14)],'ink')+rect(10,10,12,2,'mint')+poly([(18,0),(24,0),(20,6),(24,6),(14,16),(16,8),(12,8)],'gold'),
 'skill_forge':poly([(2,18),(28,18),(28,22),(22,24),(22,28),(26,28),(26,32),(4,32),(4,28),(8,28),(8,24),(2,22)],'ink')+rect(6,20,18,2,'mint')+poly([(9,4),(13,0),(25,8),(21,14)],'ink')+poly([(13,4),(15,3),(22,8),(20,10)],'wood')+poly([(15,10),(19,12),(11,22),(7,20)],'wood')+rect(2,9,3,3,'coral')+rect(0,13,3,3,'gold')+rect(27,11,3,3,'gold'),
 'skill_temper':poly([(6,30),(2,24),(4,18),(8,20),(8,12),(14,18),(18,7),(24,18),(27,15),(31,24),(26,30)],'coral')+poly([(10,30),(6,25),(12,20),(15,24),(20,17),(25,25),(22,30)],'gold')+blade(0,0),
 'status_cloud':poly([(5,8),(8,8),(8,4),(18,4),(18,6),(25,6),(25,10),(29,10),(29,18),(25,18),(25,21),(5,21),(5,18),(1,18),(1,11),(5,11)],'ink')+rect(5,11,20,6,'muted')+rect(9,7,8,9,'muted')+rect(19,10,6,6,'muted')+poly([(15,17),(23,17),(19,23),(24,23),(12,32),(15,25),(10,25)],'gold'),
 'status_stored_damage':blade(-3,0)+poly([(20,24),(24,20),(28,20),(32,24),(32,28),(28,32),(24,32),(20,28),(16,32),(12,32),(8,28),(8,24),(12,20),(16,20),(20,24),(20,27),(15,23),(12,23),(11,25),(11,27),(13,29),(15,29),(20,25),(24,29),(27,29),(29,27),(29,25),(27,23),(25,23),(21,27)],'ink')}
for name,body in special.items():
 asset('icon_'+name,32,32,body,'角色技能/状态独立图标：'+name,None,'独立图标，不含角色或数值；自动技能CD/真实状态由代码绑定。蓄伤用数值，无固定上限槽。')
manifest={'version':'R02-UI-remake-1','origin':'newly authored SVG geometry in this approved production round; not recovered R02 source and not cropped from review images','palette':P,'assets':assets}
(ROOT/'ui_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('built',len(assets),'assets')
