#!/usr/bin/env python3
"""Export accepted R04 editable geometry as native sprites, never crop review media."""
from pathlib import Path
import argparse,hashlib,json,math,sys
from PIL import Image
sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE/'original_r04'))
import build_selected_front as F
import build_selected_last_four as L
from selected_base_shapes import C,egg
from pixel_base import nail,dummy,feather

IDS=['puffer','chicken','bubble_fish','electric_sheep','magnet_crab','cactus','shell_turtle','crow']
FRONT={'puffer':F.puffer,'chicken':F.chicken,'bubble_fish':F.bubble_fish,'electric_sheep':F.sheep}
NAMES={'puffer':'充气球','chicken':'炸弹母鸡','bubble_fish':'泡泡鱼','electric_sheep':'触电羊','magnet_crab':'磁铁蟹','cactus':'仙人掌','shell_turtle':'脱壳乌龟','crow':'乌鸦'}
ORIGINS={'puffer':[48,48],'chicken':[44,56],'bubble_fish':[52,52],'electric_sheep':[42,44],
         'magnet_crab':[48,56],'cactus':[48,56],'shell_turtle':[48,56],'crow':[48,56]}
ORIGIN_BASIS={'puffer':'Explicit source gas-body centre (24,24) logical pixels ×2.',
 'chicken':'Explicit source torso centre (22,28) logical pixels ×2; head/leg movement remains local artwork.',
 'bubble_fish':'Declared handoff attachment near the approved polygonal body centre; no prior game-origin binding exists.',
 'electric_sheep':'Explicit source fleece-core centre (21,22) logical pixels ×2; legs extend below this point.',
 'magnet_crab':'R04 review metadata declared body_origin=(48,56); not runtime-verified.',
 'cactus':'R04 review metadata declared body_origin=(48,56); not runtime-verified.',
 'shell_turtle':'R04 review metadata declared body_origin=(48,56); not runtime-verified.',
 'crow':'R04 review metadata declared body_origin=(48,56); not runtime-verified.'}
REF_RADIUS={'puffer':20,'chicken':18,'bubble_fish':28,'electric_sheep':24,'magnet_crab':28,'cactus':31,'shell_turtle':26,'crow':26}

def image(art):
 return art.im.resize((96,96),Image.Resampling.NEAREST) if hasattr(art,'im') else art.image()
def main(output):
 root=Path(output);(root/'metadata').mkdir(parents=True,exist_ok=True)
 result={'version':'R04-handoff-native-characters-1','scope':'Accepted R04 native geometry and already-authored poses; not screenshots/GIF crops; not complete new animation design.',
  'source_review':'R04-review accepted visual source functions; all runtime bindings NOT VERIFIED',
  'source_directory':'source/characters/original_r04','canvas':[96,96],'format':'PNG RGBA','sampling':'nearest',
  'sizing_rule':'Keep original physics radius unchanged. Texture scale and offsets are presentation only; no collision shapes are generated.',
  'characters':[]}
 for ident in IDS:
  d=root/'assets/characters'/ident;d.mkdir(parents=True,exist_ok=True)
  entry={'id':ident,'name':NAMES[ident],'canvas':[96,96],'canvas_origin_px':[0,0],
   'attachment_origin_px':ORIGINS[ident],'origin_basis':ORIGIN_BASIS[ident],
   'runtime_origin_verified':False,'sprite2d_centered_position_px':[48-ORIGINS[ident][0],48-ORIGINS[ident][1]],
   'origin_usage':'For a Sprite2D with centered=true use centered_position_px relative to the physics body. For top-left origin use -attachment_origin. Recheck real game alignment.',
   'facing':'front' if ident in ['magnet_crab','cactus'] else 'right/three-quarter right',
   'flip_h':{'boundary_coordinates':'x_left=96-x_right','pixel_indices':'x_left=95-x_right','mirrored_attachment_origin_px':[96-ORIGINS[ident][0],ORIGINS[ident][1]],'status':'geometric rule only; mirrored appearance not in-game verified'},
   'physics_radius_unchanged':24,'source_body_reference_radius_px':REF_RADIUS[ident],
   'optional_body_fit_scale_to_radius24':round(24/REF_RADIUS[ident],6),
   'scale_status':'Presentation starting point only, based on authored torso/core size; not final approved game scale. Ignore weapon/ear/fleece extents for physics.',
   'files':[],'animations':[],'state_samples':[],'objects':[],'missing':[]}
  def save(rel,im,role,notes=None,origin=None):
   assert im.mode=='RGBA' and im.size==(96,96)
   p=d/rel;p.parent.mkdir(parents=True,exist_ok=True);im.save(p)
   bb=im.getbbox();record={'path':p.relative_to(root).as_posix(),'role':role,'size':[96,96],'alpha_bbox_px':list(bb) if bb else None,
    'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,
    'attachment_origin_px':origin if origin is not None else ORIGINS[ident],
    'origin_status':'Declared local artwork attachment, NOT verified in the game'}
   if notes:record['notes']=notes
   entry['files'].append(record);return record
  def anim(name,ims,durations,usage,loop=False,origin=None):
   if name=='hurt':usage='IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. '+usage
   records=[]
   for i,im in enumerate(ims):records.append(save(f'animations/{name}/frame_{i:02d}.png',im,'native animation/pose frame',origin=origin))
   strip=Image.new('RGBA',(96*len(ims),96))
   for i,im in enumerate(ims):strip.paste(im,(96*i,0))
   p=d/'animations'/name/'strip.png';strip.save(p)
   srec={'path':p.relative_to(root).as_posix(),'size':list(strip.size),'alpha_bbox_px':list(strip.getbbox()),'frame_size':[96,96],'frame_order':'left_to_right','attachment_origin_per_frame_px':origin if origin is not None else ORIGINS[ident],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'role':'sprite strip'}
   entry['files'].append(srec)
   entry['animations'].append({'id':name,'frames':[x['path'] for x in records],'strip':srec['path'],'frame_size':[96,96],'frame_count':len(ims),
    'unique_images':len({hashlib.sha256(im.tobytes()).hexdigest() for im in ims}),
    'source_preview_frame_durations_ms':durations,'timing_status':'Exact R04 preview timings where present; not simulation duration/CD or damage timing.',
    'loop':loop,'usage':usage,'runtime_binding_verified':False})
  def obj(name,art,origin=[48,48],notes=''):
   rec=save('objects/'+name+'.png',image(art),'independent world object/effect',notes,origin);entry['objects'].append(rec['path']);return rec
  make=lambda blink=False:image(FRONT[ident](blink=blink)) if ident in FRONT else L.selected(ident,blink=blink).image()
  idle=make();hurt=make(True)
  entry['idle']=save('idle.png',idle,'native character idle/static pose')['path']
  entry['hurt']=save('hurt.png',hurt,'native closed-eye hurt pose','IDLE ONLY. Only actual HP loss triggers ordinary blink. For other authored poses use state/phase-matched variants, never reset the body to idle. No extra invulnerability, movement, knockback or hitstop.')['path']
  entry['hurt_application']='Keep current animation state, phase, gas scale and attached objects. hurt.png/animations/hurt are idle-body references only; use provided matched pose variants or an eye-only presentation layer for any unprovided pose.'
  if ident in FRONT:
   anim('hurt',[make(v) for v in [False,True,True,False]],[140]*4,'Trigger only actual HP decrease; restore current pose afterward. Puffer immune hits use absorption instead. Do not loop as an idle.',False)
  else:
   anim('hurt',[make(i in [1,2,4]) for i in range(8)],[90]*8,'Source R04 eye-blink sequence only. Trigger actual HP decrease; hidden turtle and shell do not hurt. Not an immunity duration.',False)
  entry['missing'].append('A full idle/breathing cycle was not authored; idle.png is the approved static cactus pose. This stationary character needs no walking animation.' if ident=='cactus' else 'A full breathing/locomotion idle cycle was not authored in R04; idle.png is the approved static pose, not a complete animated idle.')
  if ident=='puffer':
   for i,gas in enumerate([0,40,50,100]):
    rec=save(f'gas_samples/gas_{gas:03d}.png',image(F.puffer(i)),'gas-driven state sample',f'Source visual radius={10 if i==0 else [10,14,15,20][i]} logical px; at gas100 source also contains accepted burst trail.')
    blinkrec=save(f'gas_samples/gas_{gas:03d}_blink.png',image(F.puffer(i,blink=True)),'same gas/body pose, closed eyes only','Only actual HP loss with matching gas/burst pose. If immune_left>0 uses absorption instead; never switch to empty idle on hit.')
    entry['state_samples'].append({'path':rec['path'],'hurt_variant_path':blinkrec['path'],'gas':gas,'visual_scale_relative_to_empty':1+gas/100,'duration_ms':None,'requires_action':'burst' if gas==100 else 'gas-driven','not_a_time_animation':True})
   for name,radius in [('absorb_segments',18),('absorb_segments_burst',21)]:
    c=C();F.segmented(c,radius);obj(name,c,notes='Only immune_left>0. Segments are one absorption style, not shield layers; may coexist with burst.')
   entry['missing'].append('Gas frames are sparse samples, not a timer animation. Either scale empty-body art by 1+gas/100 or use preinflated samples, never do both (would inflate twice). Continuous gas-driven rendering and event hooks remain game work.')
  if ident=='chicken':
   anim('panic_run',[image(F.chicken(i,run=True)) for i in range(4)],[120]*4,'Selected leg/tail sway only while existing action=run; world direction, speed and one-second duration remain code-controlled.',True)
   anim('panic_run_blink',[image(F.chicken(i,run=True,blink=True)) for i in range(4)],[120]*4,'Closed-eye counterpart at the SAME panic_run phase. Do not restart run/frame0 on damage; eye closure duration is independent presentation feedback.',True)
   entry['animations'][-1]['phase_matched_to']='panic_run'
   entry['animations'][-1]['playback_mode']='same_phase_texture_substitution_not_independent_hurt_sequence'
   save('poses/lay.png',image(F.chicken(lay=True)),'pure crouching pose','No egg baked in. Hold only while action=lay; code spawns the independent large egg after its real timer.')
   save('poses/lay_hurt.png',image(F.chicken(lay=True,blink=True)),'same pure crouching pose, closed eyes only','Use only actual HP loss while lay; do not reset crouch/action_left or show an extra egg.')
   for large in [False,True]:
    for armed in [False,True]:
     c=C();egg(c,24,24,large,armed,'a');name=('large' if large else 'small')+('_armed' if armed else '_rest')
     rec=obj('egg_'+name,c,notes='Selected spotted pattern. Small egg arms after enemy contact (0.8s); large egg arms on landing (1.5s). No fuse number baked in; armed ring is visual only.')
     rec['existing_physics_radius']=23 if large else 11
   entry['missing'].append('R04 lay_2/lay_3 combined chicken+egg frames are intentionally excluded to avoid drawing a second egg. Crouch is a held pose, not a full new laying animation.')
  if ident=='bubble_fish':
   for lvl in [1,2,4,8,16,32,64,128]:
    c=C();F.bubble(c,24,24,16,lvl);obj(f'bubble_level_{lvl}',c,notes='Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).')
   entry['bubble_rendering']={'nominal_texture_radius_px':32,'runtime_radius_formula':'min(54,9+sqrt(level)*3)','runtime_visual_scale_formula':'runtime_radius/32 (starting mapping; verify pixel alignment)',
    'color_formula':'deep+(light-deep)*exp(-0.19*log2(max(1,level)))','light_rgb':[158,205,214],'deep_rgb':[10,44,61],
    'level_cap':None,'numbers':'Render actual level dynamically, including 1 and values beyond128. Colour/display precision is not a level cap.',
    'eight_way':'Use eight independent level1 objects at actual Bubble positions. Do NOT use R04 combined fish+eight bubble frame as one gameplay sprite.'}
   entry['missing'].append('Dedicated mouth/cast/vacuum character animation was not authored; R04 eight-way frames are combined illustrations and intentionally excluded. Independent Bubble art can be bound to actual world entities; absorption movement is code-controlled.')
  if ident=='electric_sheep':
   obj('wool',F.wool(),notes='One selected round wool clump: no face/legs and no independent charge pool. Place only at actual wool_position.')
   entry['missing'].append('R04 main sheep GIF places wool and discharge on a review stage; those stage frames are not character sprites and are excluded. Sheep body uses approved idle/hurt poses; independent discharge VFX/event binding is separate.')
  if ident=='magnet_crab':
   obj('nail_rest',nail(False),notes='Resting nail is harmless; no moving trail.')
   obj('nail_moving',nail(True),notes='Moving nail source colour only; use actual IronNail.mode/position/velocity. Trail is independent VFX, not another damage object.')
   entry['missing'].append('Dedicated claw/cast or walking animation was not authored. Review nail trajectory stage is excluded; actual nail motion and return/repel use code.')
  if ident=='cactus':
   save('poses/flower_lit.png',L.selected_cactus(flower=True).image(),'same body with flower lit','Only successful reposition triggers this brief flower state; no healing/extra invulnerability.')
   save('poses/flower_lit_hurt.png',L.selected_cactus(blink=True,flower=True).image(),'same flower-lit body, closed eyes only','Keep the current flower state on actual HP loss; no healing or pose reset.')
   obj('thorn',L.thorn_object(),notes='Independent selected thorn, no added lifetime. Landing glint belongs to an event effect; code controls placement/contact damage.')
   entry['missing'].append('Full relocation/growth motion was not authored. Do not crop the moving review-stage cactus; swap actual world position and briefly select flower_lit pose.')
  if ident=='shell_turtle':
   rec=obj('shell_rest',L.shell('a'),notes='Separate physical TurtleShell; hidden turtle body is not drawn again. Shell is not damageable.')
   rec['existing_physics_radius']=22
   anim('shell_markings_spin',[L.shell_pattern(i).image() for i in range(12)],[120]*12,'Only shell markings change. Same outer alpha silhouette and canvas; repeat only actual spin_left>0. No glow, body rotation or automatic dash.',True,origin=[48,48])
   entry['animations'][-1]['target']='independent shell, NOT turtle body'
   entry['missing'].append('R04 seek/hide stage uses world-position illustration, not a body animation. Use idle at actual turtle.position during seek and hide body when code visible=false; no forced exit timing.')
  if ident=='crow':
   save('poses/feather_stored.png',L.selected('crow',stored=True).image(),'character with stored feather','Do not also overlay the independent feather object on this combined stored-state pose.')
   stored=L.selected('crow',stored=True);normal=L.selected('crow');closed=L.selected('crow',blink=True)
   closed.ops.extend(stored.ops[len(normal.ops):])
   save('poses/feather_stored_hurt.png',closed.image(),'same stored-feather body, closed eyes only','Uses the original appended feather geometry ops. Keep feather state on HP loss; do not consume it or reset the pose.')
   obj('dummy',dummy('b'),notes='Selected patchwork scarecrow, stationary world object, HP60; not a weapon or an attacking minion.')
   obj('dummy_damaged',dummy('b',True),notes='Damaged patchwork state. Actual health/collision and reflection remain code-controlled.')
   obj('feather',feather(),notes='Stored feather or contact repair cue, never a flying damage projectile.')
   entry['missing'].append('Full wing-flap/swap/repair body animation was not authored. Source stage position changes are excluded. Use actual swap and contact-repair events plus independent short endpoint glints, never a connecting projectile trail.')
  result['characters'].append(entry)
 (root/'metadata/characters.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
 print('Exported',len(result['characters']),'characters;',sum(len(x['files']) for x in result['characters']),'native PNG/strip records')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=HERE.parents[1]);a=p.parse_args();main(a.output.resolve())
