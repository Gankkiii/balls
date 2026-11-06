class_name Arena
extends Node2D
## Frictionless disks in an immovable box. Analytic time-of-impact (CCD).
## Units: logical pixels, seconds, arbitrary mass. No rigid body engine runs here.
signal wall_collided(ball: Ball, normal: Vector2)
## 同一时刻只通知一次，包含全部实际球间碰撞参与者；全部速度已更新。
signal ball_collided(colliding_balls: Array[Ball])

const TIME_EPS := 1e-9
const VEL_EPS := 1e-7
const POSITION_EPS := 1e-4
const MAX_EVENTS := 128
const MAX_POSITION_ITERATIONS := 512
const DefaultBallConfig := preload("res://configs/default_ball.tres")
@export var arena_size := Vector2(640, 680)
var balls: Array[Ball] = []
var simulation_time := 0.0
var event_limit_hits := 0
var solver_failures := 0
var position_failures := 0
var last_error := ""

func register_ball(ball: Ball) -> void:
	if not balls.has(ball):
		balls.append(ball)

func remove_ball(ball: Ball) -> void:
	balls.erase(ball)

func initialize(seed_value: int, initial_positions: Array) -> Dictionary:
	# 玩家位置只验证，不悄悄搬动；所有数据通过后才一起提交。
	return _initialize_positions(seed_value, initial_positions, false)

func initialize_demo(seed_value: int) -> Dictionary:
	var placement := generate_demo_positions(seed_value)
	if not placement.ok:
		return _initialization_failure(placement.error)
	return _initialize_positions(seed_value, placement.positions, true)

func generate_demo_positions(seed_value: int) -> Dictionary:
	var error := _geometry_error()
	if not error.is_empty():
		return _failure(error)
	var positions: Array[Vector2] = []
	if balls.is_empty():
		return {"ok": true, "positions": positions}
	# 保留原两球 Demo 的种子和采样顺序；不合法时再尝试网格。
	if balls.size() <= 2:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for i in balls.size():
			var ball := balls[i]
			positions.append(Vector2(arena_size.x * (0.28 if i == 0 else 0.72), rng.randf_range(ball.radius + 40, arena_size.y - ball.radius - 40)))
			rng.randf()
			rng.randf()
		if validate_positions(positions).ok:
			return {"ok": true, "positions": positions}
	positions.clear()
	var diameter := 0.0
	for ball in balls:
		diameter = maxf(diameter, 2.0 * ball.radius)
	var columns := 0
	var rows := 0
	var best_shape := INF
	for candidate_columns in range(1, balls.size() + 1):
		var candidate_rows := ceili(float(balls.size()) / candidate_columns)
		var cell_width := float(arena_size.x) / candidate_columns
		var cell_height := float(arena_size.y) / candidate_rows
		if cell_width < diameter or cell_height < diameter:
			continue
		var shape := absf(cell_width - cell_height)
		if shape < best_shape:
			columns = candidate_columns
			rows = candidate_rows
			best_shape = shape
	if columns == 0:
		return _failure("Demo grid could not place %d balls; try a larger arena, smaller radii, or explicit positions (this is not a packing impossibility proof)" % balls.size())
	for i in balls.size():
		positions.append(Vector2((i % columns + 0.5) * float(arena_size.x) / columns, (i / columns + 0.5) * float(arena_size.y) / rows))
	var validation := validate_positions(positions)
	if not validation.ok:
		return _failure("Demo grid did not produce representable valid positions: " + validation.error)
	return {"ok": true, "positions": positions}

func _initialize_positions(seed_value: int, initial_positions: Array, demo_sampling: bool) -> Dictionary:
	var validation := validate_positions(initial_positions)
	if not validation.ok:
		return _initialization_failure(validation.error)
	var configs: Array[BallConfig] = []
	for i in balls.size():
		var ball := balls[i]
		var config: BallConfig = DefaultBallConfig
		if ball.character_definition != null:
			if not ball.character_definition is BallConfig:
				return _initialization_failure("Ball %d: character_definition must be a BallConfig or null" % i)
			config = ball.character_definition as BallConfig
		if not is_finite(config.min_initial_speed) or not is_finite(config.max_initial_speed) or config.min_initial_speed < 0.0 or config.max_initial_speed < config.min_initial_speed:
			return _initialization_failure("Ball %d: BallConfig requires finite 0 <= min_initial_speed <= max_initial_speed" % i)
		var minimum := Vector2(config.min_initial_speed, 0.0)
		var maximum := Vector2(config.max_initial_speed, 0.0)
		if not maximum.is_finite() or not is_finite(maximum.length_squared()) or (config.min_initial_speed > 0.0 and minimum.x == 0.0) or (config.max_initial_speed > 0.0 and maximum.x == 0.0):
			return _initialization_failure("Ball %d: speed range is not representable with finite Vector2 speed and squared length" % i)
		configs.append(config)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var velocities: Array[Vector2] = []
	for i in balls.size():
		if demo_sampling:
			rng.randf()
		var angle := rng.randf_range(0.0, TAU)
		var velocity := Vector2.from_angle(angle) * rng.randf_range(configs[i].min_initial_speed, configs[i].max_initial_speed)
		if not velocity.is_finite() or not is_finite(velocity.length_squared()):
			return _initialization_failure("Ball %d: generated velocity or squared speed is not finite" % i)
		velocities.append(velocity)
	for i in balls.size():
		balls[i].position = initial_positions[i]
		balls[i].velocity = velocities[i]
	simulation_time = 0.0
	event_limit_hits = 0
	solver_failures = 0
	position_failures = 0
	last_error = ""
	queue_redraw()
	return {"ok": true, "error": ""}

func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}

func _initialization_failure(error: String) -> Dictionary:
	last_error = error
	push_error(error + "; initialization cancelled, runtime state preserved")
	return _failure(error)

func _geometry_error() -> String:
	if not arena_size.is_finite() or arena_size.x <= 0.0 or arena_size.y <= 0.0:
		return "Arena dimensions must be finite and positive"
	var seen: Dictionary = {}
	for i in balls.size():
		var ball := balls[i]
		if ball == null:
			return "Ball %d is null" % i
		if seen.has(ball):
			return "Ball %d duplicates an already registered object" % i
		seen[ball] = true
		if not is_finite(ball.radius) or ball.radius <= 0.0 or Vector2(ball.radius, 0.0).x == 0.0:
			return "Ball %d: radius must be finite, positive, and representable" % i
		if ball.radius > minf(arena_size.x, arena_size.y) * 0.5:
			return "Ball %d: diameter exceeds the arena dimensions" % i
		if not is_finite(ball.mass) or ball.mass <= 0.0:
			return "Ball %d: mass must be finite and positive" % i
	return ""

func validate_positions(positions: Array) -> Dictionary:
	var error := _geometry_error()
	if not error.is_empty():
		return _failure(error)
	if positions.size() != balls.size():
		return _failure("Expected %d positions, received %d" % [balls.size(), positions.size()])
	for i in positions.size():
		if not positions[i] is Vector2 or not positions[i].is_finite():
			return _failure("Ball %d: position must be a finite Vector2" % i)
	return _check_position_constraints(positions)

func _check_position_constraints(positions: Array) -> Dictionary:
	var errors: PackedStringArray = []
	for i in balls.size():
		var at: Vector2 = positions[i]
		var radius := balls[i].radius
		if not at.is_finite():
			return _failure("Ball %d: position is not finite" % i)
		if at.x < radius - POSITION_EPS or at.y < radius - POSITION_EPS or at.x > float(arena_size.x) - radius + POSITION_EPS or at.y > float(arena_size.y) - radius + POSITION_EPS:
			errors.append("Ball %d is outside the arena" % i)
		for j in range(i + 1, balls.size()):
			var other: Vector2 = positions[j]
			var dx := float(other.x) - at.x
			var dy := float(other.y) - at.y
			if balls[i].radius + balls[j].radius - sqrt(dx * dx + dy * dy) > POSITION_EPS:
				errors.append("Balls %d and %d overlap" % [i, j])
	return {"ok": errors.is_empty(), "error": "; ".join(errors)}

func kinetic_energy() -> float:
	var energy := 0.0
	for ball in balls:
		energy += 0.5 * ball.mass * ball.velocity.length_squared()
	return energy

func momentum() -> Vector2:
	var total := Vector2.ZERO
	for ball in balls:
		total += ball.mass * ball.velocity
	return total

func _wall_time(ball: Ball, horizon: float) -> Dictionary:
	# 预测这个球最早撞墙的时间和墙面；无碰撞返回 INF 和空列表。
	var earliest := INF
	var candidates: Array = []
	for axis in 2:
		var speed: float = ball.velocity[axis]
		var axis_normal := Vector2.RIGHT if axis == 0 else Vector2.DOWN
		if absf(speed) <= CollisionSolver.velocity_tolerance(axis_normal, ball.velocity.x, ball.velocity.y):
			continue
		var edge: float = arena_size[axis] - ball.radius if speed > 0.0 else ball.radius
		var time: float = maxf(0.0, (edge - ball.position[axis]) / speed)
		if time <= horizon + TIME_EPS:
			var normal := Vector2.ZERO
			normal[axis] = -signf(speed)
			candidates.append({"time": time, "normal": normal})
			earliest = minf(earliest, time)
	var contacts: Array = []
	# 角落可保留两面墙；保留各自时间，供全场按真正最早时刻分批。
	for candidate in candidates:
		if candidate.time <= earliest + TIME_EPS:
			contacts.append(candidate)
	return {"time": earliest, "contacts": contacts}

func _pair_time(a: Ball, b: Ball, horizon: float) -> float:
	var p := b.position - a.position
	var v := b.velocity - a.velocity
	var distance := a.radius + b.radius
	var approach := float(p.x) * v.x + float(p.y) * v.y
	var tolerance := CollisionSolver.velocity_tolerance(p.normalized(), a.velocity.x, a.velocity.y, b.velocity.x, b.velocity.y)
	if approach >= -tolerance * sqrt(float(p.x) * p.x + float(p.y) * p.y):
		return INF
	var c := float(p.x) * p.x + float(p.y) * p.y - distance * distance
	if c <= 0.0:
		return 0.0
	var speed_sq := float(v.x) * v.x + float(v.y) * v.y
	var discriminant := approach * approach - speed_sq * c
	if speed_sq <= VEL_EPS * VEL_EPS or discriminant < 0.0:
		return INF
	# Stable small root, avoids subtraction cancellation at near-contact.
	var hit := c / (-approach + sqrt(discriminant))
	return hit if hit >= -TIME_EPS and hit <= horizon + TIME_EPS else INF

func _correct_positions() -> Dictionary:
	var error := _geometry_error()
	if not error.is_empty():
		return _failure(error)
	var positions: Array[Vector2] = []
	for i in balls.size():
		if not balls[i].position.is_finite():
			return _failure("Ball %d: position is not finite" % i)
		positions.append(balls[i].position)
	# 只在副本上迭代；每轮同时复查墙和球，成功后整批提交。
	for iteration in range(MAX_POSITION_ITERATIONS + 1):
		var validation := _check_position_constraints(positions)
		if validation.ok:
			for i in balls.size():
				balls[i].position = positions[i]
			return {"ok": true, "error": "", "iterations": iteration}
		if iteration == MAX_POSITION_ITERATIONS:
			return _failure("Position correction did not converge after %d iterations: %s" % [MAX_POSITION_ITERATIONS, validation.error])
		for i in balls.size():
			var radius := balls[i].radius
			positions[i] = Vector2(clampf(positions[i].x, radius, float(arena_size.x) - radius), clampf(positions[i].y, radius, float(arena_size.y) - radius))
		for i in balls.size():
			for j in range(i + 1, balls.size()):
				var dx := float(positions[j].x) - positions[i].x
				var dy := float(positions[j].y) - positions[i].y
				var distance := sqrt(dx * dx + dy * dy)
				var depth := balls[i].radius + balls[j].radius - distance
				if depth <= POSITION_EPS:
					continue
				var nx := dx / distance if distance > 0.0 else 1.0
				var ny := dy / distance if distance > 0.0 else 0.0
				# 先按最大质量缩放，避免质量和或倒数溢出。
				var scale := maxf(balls[i].mass, balls[j].mass)
				var ma := balls[i].mass / scale
				var mb := balls[j].mass / scale
				var shift_a := (depth + POSITION_EPS * 0.25) * mb / (ma + mb)
				var shift_b := (depth + POSITION_EPS * 0.25) * ma / (ma + mb)
				positions[i] = Vector2(float(positions[i].x) - nx * shift_a, float(positions[i].y) - ny * shift_a)
				positions[j] = Vector2(float(positions[j].x) + nx * shift_b, float(positions[j].y) + ny * shift_b)
				if not positions[i].is_finite() or not positions[j].is_finite():
					return _failure("Position correction generated non-finite positions")
	return _failure("Position correction exhausted its iteration budget")

func _next_event(horizon: float) -> Dictionary:
	var earliest := INF
	var candidates: Array = []
	for i in balls.size():
		var wall := _wall_time(balls[i], horizon)
		for contact in wall.contacts:
			candidates.append({"time": contact.time, "a": i, "b": -1, "normal": contact.normal})
		earliest = minf(earliest, wall.time)
	for i in balls.size():
		for j in range(i + 1, balls.size()):
			var time := _pair_time(balls[i], balls[j], horizon)
			if is_finite(time):
				candidates.append({"time": time, "a": i, "b": j})
				earliest = minf(earliest, time)
	var contacts: Array = []
	# 先找到真正最小值，再按同一基准分批，避免“近似相等”链依赖遍历顺序。
	for candidate in candidates:
		if candidate.time <= earliest + TIME_EPS:
			contacts.append(candidate)
	return {"time": earliest, "contacts": contacts}

func _wall_contacts(ball: Ball, seeded_normals: Array[Vector2] = []) -> Array[Vector2]:
	# 返回接触墙面的法线；同刻 CCD 种子允许仍有正间隙。
	var normals: Array[Vector2] = []
	for axis in 2:
		for side in [-1.0, 1.0]:
			var normal := Vector2.ZERO
			normal[axis] = side
			var edge: float = ball.radius if side > 0.0 else arena_size[axis] - ball.radius
			var gap: float = (ball.position[axis] - edge) * side
			if seeded_normals.has(normal) or gap <= 0.0:
				normals.append(normal)
	return normals

func _pair_contact(a: Ball, b: Ball, seeded: bool = false) -> Dictionary:
	var delta := a.position - b.position
	var gap := sqrt(float(delta.x) * delta.x + float(delta.y) * delta.y) - a.radius - b.radius
	var normal := delta.normalized()
	# 正间隙只接纳显式的同刻 CCD 种子；法线从 b 指向 a。
	return {"normal": normal} if seeded or gap <= 0.0 else {}

func _contacts_at_event(seeds: Array) -> Array:
	var contacts: Array = []
	for i in balls.size():
		var seeded_normals: Array[Vector2] = []
		for seed in seeds:
			if seed.a == i and seed.b == -1:
				seeded_normals.append(seed.normal)
		for normal in _wall_contacts(balls[i], seeded_normals):
			contacts.append({"a": i, "b": -1, "normal": normal})
		for j in range(i + 1, balls.size()):
			var seeded := seeds.any(func(event: Dictionary) -> bool: return event.a == i and event.b == j)
			var contact := _pair_contact(balls[i], balls[j], seeded)
			if not contact.is_empty():
				contacts.append({"a": i, "b": j, "normal": contact.normal})
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

func _emit_collisions(contacts: Array, affected: Array) -> void:
	var participants: Array[Ball] = []
	var wall_events: Array = []
	for index in affected:
		var contact: Dictionary = contacts[index]
		if contact.b < 0:
			wall_events.append([balls[contact.a], contact.normal])
			continue
		for ball in [balls[contact.a], balls[contact.b]]:
			if not participants.has(ball):
				participants.append(ball)
	# 列表表达“同一时刻的参与者”，不表示列表中的任意两球都相撞。
	# 回调前已准备好独立列表；仅碰墙的球不混入球间碰撞通知。
	if not participants.is_empty():
		ball_collided.emit(participants)
	for event in wall_events:
		wall_collided.emit(event[0], event[1])

func step(dt: float) -> bool:
	if not is_finite(dt) or not is_finite(simulation_time) or not is_finite(simulation_time + dt):
		return _position_failure("Simulation time and step duration must be finite")
	if dt <= 0.0:
		return true
	for i in balls.size():
		if balls[i] == null or not balls[i].velocity.is_finite() or not is_finite(balls[i].velocity.length_squared()):
			return _position_failure("Ball %d: runtime velocity and squared speed must be finite" % i)
	var correction := _correct_positions()
	if not correction.ok:
		return _position_failure(correction.error)
	last_error = ""
	var remaining := dt
	var events := 0
	while remaining > TIME_EPS:
		var event := _next_event(remaining)
		var travel := minf(remaining, event.time)
		var next_positions: Array[Vector2] = []
		for ball in balls:
			var next_position := ball.position + ball.velocity * travel
			if not next_position.is_finite():
				simulation_time += dt - remaining
				return _position_failure("Movement generated a non-finite position")
			next_positions.append(next_position)
		for i in balls.size():
			balls[i].position = next_positions[i]
		remaining -= travel
		if event.contacts.is_empty():
			break
		var contacts := _contacts_at_event(event.contacts)
		var result := CollisionSolver.resolve(balls, contacts)
		if not result.ok:
			solver_failures += 1
			last_error = result.error + "; velocities unchanged, remaining substep discarded"
			push_error(last_error)
			break
		# 最后一道边界检查：先转换整批 float32 结果，确认无溢出才统一写回。
		var next_velocities: Array[Vector2] = []
		var representable := true
		for i in balls.size():
			var velocity := Vector2(result.velocities[2 * i], result.velocities[2 * i + 1])
			if not velocity.is_finite() or not is_finite(velocity.length_squared()):
				representable = false
				break
			next_velocities.append(velocity)
		if not representable:
			solver_failures += 1
			last_error = "Collision result cannot be stored as finite Vector2 state; velocities unchanged, remaining substep discarded"
			push_error(last_error)
			break
		# 所有组/墙面均完成求解后再写回，任一通知都不会观察到半算完的状态。
		for i in balls.size():
			balls[i].velocity = next_velocities[i]
		_emit_collisions(contacts, result.contacts)
		events += 1
		if events >= MAX_EVENTS and remaining > TIME_EPS:
			event_limit_hits += 1
			last_error = "Collision event safety limit reached; remaining substep discarded"
			push_error(last_error)
			break
	simulation_time += dt - remaining
	return last_error.is_empty()

func _position_failure(error: String) -> bool:
	position_failures += 1
	last_error = error
	push_error(error + "; remaining substep discarded")
	return false

func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, arena_size))
	for x in range(40, int(arena_size.x), 40):
		for y in range(40, int(arena_size.y), 40):
			draw_circle(Vector2(x, y), 1, Color(0.22, 0.29, 0.39, 0.45))
	draw_rect(Rect2(Vector2.ZERO, arena_size), Color("6685a5"), false, 3)

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111d2e")
	return style
