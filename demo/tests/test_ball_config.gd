extends SceneTree
## 验证配置资源、逐球速率配置，以及初始化和运行状态的边界。
const DefaultConfig := preload("res://configs/default_ball.tres")
var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func make_arena() -> Arena:
	var arena := Arena.new()
	for i in 2:
		arena.register_ball(Ball.new())
	return arena

func test_resource() -> void:
	check(DefaultConfig is BallConfig, "default resource has concrete BallConfig schema")
	check(DefaultConfig.min_initial_speed == 140.0, "default minimum preserves demo speed")
	check(DefaultConfig.max_initial_speed == 230.0, "default maximum preserves demo speed")
	var config := BallConfig.new()
	config.min_initial_speed = 31.5
	config.max_initial_speed = 92.25
	check(DefaultConfig.min_initial_speed == 140.0 and DefaultConfig.max_initial_speed == 230.0, "new config is independent from the shared default resource")
	var arena := Arena.new()
	var properties: Array = arena.get_script().get_script_property_list()
	for name in ["min_initial_speed", "max_initial_speed"]:
		check(not properties.any(func(property: Dictionary) -> bool: return property["name"] == name), "Arena no longer owns " + name)
	arena.free()

func test_default_seed_compatibility() -> void:
	var arena := make_arena()
	# 未配置的球沿用默认配置，不改写未分配的关联。
	for seed_value in 20:
		arena.initialize_demo(seed_value)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for i in arena.balls.size():
			var ball := arena.balls[i]
			var x := arena.arena_size.x * (0.28 if i == 0 else 0.72)
			var y := rng.randf_range(ball.radius + 40, arena.arena_size.y - ball.radius - 40)
			var angle := rng.randf_range(0.0, TAU)
			var speed := rng.randf_range(DefaultConfig.min_initial_speed, DefaultConfig.max_initial_speed)
			check(ball.position == Vector2(x, y), "seeded placement is unchanged")
			check(ball.velocity.is_equal_approx(Vector2.from_angle(angle) * speed), "seeded default velocity is unchanged")
	check(arena.balls[0].character_definition == null, "initialization does not fill an unassigned definition")
	check(arena.balls[1].character_definition == null, "default fallback does not assign another ball's definition")
	arena.free()

func verify_rejected_config(config: Resource, label: String, second_radius: float = 24.0) -> void:
	var arena := make_arena()
	# 预检失败时不能初始化前面的合法球，也不能重置竞技场计数。
	arena.balls[1].character_definition = config
	arena.balls[1].radius = second_radius
	arena.balls[0].position = Vector2(80, 90)
	arena.balls[0].velocity = Vector2(10, 20)
	arena.balls[1].position = Vector2(400, 500)
	arena.balls[1].velocity = Vector2(30, 40)
	arena.simulation_time = 3.5
	arena.event_limit_hits = 2
	arena.solver_failures = 1
	print("EXPECTED CONFIG ERROR: ", label)
	arena.initialize_demo(42)
	check(arena.balls[0].position == Vector2(80, 90) and arena.balls[0].velocity == Vector2(10, 20), "invalid second config prevents partial initialization of the first ball")
	check(arena.balls[1].position == Vector2(400, 500) and arena.balls[1].velocity == Vector2(30, 40), "invalid config preserves that ball's runtime motion")
	check(arena.simulation_time == 3.5 and arena.event_limit_hits == 2 and arena.solver_failures == 1, "invalid config preserves arena counters")
	check(arena.balls[1].character_definition == config, "invalid config reference is not silently replaced")
	arena.free()

func test_invalid_configuration() -> void:
	verify_rejected_config(Resource.new(), "non-BallConfig character_definition")
	var invalid_ranges: Array[Vector2] = [
		Vector2(-1.0, 10.0),
		Vector2(0.0, -1.0),
		Vector2(10.0, 5.0),
		Vector2(NAN, 10.0),
		Vector2(0.0, NAN),
		Vector2(INF, INF),
		Vector2(0.0, INF),
	]
	for invalid_range in invalid_ranges:
		var config := BallConfig.new()
		config.min_initial_speed = invalid_range.x
		config.max_initial_speed = invalid_range.y
		verify_rejected_config(config, "invalid speed range " + str(invalid_range))

func test_representation_and_atomic_generation() -> void:
	# 不使用 Vector2 保存测试区间，否则测试数据本身就已从 double 溢出。
	for limits in [[1e39, 1e39, "fixed 1e39"], [0.0, 1e39, "range up to 1e39"], [1e100, 1e100, "fixed 1e100"], [1e20, 1e20, "squared speed overflow at 1e20"], [0.0, 1e20, "range with squared speed overflow"], [1e-50, 1e-50, "positive speed underflow at 1e-50"]]:
		var config := BallConfig.new()
		config.min_initial_speed = limits[0]
		config.max_initial_speed = limits[1]
		check(is_finite(config.min_initial_speed) and is_finite(config.max_initial_speed), "representation regression uses finite double values")
		verify_rejected_config(config, "finite but not representable speed range: " + limits[2])
	# 第二球配置合法，但无效几何使生成阶段失败。第一球也不能已被写回。
	verify_rejected_config(null, "second ball generates non-finite motion from invalid radius", INF)
	var arena := make_arena()
	var high := BallConfig.new()
	high.min_initial_speed = 1e18
	high.max_initial_speed = 1e18
	for ball in arena.balls:
		ball.character_definition = high
	arena.simulation_time = 3.5
	arena.event_limit_hits = 2
	arena.solver_failures = 1
	for seed_value in 8:
		arena.initialize_demo(seed_value)
		for ball in arena.balls:
			check(ball.velocity.is_finite() and is_finite(ball.velocity.length_squared()), "large representable speed initializes finite vector and magnitude")
			check(absf(ball.velocity.length() / 1e18 - 1.0) < 1e-6, "large representable fixed speed is not silently clamped")
	check(arena.simulation_time == 0.0 and arena.event_limit_hits == 0 and arena.solver_failures == 0, "successful staged initialization commits counter reset")
	arena.free()

func test_per_ball_configuration() -> void:
	var arena := make_arena()
	var fixed := BallConfig.new()
	fixed.min_initial_speed = 375.0
	fixed.max_initial_speed = 375.0
	var stationary := BallConfig.new()
	stationary.min_initial_speed = 0.0
	stationary.max_initial_speed = 0.0
	arena.balls[0].character_definition = fixed
	arena.balls[1].character_definition = stationary
	for seed_value in 8:
		arena.initialize_demo(seed_value)
		check(absf(arena.balls[0].velocity.length() - 375.0) < 0.0001, "per-ball fixed speed comes from its config")
		check(arena.balls[1].velocity == Vector2.ZERO, "zero-speed config is supported")
	var previous := arena.balls[0].velocity
	fixed.min_initial_speed = 150.0
	fixed.max_initial_speed = 150.0
	check(arena.balls[0].velocity == previous, "editing config does not retroactively change runtime velocity")
	arena.initialize_demo(42)
	check(absf(arena.balls[0].velocity.length() - 150.0) < 0.0001, "next initialization reads the current config")
	check(arena.balls[0].character_definition == fixed, "initialization retains per-ball config reference")
	check(stationary.min_initial_speed == 0.0 and stationary.max_initial_speed == 0.0, "initialization does not mutate config values")
	arena.free()

func test_shared_range() -> void:
	var arena := make_arena()
	var config := BallConfig.new()
	config.min_initial_speed = 31.5
	config.max_initial_speed = 92.25
	for ball in arena.balls:
		ball.character_definition = config
	var unique_speeds: Dictionary = {}
	for seed_value in 32:
		arena.initialize_demo(seed_value)
		for ball in arena.balls:
			var speed := ball.velocity.length()
			check(speed >= 31.4999 and speed <= 92.2501, "custom range is honored for both balls")
			unique_speeds[speed] = true
	check(unique_speeds.size() > 1, "range still produces varied initial speeds")
	check(is_same(arena.balls[0].character_definition, arena.balls[1].character_definition), "multiple balls can share one config resource")
	check(config.min_initial_speed == 31.5 and config.max_initial_speed == 92.25, "sampling leaves shared config unchanged")
	arena.free()

func test_main_configuration() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	check(main.arena.balls.size() == 2, "main still creates two balls")
	for ball in main.arena.balls:
		check(ball.character_definition == DefaultConfig, "main explicitly associates each ball with the default config")
		check(ball.velocity.length() >= 139.9999 and ball.velocity.length() <= 230.0001, "main starts with the configured speed range")
	main.free()

func run() -> void:
	test_resource()
	test_default_seed_compatibility()
	test_invalid_configuration()
	test_representation_and_atomic_generation()
	test_per_ball_configuration()
	test_shared_range()
	test_main_configuration()
	print("CONFIG RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
