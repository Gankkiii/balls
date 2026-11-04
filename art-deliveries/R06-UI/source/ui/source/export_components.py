from pathlib import Path
import xml.etree.ElementTree as E,json,copy,subprocess,hashlib
R=Path(__file__).resolve().parents[1];S=Path(__file__).resolve().parent/'input_scenes';(R/'svg').mkdir(exist_ok=True);(R/'png').mkdir(exist_ok=True);(R/'metadata').mkdir(exist_ok=True)
NS='{http://www.w3.org/2000/svg}';rows=[]
def export(id,scene,selectors,bounds,use,margin=None,state='existing R06 normal state only'):
 root=E.parse(S/scene).getroot();selected=[]
 for selector in selectors:
  hits=[n for n in root if all(n.get(k)==str(v) for k,v in selector.items())]
  assert len(hits)==1,(id,selector,len(hits));selected.append(copy.deepcopy(hits[0]))
 x,y,w,h=bounds;a=E.Element('svg',{'xmlns':'http://www.w3.org/2000/svg','width':str(w),'height':str(h),'viewBox':f'{x} {y} {w} {h}'})
 for node in selected:
  node.tag=node.tag.replace(NS,'');a.append(node)
 path=R/'svg'/(id+'.svg');E.indent(a);E.ElementTree(a).write(path,encoding='unicode');path.write_text(path.read_text()+'\n');subprocess.run(['inkscape',str(path),'-o',str(R/'png'/(id+'.png'))],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 from PIL import Image
 im=Image.open(R/'png'/(id+'.png')).convert('RGBA');rows.append({'id':id,'file':f'png/{id}.png','source':f'svg/{id}.svg','delivery_file':f'assets/ui/{id}.png','delivery_source':f'source/ui/components/{id}.svg','upstream_scene':f'source/input_scenes/{scene}','method':'original SVG element extraction; no screenshot or bitmap crop','size':[w,h],'use':use,'alpha_extrema':im.getchannel('A').getextrema(),'nine_slice_ltrb':margin,'state':state,'sha256':hashlib.sha256((R/'png'/(id+'.png')).read_bytes()).hexdigest()})
def panel(id,x,y,w,h,use):
 sel=[{'x':x+5,'y':y+6,'width':w,'height':h},{'x':x,'y':y,'width':w,'height':h},{'x':x+4,'y':y+4,'width':w-8,'height':h-8},{'x':x+8,'y':y+8,'width':w-16,'height':h-16},{'x':x+8,'y':y+8,'width':w-16,'height':3}]
 export(id,'arena_main.svg',sel,[x,y,w+5,h+6],use,[8,8,13,14])
panel('arena_status_panel',164,180,230,600,'R06 B side status panel; visible panel230x600 plus right5/bottom6 shadow')
panel('arena_control_button',550,811,54,54,'R06 common control button; no glyph/text')
panel('arena_auto_skill_slot',203,534,64,64,'R06 B read-only automatic skill slot; no glyph/CD')
export('arena_hp_track','arena_main.svg',[{'x':191,'y':365,'width':176,'height':10}],[191,365,176,10],'HP track, dynamic fill is not baked')
export('arena_cd_overlay','arena_main.svg',[{'x':211,'y':542,'width':48,'height':34,'opacity':'0.14'}],[211,542,48,34],'cooldown tint; runtime clip by true remaining/CD, not a fixed cooldown animation')
export('arena_info_panel','arena_info.svg',[{'x':545,'y':266,'width':520,'height':360},{'x':540,'y':260,'width':520,'height':360},{'x':544,'y':264,'width':512,'height':352},{'x':548,'y':268,'width':504,'height':344},{'x':548,'y':268,'width':504,'height':3}],[540,260,525,366],'information popup skin without values/text',[8,8,13,14])
# story stroke centered on geometry; bounds explicitly include full stroke plus shadow.
export('story_archive_panel','story_main.svg',[{'x':36,'y':130,'width':416,'height':668},{'x':30,'y':123,'width':416,'height':668},{'x':36,'y':129,'width':404,'height':3}],[28,121,424,677],'archive listing panel, no text; includes centered3px outline and shadow',[10,10,16,17])
export('story_action_button','story_main.svg',[{'x':1192,'y':606,'width':332,'height':84},{'x':1190,'y':601,'width':332,'height':84}],[1188,599,336,91],'normal story action button without text',[4,4,6,9])
export('story_entry_selected','story_main.svg',[{'x':119,'y':291,'width':295,'height':84}],[119,291,295,84],'selected archive row flat backing',[0,0,0,0],'existing selected state')
export('story_entry_normal','story_main.svg',[{'x':119,'y':402,'width':295,'height':84}],[119,402,295,84],'normal archive row flat backing',[0,0,0,0])
export('story_search_field','story_main.svg',[{'x':58,'y':203,'width':360,'height':62}],[57,202,362,64],'search field backing without glyph/placeholder',[2,2,2,2])
export('story_search_icon','story_main.svg',[{'cx':83,'cy':230,'r':11},{'d':'M91 239 L102 250'}],[70,217,35,36],'original search circle/handle geometry; independent from font')
export('storage_trait_spark','storage_trait_spark.svg',[{'fill':'#293d40'}],[0,0,20,24],'original storage trait star glyph rendered at20px; baseline20; DejaVu license included',None,'original actual fallback glyph from R06 source')
export('storage_skill_asterisk','storage_skill_asterisk.svg',[{'fill':'#698f86'}],[0,0,26,30],'original storage second-skill ornament glyph at25px; baseline25; DejaVu license included',None,'original actual fallback glyph from R06 source')
(R/'metadata/components.json').write_text(json.dumps({'basis':'ball_art_review@54d8f8d sources/r06; original element extraction','no_dynamic_text_baked':True,'assets':rows},ensure_ascii=False,indent=2)+'\n')
print('exported',len(rows))
