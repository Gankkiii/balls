class_name BubbleFish
extends Fighter
var bubble_timer := 0.5
func _init() -> void:
	title = "BUBBLE FISH"
	color = Color("75cfff")
	cd_one = 2
	cd_two = 4
func advance(dt: float) -> void:
	super.advance(dt)
	bubble_timer -= dt
	if bubble_timer <= 0:
		world.spawn_bubble(self, position, Vector2.ZERO)
		bubble_timer += 1.1
	if cd_one <= 0:
		var target: Fighter = world.enemy_of(self)
		var direction := position.direction_to(target.position)
		world.spawn_bubble(self, position, direction * 170, 2.5, 2.5)
		cd_one = 7
	if cd_two <= 0:
		for i in 8:
			world.spawn_bubble(self, position + Vector2.from_angle(i * TAU / 8) * 42, Vector2.from_angle(i * TAU / 8) * 150, 0.8)
		cd_two = 9
	queue_redraw()
func skill_names() -> Array[String]:
	return ["VACUUM BUBBLE", "EIGHT BUBBLES"]
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-16,0), Vector2(-36,-18), Vector2(-36,18)]), color)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.15,0.8))
	draw_circle(Vector2.ZERO, 23, color)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(12,-6),5,Color.WHITE)
	draw_circle(Vector2(14,-6),2,Color("14283f"))
	draw_arc(Vector2(21,4),5,0,TAU,16,Color.WHITE,2)
