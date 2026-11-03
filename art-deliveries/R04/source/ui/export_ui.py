#!/usr/bin/env python3
"""Mechanical UI export from the accepted R04 original drawing program.
No review image, screenshot or game file is read/cropped. No new icon design.
Run from a copied handoff root outside the game checkout.
"""
from pathlib import Path
import ast,json,hashlib,subprocess,math,base64
from html import escape
from PIL import Image
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[1];OUT=ROOT/'assets/ui';META=ROOT/'metadata';OUT.mkdir(parents=True,exist_ok=True);META.mkdir(parents=True,exist_ok=True)
P={'INK':'#243746','PAPER':'#FFF7E4','CREAM':'#F7EBCD','WOOD':'#D9BA8C','BLUE':'#67AFC9','GOLD':'#EFC65B','PURPLE':'#B89ACF','CORAL':'#E77D65','MINT':'#8FBDB1'}
source=(SRC/'original_selected_ui.py').read_text();tree=ast.parse(source)
nodes=[x for x in tree.body if isinstance(x,(ast.ClassDef,ast.FunctionDef)) and x.name in ['Page','glyph']]
namespace={'R':SRC,'Path':Path,'Image':Image,'base64':base64,'escape':escape,'math':math,**P}
exec(compile(ast.Module(body=nodes,type_ignores=[]),str(SRC/'original_selected_ui.py'),'exec'),namespace)
Page=namespace['Page'];glyph=namespace['glyph'];items=[]
def export(name,w,h,draw,purpose,nine=None,binding=None):
 page=Page();draw(page);assert not page.texts
 svg='<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><title>%s</title>%s</svg>\n'%(w,h,w,h,name,''.join(page.svg))
 sp=SRC/(name+'.svg');pp=OUT/(name+'.png');sp.write_text(svg)
 subprocess.run(['inkscape',str(sp),'--export-type=png',f'--export-filename={pp}','--export-background-opacity=0'],check=True,capture_output=True)
 im=Image.open(pp);assert im.size==(w,h) and im.mode=='RGBA'
 item={'id':name,'file':str(pp.relative_to(ROOT)),'source':str(sp.relative_to(ROOT)),'size':[w,h],'format':'RGBA PNG','sha256':hashlib.sha256(pp.read_bytes()).hexdigest(),'origin':'mechanical geometry export from R04 selected original drawing code;not screenshot crop','purpose':purpose,'nine_slice_margins_ltrb':nine,'binding':binding,'alpha_extrema':list(im.getchannel('A').getextrema())};items.append(item)
export('status_panel',160,600,lambda p:p.frame(0,0,160,600),'左右状态面板，无数字/角色',[8,8,8,8])
export('control_strip',600,58,lambda p:p.frame(0,0,600,58,P['WOOD']),'公共控制底板，不带操作/文字',[8,8,8,8])
export('control_button',48,48,lambda p:p.frame(0,0,48,48,P['PAPER']),'R04预览正常按钮底板',[8,8,8,8])
export('auto_skill_slot',56,56,lambda p:p.frame(0,0,56,56,P['PAPER']),'自动技能状态槽，不是施法按钮',[8,8,8,8])
export('auto_skill_slot_ready',56,56,lambda p:(p.frame(0,0,56,56,P['PAPER']),p.rect(4,48,48,3,P['MINT'])),'CD归零原图程序已有薄荷条，不表示可打断',[8,8,8,8])
export('hp_track',132,9,lambda p:p.rect(0,0,132,9,P['WOOD']),'英雄HP背景轨；内区[2,2,128,5]',None,'health/max_health')
for color in ['blue','gold','mint','purple']:
 export('hp_fill_'+color,128,5,lambda p,c=color:p.rect(0,0,128,5,P[c.upper()]),'英雄HP满宽填充，仅横向裁切',None,'clamp(health/max_health,0,1)')
export('charge_track',132,5,lambda p:p.rect(0,0,132,5,P['WOOD']),'已画羊电量细轨',None,'ElectricSheep.charge/MAX_CHARGE;MAX_CHARGE=100')
export('charge_fill',132,5,lambda p:p.rect(0,0,132,5,P['GOLD']),'已画羊电量满宽填充',None,'ElectricSheep.charge/100')
export('object_hp_track',44,5,lambda p:p.rect(0,0,44,5,P['WOOD']),'稻草人HP轨；非独立英雄',None,'Scarecrow.health/max_health')
export('object_hp_fill',42,3,lambda p:p.rect(0,0,42,3,P['CORAL']),'稻草人HP填充，内区[1,1,42,3]',None,'Scarecrow.health/60;不对不可受伤TurtleShell画假HP')
export('cd_overlay',48,48,lambda p:p.rect(0,0,48,48,P['INK'],.24),'技能图标上方剩余CD遮罩，原透明度0.24',None,'height=48*clamp(cd_remaining/actual_cooldown,0,1);top-to-bottom')
role_tint={'bubble':'BLUE','vacuum':'BLUE','eight':'BLUE','wall':'GOLD','wool':'GOLD','bolt':'GOLD','shell':'MINT','spin':'MINT','dummy':'PURPLE','feather':'PURPLE','swap':'PURPLE'}
for kind in role_tint:
 export('icon_'+kind,24,24,lambda p,k=kind:glyph(p,k,0,0,24,P[role_tint[k]]),'R04原绘'+kind+'基础24图标；保留原始角色色，不含数值')
 export('icon_'+kind+'_28',28,28,lambda p,k=kind:glyph(p,k,0,0,28,P[role_tint[k]]),'R04原预览实际显示28尺寸的'+kind+'图标，避免从24PNG非整数放大')
for small in ['speed','heart']:
 uri='data:image/png;base64,'+base64.b64encode((SRC/'input_glyphs'/('icon_'+small+'.png')).read_bytes()).decode()
 export('icon_'+small+'_display20',20,20,lambda p,u=uri:p.add(f'<image width="20" height="20" href="{u}" style="image-rendering:pixelated"/>'),'R04实际20px显示的原始'+small+'图标机械导出；未裁截图')
# Restore exact common PNG glyphs instead of rasterising images inside a new SVG.
for name in ['pause','speed','replay','new_seed','sound_on','roster','info','heart']:
 stem='icon_'+name;pp=OUT/(stem+'.png');sp=SRC/(stem+'.svg');original=SRC/'input_glyphs'/(stem+'.png')
 import shutil
 shutil.copyfile(original,pp);shutil.copyfile(SRC/'input_glyphs'/(stem+'.svg'),sp)
 im=Image.open(pp);items.append({'id':stem,'file':str(pp.relative_to(ROOT)),'source':str(sp.relative_to(ROOT)),'size':list(im.size),'format':'RGBA PNG','sha256':hashlib.sha256(pp.read_bytes()).hexdigest(),'origin':'unchanged R02 native glyph reused by R04 selected preview;not screenshot crop','purpose':'原有公共操作或HP符号','nine_slice_margins_ltrb':None})
(OUT/'retained/r02').mkdir(parents=True,exist_ok=True)
for raw in sorted((SRC/'retained/r02').glob('*.png')):
 import shutil
 shutil.copyfile(raw,OUT/'retained/r02'/raw.name)
for pp in sorted((OUT/'retained/r02').glob('*.png')):
 sp=SRC/'retained/r02'/(pp.stem+'.svg');im=Image.open(pp)
 items.append({'id':'retained_r02_'+pp.stem,'file':str(pp.relative_to(ROOT)),'source':str(sp.relative_to(ROOT)),'size':list(im.size),'format':'RGBA PNG','sha256':hashlib.sha256(pp.read_bytes()).hexdigest(),'origin':'retained original R02 source/PNG already used or available in current game;not newly remade R04 UI','purpose':'保留既有交互态/鸭兔图标/播放静音状态/忙碌标记','nine_slice_margins_ltrb':([8,8,8,8] if pp.stem.startswith('button_') else [12,12,12,12] if pp.stem.startswith('skill_slot') else None)})
(OUT/'environment').mkdir(parents=True,exist_ok=True)
for stem,pos in [('arena_floor',[200,90]),('arena_wood_frame',[190,80]),('screen_surround',[0,0])]:
 pp=OUT/'environment'/(stem+'.png');sp=SRC/'environment'/(stem+'.svg');original=SRC/'environment'/(stem+'.png')
 import shutil
 shutil.copyfile(original,pp);im=Image.open(pp)
 items.append({'id':'environment_'+stem,'file':str(pp.relative_to(ROOT)),'source':str(sp.relative_to(ROOT)),'size':list(im.size),'format':im.mode+' PNG','sha256':hashlib.sha256(pp.read_bytes()).hexdigest(),'origin':'unchanged native R02 environment artwork reused by selected R04 UI;not extracted from a composition','purpose':'已选浅色场地/外木框/屏幕底层，独立原件','ui_top_left_anchor':[0,0],'reference_canvas_position':pos,'not_collision_geometry':True})
result={'version':'R04-handoff-ui-1','accepted_for_handoff':True,'game_verified':False,'scope':'selected minimal left/right UI reusable components;no full review screenshots inassets','baseline_game_commit':'3134f2b8dd0fe250b01e1e7d3c829da5c54aaa47','original_program':'source/ui/original_selected_ui.py','original_program_sha256':hashlib.sha256((SRC/'original_selected_ui.py').read_bytes()).hexdigest(),'assets':items,'limits':['Puffer/Chicken/MagnetCrab/Cactus dedicated skill/state icons were not drawn in accepted R04 UI;see missing list,do not invent icons.','Only interface pixels are exported;state binding,letterbox/touch/device checks remain point-point work.']}
result['layout_metadata']='metadata/ui_layout.json'
if (SRC/'layout_spec.json').exists():
 (META/'ui_layout.json').write_bytes((SRC/'layout_spec.json').read_bytes())
(META/'ui.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print('Exported',len(items),'UI PNGs with editable SVG sources;no screenshot input')
