#!/usr/bin/env python3
"""R04 original sound-direction synthesis, no audio/image file inputs.

Animal calls use jittered glottal excitation and formant resonators. Water uses
short damped cavity impulses; materials use distinct modal/granular/noise models.
These are synthetic cartoon auditions, not animal recordings or approved SFX.
Python 3, numpy, scipy. Writes only the explicit output directory.
"""
from pathlib import Path
import argparse, json, hashlib, wave
import numpy as np
from scipy import signal

SR=48000
RNG=np.random.default_rng(2026110304)

def clock(d): return np.arange(round(d*SR))/SR
def norm(x,peak=.73):
    x=np.asarray(x,dtype=float);x=x-np.mean(x)
    return x*peak/max(np.max(np.abs(x)),1e-10)
def fade(x,attack=.006,release=.025):
    x=np.array(x,copy=True);a=min(len(x),round(attack*SR));r=min(len(x),round(release*SR))
    if a:x[:a]*=np.linspace(0,1,a)
    if r:x[-r:]*=np.linspace(1,0,r)
    return x
def noise(d,lo=0,hi=6000):
    n=RNG.normal(size=round(d*SR))
    if lo and hi: sos=signal.butter(3,[lo,hi],btype='band',fs=SR,output='sos')
    else:sos=signal.butter(3,hi or lo,btype='low' if hi else 'high',fs=SR,output='sos')
    return signal.sosfilt(sos,n)
def mix(length,*parts):
    out=np.zeros(round(length*SR))
    for start,x,gain in parts:
        i=round(start*SR);n=min(len(x),len(out)-i)
        if n>0:out[i:i+n]+=x[:n]*gain
    return out
def voice(d,f0,formants,breath=.08,rasp=.0,vibrato=0):
    t=clock(d);f=np.broadcast_to(np.asarray(f0),len(t)).copy()
    jitter=signal.sosfilt(signal.butter(2,24,fs=SR,output='sos'),RNG.normal(size=len(t)))
    f*=1+.045*norm(jitter,.6)+vibrato*np.sin(2*np.pi*6.1*t)
    phase=np.cumsum(f)/SR
    # Asymmetric glottal pulse, not a single sinusoidal oscillator.
    source=signal.sawtooth(2*np.pi*phase,width=.28)
    source=signal.lfilter([1,-.88],[1],source)
    if rasp:source=np.tanh(2.4*source)+rasp*signal.sawtooth(np.pi*phase,width=.44)
    source+=breath*RNG.normal(size=len(t))
    shaped=np.zeros(len(t))
    for center,q,g in formants:
        b,a=signal.iirpeak(center,q,fs=SR);shaped+=g*signal.lfilter(b,a,source)
    return norm(shaped,.8)

def hen_clucks():
    parts=[];starts=[0,.145,.285,.42,.565]
    for i,start in enumerate(starts):
        d=.105 if i<4 else .15;t=clock(d)
        # A clipped 'k-lok': fast closure, chesty double pitch drop, no long crow.
        f=320+460*np.exp(-t*31)+80*np.exp(-((t-.035)/.018)**2)
        v=voice(d,f,[(640,3.2,1.1),(1450,4.8,.75),(2600,5,.28)],breath=.18,rasp=.2)
        env=np.minimum(1,t/.007)*np.exp(-t*(23 if i<4 else 16))
        k=noise(.018,1000,6500)*np.exp(-clock(.018)*150)
        parts.append((start,fade(v*env,release=.01),.85));parts.append((start,k,.19))
    return norm(mix(.82,*parts))

def sheep_bleat():
    d=.94;t=clock(d);f=172+16*np.sin(2*np.pi*5.6*t)+28*np.exp(-t*10)
    v=voice(d,f,[(470,3,1),(1050,5,.83),(2250,6,.36)],breath=.07,rasp=.12,vibrato=.045)
    env=np.minimum(1,t/.07)*np.minimum(1,(d-t)/.17)
    trem=.78+.22*np.sin(2*np.pi*5.6*t-.7)
    # Nasal throat 'm' opens into bleat; nonuniform tremolo is the voice identity.
    return norm(fade(v*env*trem,attack=.025,release=.07))

def crow_caws():
    parts=[]
    for start,d,base in [(0,.38,238),(.49,.46,210)]:
        t=clock(d);f=base*(1+.08*np.sin(2*np.pi*17*t))*(1-.20*t/d)
        v=voice(d,f,[(610,2.1,1),(1260,3,.85),(2360,3.5,.55)],breath=.24,rasp=.65)
        gate=(.76+.24*np.sin(2*np.pi*29*t))
        env=np.minimum(1,t/.022)*np.minimum(1,(d-t)/.10)
        parts.append((start,fade(v*gate*env,attack=.008,release=.025),1))
    return norm(mix(1.02,*parts))

def cavity_pop(d=.15,base=930):
    t=clock(d);freq=base*(1-.32*np.minimum(1,t/.035))
    phase=np.cumsum(freq)/SR
    env=(1-np.exp(-t*1700))*np.exp(-t*48)
    body=np.sin(2*np.pi*phase)+.36*np.sin(2*np.pi*phase*1.67)
    return fade(body*env+.12*noise(d,1700,8500)*np.exp(-t*115),attack=.001,release=.015)
def fish_spit():
    air=noise(.10,400,3300)*(np.sin(np.pi*clock(.10)/.10)**1.4)
    return norm(mix(.29,(0,air,.7),(.075,cavity_pop(.19,1130),1)))
def fish_merge():
    return norm(mix(.48,(0,cavity_pop(.14,1230),.6),(.075,cavity_pop(.18,970),.8),(.16,cavity_pop(.25,640),1)))
def fish_vacuum():
    d=.68;t=clock(d);s=noise(d,150,2200)*(.32+.68*np.sin(2*np.pi*11*t)**2)
    for st in [.05,.16,.25,.34,.41,.47]:
        p=cavity_pop(.12,900-450*st);i=int(st*SR);s[i:i+len(p)]+=p*.5
    return norm(fade(s*np.sin(np.pi*t/d)**.5,attack=.025,release=.08))

def latex_stretch():
    d=.55;t=clock(d);f=210+700*t/d+90*np.sin(2*np.pi*19*t)
    friction=signal.sawtooth(np.cumsum(f)/SR*2*np.pi,width=.45)
    friction=signal.sosfilt(signal.butter(2,[400,2800],btype='band',fs=SR,output='sos'),friction)
    air=noise(d,250,3700)
    return norm(fade((.35*friction+.6*air)*np.sin(np.pi*t/d)**1.2))
def air_release():
    d=.90;t=clock(d);n=noise(d,220,6500)
    flutter=.48+.35*np.sin(2*np.pi*(17*t+28*t*t))**2
    return norm(fade(n*flutter*(1-.55*t/d),attack=.014,release=.15))
def rubber_squish():
    d=.31;t=clock(d);f=220*np.exp(-t*8)+65
    body=np.sin(np.cumsum(f)/SR*2*np.pi)*np.exp(-t*13)
    squeak=signal.sawtooth(2*np.pi*(380*t+230*t*t),width=.65)*np.exp(-((t-.07)/.045)**2)
    return norm(fade(body+.18*squeak+.1*noise(d,100,1500)*np.exp(-t*20),attack=.002,release=.04))

def modal(d,modes,decays,gains,noise_band=(500,6000),noise_gain=.13):
    t=clock(d);s=np.zeros(len(t))
    for f,k,g in zip(modes,decays,gains):s+=g*np.sin(2*np.pi*f*t+RNG.uniform(-.1,.1))*np.exp(-t*k)
    s+=noise_gain*noise(d,*noise_band)*np.exp(-t*65)
    return norm(fade(s,attack=.0015,release=.02))
def egg_drop():return modal(.21,[1050,2370,3980],[32,45,65],[.6,.3,.13],(900,9000),.3)
def egg_fuse():
    click=modal(.07,[1800,4300],[65,95],[.55,.15],(1500,9500),.2)
    return norm(mix(.58,(0,click,.6),(.16,click,.7),(.31,click,.85),(.44,click,1)))
def egg_explosion():
    d=.63;t=clock(d)
    body=noise(d,35,1550)*np.exp(-t*7)+.5*np.sin(2*np.pi*(76*t-19*t*t))*np.exp(-t*13)
    crack=noise(d,1800,10500)*np.exp(-t*58)
    return norm(fade(body+crack*.75,attack=.001,release=.09))
def static_charge():
    d=.44;t=clock(d);s=noise(d,4200,13000)*.12
    for st in [0,.055,.12,.22,.33]:
        click=noise(.018,2500,12000)*np.exp(-clock(.018)*180);i=round(st*SR);s[i:i+len(click)]+=click*1.3
    return norm(fade(s*(1-.7*t/d),attack=.001,release=.04))
def sheep_zap():
    d=.63;t=clock(d);n=noise(d,550,6000)
    fuzz=n*(.48+.52*np.sin(2*np.pi*71*t)**2)
    throat=voice(d,120+12*np.sin(2*np.pi*5*t),[(400,2.4,1),(900,4,.4)],breath=.18,rasp=.2)*.12
    return norm(fade(fuzz*.72+throat,attack=.01,release=.09))
def wool_drop():
    d=.24;t=clock(d);return norm(fade(noise(d,90,1400)*np.exp(-t*15),attack=.008,release=.05))

def nail_tick():return modal(.29,[1620,4370,7220],[18,28,46],[.65,.36,.18],(1800,10000),.27)
def nail_hit():return modal(.34,[1180,3290,6080],[15,22,37],[.65,.4,.23],(600,10000),.45)
def magnetic_pull():
    d=.58;t=clock(d);coil=.16*signal.sawtooth(2*np.pi*(74*t+50*t*t),width=.5)
    texture=noise(d,80,1700)*(.25+.75*(t/d)**.5)
    click=nail_tick();return norm(mix(d+.12,(0,fade(coil+texture,attack=.04,release=.04),1),(d-.1,click,.58)))
def nail_repel():
    d=.34;t=clock(d);whoosh=noise(d,1000,7400)*np.exp(-t*15)
    return norm(mix(.40,(0,nail_tick(),.8),(.015,whoosh,.7)))

def dry_thorns():
    d=.30;s=np.zeros(round(d*SR))
    for st in [0,.026,.061,.095,.14]:
        grain=noise(.045,2200,11500)*np.exp(-clock(.045)*90);i=round(st*SR);s[i:i+len(grain)]+=grain
    return norm(fade(s,attack=.001,release=.04))
def thorn_land():return modal(.14,[820,1830,4200],[55,80,130],[.22,.3,.1],(1700,10000),.7)
def plant_reposition():
    d=.52;t=clock(d);s=noise(d,200,5200)*np.exp(-((t-.17)/.12)**2)
    roots=noise(d,70,800)*np.exp(-((t-.34)/.10)**2)
    return norm(fade(s*.65+roots,attack=.015,release=.04))
def flower_flash():
    # Dry petal flick, not a restorative chime or music arpeggio.
    d=.13;t=clock(d);return norm(fade(noise(d,700,4500)*np.exp(-t*32),attack=.003,release=.03))

def shell_knock():return modal(.40,[185,390,790,1230],[11,17,24,35],[.75,.43,.25,.11],(100,3500),.22)
def shell_enter():return norm(mix(.47,(0,wool_drop(),.32),(.09,shell_knock(),1)))
def shell_spin():
    d=.82;s=np.zeros(round(d*SR))
    for i,st in enumerate(np.arange(0,.75,.075)):
        grain=modal(.09,[260,570],[45,70],[.5,.18],(200,2800),.1);at=round(st*SR);n=min(len(grain),len(s)-at);s[at:at+n]+=grain[:n]*(.45+.12*np.sin(i))
    return norm(fade(s,attack=.01,release=.04))
def shell_exit():return norm(mix(.36,(0,shell_knock()[:round(.25*SR)],.5),(.11,wool_drop(),.7)))

def wing_flap():
    d=.46;s=np.zeros(round(d*SR))
    for st,dur,g in [(0,.14,.9),(.18,.21,.6)]:
        t=clock(dur);fl=noise(dur,130,4500)*np.sin(np.pi*t/dur)**1.7
        i=round(st*SR);s[i:i+len(fl)]+=fl*g
    return norm(fade(s,attack=.01,release=.035))
def straw_repair():
    d=.55;s=np.zeros(round(d*SR))
    for st,dur in [(0,.16),(.15,.20),(.32,.19)]:
        t=clock(dur);grain=noise(dur,900,8000)*(np.sin(np.pi*t/dur)**.6)*(.6+.4*np.sin(2*np.pi*37*t)**2)
        i=round(st*SR);s[i:i+len(grain)]+=grain
    return norm(fade(s,attack=.008,release=.045))
def straw_hit():
    d=.27;t=clock(d);return norm(fade(noise(d,180,7000)*np.exp(-t*20)+.32*np.sin(2*np.pi*128*t)*np.exp(-t*30),attack=.001,release=.04))

SPECS={
 'puffer':('充气球',[
  ('inflate','充气',latex_stretch,'INFLATE starts / visual material cue','乳胶摩擦＋气流，不是笛声'),
  ('absorb','吸收',rubber_squish,'immune_left>0 actual absorption, not HP loss','橡胶挤压回弹'),
  ('release','放气',air_release,'actual burst release; one short audition segment','宽带排气与阀口扑动'),
  ('contact','碰撞',rubber_squish,'actual effective burst collision only','低短弹性碰撞，无爆炸')]),
 'chicken':('炸弹母鸡',[
  ('panic_cluck','咯咯咯',hen_clucks,'PANIC RUN starts; rapid hen clucks, not rooster crow','短促五连咯声，声门＋胸腔共振'),
  ('egg_drop','落蛋',egg_drop,'actual egg spawn/ground contact','薄蛋壳小落地'),
  ('fuse','引信',egg_fuse,'actual armed fuse only; montage rhythm does not define fuse','短干裂壳提示'),
  ('explosion','炸蛋',egg_explosion,'actual BombEgg.explode result, not impact shortcut','干壳破裂＋短低频气爆')]),
 'bubble_fish':('泡泡鱼',[
  ('spit','噗啵',fish_spit,'actual level1 bubble spawn; harmless level1 remains harmless','嘴部噗气流＋短湿腔啵'),
  ('merge','融合',fish_merge,'same-owner bubble levels merge','两小泡并成一个低腔泡'),
  ('vacuum','吸泡',fish_vacuum,'own-bubble vacuum visual event only','湿咕噜吸气、逐泡脉冲'),
  ('hit','泡命中',lambda:cavity_pop(.24,560),'actual merged bubble level>=2 effective hit','大泡湿啪，不是玻璃铃')]),
 'electric_sheep':('触电羊',[
  ('bleat','咩',sheep_bleat,'character voice audition; optional skill expression, no new skill','鼻腔声门抖动的咩，非纯音'),
  ('charge','充电',static_charge,'actual wall collision charges the shared pool','离散短静电噼啪'),
  ('wool','落羊毛',wool_drop,'actual DROP WOOL placement','低闷软绒落地'),
  ('discharge','放电',sheep_zap,'continuous actual discharge excerpt; no added attack interval','绒毛摩擦电流，持续段而非蜂鸣旋律')]),
 'magnet_crab':('磁铁蟹',[
  ('drop','落钉',nail_tick,'actual iron nail spawn, not resting-nail damage','小钢钉高次模态短叩'),
  ('magnet','磁吸',magnetic_pull,'actual wall magnetization and moving nail onset','低线圈吸附＋最后金属搭扣'),
  ('moving_hit','钉命中',nail_hit,'actually moving nail effective collision','短钢钉硬接触'),
  ('repel','弹钉',nail_repel,'prepared returning nail actually repelled','金属弹扣＋短掠风')]),
 'cactus':('仙人掌',[
  ('scatter','散刺',dry_thorns,'five thorns scatter; not a ranged machine-gun skill','干刺逐根拨脱，噪声颗粒'),
  ('land','刺落地',thorn_land,'visual thorn placement/landing only','干小刺轻点'),
  ('regrow','换位',plant_reposition,'actual REGROW reposition; no healing','干土根纤维收放'),
  ('flower','花短亮',flower_flash,'flower blink on actual reposition only; optional visual cue','很短花瓣擦响，不是回血铃')]),
 'shell_turtle':('脱壳乌龟',[
  ('enter','入壳',shell_enter,'actual enter_shell result','空心壳腔与软身贴入'),
  ('spin','旋壳',shell_spin,'shell markings spin excerpt; no auto dash','壳腔颗粒滚动，不是飞驰风声'),
  ('contact','壳碰撞',shell_knock,'actual shell enemy contact','圆壳低空腔叩击，区别钢钉'),
  ('exit','出壳',shell_exit,'only successful legal exit, not guaranteed deadline','短壳音＋软身离开')]),
 'crow':('乌鸦',[
  ('caw','嘎嘎',crow_caws,'character voice audition, optional event emphasis, not projectile','粗糙双嘎，亚谐波声门与宽共振峰'),
  ('swap','换位',wing_flap,'actual legal swap; two endpoints feather glints, no projectile','两段短羽翼掠动'),
  ('repair','修草人',straw_repair,'actual own injured dummy repaired by contact consumes stored feather','干草束梳理摩擦，不是射羽'),
  ('reflect','草人承伤',straw_hit,'actual scarecrow damage/reflection result','布草闷拍＋纤维，不是主动攻击')])
}

def write_wav(path,x):
    x=norm(fade(x,attack=.001,release=.012),.74)
    pcm=np.rint(x*32767).astype('<i2')
    with wave.open(str(path),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
    return pcm

def make(out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    result={'cycle':'R04','format':'48kHz / 16bit / mono PCM WAV','status':'new_awaiting_audition','old_R03_audio_used':False,
      'provenance':{'type':'original_procedural_cartoon_synthesis','external_samples':False,'external_recordings':False,'source':'source/build_character_audio.py','seed':2026110304,'human_listening':'NOT_RUN','not_a_real_animal_recording':True},'characters':{}}
    for cid,(name,specs) in SPECS.items():
        entries=[];parts=[];cursor=.12;markers=[]
        for event_id,title,fn,event,model in specs:
            filename=f'{cid}_{event_id}.wav';pcm=write_wav(out/filename,fn())
            duration=len(pcm)/SR
            entry={'id':event_id,'title':title,'file':filename,'event':event,'duration_s':round(duration,5),'model':model,'status':'new_awaiting_audition','peak_linear':float(np.max(np.abs(pcm.astype(np.int32)))/32767),'clipped_samples':int(np.sum(np.abs(pcm.astype(np.int32))>=32767)),'sha256':hashlib.sha256((out/filename).read_bytes()).hexdigest()}
            entries.append(entry);parts.append((cursor,pcm.astype(float)/32767,1));markers.append({'title':title,'event':event,'start_s':round(cursor,5),'duration_s':round(duration,5),'note':'试听拼接，不是游戏技能时序'})
            cursor+=duration+.24
        filename=f'{cid}_audition.wav'
        # Exact PCM concatenation with silence: event clips retain their bytes.
        pcm=np.rint(mix(cursor,*parts)*32767).astype('<i2')
        with wave.open(str(out/filename),'wb') as w:
            w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
        montage={'title':'整段试听','file':filename,'duration_s':round(len(pcm)/SR,5),'events':markers,'status':'new_awaiting_audition','pcm_segments_match_independent_clips':True,'sha256':hashlib.sha256((out/filename).read_bytes()).hexdigest()}
        result['characters'][cid]={'name':name,'events':entries,'montage':montage,'status':'new_awaiting_audition','human_listening':'NOT_RUN'}
    (out/'review.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print('Created 32 distinct-event auditions + 8 character montages, all original new synthesis; human listening NOT RUN')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True);args=parser.parse_args();make(args.output)
