extends SceneTree
## 故意触发求解失败和数值溢出日志，验证 Arena 不提交部分或非有限状态。
var failures := 0
var checks := 0
var expected_errors := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func make_ball(x: float, speed: float, mass: float) -> Ball:
	var ball := Ball.new()
	ball.radius = 10
	ball.position = Vector2(x, 100)
	ball.velocity = Vector2(speed, 0)
	ball.mass = mass
	return ball

func verify_failure(items: Array[Ball], label: String) -> void:
	var arena := Arena.new()
	arena.arena_size = Vector2(1e30, 1e30)
	var before: Array[Vector2] = []
	var contacts: Array = []
	for i in items.size():
		before.append(items[i].velocity)
		arena.register_ball(items[i])
		if i > 0:
			contacts.append({"a": i - 1, "b": i, "normal": Vector2.LEFT})
	var result := CollisionSolver.resolve(items, contacts)
	check(not result.ok and not result.has("velocities"), label + " solver refuses to expose unsafe output")
	var groups: Array = []
	var walls: Array = []
	arena.ball_collided.connect(func(group: Array[Ball]): groups.append(group))
	arena.wall_collided.connect(func(ball: Ball, normal: Vector2): walls.append([ball, normal]))
	expected_errors += 1
	print("EXPECTED ERROR: ", label)
	arena.step(0.01)
	check(arena.solver_failures == 1, label + " Arena records failure")
	check(arena.event_limit_hits == 0, label + " failure distinct from CCD event limit")
	check(groups.is_empty() and walls.is_empty(), label + " no collision notifications")
	for i in items.size():
		check(items[i].velocity == before[i], label + " no partial velocity commit")
		check(items[i].velocity.is_finite(), label + " preserves finite runtime state")
	check(arena.simulation_time == 0.0, label + " discards remaining time")
	arena.free()

func _initialize() -> void:
	verify_failure([make_ball(100, 1, 1e12), make_ball(120, 0, 1), make_ball(140, -1, 1e12)], "ill-conditioned system does not converge")
	verify_failure([make_ball(100, 1, 1e308), make_ball(120, -1, 1e308)], "finite large masses overflow impulse")
	verify_failure([make_ball(100, 1, 1e-308), make_ball(120, -1, 1e-308)], "finite small masses overflow coupling matrix")
	verify_failure([make_ball(100, 1e19, 1), make_ball(120, 0, 0.001)], "finite double result overflows stored squared speed")
	print("FAILURE PATH RESULT checks=%d failures=%d expected_errors=%d" % [checks, failures, expected_errors])
	quit(1 if failures else 0)
