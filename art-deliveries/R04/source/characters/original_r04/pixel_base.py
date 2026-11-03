"""Accepted R03 geometry retained as editable source for R04 selected review; no image inputs."""
from pathlib import Path
import json, math, hashlib, argparse
from PIL import Image, ImageDraw, ImageFont

INK='#243746';CREAM='#FFF3DA';CORAL='#EA7E65';METAL='#B1D2D3';GOLD='#EFC65B';PURPLE='#B89ACF'
GREEN='#83B77D';DARKGREEN='#427863';LEAF='#B5D49A';WOOD='#B58C65';STRAW='#E7C77D';CYAN='#86C8C0';MUTED='#657880'
FONT='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'
ROOT=None
def rgba(c,a=255):return tuple(int(c[i:i+2],16) for i in [1,3,5])+(a,)
class Art:
 def __init__(self):self.ops=[]
 def box(self,x,y,w,h,c,a=255):self.ops.append(('r',[x,y,w,h],c,a))
 def poly(self,p,c,a=255):self.ops.append(('p',p,c,a))
 def line(self,p,c,w=1,a=255):self.ops.append(('l',p,c,a,w))
 def image(self):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
  for typ,g,c,a,*v in self.ops:
   if typ=='r':x,y,w,h=g;d.rectangle((x,y,x+w-1,y+h-1),fill=rgba(c,a))
   elif typ=='p':d.polygon(g,fill=rgba(c,a))
   else:d.line(g,fill=rgba(c,a),width=v[0])
  return im.resize((96,96),Image.Resampling.NEAREST)
 def svg(self):
  out=['<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 48 48" shape-rendering="crispEdges">']
  for t,g,c,a,*v in self.ops:
   op=f' opacity="{a/255:.6f}"' if a<255 else ''
   if t=='r':x,y,w,h=g;out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"{op}/>')
   elif t=='p':out.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in g)+f'" fill="{c}"{op}/>')
   else:out.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in g)+f'" fill="none" stroke="{c}" stroke-width="{v[0]}"{op}/>')
  return '\n'.join(out+['</svg>'])
 def save(self,folder,name):
  folder.mkdir(parents=True,exist_ok=True);self.image().save(folder/(name+'.png'));(folder/(name+'.svg')).write_text(self.svg())
def octa(a,x,y,w,h,c):
 k=min(3,w//4,h//4);a.poly([(x+k,y),(x+w-k-1,y),(x+w-1,y+k),(x+w-1,y+h-k-1),(x+w-k-1,y+h-1),(x+k,y+h-1),(x,y+h-k-1),(x,y+k)],c)
def eye(a,x,y,blink=False):
 a.box(x,y,3,1 if blink else 4,INK)
 if not blink:a.box(x,y,1,1,CREAM)
def star(a,x,y,c=GOLD):a.poly([(x,y-3),(x+1,y-1),(x+3,y),(x+1,y+1),(x,y+3),(x-1,y+1),(x-3,y),(x-1,y-1)],c)
def cactus(v='a',state='idle',phase=0):
 a=Art();a.box(15,39,22,2,INK,35)
 if v=='a':
  octa(a,17,9,15,31,INK);octa(a,19,11,11,27,GREEN);a.box(20,14,2,20,LEAF);a.box(27,14,2,22,DARKGREEN)
  a.poly([(10,17),(15,17),(15,26),(19,26),(19,32),(9,32),(7,30),(7,20),(10,20)],INK)
  a.poly([(10,20),(13,20),(13,28),(18,28),(18,30),(10,30)],GREEN)
  a.poly([(31,23),(35,23),(35,14),(39,14),(41,17),(41,29),(38,32),(30,32)],INK)
  a.poly([(32,26),(37,26),(37,17),(39,17),(39,28),(37,30),(32,30)],GREEN)
  for x,y in [(17,15),(32,17),(8,22),(15,34),(30,33),(37,13)]:a.line([(x,y),(x-2,y-2)],CREAM)
  a.box(21,6,3,5,CORAL);a.box(18,8,9,2,CORAL);a.box(22,8,2,2,GOLD)
  eye(a,24,21,state=='blink');a.box(25,28,3,1,INK)
 else:
  for x,y,w,h in [(6,15,13,16),(29,9,13,19),(13,22,24,18)]:octa(a,x,y,w,h,INK);octa(a,x+2,y+2,w-4,h-4,GREEN)
  a.box(9,18,2,8,LEAF);a.box(32,12,2,10,LEAF);a.box(17,26,3,10,LEAF);a.box(30,28,3,8,DARKGREEN)
  for x,y in [(5,20),(12,14),(36,8),(42,17),(13,34),(36,34)]:a.line([(x,y),(x+2,y-2)],CREAM)
  a.box(23,19,3,5,CORAL);a.box(20,21,9,2,CORAL);a.box(24,21,2,2,GOLD)
  eye(a,25,28,state=='blink');a.box(25,35,4,1,INK)
 if state=='thorns':
  for x,y in [(6,38),(11,9),(37,38),(42,31),(34,5)]:a.poly([(x,y-3),(x+2,y+2),(x-2,y+2)],STRAW);a.box(x,y-2,1,4,INK)
 if state=='regrow':
  for x in [10,37]:a.line([(x-2,42),(x,39),(x+2,42)],LEAF,1)
 return a
def turtle(v='a',state='idle',phase=0):
 a=Art();a.box(9,37,33,3,INK,30)
 if state=='hidden':return shell(v,phase if phase else 0)
 if v=='a':
  for x in [12,26]:octa(a,x,31,7,9,INK);a.box(x+2,33,3,5,GREEN)
  octa(a,9,21,26,15,INK);octa(a,11,23,22,11,GREEN);a.box(14,25,16,3,LEAF)
  a.box(29,18,8,12,INK);a.box(31,20,5,8,GREEN);octa(a,33,12,12,13,INK);octa(a,35,14,8,9,LEAF)
  eye(a,40,16,state=='blink');a.box(40,22,4,1,INK);a.poly([(9,27),(3,31),(9,32)],GREEN)
 else:
  for x,y in [(5,29),(27,31),(8,16),(28,18)]:a.poly([(x,y),(x+12,y+1),(x+9,y+6),(x,y+5)],INK);a.box(x+2,y+2,6,2,GREEN)
  octa(a,10,17,25,20,INK);octa(a,12,19,21,16,GREEN);a.box(15,21,15,3,LEAF);a.box(14,32,16,2,DARKGREEN)
  octa(a,32,21,13,11,INK);octa(a,34,23,9,7,LEAF);eye(a,39,23,state=='blink');a.box(40,29,4,1,INK)
  a.poly([(11,24),(4,25),(9,29)],LEAF)
 return a
def shell(v='a',phase=0):
 a=Art()
 if v=='a':
  octa(a,7,12,34,27,INK);octa(a,9,14,30,23,DARKGREEN);octa(a,11,15,26,18,GREEN)
  a.poly([(24,15),(32,21),(30,30),(19,31),(14,22)],LEAF)
  for x,y in [(11,18),(34,18),(12,31),(35,31)]:a.line([(24,23),(x,y)],DARKGREEN,1)
  a.box(10,34,28,2,METAL)
 else:
  a.poly([(12,16),(34,16),(43,24),(39,36),(10,36),(5,25)],INK)
  a.poly([(13,18),(33,18),(40,25),(37,33),(12,33),(8,25)],GREEN)
  a.poly([(18,20),(29,20),(34,25),(30,31),(17,31),(13,25)],DARKGREEN)
  a.poly([(20,22),(27,22),(30,25),(27,29),(20,29),(17,25)],LEAF)
  for x in [10,33]:a.box(x,24,4,4,STRAW)
  a.box(11,34,26,1,METAL)
 if phase:
  for j in range(4):
   t=j*math.pi/2+phase*.65;x=int(24+math.cos(t)*12);y=int(25+math.sin(t)*9);a.box(x,y,3,2,GOLD)
 return a
def crab(v='a',state='idle',phase=0):
 a=Art();a.box(7,39,34,2,INK,30)
 for side in [-1,1]:
  for i in range(3):
   x=24+side*13;y=29+i*3;a.line([(x,y),(x+side*7,y+3),(x+side*9,y+1)],INK,2);a.line([(x,y-1),(x+side*7,y+2)],CORAL)
 if v=='a':
  octa(a,10,23,28,15,INK);octa(a,12,25,24,11,CORAL);a.box(14,26,19,3,'#F7AA88');a.box(15,34,18,2,'#C76860')
  for x in [16,29]:a.box(x,15,2,11,INK);a.box(x-1,15,5,5,CREAM);a.box(x+1,16,2,1 if state=='blink' else 3,INK)
  for x in [3,34]:
   a.poly([(x,11),(x+4,11),(x+4,19),(x+7,19),(x+7,11),(x+11,11),(x+11,23),(x+8,26),(x+3,26),(x,23)],INK)
   a.poly([(x+2,13),(x+3,13),(x+3,21),(x+8,21),(x+8,13),(x+9,13),(x+9,22),(x+7,24),(x+4,24),(x+2,22)],CORAL)
   a.box(x+1,12,3,4,METAL);a.box(x+7,12,3,4,METAL)
 else:
  octa(a,15,14,19,25,INK);octa(a,17,16,15,21,CORAL);a.box(19,18,11,3,'#F7AA88');a.box(19,34,11,2,'#C76860')
  a.box(14,12,22,5,INK);a.box(16,13,18,3,METAL)
  for x in [17,21,25,29]:a.box(x,6,2,10,INK);a.box(x,7,1,7,STRAW)
  a.box(14,5,21,3,INK);a.box(16,6,17,1,CORAL)
  for x in [7,34]:octa(a,x,22,9,10,INK);octa(a,x+1,24,7,6,CORAL);a.box(x+3,22,2,4,CREAM)
  for x in [20,28]:a.box(x,23,3,4,CREAM);a.box(x+1,24,2,1 if state=='blink' else 3,INK)
 if state=='ready':star(a,24,11 if v=='a' else 3,CYAN)
 return a
def nail(moving=False):
 a=Art();c=GOLD if moving else METAL
 a.poly([(16,13),(21,10),(29,18),(27,22),(20,16),(15,21),(12,18)],INK)
 a.poly([(17,14),(21,12),(27,18),(26,20),(20,15),(15,19),(14,18)],c)
 a.poly([(23,20),(27,22),(15,38),(12,39),(13,35)],INK);a.poly([(24,22),(25,23),(14,37),(14,35)],c)
 return a
def crow(v='a',state='idle',phase=0):
 a=Art();a.box(11,39,27,2,INK,30)
 for x in [19,30]:a.box(x,34,2,6,INK);a.box(x-2,39,6,1,GOLD)
 if v=='a':
  a.poly([(19,11),(29,9),(36,13),(36,23),(31,26),(31,36),(16,36),(12,29),(14,19)],INK)
  a.poly([(21,13),(28,11),(33,14),(33,22),(29,25),(29,33),(18,34),(15,28),(17,20)],PURPLE)
  a.poly([(18,20),(8,18),(6,22),(11,33),(20,30),(24,24)],'#5B587D')
  a.line([(11,22),(16,27),(14,30)],METAL)
  a.poly([(34,16),(45,20),(34,24)],INK);a.poly([(35,18),(42,20),(35,22)],GOLD)
  eye(a,29,15,state=='blink');a.box(24,29,3,3,'#D8C8DC')
 else:
  octa(a,12,14,26,24,INK);octa(a,14,16,22,20,PURPLE)
  a.poly([(13,21),(5,27),(9,36),(21,31),(24,22)],'#5B587D');a.poly([(30,22),(41,27),(39,35),(27,31)],'#5B587D')
  for x,y in [(9,29),(12,32),(34,30)]:a.line([(x,y),(x+3,y+1)],METAL)
  a.poly([(31,15),(42,18),(41,22),(32,25)],INK);a.poly([(33,17),(39,19),(33,22)],GOLD)
  a.box(19,10,4,6,INK);a.box(24,11,4,5,INK);eye(a,28,16,state=='blink');a.box(20,32,9,2,'#D8C8DC')
 if state=='feather':
  a.poly([(20,5),(27,2),(29,4),(24,11),(21,11)],CREAM);a.line([(22,12),(26,5)],INK)
 return a
def dummy(v='a',damaged=False):
 a=Art();a.box(22,23,3,19,INK);a.box(10,23,28,3,INK);a.box(12,24,24,1,WOOD)
 if v=='a':
  octa(a,17,13,14,13,INK);octa(a,19,15,10,9,STRAW);a.box(14,11,20,4,INK);a.box(19,7,10,5,STRAW)
  a.poly([(18,27),(29,27),(31,34),(16,34)],CORAL);a.box(20,19,2,2,INK);a.box(26,19,2,2,INK)
 else:
  octa(a,15,13,18,13,INK);octa(a,17,15,14,9,STRAW);a.box(19,9,12,4,INK);a.box(16,12,21,3,INK)
  a.poly([(16,26),(31,26),(33,35),(14,35)],METAL);a.box(18,28,5,4,CORAL);a.box(26,29,4,4,PURPLE)
  a.line([(20,18),(23,21),(20,21)],INK);a.box(28,18,2,2,INK)
 for x,y in [(9,22),(36,22),(17,34),(29,35)]:a.line([(x,y),(x-2,y+3)],STRAW)
 if damaged:a.line([(27,14),(23,19),(27,24),(23,29)],INK,2)
 return a
def feather():
 a=Art();a.poly([(16,35),(15,25),(22,14),(31,9),(35,12),(32,22),(24,31)],INK);a.poly([(18,31),(18,25),(24,16),(31,12),(32,14),(29,22),(23,28)],CREAM);a.line([(15,38),(29,17)],METAL,1);return a
