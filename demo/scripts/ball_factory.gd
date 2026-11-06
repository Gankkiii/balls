## 职责边界：创建及初始化球；只管理球的出生数据，不管理场景、模拟时间或竞技场错误计数。
class_name BallFactory
extends RefCounted
## 负责创建球、生成初始位置和速度；整批验证后才写回状态。
const DefaultConfig := preload("res://configs/default_ball.tres")

## 按各球配置创建演示球；失败不暴露部分球，且只输出一次错误。
static func create_demo(configs: Array[BallConfig], arena_size: Vector2, seed_value: int) -> Dictionary:
	var balls: Array[Ball] = []
	for definition in configs:
		var config: BallConfig = definition if definition != null else DefaultConfig
		var error := BallValidation.combat_config_error(config)
		if not error.is_empty():
			push_error(error)
			return _failure(error)
		var ball := Ball.new()
		ball.max_health = config.max_health
		ball.current_health = config.max_health
		ball.attack = config.attack
		ball.defense = config.defense
		if config.impact_skill != null:
			var skill := BallSkillState.new()
			skill.skill_id = &"impact"
			skill.skill_definition = config.impact_skill
			ball.skills.append(skill)
		ball.character_definition = definition
		ball.radius = config.radius
		ball.mass = config.mass
		balls.append(ball)
	var result := initialize_demo(balls, arena_size, seed_value)
	if result.ok:
		result["balls"] = balls
	else:
		push_error(result.error + "; initialization cancelled, runtime state preserved")
	return result

## 初始化已有球的演示位置和速度，不重写半径、质量或战斗状态。
static func initialize_demo(balls: Array[Ball], arena_size: Vector2, seed_value: int) -> Dictionary:
	var placement := generate_demo_positions(balls, arena_size, seed_value)
	if not placement.ok:
		return _failure(placement.error)
	return initialize_positions(balls, arena_size, seed_value, placement.positions, true)

## 只生成演示位置；保留原随机采样和网格回退，不修改球。
static func generate_demo_positions(balls: Array[Ball], arena_size: Vector2, seed_value: int) -> Dictionary:
	var error := BallValidation.geometry_error(balls, arena_size)
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
		if BallValidation.validate_positions(balls, arena_size, positions).ok:
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
	var validation := BallValidation.validate_positions(balls, arena_size, positions)
	if not validation.ok:
		return _failure("Demo grid did not produce representable valid positions: " + validation.error)
	return {"ok": true, "positions": positions}

## 验证指定位置并生成速度；全部成功后提交，不替换球列表或球对象。
static func initialize_positions(balls: Array[Ball], arena_size: Vector2, seed_value: int, initial_positions: Array, demo_sampling: bool = false) -> Dictionary:
	var validation := BallValidation.validate_positions(balls, arena_size, initial_positions)
	if not validation.ok:
		return _failure(validation.error)
	var configs: Array[BallConfig] = []
	for i in balls.size():
		var checked := BallValidation.speed_config(balls[i], i)
		if not checked.ok:
			return _failure(checked.error)
		configs.append(checked.config)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var velocities: Array[Vector2] = []
	for i in balls.size():
		if demo_sampling:
			rng.randf()
		var angle := rng.randf_range(0.0, TAU)
		var velocity := Vector2.from_angle(angle) * rng.randf_range(configs[i].min_initial_speed, configs[i].max_initial_speed)
		if not BallValidation.velocity_is_representable(velocity):
			return _failure("Ball %d: generated velocity or squared speed is not finite" % i)
		velocities.append(velocity)
	for i in balls.size():
		balls[i].position = initial_positions[i]
		balls[i].velocity = velocities[i]
	return {"ok": true, "error": ""}

static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}
