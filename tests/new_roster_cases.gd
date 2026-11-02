extends RefCounted
var host
func ck(ok: bool, label: String) -> void:
	host.check(ok, "N " + label)
func arena(pair: Array) -> BattleArena:
	var a := BattleArena.new()
	a.setup(123,pair)
	for f in a.balls:
		f.cd_one = 999
		f.cd_two = 999
	return a
func snapshot(a: BattleArena) -> Array:
	var result: Array = [a.match_seed,a.roster.duplicate(),a.simulation_time,a.finished,a.result,a.spawn_rng.state]
	for f in a.balls:
		result.append_array([f.title,f.position,f.velocity,f.health,f.cd_one,f.cd_two,f.action,f.action_left,f.rng.state,f.stored_velocity])
		if f is Puffer:
			result.append_array([f.gas,f.immune_left,f.impact_cooldown,f.burst_base_speed])
		elif f is Chicken:
			result.append_array([f.egg_timer,f.turn_timer,f.run_base_speed])
		elif f is BubbleFish:
			result.append(f.bubble_timer)
		elif f is ElectricSheep:
			result.append_array([f.charge,f.wool_active,f.wool_position,f.zapping])
		elif f is MagnetCrab:
			result.append_array([f.nail_timer,f.repel_ready,f.magnetic_wall,f.wall_flash])
	for b in a.bubbles:
		result.append_array([b.position,b.velocity,b.level,b.launch_left,b.absorb_left,b.turn_left,b.rng.state])
	for n in a.nails:
		result.append_array([n.position,n.mode,n.target,n.velocity,n.outward_left,n.hit_left])
	for e in a.eggs:
		result.append_array([e.position,e.armed,e.fuse,e.age,e.exploded,e.blast_left])
	return result
func run(runner) -> void:
	host = runner
	var seen := {}
	for seed_value in 100:
		var a := BattleArena.new()
		var b := BattleArena.new()
		a.setup(seed_value)
		b.setup(seed_value)
		ck(a.roster.size() == 2 and a.roster[0] != a.roster[1], "distinct random heroes")
		seen[a.roster[0]] = true
		seen[a.roster[1]] = true
		ck(snapshot(a) == snapshot(b), "seed repeats initial full state")
		for i in 360:
			a.step(1.0/120)
			b.step(1.0/120)
		ck(snapshot(a) == snapshot(b), "seed repeats gameplay RNG")
		a.free()
		b.free()
	ck(seen.size() == 5,"all five available")

	var a := arena([2,1])
	var fish: BubbleFish = a.balls[0]
	var enemy: Fighter = a.balls[1]
	fish.position = Vector2(100,100)
	enemy.position = Vector2(600,500)
	var b := a.spawn_bubble(fish,enemy.position,Vector2.ZERO)
	var hp := enemy.health
	a.step_bubbles(1.0/120)
	ck(a.bubbles.is_empty() and enemy.health == hp,"level1 pops without damage")
	a.spawn_bubble(fish,Vector2(300,300),Vector2.ZERO)
	a.spawn_bubble(fish,Vector2(300,300),Vector2.ZERO)
	a.step_bubbles(1.0/120)
	ck(a.bubbles.size() == 1 and a.bubbles[0].level == 2,"1+1=2")
	b = a.spawn_bubble(fish,a.bubbles[0].position,Vector2.ZERO)
	b.level = 2
	a.step_bubbles(1.0/120)
	ck(a.bubbles.size() == 1 and a.bubbles[0].level == 4,"2+2=4")
	b = a.spawn_bubble(fish,a.bubbles[0].position,Vector2.ZERO)
	b.level = 1000000
	a.step_bubbles(1.0/120)
	ck(a.bubbles[0].level == 1000004,"unequal levels add with no gameplay cap")
	a.bubbles[0].position = enemy.position
	a.step_bubbles(1.0/120)
	ck(enemy.health == 0 and a.bubbles.is_empty(),"merged bubble deals damage and pops")
	enemy.health = 120
	b = a.spawn_bubble(fish,Vector2(300,300),Vector2(150,0),0.1)
	b.advance(0.1,a.arena_size)
	ck(b.launch_left == 0,"launch expires")
	var old := b.position
	b.advance(0.1,a.arena_size)
	ck(b.position != old and is_equal_approx(b.velocity.length(),22),"after launch random slow drift")
	for bubble in a.bubbles:
		bubble.free()
	a.bubbles.clear()
	var sink := a.spawn_bubble(fish,Vector2(300,300),Vector2(100,0),2.5,2.5)
	var other := a.spawn_bubble(fish,Vector2(300,380),Vector2.ZERO)
	var distance := sink.position.distance_to(other.position)
	a.step_bubbles(0.1)
	ck(sink.position.x == 310 and sink.position.y == 300,"vacuum straight launch")
	ck(sink.position.distance_to(other.position) < distance,"vacuum attracts nearby bubble")
	other.position = sink.position
	a.step_bubbles(0.001)
	ck(a.bubbles.size() == 1 and a.bubbles[0] == sink and sink.level == 2 and sink.absorb_left > 0,"vacuum survives merge")
	for bubble in a.bubbles:
		bubble.free()
	a.bubbles.clear()
	fish.bubble_timer = 999
	fish.cd_two = 0
	fish.advance(0.01)
	ck(a.bubbles.size() == 8,"eight directions spawn eight")
	for bubble in a.bubbles:
		ck(bubble.level == 1 and bubble.launch_left > 0,"eight launch initially harmless")
	a.step_bubbles(0.01)
	ck(a.bubbles.size() == 8,"eight launches do not instantly self merge")
	a.free()

	a = arena([3,1])
	var sheep: ElectricSheep = a.balls[0]
	enemy = a.balls[1]
	sheep.position = Vector2(300,300)
	enemy.position = Vector2(350,300)
	hp = enemy.health
	sheep.discharge(0.1)
	ck(enemy.health == hp,"no charge no damage")
	sheep._wall_charge(Vector2.LEFT)
	ck(sheep.charge == 30,"wall recharges")
	sheep.discharge(0.1)
	ck(is_equal_approx(enemy.health,hp-2) and sheep.charge == 27.5,"continuous per dt discharge")
	sheep.wool_active = true
	sheep.wool_position = sheep.position
	hp = enemy.health
	sheep.discharge(0.1)
	ck(is_equal_approx(enemy.health,hp-2),"body+wool no double damage")
	sheep.position = Vector2(100,100)
	hp = enemy.health
	sheep.discharge(0.1)
	ck(is_equal_approx(enemy.health,hp-2),"remote wool conducts")
	enemy.position = Vector2(650,550)
	var charge := sheep.charge
	sheep.discharge(1)
	ck(sheep.charge == charge,"no target conserves charge")
	enemy.position = sheep.position
	sheep.charge = 1
	hp = enemy.health
	sheep.discharge(1)
	ck(sheep.charge == 0 and is_equal_approx(hp-enemy.health,0.8),"partial last charge scales damage")
	sheep.position = Vector2(30,300)
	sheep.cd_one = 0
	sheep.advance(0.01)
	ck(sheep.velocity.x < 0 and sheep.velocity.y == 0,"turn to nearest wall")
	sheep.cd_two = 0
	sheep.advance(0.01)
	old = sheep.wool_position
	sheep.position += Vector2(80,0)
	sheep.cd_two = 0
	sheep.advance(0.01)
	ck(sheep.wool_active and sheep.wool_position == sheep.position and sheep.wool_position != old,"one wool replaces previous")
	a.free()

	a = arena([4,1])
	var crab: MagnetCrab = a.balls[0]
	enemy = a.balls[1]
	crab.position = Vector2(300,300)
	enemy.position = Vector2(400,300)
	var nail := a.spawn_nail(crab,enemy.position)
	hp = enemy.health
	nail.advance(10,a)
	ck(nail.mode == "rest" and nail.position == enemy.position and enemy.health == hp,"rest nail harmless never autoreturns")
	crab.magnetize(0)
	nail.advance(0.1,a)
	ck(nail.mode == "wall" and nail.position.x < 400 and enemy.health < hp,"moving nail damages")
	nail.position = Vector2(6,300)
	nail.advance(0.01,a)
	ck(nail.mode == "return" and nail.position.x == 5,"touch wall then return")
	crab.repel_ready = true
	nail.position = crab.position + Vector2(1,0)
	nail.advance(0.01,a)
	ck(nail.mode == "out" and not crab.repel_ready and not nail.gone,"next returned nail repelled once")
	nail.advance(1,a)
	ck(nail.mode == "rest" and not nail.gone,"repelled nail rests again")
	old = nail.position
	nail.advance(10,a)
	ck(nail.position == old,"repelled nail waits for next magnet")
	crab.magnetize(1)
	ck(nail.mode == "wall","can magnetize repelled nail again")
	nail.mode = "return"
	nail.position = crab.position
	nail.advance(0.01,a)
	ck(nail.gone,"ordinary return collected")
	a.free()

	# Every matchup both reproducible and finite over a complete match.
	for first in 5:
		for second in range(first+1,5):
			a = arena([first,second])
			for f in a.balls:
				f.cd_one = 0
				f.cd_two = 0
			for i in 10802:
				a.step(1.0/120)
				if a.finished:
					break
			ck(a.finished and a.event_limit_hits == 0,"all ten pairings complete")
			for f in a.balls:
				ck(f.position.is_finite() and f.health >= 0,"finite matchup state")
			a.free()

	# Every pair: complete new-mechanic state freezes and scales together.
	for first in 5:
		for second in range(first+1,5):
			var reference: Array = []
			for speed in [1,2,3]:
				var controller = load("res://scenes/main.tscn").instantiate()
				host.root.add_child(controller)
				controller.set_process(false)
				controller.arena.free()
				controller.arena = BattleArena.new()
				controller.arena.setup(987,[first,second])
				controller.add_child(controller.arena)
				controller.set_rate(speed)
				for i in int(360/speed):
					controller.advance_real_time(1.0/60)
				var current := snapshot(controller.arena)
				if reference.is_empty():
					reference = current
				ck(current == reference,"all pair full-state speed equivalence")
				controller.set_rate(0)
				controller.advance_real_time(10)
				ck(snapshot(controller.arena) == current,"all pair pause freezes projectiles/electricity")
				var old_ids: Array[int] = [controller.arena.get_instance_id()]
				for child in controller.arena.get_children():
					old_ids.append(child.get_instance_id())
				controller.buttons[4].pressed.emit()
				await host.process_frame
				await host.process_frame
				for id in old_ids:
					ck(not is_instance_id_valid(id),"all pair restart frees projectiles and heroes")
				controller.free()

	var main = load("res://scenes/main.tscn").instantiate()
	host.root.add_child(main)
	main.set_process(false)
	main.match_seed = 12345
	main.restart_battle(true)
	main.set_rate(1)
	for i in 180:
		main.advance_real_time(1.0/60)
	var expected := snapshot(main.arena)
	main.buttons[5].pressed.emit()
	ck(main.match_seed == 12345 and main.arena.simulation_time == 0,"same seed replay button")
	main.set_rate(3)
	for i in 60:
		main.advance_real_time(1.0/60)
	ck(snapshot(main.arena) == expected,"replay same outcome at different speed")
	var previous_arena: int = main.arena.get_instance_id()
	main.buttons[4].pressed.emit()
	ck(main.arena.simulation_time == 0 and main.arena.roster[0] != main.arena.roster[1],"new random game button")
	await host.process_frame
	await host.process_frame
	ck(not is_instance_id_valid(previous_arena),"random restart releases world/projectiles")
	main.free()
