"""Original R02 remake geometry source; no image inputs, screenshots, fonts or external art.
SVG and pixel PNG exports are rendered from the same original geometry commands.
"""
from pathlib import Path
import json, math, hashlib, argparse
from PIL import Image, ImageDraw

BASE=None
INK='#243746'; CREAM='#F7EBCD'; WOOD='#D9BA8C'; GOLD='#EFC65B'; CORAL='#E77D65'; PURPLE='#B89ACF'
CYAN='#8BC9C3'; WHITE='#FFF9E7'; SHADE='#A8B7BE'

def color(s,alpha=255):
    return tuple(int(s[i:i+2],16) for i in (1,3,5))+(alpha,)

class Art:
    def __init__(self,w,h):
        self.w=w;self.h=h;self.shapes=[]
    def box(self,x,y,w,h,c,a=255):
        self.shapes.append(('box',[int(x),int(y),int(w),int(h)],c,int(a)))
    def poly(self,p,c,a=255):
        self.shapes.append(('poly',[[int(x),int(y)] for x,y in p],c,int(a)))
    def line(self,p,c,width=2,a=255):
        self.shapes.append(('line',[[int(x),int(y)] for x,y in p],c,int(a),width))
    def render(self):
        im=Image.new('RGBA',(self.w,self.h),(0,0,0,0));d=ImageDraw.Draw(im)
        for typ,geo,c,a,*other in self.shapes:
            if typ=='box':
                x,y,w,h=geo;d.rectangle((x,y,x+w-1,y+h-1),fill=color(c,a))
            elif typ=='poly':d.polygon([tuple(p) for p in geo],fill=color(c,a))
            else:d.line([tuple(p) for p in geo],fill=color(c,a),width=other[0])
        return im
    def svg(self):
        parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}" shape-rendering="crispEdges">']
        for typ,geo,c,a,*other in self.shapes:
            opacity=f' opacity="{a/255:.6f}"' if a!=255 else ''
            if typ=='box':
                x,y,w,h=geo;parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"{opacity}/>')
            elif typ=='poly':parts.append(f'<polygon points="'+ ' '.join(f'{x},{y}' for x,y in geo)+f'" fill="{c}"{opacity}/>')
            else:parts.append(f'<polyline points="'+ ' '.join(f'{x},{y}' for x,y in geo)+f'" fill="none" stroke="{c}" stroke-width="{other[0]}" stroke-linecap="square"{opacity}/>')
        return '\n'.join(parts+['</svg>'])
    def save(self,folder,name):
        folder.mkdir(parents=True,exist_ok=True)
        self.render().save(folder/(name+'.png'))
        (folder/(name+'.svg')).write_text(self.svg())

def diamond(a,x,y,r,c,alpha=255):a.poly([(x,y-r),(x+r,y),(x,y+r),(x-r,y)],c,alpha)

def ring(a,cx,cy,rx,ry,c,width=2,alpha=255):
    # An eight-sided pixel ring; coordinates align on integer pixels.
    p=[(cx-rx//2,cy-ry),(cx+rx//2,cy-ry),(cx+rx,cy-ry//2),(cx+rx,cy+ry//2),(cx+rx//2,cy+ry),(cx-rx//2,cy+ry),(cx-rx,cy+ry//2),(cx-rx,cy-ry//2),(cx-rx//2,cy-ry)]
    a.line(p,c,width,alpha)

def cloud(a,x,y,phase):
    shift=[0,-2,-2,0,2,0][phase%6]
    p=[(x-44,y+14),(x-48,y+8),(x-48,y-4),(x-42,y-4),(x-42,y-14),(x-28,y-14),(x-28,y-24),(x-12,y-24),(x-12,y-28),(x+6,y-28),(x+6,y-24),(x+24,y-24),(x+24,y-16),(x+36,y-16),(x+36,y-8),(x+46,y-8),(x+46,y+10),(x+40,y+16),(x-34,y+16),(x-34,y+14)]
    p=[(px,py+shift) for px,py in p];a.poly(p,INK)
    a.poly([(x-42,y+8+shift),(x-42,y-2+shift),(x-36,y-2+shift),(x-36,y-10+shift),(x-22,y-10+shift),(x-22,y-20+shift),(x-10,y-20+shift),(x-10,y-24+shift),(x+2,y-24+shift),(x+2,y-20+shift),(x+20,y-20+shift),(x+20,y-12+shift),(x+32,y-12+shift),(x+32,y-4+shift),(x+40,y-4+shift),(x+40,y+8+shift),(x+34,y+12+shift),(x-30,y+12+shift),(x-30,y+8+shift)],SHADE)
    a.box(x-32,y-10+shift,12,4,'#D7D8CE');a.box(x-16,y-20+shift,14,4,'#D7D8CE')
    a.box(x-30,y+6+shift,54,6,'#7D899F');a.box(x+18,y+2+shift,16,6,'#8B91AB')
    a.box(x-18,y+14+shift,12,4,PURPLE)
    diamond(a,x+20+phase%3*2,y+22,2,GOLD)

def make_environment():
    out=BASE/'environment';entries=[]
    floor=Art(700,600);floor.box(0,0,700,600,CREAM)
    floor.box(2,2,696,596,'#F0E4C8')
    # Quiet, low-contrast inlaid panels. None imply a physical obstacle.
    for y in range(0,600,60):
        for x in range(0,700,70):
            c='#F5E9D0' if (x//70+y//60)%2 else '#F1E5CA'
            floor.box(x+2,y+2,66,56,c)
    floor.box(10,10,680,2,'#E6D8B9');floor.box(10,588,680,2,'#FFFAE5')
    floor.box(10,12,2,576,'#E6D8B9');floor.box(688,12,2,576,'#FFFAE5')
    for x,y in [(28,28),(672,28),(28,572),(672,572)]:
        diamond(floor,x,y,5,'#DDCFB0');diamond(floor,x,y,2,'#F9EFDA')
    # Center medallion intentionally low contrast and flat.
    ring(floor,350,300,42,42,'#E7DABD',2)
    ring(floor,350,300,32,32,'#E7DABD',2)
    floor.box(344,294,12,12,'#E7DABD');floor.save(out,'arena_floor')
    entries.append({'id':'arena_floor','png':'arena_floor.png','svg':'arena_floor.svg','size':[700,600],'anchor':[0,0],'opaque':True,'ui_position':[200,90],'purpose':'flat noncolliding playfield background; 1:1 visual mapping of existing 700x600 simulation'})
    frame=Art(720,620)
    # Hole stays fully transparent. Four independent timber rails and tiny rivets.
    for x,y,w,h in [(0,0,720,10),(0,610,720,10),(0,10,10,600),(710,10,10,600)]:
        frame.box(x,y,w,h,INK)
    for x,y,w,h in [(2,2,716,6),(2,612,716,6),(2,10,6,600),(712,10,6,600)]:frame.box(x,y,w,h,WOOD)
    frame.box(8,2,704,2,'#F3D6A1');frame.box(8,612,704,2,'#F3D6A1');frame.box(2,10,2,600,'#F3D6A1');frame.box(712,10,2,600,'#F3D6A1')
    for x in range(72,700,84):
        frame.box(x,4,2,3,'#B38F63');frame.box(x+22,615,28,2,'#B38F63')
    for y in range(76,600,84):
        frame.box(4,y,3,2,'#B38F63');frame.box(715,y+12,2,22,'#B38F63')
    for x,y in [(5,5),(714,5),(5,614),(714,614)]:
        frame.box(x-2,y-2,4,4,INK);frame.box(x-1,y-1,2,2,GOLD)
    frame.save(out,'arena_wood_frame')
    entries.append({'id':'arena_wood_frame','png':'arena_wood_frame.png','svg':'arena_wood_frame.svg','size':[720,620],'anchor':[10,10],'transparent_interior':[10,10,700,600],'ui_position':[190,80],'purpose':'outside-only decorative rails; never added as collision geometry'})
    corner=Art(64,64)
    corner.poly([(6,6),(48,6),(48,16),(24,16),(24,24),(16,24),(16,48),(6,48)],INK)
    corner.poly([(10,10),(44,10),(44,12),(20,12),(20,20),(12,20),(12,44),(10,44)],GOLD)
    corner.box(10,10,8,8,CORAL);corner.box(12,12,4,4,'#F6B894');corner.save(out,'corner_inlay')
    entries.append({'id':'corner_inlay','png':'corner_inlay.png','svg':'corner_inlay.svg','size':[64,64],'anchor':[0,0],'purpose':'optional flat decorative inlay outside the playable interior; rotate by 90deg for other corners'})
    surround=Art(1100,780);surround.box(0,0,1100,780,'#E8D8B8')
    for y in range(20,780,40):
        surround.box(0,y,1100,2,'#E2D1AF')
    surround.box(0,0,1100,6,INK);surround.box(0,774,1100,6,INK)
    surround.save(out,'screen_surround')
    entries.append({'id':'screen_surround','png':'screen_surround.png','svg':'screen_surround.svg','size':[1100,780],'anchor':[0,0],'opaque':True,'purpose':'outer composition backdrop only; UI and arena are separate layers'})
    (out/'manifest.json').write_text(json.dumps({'version':'R02-remake-env-1','original_new_remake':True,'no_external_art_inputs':True,'usage_class':'independent_production_exports','source':'build_environment_vfx.py supplied in delivery source directory; run --output in a new empty directory','review_only':'preview/environment_composition.png is a separately composited reference, not a production texture','assets':entries},ensure_ascii=False,indent=2)+'\n')

def fx_cloud(i):
    a=Art(128,80);cloud(a,64,39,i);return a

def fx_transfer(i):
    a=Art(128,128);r=[12,20,30,40,48,52][i];alpha=[255,255,235,205,155,75][i]
    ring(a,64,64,r,r//2,CYAN,4,alpha);ring(a,64,64,r-6,max(4,r//2-5),WHITE,2,alpha)
    for j in range(4):
        ang=j*math.pi/2+i*.16;x=int(64+math.cos(ang)*(r+6));y=int(64+math.sin(ang)*(r+6))
        diamond(a,x,y,4 if i<3 else 2,GOLD,alpha)
    if i<3:a.poly([(60,44),(69,44),(65,57),(74,57),(57,80),(61,64),(54,64)],INK,alpha)
    return a

def fx_lightning(i):
    a=Art(128,192);alpha=[255,255,245,210,130,40][i]
    # Local strike, never a full-screen flash; first frame already contacts target.
    shift=[0,4,-2,2,0,-2][i]
    bolt=[(59+shift,8),(78+shift,8),(65+shift,55),(87+shift,55),(61+shift,108),(76+shift,108),(56,172),(61,122),(43+shift,122),(59+shift,72),(42+shift,72)]
    a.poly(bolt,INK,alpha)
    a.poly([(62+shift,12),(73+shift,12),(60+shift,60),(79+shift,60),(55+shift,113),(68+shift,113),(57,158),(64,118),(49+shift,118),(64+shift,66),(49+shift,66)],GOLD,alpha)
    a.line([(67+shift,16),(55+shift,68),(68+shift,68),(51+shift,119)],WHITE,3,alpha)
    if i<4:
        a.line([(55+shift,94),(28,108),(34,126),(18,140)],CYAN,3,alpha)
        a.line([(71+shift,64),(100,82),(91,100),(110,114)],CYAN,3,alpha)
    radius=[12,22,30,38,44,46][i]
    ring(a,60,172,radius,8,GOLD,3,alpha)
    for x,y in [(30,162),(88,170),(44,184),(78,182)]:diamond(a,x+(i%2)*2,y,3,WHITE,alpha)
    return a

def fx_protected(i):
    a=Art(128,128);alpha=[255,255,235,195,135,55][i];r=[18,24,30,36,40,44][i]
    ring(a,64,70,r,r,CYAN,4,alpha);ring(a,64,70,r-5,r-5,WHITE,2,alpha)
    a.poly([(62,20),(72,20),(66,42),(77,42),(59,64),(63,48),(55,48)],GOLD,alpha)
    # Downward grounding chevrons distinguish protection from damaging strike.
    for yy in [84,98]:
        a.line([(56,yy),(64,yy+8),(72,yy)],CYAN,3,alpha)
    for x in [26,98]:diamond(a,x,68,3,GOLD,alpha)
    return a

def fx_forge(i):
    a=Art(96,96);alpha=[255,255,240,190,110,30][i]
    origin=(48,68)
    for j,(vx,vy) in enumerate([(-4,-5),(-2,-7),(1,-8),(4,-5),(5,-2),(-5,-2)]):
        x=48+vx*(i+1);y=68+vy*(i+1)+i*i
        a.line([(x-vx//2,y-vy//2),(x,y)],CORAL,3,alpha)
        diamond(a,x,y,3 if i<3 else 2,GOLD,alpha)
        if j%2==0:a.box(x,y,2,2,WHITE,alpha)
    if i<2:diamond(a,*origin,8-i*3,WHITE,alpha)
    return a

def fx_temper(i):
    a=Art(96,96)
    # Peripheral aura leaves the character and its feet readable.
    ring(a,48,68,30+(i%3)*2,12,PURPLE,3,180)
    ring(a,48,68,24,8,GOLD,2,140)
    for j in range(4):
        ang=(j/4+i/12)*math.tau;x=int(48+math.cos(ang)*32);y=int(47+math.sin(ang)*24)
        diamond(a,x,y,3,GOLD if j%2 else CORAL,230)
    return a

def fx_hit(i):
    a=Art(96,96);alpha=[255,255,235,185,110,35][i]
    r=[12,18,24,30,34,38][i]
    if i<4:
        diamond(a,48,48,10-i*2,INK,alpha)
        diamond(a,48,48,7-i,WHITE,alpha)
    for j in range(8):
        ang=j*math.pi/4
        inner=r-8;x1=int(48+math.cos(ang)*inner);y1=int(48+math.sin(ang)*inner)
        x2=int(48+math.cos(ang)*r);y2=int(48+math.sin(ang)*r)
        a.line([(x1,y1),(x2,y2)],GOLD if j%2 else CYAN,4 if i<3 else 2,alpha)
        if j%2:diamond(a,x2,y2,2,WHITE,alpha)
    return a

def make_vfx():
    out=BASE/'vfx';out.mkdir(parents=True,exist_ok=True);entries=[]
    specs=[
        ('cloud_idle',fx_cloud,[160]*6,True,[64,68],'Follow actual cloud_holder at a head-top attachment point; numeric countdown remains live UI','none'),
        ('cloud_transfer',fx_transfer,[40,50,60,60,70,80],False,[64,64],'Once at actual collision-based transfer endpoints; do not delay cloud ownership','duck_cloud_transfer.wav'),
        ('lightning_strike',fx_lightning,[30,40,45,45,50,60],False,[64,172],'At actual unprotected strike_position from strike result, frame0 immediate','duck_lightning.wav'),
        ('rod_protected',fx_protected,[35,45,50,55,60,70],False,[64,64],'Only actual protected strike branch; center at consumed rod/protected target as confirmed by event','none; no new protection WAV supplied'),
        ('forge_sparks',fx_forge,[35,45,50,55,60,70],False,[48,68],'At small-hammer/anvil visual contact frame while forge state is active; never blade damage','anvil_forge.wav'),
        ('temper_aura',fx_temper,[100]*6,True,[48,56],'While actual temper_left > 0; stop immediately on expiry or collision consumption','none'),
        ('broad_sword_hit',fx_hit,[30,40,45,50,55,65],False,[48,48],'Actual effective broad-sword collision contact, frame0 immediate; no anticipation or delayed damage','sword_wide_hit.wav'),
    ]
    for name,fn,ms,loop,anchor,event,audio in specs:
        frames=[];frameinfo=[]
        for i in range(6):
            a=fn(i);a.save(out/'frames'/name,f'{name}_{i:02}')
            im=a.render();frames.append(im)
            frameinfo.append({'index':i,'png':f'frames/{name}/{name}_{i:02}.png','source_svg':f'frames/{name}/{name}_{i:02}.svg','duration_ms':ms[i],'alpha_bbox':im.getbbox(),'sha256_pixels':hashlib.sha256(im.tobytes()).hexdigest()})
        strip=Image.new('RGBA',(frames[0].width*6,frames[0].height),(0,0,0,0))
        for i,im in enumerate(frames):strip.paste(im,(i*im.width,0))
        strip.save(out/(name+'_strip.png'))
        frames[0].save(out/(name+'.png'))
        entries.append({'id':name,'frame_size':list(frames[0].size),'frame_count':6,'distinct_pixel_frames':len({x['sha256_pixels'] for x in frameinfo}),'strip':name+'_strip.png','static_entry':name+'.png','strip_order':'left-to-right; zero gap; row0','loop':loop,'duration_ms':ms,'total_duration_ms':sum(ms),'anchor':anchor,'facing':'screen-space / nondirectional','sampling':'nearest; integer pixel scales recommended','trigger':event,'audio_event':audio,'cleanup':'Pause with simulation, do not advance while paused; remove on end/restart/scene switch; loop effects stop on state end','physics':'Visual only. Dimensions, rings and bounds do not define hitboxes, reach, timing, protection radius or damage.','frames':frameinfo})
    (out/'manifest.json').write_text(json.dumps({'version':'R02-remake-vfx-1','original_new_remake':True,'usage_class':'independent_transparent_production_exports','source':'Per-frame SVG; build_environment_vfx.py supplied in delivery source directory, run --output in a new empty directory','review_only':'preview/vfx_contact_sheet.png is a separately composited reference, not a production strip','assets':entries},ensure_ascii=False,indent=2)+'\n')

def previews():
    # Fresh contact sheet for review only. It is never an input to the assets.
    env=Image.open(BASE/'environment/arena_floor.png').convert('RGBA')
    preview=Image.new('RGBA',(720,620),(0,0,0,0));preview.paste(env,(10,10));preview.alpha_composite(Image.open(BASE/'environment/arena_wood_frame.png'))
    (BASE/'preview').mkdir(exist_ok=True)
    preview.save(BASE/'preview/environment_composition.png')
    sheet=Image.new('RGBA',(6*160,7*204),(247,235,205,255))
    names=['cloud_idle','cloud_transfer','lightning_strike','rod_protected','forge_sparks','temper_aura','broad_sword_hit']
    d=ImageDraw.Draw(sheet)
    for row,name in enumerate(names):
        for i in range(6):
            im=Image.open(BASE/'vfx/frames'/name/f'{name}_{i:02}.png')
            sheet.alpha_composite(im,(i*160+(160-im.width)//2,row*204))
        d.text((4,row*204+192),name,fill=color(INK))
    sheet.save(BASE/'preview/vfx_contact_sheet.png')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True,help='New empty export directory outside any Godot game checkout')
    args=parser.parse_args()
    BASE=args.output.expanduser().resolve()
    if any((p/'project.godot').is_file() for p in [BASE,*BASE.parents]):
        parser.error('Refusing to export inside an existing Godot project. Use a new external export directory.')
    if BASE.exists() and any(BASE.iterdir()):
        parser.error('Output directory must be empty; existing files will not be replaced.')
    BASE.mkdir(parents=True,exist_ok=True)
    make_environment();make_vfx();previews()
    print('Created original environment assets and 7 VFX sequences: 42 logical frames, 41 distinct pixel images (cloud loop returns to a repeated pose).')
