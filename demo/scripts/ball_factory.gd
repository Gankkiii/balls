class_name BallFactory
extends RefCounted
## 创建整批演示球；验证成功后才返回，失败不暴露部分球。
const DefaultConfig := preload("res://configs/default_ball.tres")

static func create_demo(configs: Array[BallConfig], arena_size: Vector2, seed_value: int) -> Dictionary:
	var staged := Arena.new()
	staged.arena_size = arena_size
	for definition in configs:
		var config: BallConfig = definition if definition != null else DefaultConfig
		var ball := Ball.new()
		ball.character_definition = definition
		ball.radius = config.radius
		ball.mass = config.mass
		staged.register_ball(ball)
	# 复用 Arena 的几何、质量、放置和速度校验，不初始化战斗状态。
	var result := staged.initialize_demo(seed_value)
	if result.ok:
		result["balls"] = staged.balls.duplicate()
	staged.free()
	return result
