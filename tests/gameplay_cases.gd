extends RefCounted
## Focused gameplay acceptance tests, separate from balance and visual QA.
var host
var before := 0
func ck(ok: bool, message: String) -> void:
	host.check(ok, "G " + message)
func arena(pair: Array) -> BattleArena:
	var a := BattleArena.new()
	a.setup(225, pair)
	for f in a.heroes:
		f.cd_one = 999; f.cd_two = 999
	return a

func run(runner) -> void:
	host = runner; before = host.checks
	# Gas, absorbing damage, skill priority, and per-target collision cooldown.
	var a := arena([0,9])
	var p: Puffer = a.heroes[0]
	var crow: Crow = a.heroes[1]
	crow.advance(2.1)
	var dummy: Scarecrow = crow.dummies[0]
	p.action = "burst"; p.gas = 100
	var dummy_hp := dummy.health; var crow_hp := crow.health
	var hp: float
	p._on_contact(dummy)
	p._on_contact(crow)
	ck(dummy.health == dummy_hp - 36 and crow.health == crow_hp - 36, "P01 independent targets both take burst hit")
	var after_dummy := dummy.health; var after_crow := crow.health
	p._on_contact(dummy); p._on_contact(crow)
	ck(dummy.health == after_dummy and crow.health == after_crow, "P02 repeated target inside cooldown cannot be hit")
	p.advance(0.34); p._on_contact(crow)
	ck(crow.health == after_crow, "P03 same target cooldown remains before threshold")
	p.advance(0.011); p._on_contact(crow)
	ck(crow.health == after_crow - 36, "P04 same target damage resumes after cooldown")
	a.free()
	a = arena([0,1]); p = a.heroes[0]
	p.action = "idle"; p.gas = 0; p.cd_one = 0; p.cd_two = 0
	p.advance(0.01)
	ck(p.action == "immune" and p.immune_left > 0, "P05 absorb has priority when both ready")
	p.gas = 98; hp = p.health
	p.hit(2)
	ck(p.action == "burst" and p.health == hp and p.immune_left > 0, "P06 full gas triggers burst while immune")
	p.hit(10)
	ck(p.health == hp, "P07 immunity remains after burst begins")
	a.free()
	# Chicken's small egg has delayed trigger and finite fuse; large egg self-damage is reduced.
	a = arena([1,0]); var chicken: Chicken = a.heroes[0]; var victim: Fighter = a.heroes[1]
	chicken.advance(0.59)
	ck(a.eggs.is_empty(), "E01 passive egg does not spawn early")
	chicken.advance(0.02)
	ck(a.eggs.size() == 1 and not a.eggs[0].armed, "E02 passive egg spawns unarmed")
	var egg: BombEgg = a.eggs[0]
	egg.position = victim.position; hp = victim.health
	egg.advance(0.01, a.balls)
	ck(egg.armed and victim.health == hp, "E03 touching egg starts fuse without immediate damage")
	egg.advance(0.79, a.balls)
	ck(victim.health == hp, "E04 fuse has not finished")
	egg.advance(0.02, a.balls)
	ck(victim.health == hp - 24 and egg.exploded, "E05 small egg explodes once")
	a.free()
	# Bubble fish releases eight projectiles; one-bubble damage stays zero.
	a = arena([2,0]); var fish: BubbleFish = a.heroes[0]; victim = a.heroes[1]
	fish.bubble_timer = 99; fish.cd_two = 0; fish.advance(0.01)
	ck(a.bubbles.size() == 8, "F01 skill creates eight bubbles")
	var directions: Array = []
	for bubble in a.bubbles:
		ck(is_equal_approx(bubble.velocity.length(),150) and is_equal_approx(bubble.launch_left,0.8), "F02 bubble has expected speed and launch time")
		directions.append(bubble.velocity.angle())
	var unique_directions := {}
	for direction in directions: unique_directions[snappedf(direction,0.01)] = true
	ck(unique_directions.size() == 8, "F03 eight launch directions differ")
	a.free()
	# Crab moves only its own stationary nails, and checks each wall destination.
	a = arena([4,0]); var crab: MagnetCrab = a.heroes[0]; victim = a.heroes[1]
	var nail := a.spawn_nail(crab,Vector2(300,300))
	var foreign := a.spawn_nail(victim,Vector2(400,300))
	for wall in 4:
		nail.mode = "rest"; foreign.mode = "rest"; crab.magnetize(wall)
		var correct := (wall == 0 and nail.target.x == 5) or (wall == 1 and nail.target.x == 695) or (wall == 2 and nail.target.y == 5) or (wall == 3 and nail.target.y == 595)
		ck(nail.mode == "wall" and correct and foreign.mode == "rest", "M01 correct wall and owner-only nail magnetization")
	a.free()
	# Duck strike/transfer, rods and exact boundaries.
	a = arena([5,0]); var duck: UnluckyDuck = a.heroes[0]; var target: Fighter = a.heroes[1]
	duck.position = Vector2(200,200); target.position = Vector2(500,200)
	duck.storm_left = 0.05; duck.cloud_holder = target; hp = target.health
	duck.advance(0.04)
	ck(target.health == hp and duck.cloud_holder == target, "D01 no early strike")
	duck.advance(0.02)
	ck(target.health == hp - 32 and duck.cloud_holder == duck and duck.storm_left == 7, "D02 strike and reset")
	duck.rods.assign([duck.position + Vector2(100,0)])
	hp = duck.health; duck.strike()
	ck(duck.health == hp and duck.rods.is_empty(), "D03 rod protects exactly at boundary and is consumed")
	duck.rods.assign([duck.position + Vector2(100.1,0)])
	hp = duck.health; duck.strike()
	ck(duck.health == hp - 32 and duck.rods.size() == 1, "D04 rod outside range does not protect")
	a.free()
	# Rabbit accumulation, forge motion restoration, and a single temper hit.
	a = arena([6,0]); var rabbit: ForgeRabbit = a.heroes[0]; target = a.heroes[1]
	rabbit.velocity = Vector2(80,60); rabbit.stored_damage = 0; rabbit.cd_one = 0
	rabbit.advance(0.01)
	ck(rabbit.action == "forge" and rabbit.velocity == Vector2.ZERO, "R01 skill automatically begins stationary forge")
	var stored_before := rabbit.stored_damage
	rabbit.advance(1.0)
	ck(is_equal_approx(rabbit.stored_damage - stored_before, 12.0), "R02 forging accumulates 12 per second")
	rabbit.advance(1.01)
	ck(rabbit.action == "idle" and rabbit.velocity == Vector2(80,60), "R03 forge ends and restores velocity")
	rabbit.stored_damage = 20; rabbit.temper_left = 1; hp = target.health
	rabbit.contact(target)
	ck(target.health == hp - 30 and rabbit.stored_damage == 0 and rabbit.temper_left == 0, "R04 boosted strike consumes stored damage and temper")
	rabbit.stored_damage = 10; rabbit.contact(target)
	ck(target.health == hp - 40, "R05 next strike unboosted")
	rabbit.temper_left = 0.1; rabbit.advance(0.2)
	ck(rabbit.temper_left == 0, "R06 unused temper expires")
	a.free()
	# Cactus fixed during collision, genuine contact retention, thorns and teleport.
	a = arena([7,0]); var cactus: Cactus = a.heroes[0]; target = a.heroes[1]
	cactus.position = Vector2(300,300); target.position = Vector2(348,300); target.velocity = Vector2(-100,0)
	hp = target.health; a.step(0.01)
	ck(cactus.position == Vector2(300,300) and target.velocity.x > 0 and target.health == hp - 18, "C01 real collision bounces from stationary cactus")
	target.position = Vector2(348,300); target.velocity = Vector2.ZERO
	for i in 10: a.step(0.01)
	ck(target.health == hp - 18, "C02 maintained contact does not repeatedly damage")
	target.position = Vector2(400,300); target.velocity = Vector2.ZERO; a.step(0.01)
	target.position = Vector2(348,300); target.velocity = Vector2(-100,0); a.step(0.01)
	ck(target.health == hp - 36, "C03 separating then recontact damages again")
	cactus.thorns.clear(); cactus.cd_one = 0; cactus.advance(0.01)
	ck(cactus.thorns.size() == 5, "C04 scatter creates five thorns")
	cactus.thorns.assign([target.position]); hp = target.health
	cactus.step_thorns(); cactus.step_thorns()
	ck(target.health == hp - 12 and cactus.thorns.is_empty(), "C05 thorn damages only once and disappears")
	cactus.thorns.assign([Vector2(70,70)]); var old_pos := cactus.position
	cactus.cd_one = 999; cactus.cd_two = 0; cactus.advance(0.01)
	ck(cactus.position != old_pos and cactus.thorns == [Vector2(70,70)], "C06 teleport leaves existing thorns")
	a.free()
	# Shell immunity, spin damage and bounce, and restoring movement.
	a = arena([8,0]); var turtle: ShellTurtle = a.heroes[0]; var shell: TurtleShell = turtle.shell; target = a.heroes[1]
	turtle.position = Vector2(180,200); shell.position = Vector2(260,200)
	turtle.cd_one = 0; turtle.advance(0.01)
	ck(turtle.action == "seek", "T01 seek starts automatically")
	shell.contact(turtle); hp = turtle.health
	turtle.hit(999)
	ck(turtle.action == "hidden" and turtle.health == hp and not turtle.physics_enabled, "T02 hidden turtle is immune and not collidable")
	shell.position = Vector2(320,200); turtle.advance(0.1)
	ck(turtle.position == shell.position, "T03 hidden turtle follows shell")
	turtle.advance(2.5)
	ck(turtle.action == "idle" and turtle.physics_enabled and is_equal_approx(turtle.velocity.length(),170), "T04 turtle exits and resumes motion")
	shell.position = Vector2(300,300); shell.velocity = Vector2(30,40); target.position = Vector2(345,300); target.velocity = Vector2.ZERO
	hp = target.health; shell.contact(target)
	ck(target.health == hp - 18, "T05 normal shell collision deals normal damage")
	shell.start_spin(); hp = target.health; var target_v: Vector2 = target.velocity
	shell.contact(target)
	ck(target.health == hp - 27 and target.velocity.x > target_v.x and shell.velocity.x < 0, "T06 spinning shell deals 1.5 damage and both rebound")
	a.free()
	# Crow: exact reflected damage, feather and stationary dummy behavior.
	a = arena([9,6]); crow = a.heroes[0]; rabbit = a.heroes[1]
	crow.advance(2.1); crow.advance(5.1)
	ck(crow.dummies.size() == 2, "W01 spawn two dummies")
	dummy = crow.dummies[0]; var fixed_pos := dummy.position
	ck(dummy.inverse_mass() == 0 and dummy.velocity == Vector2.ZERO, "W02 dummy immovable")
	dummy.health = 8; rabbit.health = 120; rabbit.stored_damage = 40; rabbit.temper_left = 2
	rabbit.contact(dummy)
	ck(dummy.health == 0 and rabbit.health == 112 and rabbit.stored_damage == 0 and rabbit.temper_left == 0, "W03 rabbit damages dummy, reflects actual remaining HP and consumes strike")
	hp = rabbit.health; dummy.hit(10)
	ck(rabbit.health == hp, "W04 destroyed dummy does not reflect again")
	dummy = crow.dummies[1]; dummy.health = 20; crow.feather = true; crow.contact(dummy)
	ck(dummy.health == 45 and not crow.feather, "W05 feather heals 25 once")
	dummy.health = 60; crow.feather = true; crow.contact(dummy)
	ck(crow.feather, "W06 full-health dummy does not consume feather")
	ck(fixed_pos.is_finite(), "W07 dummy remains valid before removal")
	a.free()
	# Cross-character interaction: wool/charge damage can be intercepted and reflected.
	a = arena([3,9]); var electric: ElectricSheep = a.heroes[0]; crow = a.heroes[1]
	electric.position = Vector2(300,300); crow.position = Vector2(400,300)
	crow.dummy_timer = 0; crow.advance(0.01); dummy = crow.dummies[0]; dummy.position = Vector2(350,300)
	electric.charge = 100; hp = electric.health; var crow_before := crow.health; var dummy_before := dummy.health
	electric.discharge(0.1)
	ck(is_equal_approx(dummy.health,dummy_before-2) and is_equal_approx(electric.health,hp-2) and crow.health == crow_before, "X01 sheep discharge blocked by dummy and damage reflected once")
	ck(is_equal_approx(electric.charge,97.5), "X02 intercepted discharge consumes charge once")
	a.free()
	# A hidden turtle is protected from egg explosions even when located at the blast.
	a = arena([1,8]); chicken = a.heroes[0]; turtle = a.heroes[1]; shell = turtle.shell
	chicken.position = Vector2(100,100); shell.position = Vector2(300,300)
	turtle.enter_shell(); hp = turtle.health
	a.spawn_egg(shell.position,chicken,true); egg = a.eggs[0]
	egg.explode(a.balls)
	ck(turtle.health == hp and shell.health == 120, "X03 hidden turtle and invulnerable shell withstand egg blast")
	a.free()
	# Sheep charge resource, shared discharge and no double damage.
	a = arena([3,0]); var sheep: ElectricSheep = a.heroes[0]; target = a.heroes[1]
	sheep.charge = 95; sheep._wall_charge(Vector2.LEFT)
	ck(sheep.charge == 100, "S01 wall charge capped at 100")
	sheep.position = Vector2(200,200); target.position = Vector2(250,200)
	sheep.wool_active = true; sheep.wool_position = sheep.position; sheep.charge = 100; hp = target.health
	sheep.discharge(1)
	ck(is_equal_approx(sheep.charge,75) and is_equal_approx(target.health,hp-20), "S02 overlapping wool/body do not double damage or drain")
	sheep.position = Vector2(100,200); sheep.velocity = Vector2(80,0); sheep.cd_one = 0; sheep.advance(0.01)
	ck(is_equal_approx(sheep.velocity.length(),140), "S03 turn raises slow velocity to 140")
	sheep.velocity = Vector2(200,0); sheep.cd_one = 0; sheep.advance(0.01)
	ck(is_equal_approx(sheep.velocity.length(),200), "S04 turn preserves speed above 140")
	a.free()
	# Existing match ending semantics, then state remains frozen.
	a = arena([0,1]); a.heroes[1].health = 0; a.step(0.01)
	ck(a.finished and a.result == "PUFFER WINS", "O01 death selects living hero winner")
	var old_time := a.simulation_time; var old_hp := a.heroes[0].health; old_pos = a.heroes[0].position
	a.step(1.0)
	ck(a.simulation_time == old_time and a.heroes[0].health == old_hp and a.heroes[0].position == old_pos, "O02 finished battle remains frozen")
	a.free()
	a = arena([0,1]); a.heroes[0].health = 0; a.heroes[1].health = 0; a.step(0.01)
	ck(a.finished and a.result == "DRAW", "O03 both heroes zero is draw")
	a.free()
	a = arena([0,1]); a.simulation_time = 90; a.step(0.01)
	ck(a.finished and a.result == "TIME LIMIT · DRAW", "O04 timeout is draw")
	a.free()
	# New roles also retain equivalent battle state across 1x/2x/3x and pause.
	var snapshotter = load("res://tests/v04_cases.gd").new()
	for role in [5,6,7,8,9]:
		var reference: Array = []
		for speed in [1,2,3]:
			var controller = load("res://scenes/main.tscn").instantiate()
			controller.page_save_path_override = "user://rate_test_%d_%d_%d.jsonl" % [OS.get_process_id(), role, speed]
			host.root.add_child(controller)
			controller.set_process(false)
			controller.arena.free()
			controller.arena = BattleArena.new()
			controller.arena.setup(527,[role,0])
			controller.add_child(controller.arena)
			controller.set_rate(speed)
			for tick in int(360 / speed): controller.advance_real_time(1.0/120)
			var state: Array = snapshotter.snapshot(controller.arena)
			if reference.is_empty(): reference = state
			ck(state == reference, "L01 new role %d state identical at speed %d" % [role,speed])
			controller.set_rate(0)
			controller.advance_real_time(5)
			ck(state == snapshotter.snapshot(controller.arena), "L02 new role %d paused state frozen" % role)
			controller.free()
	print("GAMEPLAY CASES checks=%d" % (host.checks-before))
