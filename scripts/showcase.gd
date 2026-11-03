extends Control
## Presentation-only sample. BattleArena remains the authoritative simulation.
const STEP := 1.0/120.0
const ORIGIN := Vector2(270,140)
const ZOOM := 0.8
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
var banner := "看准时机，把霉运交出去。"
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
var cue_forge: AudioStream = preload("res://assets/audio/anvil_forge.wav")
var cue_sword_hit: AudioStream = preload("res://assets/audio/sword_short_hit.wav")
var cue_thunder: AudioStream = preload("res://assets/audio/duck_lightning.wav")
var cue_transfer: AudioStream = preload("res://assets/audio/duck_cloud_transfer.wav")

func _ready() -> void:
	font = load("res://assets/arena-ui.otf")
	audio_player=AudioStreamPlayer.new()
	add_child(audio_player)
	make_button("声音开关",Vector2(830,728),Vector2(92,34),toggle_sound)
	make_button("暂停",Vector2(337,728),Vector2(80,34),toggle_pause)
	pause_button=controls.back()
	for value in [1,2,3]:
		make_button("%d×"%value,Vector2(425+(value-1)*53,728),Vector2(47,34),set_speed.bind(value))
	make_button("同局重看",Vector2(594,728),Vector2(108,34),restart.bind(true))
	make_button("换个种子",Vector2(710,728),Vector2(108,34),restart.bind(false))
	make_button("全部角色",Vector2(930,30),Vector2(126,36),open_original)
	restart(true)

func make_button(caption: String, at: Vector2, size_value: Vector2, callback: Callable) -> void:
	var b:=Button.new()
	b.text=caption
	b.position=at
	b.size=size_value
	b.add_theme_font_override("font",font)
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",INK)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("243744")
	style.set_border_width_all(2)
	style.border_color=Color("536c70")
	style.corner_radius_top_left=0
	style.corner_radius_top_right=0
	style.corner_radius_bottom_left=0
	style.corner_radius_bottom_right=0
	b.add_theme_stylebox_override("normal",style)
	var hover=style.duplicate()
	hover.bg_color=Color("3b5660")
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("pressed",hover)
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
	previous_hp=Vector2(120,120)
	health_display=previous_hp
	previous_flash=0
	effects.clear()
	trail.clear()
	accumulator=0
	paused=false
	audio_player.stream_paused=false
	pause_button.text="暂停"
	banner="看准时机，把霉运交出去。"
	banner_left=4
	queue_redraw()

func toggle_sound() -> void:
	sound_enabled=not sound_enabled
	controls[0].text="声音开启" if sound_enabled else "声音关闭"
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
	pause_button.text="继续" if paused else "暂停"
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stream_paused=paused
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
	arena.step(dt)
	if not was_forging and rabbit.action=="forge":
		play_sample(cue_forge)
	if duck.cloud_holder!=previous_holder:
		play_sample(cue_transfer)
		effects.append({"kind":"transfer","at":previous_holder.position,"to":duck.cloud_holder.position,"time":0.35,"total":0.35,"text":""})
		banner="霉运转交！" if duck.lightning_flash<=previous_flash else "下一轮乌云回到鸭子。"
		banner_left=1.4
		previous_holder=duck.cloud_holder
	var strike_event := duck.lightning_flash>previous_flash
	if strike_event:
		var safe:=duck.rods.size()<rods_before
		if safe:
			play_cue(880,0.15,0.08)
		else:
			play_sample(cue_thunder)
		banner="避雷成功 · 消耗一根避雷针" if safe else "落雷！"
		banner_left=1.8
		effects.append({"kind":"safe" if safe else "thunder","at":duck.strike_position,"time":0.5,"total":0.5,"text":"避雷" if safe else ""})
	previous_flash=duck.lightning_flash
	for i in 2:
		var hero: Fighter=arena.heroes[i]
		var lost: float=previous_hp[i]-hero.health
		if lost>0.01:
			if i==0 and rabbit.stored_damage<blade_before:
				play_sample(cue_sword_hit)
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

func _draw() -> void:
	if not is_instance_valid(arena) or font==null:
		return
	draw_rect(Rect2(0,0,1100,780),Color("182837"))
	label("鸭兔对决",Vector2(42,53),28)
	label("自动战斗",Vector2(43,78),15,MUTED)
	panel(Rect2(270,82,250,44),Color("243744"),0,Color("536c70"))
	label("鸭",Vector2(285,108),18,GOLD)
	label("%d"%ceili(duck.health),Vector2(335,108),19,GOLD)
	meter(Rect2(382,99,120,8),health_display.x/120,GOLD)
	panel(Rect2(580,82,250,44),Color("243744"),0,Color("536c70"))
	label("兔",Vector2(595,108),18,PURPLE)
	label("%d"%ceili(rabbit.health),Vector2(645,108),19,PURPLE)
	meter(Rect2(692,99,120,8),health_display.y/120,PURPLE)
	label("VS",Vector2(536,111),17,MUTED)
	panel(Rect2(260,130,580,500),Color("b18a63"),0)
	panel(Rect2(270,140,560,480),Color("415657"),0)
	draw_set_transform(ORIGIN,0,Vector2.ONE*ZOOM)
	for x in range(35,700,35):
		for y in range(35,600,35):
			draw_circle(Vector2(x,y),0.8,Color("526966"))
	for rod in duck.rods:
		draw_circle(rod,100,Color(0.3,0.65,0.62,0.07))
		draw_arc(rod,100,0,TAU,64,Color(0.3,0.65,0.62,0.3),1.4,true)
		draw_circle(rod+Vector2(0,6),10,Color("cbdacf"))
		draw_line(rod+Vector2(0,3),rod-Vector2(0,24),Color("4c9292"),5)
		draw_line(rod-Vector2(7,18),rod+Vector2(7,-28),Color("4c9292"),3)
	for effect in effects:
		if effect.kind=="transfer":
			var t: float=1-effect.time/effect.total
			var at: Vector2=effect.at.lerp(effect.to,t)
			draw_arc(at,28,0,TAU,32,Color(0.7,0.5,0.2,effect.time/effect.total),3,true)
	for i in 2:
		var h: Fighter=arena.heroes[i]
		draw_set_transform(ORIGIN+h.position*ZOOM,0,Vector2.ONE*ZOOM)
		draw_circle(Vector2(0,17),24,Color(0.18,0.27,0.22,0.12))
		if i==0:
			draw_duck()
		else:
			draw_rabbit()
	draw_set_transform(ORIGIN,0,Vector2.ONE*ZOOM)
	var cloud: Vector2=duck.cloud_holder.position+Vector2(0,-60)
	cloud.x=clampf(cloud.x,35,665)
	cloud.y=maxf(36,cloud.y)
	var danger:=duck.storm_left<=2
	var cloud_color:=Color("bd655a") if danger else Color("687680")
	for p in [Vector2(-15,0),Vector2(0,-7),Vector2(16,0)]:
		draw_circle(cloud+p,16,cloud_color)
	panel(Rect2(cloud+Vector2(-24,6),Vector2(48,25)),cloud_color,8)
	label("%.1f"%duck.storm_left,cloud+Vector2(-14,24),18,Color.WHITE)
	for effect in effects:
		var fade: float=effect.time/effect.total
		if effect.kind=="thunder":
			draw_polyline(PackedVector2Array([effect.at+Vector2(-7,-90),effect.at+Vector2(9,-51),effect.at+Vector2(-8,-48),effect.at]),Color(0.94,0.65,0.19,fade),6,true)
		elif effect.kind=="safe":
			draw_arc(effect.at,26+(1-fade)*45,0,TAU,48,Color(0.2,0.6,0.54,fade),4,true)
			label("避雷",effect.at+Vector2(-20,-34),20,Color(0.2,0.5,0.45,fade))
		elif effect.kind=="hit":
			draw_arc(effect.at,20+(1-fade)*35,0,TAU,32,Color(0.8,0.32,0.26,fade),3,true)
			label(effect.text,effect.at+Vector2(-20,-30-(1-fade)*35),28 if effect.strong else 20,Color(0.7,0.25,0.2,fade))
	draw_set_transform(Vector2.ZERO)
	# Compact state cards: symbols accompany values, while the full mode remains available.
	panel(Rect2(38,165,188,78),Color("243744"),0,Color("536c70"))
	draw_colored_polygon(PackedVector2Array([Vector2(66,177),Vector2(55,194),Vector2(63,194),Vector2(58,207),Vector2(76,188),Vector2(68,188)]),GOLD)
	label("%.1f s"%duck.storm_left,Vector2(91,203),28,GOLD)
	label("鸭" if duck.cloud_holder==duck else "兔",Vector2(52,228),15,MUTED)
	label("避雷 %d/2"%duck.rods.size(),Vector2(91,228),14,MUTED)
	var blade: float=rabbit.stored_damage*(1.5 if rabbit.temper_left>0 else 1)
	panel(Rect2(870,165,188,78),Color("243744"),0,Color("536c70"))
	label("剑",Vector2(884,199),20,PURPLE)
	label("%d"%roundi(blade),Vector2(927,203),28,PURPLE)
	meter(Rect2(887,220,145,6),minf(blade/60,1),PURPLE)
	if rabbit.temper_left>0:
		label("×1.5  %.1f s"%rabbit.temper_left,Vector2(880,276),18,GOLD)
	var event_text:=banner if banner_left>0 else "轻碰不扣血 · 关键一击才值得强调"
	if arena.finished:
		event_text="平局" if arena.result.contains("DRAW") else ("倒霉鸭获胜" if duck.health>rabbit.health else "锻造兔获胜")
	label(event_text,Vector2(290,652),16,INK)
	label("%.1f 秒  /  %d×"%[arena.simulation_time,speed],Vector2(695,652),13,MUTED)
	var captions: Array[String]=["改雷表","放避雷针","现场打铁","淬火"]
	var values: Array[float]=[duck.cd_one,duck.cd_two,rabbit.cd_one,rabbit.cd_two]
	for i in 4:
		var x:=270+i*142
		panel(Rect2(x,668,134,46),Color("243744") if values[i]>0 else Color("315253"),0,Color("536c70"))
		var icon:=Vector2(x+21,691)
		var tint:=GOLD if i<2 else PURPLE
		draw_arc(icon,13,-PI/2,-PI/2+TAU*(1-clampf(values[i]/[6.0,6.0,7.0,8.0][i],0,1)),32,tint,2,true)
		if i==0:
			draw_line(icon,icon+Vector2(0,-7),tint,2)
			draw_line(icon,icon+Vector2(6,3),tint,2)
		elif i==1:
			draw_line(icon+Vector2(0,8),icon-Vector2(0,8),tint,3)
			draw_line(icon-Vector2(5,3),icon+Vector2(5,-8),tint,2)
		elif i==2:
			draw_line(icon+Vector2(-4,7),icon+Vector2(3,-4),tint,3)
			draw_rect(Rect2(icon+Vector2(-2,-8),Vector2(11,6)),tint)
		else:
			draw_line(icon+Vector2(-5,7),icon+Vector2(6,-8),tint,4)
		label(["雷","针","锻","火"][i],Vector2(x+42,687),14,tint)
		label("%.1f s"%values[i] if values[i]>0 else "就绪",Vector2(x+72,696),14,MUTED)
	label("种子 %d"%seed_value,Vector2(42,752),12,MUTED)
	

# Rectangular pixels remain presentation-only; the simulation keeps its original circular bodies.
func pixel(rect: Rect2, color: String) -> void:
	draw_rect(rect,Color(color))

func draw_duck() -> void:
	# Pixel silhouette, deliberately larger than the physical collision body only visually.
	pixel(Rect2(-24,-5,45,25),"263647")
	pixel(Rect2(-18,-11,39,27),"ffcf63")
	pixel(Rect2(-23,0,12,13),"ffcf63")
	pixel(Rect2(-12,-5,26,12),"ffe782")
	pixel(Rect2(-8,7,23,8),"d99d49")
	pixel(Rect2(4,-27,24,25),"263647")
	pixel(Rect2(7,-24,18,19),"ffdb70")
	pixel(Rect2(5,-31,15,6),"ef7956")
	pixel(Rect2(18,-20,5,5),"263647")
	pixel(Rect2(24,-15,15,6),"ed8156")
	pixel(Rect2(-14,18,12,5),"ec815d")
	pixel(Rect2(6,18,12,5),"ec815d")

func draw_rabbit() -> void:
	# The sword is drawn independently of collision shape and has no gameplay reach.
	for x in [-14,8]:
		pixel(Rect2(x-2,-42,11,31),"263647")
		pixel(Rect2(x,-39,6,26),"d7b4e9")
		pixel(Rect2(x+2,-34,3,14),"f2dff5")
	pixel(Rect2(-22,-12,44,34),"263647")
	pixel(Rect2(-18,-16,36,34),"d9b8ec")
	pixel(Rect2(-14,-16,28,6),"f4e7f8")
	pixel(Rect2(-12,-5,5,5),"263647")
	pixel(Rect2(7,-5,5,5),"263647")
	pixel(Rect2(-3,2,6,4),"ee947d")
	pixel(Rect2(-13,10,26,8),"e39b46")
	pixel(Rect2(-12,18,8,6),"f3e8f6")
	pixel(Rect2(5,18,8,6),"f3e8f6")
	var sword_color := "f7b86e" if rabbit.temper_left>0 else "bfdcdb"
	pixel(Rect2(25,-26,8,36),"263647")
	pixel(Rect2(27,-30,4,33),sword_color)
	pixel(Rect2(21,5,20,5),"f08a5f")
	pixel(Rect2(28,10,5,9),"ad7147")
	if rabbit.action=="forge":
		var lift:=sin(arena.simulation_time*16)*4
		pixel(Rect2(-28,-6+lift,5,18),"a97953")
		pixel(Rect2(-32,-12+lift,13,7),"93aaa9")
	if rabbit.temper_left>0:
		draw_arc(Vector2.ZERO,31,0,TAU,40,Color(0.9,0.65,0.25,0.45),2,true)
