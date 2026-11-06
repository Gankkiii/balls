extends SceneTree
var checks := 0
var failures := 0
var expected_errors := 0
const COUNTS := [1, 2, 5, 20, 100]

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func snapshot(arena: Arena) -> Array:
	var state: Array = []
	for ball in arena.balls:
		state.append([ball.position, ball.velocity])
	return state

func valid_geometry(arena: Arena, label: String) -> void:
	# 检查实际 float32 写回状态，以 double 分量独立计算，不调用生产验证器。
	for i in arena.balls.size():
		var a := arena.balls[i]
		check(a.position.is_finite() and a.velocity.is_finite(), label + " finite motion")
		check(float(a.position.x) >= a.radius - Arena.POSITION_EPS and float(a.position.y) >= a.radius - Arena.POSITION_EPS and float(a.position.x) <= float(arena.arena_size.x) - a.radius + Arena.POSITION_EPS and float(a.position.y) <= float(arena.arena_size.y) - a.radius + Arena.POSITION_EPS, label + " inside walls")
		for j in range(i + 1, arena.balls.size()):
			var b := arena.balls[j]
			var dx := float(a.position.x) - b.position.x
			var dy := float(a.position.y) - b.position.y
			check(a.radius + b.radius - sqrt(dx * dx + dy * dy) <= Arena.POSITION_EPS, label + " nonoverlap")

func make_main(count: int = 1):
	var main = load("res://scenes/balls_%d.tscn" % count).instantiate()
	root.add_child(main)
	main.set_process(false)
	return main

func test_scene_resources() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/balls_1.tscn", "project starts at one-ball scene")
	for count in COUNTS:
		var main = make_main(count)
		check(main.selected_ball_count == count and main.arena.balls.size() == count, "standalone scene contains exact count %d" % count)
		check(main.rate == 1 and main.accumulator == 0, "standalone scene starts at 1x")
		check(main.scenario_buttons.size() == 5 and main.buttons.size() == 3, "all scene and speed controls available")
		check(is_same(main.ball_renderer.balls, main.arena.balls), "renderer reads current arena array")
		if count == 100:
			check("slower than real time" in main.status.text, "100-ball load note is visible before running")
		for ball in main.arena.balls:
			check(ball.radius == 24 and ball.mass == 1, "default geometry unchanged")
			check(ball.character_definition == load("res://configs/default_ball.tres"), "default config explicitly associated")
			check(ball.velocity.length() >= 139.9999 and ball.velocity.length() <= 230.0001, "default speed unchanged")
		valid_geometry(main.arena, "standalone %d" % count)
		main.free()

func test_all_seeds_and_motion() -> void:
	var main = make_main()
	for count in COUNTS:
		for seed_value in 32:
			check(main.select_scenario(count, seed_value), "scenario initializes")
			valid_geometry(main.arena, "%d balls seed %d" % [count, seed_value])
			var before := snapshot(main.arena)
			check(main.select_scenario(count, seed_value) and snapshot(main.arena) == before, "fixed seed replays exactly")
		for seed_value in [7, 42, 99]:
			main.select_scenario(count, seed_value)
			var energy: float = main.arena.kinetic_energy()
			var start_usec := Time.get_ticks_usec()
			for tick in 60:
				check(main.arena.step(main.FIXED_DT), "scenario runtime step succeeds")
				valid_geometry(main.arena, "%d balls runtime" % count)
			check(absf(main.arena.kinetic_energy() / energy - 1.0) < 0.001, "runtime energy conserved")
			check(main.arena.solver_failures == 0 and main.arena.position_failures == 0 and main.arena.event_limit_hits == 0, "no runtime safety failure")
			print("SCENARIO TIMING balls=%d seed=%d ticks=60 simulated_seconds=0.5 wall_ms=%.3f (includes geometry checks)" % [count, seed_value, (Time.get_ticks_usec() - start_usec) / 1000.0])
	main.free()

func test_controls_and_lifetimes() -> void:
	var main = make_main()
	for index in 5:
		main.set_rate(2)
		main.accumulator = main.FIXED_DT * 0.5
		main.scenario_buttons[index].pressed.emit()
		check(main.selected_ball_count == COUNTS[index] and main.arena.balls.size() == COUNTS[index], "actual selector signal selects exact count")
		check(main.rate == 1 and main.accumulator == 0 and main.arena.simulation_time == 0, "selection resets timing and starts 1x")
		var initial := snapshot(main.arena)
		main.buttons[2].pressed.emit()
		main.advance_real_time(1000)
		check(main.rate == 0 and snapshot(main.arena) == initial, "actual Pause freezes all balls")
		main.buttons[1].pressed.emit()
		main.advance_real_time(1.0 / 60.0)
		check(main.rate == 2 and main.arena.simulation_time > 0 and snapshot(main.arena) != initial, "actual 2x control advances")
		main.buttons[0].pressed.emit()
		check(main.rate == 1 and main.accumulator == 0, "actual 1x clears leftover time")
		main.restart_button.pressed.emit()
		check(snapshot(main.arena) == initial and main.arena.simulation_time == 0 and main.rate == 1, "Restart replays same seed and resets time")
		main.suspended = true
		main.advance_real_time(1000)
		check(snapshot(main.arena) == initial, "background freezes scenario")
		main._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
		check(not main.suspended and main.accumulator == 0, "foreground discards backlog")
	for count in [100, 1, 100, 100, 2, 5, 20, 1, 100, 1]:
		var old_ball: WeakRef = weakref(main.arena.balls[0])
		var old_arena: WeakRef = weakref(main.arena)
		main.select_scenario(count, 42)
		check(old_ball.get_ref() == null and old_arena.get_ref() == null, "switch releases former arena and balls")
		check(main.arena_host.get_child_count() == 2 and main.arena.get_child_count() == 1, "switch does not accumulate scene nodes")
		check(main.ball_renderer._display_colors.size() == count and is_same(main.ball_renderer.balls, main.arena.balls), "renderer retains only current balls and colors")
	var before := snapshot(main.arena)
	check(not main.select_scenario(3) and snapshot(main.arena) == before, "unsupported selection leaves scene unchanged")
	main.free()

func test_budget_and_error_recovery() -> void:
	var main = make_main(100)
	main.select_scenario(100, 42)
	main.set_rate(2)
	var start_usec := Time.get_ticks_usec()
	main.advance_real_time(0.1)
	var elapsed := Time.get_ticks_usec() - start_usec
	print("CALLBACK TIMING balls=100 rate=2 wall_ms=%.3f simulated_seconds=%.6f budget_limited=%s" % [elapsed / 1000.0, main.arena.simulation_time, main.budget_limited])
	check(main.arena.simulation_time > 0 and main.arena.simulation_time <= 0.2 + 1e-9, "budget executes whole fixed steps within requested simulation")
	check(is_equal_approx(main.arena.simulation_time / main.FIXED_DT, round(main.arena.simulation_time / main.FIXED_DT)), "budget never changes fixed step")
	if main.budget_limited:
		check(main.accumulator == 0, "overload drops backlog")
	main.buttons[2].pressed.emit()
	check(main.rate == 0, "Pause works immediately after heavy callback")
	main.select_scenario(1, 42)
	check(main.arena.balls.size() == 1 and not main.budget_limited, "switch escapes heavy scene")
	main.arena.balls[0].radius = 1000
	expected_errors += 1
	print("EXPECTED SCENARIO ERROR: invalid runtime geometry")
	main.advance_real_time(0.1)
	check(main.rate == 0 and main.accumulator == 0 and main.error_panel.visible and not main.error_message.text.is_empty(), "runtime failure pauses and shows full error without hover")
	check("Stopped:" in main.status.text, "error summary remains visible")
	main.set_rate(2)
	check(main.rate == 0, "unresolved error cannot resume")
	main.restart_button.pressed.emit()
	check(main.rate == 1 and main.arena.last_error.is_empty() and not main.error_panel.visible, "Restart clears failed state")
	main.select_scenario(2, 42)
	check(main.arena.balls.size() == 2 and main.arena.last_error.is_empty(), "switch after failure remains valid")
	main.free()

func tap(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.pressed = pressed
		event.position = point
		Input.parse_input_event(event)
		await process_frame

func test_portrait_layout() -> void:
	var main = make_main()
	check(main.safe_area_insets(Vector2(360, 640), Vector2.ZERO, Rect2(0, 30, 360, 590), Vector2(720, 1280)) == Vector4(0, 60, 0, 40), "Android safe insets convert physical pixels to logical units")
	check(main.safe_area_insets(Vector2(360, 590), Vector2(0, 30), Rect2(0, 30, 360, 590), Vector2(720, 1180)) == Vector4.ZERO, "already inset window does not double count system bars")
	check(main.safe_area_insets(Vector2.ZERO, Vector2.ZERO, Rect2(), Vector2.ZERO) == Vector4.ZERO, "empty display dimensions are safe")
	for viewport_size in [Vector2i(720, 1120), Vector2i(720, 1278), Vector2i(720, 1558), Vector2i(840, 1120)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		check(main.arena_host.size.y >= 180 and main.arena.scale.x > 0, "arena remains visible after resizing")
		var viewport := Rect2(Vector2.ZERO, Vector2(viewport_size))
		var all_buttons: Array = main.scenario_buttons.duplicate()
		all_buttons.append(main.restart_button)
		all_buttons.append_array(main.buttons)
		for button in all_buttons:
			check(viewport.encloses(button.get_global_rect()), "touch control stays inside portrait viewport")
			check(button.size.y >= 100 and button.size.x >= 180, "touch target retains usable logical dimensions")
		var arena_rect := Rect2(main.arena.global_position, main.arena.arena_size * main.arena.scale)
		check(main.arena_host.get_global_rect().grow(0.01).encloses(arena_rect), "fitted arena stays within flexible host")
	for index in 5:
		await tap(main.scenario_buttons[index])
		check(main.selected_ball_count == COUNTS[index], "synthetic screen touch selects exact scenario")
	await tap(main.buttons[2])
	check(main.rate == 0, "synthetic touch pauses")
	await tap(main.buttons[1])
	check(main.rate == 2, "synthetic touch sets 2x")
	await tap(main.buttons[0])
	check(main.rate == 1, "synthetic touch sets 1x")
	main.advance_real_time(1.0 / 60)
	await tap(main.restart_button)
	check(main.arena.simulation_time == 0 and main.rate == 1, "synthetic touch restarts")
	main.free()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_scene_resources()
	test_all_seeds_and_motion()
	test_controls_and_lifetimes()
	test_budget_and_error_recovery()
	await test_portrait_layout()
	print("SCENARIO RESULT checks=%d failures=%d expected_errors=%d" % [checks, failures, expected_errors])
	quit(1 if failures else 0)
