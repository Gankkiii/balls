extends Control
const FIXED_DT := 1.0 / 120.0
const BASE_TIME_SCALE := 1.0
var match_seed := 0
var arena: BattleArena
var rate := 0
var selected_rate := 1
var accumulator := 0.0
var suspended := false
var status: Label
var buttons: Array[Button] = []
var cards: Array[Label] = []
var visual: Control
var sound_enabled := true
var active_sounds: Array[AudioStreamPlayer] = []
var last_cue_time := {}
var sound_button: Button
var info_button: Button

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("09111f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.visible=false
	visual=load("res://scripts/r04_view.gd").new()
	visual.game=self
	add_child(visual)
	var title := Label.new()
	title.text = "BALLS · AUTO BATTLE"
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 25)
	add_child(title)
	title.visible=false
	arena = BattleArena.new()
	arena.arena_size = Vector2(700, 600)
	arena.position = Vector2(200, 90)
	add_child(arena)
	match_seed = randi()
	arena.setup(match_seed)
	arena.visible=false
	connect_presentation()
	for i in 2:
		var card := Label.new()
		card.position = Vector2(24, 95 + i * 280)
		card.add_theme_font_size_override("font_size", 21)
		card.modulate = Color("8cebd2") if i == 0 else Color("ffe0a0")
		add_child(card)
		card.visible=false
		cards.append(card)
	status = Label.new()
	status.position = Vector2(370, 685)
	status.add_theme_font_size_override("font_size", 18)
	add_child(status)
	status.visible=false
	var captions := ["1×", "2×", "3×", "Pause", "New", "Replay"]
	for i in 6:
		var button := Button.new()
		button.text = captions[i]
		button.position = Vector2(480 + i * 52, 711)
		button.size = Vector2(48, 48)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color",Color("243746"))
		for style_name in ["normal","hover","pressed","disabled"]:
			var style := StyleBoxTexture.new()
			style.texture=load("res://assets/r04/ui/retained/r02/button_"+style_name+".png")
			style.texture_margin_left=12; style.texture_margin_right=12
			style.texture_margin_top=12; style.texture_margin_bottom=12
			button.add_theme_stylebox_override(style_name,style)
		if i>=3:
			var icons := ["icon_pause.png","icon_new_seed.png","icon_replay.png"]
			button.text=""
			button.icon=load("res://assets/r04/ui/"+icons[i-3])
			button.expand_icon=true
		if i >= 4:
			button.pressed.connect(restart_battle.bind(i == 5))
		elif i == 3:
			button.pressed.connect(toggle_pause)
		else:
			button.pressed.connect(set_rate.bind(i + 1))
		add_child(button)
		buttons.append(button)
	sound_button=Button.new()
	sound_button.position=Vector2(792,711); sound_button.size=Vector2(48,48)
	sound_button.icon=load("res://assets/r04/ui/icon_sound_on.png")
	sound_button.expand_icon=true
	sound_button.pressed.connect(toggle_sound)
	add_child(sound_button)
	info_button=Button.new()
	info_button.position=Vector2(844,711); info_button.size=Vector2(48,48)
	info_button.icon=load("res://assets/r04/ui/icon_info.png")
	info_button.expand_icon=true
	info_button.pressed.connect(toggle_info)
	add_child(info_button)
	set_rate(0)
	refresh_hud()

func restart_battle(same_seed: bool = false) -> void:
	# A new arena discards all fighter, egg, cooldown and result state.
	stop_sounds()
	visual.reset()
	var old_arena := arena
	arena = BattleArena.new()
	arena.arena_size = Vector2(700, 600)
	arena.position = Vector2(200, 90)
	add_child(arena)
	if not same_seed:
		match_seed = randi()
	arena.setup(match_seed)
	arena.visible=false
	connect_presentation()
	remove_child(old_arena)
	old_arena.queue_free()
	set_rate(selected_rate)

func set_rate(value: int) -> void:
	rate = value
	if value > 0:
		selected_rate = value
	accumulator = 0.0
	for player in active_sounds:
		if is_instance_valid(player): player.stream_paused=(rate==0 or suspended)
	if buttons.size()>3:
		buttons[3].icon=load("res://assets/r04/ui/"+("retained/r02/icon_play.png" if rate==0 else "icon_pause.png"))
	for i in buttons.size():
		buttons[i].modulate = Color("50e0bd") if (i + 1 == selected_rate and i < 3) or (i == 3 and rate == 0) else Color.WHITE
	refresh_hud()

func cooldown_text(value: float) -> String:
	return "READY" if value <= 0 else "%.1fs" % value

func refresh_hud() -> void:
	if not is_instance_valid(arena) or cards.size() < 2:
		return
	for i in 2:
		var fighter: Fighter = arena.heroes[i]
		var names := fighter.skill_names()
		var extra := ""
		if fighter is Puffer:
			extra = "Gas: %d / 100" % int(fighter.gas)
		elif fighter is Chicken:
			extra = "Eggs: %d" % arena.eggs.size()
		elif fighter is BubbleFish:
			extra = "Bubbles: %d" % arena.bubbles.size()
		elif fighter is ElectricSheep:
			extra = "Charge: %.1f / 100" % fighter.charge
		elif fighter is MagnetCrab:
			extra = "Nails: %d | Repel: %s" % [arena.nails.size(), "ON" if fighter.repel_ready else "OFF"]
		elif fighter is UnluckyDuck:
			extra = "Thunder: %.1fs | Rods: %d" % [fighter.storm_left,fighter.rods.size()]
		elif fighter is ForgeRabbit:
			extra = "Blade: %.1f | Buff: %.1fs" % [fighter.stored_damage,fighter.temper_left]
		elif fighter is Cactus:
			extra = "Thorns: %d" % fighter.thorns.size()
		elif fighter is ShellTurtle:
			extra = "Shell spin: %.1fs" % fighter.shell.spin_left
		elif fighter is Crow:
			extra = "Dummies: %d | Feather: %d" % [fighter.dummies.size(),int(fighter.feather)]
		cards[i].text = "%s\nHP: %d / %d\n%s\n\n%s  %s\n%s  %s\n\nState: %s" % [fighter.title, ceili(fighter.health), int(fighter.max_health), extra, names[0], cooldown_text(fighter.cd_one), names[1], cooldown_text(fighter.cd_two), fighter.state_name()]
	if arena.finished:
		status.text = arena.result + " | Seed: %d" % match_seed
	else:
		status.text = ("PAUSED · select speed to start" if rate == 0 else "%d×" % rate) + " | %.1fs | Seed: %d" % [arena.simulation_time,match_seed]

func advance_real_time(delta: float) -> void:
	if rate == 0 or suspended or arena.finished:
		return
	accumulator += minf(delta, 0.1) * rate * BASE_TIME_SCALE
	while accumulator + 1e-12 >= FIXED_DT:
		visual.observe_before_step(arena)
		arena.step(FIXED_DT)
		visual.observe_after_step(arena,FIXED_DT)
		accumulator -= FIXED_DT
		if arena.finished:
			stop_sounds()
			accumulator = 0.0
			break

func _process(delta: float) -> void:
	advance_real_time(delta)
	refresh_hud()
	visual.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		accumulator = 0.0
		for player in active_sounds:
			if is_instance_valid(player): player.stream_paused=true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
		accumulator = 0.0
		for player in active_sounds:
			if is_instance_valid(player): player.stream_paused=(rate==0)


func connect_presentation() -> void:
	last_cue_time.clear()
	arena.presentation_event.connect(play_cue)
	for actor in arena.heroes:
		if actor is ForgeRabbit: actor.presentation_hit.connect(on_rabbit_hit)
		if actor is UnluckyDuck: actor.presentation_strike.connect(on_duck_strike)

func on_rabbit_hit(_target: Fighter, _damage: float) -> void:
	visual.rabbit_hit_left=0.42
	play_file("res://assets/audio/sword_wide_hit.wav","rabbit_hit")

func on_duck_strike(_at: Vector2, _protected: bool) -> void:
	play_file("res://assets/audio/duck_lightning.wav","duck_lightning")

func play_cue(name: String) -> void:
	play_file("res://assets/r04/audio/"+name+".wav",name)

func play_file(path: String, cue: String) -> void:
	if not sound_enabled or rate==0 or suspended: return
	var now: float=arena.simulation_time
	if now-float(last_cue_time.get(cue,-100.0))<0.12: return
	last_cue_time[cue]=now
	if active_sounds.size()>=8: return
	var sample: AudioStream=load(path)
	if sample==null: return
	var player:=AudioStreamPlayer.new()
	player.stream=sample
	player.volume_db=-12
	add_child(player)
	active_sounds.append(player)
	player.finished.connect(_sound_finished.bind(player))
	player.play()

func stop_sounds() -> void:
	for player in active_sounds:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	active_sounds.clear()

func toggle_sound() -> void:
	sound_enabled=not sound_enabled
	if not sound_enabled: stop_sounds()
	sound_button.icon=load("res://assets/r04/ui/"+("icon_sound_on.png" if sound_enabled else "retained/r02/icon_sound_off.png"))

func toggle_info() -> void:
	visual.info_open=not visual.info_open

func toggle_pause() -> void:
	set_rate(selected_rate if rate==0 else 0)

func _sound_finished(player: AudioStreamPlayer) -> void:
	active_sounds.erase(player)
	player.queue_free()

func _exit_tree() -> void:
	stop_sounds()
