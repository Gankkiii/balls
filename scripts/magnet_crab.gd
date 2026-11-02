class_name MagnetCrab
extends Fighter
var nail_timer := 0.5
var repel_ready := false
var magnetic_wall := -1
var wall_flash := 0.0
func _init() -> void:
	title = "MAGNET CRAB"
	color = Color("fa8673")
	cd_one = 4
	cd_two = 3
func advance(dt: float) -> void:
	super.advance(dt)
	wall_flash = maxf(0,wall_flash-dt)
	nail_timer -= dt
	if nail_timer <= 0:
		world.spawn_nail(self,position)
		nail_timer += 1.0
	if cd_two <= 0 and not repel_ready:
		repel_ready = true
		cd_two = 6
	if cd_one <= 0:
		magnetize(rng.randi_range(0,3))
		cd_one = 7
	queue_redraw()
func magnetize(wall: int) -> void:
	magnetic_wall = wall
	wall_flash = 1
	for nail in world.nails:
		if nail.owner_fighter != self or nail.gone:
			continue
		nail.mode = "wall"
		nail.target = nail.position
		match wall:
			0: nail.target.x = 5
			1: nail.target.x = world.arena_size.x-5
			2: nail.target.y = 5
			3: nail.target.y = world.arena_size.y-5
func skill_names() -> Array[String]:
	return ["MAGNET WALL", "RETURN REPEL"]
func _draw() -> void:
	for side in [-1,1]:
		for i in 3:
			draw_line(Vector2(side*15, i*8-5),Vector2(side*31,i*11-8),color,3)
		draw_circle(Vector2(side*26,-21),10,color)
	draw_set_transform(Vector2.ZERO,0,Vector2(1.15,0.75))
	draw_circle(Vector2.ZERO,22,color)
	draw_set_transform(Vector2.ZERO)
	for x in [-9,9]:
		draw_circle(Vector2(x,-17),5,Color.WHITE)
		draw_circle(Vector2(x,-18),2,Color("182433"))
