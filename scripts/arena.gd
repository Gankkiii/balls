class_name Arena
extends Node2D
## Frictionless disks in an immovable box. Analytic time-of-impact (CCD).
## Units: logical pixels, seconds, arbitrary mass. No rigid body engine runs here.
const TIME_EPS := 1e-9
const VEL_EPS := 1e-7
const MAX_EVENTS := 128
@export var arena_size := Vector2(640, 680)
@export var min_initial_speed := 140.0
@export var max_initial_speed := 230.0
var balls: Array[Ball] = []
var simulation_time := 0.0
var event_limit_hits := 0

func register_ball(ball: Ball) -> void:
	if not balls.has(ball):
		balls.append(ball)
		if ball.get_parent() == null:
			add_child(ball)

func remove_ball(ball: Ball) -> void:
	balls.erase(ball)
	if ball.get_parent() == self:
		remove_child(ball)

func initialize(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	simulation_time = 0.0
	event_limit_hits = 0
	for i in balls.size():
		var ball := balls[i]
		# Separate horizontal lanes guarantee a legal initial state for two disks.
		var x := arena_size.x * (0.28 if i == 0 else 0.72)
		var y := rng.randf_range(ball.radius + 40, arena_size.y - ball.radius - 40)
		var angle := rng.randf_range(0.0, TAU)
		ball.configure(Vector2(x, y), Vector2.from_angle(angle) * rng.randf_range(min_initial_speed, max_initial_speed))
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
	var approach := p.dot(v)
	if approach >= -VEL_EPS:
		return INF
	var c := p.length_squared() - distance * distance
	if c <= 0.0:
		return 0.0
	var speed_sq := v.length_squared()
	var discriminant := approach * approach - speed_sq * c
	if speed_sq <= VEL_EPS or discriminant < 0.0:
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
			if depth > 0.0:
				var normal := delta.normalized() if delta.length_squared() > 1e-12 else Vector2.RIGHT
				var weight := 1.0 / a.mass + 1.0 / b.mass
				a.position -= normal * depth / a.mass / weight
				b.position += normal * depth / b.mass / weight

func step(dt: float) -> void:
	if dt <= 0.0:
		return
	_correct_positions()
	var remaining := dt
	var events := 0
	while remaining > TIME_EPS:
		var earliest := remaining
		var wall_events: Array = []
		var pair_events: Array = []
		for ball in balls:
			for axis in 2:
				var speed: float = ball.velocity[axis]
				if absf(speed) < VEL_EPS:
					continue
				var edge: float = arena_size[axis] - ball.radius if speed > 0.0 else ball.radius
				var t: float = maxf(0.0, (edge - ball.position[axis]) / speed)
				if t > remaining + TIME_EPS:
					continue
				if t < earliest - TIME_EPS:
					earliest = t
					wall_events.clear()
					pair_events.clear()
				if absf(t - earliest) <= TIME_EPS:
					wall_events.append([ball, axis])
		for i in balls.size():
			for j in range(i + 1, balls.size()):
				var t := _pair_time(balls[i], balls[j], remaining)
				if t < earliest - TIME_EPS:
					earliest = t
					wall_events.clear()
					pair_events.clear()
				if is_finite(t) and absf(t - earliest) <= TIME_EPS:
					pair_events.append([balls[i], balls[j]])
		for ball in balls:
			ball.position += ball.velocity * earliest
		remaining -= earliest
		for event in wall_events:
			var ball: Ball = event[0]
			var axis: int = event[1]
			ball.velocity[axis] = -ball.velocity[axis]
			var normal := Vector2.ZERO
			normal[axis] = signf(ball.velocity[axis])
			ball.wall_collided.emit(normal)
		for event in pair_events:
			var a: Ball = event[0]
			var b: Ball = event[1]
			var normal := (b.position - a.position).normalized()
			var relative := (b.velocity - a.velocity).dot(normal)
			if relative < -VEL_EPS:
				var impulse := -2.0 * relative / (1.0 / a.mass + 1.0 / b.mass)
				a.velocity -= normal * impulse / a.mass
				b.velocity += normal * impulse / b.mass
				a.ball_collided.emit(b)
				b.ball_collided.emit(a)
		if wall_events.is_empty() and pair_events.is_empty():
			break
		events += 1
		if events >= MAX_EVENTS:
			# Fail visibly rather than tunnel through geometry on pathological input.
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
