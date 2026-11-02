extends Control
const FIXED_DT := 1.0 / 120.0
const ArenaScene := preload("res://scenes/arena.tscn")
const BallScene := preload("res://scenes/ball.tscn")
var arena: Arena
var rate := 0
var accumulator := 0.0
var suspended := false
var status: Label
var buttons: Array[Button] = []

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("09111f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.text = "SMOOTH ARENA"
	title.position = Vector2(40, 32)
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Frictionless motion · Elastic collisions"
	subtitle.position = Vector2(40, 78)
	subtitle.modulate = Color("9daec6")
	add_child(subtitle)
	arena = ArenaScene.instantiate()
	arena.position = Vector2(40, 145)
	add_child(arena)
	for i in 2:
		var ball: Ball = BallScene.instantiate()
		ball.color = Color("50e0bd") if i == 0 else Color("ffb45f")
		arena.register_ball(ball)
	arena.initialize(randi())
	status = Label.new()
	status.position = Vector2(40, 845)
	status.add_theme_font_size_override("font_size", 22)
	add_child(status)
	var captions := ["1×", "2×", "Pause"]
	var rates := [1, 2, 0]
	for i in 3:
		var button := Button.new()
		button.text = captions[i]
		button.position = Vector2(40 + i * 220, 900)
		button.size = Vector2(200, 64)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(set_rate.bind(rates[i]))
		add_child(button)
		buttons.append(button)
	set_rate(0)

func set_rate(value: int) -> void:
	rate = value
	accumulator = 0.0
	status.text = "Paused" if rate == 0 else "Running · %d×" % rate
	for i in buttons.size():
		buttons[i].modulate = Color("50e0bd") if [1, 2, 0][i] == rate else Color.WHITE

func advance_real_time(delta: float) -> void:
	if rate == 0 or suspended:
		return
	# Drop long background stalls; never catch up minutes of elapsed wall time.
	accumulator += minf(delta, 0.1) * rate
	while accumulator + 1e-12 >= FIXED_DT:
		arena.step(FIXED_DT)
		accumulator -= FIXED_DT

func _process(delta: float) -> void:
	advance_real_time(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		accumulator = 0.0
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
		accumulator = 0.0
