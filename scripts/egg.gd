class_name BombEgg
extends Node2D
var owner_fighter: Fighter
var large := false
var armed := false
var fuse := 0.0
var age := 0.0
var exploded := false
var blast_left := 0.0
var radius := 11.0
var blast_radius := 70.0
var damage := 24.0

func setup(at: Vector2, owner_value: Fighter, is_large: bool) -> void:
	position = at
	owner_fighter = owner_value
	large = is_large
	if large:
		radius = 23
		blast_radius = 125
		damage = 62
		armed = true
		fuse = 1.5

func advance(dt: float, fighters: Array[Ball]) -> void:
	age += dt
	if exploded:
		blast_left -= dt
		queue_redraw()
		return
	var just_armed := false
	if not armed:
		for fighter in fighters:
			if fighter != owner_fighter and fighter is Fighter and fighter.health > 0 and fighter.physics_enabled and position.distance_to(fighter.position) <= radius + fighter.radius:
				armed = true
				fuse = 0.8
				just_armed = true
				break
	if armed and not just_armed:
		fuse = maxf(0, fuse - dt)
		if fuse <= 0:
			explode(fighters)
	queue_redraw()

func explode(fighters: Array[Ball]) -> void:
	if exploded:
		return
	exploded = true
	blast_left = 0.3
	for fighter in fighters:
		if fighter is Fighter and fighter.health > 0 and fighter.physics_enabled and position.distance_to(fighter.position) <= blast_radius + fighter.radius:
			fighter.hit(damage, fighter == owner_fighter)

func _draw() -> void:
	if exploded:
		draw_circle(Vector2.ZERO, blast_radius, Color(1, 0.55, 0.22, maxf(0, blast_left) * 1.4))
		draw_arc(Vector2.ZERO, blast_radius, 0, TAU, 48, Color("ffcc70"), 2, true)
		return
	if armed:
		draw_circle(Vector2.ZERO, blast_radius, Color(1, 0.35, 0.25, 0.06))
		draw_arc(Vector2.ZERO, radius + 6, -PI / 2, -PI / 2 + TAU * fuse / (1.5 if large else 0.8), 32, Color("ff7474"), 3, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2(0.8, 1))
	draw_circle(Vector2.ZERO, radius, Color("ff8c73") if armed else Color("fff1cd"))
	draw_set_transform(Vector2.ZERO)
	if armed:
		draw_string(ThemeDB.fallback_font, Vector2(-14, -radius - 9), "%.1f" % fuse, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
