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
const DefaultBallConfig := preload("res://configs/default_ball.tres")
@export var arena_size := Vector2(640, 680)
var balls: Array[Ball] = []
var simulation_time := 0.0
var event_limit_hits := 0
var solver_failures := 0

func register_ball(ball: Ball) -> void:
	if not balls.has(ball):
		balls.append(ball)

func remove_ball(ball: Ball) -> void:
	balls.erase(ball)

func initialize(seed_value: int) -> void:
	# 初始化每个球的位置和速度，并重置竞技场的模拟时间、事件上限命中次数和求解失败次数。
	# 先验证所有配置，错误时不重置任何球或模拟计数器。
	var configs: Array[BallConfig] = []
	for ball in balls:
		var config: BallConfig = DefaultBallConfig
		if ball.character_definition != null:
			if not ball.character_definition is BallConfig:
				push_error("Ball.character_definition must be a BallConfig or null; initialization cancelled")
				return
			config = ball.character_definition as BallConfig
		if not is_finite(config.min_initial_speed) or not is_finite(config.max_initial_speed) or config.min_initial_speed < 0.0 or config.max_initial_speed < config.min_initial_speed:
			push_error("BallConfig requires finite 0 <= min_initial_speed <= max_initial_speed; initialization cancelled")
			return
		# 配置字段是 double，但 RNG 和 Vector2 使用 float32；有限 double
		# 仍可能在转换、平方求长度时溢出，或将正速率下溢为零。
		var minimum := Vector2(config.min_initial_speed, 0.0)
		var maximum := Vector2(config.max_initial_speed, 0.0)
		if not maximum.is_finite() or not is_finite(maximum.length_squared()) or (config.min_initial_speed > 0.0 and minimum.x == 0.0) or (config.max_initial_speed > 0.0 and maximum.x == 0.0):
			push_error("BallConfig speed range is not representable with finite Vector2 speed and squared length; initialization cancelled")
			return
		configs.append(config)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var positions: Array[Vector2] = []
	var velocities: Array[Vector2] = []
	for i in balls.size():
		var ball := balls[i]
		# Separate horizontal lanes guarantee a legal initial state for two disks.
		var x := arena_size.x * (0.28 if i == 0 else 0.72)
		var y := rng.randf_range(ball.radius + 40, arena_size.y - ball.radius - 40)
		var angle := rng.randf_range(0.0, TAU)
		var position_value := Vector2(x, y)
		var velocity_value := Vector2.from_angle(angle) * rng.randf_range(configs[i].min_initial_speed, configs[i].max_initial_speed)
		if not position_value.is_finite() or not velocity_value.is_finite() or not is_finite(velocity_value.length_squared()):
			push_error("Initialization generated a non-finite position, velocity, or squared speed; all runtime state preserved")
			return
		positions.append(position_value)
		velocities.append(velocity_value)
	# 整批生成、检查完才提交；包括 RNG/向量转换的失败也不能部分初始化。
	simulation_time = 0.0
	event_limit_hits = 0
	solver_failures = 0
	for i in balls.size():
		balls[i].position = positions[i]
		balls[i].velocity = velocities[i]
	queue_redraw()

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

func _correct_positions() -> void:
	for ball in balls:
		ball.position.x = clampf(ball.position.x, ball.radius, arena_size.x - ball.radius)
		ball.position.y = clampf(ball.position.y, ball.radius, arena_size.y - ball.radius)
	for i in balls.size():
		for j in range(i + 1, balls.size()):
			var a := balls[i]
			var b := balls[j]
			var delta := b.position - a.position
			var depth := a.radius + b.radius - delta.length()
			if depth > POSITION_EPS:
				var normal := delta.normalized() if delta.length_squared() > 1e-12 else Vector2.RIGHT
				var weight := 1.0 / a.mass + 1.0 / b.mass
				a.position -= normal * depth / a.mass / weight
				b.position += normal * depth / b.mass / weight

func _next_event(horizon: float) -> Dictionary:
	var earliest := INF
	var candidates: Array = []
	for i in balls.size():
		var ball := balls[i]
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
				candidates.append({"time": time, "a": i, "b": -1, "normal": normal})
				earliest = minf(earliest, time)
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

func _contacts_at_event(seeds: Array) -> Array:
	var contacts: Array = []
	for i in balls.size():
		var ball := balls[i]
		for axis in 2:
			for side in [-1.0, 1.0]:
				var normal := Vector2.ZERO
				normal[axis] = side
				var edge: float = ball.radius if side > 0.0 else arena_size[axis] - ball.radius
				var seeded := seeds.any(func(event: Dictionary) -> bool: return event.a == i and event.b == -1 and event.normal == normal)
				var gap: float = (ball.position[axis] - edge) * side
				if seeded or gap <= 0.0:
					contacts.append({"a": i, "b": -1, "normal": normal})
		for j in range(i + 1, balls.size()):
			var delta := ball.position - balls[j].position
			var seeded := seeds.any(func(event: Dictionary) -> bool: return event.a == i and event.b == j)
			var gap := sqrt(float(delta.x) * delta.x + float(delta.y) * delta.y) - ball.radius - balls[j].radius
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

func step(dt: float) -> void:
	if dt <= 0.0:
		return
	_correct_positions()
	var remaining := dt
	var events := 0
	while remaining > TIME_EPS:
		var event := _next_event(remaining)
		var travel := minf(remaining, event.time)
		for ball in balls:
			ball.position += ball.velocity * travel
		remaining -= travel
		if event.contacts.is_empty():
			break
		var contacts := _contacts_at_event(event.contacts)
		var result := CollisionSolver.resolve(balls, contacts)
		if not result.ok:
			solver_failures += 1
			push_error(result.error + "; velocities unchanged, remaining substep discarded")
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
			push_error("Collision result cannot be stored as finite Vector2 state; velocities unchanged, remaining substep discarded")
			break
		# 所有组/墙面均完成求解后再写回，任一通知都不会观察到半算完的状态。
		for i in balls.size():
			balls[i].velocity = next_velocities[i]
		_emit_collisions(contacts, result.contacts)
		events += 1
		if events >= MAX_EVENTS and remaining > TIME_EPS:
			event_limit_hits += 1
			push_error("Collision event safety limit reached; remaining substep discarded")
			break
	simulation_time += dt - remaining

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
