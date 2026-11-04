#!/usr/bin/env python3
"""Assemble same-origin R06 review prototypes; never publishes or modifies game."""
import argparse,json,hashlib,shutil
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--source',default='/workspace/shared/R06-ui-review');p.add_argument('--repo',default='/workspace/ball_art_review');a=p.parse_args();src=Path(a.source).resolve();repo=Path(a.repo).resolve();out=repo/'docs/r06';sources=repo/'sources/r06';out.mkdir(parents=True,exist_ok=True);sources.mkdir(parents=True,exist_ok=True)
PUBLIC={'.png','.svg','.gif','.jpg','.jpeg','.webp','.json','.md','.txt','.html','.js','.css'};SOURCE=PUBLIC|{'.py','.gd'}
def cp(s,d):
 if s.resolve()!=d.resolve():d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(s,d)
def rel_asset(base,v):
 if not isinstance(v,str)or not v:return None
 q=(base/v).resolve()
 if not q.is_relative_to(src)or not q.is_file():return None
 return 'r06/'+q.relative_to(src).as_posix()
for s in src.rglob('*'):
 if not s.is_file()or s.is_symlink()or any(x.startswith('.')for x in s.relative_to(src).parts):continue
 rel=s.relative_to(src)
 if s.suffix.lower()in SOURCE:cp(s,sources/rel)
 if s.suffix.lower()in PUBLIC and not any(x in {'source','sources','web'}for x in rel.parts):cp(s,out/rel)
# Restore the review shell too, so one build command reconstructs the site.
for shell in ['index.html','r06/app.js','r06/style.css']:
 s=src/'web/site'/shell
 if s.is_file():cp(s,repo/'docs'/shell)
pages=[]
for id,name in [('arena','竞技场'),('storage','仓库'),('hatch','孵蛋'),('story','主线')]:
 base=src/id;rp=base/'review.json';review=json.loads(rp.read_text())if rp.exists()else{}
 prototype=review.get('prototype')or('source.html'if id=='storage'else'prototype.html')
 if isinstance(prototype,dict):prototype=prototype.get('file',prototype.get('path','prototype.html'))
 image=review.get('image')or review.get('main_image')or'main.png';media=[]
 if isinstance(image,dict):image=image.get('file',image.get('image','main.png'))
 for m in review.get('media',review.get('detail_images',[])):
  m={'image':m,'title':'状态预览'}if isinstance(m,str)else dict(m)
  im=rel_asset(base,m.get('image',m.get('file')))
  if im:media.append({'image':im,'title':m.get('title',m.get('name','状态预览'))})
 pages.append({'id':id,'name':name,'prototype':rel_asset(base,prototype),'image':rel_asset(base,image),'media':media,'review':rel_asset(base,'review.json')})
(out/'review-data.json').write_text(json.dumps({'version':'R06','status':'selected_directions_interaction_demo','pages':pages},ensure_ascii=False,indent=2)+'\n')
(out/'PUBLIC_SCOPE.md').write_text('# R06 公开范围\n\n四个指定方向的原创网页原型、效果图与状态快览、人工 fixtures、事实依据与检查记录。原型仅示意浏览器交互，不运行游戏战斗/真实随机孵化，不写存档、不联网提交。后代仅内存单示例，刷新还原。未进行游戏手机布局适配、游戏接入或真机验证。只保留本轮导航，旧文件历史不删除；不包含 R05 手机重排图、选择草稿、私密配置、凭据、字体二进制或接入包。源码位于仓库 sources/r06。\n')
files=[]
for s in sorted(out.rglob('*')):
 if s.is_file()and s.name!='PUBLIC_MANIFEST.json':
  b=s.read_bytes();files.append({'path':s.relative_to(repo/'docs').as_posix(),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
(out/'PUBLIC_MANIFEST.json').write_text(json.dumps({'version':'R06','files':files},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'pages':[{p['id']:bool(p['prototype'])}for p in pages],'files':len(files)}))
