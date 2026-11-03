#!/usr/bin/env python3
"""R02 remake: original pixel geometry. Does not read/crop prior artwork.

Python 3 + Pillow. Emits transparent individual PNGs, strips and editable SVGs.
All artwork coordinates are original 48x48 logical pixels, exported nearest x2.
"""
from pathlib import Path
import argparse, hashlib, json, math
from PIL import Image, ImageDraw

P = {'ink':'#243746','outline_light':'#405361','cream':'#FFF3DA',
     'duck':'#F3C954','duck_hi':'#FFE996','duck_shadow':'#C99039',
     'orange':'#EA9250','coral':'#EA7E65','coral_hi':'#FFA586',
     'rabbit':'#BE9CD6','rabbit_hi':'#E5D0F0','rabbit_shadow':'#9277B3',
     'ear':'#A185C1','apron':'#C99450','apron_hi':'#E4B46A',
     'apron_shadow':'#91663C','metal':'#B1D2D3','metal_hi':'#EBF6DD',
     'metal_shadow':'#6D9CA5','blue':'#81C8CA','spark':'#FFE188'}

class Canvas:
    def __init__(self):
        self.im=Image.new('RGBA',(48,48));self.d=ImageDraw.Draw(self.im);self.svg=[]
    def rect(self,b,color):
        x,y,r,bottom=[int(round(v)) for v in b]
        if r<=x or bottom<=y:return
        c=P.get(color,color)
        self.d.rectangle((x,y,r-1,bottom-1),fill=c)
        self.svg.append(f'<rect x="{x}" y="{y}" width="{r-x}" height="{bottom-y}" fill="{c}"/>')
    def poly(self,points,color):
        pts=[(round(x),round(y)) for x,y in points];c=P.get(color,color)
        self.d.polygon(pts,fill=c)
        self.svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}"/>')
    def line(self,points,color,width=1):
        for x,y in points:self.rect((x,y,x+width,y+width),color)
    def finish(self,path,svgpath):
        path.parent.mkdir(parents=True,exist_ok=True)
        self.im.resize((96,96),Image.Resampling.NEAREST).save(path)
        svgpath.parent.mkdir(parents=True,exist_ok=True)
        # Pixel-run rectangles reproduce our original authored pixel canvas exactly
        # across SVG renderers (avoids polygon edge inclusion differences).
        runs=[]
        for y in range(48):
            x=0
            while x<48:
                rgba=self.im.getpixel((x,y));end=x+1
                while end<48 and self.im.getpixel((end,y))==rgba:end+=1
                if rgba[3]:
                    color='#%02x%02x%02x'%rgba[:3]
                    runs.append(f'<rect x="{x}" y="{y}" width="{end-x}" height="1" fill="{color}"/>')
                x=end
        svgpath.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 48 48" shape-rendering="crispEdges">'+''.join(runs)+'</svg>\n')

def duck(c,pose='idle',phase=0):
    # Feet stay on the same baseline; breathing moves only torso/head.
    b=[0,-1,-1,0][phase%4] if pose=='idle' else 0
    squash=[0,1,1,0][phase%4] if pose=='impact' else 0
    if pose=='recover':b=[1,0,-1,0][phase%4]
    headb=b+squash
    c.rect((16,37,23,40),'ink');c.rect((27,37,34,40),'ink')
    c.rect((17,38,22,39),'orange');c.rect((28,38,33,39),'coral')
    # Rounded stepped tail and body silhouette, no anti-aliasing.
    c.poly([(10,27+b),(14,27+b),(14,24+b),(20,24+b),(20,21+b),(31,21+b),(35,25+b),(35,34+b),(32,37),(17,37),(13,34+b),(13,31+b),(10,31+b)],'ink')
    c.poly([(12,28+b),(16,28+b),(16,26+b),(22,26+b),(22,23+b),(30,23+b),(33,26+b),(33,33+b),(30,35+b),(18,35+b),(15,32+b),(15,30+b),(12,30+b)],'duck')
    c.poly([(17,32+b),(23,33+b),(31,31+b),(31,35+b),(18,35+b),(15,32+b)],'duck_shadow')
    c.rect((17,27+b,25,29+b),'duck_hi');c.rect((16,29+b,21,30+b),'duck_hi')
    # Head, beak and coral cap are fixed identity traits.
    c.poly([(22,16+headb),(25,14+headb),(31,14+headb),(35,17+headb),(35,25+headb),(32,28+headb),(24,26+headb),(22,23+headb)],'ink')
    c.poly([(24,17+headb),(26,16+headb),(31,16+headb),(33,18+headb),(33,24+headb),(30,26+headb),(24,24+headb)],'duck')
    c.rect((25,17+headb,29,20+headb),'duck_hi')
    c.rect((26,11+headb,32,13+headb),'ink');c.rect((23,13+headb,34,16+headb),'ink')
    c.rect((27,12+headb,31,13+headb),'coral_hi');c.rect((24,14+headb,33,15+headb),'coral')
    c.poly([(33,21+headb),(38,21+headb),(41,23+headb),(38,25+headb),(33,25+headb)],'ink')
    c.poly([(34,22+headb),(38,22+headb),(39,23+headb),(37,24+headb),(34,24+headb)],'orange')
    c.rect((35,22+headb,38,23+headb),'coral_hi')
    if pose=='impact' and phase<2:
        c.rect((29,20+headb,31,21+headb),'ink');c.rect((30,19+headb,31,22+headb),'ink')
    else:
        c.rect((30,19+headb,32,22+headb),'ink');c.rect((30,19+headb,31,20+headb),'cream')
    # Wing silhouette changes, rather than repeating whole poses.
    wing=[[(19,28+b),(26,27+b),(29,29+b),(27,32+b),(21,33+b),(18,31+b)],
          [(18,27+b),(25,26+b),(29,28+b),(26,31+b),(20,32+b),(18,30+b)],
          [(18,26+b),(24,25+b),(28,27+b),(25,30+b),(20,31+b),(18,29+b)],
          [(19,28+b),(25,27+b),(28,29+b),(26,32+b),(21,32+b),(19,30+b)]][phase%4]
    if pose=='cast':
        wing=[[(19,28),(24,26),(29,27),(27,30),(22,32),(19,31)],
              [(19,27),(22,23),(27,21),(29,24),(25,28),(21,30)],
              [(19,27),(21,21),(25,19),(28,21),(25,25),(22,29)],
              [(19,28),(23,25),(28,25),(29,28),(24,31),(21,32)]][phase%4]
    c.poly(wing,'duck_shadow')
    c.poly([(x,y-1) for x,y in wing[:-1]],'duck_hi')
    if pose=='cast':
        for x,y in [[(34,15)],[(36,13),(39,18)],[(37,12),(41,17),(35,9)],[(36,15)]][phase%4]:
            c.rect((x,y,x+1,y+2),'spark');c.rect((x-1,y+1,x+2,y+2),'spark')

def blade(c,hx,hy,angle=-90,glow=False):
    # Local broad stair-edged blade: upward is -90 degrees; no thin rapier.
    rad=math.radians(angle);ux,uy=math.cos(rad),math.sin(rad);vx,vy=-uy,ux
    def p(a,b):return (hx+ux*a+vx*b,hy+uy*a+vy*b)
    def poly(coords,col):c.poly([p(a,b) for a,b in coords],col)
    poly([(-4,-2),(-1,-2),(-1,-5),(1,-5),(1,-4),(13,-4),(13,-3),(16,-3),(18,-1),(18,2),(16,4),(3,4),(3,5),(0,5),(0,2),(-4,2)],'ink')
    poly([(3,-2),(13,-2),(13,-1),(16,-1),(17,0),(16,2),(4,2)],'metal')
    poly([(4,-2),(13,-2),(13,-1),(16,-1),(16,0),(4,0)],'metal_hi')
    poly([(4,1),(15,1),(14,2),(4,2)],'rabbit_shadow' if not glow else 'coral')
    poly([(-1,-4),(1,-4),(1,4),(-1,4)],'coral')
    poly([(-3,-1),(-1,-1),(-1,1),(-3,1)],'apron_hi')
    poly([(-5,-1),(-3,-1),(-3,1),(-5,1)],'rabbit_shadow')

def hammer(c,hx,hy,angle=-90):
    rad=math.radians(angle);u=(math.cos(rad),math.sin(rad));v=(-u[1],u[0])
    def p(a,b):return (hx+u[0]*a+v[0]*b,hy+u[1]*a+v[1]*b)
    c.poly([p(a,b) for a,b in [(-1,-1),(8,-1),(8,1),(-1,1)]],'ink')
    c.poly([p(a,b) for a,b in [(0,0),(7,0),(7,1),(0,1)]],'apron')
    c.poly([p(a,b) for a,b in [(6,-4),(11,-4),(11,4),(6,4)]],'ink')
    c.poly([p(a,b) for a,b in [(7,-3),(10,-3),(10,3),(7,3)]],'metal')
    c.poly([p(a,b) for a,b in [(7,-3),(8,-3),(8,3),(7,3)]],'metal_hi')

def anvil(c,x=34,y=30):
    c.poly([(x-5,y),(x+8,y),(x+8,y+2),(x+4,y+4),(x+2,y+4),(x+2,y+7),(x+5,y+8),(x+5,y+10),(x-4,y+10),(x-4,y+8),(x-1,y+7),(x-1,y+4),(x-4,y+3)],'ink')
    c.poly([(x-4,y+1),(x+7,y+1),(x+4,y+3),(x-3,y+3)],'metal_hi')
    c.poly([(x-2,y+3),(x+2,y+3),(x+1,y+7),(x+3,y+8),(x-2,y+8),(x,y+7)],'metal')
    c.rect((x-3,y+8,x+4,y+9),'metal_shadow')

def rabbit(c,pose='idle',phase=0):
    b=[0,-1,0,1][phase%4] if pose=='idle' else 0
    if pose=='hit_recover':b=[1,0,-1,0][phase%4]
    # Stable feet/physics attachment; no sprite-derived hitbox.
    c.rect((16,37,23,40),'ink');c.rect((27,37,34,40),'ink')
    c.rect((17,38,22,39),'cream');c.rect((28,38,33,39),'cream')
    # Long mismatched but intentional upright ears, same pose identity each state.
    c.poly([(16,20+b),(15,7+b),(17,4+b),(21,4+b),(23,8+b),(23,20+b)],'ink')
    c.poly([(17,18+b),(17,7+b),(18,6+b),(20,6+b),(21,9+b),(21,19+b)],'rabbit')
    c.rect((18,8+b,20,17+b),'ear');c.rect((18,6+b,20,8+b),'rabbit_hi')
    c.poly([(26,20+b),(27,9+b),(29,7+b),(33,7+b),(35,10+b),(32,22+b)],'ink')
    c.poly([(28,19+b),(29,10+b),(30,9+b),(32,9+b),(33,10+b),(30,21+b)],'rabbit')
    c.rect((30,11+b,32,17+b),'ear')
    # Head/body stepped perimeter.
    c.poly([(15,19+b),(20,17+b),(28,17+b),(33,20+b),(35,24+b),(33,28+b),(34,33+b),(31,38),(17,38),(14,34+b),(13,26+b)],'ink')
    c.poly([(16,20+b),(21,19+b),(28,19+b),(31,21+b),(33,24+b),(31,28+b),(32,33+b),(29,36),(18,36),(16,33+b),(15,26+b)],'rabbit')
    c.rect((18,20+b,28,22+b),'rabbit_hi')
    c.rect((16,28+b,18,33+b),'rabbit_shadow');c.rect((30,28+b,32,34+b),'rabbit_shadow')
    # Face and simple warm forge apron are separate readable blocks.
    c.rect((19,24+b,21,27+b),'ink');c.rect((28,24+b,30,27+b),'ink')
    c.rect((19,24+b,20,25+b),'cream');c.rect((28,24+b,29,25+b),'cream')
    c.rect((24,27+b,26,28+b),'coral');c.rect((23,29+b,27,30+b),'rabbit_shadow')
    c.poly([(19,30+b),(29,30+b),(30,36),(18,36)],'apron')
    c.rect((20,30+b,28,31+b),'apron_hi');c.rect((21,33+b,27,36),'apron_shadow')
    c.rect((22,33+b,26,34+b),'apron_hi')
    # Arm and weapon geometry: forge never swings the sword as a hammer.
    if pose=='forge':
        anvil(c,36,29)
        # Metal blade is visibly laid over the anvil.
        c.rect((31,28,44,30),'ink');c.rect((33,28,43,29),'metal_hi')
        c.rect((29,28,32,30),'coral');c.rect((27,28,29,30),'apron')
        hand=[(32,27),(31,25),(33,28),(33,26),(32,27),(32,28)][phase%6]
        c.rect((30,26,34,30),'ink');c.rect((31,27,33,29),'rabbit_hi')
        hammer(c,*hand,angle=[-75,-95,-5,-35,-65,-75][phase%6])
        if phase==2:
            for x,y in [(39,25),(42,26),(40,23)]:c.rect((x,y,x+1,y+2),'spark')
    else:
        if pose=='hit_recover':
            hx,hy,angle=[(28,29,0),(28,29,15),(31,30,-50),(33,31,-90)][phase%4]
        elif pose=='temper':
            hx,hy,angle=[(33,31,-90),(33,30,-88),(33,29,-92),(33,30,-90)][phase%4]
        else:hx,hy,angle=33,31+b,[-90,-88,-90,-92][phase%4]
        if pose=='hit_recover' and phase<2:
            c.rect((28,28+b,32,32+b),'ink');c.rect((29,29+b,31,31+b),'rabbit_hi')
        else:
            c.rect((30,28+b,35,32+b),'ink');c.rect((31,29+b,34,31+b),'rabbit_hi')
        blade(c,hx,hy,angle,pose=='temper')
        if pose=='temper':
            glints=[[(39,18)],[(39,15),(41,23)],[(38,12),(42,20)],[(40,17)]][phase%4]
            for x,y in glints:
                c.rect((x,y,x+1,y+3),'spark');c.rect((x-1,y+1,x+2,y+2),'spark')

def prop(c,name):
    if name=='broad_blade':blade(c,24,36,-90)
    if name=='forge_hammer':hammer(c,24,34,-90)
    if name=='anvil':anvil(c,24,29)
    if name=='lightning_rod':
        c.rect((22,19,26,39),'ink');c.rect((23,19,25,38),'metal_shadow')
        c.rect((18,38,30,41),'ink');c.rect((19,39,29,40),'metal')
        c.poly([(19,22),(17,19),(17,14),(19,14),(19,18),(21,20),(23,20),(23,12),(25,12),(25,20),(27,20),(29,18),(29,14),(31,14),(31,19),(28,22)],'ink')
        c.poly([(19,20),(18,18),(18,15),(19,15),(19,18),(21,20),(24,20),(24,13),(25,13),(25,20),(28,20),(30,18),(30,15),(31,15),(31,19),(28,21),(20,21)],'metal_hi')
        c.rect((23,9,26,13),'ink');c.rect((24,10,25,12),'spark')

ACTIONS={
 'duck':{'idle':([160]*4,True), 'cast':([100,100,120,160],False),
         'impact':([70,80,100,120],False), 'recover':([100,120,120,160],False)},
 'rabbit':{'idle':([160]*4,True),'forge':([160,100,80,90,110,160],True),
           'temper':([140]*4,True),'hit_recover':([70,80,110,160],False)}}

def main(output):
    root=Path(output);manifest={'version':'R02-remake-characters-1','provenance':'New original pixel geometry authored for this delivery; not recovered R02 source, not cropped from previews.','canvas':[96,96],'logical_canvas':[48,48],'export_scale':2,'sampling':'nearest','alpha':'binary 0 or 255; transparent canvas; no baked backdrop','body_origin':[48,56],'foot_anchor':[48,80],'default_facing':'right','default_images':{'duck':'duck/default.png','rabbit':'rabbit/default.png'},'flip_h':{'boundary_coordinates':'x_left=96-x_right','pixel_indices':'x_left=95-x_right','body_origin_left':[48,56],'foot_anchor_left':[48,80]},'animations':[],'props':[]}
    for who,actions in ACTIONS.items():
        for action,(durations,loop) in actions.items():
            frames=[];frame_info=[]
            for i,ms in enumerate(durations):
                c=Canvas();(duck if who=='duck' else rabbit)(c,action,i)
                rel=Path(who)/action/f'frame_{i:02d}.png'
                c.finish(root/rel,root/'source/svg'/rel.with_suffix('.svg'))
                im=Image.open(root/rel);frames.append(im)
                frame_info.append({'path':rel.as_posix(),'duration_ms':ms,'alpha_bbox':list(im.getbbox()),'sha256':hashlib.sha256((root/rel).read_bytes()).hexdigest()})
            strip=Image.new('RGBA',(96*len(frames),96))
            for i,im in enumerate(frames):strip.paste(im,(96*i,0))
            strip_rel=Path(who)/(action+'_strip.png');strip.save(root/strip_rel)
            item={'character':who,'action':action,'frame_size':[96,96],'frame_count':len(frames),'strip':strip_rel.as_posix(),'frame_order':'left_to_right','frame_durations_ms':durations,'loop':loop,'unique_images':len({hashlib.sha256(im.tobytes()).hexdigest() for im in frames}),'frames':frame_info}
            if who=='rabbit' and action=='forge':item['events']=[{'frame_index':2,'event':'forge_contact','audio':'anvil_forge.wav'}]
            if who=='rabbit' and action=='hit_recover':item['events']=[{'frame_index':0,'event':'effective_contact_feedback','audio':'sword_wide_hit.wav','no_damage_delay':True}]
            manifest['animations'].append(item)
        default=root/who/'default.png';default.write_bytes((root/who/'idle/frame_00.png').read_bytes())
    for name in ['broad_blade','forge_hammer','anvil','lightning_rod']:
        c=Canvas();prop(c,name);rel=Path('props')/(name+'.png');c.finish(root/rel,root/'source/svg'/rel.with_suffix('.svg'))
        anchors={'anvil':[48,80],'lightning_rod':[48,82],'broad_blade':[48,72],'forge_hammer':[48,68]}
        manifest['props'].append({'path':rel.as_posix(),'size':[96,96],'alpha_bbox':list(Image.open(root/rel).getbbox()),'anchor':anchors[name],'anchor_semantics':'ground baseline' if name in ['anvil','lightning_rod'] else 'grip attachment','not_collision_shape':True,'sha256':hashlib.sha256((root/rel).read_bytes()).hexdigest()})
    (root/'character_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    # Transparent-first look board is a generated review only, never an asset source.
    board=Image.new('RGBA',(576,192),'#F7EBCD')
    for j,p in enumerate([root/'duck/default.png',root/'rabbit/default.png',root/'rabbit/forge/frame_02.png',root/'rabbit/hit_recover/frame_00.png',root/'props/anvil.png',root/'props/lightning_rod.png']):
        im=Image.open(p);board.alpha_composite(im,(j*96,48))
    (root/'preview').mkdir(exist_ok=True);board.save(root/'preview/character_contact_sheet.png')
    board.resize((1728,576),Image.Resampling.NEAREST).save(root/'preview/character_contact_sheet_3x.png')
    # Labeled preview is not a source or import asset.
    from PIL import ImageFont
    try:
        font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
    except OSError:
        font=ImageFont.load_default()
    overview=Image.new('RGB',(770,8*150+38),'#F7EBCD');d=ImageDraw.Draw(overview)
    d.text((12,10),'R02 REMAKE - ORIGINAL PIXEL SOURCES - PREVIEW ONLY',fill=P['ink'],font=font)
    for row,item in enumerate(manifest['animations']):
        y=38+row*150;who=item['character'];action=item['action']
        d.text((10,y+10),who+' / '+action,fill=P['ink'],font=font)
        d.text((10,y+32),'loop' if item['loop'] else 'one shot',fill=P['outline_light'],font=font)
        for i,frame in enumerate(item['frames']):
            x=180+i*96
            overview.paste(Image.open(root/frame['path']),(x,y),Image.open(root/frame['path']))
            d.text((x+4,y+101),f'{i}: {frame["duration_ms"]}ms',fill=P['ink'],font=font)
    overview.save(root/'preview/all_actions_labeled.png')
    print('Created',sum(len(a['frames']) for a in manifest['animations']),'character frames;',len(manifest['props']),'props')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',default=str(Path(__file__).resolve().parent.parent));args=parser.parse_args();main(args.output)
