class_name BattleArena
extends Arena
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
	var options := [0,1,2,3,4]
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
		register_ball(fighter)
		fighter.world = self
		fighter.rng.seed = seed_value + balls.find(fighter)*17
	initialize(seed_value)

func enemy_of(fighter: Fighter) -> Fighter:
	return balls[1] if balls[0] == fighter else balls[0]

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
	return bubble

func spawn_nail(owner_value: Fighter, at: Vector2) -> IronNail:
	var nail := IronNail.new()
	nail.owner_fighter = owner_value
	nail.position = at
	add_child(nail)
	move_child(nail,0)
	nails.append(nail)
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

func step_bubbles(dt: float) -> void:
	for bubble in bubbles:
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
				drop.gone = true
				if a.gone:
					break
	for bubble in bubbles:
		if bubble.gone:
			continue
		var enemy := enemy_of(bubble.owner_fighter)
		if bubble.position.distance_to(enemy.position) <= bubble.size_radius()+enemy.radius:
			if bubble.level >= 2:
				enemy.hit(float(bubble.level)*8)
			bubble.gone = true
	for i in range(bubbles.size()-1,-1,-1):
		if bubbles[i].gone:
			bubbles[i].free()
			bubbles.remove_at(i)

func step(dt: float) -> void:
	if finished or dt <= 0:
		return
	for fighter in balls:
		fighter.advance(dt)
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
	for fighter in balls:
		if fighter is ElectricSheep:
			fighter.discharge(dt)
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
	for fighter in balls:
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
