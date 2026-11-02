class_name FighterHUD
extends Node2D
var fighter: Fighter
func _ready() -> void:
	z_index = 20
func _process(_delta: float) -> void:
	queue_redraw()
func health_fraction() -> float:
	return clampf(fighter.health / fighter.max_health,0,1) if fighter.max_health > 0 else 0.0
func cd_text(index: int) -> String:
	var value := fighter.cd_one if index == 0 else fighter.cd_two
	return "%d: OK" % (index+1) if value <= 0 else "%d: %.1f" % [index+1,value]
func layout() -> Array[Rect2]:
	var extent := fighter.radius
	if fighter is Puffer:
		extent = fighter.visual_radius() + 5
	var health_pos := Vector2(-34,-extent-16)
	var skills_pos := Vector2(extent+8,-22)
	if fighter.world != null:
		var area: Vector2 = fighter.world.arena_size
		if fighter.position.y + health_pos.y < 2:
			health_pos.y = extent + 8
		if fighter.position.x + skills_pos.x + 62 > area.x-2:
			skills_pos.x = -extent-70
		health_pos = (fighter.position + health_pos).clamp(Vector2(2,2),area-Vector2(70,12))-fighter.position
		skills_pos = (fighter.position + skills_pos).clamp(Vector2(2,2),area-Vector2(64,46))-fighter.position
	return [Rect2(health_pos,Vector2(68,10)),Rect2(skills_pos,Vector2(62,20)),Rect2(skills_pos+Vector2(0,24),Vector2(62,20))]
func _draw() -> void:
	if not is_instance_valid(fighter):
		return
	var rects := layout()
	draw_rect(rects[0],Color("222b39"))
	var fill := rects[0]
	fill.size.x *= health_fraction()
	draw_rect(fill,Color("6be39a") if health_fraction() > 0.3 else Color("ff7777"))
	draw_rect(rects[0],Color.WHITE,false,1)
	for i in 2:
		draw_rect(rects[i+1],Color(0.035,0.07,0.13,0.9))
		var ready := (fighter.cd_one if i == 0 else fighter.cd_two) <= 0
		draw_rect(rects[i+1],Color("65e3b1") if ready else Color("91a9c4"),false,1)
		draw_string(ThemeDB.fallback_font,rects[i+1].position+Vector2(4,15),cd_text(i),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
