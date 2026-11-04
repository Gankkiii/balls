import json,sys
from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[2];BASE=(sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:8034').rstrip('/');URL=BASE+'/source/navigation/'
JS='''() => [...document.querySelectorAll('button,input,select,summary')].filter(e=>!e.id.startsWith('nav-') && !e.closest('.heading .index')).map(e=>{const s=getComputedStyle(e),r=e.getBoundingClientRect();let clip={x:Math.max(0,r.x),y:Math.max(92,r.y),right:Math.min(1600,r.right),bottom:Math.min(900,r.bottom)};for(let p=e.parentElement;p;p=p.parentElement){let a=getComputedStyle(p);if(/hidden|auto|scroll/.test(a.overflow+a.overflowX+a.overflowY)){let q=p.getBoundingClientRect();clip.x=Math.max(clip.x,q.x);clip.y=Math.max(clip.y,q.y);clip.right=Math.min(clip.right,q.right);clip.bottom=Math.min(clip.bottom,q.bottom);}}return {id:e.id||null,action:e.dataset.act||null,tag:e.tagName,text:(e.getAttribute('aria-label')||e.textContent||e.placeholder||'').trim().slice(0,140),rect:[r.x,r.y,r.width,r.height].map(x=>Math.round(x*1000)/1000),clip_rect:[clip.x,clip.y,Math.max(0,clip.right-clip.x),Math.max(0,clip.bottom-clip.y)].map(x=>Math.round(x*1000)/1000),displayed:s.display!=='none'&&s.visibility!=='hidden'&&r.width>0&&r.height>0,disabled:!!e.disabled};}).filter(x=>x.displayed && x.rect[1]+x.rect[3]>92)'''
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True);page=b.new_page(viewport={'width':1600,'height':900});rows=[]
 for name in ['arena','story','storage','hatch']:
  page.goto(URL+name+'.html',wait_until='networkidle')
  if page.locator('iframe.reference').count():f=page.locator('iframe.reference').element_handle().content_frame()
  else:
   page.goto(BASE+'/source/r06/'+name+'/prototype.html',wait_until='networkidle');f=page.main_frame
  f.wait_for_load_state('networkidle');page.wait_for_timeout(60)
  def capture(state):rows.append({'page':name,'state':state,'coordinate_space':'1600x900 content; common nav measured separately; clips exclude covered original header','controls':f.evaluate(JS)})
  capture('main_ready_sample')
  if name=='hatch':
   for state,action in [('pick-mother','pick-mother'),('pick-father','pick-father'),('detail-mother','detail-mother'),('detail-father','detail-father'),('rules','rules'),('preview','preview'),('confirm','confirm'),('success_reference','success'),('failure_reference','failure'),('missing','missing')]:
    f.evaluate("HatchDemo.go('reset')");f.evaluate('(a)=>HatchDemo.go(a)',action);page.wait_for_timeout(35);capture(state)
 b.close()
j={'status':'SOURCE_MEASURED_GEOMETRY_NOT_GODOT_TOUCH_QA','canvas':[1600,900],'source':'Warehouse/Hatch final-derived browser frames; Arena/Story original R06 control geometry unchanged by header-only combination; Chromium1600x900','common_nav':'metadata/navigation.json','states':rows,'limitations':['These are source-measured control boxes, not a completed Godot UI or mobile-dp specification.','Final reference hides review debug selectors and artificial result buttons. Actual confirmation execution button and real result binding must be implemented as specified in INTEGRATION.md.','Offscreen list rows have zero/partial clip_rect and require scrolling; full source rect is not the hit area outside a ScrollContainer.','Underlying child navigation excluded; always use the single confirmed top navigation owner.']}
(ROOT/'metadata/hit_regions.json').write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n');print('Measured',len(rows),'source states;',sum(len(x['controls'])for x in rows),'control instances')
