extends SceneTree
var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func make_arena() -> Arena:
	var arena := Arena.new()
	arena.arena_size = Vector2(1000, 1000)
	for i in 2:
		var ball := Ball.new()
		ball.radius = 10
		arena.register_ball(ball)
	return arena

func close_vec(a: Vector2, b: Vector2, tolerance: float = 0.002) -> bool:
	return a.distance_to(b) < tolerance

func set_state(ball: Ball, at: Vector2, motion: Vector2) -> void:
	ball.position = at
	ball.velocity = motion

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var a := make_arena()
	var x := a.balls[0]
	var y := a.balls[1]
	set_state(x, Vector2(100, 100), Vector2(30, 40))
	set_state(y, Vector2(700, 700), Vector2.ZERO)
	a.step(1.0)
	check(close_vec(x.position, Vector2(130, 140)), "uniform motion")
	for velocity in [Vector2(100, 0), Vector2(-100, 0), Vector2(0, 100), Vector2(0, -100)]:
		set_state(x, Vector2(500, 500), velocity)
		set_state(y, Vector2(700, 700), Vector2.ZERO)
		a.step(5)
		check(close_vec(x.velocity, -velocity), "wall reflection " + str(velocity))
		check(absf(x.velocity.length() - 100) < 0.001, "wall energy")
	set_state(x, Vector2(980, 980), Vector2(100, 100))
	a.step(0.2)
	check(close_vec(x.velocity, Vector2(-100, -100)), "corner reflection")
	set_state(x, Vector2(400, 500), Vector2(100, 0))
	set_state(y, Vector2(440, 500), Vector2(-50, 0))
	a.step(0.2)
	check(close_vec(x.velocity, Vector2(-50, 0)) and close_vec(y.velocity, Vector2(100, 0)), "head-on exchange")
	set_state(x, Vector2(400, 500), Vector2(100, 30))
	set_state(y, Vector2(420, 500), Vector2(-50, -20))
	var energy := a.kinetic_energy()
	var momentum := a.momentum()
	a.step(0.001)
	check(close_vec(x.velocity, Vector2(-50, 30)) and close_vec(y.velocity, Vector2(100, -20)), "oblique tangent preserved")
	check(absf(a.kinetic_energy() - energy) < 0.01, "pair energy")
	check(close_vec(a.momentum(), momentum), "pair momentum")
	set_state(x, Vector2(400, 500), Vector2(-100, 0))
	set_state(y, Vector2(420, 500), Vector2(100, 0))
	a.step(0.01)
	check(x.velocity.x == -100 and y.velocity.x == 100, "separating contact no impulse")
	set_state(x, Vector2(100, 300), Vector2(40000, 0))
	set_state(y, Vector2(600, 300), Vector2(-30000, 0))
	energy = a.kinetic_energy()
	a.step(1.0 / 120)
	check(absf(a.kinetic_energy() / energy - 1) < 0.0001, "CCD high-speed conservation")
	check(x.position.distance_to(y.position) >= 19.99, "CCD no tunneling overlap")
	a.free()
	var worst := 0.0
	for seed_value in 20:
		a = make_arena()
		BallFactory.initialize_demo(a.balls, a.arena_size, seed_value)
		energy = a.kinetic_energy()
		check(a.balls[0].position.distance_to(a.balls[1].position) > 20, "legal initial seed %d" % seed_value)
		for tick in 72000:
			a.step(1.0 / 120)
			if tick % 120 == 0:
				for ball in a.balls:
					check(ball.position.is_finite() and ball.velocity.is_finite(), "finite state")
					check(ball.position.x >= 9.99 and ball.position.x <= 990.01 and ball.position.y >= 9.99 and ball.position.y <= 990.01, "inside walls")
				check(a.balls[0].position.distance_to(a.balls[1].position) >= 19.98, "nonoverlap")
		worst = maxf(worst, absf(a.kinetic_energy() / energy - 1))
		check(absf(a.kinetic_energy() / energy - 1) < 0.001, "10 minute energy relative tolerance 0.1 percent")
		check(a.event_limit_hits == 0, "no event safety limit")
		a.free()
	# Exercise actual scene controller, not a duplicate test implementation.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.select_scenario(2)
	main.set_process(false)
	main.current_scenario.set_process(false)
	main.select_scenario(2, 42)
	main.current_scenario.set_process(false)
	main.set_rate(1)
	for i in 600:
		main.advance_real_time(1.0 / 60)
	var first: Vector2 = main.current_scenario.arena.balls[0].position
	var second: Vector2 = main.current_scenario.arena.balls[1].position
	main.select_scenario(2, 42)
	main.current_scenario.set_process(false)
	main.set_rate(2)
	for i in 300:
		main.advance_real_time(1.0 / 60)
	check(close_vec(main.current_scenario.arena.balls[0].position, first) and close_vec(main.current_scenario.arena.balls[1].position, second), "1x10s equals 2x5s")
	main.set_rate(0)
	main.advance_real_time(1000)
	check(close_vec(main.current_scenario.arena.balls[0].position, first), "pause preserves state")
	for i in 100:
		main.set_rate(i % 3)
	check(main.current_scenario.arena.balls.size() == 2, "repeated control no extra balls")
	main.current_scenario.suspended = true
	main.advance_real_time(1000)
	check(close_vec(main.current_scenario.arena.balls[0].position, first), "background preserves state")
	main.free()
	print("RESULT checks=%d failures=%d worst_relative_energy_error=%.9f" % [checks, failures, worst])
	quit(1 if failures else 0)
