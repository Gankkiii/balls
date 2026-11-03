extends Control
## Presentation-only sample. BattleArena remains the authoritative simulation.
const STEP := 1.0/120.0
const ORIGIN := Vector2(200,90)
const ZOOM := 1.0
const INK := Color("f4eddf")
const MUTED := Color("a7babb")
const GOLD := Color("ffcb6c")
const PURPLE := Color("d7a3ed")
var font: Font
var arena: BattleArena
var duck: UnluckyDuck
var rabbit: ForgeRabbit
var seed_value := 527
var speed := 1
var paused := false
var suspended := false
var accumulator := 0.0
var effects: Array[Dictionary] = []
var banner := ""
var banner_left := 4.0
var health_display := Vector2(120,120)
var controls: Array[Button] = []
var pause_button: Button
var previous_holder: Fighter
var previous_hp := Vector2(120,120)
var previous_flash := 0.0
var trail: Array[Vector2] = []
var audio_player: AudioStreamPlayer
var sound_enabled := true
var texture_cache: Dictionary = {}
var rabbit_hit_left := 0.0
var duck_impact_left := 0.0
var info_open := false
var forge_phase := -1
var pending_strike := false
var strike_safe := false
var strike_at := Vector2.ZERO
const ROOT := "res://assets/r02/"

var cue_forge: AudioStream = preload("res://assets/audio/anvil_forge.wav")
var cue_sword_hit: AudioStream = preload("res://assets/audio/sword_wide_hit.wav")
var cue_thunder: AudioStream = preload("res://assets/audio/duck_lightning.wav")
var cue_transfer: AudioStream = preload("res://assets/audio/duck_cloud_transfer.wav")

func _ready() -> void:
	font = load("res://assets/arena-ui.otf")
	audio_player=AudioStreamPlayer.new()
	add_child(audio_player)
	make_button("♪",Vector2(480,711),Vector2(48,48),toggle_sound)
	make_button("Ⅱ",Vector2(532,711),Vector2(48,48),toggle_pause)
	pause_button=controls.back()
	for value in [1,2,3]:
		make_button("%d×"%value,Vector2(584+(value-1)*52,711),Vector2(48,48),set_speed.bind(value))
	make_button("↻",Vector2(740,711),Vector2(48,48),restart.bind(true))
	make_button("⚄",Vector2(792,711),Vector2(48,48),restart.bind(false))
	make_button("▣",Vector2(844,711),Vector2(48,48),open_original)
	make_button("i",Vector2(896,711),Vector2(48,48),toggle_info)
	restart(true)

func make_button(caption: String, at: Vector2, size_value: Vector2, callback: Callable) -> void:
	var b:=Button.new()
	b.text=caption
	var icons := {"♪":"icon_sound_on", "Ⅱ":"icon_pause", "↻":"icon_replay", "⚄":"icon_new_seed", "▣":"icon_roster", "i":"icon_info"}
	if icons.has(caption):
		b.text=""
		b.icon=load(ROOT+"ui/png/"+icons[caption]+".png")
		b.expand_icon=true
		b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	b.position=at
	b.size=size_value
	b.add_theme_font_override("font",font)
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",INK)
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxTexture.new()
		style.texture=load(ROOT+"ui/png/button_"+state+".png")
		style.texture_margin_left=12
		style.texture_margin_top=12
		style.texture_margin_right=12
		style.texture_margin_bottom=12
		b.add_theme_stylebox_override(state,style)
	b.add_theme_color_override("font_color",Color("243746"))
	b.pressed.connect(callback)
	add_child(b)
	controls.append(b)

func restart(same_seed: bool) -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			if child != audio_player:
				child.queue_free()
	if not same_seed:
		seed_value=randi()%100000
	if is_instance_valid(arena):
		remove_child(arena)
		arena.queue_free()
	arena=BattleArena.new()
	arena.setup(seed_value,[5,6])
	arena.visible=false
	add_child(arena)
	duck=arena.heroes[0]
	rabbit=arena.heroes[1]
	previous_holder=duck
	rabbit.presentation_hit.connect(on_rabbit_hit)
	duck.presentation_strike.connect(on_strike)
	pending_strike=false
	forge_phase=-1
	rabbit_hit_left=0
	duck_impact_left=0
	previous_hp=Vector2(120,120)
	health_display=previous_hp
	previous_flash=0
	effects.clear()
	trail.clear()
	accumulator=0
	paused=false
	audio_player.stream_paused=false
	pause_button.icon=load(ROOT+"ui/png/icon_pause.png")
	banner=""
	banner_left=0
	queue_redraw()

func toggle_sound() -> void:
	sound_enabled=not sound_enabled
	controls[0].icon=load(ROOT+("ui/png/icon_sound_on.png" if sound_enabled else "ui/png/icon_sound_off.png"))
	if not sound_enabled:
		for child in get_children():
			if child is AudioStreamPlayer:
				child.stop()
				if child != audio_player:
					child.queue_free()
func play_sample(sample: AudioStream) -> void:
	if not sound_enabled:
		return
	var player := AudioStreamPlayer.new()
	player.stream = sample
	player.volume_db = -10.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_cue(base_frequency: float, duration: float, gain: float) -> void:
	if not sound_enabled:
		return
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	var count:=int(duration*22050)
	var bytes:=PackedByteArray()
	bytes.resize(count*2)
	for i in count:
		var t:=float(i)/22050
		var envelope:=pow(1-float(i)/count,2)*minf(1,t/0.005)
		var value:=sin(TAU*base_frequency*t)*0.7+sin(TAU*base_frequency*1.5*t)*0.3
		bytes.encode_s16(i*2,int(value*envelope*gain*32767))
	stream.data=bytes
	audio_player.stream=stream
	audio_player.play()

func toggle_pause() -> void:
	paused=not paused
	accumulator=0
	pause_button.icon=load(ROOT+("ui/png/icon_play.png" if paused else "ui/png/icon_pause.png"))
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stream_paused=paused
func toggle_info() -> void:
	info_open = not info_open

func on_rabbit_hit(other: Fighter, damage: float) -> void:
	if other == duck:
		rabbit_hit_left = 0.42
		duck_impact_left = 0.37
		play_sample(cue_sword_hit)
		effects.append({"kind":"blade","at":other.position,"time":0.28,"total":0.28,"text":""})

func on_strike(at: Vector2, protected: bool) -> void:
	pending_strike=true
	strike_safe=protected
	strike_at=at

func set_speed(value: int) -> void:
	speed=value
	accumulator=0
func open_original() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		suspended=true
		accumulator=0
	elif what==NOTIFICATION_APPLICATION_RESUMED or what==NOTIFICATION_APPLICATION_FOCUS_IN:
		suspended=false
		accumulator=0
func _process(delta: float) -> void:
	if not paused and not suspended:
		accumulator+=minf(delta,0.1)*speed
		while accumulator>=STEP:
			advance(STEP)
			accumulator-=STEP
		health_display=health_display.lerp(Vector2(duck.health,rabbit.health),minf(1,delta*9))
	queue_redraw()
func advance(dt: float) -> void:
	rabbit_hit_left=maxf(0.0,rabbit_hit_left-dt)
	duck_impact_left=maxf(0.0,duck_impact_left-dt)
	for i in range(effects.size()-1,-1,-1):
		effects[i].time-=dt
		if effects[i].time<=0:
			effects.remove_at(i)
	banner_left=maxf(0,banner_left-dt)
	if arena.finished:
		return
	var rods_before:=duck.rods.size()
	var blade_before:=rabbit.stored_damage
	var was_forging:=rabbit.action=="forge"
	var before_storm:=duck.storm_left
	arena.step(dt)
	if rabbit.action=="forge":
		var phase := int(fmod(arena.simulation_time,0.70)/0.70*6.0)
		if phase==2 and forge_phase!=2:
			play_sample(cue_forge)
			effects.append({"kind":"forge","at":rabbit.position,"time":0.3,"total":0.3,"text":""})
		forge_phase=phase
	else:
		forge_phase=-1
	if duck.storm_left < before_storm and ceili(duck.storm_left)<ceili(before_storm) and before_storm-duck.storm_left<0.1:
		play_sample(preload("res://assets/audio/duck_countdown_final.wav") if ceili(duck.storm_left)==1 else preload("res://assets/audio/duck_countdown_tick.wav"))
	if duck.cloud_holder!=previous_holder:
		if not pending_strike:
			play_sample(cue_transfer)
			effects.append({"kind":"transfer","at":previous_holder.position,"to":duck.cloud_holder.position,"time":0.35,"total":0.35,"text":""})
			banner="霉运转交！"
			banner_left=1.4
		previous_holder=duck.cloud_holder
	var strike_event := pending_strike
	if strike_event:
		var safe:=strike_safe
		play_sample(cue_thunder)
		banner="避雷成功 · 消耗一根避雷针" if safe else "落雷！"
		banner_left=1.8
		effects.append({"kind":"safe" if safe else "thunder","at":strike_at,"time":0.5,"total":0.5,"text":"避雷" if safe else ""})
	pending_strike=false
	previous_flash=duck.lightning_flash
	for i in 2:
		var hero: Fighter=arena.heroes[i]
		var lost: float=previous_hp[i]-hero.health
		if lost>0.01:
			if i==0 and rabbit.stored_damage<blade_before:
				pass
			elif not strike_event:
				play_cue(320,0.1,0.08)
			effects.append({"kind":"hit","at":hero.position,"time":0.7,"total":0.7,"text":"−%d"%roundi(lost),"strong":lost>=24})
			if i==0 and rabbit.stored_damage<blade_before:
				banner="重刀命中！" if lost>=24 else "刀刃命中"
				banner_left=1.4
		previous_hp[i]=hero.health
	trail.append(rabbit.position)
	if trail.size()>12:
		trail.pop_front()

func label(text_value: String,at: Vector2,size_value: int=18,tint: Color=INK) -> void:
	draw_string(font,at,text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,tint)
func panel(rect: Rect2,fill: Color,radius_value: int=16,border: Color=Color.TRANSPARENT) -> void:
	var s:=StyleBoxFlat.new()
	s.bg_color=fill
	s.corner_radius_top_left=radius_value
	s.corner_radius_top_right=radius_value
	s.corner_radius_bottom_left=radius_value
	s.corner_radius_bottom_right=radius_value
	if border.a>0:
		s.set_border_width_all(1)
		s.border_color=border
	draw_style_box(s,rect)
func meter(rect: Rect2,value: float,tint: Color) -> void:
	panel(rect,Color("132430"),0)
	if value>0:
		panel(Rect2(rect.position,Vector2(rect.size.x*clampf(value,0,1),rect.size.y)),tint,0)

func texture(path: String) -> Texture2D:
	if not texture_cache.has(path):
		texture_cache[path] = load(ROOT + path)
	return texture_cache[path]

func nine_patch(path: String, rect: Rect2, border: int = 12) -> void:
	var t := texture(path)
	if not t:
		return
	var source_size := t.get_size()
	var sw: Array = [float(border),source_size.x-border*2,float(border)]
	var sh: Array = [float(border),source_size.y-border*2,float(border)]
	var dw: Array = [float(border),rect.size.x-border*2,float(border)]
	var dh: Array = [float(border),rect.size.y-border*2,float(border)]
	var sy := 0.0
	var dy := rect.position.y
	for y in 3:
		var sx := 0.0
		var dx := rect.position.x
		for x in 3:
			draw_texture_rect_region(t,Rect2(dx,dy,dw[x],dh[y]),Rect2(sx,sy,sw[x],sh[y]))
			sx += sw[x]
			dx += dw[x]
		sy += sh[y]
		dy += dh[y]

func image_at(path: String, rect: Rect2) -> void:
	var t := texture(path)
	if t:
		draw_texture_rect(t,rect,false)

func strip_at(path: String, at: Vector2, frame_size: Vector2, durations: Array, elapsed: float, looped: bool = true, flip: bool = false, origin: Vector2 = Vector2.ZERO) -> void:
	var total := 0.0
	for duration in durations:
		total += float(duration)
	var time := fposmod(elapsed,total) if looped else minf(elapsed,total-0.0001)
	var frame := 0
	while frame < durations.size()-1 and time >= float(durations[frame]):
		time -= float(durations[frame])
		frame += 1
	var source := Rect2(Vector2(frame*frame_size.x,0),frame_size)
	var t := texture(path)
	if t:
		draw_set_transform(at,0,Vector2(-1,1) if flip else Vector2.ONE)
		draw_texture_rect_region(t,Rect2(-origin,frame_size),source)
		draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if not is_instance_valid(arena) or font==null:
		return
	image_at("environment/screen_surround.png",Rect2(0,0,1100,780))
	image_at("environment/arena_wood_frame.png",Rect2(190,80,720,620))
	image_at("environment/arena_floor.png",Rect2(200,90,700,600))
	for rod in duck.rods:
		image_at("characters/props/lightning_rod.png",Rect2(ORIGIN+rod-Vector2(48,82),Vector2(96,96)))
	var t := arena.simulation_time
	var duck_strip := "characters/duck/impact_strip.png" if duck_impact_left > 0 else "characters/duck/idle_strip.png"
	strip_at(duck_strip,ORIGIN+duck.position,Vector2(96,96),[0.07,0.08,0.10,0.12] if duck_impact_left>0 else [0.16,0.16,0.16,0.16],0.37-duck_impact_left if duck_impact_left>0 else t,duck_impact_left<=0,duck.velocity.x<0,Vector2(48,56))
	var rs := "idle"
	var durations: Array = [0.16,0.16,0.16,0.16]
	var rt := t
	var looped := true
	if rabbit_hit_left>0:
		rs="hit_recover"
		durations=[0.07,0.08,0.11,0.16]
		rt=0.42-rabbit_hit_left
		looped=false
	elif rabbit.action=="forge":
		rs="forge"
		durations=[0.16,0.10,0.08,0.09,0.11,0.16]
	elif rabbit.temper_left>0:
		rs="temper"
		durations=[0.14,0.14,0.14,0.14]
	strip_at("characters/rabbit/"+rs+"_strip.png",ORIGIN+rabbit.position,Vector2(96,96),durations,rt,looped,rabbit.velocity.x<0,Vector2(48,56))
	var cloud: Vector2=ORIGIN+duck.cloud_holder.position+Vector2(0,-45)
	cloud.x=clampf(cloud.x,238,862)
	cloud.y=maxf(110,cloud.y)
	strip_at("vfx/cloud_idle_strip.png",cloud,Vector2(128,80),[0.16,0.16,0.16,0.16,0.16,0.16],t,true,false,Vector2(64,68))
	label("%.1f"%duck.storm_left,cloud+Vector2(-15,-20),18,Color("243746"))
	if rabbit.temper_left>0:
		strip_at("vfx/temper_aura_strip.png",ORIGIN+rabbit.position,Vector2(96,96),[0.1,0.1,0.1,0.1,0.1,0.1],t,true,false,Vector2(48,56))
	for effect in effects:
		var elapsed: float=effect.total-effect.time
		if effect.kind=="blade":
			strip_at("vfx/broad_sword_hit_strip.png",ORIGIN+effect.at,Vector2(96,96),[0.03,0.04,0.045,0.05,0.055,0.065],elapsed,false,false,Vector2(48,48))
		elif effect.kind=="forge":
			strip_at("vfx/forge_sparks_strip.png",ORIGIN+effect.at,Vector2(96,96),[0.035,0.045,0.05,0.055,0.06,0.07],elapsed,false,false,Vector2(48,68))
		elif effect.kind=="transfer":
			strip_at("vfx/cloud_transfer_strip.png",ORIGIN+effect.at,Vector2(128,128),[0.04,0.05,0.06,0.06,0.07,0.08],elapsed,false,false,Vector2(64,64))
		elif effect.kind=="thunder":
			strip_at("vfx/lightning_strike_strip.png",ORIGIN+effect.at,Vector2(128,192),[0.03,0.04,0.045,0.045,0.05,0.06],elapsed,false,false,Vector2(64,172))
		elif effect.kind=="safe":
			strip_at("vfx/rod_protected_strip.png",ORIGIN+effect.at,Vector2(128,128),[0.035,0.045,0.05,0.055,0.06,0.07],elapsed,false,false,Vector2(64,64))
		elif effect.kind=="hit":
			label(effect.text,ORIGIN+effect.at+Vector2(-18,-45-elapsed*20),22,Color("a24037"))
	nine_patch("ui/png/control_strip.png",Rect2(470,706,490,58))
	for i in 2:
		var x := 10 if i==0 else 930
		var hero: Fighter = duck if i==0 else rabbit
		nine_patch("ui/png/status_panel.png",Rect2(x,90,160,600))
		image_at("characters/"+("duck" if i==0 else "rabbit")+"/default.png",Rect2(x+56,110,48,48))
		label("%d"%ceili(hero.health),Vector2(x+65,205),22,Color("243746"))
		image_at("ui/png/hp_track.png",Rect2(x+16,226,128,16))
		draw_rect(Rect2(x+20,230,120*clampf(hero.health/hero.max_health,0,1),8),Color("efc65b") if i==0 else Color("b89acf"))
		image_at("ui/png/hp_frame.png",Rect2(x+16,226,128,16))
		var values: Array = [hero.cd_one,hero.cd_two]
		var icons: Array = ["icon_skill_timer","icon_skill_rod"] if i==0 else ["icon_skill_forge","icon_skill_temper"]
		for j in 2:
			var pos := Vector2(x+12+j*72,414)
			image_at("ui/png/skill_slot_ready.png" if values[j]<=0 else "ui/png/skill_slot_normal.png",Rect2(pos,Vector2(64,64)))
			image_at("ui/png/"+icons[j]+".png",Rect2(pos+Vector2(16,16),Vector2(32,32)))
			if values[j]>0:
				label("%.1f"%values[j],pos+Vector2(17,87),16,Color("243746"))
		if i==0:
			image_at("ui/png/icon_status_cloud.png",Rect2(x+18,280,32,32))
			label("%d"%duck.rods.size(),Vector2(x+70,305),20,Color("243746"))
		else:
			image_at("ui/png/icon_status_stored_damage.png",Rect2(x+18,280,32,32))
			label("%d"%roundi(rabbit.stored_damage),Vector2(x+58,305),20,Color("243746"))
	if arena.finished:
		label("平局" if arena.result.contains("DRAW") else ("倒霉鸭获胜" if duck.health>rabbit.health else "锻造兔获胜"),Vector2(220,742),22,Color("243746"))
	elif banner_left>0:
		label(banner,Vector2(210,742),16,Color("243746"))
	if info_open:
		panel(Rect2(280,225,540,280),Color("f7ebcd"),0,Color("243746"))
		label("种子 %d    时间 %.1f 秒"%[seed_value,arena.simulation_time],Vector2(310,270),20,Color("243746"))
		label("乌云倒计时 %.1f 秒   避雷针 %d/2"%[duck.storm_left,duck.rods.size()],Vector2(310,315),18,Color("243746"))
		label("蓄伤 %.1f   淬火 %s"%[rabbit.stored_damage,"生效" if rabbit.temper_left>0 else "无"],Vector2(310,355),18,Color("243746"))
		label("技能自动释放，数字表示冷却时间。",Vector2(310,400),18,Color("243746"))
