extends Control
const FIXED_DT := 1.0 / 120.0
# 检查发生在完整物理步之间；单个昂贵物理步仍可能超过此预算。
const FRAME_BUDGET_USEC := 12000
const SCENARIO_COUNTS := [1, 2, 5, 20, 100]
const ArenaScene := preload("res://scenes/arena.tscn")
const DefaultBallConfig := preload("res://configs/default_ball.tres")
@export_enum("1 ball:1", "2 balls:2", "5 balls:5", "20 balls:20", "100 balls:100") var initial_ball_count := 1
var arena: Arena
var ball_renderer: BallRenderer
var rate := 0
var accumulator := 0.0
var suspended := false
var selected_ball_count := 1
var scenario_seed := 0
var budget_limited := false
var status: Label
var outer_margin: MarginContainer
var buttons: Array[Button] = []
var scenario_buttons: Array[Button] = []
var restart_button: Button
var arena_host: Control
var error_panel: PanelContainer
var error_message: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("09111f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	outer_margin = MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer_margin)
	resized.connect(_update_safe_area)
	_update_safe_area()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	outer_margin.add_child(layout)
	var title := Label.new()
	title.text = "SMOOTH ARENA"
	title.add_theme_font_size_override("font_size", 32)
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Choose a scene · Frictionless elastic motion"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.modulate = Color("9daec6")
	layout.add_child(subtitle)
	var choices := GridContainer.new()
	choices.columns = 3
	choices.add_theme_constant_override("h_separation", 12)
	choices.add_theme_constant_override("v_separation", 12)
	layout.add_child(choices)
	for count in SCENARIO_COUNTS:
		var button := _make_button("%d ball%s" % [count, "" if count == 1 else "s"])
		button.pressed.connect(select_scenario.bind(count))
		choices.add_child(button)
		scenario_buttons.append(button)
	restart_button = _make_button("Restart")
	restart_button.tooltip_text = "Restart this scene from the same initial state at 1×"
	restart_button.pressed.connect(restart_scenario)
	choices.add_child(restart_button)
	arena_host = Control.new()
	arena_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena_host.custom_minimum_size = Vector2(0, 180)
	arena_host.resized.connect(_fit_arena)
	layout.add_child(arena_host)
	_build_error_panel()
	status = Label.new()
	status.custom_minimum_size.y = 62
	status.add_theme_font_size_override("font_size", 20)
	layout.add_child(status)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	layout.add_child(controls)
	var captions := ["1×", "2×", "Pause"]
	var rates := [1, 2, 0]
	for i in 3:
		var button := _make_button(captions[i])
		button.pressed.connect(set_rate.bind(rates[i]))
		controls.add_child(button)
		buttons.append(button)
	select_scenario(initial_ball_count)

# Android 安全区按窗口到逻辑画布的比例转换，给刘海和系统导航留空间。
func _update_safe_area() -> void:
	var insets := Vector4.ZERO
	if OS.has_feature("android"):
		insets = safe_area_insets(Vector2(DisplayServer.window_get_size()), Vector2(DisplayServer.window_get_position()), Rect2(DisplayServer.get_display_safe_area()), size)
	for i in 4:
		outer_margin.add_theme_constant_override("margin_" + ["left", "top", "right", "bottom"][i], 24 + ceili(insets[i]))

func safe_area_insets(window_size: Vector2, window_position: Vector2, safe_area: Rect2, logical_size: Vector2) -> Vector4:
	if window_size.x <= 0 or window_size.y <= 0:
		return Vector4.ZERO
	var window := Rect2(window_position, window_size)
	var usable := safe_area.intersection(window)
	if not usable.has_area():
		return Vector4.ZERO
	var ratio := logical_size / window_size
	return Vector4((usable.position.x - window.position.x) * ratio.x, (usable.position.y - window.position.y) * ratio.y, (window.end.x - usable.end.x) * ratio.x, (window.end.y - usable.end.y) * ratio.y)

func _make_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	# 320px 宽竖屏上约 44px 高，选择和播放控件均可直接触摸。
	button.custom_minimum_size = Vector2(0, 100)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 26)
	return button

func _build_error_panel() -> void:
	error_panel = PanelContainer.new()
	error_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_host.add_child(error_panel)
	var padding := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 20)
	error_panel.add_child(padding)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	padding.add_child(scroll)
	error_message = Label.new()
	error_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	error_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_message.add_theme_font_size_override("font_size", 24)
	scroll.add_child(error_message)
	error_panel.hide()

# 五个独立场景与屏幕选择器共用这条入口，不复制或替换物理算法。
# seed_value < 0 时生成新种子；Restart 复现当前种子。
func select_scenario(count: int, seed_value: int = -1) -> bool:
	if count not in SCENARIO_COUNTS:
		return false
	if is_instance_valid(arena):
		arena.free()
	arena = ArenaScene.instantiate()
	arena_host.add_child(arena)
	arena_host.move_child(error_panel, -1)
	ball_renderer = BallRenderer.new()
	ball_renderer.balls = arena.balls
	arena.add_child(ball_renderer)
	for i in count:
		var ball := Ball.new()
		ball.character_definition = DefaultBallConfig
		# 展示配色留在渲染层；两球仍使用原来的青绿与橙色。
		var color := Color.from_hsv(fmod(i * 0.61803398875, 1.0), 0.57, 0.95)
		if i < 2:
			color = Color("50e0bd") if i == 0 else Color("ffb45f")
		ball_renderer.set_display_color(ball, color)
		arena.register_ball(ball)
	selected_ball_count = count
	scenario_seed = randi() if seed_value < 0 else seed_value
	budget_limited = false
	var result := arena.initialize_demo(scenario_seed)
	_fit_arena()
	for i in scenario_buttons.size():
		scenario_buttons[i].modulate = Color("50e0bd") if SCENARIO_COUNTS[i] == count else Color.WHITE
	set_rate(1)
	return result.ok

func restart_scenario() -> void:
	select_scenario(selected_ball_count, scenario_seed)

func _fit_arena() -> void:
	if not is_instance_valid(arena):
		return
	var fit := minf(arena_host.size.x / arena.arena_size.x, arena_host.size.y / arena.arena_size.y)
	arena.scale = Vector2.ONE * fit
	arena.position = (arena_host.size - arena.arena_size * fit) * 0.5

func set_rate(value: int) -> void:
	rate = value if value in [0, 1, 2] and arena.last_error.is_empty() else 0
	accumulator = 0.0
	_refresh_status()
	for i in buttons.size():
		buttons[i].modulate = Color("50e0bd") if [1, 2, 0][i] == rate else Color.WHITE

func _refresh_status() -> void:
	status.text = "%s · %d ball%s · %.2f s" % ["Paused" if rate == 0 else "Running %d×" % rate, selected_ball_count, "" if selected_ball_count == 1 else "s", arena.simulation_time]
	status.tooltip_text = arena.last_error
	if not arena.last_error.is_empty():
		status.text = "Stopped: simulation error · Choose a scene or Restart"
		error_message.text = "Simulation stopped\n\n" + arena.last_error + "\n\nChoose another scene or tap Restart to reset."
		error_panel.show()
	else:
		error_panel.hide()
		if selected_ball_count == 100 or budget_limited:
			status.text += "\nHeavy load: simulation may run slower than real time."

func advance_real_time(delta: float) -> void:
	if rate == 0 or suspended:
		return
	# 长卡顿不补算；完整步之间检查墙钟预算，避免大量积压阻挡触摸。
	accumulator += minf(delta, 0.1) * rate
	var start_usec := Time.get_ticks_usec()
	while accumulator + 1e-12 >= FIXED_DT:
		if not arena.step(FIXED_DT):
			set_rate(0)
			return
		accumulator -= FIXED_DT
		if Time.get_ticks_usec() - start_usec >= FRAME_BUDGET_USEC:
			budget_limited = true
			accumulator = 0.0
			break
	_refresh_status()

func _process(delta: float) -> void:
	advance_real_time(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		accumulator = 0.0
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
		accumulator = 0.0
