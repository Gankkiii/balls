from pathlib import Path
from playwright.sync_api import sync_playwright
import json,datetime
OUT=Path('/workspace/shared/R06-ui-review/qa');records=[];disabled=[]
with sync_playwright()as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True);page=b.new_page(viewport={'width':1800,'height':1150});errors=[];page.on('pageerror',lambda e:errors.append(str(e)));page.goto('http://127.0.0.1:8033/');page.wait_for_function("document.documentElement.dataset.reviewReady==='true'")
 def hatch():
  page.locator('#pages [data-page=hatch]').click();page.wait_for_function("reviewState.active==='hatch'");frame=page.locator('iframe[data-page=hatch]').element_handle().content_frame();frame.wait_for_function('window.HatchDemo!==undefined');return frame
 h=hatch();screens=h.locator('#screen-index option').evaluate_all('(a)=>a.map(e=>e.value)')
 for screen in screens:
  h=hatch();h.evaluate('HatchDemo.reset()');h.locator('#screen-index').select_option(screen);items=h.locator('button[data-act]').evaluate_all('(a)=>a.filter(e=>e.getBoundingClientRect().width>0&&e.getBoundingClientRect().height>0).map(e=>({act:e.dataset.act,id:e.dataset.id||null,text:e.innerText,disabled:e.disabled}))')
  for item in items:
   if item['disabled']:disabled.append({'screen':screen,**item});continue
   h=hatch();h.evaluate('HatchDemo.reset()');h.locator('#screen-index').select_option(screen);a=item['act'];sel='button[data-act="'+a+'"]'+('[data-id="'+item['id']+'"]'if item['id']else'');h.locator(sel).click();state=h.evaluate('HatchDemo.getState()')
   if a.startswith('nav-')or a=='storage-child':
    dest=a[4:]if a.startswith('nav-')else'storage';page.wait_for_function('(id)=>reviewState.active===id',arg=dest);observed='parent:'+page.evaluate('reviewState.active');expected='parent:'+dest
   else:
    expected='pick'if a.startswith('pick-')or a=='candidate'else'detail'if a.startswith('detail-')else'workbench'if a in ['reset','use-parent','workbench']or a.startswith('tie-')else a
    observed=state['page'];assert observed==expected,(screen,item,state)
    if a=='candidate':assert state['candidate']==item['id']
    if a.startswith('tie-'):assert state['tie']==int(a[-1])
   assert observed==expected,(screen,item,observed,expected);records.append({'screen':screen,**item,'expected':expected,'observed':observed})
 assert not errors,errors;out={'result':'PASS','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'screens':screens,'enabled_visible_buttons_clicked':len(records),'records':records,'disabled_buttons_expected_not_clicked':disabled,'method':'Set each UI state through visible state directory, then click every visible enabled button. Reset API used only to isolate preconditions between cases; no game or save access.','javascript_errors':errors,'game_binding':'NOT_RUN'};(OUT/'button-coverage.json').write_text(json.dumps(out,ensure_ascii=False,indent=2));b.close();print('ALL VISIBLE BUTTONS PASS',len(records),'across',len(screens),'states')
