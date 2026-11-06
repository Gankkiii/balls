extends SceneTree
var failures := 0
var checks := 0
var cases := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func make_ball(at: Vector2, velocity: Vector2, radius: float = 10.0) -> Ball:
	var ball := Ball.new()
	ball.position = at
	ball.velocity = velocity
	ball.radius = radius
	return ball

func check_hit(arena: Arena, ball: Ball, horizon: float, time: float, normals: Array, label: String) -> void:
	cases += 1
	var position_before := ball.position
	var velocity_before := ball.velocity
	var result := arena._wall_time(ball, horizon)
	check(result.time == time, label + " earliest time")
	check(result.contacts.size() == normals.size(), label + " contact count")
	for normal in normals:
		check(result.contacts.any(func(contact) -> bool: return contact.normal == normal), label + " wall normal")
	for contact in result.contacts:
		check(contact.time >= result.time and contact.time <= result.time + Arena.TIME_EPS, label + " individual time")
	check(ball.position == position_before and ball.velocity == velocity_before, label + " does not change ball")
	check(arena.balls.is_empty() and arena.simulation_time == 0.0 and arena.event_limit_hits == 0 and arena.solver_failures == 0, label + " does not change arena")

func test_sides_and_corners() -> void:
	var arena := Arena.new()
	arena.arena_size = Vector2(200, 300)
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		var axis := 0 if direction.x != 0.0 else 1
		var ball := make_ball(Vector2(100, 150), direction * 100.0)
		var time := 0.9 if axis == 0 else 1.4
		check_hit(arena, ball, 2.0, time, [-direction], "side " + str(direction))
		ball.position[axis] = arena.arena_size[axis] - ball.radius if direction[axis] > 0.0 else ball.radius
		check_hit(arena, ball, 0.0, 0.0, [-direction], "outward contact " + str(direction))
		ball.velocity = -ball.velocity
		check_hit(arena, ball, 0.0, INF, [], "separating contact " + str(direction))
		ball.velocity = -ball.velocity
		ball.position += direction
		check_hit(arena, ball, 0.0, 0.0, [-direction], "outside clamp " + str(direction))
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			var ball := make_ball(Vector2(100, 150), Vector2(90 * x, 140 * y))
			check_hit(arena, ball, 1.0, 1.0, [Vector2(-x, 0), Vector2(0, -y)], "corner " + str(Vector2(x, y)))
	var different := make_ball(Vector2(100, 150), Vector2(100, 100), 20.0)
	check_hit(arena, different, 2.0, 0.8, [Vector2.LEFT], "earlier horizontal and custom radius")
	different.velocity = Vector2(50, 200)
	check_hit(arena, different, 2.0, 0.65, [Vector2.UP], "earlier vertical")
	arena.free()

func test_stationary_and_speed_tolerance() -> void:
	var arena := Arena.new()
	arena.arena_size = Vector2(200, 300)
	check_hit(arena, make_ball(Vector2(100, 150), Vector2.ZERO), 100.0, INF, [], "stationary")
	for axis in 2:
		for sign_value in [-1.0, 1.0]:
			var velocity := Vector2.ZERO
			velocity[axis] = sign_value * CollisionSolver.VELOCITY_EPS * 0.5
			var ball := make_ball(Vector2(100, 150), velocity)
			ball.position[axis] = arena.arena_size[axis] - ball.radius if sign_value > 0.0 else ball.radius
			check_hit(arena, ball, 1.0, INF, [], "below velocity tolerance")
			velocity[axis] = sign_value * CollisionSolver.VELOCITY_EPS * 2.0
			ball.velocity = velocity
			var normal := Vector2.ZERO
			normal[axis] = -sign_value
			check_hit(arena, ball, 0.0, 0.0, [normal], "above velocity tolerance")
	arena.free()

func test_horizon_tolerance() -> void:
	var arena := Arena.new()
	arena.arena_size = Vector2(200, 300)
	var ball := make_ball(Vector2(100, 150), Vector2(100, 0))
	for offset in [-2.0, -1.0, -0.5, 0.0, 0.5, 2.0]:
		var horizon: float = 0.9 + offset * Arena.TIME_EPS
		var admitted: bool = offset >= -1.0
		check_hit(arena, ball, horizon, 0.9 if admitted else INF, [Vector2.LEFT] if admitted else [], "horizon offset " + str(offset))
	check_hit(arena, ball, 0.0, INF, [], "zero horizon before contact")
	arena.free()

func test_corner_time_tolerance() -> void:
	var arena := Arena.new()
	var ball := make_ball(Vector2(10, 10), Vector2(1e9, 1e9), 1.0)
	for gap in [0.0, 0.5, 1.0, 2.0]:
		arena.arena_size = Vector2(32, 32 + gap)
		var normals: Array = [Vector2.LEFT]
		if gap <= 1.0:
			normals.append(Vector2.UP)
		check_hit(arena, ball, 1.0, 21.0 / 1e9, normals, "corner time gap " + str(gap))
		var result := arena._wall_time(ball, 1.0)
		for contact in result.contacts:
			var expected: float = 21.0 / 1e9 if contact.normal == Vector2.LEFT else (21.0 + gap) / 1e9
			check(contact.time == expected, "corner preserves each wall time")
	# y 轴先撞时同样保留双墙，不依赖 axis 的遍历顺序。
	arena.arena_size = Vector2(32.5, 32)
	check_hit(arena, ball, 1.0, 21.0 / 1e9, [Vector2.LEFT, Vector2.UP], "vertical first within tolerance")
	arena.free()

func test_global_time_tolerance() -> void:
	for reverse_order in [false, true]:
		cases += 1
		var arena := Arena.new()
		arena.arena_size = Vector2(32, 32.75)
		var corner := make_ball(Vector2(10, 10), Vector2(1e9, 1e9), 1.0)
		var earlier := make_ball(Vector2(20, 21.25), Vector2(0, -1e9), 1.0)
		var items: Array[Ball] = [corner, earlier]
		if reverse_order:
			items.reverse()
		for ball in items:
			arena.register_ball(ball)
		var local := arena._wall_time(corner, 1.0)
		check(local.contacts.size() == 2, "both walls locally within tolerance")
		var result := arena._next_event(1.0)
		check(result.time == 20.25 / 1e9, "global earliest time")
		check(result.contacts.size() == 2, "global batch excludes chained near-equal wall")
		var corner_index := arena.balls.find(corner)
		check(result.contacts.any(func(contact) -> bool: return contact.a == corner_index and contact.b == -1 and contact.normal == Vector2.LEFT), "global batch retains near wall")
		check(not result.contacts.any(func(contact) -> bool: return contact.a == corner_index and contact.b == -1 and contact.normal == Vector2.UP), "global batch rejects distant wall")
		check(flatten_event(result) == original_next_event(arena, 1.0), "global result matches original")
		arena.free()

# 保留抽取前的事件收集算法，逐项比较时间、索引、法线和列表顺序。
func flatten_event(result: Dictionary) -> Dictionary:
	var contacts: Array = []
	for event: CollisionEvent in result.contacts:
		var item := {"time": event.time, "a": event.a, "b": event.b}
		if event.b == -1:
			item["normal"] = event.normal
		contacts.append(item)
	return {"time": result.time, "contacts": contacts}

func original_next_event(arena: Arena, horizon: float) -> Dictionary:
	var earliest := INF
	var candidates: Array = []
	for i in arena.balls.size():
		var ball := arena.balls[i]
		for axis in 2:
			var speed: float = ball.velocity[axis]
			var axis_normal := Vector2.RIGHT if axis == 0 else Vector2.DOWN
			if absf(speed) <= CollisionSolver.velocity_tolerance(axis_normal, ball.velocity.x, ball.velocity.y):
				continue
			var edge: float = arena.arena_size[axis] - ball.radius if speed > 0.0 else ball.radius
			var time: float = maxf(0.0, (edge - ball.position[axis]) / speed)
			if time <= horizon + Arena.TIME_EPS:
				var normal := Vector2.ZERO
				normal[axis] = -signf(speed)
				candidates.append({"time": time, "a": i, "b": -1, "normal": normal})
				earliest = minf(earliest, time)
	for i in arena.balls.size():
		for j in range(i + 1, arena.balls.size()):
			var time := arena._pair_time(arena.balls[i], arena.balls[j], horizon)
			if is_finite(time):
				candidates.append({"time": time, "a": i, "b": j})
				earliest = minf(earliest, time)
	var contacts: Array = []
	for candidate in candidates:
		if candidate.time <= earliest + Arena.TIME_EPS:
			contacts.append(candidate)
	return {"time": earliest, "contacts": contacts}

func test_randomized_equivalence() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 601106
	for scenario in 2000:
		cases += 1
		var arena := Arena.new()
		arena.arena_size = Vector2(rng.randf_range(200, 1000), rng.randf_range(200, 1000))
		for index in scenario % 6:
			var radius := rng.randf_range(1, 20)
			var position_value := Vector2(rng.randf_range(radius, arena.arena_size.x - radius), rng.randf_range(radius, arena.arena_size.y - radius))
			var speed: float = [0.0, 1e-8, 1e-6, 1.0, 1e3, 1e9][rng.randi_range(0, 5)]
			var ball := make_ball(position_value, Vector2.from_angle(rng.randf_range(0, TAU)) * speed, radius)
			if scenario % 7 == 0:
				var axis := index % 2
				ball.position[axis] = ball.radius if ball.velocity[axis] < 0.0 else arena.arena_size[axis] - ball.radius
			arena.register_ball(ball)
		for horizon in [0.0, 1e-9, 1e-6, 1.0 / 120.0, 10.0]:
			var actual := arena._next_event(horizon)
			var flattened: Array = []
			for event: CollisionEvent in actual.contacts:
				var record := {"time": event.time, "a": event.a, "b": event.b}
				if event.b == -1:
					record["normal"] = event.normal
				flattened.append(record)
			actual.contacts = flattened
			check(actual == original_next_event(arena, horizon), "original event equality scenario %d horizon %s" % [scenario, horizon])
		arena.free()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for test in [test_sides_and_corners, test_stationary_and_speed_tolerance, test_horizon_tolerance, test_corner_time_tolerance, test_global_time_tolerance, test_randomized_equivalence]:
		test.call()
	print("RESULT wall_time cases=%d checks=%d failures=%d" % [cases, checks, failures])
	quit(1 if failures else 0)
