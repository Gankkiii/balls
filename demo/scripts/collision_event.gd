class_name CollisionEvent
extends RefCounted
## 同一记录从预测进入求解和战斗；normal 始终从 b 指向 a（墙法线朝内）。
var a: int
var b: int
var ball_a: Ball
var ball_b: Ball
var time := 0.0
var normal := Vector2.ZERO
var velocity_a_before := Vector2.ZERO
var velocity_b_before := Vector2.ZERO
var confirmed := false

static func create(items: Array[Ball], index_a: int, index_b: int, at: float = 0.0, direction: Vector2 = Vector2.ZERO) -> CollisionEvent:
	var event := CollisionEvent.new()
	event.a = index_a
	event.b = index_b
	event.ball_a = items[index_a]
	event.ball_b = items[index_b] if index_b >= 0 else null
	event.time = at
	event.normal = direction
	return event
