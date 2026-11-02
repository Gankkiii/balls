class_name Ball
extends Node2D
## A passive simulation object. Arena alone advances its position.
signal wall_collided(normal: Vector2)
signal ball_collided(other: Ball)

@export var radius: float = 24.0
@export var mass: float = 1.0
@export var color: Color = Color("55d6be")
var velocity := Vector2.ZERO
var physics_enabled := true

func configure(at: Vector2, motion: Vector2) -> void:
	position = at
	velocity = motion
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(2, 4), radius + 2, Color(0, 0, 0, 0.25))
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius - 1, 0, TAU, 64, color.lightened(0.4), 2, true)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.2, Color(1, 1, 1, 0.45))

func inverse_mass() -> float:
	return 1.0 / mass
