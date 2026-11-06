class_name BallValidation
extends RefCounted
## 集中保存只读的数据检查；不创建球、不改状态、不输出错误。
const POSITION_EPS := 1e-4
const DefaultConfig := preload("res://configs/default_ball.tres")

## 检查场地尺寸、球引用、半径和质量；成功返回空字符串。
static func geometry_error(balls: Array[Ball], arena_size: Vector2) -> String:
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

## 检查外部位置的数量、类型、有限性、边界和重叠；只读不纠正。
static func validate_positions(balls: Array[Ball], arena_size: Vector2, positions: Array) -> Dictionary:
	var error := geometry_error(balls, arena_size)
	if not error.is_empty():
		return _failure(error)
	if positions.size() != balls.size():
		return _failure("Expected %d positions, received %d" % [balls.size(), positions.size()])
	for i in positions.size():
		if not positions[i] is Vector2 or not positions[i].is_finite():
			return _failure("Ball %d: position must be a finite Vector2" % i)
	return position_constraints(balls, arena_size, positions)

## 检查已知合法结构的位置数组是否越界或重叠，供纠正迭代复查。
static func position_constraints(balls: Array[Ball], arena_size: Vector2, positions: Array) -> Dictionary:
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

## 检查角色配置类型及初始速率范围，返回验证后的配置引用。
static func speed_config(ball: Ball, index: int) -> Dictionary:
	var config: BallConfig = DefaultConfig
	if ball.character_definition != null:
		if not ball.character_definition is BallConfig:
			return _failure("Ball %d: character_definition must be a BallConfig or null" % index)
		config = ball.character_definition as BallConfig
	if not is_finite(config.min_initial_speed) or not is_finite(config.max_initial_speed) or config.min_initial_speed < 0.0 or config.max_initial_speed < config.min_initial_speed:
		return _failure("Ball %d: BallConfig requires finite 0 <= min_initial_speed <= max_initial_speed" % index)
	var minimum := Vector2(config.min_initial_speed, 0.0)
	var maximum := Vector2(config.max_initial_speed, 0.0)
	if not velocity_is_representable(maximum) or (config.min_initial_speed > 0.0 and minimum.x == 0.0) or (config.max_initial_speed > 0.0 and maximum.x == 0.0):
		return _failure("Ball %d: speed range is not representable with finite Vector2 speed and squared length" % index)
	return {"ok": true, "config": config}

## 检查速度向量及速度平方是否有限，供初始化和碰撞写回共用。
static func velocity_is_representable(velocity: Vector2) -> bool:
	return velocity.is_finite() and is_finite(velocity.length_squared())

## 检查模拟时间、步长及两者相加是否有限，不限制步长正负。
static func time_error(simulation_time: float, dt: float) -> String:
	if not is_finite(dt) or not is_finite(simulation_time) or not is_finite(simulation_time + dt):
		return "Simulation time and step duration must be finite"
	return ""

## 检查推进前每颗球的引用和运行速度。
static func runtime_velocity_error(balls: Array[Ball]) -> String:
	for i in balls.size():
		if balls[i] == null or not velocity_is_representable(balls[i].velocity):
			return "Ball %d: runtime velocity and squared speed must be finite" % i
	return ""

## 检查碰撞求解输入的质量、速度和法线，保持求解器原有边界。
static func solver_input_error(balls: Array[Ball], contacts: Array) -> String:
	for ball in balls:
		if not is_finite(ball.mass) or ball.mass <= 0.0 or not ball.velocity.is_finite():
			return "Contact solver requires finite velocities and positive finite masses"
	for contact in contacts:
		var normal: Vector2 = contact.normal
		if not normal.is_finite() or normal.length_squared() <= 0.0:
			return "Contact solver requires finite nonzero normals"
	return ""

## 检查求解器的双精度速度数组能否写回 Vector2，且速度平方有限。
static func solver_velocities_are_representable(values: PackedFloat64Array) -> bool:
	for i in range(0, values.size(), 2):
		if not is_finite(values[i]) or not is_finite(values[i + 1]):
			return false
		var velocity := Vector2(values[i], values[i + 1])
		if not velocity_is_representable(velocity):
			return false
	return true

## 构造检查失败结果，由调用方决定是否记录或输出错误。
static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}
