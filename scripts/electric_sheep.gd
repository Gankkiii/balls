class_name ElectricSheep
extends Fighter
const MAX_CHARGE := 100.0
const DRAIN := 25.0
const DPS := 20.0
const RANGE := 110.0
var charge := 0.0
var wool_active := false
var wool_position := Vector2.ZERO
var zapping := false
func _init() -> void:
	title = "ELECTRIC SHEEP"
	color = Color("fff3c0")
	cd_one = 2
	cd_two = 3
	wall_collided.connect(_wall_charge)
func _wall_charge(_normal: Vector2) -> void:
	charge = minf(MAX_CHARGE, charge + 30)
func advance(dt: float) -> void:
	super.advance(dt)
	if cd_one <= 0:
		var distances := [position.x, world.arena_size.x-position.x, position.y, world.arena_size.y-position.y]
		var nearest := 0
		for i in range(1,4):
			if distances[i] < distances[nearest]:
				nearest = i
		velocity = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN][nearest] * maxf(140, velocity.length())
		cd_one = 5
	if cd_two <= 0:
		wool_active = true
		wool_position = position
		cd_two = 7
	queue_redraw()
func discharge(dt: float) -> void:
	var enemy: Fighter = world.enemy_of(self)
	var in_range := position.distance_to(enemy.position) <= RANGE + enemy.radius
	if wool_active:
		in_range = in_range or wool_position.distance_to(enemy.position) <= RANGE + enemy.radius
	zapping = charge > 0 and enemy.health > 0 and in_range
	if zapping:
		var spent := minf(charge, DRAIN * dt)
		charge -= spent
		var origin := position
		if position.distance_to(enemy.position) > RANGE + enemy.radius and wool_active:
			origin = wool_position
		var target: Fighter = world.first_target(self,origin,enemy.position)
		if target != null:
			target.hit(DPS * spent / DRAIN)
	queue_redraw()
func skill_names() -> Array[String]:
	return ["WALL TURN", "DROP WOOL"]
func _draw() -> void:
	for i in 7:
		draw_circle(Vector2.from_angle(i * TAU / 7) * 14, 13, color)
	draw_circle(Vector2(12,3),12,Color("665a6d"))
	draw_circle(Vector2(15,-1),3,Color.WHITE)
	if charge > 0:
		draw_arc(Vector2.ZERO,32,-PI/2,-PI/2+TAU*charge/MAX_CHARGE,32,Color("ffe45c"),3)
