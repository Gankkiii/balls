from pathlib import Path
from urllib.parse import urlparse,urljoin
from playwright.sync_api import sync_playwright
import json,hashlib,datetime
ROOT=Path('/workspace/ball_art_review/docs');OUT=Path('/workspace/shared/R06-ui-review/qa');BASE='http://127.0.0.1:8033/'
with sync_playwright()as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True);page=b.new_page(viewport={'width':1800,'height':1150});errors=[];bad=[];writes=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('response',lambda r:bad.append([r.url,r.status])if r.status>=400 else None);page.on('request',lambda r:writes.append([r.url,r.method])if r.method not in ['GET','HEAD']else None);page.goto(BASE);page.wait_for_function("document.documentElement.dataset.reviewReady==='true'");data=page.request.get(BASE+'r06/review-data.json').json();assert len(data['pages'])==4
 def nav(id):
  page.locator('#pages [data-page="'+id+'"]').click();page.wait_for_function('(id)=>reviewState.active===id',arg=id);page.wait_for_function('(id)=>{const f=document.querySelector("iframe[data-page="+id+"]");return f&&f.dataset.loaded==="true"}',arg=id);return page.locator('iframe[data-page="'+id+'"]').element_handle().content_frame()
 a=nav('arena');a.wait_for_function('document.querySelectorAll("button").length>8')
 for id in ['left-info','right-info','info']:
  a.locator('[id="'+id+'"]').click();assert a.locator('#scene').get_attribute('src')=='info.png';a.locator('#close').click();assert a.locator('#scene').get_attribute('src')=='main.png'
 for id in ['pause','pause','1×','2×','3×','replay','new_seed','sound_on','sound_on']:
  a.locator('[id="'+id+'"]').click();assert a.locator('#toast').is_visible()
 for id in ['arena','story','storage','hatch']:
  a=nav('arena');a.locator('#nav-'+id).click();page.wait_for_function('(id)=>reviewState.active===id',arg=id)
 s=nav('story');s.wait_for_function('document.querySelector("#entry-d")!==null')
 for key in 'abcd':
  s.locator('#entry-'+key).click();assert s.locator('#scene').get_attribute('src')=='states/'+key+'_main.png';s.locator('#view').click();assert s.locator('#scene').get_attribute('src')=='states/'+key+'_detail.png';assert s.locator('#pending').is_disabled();s.locator('#return').click();assert s.locator('#scene').get_attribute('src')=='states/'+key+'_main.png';s.locator('#view').click();s.locator('#close').click();assert s.locator('#scene').get_attribute('src')=='states/'+key+'_main.png'
 s.locator('#search').fill('不存在');assert s.locator('[id^="entry-"]:enabled').count()==0;s.locator('#search').fill('');assert s.locator('[id^="entry-"]:enabled').count()==4
 for id in ['help-top','help-bottom']:
  s.locator('#'+id).click();assert s.locator('#shade').is_visible();s.locator('#helpbox button').click();assert not s.locator('#shade').is_visible()
 s.locator('#header-back').click();page.wait_for_function("reviewState.active==='arena'")
 for id in ['arena','story','storage','hatch']:
  s=nav('story');s.locator('#nav-'+id).click();page.wait_for_function('(id)=>reviewState.active===id',arg=id)
 # Four-frame caching: all src remain same-origin and only allowed page IDs.
 frames=page.locator('iframe').evaluate_all('(a)=>a.map(f=>({id:f.dataset.page,src:f.src}))');assert len(frames)==4 and {f['id']for f in frames}=={'arena','story','storage','hatch'};assert all(urlparse(f['src']).netloc=='127.0.0.1:8033'for f in frames)
 media=[];urls=set()
 for pg in data['pages']:
  nav(pg['id']);page.locator('#screenshots').evaluate('(e)=>e.open=true');images=page.locator('#state-gallery img');assert images.count()==1+len(pg['media'])
  for img in images.all():
   img.evaluate('(e)=>e.loading="eager"');page.wait_for_function('(e)=>e.complete&&e.naturalWidth===1600&&e.naturalHeight===900',arg=img.element_handle());src=img.get_attribute('src');assert 'phone'not in src;media.append(src);urls.add(urljoin(BASE,src))
  assert pg['image']and pg['prototype'];urls.add(urljoin(BASE,pg['prototype']));urls.add(urljoin(BASE,pg['review']))
 assert len(media)==20 and len(set(media))==20
 page.locator('#view-image').click();page.locator('#image-size').click();assert page.locator('#image-dialog img').evaluate('(e)=>e.getBoundingClientRect().width')==1600;page.keyboard.press('Escape');assert not page.locator('#image-dialog').evaluate('(e)=>e.open')
 # Original dimensions can be scrolled; no mobile-adaptation claim.
 page.set_viewport_size({'width':1280,'height':900});page.locator('#size-toggle').click();native=page.locator('#workspace').evaluate('(e)=>({width:e.clientWidth,scroll:e.scrollWidth})');assert native['scroll']>native['width'];page.locator('#size-toggle').click();fit=page.locator('#workspace').evaluate('(e)=>({width:e.clientWidth,height:e.clientHeight,scrollWidth:e.scrollWidth,scrollHeight:e.scrollHeight})');page.screenshot(path=str(OUT/'shell-fit-browser.png'))
 for url in page.locator('[src],a[href],link[href]').evaluate_all('(a)=>a.map(e=>e.src||e.href).filter(Boolean)'):urls.add(url)
 checked=[]
 for url in sorted(urls):
  u=urlparse(url)
  if u.netloc!='127.0.0.1:8033'or(u.fragment and u.path=='/'):continue
  res=page.request.get(url);assert res.ok,(url,res.status);checked.append(url)
 # Query entry then child navigation: reload follows current hash, not stale query.
 page.goto(BASE+'?page=hatch&size=native');page.wait_for_function("document.documentElement.dataset.reviewReady==='true'&&reviewState.active==='hatch'");h=page.locator('iframe[data-page=hatch]').element_handle().content_frame();h.wait_for_function('window.HatchDemo!==undefined');h.locator('[data-act=nav-storage]').click();page.wait_for_function("reviewState.active==='storage'");assert page.evaluate('location.hash')=='#storage';page.reload();page.wait_for_function("document.documentElement.dataset.reviewReady==='true'&&reviewState.active==='storage'");st=page.locator('iframe[data-page=storage]').element_handle().content_frame();st.wait_for_function('window.r06Storage!==undefined');assert st.evaluate('r06Storage.getState().count')==20
 assert not errors,errors;assert not bad,bad;assert not writes,writes
 hashes={x:hashlib.sha256((ROOT/x).read_bytes()).hexdigest()for x in ['index.html','r06/app.js','r06/style.css','r06/review-data.json','r06/arena/prototype.html','r06/story/prototype.html']};out={'result':'PASS','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'Arena/Story button destinations, shell query/hash, complete20 state media, same-origin frames, basic viewing; not game/mobile adaptation','arena_controls_and_three_info_entries':True,'story_four_entries_detail_close_return':True,'story_search_empty_clear_and_help':True,'both_pages_all4_navigation':True,'frames':frames,'state_media':media,'no_new_phone_media':True,'original_image_1600':True,'native_workspace':native,'fit_workspace':fit,'query_hash_reload_priority':True,'reload_resets_memory_child':True,'static_targets':checked,'javascript_errors':errors,'http_errors':bad,'mutating_network_requests':writes,'hashes':hashes,'game_binding':'NOT_RUN','real_device':'NOT_RUN'};(OUT/'browser-shell-media.json').write_text(json.dumps(out,ensure_ascii=False,indent=2));b.close();print('SHELL/MEDIA PASS20 images;',len(checked),'targets; fit',fit)
