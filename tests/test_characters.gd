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
	a.setup(seed_value)
	return a

func snapshot(a: BattleArena) -> Array:
	var data: Array = [a.simulation_time, a.finished, a.eggs.size()]
	for f in a.balls:
		data.append_array([f.position, f.velocity, f.health, f.cd_one, f.cd_two, f.action])
	for egg in a.eggs:
		data.append_array([egg.position, egg.fuse, egg.age, egg.exploded])
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
		root.add_child(main)
		main.set_process(false)
		main.arena.free()
		main.arena = battle(81)
		main.add_child(main.arena)
		check(main.rate == 0 and main.selected_rate == 1 and main.buttons.size() == 4, "C26 paused default1x and four controls")
		main.set_rate(shown_rate)
		for i in (360 / shown_rate):
			main.advance_real_time(1.0 / 60)
		check(absf(main.arena.simulation_time - 12) < 0.00001, "C27 base time doubled")
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
		main.free()
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
