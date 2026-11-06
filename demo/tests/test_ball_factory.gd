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

func config(radius: float, mass: float) -> BallConfig:
	var value := BallConfig.new()
	value.radius = radius
	value.mass = mass
	return value

func run() -> void:
	var small := config(10.0, 1.0)
	var large := config(20.0, 3.0)
	var result := BallFactory.create_demo([small, large], Vector2(640, 680), 42)
	check(result.ok, "different configs create a complete batch")
	if result.ok:
		var a: Ball = result.balls[0]
		var b: Ball = result.balls[1]
		check(a.radius == 10.0 and b.radius == 20.0 and a.mass == 1.0 and b.mass == 3.0, "each ball reads its own size and mass")
		check(a.character_definition == small and b.character_definition == large, "config references retained")
		check(a.current_health == null and a.max_health == null and b.current_health == null and b.max_health == null, "health is untouched")
		check(a.skills.is_empty() and b.skills.is_empty(), "no skills initialized")
		var arena := Arena.new()
		arena.register_ball(a)
		arena.register_ball(b)
		a.position = Vector2(100, 300)
		b.position = Vector2(140, 300)
		a.velocity = Vector2(100, 0)
		b.velocity = Vector2.ZERO
		check(arena.step(0.2), "configured balls collide successfully")
		check(a.velocity.is_equal_approx(Vector2(-50, 0)) and b.velocity.is_equal_approx(Vector2(50, 0)), "configured mass controls analytic collision response")
		check(a.position.is_equal_approx(Vector2(105, 300)) and b.position.is_equal_approx(Vector2(145, 300)), "configured radii control contact time")
		small.radius = 15.0
		small.mass = 2.0
		check(a.radius == 10.0 and a.mass == 1.0, "config edits do not mutate existing balls")
		var next := BallFactory.create_demo([small], arena.arena_size, 42)
		check(next.ok and next.balls[0].radius == 15.0 and next.balls[0].mass == 2.0, "next creation reads updated config")
		arena.free()
	var fallback := BallFactory.create_demo([null], Vector2(640, 680), 42)
	check(fallback.ok and fallback.balls[0].radius == 24.0 and fallback.balls[0].mass == 1.0, "null config uses defaults")
	check(fallback.balls[0].character_definition == null, "fallback preserves unassigned definition")
	var shared := BallFactory.create_demo([small, small], Vector2(640, 680), 42)
	check(shared.ok and shared.balls[0] != shared.balls[1], "shared config creates independent ball objects")
	check(small.radius == 15.0 and small.mass == 2.0, "creation leaves config unchanged")
	for field in ["radius", "mass"]:
		for value in [0.0, -1.0, NAN, INF]:
			var invalid := config(24.0, 1.0)
			invalid.set(field, value)
			reject([small, invalid], "invalid " + field)
	for value in [1e-50, 1e39, 400.0]:
		reject([small, config(value, 1.0)], "unrepresentable or oversized radius")
	reject([config(300.0, 1.0), config(300.0, 1.0)], "impossible demo grid")
	var bad_speed := config(24.0, 1.0)
	bad_speed.min_initial_speed = -1.0
	reject([small, bad_speed], "speed failure after geometry creation")
	for count in [1, 2, 5, 20, 100]:
		var scene = load("res://scenes/balls_%d.tscn" % count).instantiate()
		scene.ball_config = config(12.0, 2.5)
		scene.scenario_seed = 42
		root.add_child(scene)
		scene.set_process(false)
		check(scene.arena.last_error.is_empty() and scene.arena.balls.size() == count, "custom config starts scene")
		for ball in scene.arena.balls:
			check(ball.radius == 12.0 and ball.mass == 2.5, "scene uses configured geometry")
		check(is_same(scene.ball_renderer.balls, scene.arena.balls), "renderer reads configured balls")
		scene.free()
	var failed_scene = load("res://scenes/balls_2.tscn").instantiate()
	failed_scene.ball_config = config(INF, 1.0)
	print("EXPECTED CONFIG ERROR: invalid scene geometry")
	root.add_child(failed_scene)
	check(failed_scene.rate == 0 and not failed_scene.arena.last_error.is_empty(), "invalid scene pauses with reason")
	check(failed_scene.arena.balls.is_empty() and failed_scene.ball_renderer.balls.is_empty(), "failed scene exposes no partial balls")
	check(failed_scene.arena.simulation_time == 0.0, "failed scene does not advance")
	failed_scene.free()
	print("FACTORY RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func reject(configs: Array[BallConfig], label: String) -> void:
	print("EXPECTED CONFIG ERROR: ", label)
	var result := BallFactory.create_demo(configs, Vector2(640, 680), 42)
	check(not result.ok and not result.error.is_empty(), label + " rejected")
	check(not result.has("balls"), label + " returns no partial batch")
