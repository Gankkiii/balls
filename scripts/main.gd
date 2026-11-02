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

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("09111f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.text = "BALLS · AUTO BATTLE"
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 25)
	add_child(title)
	arena = BattleArena.new()
	arena.arena_size = Vector2(700, 600)
	arena.position = Vector2(370, 70)
	add_child(arena)
	match_seed = randi()
	arena.setup(match_seed)
	for i in 2:
		var card := Label.new()
		card.position = Vector2(24, 95 + i * 280)
		card.add_theme_font_size_override("font_size", 21)
		card.modulate = Color("8cebd2") if i == 0 else Color("ffe0a0")
		add_child(card)
		cards.append(card)
	status = Label.new()
	status.position = Vector2(370, 685)
	status.add_theme_font_size_override("font_size", 18)
	add_child(status)
	var captions := ["1×", "2×", "3×", "Pause", "New", "Replay"]
	for i in 6:
		var button := Button.new()
		button.text = captions[i]
		button.position = Vector2(370 + i * 118, 718)
		button.size = Vector2(110, 50)
		button.add_theme_font_size_override("font_size", 24)
		if i >= 4:
			button.pressed.connect(restart_battle.bind(i == 5))
		else:
			button.pressed.connect(set_rate.bind(i + 1 if i < 3 else 0))
		add_child(button)
		buttons.append(button)
	set_rate(0)
	refresh_hud()

func restart_battle(same_seed: bool = false) -> void:
	# A new arena discards all fighter, egg, cooldown and result state.
	var old_arena := arena
	arena = BattleArena.new()
	arena.arena_size = Vector2(700, 600)
	arena.position = Vector2(370, 70)
	add_child(arena)
	if not same_seed:
		match_seed = randi()
	arena.setup(match_seed)
	remove_child(old_arena)
	old_arena.queue_free()
	set_rate(selected_rate)

func set_rate(value: int) -> void:
	rate = value
	if value > 0:
		selected_rate = value
	accumulator = 0.0
	for i in buttons.size():
		buttons[i].modulate = Color("50e0bd") if (i + 1 == selected_rate and i < 3) or (i == 3 and rate == 0) else Color.WHITE
	refresh_hud()

func cooldown_text(value: float) -> String:
	return "READY" if value <= 0 else "%.1fs" % value

func refresh_hud() -> void:
	if not is_instance_valid(arena) or cards.size() < 2:
		return
	for i in 2:
		var fighter: Fighter = arena.balls[i]
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
		arena.step(FIXED_DT)
		accumulator -= FIXED_DT
		if arena.finished:
			accumulator = 0.0
			break

func _process(delta: float) -> void:
	advance_real_time(delta)
	refresh_hud()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		accumulator = 0.0
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
		accumulator = 0.0
