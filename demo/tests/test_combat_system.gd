extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
func make_arena(health: float = 100.0) -> Arena:
	var config := BallConfig.new()
	config.max_health = health
	config.radius = 10
	config.impact_skill = ImpactSkillConfig.new()
	var created := BallFactory.create_demo([config, config], Vector2(1000, 1000), 42)
	var arena := Arena.new()
	arena.arena_size = Vector2(1000, 1000)
	for ball in created.balls:
		arena.register_ball(ball)
	arena.balls[0].position = Vector2(400, 500)
	arena.balls[1].position = Vector2(440, 500)
	arena.balls[0].velocity = Vector2(200, 0)
	arena.balls[1].velocity = Vector2(-200, 0)
	return arena
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var system := CombatSystem.new()
	var arena := make_arena()
	var a := arena.balls[0]
	var b := arena.balls[1]
	var predicted := arena._next_event(0.1)
	var seed: CollisionEvent = predicted.contacts[0]
	check(not seed.confirmed and seed.ball_a == a and seed.ball_b == b, "prediction uses shared typed event")
	a.position += a.velocity * predicted.time
	b.position += b.velocity * predicted.time
	var completed := arena._contacts_at_event(predicted.contacts)
	check(is_same(seed, completed[0]), "contact completion reuses prediction object")
	seed.confirmed = true
	var candidate := system.resolve(completed)
	check(candidate.error.is_empty() and candidate.health[a] == 90 and candidate.health[b] == 90, "both candidates use pre-impact speeds")
	check(a.current_health == 100 and b.current_health == 100 and a.velocity.x == 200, "calculation does not commit")
	arena.combat_resolver = system.resolve
	arena.ball_collided.connect(func(_items): check(a.current_health == 90 and b.current_health == 90 and a.velocity.x < 0, "notification sees complete batch"))
	check(arena.step(0.01), "batch succeeds")
	check(a.current_health == 90 and b.current_health == 90, "both health values committed once")
	check(arena.step(0.01) and a.current_health == 90, "separating contact does not repeat damage")
	arena.free()
	arena = make_arena(5)
	a = arena.balls[0]
	b = arena.balls[1]
	arena.combat_resolver = system.resolve
	check(arena.step(0.2), "mutual death completes remaining timestep")
	check(a.current_health == 0 and b.current_health == 0 and arena.balls.is_empty(), "simultaneous mutual death removes both")
	check(is_equal_approx(arena.simulation_time, 0.2), "empty arena advances remaining time")
	arena.free()
	arena = make_arena()
	a = arena.balls[0]
	b = arena.balls[1]
	arena.combat_resolver = func(_events):
		var result := CombatResult.new()
		result.health[a] = NAN
		return result
	var notifications: Array = []
	arena.ball_collided.connect(func(items): notifications.append(items))
	print("EXPECTED ERROR: rejected combat batch")
	check(not arena.step(0.1), "invalid combat candidate fails step")
	check(a.velocity.x == 200 and b.velocity.x == -200 and a.current_health == 100 and b.current_health == 100, "failure commits neither velocities nor health")
	check(notifications.is_empty() and arena.combat_failures == 1, "failure emits no success notification")
	arena.free()
	arena = make_arena()
	a = arena.balls[0]
	b = arena.balls[1]
	check(arena.step(0.1) and a.current_health == 100 and a.velocity.x < 0, "no callback preserves pure physics")
	arena.free()
	# 同刻多对接触汇总不依赖输入顺序。
	arena = make_arena()
	a = arena.balls[0]
	b = arena.balls[1]
	var c := Ball.new()
	c.max_health = 100
	c.current_health = 100
	c.position = Vector2(500, 500)
	arena.register_ball(c)
	var ab := CollisionEvent.create(arena.balls, 0, 1, 0.0, Vector2.LEFT)
	ab.confirmed = true
	ab.velocity_a_before = Vector2(200, 0)
	var ac := CollisionEvent.create(arena.balls, 0, 2, 0.0, Vector2.LEFT)
	ac.confirmed = true
	ac.velocity_a_before = Vector2(200, 0)
	check(system.resolve([ab, ac]).health == system.resolve([ac, ab]).health, "batch ordering independent")
	ab.confirmed = false
	check(system.resolve([ab]).health.is_empty(), "unconfirmed events ignored")
	var wall := CollisionEvent.create(arena.balls, 0, -1, 0.0, Vector2.RIGHT)
	wall.confirmed = true
	check(system.resolve([wall]).health.is_empty(), "walls do not deal damage")
	arena.free()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.select_scenario(2, 42)
	main.current_scenario.arena.balls[0].current_health = 1
	main.restart_scenario()
	check(main.current_scenario.arena.balls[0].current_health == 100, "restart restores configured full health")
	main.select_scenario(100, 42)
	main.current_scenario.set_process(false)
	for tick in 120:
		check(main.current_scenario.arena.step(1.0 / 120.0), "dense combat advances safely")
	for ball in main.current_scenario.arena.balls:
		check(ball.current_health > 0 and ball.current_health <= ball.max_health, "only living valid balls remain")
	main.free()
	print("COMBAT RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
