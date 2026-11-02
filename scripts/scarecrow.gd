class_name Scarecrow
extends Fighter
var owner_crow: Fighter
func _init() -> void:
	title = "SCARECROW"
	health = 60
	max_health = 60
	radius = 20
	color = Color("bc9369")
func inverse_mass() -> float:
	return 0
func hit(damage: float, _self_blast: bool = false) -> void:
	if health <= 0:
		return
	var actual := minf(health,maxf(0,damage))
	health -= actual
	# Reflection bypasses dummy routing: no recursive chains.
	world.enemy_of(owner_crow).hit(actual)
	queue_redraw()
func skill_names() -> Array[String]:
	return ["", ""]
func _draw() -> void:
	draw_line(Vector2(0,20),Vector2(0,-15),color,6)
	draw_line(Vector2(-24,0),Vector2(24,0),color,6)
	draw_circle(Vector2(0,-15),10,Color("e6c97c"))
	draw_rect(Rect2(-12,-27,24,5),Color("3f4056"))
