'use strict';
const data=window.REVIEW_DATA, $=id=>document.getElementById(id);
const tabs=[...document.querySelectorAll('[role=tab]')];
function list(id,values){$(id).replaceChildren(...values.map(value=>{const e=document.createElement('li');e.textContent=value;return e}));}
function select(id){
 const level=data.ui.levels.find(x=>x.id===id); if(!level)return;
 tabs.forEach(t=>{const active=t.dataset.level===id;t.setAttribute('aria-selected',String(active));t.tabIndex=active?0:-1});
 $('ui-panel').setAttribute('aria-labelledby','tab-'+id);
 $('ui-image').src='../ui/'+level.file; $('ui-image').alt=level.alt||level.name+'手机界面概念图';$('ui-zoom').href='../ui/'+level.file;
 $('ui-name').textContent=level.name;$('density-number').textContent='LEVEL 0'+(data.ui.levels.indexOf(level)+1);
 $('text-count').textContent='画面可见字符 '+level.text_characters+' · 其中游戏信息 '+level.text_characters_gameplay;
 list('shown',level.shown);list('hidden',level.hidden);
}
tabs.forEach((tab,i)=>{tab.addEventListener('click',()=>select(tab.dataset.level));tab.addEventListener('keydown',e=>{let n=i;if(e.key==='ArrowRight')n=(i+1)%4;else if(e.key==='ArrowLeft')n=(i+3)%4;else if(e.key==='Home')n=0;else if(e.key==='End')n=3;else return;e.preventDefault();tabs[n].focus();select(tabs[n].dataset.level)})});
select('minimal');
$('count-rule').textContent='同口径统计：包含可见汉字、字母、数字及标点，不计空白与图标。第一轮上限：全部字符 '+data.ui.r01_text_cap+'；游戏信息 '+data.ui.r01_gameplay_text_cap+'。四档均在上限以内。';
const variant={shared:'通用事件',short_sword:'短剑候选',broad_sword:'宽剑候选'};
data.audio.forEach(item=>{const card=document.createElement('article');card.className='sound';const title=document.createElement('h3');title.textContent=item.title;const note=document.createElement('p');note.textContent=(variant[item.variant]||item.variant)+' · '+item.duration_s.toFixed(2)+' 秒';const audio=document.createElement('audio');audio.controls=true;audio.preload='metadata';audio.src='../audio/'+item.file;audio.setAttribute('aria-label',item.title+'试听');const download=document.createElement('a');download.href=audio.getAttribute('src');download.textContent='独立 WAV';download.className='small';card.append(title,note,audio,download);$('sounds').append(card)});
const labels={rabbit_demo:'兔子短剑',rabbit_broad_demo:'兔子宽剑',duck_demo:'鸭子雷倒计时'},events={forge_contact:'锻造接触',sword_swing:'挥剑',sword_contact:'剑命中',countdown_tick:'倒计时',countdown_final:'末秒提示',lightning_strike:'落雷'};
Object.entries(data.events.clips).forEach(([key,rows])=>{const section=document.createElement('div');section.className='event-group';const h=document.createElement('h4');h.textContent=labels[key]||key;const ul=document.createElement('ul');rows.forEach(row=>{const li=document.createElement('li');li.textContent=row.time_s.toFixed(2)+' 秒 · '+(events[row.event]||row.event)+' · '+row.audio;ul.append(li)});section.append(h,ul);$('event-summary').append(section)});
const media=[...document.querySelectorAll('audio,video')];
media.forEach(item=>item.addEventListener('play',()=>media.forEach(other=>{if(other!==item)other.pause()})));
$('stop-all').addEventListener('click',()=>media.forEach(item=>{item.pause();item.currentTime=0}));
document.addEventListener('visibilitychange',()=>{if(document.hidden)media.forEach(item=>item.pause())});
