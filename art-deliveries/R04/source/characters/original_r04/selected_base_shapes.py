#!/usr/bin/env python3
"""R04 selected-shape helpers derived from the user's approved R03 silhouettes.
Original pixel geometry only; no old audition audio or game files are read/written.
The R04 builder calls only approved shapes; unused helper branches are not options.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,math,hashlib
ROOT=Path(__file__).resolve().parent.parent
P={'ink':'#243746','cream':'#FFF3DA','coral':'#EA7E65','orange':'#E8A05D','gold':'#F3CC68','mint':'#8CD7C0','mint_dark':'#539E95','mint_hi':'#CDF0D1','blue':'#8BCEDB','blue_hi':'#D5F0E8','blue_dark':'#5B93AD','purple':'#AE96C7','purple_hi':'#DFCEE8','wool':'#F3E4BD','wool_dark':'#CBBF99','face':'#65586E','metal':'#B1D2D3'}
class C:
 def __init__(self):self.im=Image.new('RGBA',(48,48));self.d=ImageDraw.Draw(self.im)
 def rect(self,b,col):
  x,y,r,b=map(round,b)
  if r>x and b>y:self.d.rectangle((x,y,r-1,b-1),fill=P.get(col,col))
 def poly(self,pts,col):self.d.polygon([(round(x),round(y)) for x,y in pts],fill=P.get(col,col))
 def ball(self,x,y,r,col):
  # Discrete octagonal mass, not smooth or antialiased.
  k=round(r*.65);self.poly([(x-k,y-r),(x+k,y-r),(x+r,y-k),(x+r,y+k),(x+k,y+r),(x-k,y+r),(x-r,y+k),(x-r,y-k)],col)
 def ring(self,x,y,r,col):
  for i in range(24):
   a=i*math.tau/24;self.rect((x+math.cos(a)*r,y+math.sin(a)*r,x+math.cos(a)*r+1,y+math.sin(a)*r+1),col)
 def save(self,p):
  p.parent.mkdir(parents=True,exist_ok=True);self.im.resize((96,96),Image.Resampling.NEAREST).save(p)
  runs=[]
  for y in range(48):
   x=0
   while x<48:
    col=self.im.getpixel((x,y));end=x+1
    while end<48 and self.im.getpixel((end,y))==col:end+=1
    if col[3]:runs.append(f'<rect x="{x}" y="{y}" width="{end-x}" height="1" fill="#{col[0]:02x}{col[1]:02x}{col[2]:02x}"/>')
    x=end
  p.with_suffix('.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 48 48" shape-rendering="crispEdges">'+''.join(runs)+'</svg>\n')

def eye(c,x,y):c.rect((x,y,x+2,y+3),'ink');c.rect((x,y,x+1,y+1),'cream')
def puff(c,v,s):
 r=[10,14,15,20][s];cx,cy=24,24
 if v=='a':
  for i in range(8):
   a=i*math.tau/8;c.ball(cx+math.cos(a)*(r-1),cy+math.sin(a)*(r-1),3,'ink');c.ball(cx+math.cos(a)*(r-1),cy+math.sin(a)*(r-1),1,'mint_hi')
  c.ball(cx,cy,r,'ink');c.ball(cx,cy,r-2,'mint');c.poly([(cx-r+3,cy+2),(cx-3,cy+r-3),(cx+r-3,cy+3),(cx+r-3,cy+r-5),(cx+2,cy+r-2),(cx-r+3,cy+r-5)],'mint_dark')
  c.rect((cx-r+5,cy-r+5,cx-1,cy-r+7),'mint_hi');eye(c,cx-5,cy-3);eye(c,cx+4,cy-3);c.rect((cx-1,cy+3,cx+2,cy+5),'ink')
 else:
  # Folded bladder has a tall diamond/segmented silhouette, not a recolour.
  c.poly([(cx,cy-r-1),(cx+r-3,cy-r+5),(cx+r,cy),(cx+r-3,cy+r-4),(cx,cy+r+1),(cx-r+3,cy+r-4),(cx-r,cy),(cx-r+3,cy-r+5)],'ink')
  c.poly([(cx,cy-r+1),(cx+r-5,cy-r+6),(cx+r-2,cy),(cx+r-5,cy+r-5),(cx,cy+r-1),(cx-r+5,cy+r-5),(cx-r+2,cy),(cx-r+5,cy-r+6)],'gold')
  c.poly([(cx-r+4,cy),(cx-2,cy-r+2),(cx-4,cy+r-3),(cx-r+5,cy+r-5)],'orange')
  c.poly([(cx+3,cy-r+3),(cx+r-4,cy-r+7),(cx+r-2,cy),(cx+4,cy+r-4)],'coral')
  c.rect((cx-1,cy-r+3,cx+1,cy-6),'cream');c.rect((cx-1,cy+7,cx+1,cy+r-2),'cream')
  eye(c,cx-5,cy-3);eye(c,cx+4,cy-3);c.rect((cx-2,cy+3,cx+3,cy+5),'ink')
 if s==3:
  for x,y in [(3,33),(6,37),(8,40)]:c.rect((x,y,x+3,y+2),'mint_hi' if v=='a' else 'cream')

def egg(c,x,y,big=False,armed=False,v='a'):
 rx=5 if not big else 8;ry=7 if not big else 10
 c.poly([(x-2,y-ry),(x+2,y-ry),(x+rx,y-2),(x+rx,y+ry-3),(x+rx-2,y+ry),(x-rx+2,y+ry),(x-rx,y+ry-3),(x-rx,y-2)],'ink')
 c.poly([(x-1,y-ry+2),(x+1,y-ry+2),(x+rx-2,y-2),(x+rx-2,y+ry-3),(x+rx-3,y+ry-2),(x-rx+3,y+ry-2),(x-rx+2,y+ry-3),(x-rx+2,y-2)],'coral' if armed else 'cream')
 if v=='a':c.rect((x-2,y-1,x,y+1),'orange');c.rect((x+1,y+3,x+3,y+5),'orange')
 else:c.rect((x-rx+2,y,x+rx-1,y+2),'gold');c.rect((x-1,y-4,x+1,y-1),'gold')
 if armed:c.ring(x,y,max(rx,ry)+3,'coral')
def chicken(c,v,s):
 squash=3 if s==2 else 0;b=1 if s==1 else 0
 if v=='a':
  c.poly([(11,27),(5,21),(7,32),(14,35)],'ink');c.poly([(10,27),(7,25),(9,31),(14,33)],'orange')
  c.ball(22,29+squash,12-squash//2,'ink');c.ball(22,28+squash,10-squash//2,'gold');c.ball(21,29+squash,6,'orange');c.ball(20,27+squash,4,'cream')
  hx,hy=29,18+squash
 else:
  # Upright hen, flared three-feather fan, long neck/visible legs.
  c.poly([(14,29),(7,16),(8,11),(12,15),(14,22),(13,12),(16,9),(19,22),(21,16),(24,17),(21,30)],'ink')
  c.poly([(14,26),(9,16),(10,15),(16,23),(15,13),(17,13),(19,26)],'coral')
  c.ball(22,28+squash,9,'ink');c.ball(22,27+squash,7,'cream');c.rect((27,15+squash,32,29+squash),'ink');c.rect((28,16+squash,31,27+squash),'gold');hx,hy=30,14+squash
  c.rect((18,36,20,41-b),'ink');c.rect((24,36,26,41+b),'ink');c.rect((17,40-b,22,42-b),'orange');c.rect((24,40+b,29,42+b),'orange')
 c.ball(hx,hy,7,'ink');c.ball(hx,hy,5,'cream');c.rect((hx-4,hy-9,hx+5,hy-6),'ink')
 if v=='a':
  for dx in [-3,0,3]:c.ball(hx+dx,hy-8,2,'coral')
 else:c.poly([(hx-4,hy-7),(hx-5,hy-12),(hx-1,hy-10),(hx+1,hy-13),(hx+4,hy-7)],'coral')
 c.poly([(hx+5,hy-1),(hx+10,hy+1),(hx+5,hy+3)],'ink');c.poly([(hx+6,hy),(hx+8,hy+1),(hx+6,hy+2)],'orange');eye(c,hx+1,hy-2);c.rect((hx+2,hy+5,hx+4,hy+8),'coral')
 if v=='a' and s!=2:
  c.rect((18,39,23,41),'orange');c.rect((27,39,32,41),'orange')
 if s==1:
  c.rect((5,37,10,38),'orange');c.rect((3,34,8,35),'orange')
 if s==2:egg(c,35,36,False,False,v)
 if s==3:egg(c,12,33,True,True,v)

def bubble(c,x,y,r,level=1,v='a'):
 c.ring(x,y,r,'blue_hi' if level==1 else 'blue');c.rect((x-r+2,y-r+2,x-r+4,y-r+3),'cream')
 if v=='b' and level>1:c.ring(x,y,r-2,'purple_hi')
def fish(c,v,s):
 if v=='a':
  c.poly([(15,24),(3,15),(5,23),(3,33),(15,29)],'ink');c.poly([(12,24),(6,19),(7,24),(6,29),(12,27)],'coral')
  c.poly([(14,17),(20,11),(27,11),(30,15),(23,19)],'ink');c.poly([(17,16),(21,13),(25,13),(27,15)],'blue_hi')
  c.poly([(14,18),(31,16),(38,20),(40,29),(33,35),(17,34),(12,29),(12,23)],'ink')
  c.poly([(16,20),(30,18),(36,21),(38,28),(32,33),(18,32),(14,28),(14,24)],'blue')
  c.poly([(18,28),(25,27),(28,30),(24,32),(19,31)],'blue_dark');c.rect((18,21,27,23),'blue_hi');eye(c,31,22)
  c.rect((37,26,41,29),'cream');c.rect((39,26,41,29),'ink')
 else:
  c.poly([(12,24),(5,19),(5,30),(12,28)],'ink');c.poly([(7,22),(11,24),(11,26),(7,27)],'coral')
  c.poly([(14,13),(31,13),(37,19),(37,33),(32,37),(15,37),(11,32),(11,19)],'ink')
  c.poly([(16,15),(30,15),(35,20),(35,32),(31,35),(17,35),(13,31),(13,20)],'gold')
  c.poly([(15,24),(20,26),(20,34),(17,34),(14,30)],'orange');c.rect((17,17,27,19),'cream')
  c.rect((33,25,42,30),'ink');c.rect((35,26,41,29),'blue_hi');eye(c,28,20)
  for x,y in [(19,22),(24,28),(28,32)]:c.rect((x,y,x+2,y+2),'coral')
 if s==1:bubble(c,43,17,3,1,v)
 if s==2:
  bubble(c,40,11,6,2,v);bubble(c,9,9,3,1,v);bubble(c,12,10,3,1,v)
 if s==3:
  for i in range(8):
   a=i*math.tau/8;bubble(c,24+math.cos(a)*20,24+math.sin(a)*20,2,1,v)

def sheep(c,v,s):
 if v=='a':
  for x,y in [(14,19),(23,15),(31,18),(33,27),(25,33),(16,32),(10,26)]:c.ball(x,y,8,'ink');c.ball(x,y,6,'wool')
  c.ball(21,25,12,'wool');c.rect((13,33,18,40),'ink');c.rect((25,34,30,40),'ink')
  c.ball(32,28,7,'ink');c.ball(32,28,5,'face');c.rect((32,26,35,29),'cream');c.rect((34,26,35,29),'ink');c.poly([(33,21),(35,17),(39,18),(36,23)],'ink')
  c.rect((14,19,18,21),'cream');c.rect((23,15,27,17),'cream')
 else:
  # Low blocky fleece with layered lock ridges, ears differ from cloud silhouette.
  c.poly([(9,16),(15,12),(32,12),(36,17),(37,30),(32,35),(12,35),(7,30),(7,20)],'ink')
  c.poly([(11,18),(16,14),(31,14),(34,18),(35,29),(31,33),(13,33),(9,29),(9,20)],'wool')
  for x in [12,19,26]:
   c.poly([(x,17),(x+4,17),(x+4,21),(x,21),(x,26),(x+4,26),(x+4,29)],'wool_dark');c.rect((x+1,17,x+4,18),'cream')
  c.rect((12,34,17,39),'ink');c.rect((28,34,33,39),'ink')
  c.poly([(28,21),(36,20),(40,24),(39,32),(32,34),(28,30)],'ink');c.poly([(30,23),(35,22),(38,25),(37,30),(33,32),(30,29)],'face')
  c.poly([(31,21),(28,16),(29,13),(33,17),(34,22)],'ink');c.rect((35,24,38,27),'cream');c.rect((37,24,38,27),'ink')
 if s>0:
  for x,y in [(9,13),(34,10)]:c.poly([(x,y),(x+3,y),(x+1,y+3),(x+4,y+3),(x,y+7),(x+1,y+4),(x-1,y+4)],'gold')
 if s==2:
  # One independent wool patch, no face/limbs/new sheep.
  c.ball(8,38,5,'ink');c.ball(8,38,3,'wool');c.rect((6,36,9,37),'cream')
 if s==3:
  # Single discharge path only, no duplicated damage beams.
  c.poly([(38,24),(43,20),(40,26),(45,23),(40,31),(42,26),(38,29)],'gold')
