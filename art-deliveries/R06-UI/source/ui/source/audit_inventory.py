from pathlib import Path
from PIL import Image
from fontTools.ttLib import TTFont
import json,hashlib,re
R=Path(__file__).resolve().parents[1];REVIEW=Path('/workspace/ball_art_review/sources/r06');GAME=Path('/workspace/balls');meta=json.loads((GAME/'art-deliveries/R04/metadata/ui.json').read_text());rows=[]
for a in meta['assets']:
 rel=Path(a['file']).relative_to('assets');p=GAME/'assets/r04'/rel;im=Image.open(p).convert('RGBA');rows.append({'id':a['id'],'current_game_file':str(p.relative_to(GAME)),'original_source':str(Path('art-deliveries/R04')/a['source']),'size':list(im.size),'alpha_extrema':im.getchannel('A').getextrema(),'nine_slice_ltrb':a.get('nine_slice_margins_ltrb'),'purpose':a.get('purpose'),'classification':'existing_independent_native_asset','exact_r06_skin':False,'note':'Reuse only where source matches; R04 160 sidebar/56 skill is not R06230 sidebar/64skill','sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
portraits=[]
for id in ['puffer','chicken','bubble_fish','electric_sheep','magnet_crab','duck','rabbit','cactus','shell_turtle','crow']:
 p=GAME/('assets/r02/characters/'+id+'/default.png' if id in ['duck','rabbit'] else 'assets/r04/characters/'+id+'/idle.png');im=Image.open(p).convert('RGBA');portraits.append({'id':id,'current_game_file':str(p.relative_to(GAME)),'size':list(im.size),'alpha_extrema':im.getchannel('A').getextrema(),'use':'existing transparent portrait/fighter source; no new drawing'})
refs=[]
for page in ['arena','storage','hatch','story']:
 for p in (REVIEW/page).rglob('*.png'):
  if 'qa' in p.parts:continue
  im=Image.open(p)
  # Hatch/assets consists of true duplicated portrait originals; separate it from page reference captures.
  refs.append({'file':str(p.relative_to(REVIEW)),'size':list(im.size),'classification':'existing_portrait_copy' if 'assets' in p.relative_to(REVIEW).parts else 'full_page_reference_only','usable_as_hud_component':False})
font=TTFont(GAME/'assets/arena-ui.otf');cmap=font.getBestCmap();corpus=''.join(p.read_text(errors='ignore') for page in ['arena','storage','hatch','story'] for p in (REVIEW/page).rglob('*') if p.suffix in ['.svg','.html','.js','.css','.json']);chars=set(re.findall('[\u4e00-\u9fff♀♂]',corpus));missing=''.join(sorted(c for c in chars if ord(c) not in cmap))
data={'game_commit':'3dd29e881d43b0be53170696633a6c118cd7d077','review_commit':'54d8f8d','existing_r04_ui_count':len(rows),'existing_r04_ui':rows,'portraits':portraits,'r06_page_reference_images':refs,'font':{'file':'assets/arena-ui.otf','family':'Noto Sans CJK SC','version':'2.004','cmap_count':len(cmap),'license_file':'assets/OFL.txt','source_corpus_unique_cjk_gender_chars':len(chars),'missing_source_corpus_chars':missing,'missing_count':len(missing),'method':'upper-bound source corpus scan including literals/comments/fixtures; not OCR or exact visible-text list','replacement_plan':'root supplies same-family complete SC font and OFL; no game replacement here'}}
(R/'metadata/resource_inventory.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n');print('R04 native',len(rows),'portraits',len(portraits),'references',len(refs),'font missing source corpus',len(missing))
