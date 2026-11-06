class_name BallRenderer
extends Node2D
## 只读使用 Arena 的共享球列表；绘制不推进或修改球的运行状态。

## 没有指定展示配色时使用的默认颜色，只属于渲染层。
const DEFAULT_DISPLAY_COLOR := Color("55d6be")
## Arena 共享的球状态列表；渲染器只读取各球的位置、半径和生命。
var balls: Array[Ball] = []
## Demo 配色记录，以 Godot 对象 ID 为键，不使用 Ball 的业务 instance_id。
## 每条记录只保存球的弱引用和展示颜色，不阻止已移除且无人持有的球释放。
## 对象存活时保留配色；对象销毁后在设置配色或下一帧清理记录。
var _display_colors: Dictionary[int, Dictionary] = {}

## ball 是要设置展示配色的球；display_color 是仅用于绘制的颜色。
func set_display_color(ball: Ball, display_color: Color) -> void:
	_forget_destroyed_balls()
	# owner 只弱引用球，color 保存展示颜色；两者属于同一条记录。
	_display_colors[ball.get_instance_id()] = {&"owner": weakref(ball), &"color": display_color}

## ball 是要查询展示配色的球；没有有效配置时返回渲染器的默认颜色。
func display_color_for(ball: Ball) -> Color:
	# entry 是该 Godot 对象 ID 对应的展示记录，空字典表示没有配置。
	var entry: Dictionary = _display_colors.get(ball.get_instance_id(), {})
	if entry.is_empty() or not is_same(entry[&"owner"].get_ref(), ball):
		return DEFAULT_DISPLAY_COLOR
	return entry[&"color"]

func _forget_destroyed_balls() -> void:
	# ball_id 是待检查记录的 Godot 对象 ID；keys() 提供独立列表，允许删除原记录。
	for ball_id in _display_colors.keys():
		if _display_colors[ball_id][&"owner"].get_ref() == null:
			_display_colors.erase(ball_id)

## _delta 是本帧经过的实际秒数；这里只清理展示记录并请求重绘，不推进模拟。
func _process(_delta: float) -> void:
	_forget_destroyed_balls()
	queue_redraw()

func _draw() -> void:
	# ball 是本次循环中要绘制的球状态。
	for ball in balls:
		# display_color 是本次绘制使用的颜色，不是球的模拟状态。
		var display_color := display_color_for(ball)
		draw_set_transform(ball.position)
		draw_circle(Vector2(2, 4), ball.radius + 2, Color(0, 0, 0, 0.25))
		draw_circle(Vector2.ZERO, ball.radius, display_color)
		draw_arc(Vector2.ZERO, ball.radius - 1, 0, TAU, 64, display_color.lightened(0.4), 2, true)
		draw_circle(Vector2(-ball.radius * 0.3, -ball.radius * 0.3), ball.radius * 0.2, Color(1, 1, 1, 0.45))
		if ball.current_health != null and ball.max_health != null and ball.max_health > 0:
			var width := ball.radius * 2.0
			var bar := Rect2(-ball.radius, -ball.radius - 10, width, 4)
			draw_rect(bar, Color(0.1, 0.1, 0.15, 0.9))
			bar.size.x *= clampf(float(ball.current_health) / float(ball.max_health), 0.0, 1.0)
			draw_rect(bar, Color("50e0bd"))
	draw_set_transform(Vector2.ZERO)
