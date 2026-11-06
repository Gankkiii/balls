extends SceneTree
var failures := 0
var checks := 0
var cases := 0
var failed_cases := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func run_case(test: Callable) -> void:
	cases += 1
	var before := failures
	test.call()
	if failures != before:
		failed_cases += 1

func _initialize() -> void:
	call_deferred("run")

func test_defaults() -> void:
	var ball := Ball.new()
	check(ball.position == Vector2.ZERO, "default position")
	check(ball.velocity == Vector2.ZERO, "default velocity")
	check(ball.radius == 24.0, "default radius")
	check(ball.mass == 1.0, "default mass")
	check(ball.color == Color("55d6be"), "default color")

func test_instance_isolation() -> void:
	var first := Ball.new()
	var second := Ball.new()
	first.position = Vector2(50, 60)
	first.velocity = Vector2(10, -20)
	first.radius = 10
	first.mass = 2
	first.color = Color.RED
	check(second.position == Vector2.ZERO, "positions are independent")
	check(second.velocity == Vector2.ZERO, "velocities are independent")
	check(second.radius == 24.0, "radii are independent")
	check(second.mass == 1.0, "masses are independent")
	check(second.color == Color("55d6be"), "colors are independent")

func test_state_only() -> void:
	var ball := Ball.new()
	check(ball is RefCounted, "state uses reference-counted lifetime")
	check(not is_instance_of(ball, Node), "state does not require a scene node")
	check(ball.get_script().get_script_method_list().is_empty(), "state defines no behavior")
	check(ball.get_script().get_script_signal_list().is_empty(), "collision notifications belong to Arena")

func test_registration() -> void:
	var arena := Arena.new()
	var ball := Ball.new()
	arena.register_ball(ball)
	arena.register_ball(ball)
	check(arena.balls.size() == 1, "registration is idempotent")
	check(is_same(arena.balls[0], ball), "Arena keeps the original state")
	check(arena.get_child_count() == 0, "simulation needs no rendering nodes")
	arena.remove_ball(ball)
	arena.remove_ball(ball)
	check(arena.balls.is_empty(), "removal is idempotent")
	check(is_instance_valid(ball), "removal does not destroy externally held state")
	arena.register_ball(ball)
	check(is_same(arena.balls[0], ball), "removed state can be registered again")
	arena.free()

func test_external_motion() -> void:
	var arena := Arena.new()
	var ball := Ball.new()
	ball.position = Vector2(100, 100)
	ball.velocity = Vector2(30, 40)
	arena.register_ball(ball)
	arena.step(1.0)
	check(ball.position == Vector2(130, 140), "Arena advances the stored position")
	check(ball.velocity == Vector2(30, 40), "unobstructed movement preserves velocity")
	arena.remove_ball(ball)
	arena.step(1.0)
	check(ball.position == Vector2(130, 140), "removed state is no longer simulated")
	arena.free()

func test_collision_notifications() -> void:
	var arena := Arena.new()
	var first := Ball.new()
	first.radius = 10
	first.position = Vector2(20, 100)
	first.velocity = Vector2(-100, 0)
	arena.register_ball(first)
	var wall_events: Array = []
	arena.wall_collided.connect(func(ball: Ball, normal: Vector2): wall_events.append([ball, normal]))
	arena.step(0.2)
	check(wall_events.size() == 1, "Arena emits one wall notification")
	if wall_events.size() == 1:
		check(is_same(wall_events[0][0], first), "wall notification identifies the ball")
		check(wall_events[0][1] == Vector2.RIGHT, "wall notification contains inward normal")
	var second := Ball.new()
	second.radius = 10
	first.position = Vector2(100, 100)
	first.velocity = Vector2(100, 0)
	second.position = Vector2(140, 100)
	second.velocity = Vector2(-100, 0)
	arena.register_ball(second)
	var pair_events: Array = []
	arena.ball_collided.connect(func(a: Ball, b: Ball): pair_events.append([a, b]))
	arena.step(0.2)
	check(pair_events.size() == 1, "Arena emits one notification per ball pair")
	if pair_events.size() == 1:
		check(is_same(pair_events[0][0], first) and is_same(pair_events[0][1], second), "pair notification identifies both balls")
	check(first.velocity == Vector2(-100, 0) and second.velocity == Vector2(100, 0), "notifications preserve elastic collision response")
	arena.free()

func test_renderer_binding() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	var arena: Arena = main.arena
	var renderer: BallRenderer = main.ball_renderer
	check(renderer.get_parent() == arena, "renderer uses arena-local coordinates")
	check(is_same(renderer.balls, arena.balls), "renderer reads the live state list")
	check(renderer.balls.size() == 2, "main scene creates two visible states")
	var first := arena.balls[0]
	check(first.color == Color("50e0bd") and arena.balls[1].color == Color("ffb45f"), "main preserves ball colors")
	var at := first.position
	var motion := first.velocity
	renderer._process(1000)
	check(first.position == at and first.velocity == motion, "render updates do not advance simulation")
	arena.remove_ball(first)
	check(renderer.balls.size() == 1 and not renderer.balls.has(first), "renderer observes removal")
	arena.register_ball(first)
	check(renderer.balls.size() == 2 and is_same(renderer.balls[1], first), "renderer observes re-registration")
	main.free()
	check(is_instance_valid(first), "state can outlive the main scene")

func run() -> void:
	for test in [test_defaults, test_instance_isolation, test_state_only, test_registration, test_external_motion, test_collision_notifications, test_renderer_binding]:
		run_case(test)
	print("RESULT cases=%d passed=%d failed=%d checks=%d failures=%d" % [cases, cases - failed_cases, failed_cases, checks, failures])
	quit(1 if failures else 0)
