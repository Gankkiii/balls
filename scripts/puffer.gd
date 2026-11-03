class_name Puffer
extends Fighter
const GAS_MAX := 100.0
const INFLATE_RATE := 40.0
const DEFLATE_RATE := 25.0
const IMMUNE_DURATION := 2.5
const HIT_DAMAGE := 36.0
var gas := 0.0
var immune_left := 0.0
var impact_cooldown := 0.0
var burst_base_speed := 180.0

func _init() -> void:
	title = "PUFFER"
	color = Color("50dfc0")
	ball_collided.connect(_on_contact)

func advance(dt: float) -> void:
	super.advance(dt)
	immune_left = maxf(0, immune_left - dt)
	impact_cooldown = maxf(0, impact_cooldown - dt)
	if action == "burst":
		gas = maxf(0, gas - DEFLATE_RATE * dt)
		if gas <= 0:
			velocity = velocity.normalized() * burst_base_speed
			action = "idle"
	elif action == "inflate":
		gas = minf(GAS_MAX, gas + INFLATE_RATE * dt)
	elif action == "immune":
		if immune_left <= 0:
			action = "idle"
	if gas >= GAS_MAX and action != "burst":
		start_burst()
	if action == "idle":
		# Both ready: take skill 2 first so it cannot starve behind inflation.
		if cd_two <= 0:
			action = "immune"
			immune_left = IMMUNE_DURATION
			cd_two = 9.0
		elif cd_one <= 0:
			begin_stationary("inflate")
			if world is BattleArena: world.present("puffer_inflate")
			cd_one = 6.0
	queue_redraw()

func start_burst() -> void:
	if world is BattleArena: world.present("puffer_release")
	if action == "inflate":
		resume_motion()
	burst_base_speed = clampf(velocity.length(), 140, 230)
	if velocity.length_squared() < 1:
		velocity = Vector2.RIGHT
	velocity = velocity.normalized() * burst_base_speed * 2.5
	action = "burst"

func hit(damage: float, self_blast: bool = false) -> void:
	if immune_left > 0:
		if damage > 0 and world is BattleArena: world.present("puffer_absorb")
		gas = minf(GAS_MAX, gas + damage * 1.8)
		if gas >= GAS_MAX and action != "burst":
			start_burst()
	else:
		super.hit(damage, self_blast)
	queue_redraw()

func _on_contact(other: Ball) -> void:
	if action == "burst" and impact_cooldown <= 0 and other is Fighter and (not world is BattleArena or world.is_enemy_body(self,other)):
		other.hit(HIT_DAMAGE)
		if world is BattleArena: world.present("puffer_contact")
		impact_cooldown = 0.35

func skill_names() -> Array[String]:
	return ["INFLATE", "ABSORB"]

func visual_radius() -> float:
	# Keep the established physical collider independent of the artwork.
	return radius * (1.0 + clampf(gas / GAS_MAX, 0.0, 1.0))

func _draw() -> void:
	var r := visual_radius()
	if immune_left > 0:
		draw_arc(Vector2.ZERO, r + 7, 0, TAU, 48, Color("78b9ff"), 3, true)
	if action == "burst":
		var tail := -velocity.normalized()
		for i in 3:
			draw_circle(tail * (r + 8 + i * 10), 6.0 - i, Color(0.6, 1, 0.9, 0.6 - i * 0.15))
	draw_circle(Vector2.ZERO, r, color)
	for i in 10:
		var n := Vector2.from_angle(i * TAU / 10)
		draw_line(n * (r - 2), n * (r + 5), color.lightened(0.2), 3)
	draw_circle(Vector2(-7, -5), 4, Color("0b2733"))
	draw_circle(Vector2(7, -5), 4, Color("0b2733"))
	draw_circle(Vector2(0, 6), 3, Color("0b2733"))
