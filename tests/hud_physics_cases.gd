extends RefCounted
var host
func ck(ok: bool, label: String) -> void:
	host.check(ok,"H/P " + label)
func near(a: Vector2,b: Vector2) -> bool:
	return a.distance_to(b)<0.002
func run(runner) -> void:
	host = runner
	for kind in 5:
		var world := BattleArena.new()
		world.setup(17,[kind,(kind+1)%5])
		host.root.add_child(world)
		var f: Fighter = world.balls[0]
		ck(f.hud != null and f.hud.get_parent() == f,"every hero has following HUD")
		ck(f.hud.health_fraction() == 1,"full HP")
		f.hit(30)
		ck(is_equal_approx(f.hud.health_fraction(),0.75),"damage updates health fraction")
		f.hit(500)
		ck(f.hud.health_fraction() == 0,"zero HP clamps")
		f.cd_one = 2.5
		f.cd_two = 0
		ck(f.hud.cd_text(0) == "1: 2.5" and f.hud.cd_text(1) == "2: OK","two independent cooldown boxes")
		for at in [Vector2(24,24),Vector2(676,24),Vector2(24,576),Vector2(676,576),Vector2(350,300)]:
			f.position = at
			if f is Puffer:
				f.gas = 100
			for rect in f.hud.layout():
				var global_rect := Rect2(rect.position+f.position,rect.size)
				ck(Rect2(Vector2.ZERO,world.arena_size).encloses(global_rect),"HUD inside arena corners/full puffer")
		var before := [f.position,f.velocity,f.health,f.cd_one,f.cd_two]
		for i in 100:
			f.hud._process(1)
			f.hud.layout()
		ck(before == [f.position,f.velocity,f.health,f.cd_one,f.cd_two],"HUD drawing cannot advance game/physics")
		world.free()

	# Isolate production Fighter/Arena collision solver from intentional combat forces.
	for first in 5:
		for second in range(first+1,5):
			var source := BattleArena.new()
			source.setup(1,[first,second])
			var a := Arena.new()
			a.arena_size = Vector2(1000,1000)
			var x: Fighter = source.balls[0]
			var y: Fighter = source.balls[1]
			source.remove_ball(x)
			source.remove_ball(y)
			a.register_ball(x)
			a.register_ball(y)
			x.world = a
			y.world = a
			x.configure(Vector2(400,500),Vector2(100,30))
			y.configure(Vector2(448,500),Vector2(-50,-20))
			var e := a.kinetic_energy()
			var momentum := a.momentum()
			a.step(0.001)
			ck(near(x.velocity,Vector2(-50,30)) and near(y.velocity,Vector2(100,-20)),"all pairs normal exchange/tangent unchanged")
			ck(absf(a.kinetic_energy()-e)<0.01 and near(a.momentum(),momentum),"all pairs isolated energy/momentum")
			ck(x.health == 120 and y.health == 120,"normal contact harmless for all heroes")
			x.configure(Vector2(100,300),Vector2(40000,0))
			y.configure(Vector2(600,300),Vector2(-30000,0))
			e = a.kinetic_energy()
			for i in 120:
				a.step(1.0/120)
				ck(x.position.distance_to(y.position) >= 47.98,"all pairs fast no overlap")
				for f in [x,y]:
					ck(f.position.x >= 23.99 and f.position.x <= 976.01,"fast wall bounds")
			ck(absf(a.kinetic_energy()/e-1)<0.0001 and a.event_limit_hits == 0,"fast no energy growth/event overflow")
			a.free()
			source.free()

	# Both actual stationary skill states: incoming disk reflects, caster does not move.
	for stationary in [Puffer.new(),Chicken.new()]:
		var a := Arena.new()
		a.arena_size = Vector2(1000,1000)
		var moving := Fighter.new()
		a.register_ball(stationary)
		a.register_ball(moving)
		stationary.configure(Vector2(400,500),Vector2(120,0))
		stationary.begin_stationary("inflate" if stationary is Puffer else "lay")
		moving.configure(Vector2(448,500),Vector2(-100,30))
		a.step(0.01)
		ck(stationary.position == Vector2(400,500) and stationary.velocity == Vector2.ZERO,"stationary caster stays put")
		ck(near(moving.velocity,Vector2(100,30)),"stationary obstacle reflects normal only")
		stationary.resume_motion()
		ck(stationary.inverse_mass() == 1 and stationary.velocity == Vector2(120,0),"skill end restores mobile body")
		a.free()

	var a := Arena.new()
	a.arena_size = Vector2(1000,1000)
	var x := Ball.new()
	var y := Ball.new()
	x.mass = 2
	y.mass = 1
	a.register_ball(x)
	a.register_ball(y)
	x.configure(Vector2(400,500),Vector2(100,0))
	y.configure(Vector2(448,500),Vector2(-50,0))
	var e := a.kinetic_energy()
	var momentum := a.momentum()
	a.step(0.01)
	ck(near(x.velocity,Vector2.ZERO) and near(y.velocity,Vector2(150,0)),"unequal mass elastic formula")
	ck(absf(a.kinetic_energy()-e)<0.01 and near(a.momentum(),momentum),"unequal mass conservation")
	a.free()

	# Puffer's real burst entry uses boosted speed but collision response remains elastic.
	var burst_arena := Arena.new()
	burst_arena.arena_size = Vector2(1000,1000)
	var puffer := Puffer.new()
	var target := Fighter.new()
	burst_arena.register_ball(puffer)
	burst_arena.register_ball(target)
	puffer.configure(Vector2(400,500),Vector2(180,0))
	target.configure(Vector2(448,500),Vector2.ZERO)
	puffer.gas = 100
	puffer.start_burst()
	var boosted := puffer.velocity
	e = burst_arena.kinetic_energy()
	burst_arena.step(0.01)
	ck(near(puffer.velocity,Vector2.ZERO) and near(target.velocity,boosted),"actual burst collision exchanges velocity")
	ck(absf(burst_arena.kinetic_energy()-e)<0.01 and target.health == 120-Puffer.HIT_DAMAGE,"burst attack does not add collision impulse")
	burst_arena.free()
