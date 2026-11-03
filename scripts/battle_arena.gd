class_name BattleArena
extends Arena
signal presentation_event(cue_name: String)

func present(cue_name: String) -> void:
	presentation_event.emit(cue_name)
var heroes: Array[Fighter] = []
var eggs: Array[BombEgg] = []
var bubbles: Array[Bubble] = []
var nails: Array[IronNail] = []
var finished := false
var result := ""
var match_seed := 0
var spawn_rng := RandomNumberGenerator.new()
var roster: Array[int] = []

func _init() -> void:
	arena_size = Vector2(700, 600)

func setup(seed_value: int, chosen: Array = []) -> void:
	match_seed = seed_value
	spawn_rng.seed = seed_value
	var options := [0,1,2,3,4,5,6,7,8,9]
	if chosen.is_empty():
		for i in 2:
			var index := spawn_rng.randi_range(0,options.size()-1)
			roster.append(options.pop_at(index))
	else:
		roster.assign(chosen)
	for id in roster:
		var fighter: Fighter
		match id:
			0: fighter = Puffer.new()
			1: fighter = Chicken.new()
			2: fighter = BubbleFish.new()
			3: fighter = ElectricSheep.new()
			4: fighter = MagnetCrab.new()
			5: fighter = UnluckyDuck.new()
			6: fighter = ForgeRabbit.new()
			7: fighter = Cactus.new()
			8: fighter = ShellTurtle.new()
			9: fighter = Crow.new()
		heroes.append(fighter)
		register_ball(fighter)
		fighter.world = self
		fighter.rng.seed = seed_value + balls.find(fighter)*17
	initialize(seed_value)
	for fighter in heroes:
		if fighter is Cactus:
			fighter.velocity = Vector2.ZERO
		if fighter is UnluckyDuck:
			fighter.cloud_holder = fighter
		if fighter is ShellTurtle:
			var shell := TurtleShell.new()
			shell.turtle = fighter
			shell.world = self
			shell.rng.seed = spawn_rng.randi()
			shell.position = free_position(shell.radius)
			shell.velocity = Vector2.from_angle(spawn_rng.randf_range(0,TAU))*180
			fighter.shell = shell
			register_ball(shell)

func enemy_of(fighter: Fighter) -> Fighter:
	return heroes[1] if heroes[0] == fighter else heroes[0]

func owner_of(body: Fighter) -> Fighter:
	if body is Scarecrow:
		return body.owner_crow
	if body is TurtleShell:
		return body.turtle
	return body

func is_enemy_body(attacker: Fighter, body: Fighter) -> bool:
	return owner_of(body) != owner_of(attacker)

func attack_targets(attacker: Fighter) -> Array[Fighter]:
	var targets: Array[Fighter] = []
	for body in balls:
		if body is Fighter and body.physics_enabled and body.health > 0 and is_enemy_body(attacker,body):
			targets.append(body)
	return targets

func first_target(attacker: Fighter, start: Vector2, finish: Vector2, extra_radius: float = 0) -> Fighter:
	var target: Fighter = null
	var best := INF
	var segment := finish-start
	for candidate in attack_targets(attacker):
		var radius_sum := candidate.radius+extra_radius
		var offset := start-candidate.position
		var t := 0.0
		if offset.length_squared() > radius_sum*radius_sum:
			var aa := segment.length_squared()
			if aa < 1e-12:
				continue
			var bb := offset.dot(segment)
			var discriminant := bb*bb-aa*(offset.length_squared()-radius_sum*radius_sum)
			if discriminant < 0:
				continue
			t = (-bb-sqrt(discriminant))/aa
			if t < 0 or t > 1:
				continue
		if t < best:
			best = t
			target = candidate
	return target

func position_clear(at: Vector2, size: float, ignore: Ball = null, ignore_two: Ball = null) -> bool:
	if at.x < size+2 or at.y < size+2 or at.x > arena_size.x-size-2 or at.y > arena_size.y-size-2:
		return false
	for body in balls:
		if body != ignore and body != ignore_two and body.physics_enabled and at.distance_to(body.position) < size+body.radius+3:
			return false
	return true

func free_position(size: float, ignore: Ball = null, near: Vector2 = Vector2(-1,-1)) -> Vector2:
	for i in 100:
		var at := Vector2(spawn_rng.randf_range(size+3,arena_size.x-size-3),spawn_rng.randf_range(size+3,arena_size.y-size-3))
		if near.x >= 0 and i < 24:
			at = near + Vector2.from_angle(i*TAU/24)*(size+28)
		if position_clear(at,size,ignore):
			return at
	return Vector2(-1,-1)

func spawn_bubble(owner_value: Fighter, at: Vector2, speed: Vector2, launch: float = 0, absorb: float = 0) -> Bubble:
	var bubble := Bubble.new()
	bubble.owner_fighter = owner_value
	bubble.position = at
	bubble.velocity = speed
	bubble.launch_left = launch
	bubble.absorb_left = absorb
	bubble.rng.seed = spawn_rng.randi()
	add_child(bubble)
	move_child(bubble,0)
	bubbles.append(bubble)
	present("bubble_fish_vacuum" if absorb > 0 else "bubble_fish_spit")
	return bubble

func spawn_nail(owner_value: Fighter, at: Vector2) -> IronNail:
	var nail := IronNail.new()
	nail.owner_fighter = owner_value
	nail.position = at
	add_child(nail)
	move_child(nail,0)
	nails.append(nail)
	present("magnet_crab_drop")
	return nail

func spawn_egg(at: Vector2, owner_value: Fighter, large: bool) -> void:
	if eggs.size() >= 32:
		var old: BombEgg = eggs.pop_front()
		old.free()
	var egg := BombEgg.new()
	egg.setup(at, owner_value, large)
	add_child(egg)
	move_child(egg, 0)
	eggs.append(egg)
	present("chicken_egg_drop")
	if large:
		present("chicken_fuse")

func step_bubbles(dt: float) -> void:
	var previous := {}
	for bubble in bubbles:
		previous[bubble] = bubble.position
		bubble.advance(dt, arena_size)
	# Vacuum movement is straight during launch; it moves other bubbles, not itself.
	for sink in bubbles:
		if sink.gone or sink.absorb_left <= 0:
			continue
		for other in bubbles:
			if other != sink and not other.gone and other.owner_fighter == sink.owner_fighter and other.position.distance_to(sink.position) <= 105:
				other.position = other.position.move_toward(sink.position,120*dt)
	for i in bubbles.size():
		var a := bubbles[i]
		if a.gone:
			continue
		for j in range(i+1,bubbles.size()):
			var b := bubbles[j]
			if b.gone or a.owner_fighter != b.owner_fighter:
				continue
			if a.position.distance_to(b.position) <= a.size_radius()+b.size_radius():
				# Preserve the vacuum projectile as the survivor when it merges.
				var keep := b if b.absorb_left > a.absorb_left else a
				var drop := a if keep == b else b
				keep.level += drop.level
				present("bubble_fish_merge")
				drop.gone = true
				if a.gone:
					break
	for bubble in bubbles:
		if bubble.gone:
			continue
		var enemy := first_target(bubble.owner_fighter,previous[bubble],bubble.position,bubble.size_radius())
		if enemy != null:
			if bubble.level >= 2:
				enemy.hit(float(bubble.level)*8)
				present("bubble_fish_hit")
			bubble.gone = true
	for i in range(bubbles.size()-1,-1,-1):
		if bubbles[i].gone:
			bubbles[i].free()
			bubbles.remove_at(i)

func step(dt: float) -> void:
	if finished or dt <= 0:
		return
	for fighter in heroes:
		fighter.advance(dt)
	for fighter in heroes:
		if fighter is ShellTurtle:
			fighter.shell.advance(dt)
	super.step(dt)
	for egg in eggs:
		egg.advance(dt, balls)
	for i in range(eggs.size() - 1, -1, -1):
		var egg := eggs[i]
		if (egg.exploded and egg.blast_left <= 0) or egg.age > 22:
			eggs.remove_at(i)
			egg.free()
	step_bubbles(dt)
	for nail in nails:
		nail.advance(dt,self)
	for i in range(nails.size()-1,-1,-1):
		if nails[i].gone:
			nails[i].free()
			nails.remove_at(i)
	for fighter in heroes:
		if fighter is ElectricSheep:
			fighter.discharge(dt)
	for fighter in heroes:
		if fighter is Cactus:
			fighter.step_thorns()
		if fighter is ShellTurtle and fighter.action == "hidden":
			fighter.position = fighter.shell.position
		if fighter is Crow:
			for i in range(fighter.dummies.size()-1,-1,-1):
				var dummy: Scarecrow = fighter.dummies[i]
				if dummy.health <= 0:
					fighter.dummies.remove_at(i)
					remove_ball(dummy)
					dummy.free()
	var first_alive: bool = balls[0].health > 0
	var second_alive: bool = balls[1].health > 0
	if not first_alive or not second_alive:
		finished = true
		result = "DRAW" if not first_alive and not second_alive else ((balls[0].title if first_alive else balls[1].title) + " WINS")
	elif simulation_time >= 90:
		finished = true
		result = "TIME LIMIT · DRAW"
	queue_redraw()

func _draw() -> void:
	super._draw()
	for fighter in heroes:
		if fighter is ElectricSheep:
			if fighter.wool_active:
				draw_circle(fighter.wool_position,13,Color("fff3c0"))
				draw_arc(fighter.wool_position,ElectricSheep.RANGE,0,TAU,48,Color(1,0.9,0.5,0.2),1)
			if fighter.zapping:
				var enemy := enemy_of(fighter)
				for origin in [fighter.position, fighter.wool_position]:
					if origin == fighter.wool_position and not fighter.wool_active:
						continue
					if origin.distance_to(enemy.position) <= ElectricSheep.RANGE + enemy.radius:
						draw_line(origin,enemy.position,Color("ffe45c"),2)
		elif fighter is MagnetCrab and fighter.wall_flash > 0:
			var starts := [Vector2.ZERO,Vector2(arena_size.x,0),Vector2.ZERO,Vector2(0,arena_size.y)]
			var ends := [Vector2(0,arena_size.y),arena_size,Vector2(arena_size.x,0),arena_size]
			draw_line(starts[fighter.magnetic_wall],ends[fighter.magnetic_wall],Color("ff987d"),6)

		elif fighter is UnluckyDuck:
			for rod in fighter.rods:
				draw_line(rod+Vector2(0,8),rod-Vector2(0,22),Color("86d8ee"),4)
				draw_arc(rod,100,0,TAU,48,Color(0.5,0.8,1,0.2),1)
			if fighter.cloud_holder != null:
				var cloud: Vector2 = fighter.cloud_holder.position+Vector2(0,-58)
				draw_circle(cloud,14,Color("727894"))
				draw_string(ThemeDB.fallback_font,cloud+Vector2(-10,5),"%.1f" % fighter.storm_left,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
			if fighter.lightning_flash > 0:
				draw_line(fighter.strike_position-Vector2(0,80),fighter.strike_position,Color("fff19e"),5)
		elif fighter is Cactus:
			for thorn in fighter.thorns:
				draw_colored_polygon(PackedVector2Array([thorn+Vector2(-5,5),thorn+Vector2(0,-7),thorn+Vector2(5,5)]),Color("cfdf97"))
