class_name ForgeRabbit
extends Fighter
signal presentation_hit(target: Fighter, damage: float)
const GROWTH := 8.0
var stored_damage := 0.0
var temper_left := 0.0
func _init() -> void:
	title = "FORGE RABBIT"
	color = Color("d6b2ef")
	cd_one = 2
	cd_two = 5
	ball_collided.connect(contact)
func contact(other: Ball) -> void:
	if other is Fighter and world != null and world.is_enemy_body(self,other):
		var damage := stored_damage * (1.5 if temper_left > 0 else 1.0)
		other.hit(damage)
		presentation_hit.emit(other, damage)
		stored_damage = 0
		temper_left = 0
func advance(dt: float) -> void:
	super.advance(dt)
	temper_left = maxf(0,temper_left-dt)
	stored_damage += GROWTH * dt * (1.5 if action == "forge" else 1.0)
	if action == "forge":
		action_left = maxf(0,action_left-dt)
		if action_left == 0:
			resume_motion()
	if action == "idle":
		if cd_two <= 0:
			temper_left = 3
			cd_two = 8
		elif cd_one <= 0:
			begin_stationary("forge")
			action_left = 2
			cd_one = 7
	queue_redraw()
func skill_names() -> Array[String]:
	return ["HAMMER FORGE","TEMPER"]
func _draw() -> void:
	draw_circle(Vector2.ZERO,22,color)
	for x in [-10,10]:
		draw_line(Vector2(x,-12),Vector2(x,-39),color,10)
		draw_circle(Vector2(x/2,-4),3,Color("24354c"))
	draw_line(Vector2(14,12),Vector2(36,-13),Color("ff9f5e") if temper_left > 0 else Color("d8e7ec"),6)
