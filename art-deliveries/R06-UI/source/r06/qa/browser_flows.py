from pathlib import Path
from playwright.sync_api import sync_playwright
import json,hashlib,datetime
BASE='http://127.0.0.1:8033/';ROOT=Path('/workspace/ball_art_review/docs');OUT=Path('/workspace/shared/R06-ui-review/qa');fixtures=json.load(open('/workspace/shared/R06-ui-review/fixtures.json'));people={p['id']:p for p in fixtures['people']}
with sync_playwright()as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True);ctx=b.new_context(viewport={'width':1800,'height':1150});page=ctx.new_page();errors=[];http=[];writes=[];visited=[];details=[]
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('response',lambda r:http.append([r.url,r.status])if r.status>=400 else None);page.on('request',lambda r:writes.append([r.url,r.method])if r.method not in ['GET','HEAD']else None)
 page.goto(BASE,wait_until='networkidle');page.wait_for_function("document.documentElement.dataset.reviewReady==='true'");assert page.locator('#choices,#template,.choice-button').count()==0
 def topnav(id):
  page.locator('#pages [data-page="'+id+'"]').click();page.wait_for_function('(id)=>window.reviewState.active===id',arg=id);page.wait_for_function('(id)=>{const f=document.querySelector("iframe[data-page="+id+"]");return f&&f.dataset.loaded==="true"}',arg=id);return page.locator('iframe[data-page="'+id+'"]').element_handle().content_frame()
 storage=topnav('storage');storage.wait_for_function('window.r06Storage!==undefined');assert storage.evaluate('r06Storage.getState().count')==20
 def storage_table(c):
  rows=storage.locator('#statrows tr');assert rows.count()==6
  for i in range(6):assert rows.nth(i).inner_text().split()==[fixtures['stats'][i],'待定',str(c['innate'][i]),str(c['training'][i]),'待定']
  assert storage.locator('table').is_visible();assert '其他特性' in storage.locator('#othertraits').inner_text();assert '其他技能' in storage.locator('#otherskills').inner_text()
 assert storage.locator('button').filter(has_text='收起').count()==0
 for i,c in enumerate(fixtures['people']):
  storage.locator('#individual').select_option(str(i));assert storage.evaluate('r06Storage.getState().current.id')==c['id'];storage_table(c)
 storage.locator('#explain').click();assert 'open' in storage.locator('#info').get_attribute('class');storage.locator('#close-info').click();assert 'open' not in storage.locator('#info').get_attribute('class');storage_table(fixtures['people'][-1]);storage.locator('#prev').click();storage.locator('#next').click();assert storage.evaluate('r06Storage.getState().selected')==19
 h=topnav('hatch');h.wait_for_function('window.HatchDemo!==undefined')
 def state():return h.evaluate('HatchDemo.getState()')
 def act(a,id=None):
  selector='[data-act="'+a+'"]'+('[data-id="'+id+'"]'if id else '');h.locator(selector).click();visited.append(a+(':'+id if id else ''));return state()
 def unchanged(s):
  now=state();assert all(now[k]==s[k]for k in ['mother','father','tie']),[s,now]
 def full_table(c):
  t=h.locator('.full-detail');assert t.locator('thead th').all_text_contents()==['属性','种族基础','先天','后天','最终'];rows=t.locator('tbody tr');assert rows.count()==6
  for i in range(6):assert rows.nth(i).inner_text().split()==[fixtures['stats'][i],'待定',str(c['innate'][i]),str(c['training'][i]),'待定']
  txt=t.inner_text();assert c['name']in txt and 'Lv.0'in txt and '其他特性' in txt and '其他技能'in txt
  for i in c['skills']:assert c['skill_names'][i]in txt
  for i in [2,3,4]:assert c['skill_names'][i]in txt
 act('reset');assert state()['mother']==fixtures['default_mother'] and state()['father']==fixtures['default_father'];act('tie-1');selected=state()
 for role in ['mother','father']:
  act('detail-'+role);full_table(people[selected[role]]);act('workbench');unchanged(selected)
  act('pick-'+role);buttons=h.locator('[data-act=candidate]');ids=buttons.evaluate_all('(a)=>a.map(e=>e.dataset.id)');expected=[x['id']for x in fixtures['people']if x['sex']==(0 if role=='mother'else 1)];assert set(ids)==set(expected) and len(ids)==10
  for id in expected:act('candidate',id);full_table(people[id]);details.append(id)
  act('workbench');unchanged(selected)
 # Reusing the SAME mother must not silently overwrite the chosen tied skill.
 act('pick-mother');act('candidate',selected['mother']);act('use-parent');unchanged(selected)
 act('pick-father');act('candidate',selected['father']);act('use-parent');unchanged(selected)
 # A non-tied mother automatically inherits her unique highest selected skill.
 act('pick-mother');act('candidate','chicken_f');act('use-parent');assert h.locator('[data-act^="tie-"]').count()==0;assert '大炸弹' in h.locator('.only-read').inner_text();assert state()['mother']=='chicken_f'
 for action in ['rules','preview']:
  act(action);assert state()['page']==action;act('workbench');assert state()['mother']=='chicken_f'
 act('confirm');act('workbench');assert state()['mother']=='chicken_f'
 act('pick-mother');act('candidate',fixtures['default_mother']);act('use-parent');act('tie-1');selected=state()
 act('rules');rules=h.locator('#app').inner_text();assert all(x in rules for x in ['1%','+10','+1～+9','9 : 8 : 7 : 6 : 5 : 4 : 3 : 2 : 1','未设计','不执行随机']);act('preview');assert '八方泡泡' in h.locator('#app').inner_text();act('confirm');act('workbench');unchanged(selected)
 # Every failure return preserves parents/identity choice and adds no object.
 for destination in ['preview','workbench','confirm']:
  if state()['page']!='workbench':act('workbench')
  act('confirm');act('failure');assert state()['child']is None;assert storage.evaluate('r06Storage.getState().count')==20;act(destination);unchanged(selected)
 if state()['page']!='confirm':act('confirm')
 act('success');child=state()['child'];m=people[state()['mother']];f=people[state()['father']];assert child['species']==m['species']and child['trait']==m['trait']and child['level']==0 and child['skills'][0]==m['skills'][1]and child['skills'][0]!=child['skills'][1];assert child['training']==[0]*6 and child['number']==21
 assert all(min(x,y)<=v<=max(x,y)for x,y,v in zip(m['innate'],f['innate'],child['innate']));assert min(max(m['ranks']),max(f['ranks']))<=child['ranks'][0]<=max(max(m['ranks']),max(f['ranks']));assert 1<=child['ranks'][1]<=9
 assert h.locator('table tbody tr').count()==6;assert '非实抽 / 非真实写盘'in h.locator('#app').inner_text();h.locator('#app').screenshot(path=str(OUT/'hatch-success-browser.png'))
 act('storage-child');page.wait_for_function("reviewState.active==='storage'");storage=page.locator('iframe[data-page=storage]').element_handle().content_frame();page.wait_for_timeout(100);st=storage.evaluate('r06Storage.getState()');assert st['count']==21 and st['current']['number']==21 and st['current']['skills']==child['skills']and st['current']['innate']==child['innate'];storage_table(child)
 h=topnav('hatch');assert state()['page']=='success' and state()['child']==child;act('confirm');act('failure');act('confirm');act('success');act('storage-child');page.wait_for_function("reviewState.active==='storage'");assert storage.evaluate('r06Storage.getState().count')==21
 # Replacement, rather than unlimited accumulation, when a different mock is viewed.
 h=topnav('hatch');act('workbench');act('pick-mother');act('candidate','chicken_f');act('use-parent');act('confirm');act('success');replacement=state()['child'];assert replacement['species']==1 and replacement['skills'][0]==1;act('storage-child');page.wait_for_function("reviewState.active==='storage'");page.wait_for_timeout(80);st=storage.evaluate('r06Storage.getState()');assert st['count']==21 and st['current']['species']==1
 h=topnav('hatch');h.locator('#screen-index').select_option('missing');assert state()['mother']is None and state()['father']is None;assert h.locator('[data-act=confirm],[data-act=success]').count()==0;assert h.locator('[data-act=pick-mother]').count()==1 and h.locator('[data-act=pick-father]').count()==1;act('rules');assert h.locator('[data-act=preview]').is_disabled();act('workbench');act('pick-mother');act('candidate','bubble_fish_f');act('use-parent');assert state()['father']is None and h.locator('[data-act=confirm]').count()==0;act('pick-father');act('candidate','electric_sheep_m');act('use-parent');assert h.locator('[data-act=confirm]').count()==1;act('reset')
 # Parent navigation accepts only loaded iframe source, same origin and fixed IDs.
 active=page.evaluate('reviewState.active');page.evaluate("window.postMessage({type:'r06-nav',page:'story'},location.origin)");page.wait_for_timeout(50);assert page.evaluate('reviewState.active')==active
 h.evaluate("parent.postMessage({type:'r06-nav',page:'https://example.invalid/'},location.origin)");page.wait_for_timeout(50);assert page.evaluate('reviewState.active')==active
 h.evaluate("parent.postMessage({type:'not-r06',page:'story'},location.origin)");page.wait_for_timeout(50);assert page.evaluate('reviewState.active')==active
 page.evaluate("window.dispatchEvent(new MessageEvent('message',{origin:'https://example.invalid',source:document.querySelector('iframe[data-page=hatch]').contentWindow,data:{type:'r06-nav',page:'story'}}))");assert page.evaluate('reviewState.active')==active
 # Valid iframe navigation and retained business selection on return.
 for id in ['arena','story','storage','hatch']:
  act('nav-'+id);page.wait_for_function('(id)=>reviewState.active===id',arg=id);h=topnav('hatch');assert state()['mother']==fixtures['default_mother']
 assert page.evaluate('localStorage.length')==0 and page.evaluate('sessionStorage.length')==0
 # Basic viewing/scrolling only, explicitly not a phone layout adaptation check.
 page.set_viewport_size({'width':390,'height':844});page.locator('#size-toggle').click();z=page.locator('#workspace').evaluate('(e)=>({client:e.clientWidth,scroll:e.scrollWidth})');assert z['scroll']>z['client'];page.locator('#workspace').evaluate('(e)=>e.scrollLeft=500');assert page.locator('#workspace').evaluate('(e)=>e.scrollLeft>0');page.set_viewport_size({'width':1800,'height':1150})
 assert not errors,errors;assert not http,http;assert not writes,writes
 hashes={x:hashlib.sha256((ROOT/x).read_bytes()).hexdigest()for x in ['index.html','r06/app.js','r06/hatch/app.js','r06/hatch/style.css','r06/storage/source.html']}
 report={'result':'PASS','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'Hatch/storage and shell business flow, before final metadata/media manifest; no game or player-save interaction','all20_parent_full_details':details,'actions_clicked':visited,'same_mother_preserves_tie':True,'non_tied_mother_read_only_highest':True,'cancel_and_failure_preserve_selection':True,'mock_child':child,'replacement_child':replacement,'single21_memory_object':True,'storage_all20_full_matrix':True,'storage_no_collapsed_route':True,'foreign_origin_source_type_and_page_rejected':True,'valid_iframe_navigation':True,'no_local_or_session_storage_writes':True,'basic_native_scroll':z,'javascript_errors':errors,'http_errors':http,'mutating_network_requests':writes,'hashes':hashes,'real_device':'NOT_RUN','game_binding':'NOT_RUN'};(OUT/'browser-flows.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));b.close();print('R06 BUSINESS PASS20 details;',len(visited),'button actions')
