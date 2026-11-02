class_name Crow
extends Fighter
var dummy_timer := 2.0
var feather := false
var dummies: Array[Scarecrow] = []
func _init() -> void:
	title = "CROW"
	color = Color("a69fce")
	cd_one = 4
	cd_two = 3
	ball_collided.connect(contact)
func contact(other: Ball) -> void:
	if other is Scarecrow and other.owner_crow == self and feather and other.health > 0 and other.health < other.max_health:
		other.health = minf(other.max_health,other.health+25)
		feather = false
		other.queue_redraw()
func advance(dt: float) -> void:
	super.advance(dt)
	dummy_timer = maxf(0,dummy_timer-dt)
	if dummy_timer <= 0 and dummies.size() < 2:
		var at: Vector2 = world.free_position(20)
		if at.x >= 0:
			var dummy := Scarecrow.new()
			dummy.owner_crow = self
			dummy.world = world
			dummy.rng.seed = world.spawn_rng.randi()
			dummy.position = at
			world.register_ball(dummy)
			dummies.append(dummy)
			dummy_timer = 5
	if cd_two <= 0 and not feather:
		feather = true
		cd_two = 6
	if cd_one <= 0 and not dummies.is_empty():
		var dummy := dummies[0]
		# A larger crow must also fit at the dummy's old position.
		if world.position_clear(dummy.position,radius,self,dummy) and world.position_clear(position,dummy.radius,self,dummy):
			var old := position
			position = dummy.position
			dummy.position = old
			world.release_contacts()
			cd_one = 7
	queue_redraw()
func skill_names() -> Array[String]:
	return ["SWAP DUMMY","STORE FEATHER"]
func _draw() -> void:
	draw_circle(Vector2.ZERO,21,color)
	draw_colored_polygon(PackedVector2Array([Vector2(-10,0),Vector2(-34,-18),Vector2(-25,15)]),Color("5b537c"))
	draw_colored_polygon(PackedVector2Array([Vector2(15,-10),Vector2(36,-4),Vector2(15,2)]),Color("e2b571"))
	draw_circle(Vector2(10,-10),4,Color.WHITE)
	if feather:
		draw_line(Vector2(-5,-25),Vector2(6,-40),Color.WHITE,4)
