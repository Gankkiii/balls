class_name Bubble
extends Node2D
var owner_fighter: Fighter
var level: int = 1
var velocity := Vector2.ZERO
var launch_left := 0.0
var absorb_left := 0.0
var turn_left := 0.0
var gone := false
var rng := RandomNumberGenerator.new()

func size_radius() -> float:
	# Level has no gameplay cap. Only artwork/hitbox growth is bounded.
	return minf(54, 9 + sqrt(float(level)) * 3)

func advance(dt: float, area: Vector2) -> void:
	absorb_left = maxf(0, absorb_left - dt)
	if launch_left > 0:
		launch_left = maxf(0, launch_left - dt)
		if launch_left == 0:
			turn_left = 0
	else:
		turn_left -= dt
		if turn_left <= 0:
			velocity = Vector2.from_angle(rng.randf_range(0, TAU)) * 22
			turn_left = rng.randf_range(0.5, 1.3)
	position += velocity * dt
	var r := size_radius()
	if position.x < r or position.x > area.x - r:
		velocity.x *= -1
	if position.y < r or position.y > area.y - r:
		velocity.y *= -1
	position = position.clamp(Vector2.ONE * r, area - Vector2.ONE * r)
	queue_redraw()

func _draw() -> void:
	var r := size_radius()
	draw_circle(Vector2.ZERO, r, Color(0.3, 0.75, 1, 0.2))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color("75d8ff") if level > 1 else Color("b5d7e8"), 2, true)
	if absorb_left > 0:
		draw_arc(Vector2.ZERO, 105, 0, TAU, 48, Color(0.4, 0.9, 1, 0.35), 1, true)
	draw_string(ThemeDB.fallback_font, Vector2(-8, 5), str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
