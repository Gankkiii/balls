extends SceneTree
## T01–T22 automated. T23–T24 are manual, never auto-counted as passed.
const POSITION_EPS := 0.002
const VELOCITY_EPS := 0.002
const ENERGY_ABS_EPS := 0.01
const ENERGY_REL_EPS := 0.001
const BOUNDS_EPS := 0.01
const OVERLAP_EPS := 0.02
var failures := 0
var checks := 0
var case_id := ""
var case_start_failures := 0
var case_start_checks := 0
var passed_cases := 0
var failed_cases := 0
var worst_energy_error := 0.0

func begin_case(id: String, title: String) -> void:
	case_id = id
	case_start_failures = failures
	case_start_checks = checks
	print("BEGIN ", id, " ", title)

func end_case() -> void:
	if failures == case_start_failures:
		passed_cases += 1
		print("PASS ", case_id, " assertions=", checks - case_start_checks)
	else:
		failed_cases += 1
		print("FAIL ", case_id, " failures=", failures - case_start_failures)

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ", case_id, ": ", message)

func near(a: Vector2, b: Vector2, tolerance: float = POSITION_EPS) -> bool:
	return a.distance_to(b) < tolerance

func make_arena() -> Arena:
	var a := Arena.new()
	a.arena_size = Vector2(1000, 1000)
	for i in 2:
		var ball := Ball.new()
		ball.radius = 10
		a.register_ball(ball)
	return a

func make_main():
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	main.arena.initialize(42)
	return main

func state(a: Arena) -> Array:
	var result: Array = [a.simulation_time]
	for b in a.balls:
		result.append(b.position)
		result.append(b.velocity)
	return result

func legal(a: Arena) -> void:
	for b in a.balls:
		check(b.position.is_finite() and b.velocity.is_finite(), "finite state")
		check(b.position.x >= b.radius - BOUNDS_EPS and b.position.x <= a.arena_size.x - b.radius + BOUNDS_EPS and b.position.y >= b.radius - BOUNDS_EPS and b.position.y <= a.arena_size.y - b.radius + BOUNDS_EPS, "inside bounds")
	check(a.balls[0].position.distance_to(a.balls[1].position) >= a.balls[0].radius + a.balls[1].radius - OVERLAP_EPS, "nonoverlap")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	begin_case("T01", "Scene composition")
	var main = make_main()
	check(main.arena is Arena, "one Arena")
	check(main.arena.balls.size() == 2 and main.arena.get_child_count() == 2, "two Ball children")
	check(main.buttons.size() == 3, "three original controls")
	check(main.arena.balls[0] is Ball and main.arena.balls[1] is Ball, "Ball instances")
	main.free()
	end_case()

	begin_case("T02", "Legal initialization across 100 seeds")
	var a := make_arena()
	for seed_value in 100:
		a.initialize(seed_value)
		legal(a)
		check(a.balls[0].radius == a.balls[1].radius and a.balls[0].mass == a.balls[1].mass, "equal disks")
	end_case()

	begin_case("T03", "Seed reproducibility and speed limits")
	for seed_value in 100:
		a.initialize(seed_value)
		var before := state(a)
		for b in a.balls:
			check(b.velocity.length() >= a.min_initial_speed - VELOCITY_EPS and b.velocity.length() <= a.max_initial_speed + VELOCITY_EPS, "initial speed range")
		a.initialize(seed_value)
		check(state(a) == before, "same seed exact initial state")
	a.initialize(1)
	var first_seed := state(a)
	a.initialize(2)
	check(state(a) != first_seed, "chosen distinct seeds differ")
	end_case()

	begin_case("T04", "Register and remove")
	var removed := a.balls[1]
	a.register_ball(removed)
	check(a.balls.size() == 2 and a.get_child_count() == 2, "duplicate registration ignored")
	a.remove_ball(removed)
	var old_position := removed.position
	a.step(0.1)
	check(a.balls.size() == 1 and removed.get_parent() == null, "removed from membership and tree")
	check(removed.position == old_position, "removed object not simulated")
	a.register_ball(removed)
	check(a.balls.size() == 2 and removed.get_parent() == a, "can register again")
	a.free()
	end_case()

	a = make_arena()
	var x := a.balls[0]
	var y := a.balls[1]
	begin_case("T05", "Uniform motion")
	x.configure(Vector2(100, 100), Vector2(30, 40))
	y.configure(Vector2(700, 700), Vector2.ZERO)
	a.step(1.0)
	check(near(x.position, Vector2(130, 140)), "expected displacement")
	check(near(x.velocity, Vector2(30, 40), VELOCITY_EPS), "constant velocity")
	end_case()

	var velocities := [Vector2(-100, 0), Vector2(100, 0), Vector2(0, -100), Vector2(0, 100)]
	for i in 4:
		begin_case("T%02d" % (6 + i), "Wall reflection")
		x.configure(Vector2(500, 500), velocities[i])
		y.configure(Vector2(700, 700), Vector2.ZERO)
		a.step(5)
		check(near(x.velocity, -velocities[i], VELOCITY_EPS), "normal reflected")
		check(absf(x.velocity.length() - 100) < 0.001, "speed preserved")
		legal(a)
		end_case()

	begin_case("T10", "Corner")
	x.configure(Vector2(980, 980), Vector2(100, 100))
	a.step(0.2)
	check(near(x.velocity, Vector2(-100, -100), VELOCITY_EPS), "both normals reflected")
	check(near(x.position, Vector2(980, 980)), "remaining time consumed")
	legal(a)
	end_case()

	begin_case("T11", "Head-on collision")
	x.configure(Vector2(400, 500), Vector2(100, 0))
	y.configure(Vector2(440, 500), Vector2(-50, 0))
	a.step(0.2)
	check(near(x.velocity, Vector2(-50, 0)) and near(y.velocity, Vector2(100, 0)), "normal exchange")
	end_case()

	begin_case("T12", "Oblique contact, energy and momentum")
	x.configure(Vector2(400, 500), Vector2(100, 30))
	y.configure(Vector2(420, 500), Vector2(-50, -20))
	var energy := a.kinetic_energy()
	var momentum := a.momentum()
	a.step(0.001)
	check(near(x.velocity, Vector2(-50, 30)) and near(y.velocity, Vector2(100, -20)), "tangent preserved")
	check(absf(a.kinetic_energy() - energy) < ENERGY_ABS_EPS, "energy")
	check(near(a.momentum(), momentum), "momentum")
	end_case()

	begin_case("T13", "Separating contact")
	x.configure(Vector2(400, 500), Vector2(-100, 0))
	y.configure(Vector2(420, 500), Vector2(100, 0))
	for i in 10:
		a.step(0.001)
	check(x.velocity == Vector2(-100, 0) and y.velocity == Vector2(100, 0), "no impulse")
	end_case()

	begin_case("T14", "Near miss")
	x.configure(Vector2(400, 500), Vector2(100, 0))
	y.configure(Vector2(450, 520.1), Vector2.ZERO)
	a.step(1.0)
	check(near(x.position, Vector2(500, 500)) and near(x.velocity, Vector2(100, 0)), "moving ball unchanged")
	check(y.position == Vector2(450, 520.1) and y.velocity == Vector2.ZERO, "stationary ball unchanged")
	a.free()
	end_case()

	begin_case("T15", "Initial pause")
	main = make_main()
	var before := state(main.arena)
	check(main.rate == 0, "initial rate")
	main.advance_real_time(3)
	check(state(main.arena) == before, "initial state frozen")
	end_case()

	begin_case("T16", "Pause and resume")
	main.set_rate(1)
	main.advance_real_time(0.05)
	before = state(main.arena)
	check(main.arena.simulation_time > 0, "started")
	main.set_rate(0)
	main.advance_real_time(1000)
	check(state(main.arena) == before and main.accumulator == 0.0, "pause exact state")
	main.set_rate(1)
	check(state(main.arena) == before, "resume itself does not move")
	main.advance_real_time(1.0 / 120)
	check(absf(main.arena.simulation_time - float(before[0]) - 1.0 / 120) < 1e-9, "one resumed step only")
	end_case()

	begin_case("T17", "1x/2x and render frame rate equivalence")
	var reference: Array = []
	for config in [[1, 60, 600], [2, 60, 300], [1, 30, 300], [1, 144, 1440]]:
		main.arena.initialize(42)
		main.set_rate(config[0])
		for i in config[2]:
			main.advance_real_time(1.0 / config[1])
		if reference.is_empty():
			reference = state(main.arena)
		else:
			var actual := state(main.arena)
			check(absf(actual[0] - reference[0]) < 1e-9, "same simulated time")
			for i in range(1, actual.size()):
				check(near(actual[i], reference[i]), "same position and velocity")
	end_case()

	begin_case("T18", "Repeated real button signals")
	main.arena.initialize(42)
	before = state(main.arena)
	for i in 99:
		main.buttons[i % 3].pressed.emit()
	check(state(main.arena) == before, "button clicks do not move state")
	check(main.arena.balls.size() == 2 and main.arena.get_child_count() == 2, "no duplicate instances")
	main.buttons[0].pressed.emit()
	main.advance_real_time(1.0 / 60)
	check(absf(main.arena.simulation_time - 1.0 / 60) < 1e-9, "exactly one update loop")
	end_case()

	begin_case("T19", "App notifications and stall clamp")
	before = state(main.arena)
	main._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	main.advance_real_time(1000)
	check(state(main.arena) == before and main.accumulator == 0.0, "paused application frozen")
	main._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	check(state(main.arena) == before, "resume no immediate jump")
	main.advance_real_time(1.0 / 120)
	check(absf(main.arena.simulation_time - float(before[0]) - 1.0 / 120) < 1e-9, "resume small step")
	var old_time: float = main.arena.simulation_time
	main.advance_real_time(1000)
	check(main.arena.simulation_time - old_time <= 0.100001, "long stall capped")
	main.free()
	end_case()

	begin_case("T20", "High speed and multiple impacts per step")
	a = make_arena()
	x = a.balls[0]
	y = a.balls[1]
	x.configure(Vector2(100, 300), Vector2(40000, 0))
	y.configure(Vector2(600, 300), Vector2(-30000, 0))
	energy = a.kinetic_energy()
	for i in 240:
		a.step(1.0 / 120)
		legal(a)
	check(absf(a.kinetic_energy() / energy - 1) < 0.0001, "high speed energy")
	check(a.event_limit_hits == 0, "no event limit")
	end_case()

	begin_case("T21", "Small initial overlap, approaching and separating")
	for direction in [-1, 1]:
		x.configure(Vector2(400, 500), Vector2(direction * 100, 0))
		y.configure(Vector2(419.5, 500), Vector2(-direction * 100, 0))
		energy = a.kinetic_energy()
		a.step(1.0 / 120)
		legal(a)
		check(absf(a.kinetic_energy() - energy) < ENERGY_ABS_EPS, "separation adds no energy")
		check((y.velocity - x.velocity).dot(y.position - x.position) > 0, "separating after correction")
	a.free()
	end_case()

	begin_case("T22", "20 seeds, ten simulated minutes each")
	for seed_value in 20:
		a = make_arena()
		a.initialize(seed_value)
		energy = a.kinetic_energy()
		for tick in 72000:
			a.step(1.0 / 120)
			if tick % 120 == 0:
				legal(a)
				var drift := absf(a.kinetic_energy() / energy - 1)
				worst_energy_error = maxf(worst_energy_error, drift)
				check(drift < ENERGY_REL_EPS, "sampled energy drift")
		check(absf(a.kinetic_energy() / energy - 1) < ENERGY_REL_EPS, "final energy")
		check(a.event_limit_hits == 0, "no safety limit")
		a.free()
	end_case()
	print("MANUAL T23 NOT_RUN desktop/mobile visual layout and touch")
	print("MANUAL T24 NOT_RUN Android device install and lifecycle")
	print("RESULT automated_cases=%d passed=%d failed=%d manual_not_run=2 checks=%d failures=%d worst_relative_energy_error=%.9f" % [passed_cases + failed_cases, passed_cases, failed_cases, checks, failures, worst_energy_error])
	quit(1 if failures else 0)
