class_name Cactus
extends Fighter
var thorns: Array[Vector2] = []
func _init() -> void:
	title = "CACTUS"
	color = Color("79ce87")
	cd_one = 2
	cd_two = 6
	ball_collided.connect(contact)
func inverse_mass() -> float:
	return 0
func contact(other: Ball) -> void:
	if other is Fighter and world != null and world.is_enemy_body(self,other):
		other.hit(18)
func advance(dt: float) -> void:
	super.advance(dt)
	velocity = Vector2.ZERO
	if cd_one <= 0:
		for i in 5:
			var at := position + Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(40,85)
			thorns.append(at.clamp(Vector2(8,8),world.arena_size-Vector2(8,8)))
		cd_one = 6
	if cd_two <= 0:
		var at: Vector2 = world.free_position(radius,self)
		if at.x >= 0:
			position = at
			world.release_contacts()
			cd_two = 9
	queue_redraw()
func step_thorns() -> void:
	for i in range(thorns.size()-1,-1,-1):
		for target in world.attack_targets(self):
			if thorns[i].distance_to(target.position) <= target.radius+6:
				target.hit(12)
				thorns.remove_at(i)
				break
func skill_names() -> Array[String]:
	return ["SCATTER THORNS","REGROW"]
func _draw() -> void:
	draw_line(Vector2(0,20),Vector2(0,-22),color,26)
	for side in [-1,1]:
		draw_line(Vector2.ZERO,Vector2(side*25,0),color,10)
		draw_line(Vector2(side*25,0),Vector2(side*25,-15),color,10)
	for i in 9:
		var n := Vector2.from_angle(i*TAU/9)
		draw_line(n*17,n*28,Color("e3f3bc"),2)
