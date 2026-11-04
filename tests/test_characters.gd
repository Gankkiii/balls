extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ROLE: ", label)

func _initialize() -> void:
	call_deferred("run")

func battle(seed_value: int = 42) -> BattleArena:
	var a := BattleArena.new()
	a.setup(seed_value, [0,1])
	return a

func snapshot(a: BattleArena) -> Array:
	var data: Array = [a.simulation_time, a.finished, a.result, a.eggs.size()]
	for f in a.balls:
		data.append_array([f.position, f.velocity, f.health, f.cd_one, f.cd_two, f.action, f.action_left, f.stored_velocity, f.rng.state])
		if f is Puffer:
			data.append_array([f.gas, f.immune_left, f.impact_cooldown, f.burst_base_speed, f.visual_radius()])
			var independent_cooldowns: Array = []
			for target in a.balls:
				if f.impact_cooldowns.has(target): independent_cooldowns.append([a.balls.find(target), f.impact_cooldowns[target]])
			data.append(independent_cooldowns)
		else:
			data.append_array([f.egg_timer, f.turn_timer, f.run_base_speed])
	for egg in a.eggs:
		data.append_array([egg.position, egg.fuse, egg.age, egg.exploded, egg.armed, egg.large, egg.blast_left, a.balls.find(egg.owner_fighter)])
	return data

func run() -> void:
	var p := Puffer.new()
	var c := Chicken.new()
	p.velocity = Vector2(180, 0)
	p.cd_one = 10
	p.cd_two = 10
	p.gas = 99
	p.advance(0.1)
	check(p.action == "idle", "C01 below full gas does not trigger")
	p.gas = 100
	p.advance(0.01)
	check(p.action == "burst" and p.velocity.length() > 180, "C02 full gas triggers boosted burst")
	var hp := c.health
	p._on_contact(c)
	check(c.health == hp - Puffer.HIT_DAMAGE, "C03 burst collision damage")
	p._on_contact(c)
	check(c.health == hp - Puffer.HIT_DAMAGE, "C04 collision cooldown")
	p.action = "idle"
	p.impact_cooldown = 0
	hp = c.health
	p._on_contact(c)
	check(c.health == hp, "C05 normal contact harmless")
	p.gas = 0
	p.cd_one = 0
	p.cd_two = 9
	p.advance(0.01)
	check(p.action == "inflate" and p.velocity == Vector2.ZERO, "C06 automatic stationary inflate")
	for i in 301:
		p.advance(1.0 / 120)
	check(p.action == "burst", "C07 inflation fills and releases automatically")
	p.cd_one = 99
	p.cd_two = 99
	for i in 500:
		p.advance(1.0 / 120)
	check(p.gas == 0 and p.action == "idle", "C08 deflate to empty ends")
	p.cd_two = 0
	p.advance(0.01)
	hp = p.health
	p.hit(20)
	check(p.health == hp and p.gas > 0 and p.immune_left > 0, "C09 absorb immunity converts attack to gas")
	for i in 301:
		p.advance(1.0 / 120)
	p.hit(10)
	check(p.health == hp - 10, "C10 immunity expires")
	p.gas = 0
	check(is_equal_approx(p.visual_radius(), p.radius), "C34 empty original size")
	p.gas = 100
	check(is_equal_approx(p.visual_radius(), p.radius * 2), "C35 full double diameter")
	p.action = "burst"
	p.cd_one = 99
	p.cd_two = 99
	var full_size := p.visual_radius()
	p.advance(1)
	check(p.visual_radius() < full_size and p.visual_radius() > p.radius, "C36 gradual deflation shrink")
	p.advance(3)
	check(is_equal_approx(p.visual_radius(), p.radius), "C37 deflated original size")
	p.free()
	c.free()

	var a := battle()
	p = a.balls[0]
	c = a.balls[1]
	p.cd_one = 99
	p.cd_two = 99
	c.cd_one = 99
	c.cd_two = 99
	p.position = Vector2(300, 300)
	c.position = Vector2(600, 500)
	a.spawn_egg(p.position, c, false)
	var egg := a.eggs[0]
	hp = p.health
	egg.advance(0.01, a.balls)
	check(egg.armed and is_equal_approx(egg.fuse, 0.8) and p.health == hp, "C11 enemy step arms without instant damage")
	egg.advance(0.7, a.balls)
	check(not egg.exploded and p.health == hp, "C12 small egg waits")
	egg.advance(0.11, a.balls)
	check(egg.exploded and p.health == hp - egg.damage, "C13 delayed in-radius explosion")
	egg.explode(a.balls)
	check(p.health == hp - egg.damage, "C14 explosion cannot repeat damage")
	a.spawn_egg(p.position, c, false)
	egg = a.eggs.back()
	egg.advance(0.01, a.balls)
	p.position = Vector2(100, 100)
	hp = p.health
	egg.advance(1, a.balls)
	check(p.health == hp, "C15 can escape blast radius")
	a.spawn_egg(c.position, c, false)
	egg = a.eggs.back()
	egg.advance(0.1, a.balls)
	check(not egg.armed, "C16 owner does not trigger small egg")
	a.spawn_egg(c.position, c, true)
	egg = a.eggs.back()
	hp = c.health
	egg.advance(1.49, a.balls)
	check(not egg.exploded, "C17 big egg waits 1.5 seconds")
	egg.advance(0.02, a.balls)
	check(absf(c.health - (hp - 62 * 0.2)) < 0.001, "C18 self blast reduced to20percent")
	c.cd_one = 0
	c.advance(0.01)
	check(c.action == "run", "C19 panic auto starts")
	var previous := c.velocity
	c.advance(0.19)
	check(c.velocity != previous, "C20 panic changes random direction")
	c.action = "idle"
	c.cd_one = 99
	c.cd_two = 0
	c.egg_timer = 99
	var egg_count := a.eggs.size()
	c.advance(0.01)
	check(c.action == "lay" and c.velocity == Vector2.ZERO, "C21 big egg stationary crouch")
	c.advance(2.99)
	check(a.eggs.size() == egg_count, "C22 not before3seconds")
	c.advance(0.011)
	check(a.eggs.size() == egg_count + 1 and a.eggs.back().large, "C23 lay big egg after3seconds")
	# Ready second skill waits during uninterruptible lay, then starts automatically.
	c.begin_stationary("lay")
	c.action_left = 1
	c.cd_one = 0
	c.cd_two = 99
	c.advance(0.5)
	check(c.action == "lay" and c.cd_one == 0, "C24 ready skill queued")
	c.advance(0.51)
	check(c.action == "run", "C25 queued skill starts on finish")
	a.free()

	# Real main controller: all battle timers, positions, HP, RNG/egg states must match.
	var reference: Array = []
	for shown_rate in [1, 2, 3]:
		var main = load("res://scenes/main.tscn").instantiate()
		main.page_save_path_override = "user://readonly_test_%d_%d.jsonl" % [OS.get_process_id(), Time.get_ticks_usec()]
		root.add_child(main)
		main.set_process(false)
		main.arena.free()
		main.match_seed = legacy_seed()
		main.arena = BattleArena.new()
		main.arena.setup(main.match_seed)
		main.add_child(main.arena)
		check(main.rate == 0 and main.selected_rate == 1 and main.buttons.size() == 6, "C26 paused default1x and six controls")
		main.set_rate(shown_rate)
		for i in (360 / shown_rate):
			main.advance_real_time(1.0 / 60)
		check(absf(main.arena.simulation_time - 6) < 0.00001, "C27 original base speed restored")
		var current := snapshot(main.arena)
		if reference.is_empty():
			reference = current
		else:
			check(current == reference, "C28 displayed1x2x3x whole simulation equivalent")
		main.set_rate(0)
		main.advance_real_time(10)
		check(snapshot(main.arena) == current, "C29 pause freezes skills and eggs")
		main.refresh_hud()
		check(main.cards[0].text.contains("INFLATE") and main.cards[1].text.contains("BIG EGG"), "C30 HUD names and cooldown content")
		main.arena.finished = true
		main.arena.result = "TEST WIN"
		main.arena.balls[0].health = 1
		main.accumulator = 0.004
		main.buttons[5].pressed.emit()
		check(not main.arena.finished and main.arena.result == "" and main.arena.simulation_time == 0, "C38 restart clears outcome/time")
		check(main.arena.eggs.is_empty() and main.arena.balls.size() == 2 and main.arena.balls[0].health == 120, "C39 restart fresh fighters/eggs")
		check(main.rate == shown_rate and main.accumulator == 0, "C40 restart runs selected speed")
		for j in 5:
			main.buttons[5].pressed.emit()
		check(main.arena.balls.size() == 2 and main.arena.get_parent() == main, "C41 repeated restart remains valid")
		main.advance_real_time(0.1)
		check(main.arena.simulation_time > 0, "C42 restarted match advances")
		main.free()
	load("res://tests/page_cases.gd").new().run(self)
	load("res://tests/hatching_cases.gd").new().run(self)
	load("res://tests/gameplay_cases.gd").new().run(self)
	await extended_checks()
	await load("res://tests/new_roster_cases.gd").new().run(self)
	load("res://tests/hud_physics_cases.gd").new().run(self)
	load("res://tests/v04_cases.gd").new().run(self)
	var wins := {}
	for seed_value in 20:
		a = battle(seed_value)
		for i in 10802:
			a.step(1.0 / 120)
			if a.finished:
				break
		check(a.finished and a.event_limit_hits == 0, "C31 bounded match seed%d" % seed_value)
		check(a.eggs.size() <= 32, "C32 egg cap")
		for f in a.balls:
			check(f.position.is_finite() and f.health >= 0, "C33 valid fighter")
		wins[a.result] = int(wins.get(a.result, 0)) + 1
		a.free()
	print("ROLE RESULT checks=%d failures=%d outcomes=%s" % [checks, failures, wins])
	quit(1 if failures else 0)

func new_main():
	var main = load("res://scenes/main.tscn").instantiate()
	main.page_save_path_override = "user://readonly_test_%d_%d.jsonl" % [OS.get_process_id(), Time.get_ticks_usec()]
	root.add_child(main)
	main.set_process(false)
	main.arena.free()
	main.match_seed = legacy_seed()
	main.arena = BattleArena.new()
	main.arena.setup(main.match_seed)
	main.add_child(main.arena)
	return main

func extended_checks() -> void:
	var p := Puffer.new()
	for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
		p.gas = fraction * Puffer.GAS_MAX
		check(is_equal_approx(p.visual_radius(), p.radius * (1 + fraction)), "C43 quarter gas sizes")
	p.gas = 0
	p.cd_one = 99
	p.cd_two = 99
	p.begin_stationary("inflate")
	var previous_size := p.visual_radius()
	for tick in 300:
		p.advance(1.0 / 120)
		check(p.visual_radius() >= previous_size and p.visual_radius() <= p.radius * 2, "C44 continuous growth")
		previous_size = p.visual_radius()
	p.gas = 100
	p.start_burst()
	previous_size = p.visual_radius()
	for tick in 480:
		p.advance(1.0 / 120)
		check(p.visual_radius() <= previous_size and p.visual_radius() >= p.radius, "C45 continuous shrink")
		previous_size = p.visual_radius()
	p.gas = 0
	p.action = "immune"
	p.immune_left = 2
	p.hit(20)
	check(is_equal_approx(p.gas, 36) and is_equal_approx(p.visual_radius(), p.radius * 1.36), "C46 hit absorption expands immediately")
	p.hit(100)
	check(p.gas == 100 and p.action == "burst" and p.visual_radius() == p.radius * 2, "C47 absorption clamps and bursts")
	check(p.radius == 24, "C48 art scaling leaves physical radius unchanged")
	p.free()

	for mode in ["running", "paused", "inflate", "burst", "lay", "finished"]:
		var main = new_main()
		main.set_rate(3)
		main.advance_real_time(0.1)
		p = main.arena.balls[0]
		var c: Chicken = main.arena.balls[1]
		p.health = 17
		c.health = 23
		p.gas = 72
		p.immune_left = 1.2
		p.impact_cooldown = 0.2
		p.cd_one = 5
		c.cd_two = 8
		if mode == "paused":
			main.set_rate(0)
		elif mode == "inflate":
			p.begin_stationary("inflate")
		elif mode == "burst":
			p.start_burst()
		elif mode == "lay":
			c.begin_stationary("lay")
			c.action_left = 2
		elif mode == "finished":
			main.arena.finished = true
			main.arena.result = "TEST"
		main.arena.spawn_egg(p.position, c, true)
		var old_ids: Array[int] = [main.arena.get_instance_id(), p.get_instance_id(), c.get_instance_id(), main.arena.eggs[0].get_instance_id()]
		main.buttons[5].pressed.emit()
		var fresh := battle(1)
		for i in 2:
			var actual: Fighter = main.arena.balls[i]
			var expected: Fighter = fresh.balls[i]
			check(actual.health == expected.health and actual.cd_one == expected.cd_one and actual.cd_two == expected.cd_two and actual.action == expected.action and actual.action_left == expected.action_left and actual.stored_velocity == expected.stored_velocity, "C49 all shared state reset " + mode)
		p = main.arena.balls[0]
		c = main.arena.balls[1]
		check(p.gas == 0 and p.immune_left == 0 and p.impact_cooldown == 0 and p.visual_radius() == p.radius and p.burst_base_speed == 180, "C50 puffer reset " + mode)
		check(c.egg_timer == 0.6 and c.turn_timer == 0 and c.run_base_speed == 180, "C51 chicken reset " + mode)
		check(main.arena.simulation_time == 0 and not main.arena.finished and main.arena.result == "" and main.arena.eggs.is_empty() and main.rate == 3 and main.accumulator == 0, "C52 arena reset " + mode)
		fresh.free()
		await process_frame
		await process_frame
		for id in old_ids:
			check(not is_instance_id_valid(id), "C53 old nodes truly freed " + mode)
		for i in 20:
			old_ids.append(main.arena.get_instance_id())
			main.buttons[5].pressed.emit()
		await process_frame
		await process_frame
		for id in old_ids:
			check(not is_instance_id_valid(id), "C54 repeated restart no leaked arenas")
		var arena_count := 0
		for node in main.get_children():
			if node is BattleArena:
				arena_count += 1
		check(arena_count == 1, "C55 single arena in live scene")
		main.advance_real_time(1.0 / 60)
		check(absf(main.arena.simulation_time - 0.05) < 1e-9, "C56 single update after restarts")
		main.free()

	var reference: Array = []
	for fps in [10, 30, 60, 144]:
		for speed in [1, 2, 3]:
			var main = new_main()
			main.buttons[speed - 1].pressed.emit()
			check(main.rate == speed, "C57 actual speed buttons")
			for i in int(6 * fps / speed):
				main.advance_real_time(1.0 / fps)
			var current := snapshot(main.arena)
			if reference.is_empty():
				reference = current
			check(current == reference, "C58 complete state equivalent across rates/fps")
			main.buttons[3].pressed.emit()
			main.advance_real_time(1000)
			check(snapshot(main.arena) == current, "C59 paused entire state")
			main.buttons[speed - 1].pressed.emit()
			for notifications in [[MainLoop.NOTIFICATION_APPLICATION_PAUSED, MainLoop.NOTIFICATION_APPLICATION_RESUMED], [MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN]]:
				current = snapshot(main.arena)
				main._notification(notifications[0])
				main.advance_real_time(1000)
				check(snapshot(main.arena) == current and main.accumulator == 0, "C60 background freezes all state")
				main._notification(notifications[1])
				check(snapshot(main.arena) == current, "C61 return has no immediate jump")
				main.advance_real_time(1.0 / 120)
				check(absf(main.arena.simulation_time - float(current[0]) - speed / 120.0) < 1e-9, "C62 return only consumes new time")
			var before: float = main.arena.simulation_time
			main.advance_real_time(1000)
			check(absf(main.arena.simulation_time - before - speed * 0.1) < 1e-9, "C63 long frame capped at every rate")
			main.free()

func legacy_seed() -> int:
	for seed_value in 1000:
		var a := BattleArena.new()
		a.setup(seed_value)
		var correct := a.roster == [0,1]
		a.free()
		if correct:
			return seed_value
	assert(false, "No legacy pair seed found")
	return 0
