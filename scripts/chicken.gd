class_name Chicken
extends Fighter
const PASSIVE_INTERVAL := 1.7
const CROUCH_TIME := 3.0
const SELF_DAMAGE_FACTOR := 0.2
var egg_timer := 0.6
var turn_timer := 0.0
var run_base_speed := 180.0

func _init() -> void:
	title = "CHICKEN"
	color = Color("ffda82")
	cd_one = 2.0
	cd_two = 4.0

func advance(dt: float) -> void:
	super.advance(dt)
	egg_timer -= dt
	if egg_timer <= 0:
		if world != null:
			world.spawn_egg(position, self, false)
		egg_timer += PASSIVE_INTERVAL
	if action == "lay":
		action_left = maxf(0, action_left - dt)
		if action_left <= 0:
			if world != null:
				world.spawn_egg(position, self, true)
			resume_motion()
	elif action == "run":
		action_left -= dt
		turn_timer -= dt
		if turn_timer <= 0:
			velocity = Vector2.from_angle(rng.randf_range(0, TAU)) * run_base_speed * 1.8
			turn_timer = 0.18
		if action_left <= 0:
			velocity = velocity.normalized() * run_base_speed
			action = "idle"
	if action == "idle":
		if cd_two <= 0:
			begin_stationary("lay")
			action_left = CROUCH_TIME
			cd_two = 10.0
		elif cd_one <= 0:
			action = "run"
			action_left = 1.0
			turn_timer = 0.0
			run_base_speed = clampf(velocity.length(), 140, 230)
			cd_one = 5.0
	queue_redraw()

func hit(damage: float, self_blast: bool = false) -> void:
	super.hit(damage * SELF_DAMAGE_FACTOR if self_blast else damage)

func skill_names() -> Array[String]:
	return ["PANIC RUN", "BIG EGG"]

func _draw() -> void:
	# Separate presentation: replace this with AnimatedSprite2D later; collider stays a disk.
	var crouch := action == "lay"
	var offset := Vector2(0, 5) if crouch else Vector2.ZERO
	draw_colored_polygon(PackedVector2Array([Vector2(-20, 0), Vector2(-34, -13), Vector2(-30, 7), Vector2(-18, 13)]) , Color("e3a850"))
	draw_set_transform(offset, 0, Vector2(1.1, 0.65 if crouch else 0.85))
	draw_circle(Vector2.ZERO, 22, Color("ffe4a0"))
	draw_circle(Vector2(-4, 3), 12, Color("dfad62"))
	draw_set_transform(offset)
	draw_circle(Vector2(13, -17), 13, Color("fff2c6"))
	for i in 3:
		draw_circle(Vector2(7 + i * 6, -29), 5, Color("f16a66"))
	draw_colored_polygon(PackedVector2Array([Vector2(23, -18), Vector2(36, -12), Vector2(23, -8)]), Color("f3a344"))
	draw_circle(Vector2(16, -19), 3, Color("182433"))
	draw_circle(Vector2(23, -3), 4, Color("e95555"))
	if not crouch:
		for x in [-8, 8]:
			draw_line(Vector2(x, 17), Vector2(x, 29), Color("f0a24c"), 3)
			draw_line(Vector2(x - 4, 29), Vector2(x + 6, 29), Color("f0a24c"), 3)
	draw_set_transform(Vector2.ZERO)
