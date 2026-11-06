extends SceneTree
var failures := 0
var checks := 0
var cases := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func close_vec(a: Vector2, b: Vector2, tolerance: float = 0.002) -> bool:
	return a.distance_to(b) <= tolerance

func make_ball(at: Vector2, velocity: Vector2, mass: float = 1.0) -> Ball:
	var ball := Ball.new()
	ball.radius = 10
	ball.position = at
	ball.velocity = velocity
	ball.mass = mass
	return ball

func make_arena(items: Array[Ball], order: Array = []) -> Arena:
	var arena := Arena.new()
	arena.arena_size = Vector2(1000, 1000)
	if order.is_empty():
		for ball in items:
			arena.register_ball(ball)
	else:
		for index in order:
			arena.register_ball(items[index])
	return arena

func permutations(values: Array) -> Array:
	if values.is_empty():
		return [[]]
	var result: Array = []
	for i in values.size():
		var tail := values.duplicate()
		tail.remove_at(i)
		for suffix in permutations(tail):
			var order: Array = [values[i]]
			order.append_array(suffix)
			result.append(order)
	return result

func check_energy(arena: Arena, before: float, label: String) -> void:
	check(absf(arena.kinetic_energy() - before) <= maxf(0.001, before * 1e-5), label + " energy conserved")
	check(arena.event_limit_hits == 0 and arena.solver_failures == 0, label + " no safety limit")

func check_list(events: Array, expected: Array[Ball], label: String) -> void:
	check(events.size() == 1, label + " emits once per time")
	if events.size() == 1:
		check(events[0].size() == expected.size(), label + " no duplicated or extraneous balls")
		for ball in expected:
			check(events[0].has(ball), label + " includes participant")

func test_two_ball_masses() -> void:
	cases += 1
	var a := make_ball(Vector2(100, 100), Vector2(100, 30), 2)
	var b := make_ball(Vector2(120, 100), Vector2(-50, -20), 1)
	var arena := make_arena([a, b])
	var energy := arena.kinetic_energy()
	var momentum := arena.momentum()
	arena.step(0.001)
	check(close_vec(a.velocity, Vector2(0, 30)) and close_vec(b.velocity, Vector2(150, -20)), "unequal pair preserves analytic response and tangent")
	check_energy(arena, energy, "unequal pair")
	check(close_vec(arena.momentum(), momentum), "unequal pair momentum")
	arena.free()

func test_three_ball_symmetry() -> void:
	for order in permutations([0, 1, 2]):
		for instant in [false, true]:
			cases += 1
			var offset := 0.0 if instant else 10.0
			var items: Array[Ball] = [
				make_ball(Vector2(100 - offset, 100), Vector2(100, 0)),
				make_ball(Vector2(120, 100), Vector2.ZERO),
				make_ball(Vector2(140 + offset, 100), Vector2(-100, 0)),
			]
			var arena := make_arena(items, order)
			var events: Array = []
			arena.ball_collided.connect(func(group: Array[Ball]):
				events.append(group)
				check(close_vec(items[0].velocity, Vector2(-100, 0)) and close_vec(items[1].velocity, Vector2.ZERO) and close_vec(items[2].velocity, Vector2(100, 0)), "symmetric callback only sees complete solution"))
			var energy := arena.kinetic_energy()
			arena.step(0.01 if instant else 0.11)
			check_list(events, items, "symmetric three-ball " + str(order))
			check_energy(arena, energy, "symmetric three-ball")
			check(close_vec(arena.momentum(), Vector2.ZERO), "symmetric three-ball momentum")
			check(close_vec(items[1].position, Vector2(120, 100)), "symmetric center stays still")
			arena.free()

func test_unequal_chain() -> void:
	for order in permutations([0, 1, 2]):
		cases += 1
		var items: Array[Ball] = [
			make_ball(Vector2(100, 100), Vector2(60, 15), 1),
			make_ball(Vector2(120, 100), Vector2(0, -5), 2),
			make_ball(Vector2(140, 100), Vector2(-30, 20), 3),
		]
		var arena := make_arena(items, order)
		var energy := arena.kinetic_energy()
		var momentum := arena.momentum()
		arena.step(0.001)
		# In 1D a connected active chain reflects relative to center-of-mass velocity (-5).
		check(close_vec(items[0].velocity, Vector2(-70, 15)) and close_vec(items[1].velocity, Vector2(-10, -5)) and close_vec(items[2].velocity, Vector2(20, 20)), "unequal chain simultaneous analytic solution")
		check_energy(arena, energy, "unequal chain")
		check(close_vec(arena.momentum(), momentum), "unequal chain momentum")
		arena.free()

func test_resting_chain() -> void:
	for order in permutations([0, 1, 2]):
		cases += 1
		var items: Array[Ball] = [
			make_ball(Vector2(100, 100), Vector2(90, 0)),
			make_ball(Vector2(120, 100), Vector2.ZERO),
			make_ball(Vector2(140, 100), Vector2.ZERO),
		]
		var arena := make_arena(items, order)
		var events: Array = []
		arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
		var energy := arena.kinetic_energy()
		var momentum := arena.momentum()
		arena.step(0.01)
		check(close_vec(items[0].velocity, Vector2(-30, 0)) and close_vec(items[1].velocity, Vector2(60, 0)) and close_vec(items[2].velocity, Vector2(60, 0)), "resting chain uses chosen simultaneous rigid-impact model")
		check_list(events, items, "resting chain")
		check_energy(arena, energy, "resting chain")
		check(close_vec(arena.momentum(), momentum), "resting chain momentum")
		arena.free()

func test_disjoint_groups() -> void:
	for order in permutations([0, 1, 2, 3]):
		cases += 1
		var items: Array[Ball] = [
			make_ball(Vector2(100, 100), Vector2(100, 0)), make_ball(Vector2(140, 100), Vector2(-100, 0)),
			make_ball(Vector2(500, 500), Vector2(100, 0)), make_ball(Vector2(540, 500), Vector2(-100, 0)),
		]
		var arena := make_arena(items, order)
		var events: Array = []
		arena.ball_collided.connect(func(group: Array[Ball]):
			events.append(group)
			for i in 4:
				check(close_vec(items[i].velocity, Vector2(-100 if i % 2 == 0 else 100, 0)), "disjoint callbacks see every group committed"))
		var energy := arena.kinetic_energy()
		arena.step(0.11)
		check_list(events, items, "disjoint simultaneous groups")
		check_energy(arena, energy, "disjoint groups")
		check(close_vec(arena.momentum(), Vector2.ZERO), "disjoint momentum")
		arena.free()

func test_wall_contacts() -> void:
	for order in [[0, 1], [1, 0]]:
		for resting in [false, true]:
			cases += 1
			var items: Array[Ball] = [
				make_ball(Vector2(10 if resting else 20, 100), Vector2(0 if resting else -10, 0)),
				make_ball(Vector2(30 if resting else 50, 100), Vector2(-10 if resting else -20, 0)),
			]
			var arena := make_arena(items, order)
			var groups: Array = []
			var walls: Array = []
			arena.ball_collided.connect(func(group: Array[Ball]): groups.append(group))
			arena.wall_collided.connect(func(ball: Ball, normal: Vector2):
				walls.append([ball, normal])
				check(close_vec(items[1].velocity, Vector2(10 if resting else 20, 0)), "wall callback sees pair result"))
			var energy := arena.kinetic_energy()
			arena.step(0.01 if resting else 1.01)
			check(close_vec(items[0].velocity, Vector2(0 if resting else 10, 0)) and close_vec(items[1].velocity, Vector2(10 if resting else 20, 0)), "wall and pair solve together")
			check_list(groups, items, "wall and pair")
			check(walls.size() == 1 and walls[0][0] == items[0] and walls[0][1] == Vector2.RIGHT, "one wall impulse notification with inward normal")
			check_energy(arena, energy, "wall and pair")
			arena.free()
	cases += 1
	var corner := make_ball(Vector2(20, 20), Vector2(-10, -10))
	var other := make_ball(Vector2(50, 10), Vector2(-20, 0))
	var arena := make_arena([corner, other])
	var walls: Array = []
	arena.wall_collided.connect(func(ball: Ball, normal: Vector2): walls.append([ball, normal]))
	var energy := arena.kinetic_energy()
	arena.step(1.01)
	check(close_vec(corner.velocity, Vector2(10, 10)) and close_vec(other.velocity, Vector2(20, 0)), "corner and pair simultaneous")
	check(walls.size() == 2, "corner emits two actual wall impulses, resting zero-impulse wall omitted")
	check_energy(arena, energy, "corner and pair")
	arena.free()

func test_event_membership() -> void:
	cases += 1
	var first := make_ball(Vector2(100, 100), Vector2(10, 0))
	var second := make_ball(Vector2(120, 100), Vector2(-10, 0))
	var separating := make_ball(Vector2(140, 100), Vector2(30, 0))
	var wall_only := make_ball(Vector2(10, 500), Vector2(-10, 0))
	var idle := make_ball(Vector2(500, 500), Vector2.ZERO)
	var arena := make_arena([first, second, separating, wall_only, idle])
	var events: Array = []
	arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
	arena.step(0.01)
	check_list(events, [first, second], "event excludes separating, idle, and wall-only balls")
	check(wall_only.velocity == Vector2(10, 0), "independent wall solved in same event")
	arena.free()
	cases += 1
	first = make_ball(Vector2(100, 100), Vector2.ZERO)
	second = make_ball(Vector2(120, 100), Vector2.ZERO)
	arena = make_arena([first, second])
	events = []
	arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
	arena.step(0.1)
	check(events.is_empty(), "resting contacts alone emit no event")
	arena.free()

func test_same_time_waves() -> void:
	for order in permutations([0, 1, 2]):
		cases += 1
		var items: Array[Ball] = [
			make_ball(Vector2(100, 100), Vector2(10, 0)),
			make_ball(Vector2(120, 100), Vector2.ZERO),
			make_ball(Vector2(140, 100), Vector2(1, 0)),
		]
		var arena := make_arena(items, order)
		var events: Array = []
		arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
		var energy := arena.kinetic_energy()
		arena.step(0.01)
		check(close_vec(items[0].velocity, Vector2.ZERO) and close_vec(items[1].velocity, Vector2(1, 0)) and close_vec(items[2].velocity, Vector2(10, 0)), "newly closing contact resolved before notifying")
		check_list(events, items, "multiple waves one timestamp")
		check_energy(arena, energy, "multiple waves")
		arena.free()

func test_different_times() -> void:
	cases += 1
	var items: Array[Ball] = [
		make_ball(Vector2(100, 100), Vector2(100, 0)), make_ball(Vector2(140, 100), Vector2(-100, 0)),
		make_ball(Vector2(500, 500), Vector2(100, 0)), make_ball(Vector2(560, 500), Vector2(-100, 0)),
	]
	var arena := make_arena(items)
	var events: Array = []
	arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
	arena.step(0.21)
	check(events.size() == 2, "different times within one step remain separate notifications")
	if events.size() == 2:
		check(events[0].has(items[0]) and events[0].has(items[1]) and events[0].size() == 2, "first time membership")
		check(events[1].has(items[2]) and events[1].has(items[3]) and events[1].size() == 2, "second time membership")
	arena.free()

func test_independent_near_future_contact() -> void:
	cases += 1
	var items: Array[Ball] = [
		make_ball(Vector2(100, 100), Vector2(10, 0)), make_ball(Vector2(120, 100), Vector2.ZERO),
		make_ball(Vector2(500, 500), Vector2(10, 0)), make_ball(Vector2(520.000061, 500), Vector2.ZERO),
	]
	var arena := make_arena(items)
	var events: Array = []
	arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
	arena.step(0.001)
	check(events.size() == 2, "position slop does not absorb unrelated later collision")
	if events.size() == 2:
		check(events[0].size() == 2 and events[0].has(items[0]) and events[0].has(items[1]), "first touching group alone")
		check(events[1].size() == 2 and events[1].has(items[2]) and events[1].has(items[3]), "near future group remains its own time")
	arena.free()

func test_connected_future_contact() -> void:
	cases += 1
	var items: Array[Ball] = [
		make_ball(Vector2(100, 100), Vector2(10, 0)),
		make_ball(Vector2(120, 100), Vector2.ZERO),
		make_ball(Vector2(140.000061, 100), Vector2(-1, 0)),
	]
	var arena := make_arena(items)
	var events: Array = []
	arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
	arena.step(0.001)
	check(events.size() == 3, "positive gap closing chain waits for its actual later impacts")
	if events.size() == 3:
		check(events[0].size() == 2 and events[0].has(items[0]) and events[0].has(items[1]), "near future connected ball excluded from initial event")
	check(arena.event_limit_hits == 0 and arena.solver_failures == 0, "connected later impacts finish")
	arena.free()

func test_small_speeds() -> void:
	for speed in [1e-8, 1e-7, 1e-6, 1e-4]:
		cases += 1
		var first := make_ball(Vector2(100, 100), Vector2(speed, 0))
		var second := make_ball(Vector2(120, 100), Vector2.ZERO)
		var arena := make_arena([first, second])
		var events: Array = []
		arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
		arena.step(0.01)
		check(arena.event_limit_hits == 0 and arena.solver_failures == 0, "tiny-speed pair makes progress without repeated zero-time events")
		check(absf(arena.simulation_time - 0.01) < 1e-9, "tiny-speed pair consumes requested time")
		check(events.size() == (1 if speed > 1e-7 or first.velocity.x == 0.0 else 0), "tiny-speed detection agrees with solver threshold")
		arena.free()
		cases += 1
		first = make_ball(Vector2(10, 100), Vector2(-speed, 0))
		arena = make_arena([first])
		arena.step(0.01)
		check(arena.event_limit_hits == 0 and arena.solver_failures == 0, "tiny-speed wall makes progress without repeated zero-time events")
		check(absf(arena.simulation_time - 0.01) < 1e-9, "tiny-speed wall consumes requested time")
		arena.free()

func test_time_tolerance() -> void:
	for offset in [0.046875, 0.296875]:
		for order in [[0, 1, 2, 3], [3, 2, 1, 0]]:
			cases += 1
			var items: Array[Ball] = [
				make_ball(Vector2(1000, 100), Vector2(1e8, 0)), make_ball(Vector2(101020, 100), Vector2.ZERO),
				make_ball(Vector2(1000, 500), Vector2(1e8, 0)), make_ball(Vector2(101020 + offset, 500), Vector2.ZERO),
			]
			var arena := make_arena(items, order)
			arena.arena_size = Vector2(1e9, 1e9)
			var events: Array = []
			arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
			arena.step(0.00100001)
			if offset < 0.1:
				check_list(events, items, "within TIME_EPS grouped from earliest time")
			else:
				check(events.size() == 2, "outside TIME_EPS distinct even within same fixed step")
			check(arena.event_limit_hits == 0 and arena.solver_failures == 0, "time tolerance no solver limit")
			arena.free()

func test_triangle() -> void:
	for order in permutations([0, 1, 2]):
		cases += 1
		var center := Vector2(500, 500)
		var items: Array[Ball] = []
		for angle in [0.0, TAU / 3, 2 * TAU / 3]:
			var direction := Vector2.from_angle(angle)
			items.append(make_ball(center + direction * (19.99995 / sqrt(3.0)), -direction * 60))
		var arena := make_arena(items, order)
		var energy := arena.kinetic_energy()
		var momentum := arena.momentum()
		var initial: Array[Vector2] = []
		for ball in items:
			initial.append(ball.velocity)
		var events: Array = []
		arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
		arena.step(0.001)
		for i in 3:
			check(close_vec(items[i].velocity, -initial[i]), "2D triangle expands symmetrically")
		check_list(events, items, "2D triangle")
		check_energy(arena, energy, "2D triangle")
		check(close_vec(arena.momentum(), momentum), "2D triangle momentum")
		arena.free()

func test_nonnegative_impulses() -> void:
	for order in permutations([0, 1, 2]):
		cases += 1
		var direction := Vector2.from_angle(deg_to_rad(80))
		var center := Vector2(500, 500)
		var items: Array[Ball] = [
			make_ball(center, Vector2.ZERO),
			make_ball(center + Vector2(20, 0), Vector2(-100, 0)),
			make_ball(center + 19.99995 * direction, -direction),
		]
		var arena := make_arena(items, order)
		var events: Array = []
		arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
		var energy := arena.kinetic_energy()
		var momentum := arena.momentum()
		arena.step(1e-6)
		# 无约束联立解会给第三球负冲量；非负约束应将它释放。
		check(close_vec(items[0].velocity, Vector2(-100, 0)) and close_vec(items[1].velocity, Vector2.ZERO), "nonnegative solve keeps actual impact")
		check(close_vec(items[2].velocity, -direction), "release contact that would need tensile impulse")
		check_list(events, [items[0], items[1]], "zero-impulse candidate omitted")
		check_energy(arena, energy, "nonnegative impulses")
		check(close_vec(arena.momentum(), momentum), "nonnegative impulses momentum")
		arena.free()

func test_rotated_contact_chains() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for speed in [200.0, 1000.0]:
		for trial in 500:
			cases += 1
			var angle := rng.randf_range(0, TAU)
			var turn := rng.randf_range(-1.0, 1.0)
			var first_direction := Vector2.from_angle(angle)
			var second_direction := Vector2.from_angle(angle + turn)
			var center := Vector2(500, 500)
			# 微小重叠确保 float32 坐标下已有接触，并低于位置修正阈值。
			var items: Array[Ball] = [
				make_ball(center - 19.99995 * first_direction, speed * first_direction),
				make_ball(center, Vector2.ZERO),
				make_ball(center + 19.99995 * second_direction, Vector2.ZERO),
			]
			var arena := make_arena(items, [0, 1, 2] if trial % 2 == 0 else [2, 0, 1])
			var events: Array = []
			arena.ball_collided.connect(func(group: Array[Ball]): events.append(group))
			var energy := arena.kinetic_energy()
			var momentum := arena.momentum()
			arena.step(1e-6)
			check_list(events, items, "rotated chain avoids duplicate float32 residual impacts")
			check_energy(arena, energy, "rotated chain")
			check(close_vec(arena.momentum(), momentum), "rotated chain momentum")
			check(absf(arena.simulation_time - 1e-6) < 1e-12, "rotated chain advances time")
			arena.free()

func test_solver_failure_is_atomic() -> void:
	cases += 1
	var items: Array[Ball] = [
		make_ball(Vector2(100, 100), Vector2(1, 0), 1e12),
		make_ball(Vector2(120, 100), Vector2.ZERO),
		make_ball(Vector2(140, 100), Vector2(-1, 0), 1e12),
	]
	var contacts: Array = [CollisionEvent.create(items, 0, 1, 0.0, Vector2.LEFT), CollisionEvent.create(items, 1, 2, 0.0, Vector2.LEFT)]
	var result := CollisionSolver.resolve(items, contacts)
	check(not result.ok, "ill-conditioned system reports nonconvergence instead of accepting invalid impulses")
	check(items[0].velocity == Vector2(1, 0) and items[1].velocity == Vector2.ZERO and items[2].velocity == Vector2(-1, 0), "failed solve does not change any Ball velocity")
	check(not result.has("velocities"), "failed solve exposes no partial velocity commit")
	cases += 1
	var pair: Array[Ball] = [make_ball(Vector2(100, 100), Vector2(10, 0)), make_ball(Vector2(120, 100), Vector2(-10, 0))]
	var duplicate: Array = [CollisionEvent.create(pair, 0, 1, 0.0, Vector2.LEFT), CollisionEvent.create(pair, 0, 1, 0.0, Vector2.LEFT)]
	result = CollisionSolver.resolve(pair, duplicate)
	check(result.ok and absf(result.velocities[0] + 10) < 0.001 and absf(result.velocities[2] - 10) < 0.001, "redundant singular constraints are supported")

func test_listener_registration() -> void:
	cases += 1
	var first := make_ball(Vector2(10, 100), Vector2.ZERO)
	var second := make_ball(Vector2(30, 100), Vector2(-10, 0))
	var arena := make_arena([first, second])
	var walls: Array = []
	var captured: Array = []
	arena.ball_collided.connect(func(group: Array[Ball]):
		captured.append(group)
		arena.remove_ball(first)
		group.clear())
	arena.wall_collided.connect(func(ball: Ball, normal: Vector2): walls.append([ball, normal]))
	arena.step(0.01)
	check(arena.balls.size() == 1 and arena.balls[0] == second, "emitted list does not alias Arena registration")
	check(walls.size() == 1 and walls[0][0] == first and walls[0][1] == Vector2.RIGHT, "prebuilt wall event survives registration mutation")
	check(close_vec(second.velocity, Vector2(10, 0)), "listener sees fully solved state")
	arena.free()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for test in [test_two_ball_masses, test_three_ball_symmetry, test_unequal_chain, test_resting_chain, test_disjoint_groups, test_wall_contacts, test_event_membership, test_same_time_waves, test_different_times, test_independent_near_future_contact, test_connected_future_contact, test_small_speeds, test_time_tolerance, test_triangle, test_nonnegative_impulses, test_rotated_contact_chains, test_solver_failure_is_atomic, test_listener_registration]:
		test.call()
	print("RESULT simultaneous cases=%d checks=%d failures=%d" % [cases, checks, failures])
	quit(1 if failures else 0)
