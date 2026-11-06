class_name BallRenderer
extends Node2D
## Read-only view of Arena's shared ball list; rendering never advances state.
var balls: Array[Ball] = []

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for ball in balls:
		draw_set_transform(ball.position)
		draw_circle(Vector2(2, 4), ball.radius + 2, Color(0, 0, 0, 0.25))
		draw_circle(Vector2.ZERO, ball.radius, ball.color)
		draw_arc(Vector2.ZERO, ball.radius - 1, 0, TAU, 64, ball.color.lightened(0.4), 2, true)
		draw_circle(Vector2(-ball.radius * 0.3, -ball.radius * 0.3), ball.radius * 0.2, Color(1, 1, 1, 0.45))
	draw_set_transform(Vector2.ZERO)
