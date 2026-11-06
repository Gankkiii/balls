## 职责边界：管理已初始化的球列表、模拟时间、运行错误、运动和碰撞；不创建球或安排出生状态。
class_name Arena
extends Node2D
## Frictionless disks in an immovable box. Analytic time-of-impact (CCD).
## Units: logical pixels, seconds, arbitrary mass. No rigid body engine runs here.
signal wall_collided(ball: Ball, normal: Vector2)
## 同一时刻只通知一次，包含全部实际球间碰撞参与者；全部速度已更新。
signal ball_collided(colliding_balls: Array[Ball])

const TIME_EPS := 1e-9
const VEL_EPS := 1e-7
const POSITION_EPS := BallValidation.POSITION_EPS
const MAX_EVENTS := 128
const MAX_POSITION_ITERATIONS := 512
@export var arena_size := Vector2(640, 680)
var balls: Array[Ball] = []
var simulation_time := 0.0
var event_limit_hits := 0
var solver_failures := 0
var position_failures := 0
var last_error := ""
## 由场景注入的纯计算回调；空回调保持纯物理模式。
var combat_resolver: Callable
var combat_failures := 0
signal combat_committed(result: CombatResult)

func register_ball(ball: Ball) -> void:
	if not balls.has(ball):
		balls.append(ball)

func remove_ball(ball: Ball) -> void:
	balls.erase(ball)

func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}

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
	var error := BallValidation.geometry_error(balls, arena_size)
	if not error.is_empty():
		return _failure(error)
	var positions: Array[Vector2] = []
	for i in balls.size():
		if not balls[i].position.is_finite():
			return _failure("Ball %d: position is not finite" % i)
		positions.append(balls[i].position)
	# 只在副本上迭代；每轮同时复查墙和球，成功后整批提交。
	for iteration in range(MAX_POSITION_ITERATIONS + 1):
		var validation := BallValidation.position_constraints(balls, arena_size, positions)
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
			candidates.append(CollisionEvent.create(balls, i, -1, contact.time, contact.normal))
		earliest = minf(earliest, wall.time)
	for i in balls.size():
		for j in range(i + 1, balls.size()):
			var time := _pair_time(balls[i], balls[j], horizon)
			if is_finite(time):
				candidates.append(CollisionEvent.create(balls, i, j, time))
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

## 复用预测事件；接触链只为尚未出现的球对创建记录。
func _complete_contact(seeds: Array, a: int, b: int, normal: Vector2) -> CollisionEvent:
	var event: CollisionEvent
	for seed: CollisionEvent in seeds:
		if seed.a == a and seed.b == b and (b >= 0 or seed.normal == normal):
			event = seed
			break
	if event == null:
		event = CollisionEvent.create(balls, a, b, seeds[0].time if not seeds.is_empty() else 0.0)
	event.normal = normal
	event.velocity_a_before = event.ball_a.velocity
	event.velocity_b_before = event.ball_b.velocity if event.ball_b != null else Vector2.ZERO
	return event

func _contacts_at_event(seeds: Array) -> Array:
	var contacts: Array = []
	for i in balls.size():
		var seeded_normals: Array[Vector2] = []
		for seed in seeds:
			if seed.a == i and seed.b == -1:
				seeded_normals.append(seed.normal)
		for normal in _wall_contacts(balls[i], seeded_normals):
			contacts.append(_complete_contact(seeds, i, -1, normal))
		for j in range(i + 1, balls.size()):
			var seeded := seeds.any(func(event: CollisionEvent) -> bool: return event.a == i and event.b == j)
			var contact := _pair_contact(balls[i], balls[j], seeded)
			if not contact.is_empty():
				contacts.append(_complete_contact(seeds, i, j, contact.normal))
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
			var contact: CollisionEvent = contacts[index]
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
		var contact: CollisionEvent = contacts[index]
		if contact.b < 0:
			wall_events.append([contact.ball_a, contact.normal])
			continue
		for ball in [contact.ball_a, contact.ball_b]:
			if not participants.has(ball):
				participants.append(ball)
	# 列表表达“同一时刻的参与者”，不表示列表中的任意两球都相撞。
	# 回调前已准备好独立列表；仅碰墙的球不混入球间碰撞通知。
	if not participants.is_empty():
		ball_collided.emit(participants)
	for event in wall_events:
		wall_collided.emit(event[0], event[1])

func step(dt: float) -> bool:
	var time_error := BallValidation.time_error(simulation_time, dt)
	if not time_error.is_empty():
		return _position_failure(time_error)
	if dt <= 0.0:
		return true
	var velocity_error := BallValidation.runtime_velocity_error(balls)
	if not velocity_error.is_empty():
		return _position_failure(velocity_error)
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
			if not BallValidation.velocity_is_representable(velocity):
				representable = false
				break
			next_velocities.append(velocity)
		if not representable:
			solver_failures += 1
			last_error = "Collision result cannot be stored as finite Vector2 state; velocities unchanged, remaining substep discarded"
			push_error(last_error)
			break
		var confirmed: Array = []
		for index in result.contacts:
			contacts[index].confirmed = true
			confirmed.append(contacts[index])
		var combat := CombatResult.new()
		if combat_resolver.is_valid():
			var candidate: Variant = combat_resolver.call(confirmed)
			if candidate is CombatResult:
				combat = candidate
			else:
				combat.error = "Combat resolver returned an invalid result"
		var combat_error := BallValidation.combat_result_error(combat, balls)
		if not combat_error.is_empty():
			combat_failures += 1
			last_error = combat_error + "; velocity and health batch not committed"
			push_error(last_error)
			break
		# 物理与战斗全部通过后一次提交；通知前不调用任何外部代码。
		for i in balls.size():
			balls[i].velocity = next_velocities[i]
		for ball: Ball in combat.health:
			ball.current_health = combat.health[ball]
		for ball in combat.dead:
			remove_ball(ball)
		_emit_collisions(contacts, result.contacts)
		if not combat.health.is_empty():
			combat_committed.emit(combat)
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
