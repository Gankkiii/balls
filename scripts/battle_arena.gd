class_name BattleArena
extends Arena
var eggs: Array[BombEgg] = []
var finished := false
var result := ""

func _init() -> void:
	arena_size = Vector2(700, 600)

func setup(seed_value: int) -> void:
	var puffer := Puffer.new()
	var chicken := Chicken.new()
	register_ball(puffer)
	register_ball(chicken)
	for fighter in balls:
		fighter.world = self
		fighter.rng.seed = seed_value + balls.find(fighter) * 17
	initialize(seed_value)

func spawn_egg(at: Vector2, owner_value: Fighter, large: bool) -> void:
	if eggs.size() >= 32:
		var old: BombEgg = eggs.pop_front()
		old.free()
	var egg := BombEgg.new()
	egg.setup(at, owner_value, large)
	add_child(egg)
	move_child(egg, 0)
	eggs.append(egg)

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
	var p_alive: bool = balls[0].health > 0
	var c_alive: bool = balls[1].health > 0
	if not p_alive or not c_alive:
		finished = true
		result = "DRAW" if not p_alive and not c_alive else ("PUFFER WINS" if p_alive else "CHICKEN WINS")
	elif simulation_time >= 90:
		finished = true
		result = "TIME LIMIT · DRAW"
