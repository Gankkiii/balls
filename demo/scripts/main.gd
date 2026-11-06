extends Control

# 页面外壳：只负责选择场景、共用按钮、状态和手机布局。
const SCENARIO_COUNTS := [1, 2, 5, 20, 100]
const SCENES := {
	1: preload("res://scenes/balls_1.tscn"),
	2: preload("res://scenes/balls_2.tscn"),
	5: preload("res://scenes/balls_5.tscn"),
	20: preload("res://scenes/balls_20.tscn"),
	100: preload("res://scenes/balls_100.tscn"),
}
var current_scenario: DemoScenario
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
	select_scenario(1)

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

# 选择器实际加载对应场景；Restart 使用相同种子重新创建该场景。
func select_scenario(count: int, seed_value: int = -1) -> bool:
	if not SCENES.has(count):
		return false
	var was_suspended := false
	if is_instance_valid(current_scenario):
		was_suspended = current_scenario.suspended
		current_scenario.free()
	current_scenario = SCENES[count].instantiate()
	current_scenario.scenario_seed = seed_value
	current_scenario.suspended = was_suspended
	arena_host.add_child(current_scenario)
	arena_host.move_child(error_panel, -1)
	for i in scenario_buttons.size():
		scenario_buttons[i].modulate = Color("50e0bd") if SCENARIO_COUNTS[i] == count else Color.WHITE
	_refresh_status()
	return current_scenario.arena.last_error.is_empty()

func restart_scenario() -> void:
	select_scenario(current_scenario.ball_count, current_scenario.scenario_seed)

func set_rate(value: int) -> void:
	current_scenario.set_rate(value)
	_refresh_status()

func _refresh_status() -> void:
	for i in buttons.size():
		buttons[i].modulate = Color("50e0bd") if [1, 2, 0][i] == current_scenario.rate else Color.WHITE
	status.text = "%s · %d ball%s · %.2f s" % ["Paused" if current_scenario.rate == 0 else "Running %d×" % current_scenario.rate, current_scenario.ball_count, "" if current_scenario.ball_count == 1 else "s", current_scenario.arena.simulation_time]
	status.tooltip_text = current_scenario.arena.last_error
	if not current_scenario.arena.last_error.is_empty():
		status.text = "Stopped: simulation error · Choose a scene or Restart"
		error_message.text = "Simulation stopped\n\n" + current_scenario.arena.last_error + "\n\nChoose another scene or tap Restart to reset."
		error_panel.show()
	else:
		error_panel.hide()
		if current_scenario.ball_count == 100 or current_scenario.budget_limited:
			status.text += "\nHeavy load: simulation may run slower than real time."

# 测试及外部调用可显式推进；正常逐帧推进由场景自己负责。
func advance_real_time(delta: float) -> void:
	current_scenario.advance_real_time(delta)
	_refresh_status()

func _process(_delta: float) -> void:
	_refresh_status()
