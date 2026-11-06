extends SceneTree
var checks := 0
var failures := 0
var expected_errors := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func make_arena(count: int, radius: float = 24.0) -> Arena:
	var arena := Arena.new()
	for i in count:
		var ball := Ball.new()
		ball.radius = radius
		ball.position = Vector2(80 + i * 30, 100)
		ball.velocity = Vector2(i + 1, i + 2)
		arena.register_ball(ball)
	return arena

func snapshot(arena: Arena) -> Array:
	var state: Array = [var_to_bytes(arena.arena_size), arena.simulation_time, arena.event_limit_hits, arena.solver_failures, arena.position_failures]
	for ball in arena.balls:
		if ball == null:
			state.append(null)
		else:
			state.append([ball, ball.position, ball.velocity, ball.character_definition, var_to_bytes([ball.radius, ball.mass])])
	return state

func positions(arena: Arena) -> Array:
	var result: Array = []
	for ball in arena.balls:
		result.append(ball.position)
	return result

func valid_geometry(arena: Arena, label: String) -> void:
	# 独立使用 double 分量检查已写回的 float32 位置，不调用生产验证器。
	for i in arena.balls.size():
		var a := arena.balls[i]
		check(a.position.is_finite(), label + " finite position")
		check(float(a.position.x) >= a.radius - Arena.POSITION_EPS and float(a.position.y) >= a.radius - Arena.POSITION_EPS and float(a.position.x) <= float(arena.arena_size.x) - a.radius + Arena.POSITION_EPS and float(a.position.y) <= float(arena.arena_size.y) - a.radius + Arena.POSITION_EPS, label + " inside all walls")
		for j in range(i + 1, arena.balls.size()):
			var b := arena.balls[j]
			var dx := float(a.position.x) - b.position.x
			var dy := float(a.position.y) - b.position.y
			check(a.radius + b.radius - sqrt(dx * dx + dy * dy) <= Arena.POSITION_EPS, label + " pair separated")

func reject_initialize(arena: Arena, input: Array, label: String) -> void:
	arena.simulation_time = 3.5
	arena.event_limit_hits = 2
	arena.solver_failures = 4
	arena.position_failures = 5
	var before := snapshot(arena)
	var input_before := var_to_bytes(input)
	expected_errors += 1
	print("EXPECTED PLACEMENT ERROR: ", label)
	var result := arena.initialize(42, input)
	check(not result.ok and not result.error.is_empty(), label + " explicit error")
	check(snapshot(arena) == before, label + " all motion/configs/counters unchanged")
	check(var_to_bytes(input) == input_before, label + " placement input unchanged")

func test_explicit_positions() -> void:
	var arena := make_arena(3, 10)
	var requested: Array = [Vector2(10, 10), Vector2(30, 10), Vector2(60, 10)]
	var input_before := requested.duplicate()
	check(arena.initialize(42, requested).ok, "valid explicit touching positions accepted")
	check(positions(arena) == input_before and requested == input_before, "explicit positions preserved exactly")
	valid_geometry(arena, "explicit")
	var stationary := BallConfig.new()
	stationary.min_initial_speed = 0
	stationary.max_initial_speed = 0
	arena.balls[2].character_definition = stationary
	check(arena.initialize(43, requested).ok and arena.balls[2].velocity == Vector2.ZERO, "explicit path retains per-ball speed config")
	reject_initialize(arena, [Vector2(100, 100), Vector2(120, 100), Vector2(139, 100)], "overlapping final ball")
	reject_initialize(arena, [Vector2(100, 100), Vector2(120, 100), Vector2(640, 100)], "outside final ball")
	for bad in [Vector2(NAN, 100), Vector2(INF, 100), "invalid", null]:
		reject_initialize(arena, [Vector2(100, 100), Vector2(120, 100), bad], "invalid final position")
	reject_initialize(arena, [Vector2(100, 100)], "wrong position count")
	for bad in [0.0, -1.0, NAN, INF, 400.0, 1e-50]:
		arena.balls[2].radius = bad
		reject_initialize(arena, requested, "invalid final radius")
	arena.balls[2].radius = 10
	for bad in [0.0, -1.0, NAN, INF]:
		arena.balls[2].mass = bad
		reject_initialize(arena, requested, "invalid final mass")
	arena.balls[2].mass = 1
	for bad in [Vector2.ZERO, Vector2(-1, 680), Vector2(NAN, 680), Vector2(640, INF)]:
		arena.arena_size = bad
		reject_initialize(arena, requested, "invalid arena size")
	arena.arena_size = Vector2(640, 680)
	arena.balls[2].character_definition = Resource.new()
	reject_initialize(arena, requested, "invalid final speed config type")
	arena.balls[2].character_definition = null
	arena.balls.append(null)
	reject_initialize(arena, requested + [Vector2(200, 100)], "null ball")
	arena.balls.pop_back()
	arena.balls.append(arena.balls[0])
	reject_initialize(arena, requested + [Vector2(200, 100)], "duplicate Ball reference")
	arena.free()

func test_tolerance() -> void:
	var arena := make_arena(2, 1)
	for gap in [-Arena.POSITION_EPS * 0.5, Arena.POSITION_EPS * 0.5, Arena.POSITION_EPS * 2]:
		var requested: Array = [Vector2(1, 1), Vector2(3 + gap, 1)]
		check(arena.initialize(1, requested).ok, "pair tolerance accepts contact and tiny overlap")
		check(positions(arena) == requested, "tolerated overlap not moved")
	var rejected := arena.validate_positions([Vector2(1, 1), Vector2(3 - Arena.POSITION_EPS * 2, 1)])
	check(not rejected.ok and "0 and 1" in rejected.error, "pair violation names both balls")
	var requested: Array = [Vector2(1 - Arena.POSITION_EPS * 0.5, 1), Vector2(5, 1)]
	check(arena.initialize(2, requested).ok and positions(arena) == requested, "wall tolerance accepts tiny boundary residual unchanged")
	check(not arena.validate_positions([Vector2(1 - Arena.POSITION_EPS * 2, 1), Vector2(5, 1)]).ok, "wall violation beyond tolerance rejected")
	var before := snapshot(arena)
	for i in 20:
		check(arena._correct_positions().ok, "valid position correction succeeds")
	check(snapshot(arena) == before, "repeated corrections do not drift valid state")
	arena.free()

func test_demo_grid() -> void:
	var arena := make_arena(100)
	for seed_value in 100:
		var before := snapshot(arena)
		var generated := arena.generate_demo_positions(seed_value)
		check(generated.ok, "grid finds 100 default balls without random retries")
		check(snapshot(arena) == before, "placement generation is read-only")
		check(arena.initialize_demo(seed_value).ok, "100-ball initialization succeeds")
		valid_geometry(arena, "100 balls seed %d" % seed_value)
		check(positions(arena) == generated.positions, "demo commits validated generated positions")
		var initialized := snapshot(arena)
		check(arena.initialize_demo(seed_value).ok and snapshot(arena) == initialized, "seed reproduces positions and velocities")
		for ball in arena.balls:
			check(ball.velocity.length() >= 139.9999 and ball.velocity.length() <= 230.0001, "100 balls preserve configured speed range")
	for i in 120:
		check(arena.step(1.0 / 120.0), "100-ball simulation step")
		valid_geometry(arena, "100 balls runtime")
	check(arena.position_failures == 0 and arena.solver_failures == 0 and arena.event_limit_hits == 0, "100-ball simulation no safety failure")
	arena.free()
	arena = make_arena(3, 10)
	arena.arena_size = Vector2(40, 20)
	var before := snapshot(arena)
	var result := arena.generate_demo_positions(1)
	check(not result.ok and "not a packing impossibility proof" in result.error, "grid failure states search limitation")
	check(snapshot(arena) == before, "failed grid changes no state")
	expected_errors += 1
	print("EXPECTED PLACEMENT ERROR: impossible demo grid")
	check(not arena.initialize_demo(1).ok and snapshot(arena) == before, "failed auto initialization is atomic")
	arena.free()
	arena = make_arena(0)
	check(arena.initialize(1, []).ok and arena.initialize_demo(1).ok, "empty arena initialization succeeds")
	arena.free()

func test_correction() -> void:
	for layout in [[Vector2(10, 50), Vector2(29, 50)], [Vector2(10, 50), Vector2(29, 50), Vector2(48, 50)], [Vector2(71, 50), Vector2(90, 50)], [Vector2(50, 10), Vector2(50, 29), Vector2(50, 48)], [Vector2(50, 50), Vector2(50, 50), Vector2(50, 50)]]:
		var arena := make_arena(layout.size(), 10)
		arena.arena_size = Vector2(100, 100)
		var velocity_before: Array = []
		for i in layout.size():
			arena.balls[i].position = layout[i]
			velocity_before.append(arena.balls[i].velocity)
		var result := arena._correct_positions()
		check(result.ok, "wall / chain / coincident correction converges: " + str(layout))
		if result.ok:
			check(result.iterations <= Arena.MAX_POSITION_ITERATIONS, "bounded successful correction")
			valid_geometry(arena, "corrected layout")
		for i in layout.size():
			check(arena.balls[i].velocity == velocity_before[i], "correction does not change velocity")
		arena.free()
	for masses in [[1.0, 1000.0], [1000.0, 1.0], [1e308, 1e308], [1e-308, 1e-308]]:
		var arena := make_arena(2, 10)
		arena.balls[0].position = Vector2(100, 100)
		arena.balls[1].position = Vector2(119, 100)
		for i in 2:
			arena.balls[i].mass = masses[i]
		check(arena._correct_positions().ok, "mass ratio correction stays finite")
		valid_geometry(arena, "mass ratio")
		arena.free()

func test_correction_failure() -> void:
	var arena := make_arena(3, 10)
	arena.arena_size = Vector2(40, 20)
	for i in 3:
		arena.balls[i].position = Vector2(10 + i * 10, 10)
	var before := snapshot(arena)
	var result := arena._correct_positions()
	check(not result.ok and "512 iterations" in result.error, "impossible correction terminates at iteration limit")
	check(snapshot(arena) == before, "failed correction commits no candidate positions")
	var notifications: Array = []
	arena.wall_collided.connect(func(ball: Ball, normal: Vector2): notifications.append([ball, normal]))
	arena.ball_collided.connect(func(group: Array[Ball]): notifications.append(group))
	expected_errors += 1
	print("EXPECTED PLACEMENT ERROR: impossible runtime correction")
	check(not arena.step(0.1), "step stops on correction failure")
	check(arena.position_failures == 1 and not arena.last_error.is_empty(), "step records explicit correction failure")
	check(arena.simulation_time == 0 and arena.solver_failures == 0 and arena.event_limit_hits == 0, "failed correction never enters CCD")
	check(notifications.is_empty(), "failed correction emits no collision events")
	arena.position_failures = 0
	check(snapshot(arena) == before, "failed step preserves all motion and elapsed time")
	arena.free()
	arena = make_arena(2, 10)
	arena.balls[0].position = Vector2(-1, 100)
	arena.balls[1].position = Vector2(INF, 100)
	var bytes_before := var_to_bytes(positions(arena))
	check(not arena._correct_positions().ok, "nonfinite position rejected before correction")
	check(var_to_bytes(positions(arena)) == bytes_before, "nonfinite final position leaves first ball unchanged")
	arena.free()

func test_nonfinite_step() -> void:
	var arena := make_arena(2, 10)
	for dt in [NAN, INF]:
		var before := snapshot(arena)
		expected_errors += 1
		print("EXPECTED PLACEMENT ERROR: nonfinite step duration")
		check(not arena.step(dt), "nonfinite duration is rejected")
		arena.position_failures = 0
		check(snapshot(arena) == before, "nonfinite duration preserves state")
	for velocity in [Vector2(NAN, 0), Vector2(INF, 0), Vector2(1e20, 0)]:
		arena.balls[1].velocity = velocity
		var before := var_to_bytes(snapshot(arena))
		expected_errors += 1
		print("EXPECTED PLACEMENT ERROR: nonfinite runtime speed")
		check(not arena.step(0.1), "nonfinite velocity or squared speed is rejected")
		arena.position_failures = 0
		check(var_to_bytes(snapshot(arena)) == before, "invalid final velocity prevents all movement")
	arena.balls[0].velocity = Vector2.ZERO
	arena.balls[1].velocity = Vector2.ZERO
	var before := snapshot(arena)
	expected_errors += 1
	print("EXPECTED PLACEMENT ERROR: unrepresentable movement scalar")
	check(not arena.step(1e40), "movement float32 overflow is rejected")
	arena.position_failures = 0
	check(snapshot(arena) == before, "failed movement commits no positions or elapsed time")
	arena.free()

func test_main_stops() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.select_scenario(2)
	main.set_process(false)
	main.current_scenario.set_process(false)
	main.set_rate(1)
	main.current_scenario.arena.balls[1].radius = 1000
	var before := snapshot(main.current_scenario.arena)
	expected_errors += 1
	print("EXPECTED PLACEMENT ERROR: UI pauses on invalid runtime geometry")
	main.advance_real_time(0.1)
	check(main.current_scenario.rate == 0 and main.current_scenario.accumulator == 0, "main stops fixed-step loop after failure")
	check("Stopped:" in main.status.text, "main displays failure")
	main.current_scenario.arena.position_failures = 0
	check(snapshot(main.current_scenario.arena) == before, "UI failure preserves motion")
	main.set_rate(2)
	check(main.current_scenario.rate == 0, "UI cannot accidentally resume unresolved failure")
	main.current_scenario.arena.balls[1].radius = 24
	check(main.current_scenario.arena.initialize_demo(42).ok, "corrected setup can reinitialize")
	main.set_rate(2)
	check(main.current_scenario.rate == 2 and main.status.tooltip_text.is_empty(), "successful reinitialization clears UI stop")
	main.free()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for test in [test_explicit_positions, test_tolerance, test_demo_grid, test_correction, test_correction_failure, test_nonfinite_step, test_main_stops]:
		test.call()
	print("PLACEMENT RESULT checks=%d failures=%d expected_errors=%d" % [checks, failures, expected_errors])
	quit(1 if failures else 0)
