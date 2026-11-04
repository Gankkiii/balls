from pathlib import Path
import json,subprocess,base64,html
ROOT=Path(__file__).resolve().parent
BASE='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>R06 {title} · 纯UI示意</title><style>html,body{{margin:0;background:#dfe2d4;font-family:"Noto Sans CJK SC",sans-serif}}#stage{{width:1600px;height:900px;position:relative;transform-origin:top left;overflow:hidden}}#scene{{position:absolute;inset:0;width:1600px;height:900px}}button,input{{position:absolute;box-sizing:border-box;font:600 22px "Noto Sans CJK SC",sans-serif}}button{{border:0;background:transparent;cursor:pointer;color:#243746}}button:hover{{outline:4px solid #398a79;outline-offset:-4px;background:#67afc922}}button:focus-visible{{outline:5px solid #e4b86d;outline-offset:-5px}}button.on{{box-shadow:inset 0 0 0 5px #398a79;background:#A6CFC1!important}}button:disabled{{cursor:default}}.common{{border:3px solid #243746}}#toast{{position:absolute;left:480px;top:100px;max-width:650px;padding:12px 22px;background:#fff8e8;border:3px solid #243746;font-size:20px;display:none;z-index:12}}#disclaimer{{position:absolute;left:22px;top:104px;font-size:13px;color:#6d7c78;pointer-events:none}}.cover{{position:absolute;background:#f3efdfbb;pointer-events:none}}#close{{z-index:10}}#shade{{position:absolute;inset:100px 0 96px;background:#213c4566;z-index:15;display:none}}#helpbox{{position:absolute;left:410px;top:240px;width:780px;padding:30px;background:#fff8e8;border:4px solid #283e45;line-height:1.8}}#helpbox button{{position:static;background:#398a79;color:#fff8e8;padding:12px 24px}}#helpbox h2{{margin:0}}#helpbox p{{font-size:23px}}#search{{background:#e4e7dc;border:0;color:#283e45;padding:8px 16px;outline:0}}</style><main id="stage"><img id="scene" src="main.png" alt="{title}方向细化效果图"><div id="toast" role="status"></div><div id="disclaimer">纯UI示意 · 非游戏运行</div><div id="shade"><section id="helpbox"><h2>页面说明</h2><p id="helptext"></p><button onclick="document.getElementById('shade').style.display='none'">关闭</button></section></div></main><script>
const stage=document.getElementById('stage'),scene=document.getElementById('scene');function scale(){{let s=Math.min(innerWidth/1600,innerHeight/900);stage.style.transform=`scale(${{s}})`;document.body.style.height=(900*s)+'px'}}addEventListener('resize',scale);scale();function toast(t){{let a=document.getElementById('toast');a.textContent=t;a.style.display='block';clearTimeout(window.tt);window.tt=setTimeout(()=>a.style.display='none',2600)}}function button(id,label,x,y,w,h,fn){{let b=document.createElement('button');b.id=id;b.title=label;b.setAttribute('aria-label',label);Object.assign(b.style,{{left:x+'px',top:y+'px',width:w+'px',height:h+'px'}});b.onclick=fn;stage.appendChild(b);return b}}function nav(page){{parent.postMessage({{type:'r06-nav',page}},'*');toast('切换页面：'+{{arena:'竞技场',story:'主线',storage:'仓库',hatch:'孵蛋'}}[page]+'（评审导航）')}}function help(t){{document.getElementById('helptext').textContent=t;document.getElementById('shade').style.display='block'}}
{script}
</script></html>'''
def render(page,name,text):
 p=ROOT/page/(name+'.svg');p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text);subprocess.run(['inkscape',str(p),'-o',str(p.with_suffix('.png'))],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
for page in ['arena','story']:
 for name in (['main','info'] if page=='arena' else ['main','detail']):
  text=(ROOT/page/'source'/(name+'.svg')).read_text().replace('概念 · 示例数据','方向细化 · 示例数据')
  render(page,name,text)
navs=['arena','story','storage','hatch']
script='let modal=false,paused=false,muted=false,rate=1;function showInfo(v){modal=v;scene.src=v?"info.png":"main.png";document.getElementById("close").style.display=v?"block":"none";document.querySelectorAll(".common").forEach(b=>b.disabled=v)};'
for n,page in enumerate(navs):script+=f'button("nav-{page}","{page}",{48+n*137},28,124,48,()=>nav("{page}"));'
ks=['pause','1×','2×','3×','replay','new_seed','sound_on','info'];labels=['暂停/继续','1倍速','2倍速','3倍速','重看同局','新随机局','声音开关','查看信息']
for j,k in enumerate(ks):
 action=("paused=!paused;document.getElementById('pause').textContent=paused?'▶':'';document.getElementById('pause').style.background=paused?'#F6EDD9':'transparent';toast(paused?'已暂停（仅UI状态）':'继续（仅UI状态）')" if j==0 else f"rate={j};document.querySelectorAll('.rate').forEach(b=>b.classList.remove('on'));document.getElementById('{k}').classList.add('on');toast('{j}×（仅按钮状态，画面不运行）')" if j<4 else "toast('重看同局：seed3103（仅操作反馈，不运行战斗）')" if j==4 else "toast('新局：已演示按钮反馈，不生成随机战斗')" if j==5 else "muted=!muted;document.getElementById('sound_on').textContent=muted?'×':'';document.getElementById('sound_on').style.background=muted?'#F6EDD9':'transparent';toast(muted?'已静音（无实际音频）':'声音开启（无实际音频）')" if j==6 else 'showInfo(true)')
 script+=f'button({json.dumps(k)},{json.dumps(labels[j])},{550+j*64},811,54,54,()=>{{{action}}}).className="common'+(' rate' if 0<j<4 else '')+'";'
script+='document.querySelectorAll(".rate").forEach((b,i)=>{b.textContent=(i+1)+"×";b.style.background="#F6EDD9"});document.getElementById("1×").classList.add("on");button("left-info","鱼信息",259,699,40,40,()=>showInfo(true));button("right-info","羊信息",1295,699,40,40,()=>showInfo(true));button("close","关闭信息",995,278,54,54,()=>showInfo(false)).style.display="none";'
(ROOT/'arena/prototype.html').write_text(BASE.format(title='竞技场B',script=script))
# Four placeholder archive selections: same accepted D layout, no invented content.
for n,key in enumerate('ABCD'):
 for name in ['main','detail']:
  s=(ROOT/'story/source'/(name+'.svg')).read_text();s=s.replace('地点 A',f'地点 {key}')
  for j in range(4):
   y=291+j*111;s=s.replace(f'x="119" y="{y}" width="295" height="84" fill="'+('#398a79' if j==0 else '#e6e8da')+'"',f'x="119" y="{y}" width="295" height="84" fill="'+('#398a79' if j==n else '#e6e8da')+'"')
  # Restore row labels after broad stage-title replacement.
  for j,ch in enumerate('ABCD'):
   y=291+j*111+37;import re
   s=re.sub(r'(<text x="140" y="'+str(y)+r'"[^>]*>)地点 [ABCD](</text>)',r'\g<1>地点 '+ch+r'\2',s)
  for j in range(4):
   for y,col in [(328+j*111,'#fff8e8' if j==n else '#283e45'),(358+j*111,'#d5eadd' if j==n else '#6d7c78')]:
    s=re.sub(r'(<text x="140" y="'+str(y)+r'"[^>]*fill=")[^"]+("[^>]*>)',r'\g<1>'+col+r'\2',s)
   y=321+j*111;s=re.sub(r'(<circle cx="87" cy="'+str(y)+r'"[^>]*fill=")[^"]+("[^>]*>)',r'\g<1>'+('#398a79' if j==n else '#c4cdbb')+r'\2',s)
  render('story',f'states/{key.lower()}_{name}',s)
script='let selected="a",detail=false;function update(){scene.src="states/"+selected+"_"+(detail?"detail":"main")+".png";document.querySelectorAll(".list").forEach(b=>b.disabled=detail);document.getElementById("view").style.display=detail?"none":"block";document.getElementById("return").style.display=detail?"block":"none";document.getElementById("close").style.display=detail?"block":"none"}function openDetail(){detail=true;update()}function back(){detail=false;update()};'
for n,page in enumerate(navs):script+=f'button("nav-{page}","{page}",{445+n*228},806,208,84,()=>nav("{page}"));'
script+='button("header-back","返回竞技场",32,8,96,84,()=>nav("arena"));'
for n,key in enumerate('abcd'):script+=f'button("entry-{key}","地点{key.upper()}结构条目",119,{291+n*111},295,84,()=>{{selected="{key}";update();toast("地点{key.upper()}：结构占位，未开始主线")}}).className="list";'
script+='button("view","查看档案",1190,601,332,84,openDetail);button("return","返回档案",430,545,345,84,back);button("close","关闭详情",1115,252,64,64,back);button("pending","内容待定",800,545,365,84,()=>toast("内容与玩法尚未设计"));document.getElementById("pending").disabled=true;document.getElementById("pending").style.display="none";'
# Pending is an intentionally disabled placeholder, not an active dead button.
script+='let oldUpdate=update;update=function(){oldUpdate();let search=document.getElementById("search");if(search)search.disabled=detail;document.getElementById("pending").style.display=detail?"block":"none"};'
script+='for(let [id,x,y] of [["help-top",1490,22],["help-bottom",1424,817]])button(id,"说明",x,y,64,64,()=>help("档案与舞台仅是信息结构占位。条目不表示关卡、解锁或进度，不开始战斗，不提供奖励。搜索、查看、返回与四页导航均为评审UI示意。"));'
script+='let input=document.createElement("input");input.id="search";input.type="search";input.placeholder="地点 / 章节";input.setAttribute("aria-label","搜索档案占位条目");Object.assign(input.style,{left:"109px",top:"210px",width:"302px",height:"48px"});stage.appendChild(input);input.oninput=()=>{let found=0;[..."abcd"].forEach(k=>{let b=document.getElementById("entry-"+k),ok=("地点 "+k).toLowerCase().includes(input.value.toLowerCase());b.style.background=ok?"transparent":"#f3efdfdd";b.disabled=!ok;found+=ok});toast(found?"找到 "+found+" 个占位条目":"没有匹配条目；清空搜索可返回")};update();'
(ROOT/'story/prototype.html').write_text(BASE.format(title='主线D',script=script))
for page,chosen,title,detail in [('arena','B','竞技场 · 双侧状态卡','info'),('story','D','主线 · 档案与舞台','detail')]:
 meta={'page':page,'selected_direction':chosen,'status':'direction_refinement_not_game','title':title,'image':'main.png','source':'main.svg','prototype':'prototype.html','canvas':[1600,900],'detail_images':[{'image':detail+'.png','source':detail+'.svg','title':'信息展开与关闭' if page=='arena' else '档案详情与返回'}],'limits':['纯UI交互示意，非真实战斗/真实游戏导航','不包含手机适配或A-D选择','游戏接入、设备交互与性能未验证'],'navigation_message':{'type':'r06-nav','page':'arena|story|storage|hatch'}}
 (ROOT/page/'review.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
print('R06 arena/story built')
