extends SceneTree
## Independently initialized gameplay scenarios. PASS only after at least one assertion.
var checks := 0
var failures := 0
var passed := 0
var failed := 0
var start_checks := 0
var start_failures := 0
var current := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ", current, ": ", message)

func scenario(id: String, title: String, test: Callable) -> void:
	current = id
	start_checks = checks
	start_failures = failures
	print("BEGIN ", id, " ", title)
	test.call()
	if checks == start_checks:
		failures += 1
		printerr("FAIL ", id, ": no assertions executed")
	if failures == start_failures:
		passed += 1
		print("PASS ", id, " assertions=", checks-start_checks)
	else:
		failed += 1
		print("FAIL ", id, " failures=", failures-start_failures)

func battle(pair: Array) -> BattleArena:
	var a := BattleArena.new()
	a.setup(225, pair)
	for f in a.heroes:
		f.cd_one = 999
		f.cd_two = 999
	return a

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	scenario("G01", "Contact only once until separation", contact_once)
	scenario("G02", "Stationary cactus reflects incoming fighter", cactus_reflection)
	scenario("G03", "Blocked crow swap stays ready", blocked_swap)
	scenario("G04", "Shell restores velocity when spin ends untouched", spin_restore)
	scenario("G05", "Shell preserves collision motion when spin ends", spin_moving)
	scenario("G06", "Hidden turtle survives lightning", hidden_lightning)
	scenario("G07", "Hidden turtle survives explosion", hidden_explosion)
	scenario("G08", "Reflected lethal hit ends the fight", reflected_lethal)
	scenario("G09", "Dead fighter loses despite surviving shell", shell_survivor)
	scenario("G10", "Finished fight freezes skill timers and RNG", finished_freeze)
	scenario("G11", "Duck does not transfer cloud to turtle shell", duck_shell)
	scenario("G12", "Real turtle seek enters shell", turtle_seek)
	scenario("G13", "Blocked cactus relocation preserves position", blocked_cactus)
	scenario("G14", "Blocked turtle emergence retries safely", blocked_emergence)
	scenario("G15", "Paused hidden turtle freezes state", paused_hidden)
	scenario("G16", "New game clears hidden turtle state", restart_hidden)
	scenario("G17", "Pause freezes imminent lightning", paused_duck)
	scenario("G18", "Hidden state agrees across speed settings", hidden_speed)
	scenario("G19", "Nearest dummy intercepts projectile", nearest_intercept)
	scenario("G20", "Nail hit cooldown is per projectile", nail_cooldown)
	scenario("G21", "Puffer cooldown is independent per target", puffer_targets)
	scenario("G22", "Sheep and wool never double-discharge", sheep_wool)
	scenario("G23", "Small egg waits for fuse", egg_fuse)
	scenario("G24", "Rabbit temper applies once", rabbit_temper)
	scenario("G25", "Lightning rod blocks once then disappears", lightning_rod)
	print("INDEPENDENT RESULT cases=%d passed=%d failed=%d assertions=%d failures=%d" % [passed+failed, passed, failed, checks, failures])
	quit(1 if failed or failures else 0)

func contact_once() -> void:
	var a := battle([7,0])
	var cactus: Cactus = a.heroes[0]
	var victim: Fighter = a.heroes[1]
	cactus.position = Vector2(300,300)
	victim.position = Vector2(348,300)
	victim.velocity = Vector2(-100,0)
	var hp := victim.health
	a.step(0.000001)
	check(victim.health == hp-18, "first collision hits once")
	victim.velocity = Vector2(-100,0)
	a.step(0.000001)
	check(victim.health == hp-18, "retained contact does not hit twice")
	victim.position = Vector2(420,300)
	victim.velocity = Vector2.ZERO
	a.step(0.01)
	victim.position = Vector2(348,300)
	victim.velocity = Vector2(-100,0)
	a.step(0.01)
	check(victim.health == hp-36, "new contact after separation hits again")
	a.free()

func cactus_reflection() -> void:
	var a := battle([7,0])
	var c: Cactus = a.heroes[0]
	var b: Fighter = a.heroes[1]
	c.position = Vector2(300,300)
	b.position = Vector2(348,300)
	b.velocity = Vector2(-100,25)
	a.step(0.01)
	check(c.position == Vector2(300,300) and c.velocity == Vector2.ZERO, "cactus remains fixed")
	check(b.velocity.x > 0 and is_equal_approx(b.velocity.y,25), "normal reflected and tangent preserved")
	check(c.position.distance_to(b.position) >= c.radius+b.radius-0.02, "no overlap")
	a.free()

func blocked_swap() -> void:
	var a := battle([9,0])
	var crow: Crow = a.heroes[0]
	var opponent: Fighter = a.heroes[1]
	crow.position = Vector2(100,100)
	crow.dummy_timer = 0
	crow.advance(0.01)
	check(crow.dummies.size() == 1, "dummy exists")
	var dummy: Scarecrow = crow.dummies[0]
	dummy.position = Vector2(300,300)
	opponent.position = Vector2(350,300)
	var old_crow := crow.position
	var old_dummy := dummy.position
	crow.cd_one = 0
	crow.advance(0.01)
	check(crow.position == old_crow and dummy.position == old_dummy, "blocked swap does not move either")
	check(crow.cd_one == 0, "blocked swap does not consume cooldown")
	opponent.position = Vector2(600,500)
	crow.advance(0.01)
	check(crow.position == old_dummy and dummy.position == old_crow and crow.cd_one > 0, "swap works after obstacle removed")
	a.free()

func spin_restore() -> void:
	var a := battle([8,0])
	var s: TurtleShell = a.heroes[0].shell
	s.velocity = Vector2(30,40)
	s.start_spin()
	check(s.velocity == Vector2.ZERO, "spin stops shell")
	s.advance(2.49)
	check(s.spin_left > 0 and s.velocity == Vector2.ZERO, "still spinning")
	s.advance(0.02)
	check(s.spin_left == 0 and s.velocity == Vector2(30,40), "restores saved motion")
	a.free()

func spin_moving() -> void:
	var a := battle([8,0])
	var s: TurtleShell = a.heroes[0].shell
	var enemy: Fighter = a.heroes[1]
	s.position = Vector2(300,300)
	enemy.position = Vector2(346,300)
	s.velocity = Vector2(30,40)
	s.start_spin()
	s.contact(enemy)
	var after := s.velocity
	check(after.length_squared() > 1, "collision gives shell motion")
	s.advance(2.51)
	check(s.spin_left == 0 and s.velocity == after, "preserves collision motion")
	a.free()

func hidden_lightning() -> void:
	var a := battle([5,8])
	var duck: UnluckyDuck = a.heroes[0]
	var turtle: ShellTurtle = a.heroes[1]
	turtle.enter_shell()
	duck.cloud_holder = turtle
	duck.rods.clear()
	var hp := turtle.health
	duck.strike()
	check(turtle.health == hp and turtle.action == "hidden", "lightning causes no damage while hidden")
	a.free()

func hidden_explosion() -> void:
	var a := battle([1,8])
	var chicken: Chicken = a.heroes[0]
	var turtle: ShellTurtle = a.heroes[1]
	turtle.enter_shell()
	var hp := turtle.health
	a.spawn_egg(turtle.position,chicken,true)
	a.eggs[0].explode(a.balls)
	check(turtle.health == hp, "explosion cannot damage hidden turtle")
	a.free()

func reflected_lethal() -> void:
	var a := battle([9,6])
	var crow: Crow = a.heroes[0]
	var rabbit: ForgeRabbit = a.heroes[1]
	crow.dummy_timer = 0
	crow.advance(0.01)
	var dummy: Scarecrow = crow.dummies[0]
	rabbit.health = 5
	rabbit.stored_damage = 10
	rabbit.contact(dummy)
	check(rabbit.health == 0, "reflected damage defeats attacker")
	a.step(0.01)
	check(a.finished and a.result == "CROW WINS", "actual reflected defeat yields crow victory")
	a.free()

func shell_survivor() -> void:
	var a := battle([8,0])
	var turtle: ShellTurtle = a.heroes[0]
	check(turtle.shell.health > 0, "shell exists")
	turtle.hit(999)
	a.step(0.01)
	check(a.finished and a.result == "PUFFER WINS", "shell cannot prevent owner's defeat")
	a.free()

func finished_freeze() -> void:
	var a := battle([5,0])
	var duck: UnluckyDuck = a.heroes[0]
	a.heroes[1].health = 0
	a.step(0.01)
	var before := [a.simulation_time,duck.storm_left,duck.cd_one,duck.rng.state,a.spawn_rng.state]
	a.step(4)
	check(before == [a.simulation_time,duck.storm_left,duck.cd_one,duck.rng.state,a.spawn_rng.state], "timers and RNG frozen")
	a.free()

func duck_shell() -> void:
	var a := battle([5,8])
	var duck: UnluckyDuck = a.heroes[0]
	var turtle: ShellTurtle = a.heroes[1]
	duck.cloud_holder = duck
	duck.contact(turtle.shell)
	check(duck.cloud_holder == duck, "shell cannot hold storm cloud")
	a.free()

func turtle_seek() -> void:
	var a := battle([8,0])
	var turtle: ShellTurtle = a.heroes[0]
	var shell: TurtleShell = turtle.shell
	var opponent: Fighter = a.heroes[1]
	turtle.position = Vector2(100,200)
	turtle.velocity = Vector2.ZERO
	shell.position = Vector2(220,200)
	shell.velocity = Vector2.ZERO
	opponent.position = Vector2(600,500)
	opponent.velocity = Vector2.ZERO
	turtle.cd_one = 0
	for i in 120:
		a.step(1.0/120)
		if turtle.action == "hidden": break
	check(turtle.action == "hidden" and not turtle.physics_enabled, "seek reaches and enters shell")
	a.free()

func blocked_cactus() -> void:
	var a := battle([7,0])
	var c: Cactus = a.heroes[0]
	a.arena_size = Vector2(50,50)
	c.position = Vector2(25,25)
	c.cd_two = 0
	c.advance(0.01)
	check(c.position == Vector2(25,25) and c.cd_two == 0, "no legal placement leaves cactus and cooldown unchanged")
	a.free()

func blocked_emergence() -> void:
	var a := battle([8,0])
	var t: ShellTurtle = a.heroes[0]
	a.arena_size = Vector2(50,50)
	t.shell.position = Vector2(25,25)
	t.enter_shell()
	t.advance(3)
	check(t.action == "hidden" and not t.physics_enabled, "no legal exit keeps turtle hidden")
	a.arena_size = Vector2(700,600)
	t.shell.position = Vector2(300,300)
	a.heroes[1].position = Vector2(600,500)
	t.advance(0.01)
	check(t.action == "idle" and t.physics_enabled, "turtle emerges once space is available")
	check(t.position.distance_to(t.shell.position) >= t.radius+t.shell.radius, "exit does not overlap shell")
	a.free()

func controller(pair: Array):
	var main = load("res://scenes/main.tscn").instantiate()
	main.page_save_path_override = "user://independent_%d_%d.jsonl" % [OS.get_process_id(), Time.get_ticks_usec()]
	root.add_child(main)
	main.set_process(false)
	main.arena.free()
	main.arena = battle(pair)
	main.add_child(main.arena)
	return main

func paused_hidden() -> void:
	var main = controller([8,0])
	var t: ShellTurtle = main.arena.heroes[0]
	t.enter_shell()
	var before := [t.action, t.action_left, t.position, t.health, main.arena.simulation_time]
	main.set_rate(0)
	main.advance_real_time(10)
	check(before == [t.action, t.action_left, t.position, t.health, main.arena.simulation_time], "hidden state frozen throughout pause")
	main.free()

func restart_hidden() -> void:
	var main = controller([8,0])
	var t: ShellTurtle = main.arena.heroes[0]
	t.enter_shell()
	main.buttons[5].pressed.emit()
	check(main.arena.simulation_time == 0 and not main.arena.finished, "restart clears battle progress")
	check(main.arena.heroes.size() == 2 and main.arena.heroes[0].action != "hidden" and main.arena.heroes[1].action != "hidden", "restart creates fresh visible fighters")
	main.free()

func paused_duck() -> void:
	var main = controller([5,0])
	var duck: UnluckyDuck = main.arena.heroes[0]
	duck.storm_left = 0.05
	var hp := duck.health
	main.set_rate(0)
	main.advance_real_time(3)
	check(is_equal_approx(duck.storm_left,0.05) and duck.health == hp, "lightning countdown freezes on pause")
	main.free()

func hidden_speed() -> void:
	var reference: Array = []
	for speed in [1,2,3]:
		var main = controller([8,0])
		var t: ShellTurtle = main.arena.heroes[0]
		t.enter_shell()
		main.set_rate(speed)
		for i in int(120 / speed):
			main.advance_real_time(1.0/120)
		var state := [t.action,t.action_left,t.position,t.health,t.shell.position,t.shell.velocity,main.arena.simulation_time]
		if reference.is_empty(): reference = state
		check(state == reference, "same simulated time yields same hidden state at %dx" % speed)
		main.free()

func nearest_intercept() -> void:
	var a := battle([9,0])
	var crow: Crow = a.heroes[0]
	var enemy: Fighter = a.heroes[1]
	crow.dummy_timer = 0
	crow.advance(0.01)
	var dummy: Scarecrow = crow.dummies[0]
	enemy.position = Vector2(100,300)
	dummy.position = Vector2(300,300)
	crow.position = Vector2(450,300)
	check(a.first_target(enemy,Vector2(100,300),Vector2(500,300)) == dummy, "nearest target blocks farther crow")
	dummy.health = 0
	check(a.first_target(enemy,Vector2(100,300),Vector2(500,300)) == crow, "dead dummy no longer blocks")
	a.free()

func nail_cooldown() -> void:
	var a := battle([4,0])
	var crab: MagnetCrab = a.heroes[0]
	var victim: Fighter = a.heroes[1]
	var nail := a.spawn_nail(crab,Vector2(300,300))
	victim.position = Vector2(300,300)
	nail.mode = "return"
	var hp := victim.health
	nail.advance(0.01,a)
	var first := victim.health
	check(first < hp, "moving nail hits")
	nail.advance(0.01,a)
	check(victim.health == first, "nail cooldown prevents immediate second hit")
	a.free()

func puffer_targets() -> void:
	var a := battle([0,9])
	var p: Puffer = a.heroes[0]
	var crow: Crow = a.heroes[1]
	crow.dummy_timer = 0
	crow.advance(0.01)
	var dummy: Scarecrow = crow.dummies[0]
	p.action = "burst"
	p.gas = 100
	var first := dummy.health
	var second := crow.health
	p._on_contact(dummy)
	p._on_contact(crow)
	check(dummy.health == first - 36 and crow.health == second - 36, "both separate targets take damage")
	p._on_contact(dummy)
	p._on_contact(crow)
	check(dummy.health == first - 36 and crow.health == second - 36, "same targets protected during cooldown")
	a.free()

func sheep_wool() -> void:
	var a := battle([3,0])
	var sheep: ElectricSheep = a.heroes[0]
	var enemy: Fighter = a.heroes[1]
	sheep.position = Vector2(200,200)
	enemy.position = Vector2(250,200)
	sheep.wool_active = true
	sheep.wool_position = sheep.position
	sheep.charge = 100
	var hp := enemy.health
	sheep.discharge(1)
	check(is_equal_approx(enemy.health,hp-20) and is_equal_approx(sheep.charge,75), "one hit and one charge drain")
	a.free()

func egg_fuse() -> void:
	var a := battle([1,0])
	var chicken: Chicken = a.heroes[0]
	var enemy: Fighter = a.heroes[1]
	a.spawn_egg(enemy.position,chicken,false)
	var egg: BombEgg = a.eggs[0]
	var hp := enemy.health
	egg.advance(0.01,a.balls)
	check(egg.armed and enemy.health == hp, "touch starts fuse without damage")
	egg.advance(0.79,a.balls)
	check(enemy.health == hp, "no damage before fuse ends")
	egg.advance(0.02,a.balls)
	check(egg.exploded and enemy.health == hp-24, "explodes after delay")
	a.free()

func rabbit_temper() -> void:
	var a := battle([6,0])
	var rabbit: ForgeRabbit = a.heroes[0]
	var enemy: Fighter = a.heroes[1]
	var hp := enemy.health
	rabbit.stored_damage = 20
	rabbit.temper_left = 1
	rabbit.contact(enemy)
	check(enemy.health == hp-30 and rabbit.stored_damage == 0 and rabbit.temper_left == 0, "1.5x strike consumes buff")
	rabbit.stored_damage = 10
	rabbit.contact(enemy)
	check(enemy.health == hp-40, "following strike not boosted")
	a.free()

func lightning_rod() -> void:
	var a := battle([5,0])
	var duck: UnluckyDuck = a.heroes[0]
	duck.rods.assign([duck.position])
	duck.cloud_holder = duck
	var hp := duck.health
	duck.strike()
	check(duck.health == hp and duck.rods.is_empty(), "one rod blocks one strike then disappears")
	duck.strike()
	check(duck.health == hp-32, "next strike damages without a rod")
	a.free()
