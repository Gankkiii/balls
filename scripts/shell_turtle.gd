class_name ShellTurtle
extends Fighter
var shell: TurtleShell
func _init() -> void:
	title = "SHELL TURTLE"
	color = Color("bcdb96")
	cd_one = 3
	cd_two = 5
	ball_collided.connect(contact)
func contact(other: Ball) -> void:
	if action != "hidden" and world != null and other is Fighter and world.is_enemy_body(self,other):
		hit(12)
func hit(damage: float, self_blast: bool = false) -> void:
	if action != "hidden":
		super.hit(damage,self_blast)
func enter_shell() -> void:
	if world is BattleArena: world.present("shell_turtle_enter")
	action = "hidden"
	action_left = 2.5
	physics_enabled = false
	visible = false
	position = shell.position
	velocity = Vector2.ZERO
func advance(dt: float) -> void:
	super.advance(dt)
	if action == "hidden":
		position = shell.position
		action_left = maxf(0,action_left-dt)
		if action_left == 0:
			var at: Vector2 = world.free_position(radius,self,shell.position)
			if at.x >= 0:
				position = at
				if world is BattleArena: world.present("shell_turtle_exit")
				physics_enabled = true
				visible = true
				velocity = Vector2.from_angle(rng.randf_range(0,TAU))*170
				action = "idle"
	elif action == "seek":
		action_left -= dt
		velocity = position.direction_to(shell.position)*240
		if position.distance_to(shell.position) <= radius+shell.radius+0.02:
			enter_shell()
		elif action_left <= 0:
			action = "idle"
	if cd_two <= 0:
		shell.start_spin()
		cd_two = 8
	if cd_one <= 0 and action == "idle":
		action = "seek"
		action_left = 6
		cd_one = 9
	queue_redraw()
func skill_names() -> Array[String]:
	return ["HIDE IN SHELL","SPIN SHELL"]
func _draw() -> void:
	draw_circle(Vector2.ZERO,18,color)
	for at in [Vector2(-17,-12),Vector2(-17,12),Vector2(17,-12),Vector2(17,12)]:
		draw_circle(at,7,color)
	draw_circle(Vector2(23,0),10,color)
	draw_circle(Vector2(25,-3),2,Color("24354c"))
