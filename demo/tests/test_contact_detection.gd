extends SceneTree
var failures := 0
var checks := 0
var cases := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func make_ball(at: Vector2, velocity: Vector2 = Vector2.ZERO, radius: float = 10.0) -> Ball:
	var ball := Ball.new()
	ball.position = at
	ball.velocity = velocity
	ball.radius = radius
	return ball

func snapshot(arena: Arena) -> Array:
	var state: Array = [arena.arena_size, arena.simulation_time, arena.event_limit_hits, arena.solver_failures]
	for ball in arena.balls:
		state.append([ball, ball.position, ball.velocity, ball.radius, ball.mass])
	return state

func check_walls(arena: Arena, ball: Ball, seeded_normals: Array[Vector2], expected: Array, label: String) -> void:
	cases += 1
	var before := [ball.position, ball.velocity, ball.radius, ball.mass, snapshot(arena)]
	var seeds_before := seeded_normals.duplicate()
	check(arena._wall_contacts(ball, seeded_normals) == expected, label)
	check([ball.position, ball.velocity, ball.radius, ball.mass, snapshot(arena)] == before, label + " state unchanged")
	check(seeded_normals == seeds_before, label + " seeds unchanged")

func check_pair(arena: Arena, a: Ball, b: Ball, seeded: bool, expected: Dictionary, label: String) -> void:
	cases += 1
	var before := [a.position, a.velocity, a.radius, b.position, b.velocity, b.radius, snapshot(arena)]
	check(arena._pair_contact(a, b, seeded) == expected, label)
	check([a.position, a.velocity, a.radius, b.position, b.velocity, b.radius, snapshot(arena)] == before, label + " state unchanged")

func check_event(arena: Arena, seeds: Array, expected: Array, label: String) -> void:
	cases += 1
	var before := snapshot(arena)
	var seeds_before := seeds.duplicate(true)
	var actual := arena._contacts_at_event(seeds)
	check(actual == expected, label + " expected contacts and order")
	check(actual == original_contacts_at_event(arena, seeds), label + " original equality")
	check(snapshot(arena) == before and seeds == seeds_before, label + " state and seeds unchanged")

func test_wall_contacts() -> void:
	var arena := Arena.new()
	arena.arena_size = Vector2(200, 300)
	for normal in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var axis := 0 if normal.x != 0.0 else 1
		for gap in [-1.0, 0.0, 0.00006103515625, 1.0, 20.0]:
			var ball := make_ball(Vector2(100, 150))
			var edge: float = ball.radius if normal[axis] > 0.0 else arena.arena_size[axis] - ball.radius
			ball.position[axis] = edge + normal[axis] * gap
			for seeded in [false, true]:
				var seeds: Array[Vector2] = []
				if seeded:
					seeds.append(normal)
					seeds.append(normal)
				check_walls(arena, ball, seeds, [normal] if seeded or gap <= 0.0 else [], "wall %s gap %s seeded %s" % [normal, gap, seeded])
			ball.velocity = -normal * 100
			check_walls(arena, ball, [], [normal] if gap <= 0.0 else [], "approaching wall does not count positive gap")
			ball.velocity = normal * 100
			check_walls(arena, ball, [], [normal] if gap <= 0.0 else [], "separating wall keeps actual contact")
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			var ball := make_ball(Vector2(10 if x > 0 else 190, 10 if y > 0 else 290))
			check_walls(arena, ball, [], [Vector2(x, 0), Vector2(0, y)], "corner normal order")
	var custom := make_ball(Vector2(17, 150), Vector2.ZERO, 17.0)
	check_walls(arena, custom, [], [Vector2.RIGHT], "custom wall radius")
	arena.arena_size = Vector2(20, 20)
	check_walls(arena, make_ball(Vector2(10, 10)), [], [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN], "all walls preserve axis and side order")
	check(arena._wall_contacts(make_ball(Vector2(10, 10))).size() == 4, "wall default seeds")
	arena.free()

func test_pair_contact() -> void:
	var arena := Arena.new()
	for gap in [-1.0, 0.0, 0.00006103515625, 1.0, 20.0]:
		for speed in [-100.0, 0.0, 100.0]:
			var a := make_ball(Vector2.ZERO, Vector2(speed, 0), 7.0)
			var b := make_ball(Vector2(20 + gap, 0), Vector2(-speed, 0), 13.0)
			for seeded in [false, true]:
				var expected := {"normal": Vector2.LEFT} if seeded or gap <= 0.0 else {}
				check_pair(arena, a, b, seeded, expected, "pair gap %s speed %s seeded %s" % [gap, speed, seeded])
	for offset in [Vector2(20, 0), Vector2(-20, 0), Vector2(0, 20), Vector2(0, -20), Vector2(12, 16), Vector2(-12, 16), Vector2(12, -16), Vector2(-12, -16)]:
		var a := make_ball(Vector2(100, 100))
		var b := make_ball(a.position + offset)
		check_pair(arena, a, b, false, {"normal": -offset.normalized()}, "normal from b to a")
		check_pair(arena, b, a, false, {"normal": offset.normalized()}, "reverse pair normal")
	check_pair(arena, make_ball(Vector2.ZERO), make_ball(Vector2.ZERO), false, {"normal": Vector2.ZERO}, "coincident centers retain zero normal")
	check(arena._pair_contact(make_ball(Vector2.ZERO), make_ball(Vector2(20, 0))) == {"normal": Vector2.LEFT}, "pair default seed")
	check(arena._pair_contact(make_ball(Vector2.ZERO), make_ball(Vector2(21, 0))).is_empty(), "pair default excludes positive gap")
	arena.free()

func test_connected_groups() -> void:
	var arena := Arena.new()
	for position_value in [Vector2(10, 100), Vector2(30, 100), Vector2(50, 100), Vector2(200, 100), Vector2(220, 100), Vector2(10, 200)]:
		arena.register_ball(make_ball(position_value))
	var chain: Array = [
		{"a": 0, "b": -1, "normal": Vector2.RIGHT},
		{"a": 0, "b": 1, "normal": Vector2.LEFT},
		{"a": 1, "b": 2, "normal": Vector2.LEFT},
	]
	var separate: Array = [{"a": 3, "b": 4, "normal": Vector2.LEFT}]
	check_event(arena, [{"a": 1, "b": 2}], chain, "backward expansion reaches wall through chain")
	check_event(arena, [{"a": 0, "b": -1, "normal": Vector2.RIGHT}], chain, "wall seed reaches chain without joining other wall ball")
	check_event(arena, [{"a": 3, "b": 4}], separate, "independent group stays separate")
	check_event(arena, [{"a": 1, "b": 2}, {"a": 3, "b": 4}], chain + separate, "simultaneous independent groups")
	check_event(arena, [{"a": 1, "b": 2}, {"a": 1, "b": 2}], chain, "duplicate seeds do not duplicate contacts")
	check_event(arena, [], [], "no seeds do not select touching contacts")
	arena.free()
	arena = Arena.new()
	check_event(arena, [], [], "empty arena")
	arena.free()

func test_positive_gap_seeds() -> void:
	var arena := Arena.new()
	for position_value in [Vector2(10, 100), Vector2(30.00006103515625, 100), Vector2(50.00006103515625, 100)]:
		arena.register_ball(make_ball(position_value))
	var wall := {"a": 0, "b": -1, "normal": Vector2.RIGHT}
	var pair_01 := {"a": 0, "b": 1, "normal": Vector2.LEFT}
	var pair_12 := {"a": 1, "b": 2, "normal": Vector2.LEFT}
	check_event(arena, [wall], [wall], "small positive gap does not extend chain")
	check_event(arena, [{"a": 1, "b": 2}], [pair_12], "small positive gap does not connect wall")
	check_event(arena, [{"a": 0, "b": 1}], [wall, pair_01, pair_12], "seeded positive pair gap extends chain")
	arena.balls[0].position.x += 0.00006103515625
	check_event(arena, [{"a": 0, "b": 1}], [pair_01, pair_12], "ordinary positive wall gap excluded")
	check_event(arena, [wall], [wall, pair_01, pair_12], "seeded positive wall gap retained")
	arena.balls[1].position.x += 1.0
	check_event(arena, [wall], [wall], "wall seed does not seed pair")
	arena.free()
	arena = Arena.new()
	arena.arena_size = Vector2(32, 32.5)
	var ball := make_ball(Vector2(10, 10), Vector2(1e9, 1e9), 1.0)
	arena.register_ball(ball)
	var event := arena._next_event(1.0)
	for item in arena.balls:
		item.position += item.velocity * event.time
	check(ball.position.y < arena.arena_size.y - ball.radius, "simultaneous wall still has positive gap")
	check_event(arena, event.contacts, [{"a": 0, "b": -1, "normal": Vector2.LEFT}, {"a": 0, "b": -1, "normal": Vector2.UP}], "real simultaneous wall seed")
	arena.free()
	arena = Arena.new()
	arena.arena_size = Vector2(32, 40)
	arena.register_ball(make_ball(Vector2(10, 10), Vector2(1e9, 0), 1.0))
	arena.register_ball(make_ball(Vector2(5, 25), Vector2(1e9, 0), 1.0))
	arena.register_ball(make_ball(Vector2(28.5, 25), Vector2.ZERO, 1.0))
	event = arena._next_event(1.0)
	for item in arena.balls:
		item.position += item.velocity * event.time
	check(arena.balls[1].position.distance_to(arena.balls[2].position) > 2.0, "simultaneous pair still has positive gap")
	check_event(arena, event.contacts, [{"a": 0, "b": -1, "normal": Vector2.LEFT}, {"a": 1, "b": 2, "normal": Vector2.LEFT}], "real simultaneous pair seed")
	arena.free()

func test_randomized_equivalence() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 611106
	for scenario in 3000:
		var arena := Arena.new()
		arena.arena_size = Vector2(rng.randf_range(100, 1000), rng.randf_range(100, 1000))
		for index in scenario % 8:
			var radius := rng.randf_range(1, 20)
			var at := Vector2(rng.randf_range(radius, arena.arena_size.x - radius), rng.randf_range(radius, arena.arena_size.y - radius))
			var ball := make_ball(at, Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(0, 1e4), radius)
			if scenario % 3 == 0:
				var axis := index % 2
				var side := -1.0 if index % 3 == 0 else 1.0
				var edge: float = ball.radius if side > 0.0 else arena.arena_size[axis] - ball.radius
				ball.position[axis] = edge + side * [-1.0, 0.0, 0.00006103515625, 1.0][rng.randi_range(0, 3)]
			elif index > 0 and scenario % 3 == 1:
				var previous := arena.balls[index - 1]
				var distance: float = previous.radius + ball.radius + [-1.0, 0.0, 0.00006103515625, 1.0][rng.randi_range(0, 3)]
				ball.position = previous.position + Vector2.from_angle(rng.randf_range(0, TAU)) * distance
			arena.register_ball(ball)
		var arbitrary: Array = []
		for i in arena.balls.size():
			if rng.randf() < 0.3:
				arbitrary.append({"a": i, "b": -1, "normal": [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][rng.randi_range(0, 3)]})
			for j in range(i + 1, arena.balls.size()):
				if rng.randf() < 0.2:
					arbitrary.append({"a": i, "b": j})
		for seeds in [[], arbitrary]:
			check_event(arena, seeds, original_contacts_at_event(arena, seeds), "random contacts %d" % scenario)
		var event := arena._next_event(0.1)
		if is_finite(event.time):
			for ball in arena.balls:
				ball.position += ball.velocity * event.time
		check_event(arena, event.contacts, original_contacts_at_event(arena, event.contacts), "random event %d" % scenario)
		arena.free()

# 保留抽取前的算法，逐项比较接触、法线、顺序和连通组。
func original_contacts_at_event(arena: Arena, seeds: Array) -> Array:
	var contacts: Array = []
	for i in arena.balls.size():
		var ball := arena.balls[i]
		for axis in 2:
			for side in [-1.0, 1.0]:
				var normal := Vector2.ZERO
				normal[axis] = side
				var edge: float = ball.radius if side > 0.0 else arena.arena_size[axis] - ball.radius
				var seeded := seeds.any(func(event: Dictionary) -> bool: return event.a == i and event.b == -1 and event.normal == normal)
				var gap: float = (ball.position[axis] - edge) * side
				if seeded or gap <= 0.0:
					contacts.append({"a": i, "b": -1, "normal": normal})
		for j in range(i + 1, arena.balls.size()):
			var delta := ball.position - arena.balls[j].position
			var seeded := seeds.any(func(event: Dictionary) -> bool: return event.a == i and event.b == j)
			var gap := sqrt(float(delta.x) * delta.x + float(delta.y) * delta.y) - ball.radius - arena.balls[j].radius
			var normal := delta.normalized()
			# 正间隙不算已有接触，只能通过显式的同刻 CCD 种子进入本批。
			if seeded or gap <= 0.0:
				contacts.append({"a": i, "b": j, "normal": normal})
	# 只扩展本批碰撞接触到的链，避免把远处“很快才撞”的独立近接触提前合并。
	var involved: Dictionary = {}
	for seed in seeds:
		involved[seed.a] = true
		if seed.b >= 0:
			involved[seed.b] = true
	var selected: Dictionary = {}
	var expanded := true
	while expanded:
		expanded = false
		for index in contacts.size():
			var contact: Dictionary = contacts[index]
			if selected.has(index) or not (involved.has(contact.a) or involved.has(contact.b)):
				continue
			selected[index] = true
			involved[contact.a] = true
			if contact.b >= 0:
				involved[contact.b] = true
			expanded = true
	var connected: Array = []
	for index in contacts.size():
		if selected.has(index):
			connected.append(contacts[index])
	return connected

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for test in [test_wall_contacts, test_pair_contact, test_connected_groups, test_positive_gap_seeds, test_randomized_equivalence]:
		test.call()
	print("RESULT contact_detection cases=%d checks=%d failures=%d" % [cases, checks, failures])
	quit(1 if failures else 0)
