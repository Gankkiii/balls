from pathlib import Path
from playwright.sync_api import sync_playwright
import json,hashlib
root=Path('/workspace/shared/R06-ui-review/storage');html=(root/'source.html').read_text();child=json.loads((root/'source/demo_child.json').read_text());checks=[]
def check(name,condition):
 assert condition,name
 checks.append(name)
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox']);ctx=browser.new_context(viewport={'width':1600,'height':900});harness='<iframe id="frame" src="/storage" style="width:1600px;height:900px;border:0"></iframe><script>window.navs=[];window.addEventListener("message",e=>window.navs.push(e.data));</script>'
 ctx.route('http://r06.test/**',lambda route:route.fulfill(status=200,content_type='text/html',body=html if route.request.url.endswith('/storage') else harness))
 page=ctx.new_page();page.goto('http://r06.test/parent');frame=page.frames[1];frame.wait_for_selector('#statrows tr')
 state=frame.evaluate('window.r06Storage.getState()');check('default mother fish, 20 shared fixture individuals',state['selected']==4 and state['count']==20)
 check('all 6 rows / 4 source columns visible',frame.locator('#statrows tr').count()==6 and frame.locator('thead th').count()==5)
 check('no collapsed default / toggle',not frame.get_by_text('收起',exact=False).count() and frame.locator('#statrows').is_visible())
 frame.locator('#next').click();check('next individual becomes male fish',frame.evaluate('window.r06Storage.getState().current.sex')==1)
 frame.locator('#prev').click();check('previous returns selected mother',frame.evaluate('window.r06Storage.getState().selected')==4)
 frame.locator('#individual').select_option('7');check('shared father sample ranks3/3',frame.evaluate('window.r06Storage.getState().current.ranks')==[3,3])
 frame.locator('#individual').select_option('19');check('last fixed example boundary disabled',frame.locator('#next').is_disabled())
 frame.locator('#explain').click();check('attribute explanation opens',frame.locator('#info').evaluate('(e)=>e.classList.contains("open")'));frame.locator('#close-info').click();check('explanation closes without collapsing matrix',not frame.locator('#info').evaluate('(e)=>e.classList.contains("open")') and frame.locator('#statrows').is_visible())
 frame.locator('[data-nav=arena]').click();page.wait_for_function('window.navs.some(x=>x.type==="r06-nav"&&x.page==="arena")');check('same-origin nav postMessage delivered',True)
 page.evaluate('(c)=>document.getElementById("frame").contentWindow.postMessage({type:"r06-demo-child",child:c},location.origin)',child);frame.wait_for_function('window.r06Storage.getState().count===21');check('parent child-message selects one in-memory child21',frame.evaluate('window.r06Storage.getState().current.number')==21)
 child['number']=22;child['ranks']=[3,1];page.evaluate('(c)=>document.getElementById("frame").contentWindow.postMessage({type:"r06-demo-child",child:c},location.origin)',child);frame.wait_for_function('window.r06Storage.getState().current.ranks[1]===1');check('repeated demo replaces sole child rather than adding',frame.evaluate('window.r06Storage.getState().count')==21 and frame.evaluate('window.r06Storage.getState().current.number')==21)
 check('no browser persistence APIs',all(x not in html for x in ['localStorage','sessionStorage','indexedDB','fetch(']))
 check('full matrix above footer',frame.locator('table').evaluate('(e)=>e.getBoundingClientRect().bottom')<854)
 browser.close()
(root/'qa.json').write_text(json.dumps({'automated_ui_checks_passed':len(checks),'failed':0,'checks':checks,'scope':'browser prototype only; Godot/game/device NOT RUN','source_sha256':hashlib.sha256((root/'source.html').read_bytes()).hexdigest()},ensure_ascii=False,indent=2)+'\n');print(len(checks),'passed')
