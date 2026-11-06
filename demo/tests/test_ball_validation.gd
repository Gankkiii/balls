extends SceneTree
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var a := Ball.new()
	var b := Ball.new()
	var balls: Array[Ball] = [a, b]
	var size := Vector2(640, 680)
	var positions: Array = [Vector2(100, 200), Vector2(400, 200)]
	a.position = Vector2(60, 80)
	a.velocity = Vector2(3, 4)
	check(BallValidation.geometry_error(balls, size).is_empty(), "valid geometry")
	check(BallValidation.validate_positions(balls, size, positions).ok, "valid external positions")
	check(a.position == Vector2(60, 80) and a.velocity == Vector2(3, 4), "validation is read only")
	check(not BallValidation.geometry_error([a, a], size).is_empty(), "duplicate reference rejected")
	check(not BallValidation.geometry_error([a, null], size).is_empty(), "null reference rejected")
	check(not BallValidation.geometry_error(balls, Vector2(INF, 680)).is_empty(), "invalid arena rejected")
	for invalid in [[], [Vector2.ZERO, "bad"], [Vector2(NAN, 0), Vector2.ZERO], [Vector2.ZERO, Vector2(400, 200)], [Vector2(100, 200), Vector2(110, 200)]]:
		check(not BallValidation.validate_positions(balls, size, invalid).ok, "invalid positions rejected")
	var near_wall: Array = [Vector2(24.0 - 0.00005, 100), Vector2(400, 200)]
	check(BallValidation.validate_positions(balls, size, near_wall).ok, "original position tolerance retained")
	check(BallValidation.speed_config(a, 0).ok and a.character_definition == null, "fallback validation does not assign config")
	b.character_definition = Resource.new()
	check(not BallValidation.speed_config(b, 1).ok, "wrong definition type rejected")
	var bad := BallConfig.new()
	bad.max_initial_speed = 1e20
	b.character_definition = bad
	check(not BallValidation.speed_config(b, 1).ok, "finite speed with overflowing square rejected")
	check(BallValidation.velocity_is_representable(Vector2(3, 4)), "finite runtime velocity accepted")
	check(not BallValidation.velocity_is_representable(Vector2(1e20, 0)), "runtime square overflow rejected")
	check(BallValidation.time_error(1.0, 0.0).is_empty() and BallValidation.time_error(1.0, -1.0).is_empty(), "nonpositive finite step remains allowed")
	check(not BallValidation.time_error(1e308, 1e308).is_empty(), "time addition overflow rejected")
	check(not BallValidation.runtime_velocity_error([a, null]).is_empty(), "runtime null rejected")
	check(BallValidation.solver_input_error(balls, [{"normal": Vector2.RIGHT}]).is_empty(), "solver input accepted")
	check(not BallValidation.solver_input_error(balls, [{"normal": Vector2.ZERO}]).is_empty(), "zero solver normal rejected")
	check(BallValidation.solver_velocities_are_representable(PackedFloat64Array([3, 4, 0, 0])), "solver output accepted")
	check(not BallValidation.solver_velocities_are_representable(PackedFloat64Array([1e39, 0])), "solver output overflow rejected")
	# 第二球配置失败时，工厂不能先写回第一球；不需要创建 Arena。
	var original_list := balls
	var original_positions := positions.duplicate()
	var result := BallFactory.initialize_positions(balls, size, 42, positions)
	check(not result.ok and a.position == Vector2(60, 80) and a.velocity == Vector2(3, 4), "factory failure leaves earlier ball unchanged")
	check(is_same(original_list, balls) and balls[0] == a and balls[1] == b, "factory failure retains list and ball identities")
	check(positions == original_positions, "factory leaves caller positions unchanged")
	b.character_definition = null
	check(BallFactory.initialize_positions(balls, size, 42, positions).ok, "factory directly initializes manual positions")
	check(a.position == positions[0] and b.position == positions[1], "manual positions are not relocated")
	check(is_same(original_list, balls), "factory success retains list identity")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for ball in balls:
		var angle := rng.randf_range(0.0, TAU)
		var speed := rng.randf_range(140.0, 230.0)
		check(ball.velocity == Vector2.from_angle(angle) * speed, "manual initialization preserves sample order")
	var before := [a.position, a.velocity, b.position, b.velocity]
	check(BallFactory.generate_demo_positions(balls, size, 42).ok, "factory generates positions without arena")
	check(before == [a.position, a.velocity, b.position, b.velocity], "position generation is read only")
	var arena := Arena.new()
	arena.register_ball(a)
	arena.register_ball(b)
	var renderer := BallRenderer.new()
	renderer.balls = arena.balls
	var shared_list := arena.balls
	check(arena.initialize_demo(7).ok, "compatibility entry initializes")
	check(is_same(shared_list, arena.balls) and is_same(renderer.balls, arena.balls), "compatibility entry preserves renderer list")
	check(arena.balls[0] == a and arena.balls[1] == b, "compatibility entry preserves ball objects")
	check(a.current_health == null and a.max_health == null and a.skills.is_empty(), "initialization does not add combat state")
	renderer.free()
	arena.free()
	print("VALIDATION RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
