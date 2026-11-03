class_name TurtleShell
extends Fighter
var turtle: Fighter
var spin_left := 0.0
var spin_restore := Vector2.ZERO
func _init() -> void:
	title = "SHELL"
	radius = 22
	show_hud = false
	color = Color("8ac79a")
	ball_collided.connect(contact)
func hit(_damage: float, _self_blast: bool = false) -> void:
	pass
func contact(other: Ball) -> void:
	if other == turtle:
		if turtle.action == "seek":
			turtle.enter_shell()
		return
	if other is Fighter and world.is_enemy_body(turtle,other):
		other.hit(18 * (1.5 if spin_left > 0 else 1.0))
		if world is BattleArena: world.present("shell_turtle_contact")
		if spin_left > 0 and other.inverse_mass() > 0:
			var n := position.direction_to(other.position)
			var impulse := 100.0
			other.velocity += n * impulse * other.inverse_mass()
			velocity -= n * impulse * inverse_mass()
func start_spin() -> void:
	if world is BattleArena: world.present("shell_turtle_spin")
	spin_restore = velocity
	velocity = Vector2.ZERO
	spin_left = 2.5
func advance(dt: float) -> void:
	if spin_left > 0:
		spin_left = maxf(0,spin_left-dt)
		if spin_left == 0 and velocity.length_squared() < 1:
			velocity = spin_restore
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2.ZERO,radius,color)
	var angle := world.simulation_time*15 if spin_left > 0 else 0.0
	for i in 6:
		draw_line(Vector2.ZERO,Vector2.from_angle(angle+i*TAU/6)*radius,Color("305e49"),2)
