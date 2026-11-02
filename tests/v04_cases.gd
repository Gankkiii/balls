extends RefCounted
var host
func ck(ok: bool, label: String) -> void:
	host.check(ok,"V04 "+label)
func arena(pair: Array) -> BattleArena:
	var a := BattleArena.new()
	a.setup(225,pair)
	for f in a.heroes:
		f.cd_one=999
		f.cd_two=999
	return a
func snapshot(a: BattleArena) -> Array:
	var data: Array = [a.roster.duplicate(),a.simulation_time,a.finished,a.result,a.spawn_rng.state]
	for f in a.balls:
		data.append_array([f.title,f.position,f.velocity,f.health,f.cd_one,f.cd_two,f.action,f.action_left,f.rng.state,f.physics_enabled])
		for prop in ["gas","immune_left","impact_cooldown","egg_timer","turn_timer","bubble_timer","charge","wool_active","wool_position","nail_timer","repel_ready","storm_left","rods","stored_damage","temper_left","thorns","dummy_timer","feather","spin_left"]:
			var value = f.get(prop)
			if value != null:
				data.append(value.duplicate() if value is Array else value)
		if f is UnluckyDuck:
			data.append(a.heroes.find(f.cloud_holder))
	for b in a.bubbles:
		data.append_array([b.position,b.velocity,b.level,b.launch_left,b.absorb_left,b.rng.state])
	for n in a.nails:
		data.append_array([n.position,n.mode,n.target,n.hit_left,n.outward_left])
	for e in a.eggs:
		data.append_array([e.position,e.armed,e.fuse,e.age,e.exploded,e.blast_left])
	return data
func run(runner) -> void:
	host=runner
	var a:=arena([5,0])
	var duck: UnluckyDuck=a.heroes[0]
	var enemy: Fighter=a.heroes[1]
	duck.storm_left=3
	duck.contact(enemy)
	ck(duck.cloud_holder==enemy and duck.storm_left==3,"D01 transfer preserves timer")
	duck.contact(enemy)
	var hp:=duck.health
	duck.strike()
	ck(duck.health==hp-32,"D02 duck takes lightning")
	duck.cloud_holder=enemy
	duck.storm_left=1
	duck.cd_one=0
	hp=enemy.health
	duck.advance(0.01)
	ck(enemy.health==hp-32 and duck.storm_left==7,"D03 timer zero immediate strike")
	duck.storm_left=3
	duck.cd_one=0
	duck.advance(0.01)
	ck(absf(duck.storm_left-4.99)<0.00001,"D04 self extends timer")
	duck.rods.assign([duck.position,duck.position])
	hp=duck.health
	duck.strike()
	ck(duck.health==hp and duck.rods.size()==1,"D05 overlap consumes one rod")
	duck.rods.assign([enemy.position])
	duck.cloud_holder=enemy
	hp=enemy.health
	duck.strike()
	ck(enemy.health==hp and duck.rods.is_empty(),"D06 enemy can use protection")
	duck.rods.assign([duck.position,enemy.position])
	duck.cd_two=0
	duck.advance(0.01)
	ck(duck.rods.size()==2 and duck.cd_two==0,"D07 full rod cap waits")
	duck.rods.remove_at(0)
	duck.advance(0.01)
	ck(duck.rods.size()==2 and duck.cd_two>0,"D08 replace missing rod")
	a.free()

	a=arena([6,0])
	var rabbit: ForgeRabbit=a.heroes[0]
	enemy=a.heroes[1]
	rabbit.advance(1)
	ck(rabbit.stored_damage==8,"R01 time accumulates blade")
	rabbit.begin_stationary("forge")
	rabbit.action_left=2
	rabbit.advance(1)
	ck(rabbit.stored_damage==20 and rabbit.velocity==Vector2.ZERO,"R02 forge faster stationary")
	rabbit.temper_left=2
	hp=enemy.health
	rabbit.contact(enemy)
	ck(enemy.health==hp-30 and rabbit.stored_damage==0 and rabbit.temper_left==0,"R03 buff1.5 once consumed")
	rabbit.stored_damage=10
	rabbit.contact(enemy)
	ck(enemy.health==hp-40,"R04 next hit unbuffed")
	rabbit.temper_left=0.1
	rabbit.advance(0.2)
	ck(rabbit.temper_left==0,"R05 unused buff expires")
	a.free()

	a=arena([7,0])
	var cactus: Cactus=a.heroes[0]
	enemy=a.heroes[1]
	ck(cactus.velocity==Vector2.ZERO and cactus.inverse_mass()==0,"C01 immovable spawn")
	cactus.position=Vector2(300,300)
	enemy.position=Vector2(348,300)
	enemy.velocity=Vector2(-100,0)
	hp=enemy.health
	a.step(0.01)
	ck(cactus.position==Vector2(300,300) and enemy.velocity.x>0 and enemy.health==hp-18,"C02 physical bounce deals one hit")
	enemy.velocity=Vector2.ZERO
	for i in 10:
		a.step(0.01)
	ck(enemy.health==hp-18,"C03 sustained contact no repeated damage")
	cactus.hit(10)
	ck(cactus.health==110,"C04 cactus vulnerable")
	cactus.thorns.assign([enemy.position])
	hp=enemy.health
	cactus.step_thorns()
	ck(cactus.thorns.is_empty() and enemy.health==hp-12,"C05 thorn consumed")
	cactus.thorns.assign([Vector2(70,70)])
	var old:=cactus.position
	cactus.cd_two=0
	cactus.advance(0.01)
	ck(cactus.position!=old and a.position_clear(cactus.position,cactus.radius,cactus) and cactus.thorns.size()==1,"C06 safe teleport retains thorns")
	a.free()

	a=arena([8,0])
	var turtle: ShellTurtle=a.heroes[0]
	var shell:=turtle.shell
	enemy=a.heroes[1]
	ck(a.balls.size()==3 and shell.position.distance_to(turtle.position)>shell.radius+turtle.radius,"T01 separated shell spawn")
	shell.hit(999)
	ck(shell.health==120,"T02 invincible shell")
	shell.contact(turtle)
	ck(turtle.health==120,"T03 own shell harmless")
	turtle.contact(enemy)
	ck(turtle.health==108,"T04 exposed body contact hurts")
	turtle.action="seek"
	shell.contact(turtle)
	turtle.hit(999)
	ck(turtle.action=="hidden" and not turtle.physics_enabled and turtle.health==108,"T05 hidden immune and no collider")
	turtle.advance(3)
	ck(turtle.action=="idle" and turtle.physics_enabled and a.position_clear(turtle.position,turtle.radius,turtle),"T06 safe emergence")
	shell.position=Vector2(300,300)
	enemy.position=Vector2(346,300)
	shell.start_spin()
	hp=enemy.health
	shell.contact(enemy)
	ck(enemy.health==hp-27 and shell.velocity.length()>0 and enemy.velocity.length()>0,"T07 spinning1.5 both rebound")
	a.free()

	a=arena([9,0])
	var crow: Crow=a.heroes[0]
	enemy=a.heroes[1]
	ck(crow.dummies.is_empty(),"W01 no initial dummy")
	crow.advance(2.1)
	crow.advance(5.1)
	ck(crow.dummies.size()==2,"W02 periodic two dummies")
	crow.advance(10)
	ck(crow.dummies.size()==2,"W03 cap waits")
	var dummy:=crow.dummies[0]
	ck(dummy.inverse_mass()==0 and dummy.velocity==Vector2.ZERO,"W04 fixed dummy")
	hp=enemy.health
	dummy.hit(10)
	ck(dummy.health==50 and enemy.health==hp-10,"W05 actual damage reflected")
	crow.feather=true
	crow.contact(dummy)
	ck(dummy.health==60 and not crow.feather,"W06 collision heals consumes feather")
	crow.cd_two=0
	crow.advance(0.01)
	ck(crow.feather,"W07 generates feather")
	crow.cd_two=0
	crow.advance(0.01)
	ck(crow.feather and crow.cd_two==0,"W08 feather cap1")
	old=crow.position
	var dummy_old:=dummy.position
	crow.cd_one=0
	crow.advance(0.01)
	ck(crow.position==dummy_old and dummy.position==old,"W09 exact swap")
	crow.position=Vector2(500,300)
	dummy.position=Vector2(350,300)
	enemy.position=Vector2(200,300)
	ck(a.enemy_of(enemy)==crow and a.first_target(enemy,enemy.position,crow.position)==dummy,"W10 blocker not targeting")
	var bubble:=a.spawn_bubble(enemy,Vector2(300,300),Vector2(1000,0),1)
	bubble.level=2
	hp=crow.health
	var dummy_hp:=dummy.health
	a.step_bubbles(0.1)
	ck(crow.health==hp and dummy.health==dummy_hp-16 and a.bubbles.is_empty(),"W11 bubble intercepted")
	var nail:=a.spawn_nail(enemy,Vector2(300,300))
	nail.mode="wall"
	nail.target=Vector2(600,300)
	dummy_hp=dummy.health
	nail.advance(0.4,a)
	ck(dummy.health==dummy_hp-16 and crow.health==hp and nail.mode=="rest","W12 nail blocked and rests")
	dummy.hit(999)
	a.step(0.01)
	ck(crow.dummies.size()==1,"W13 destroyed dummy removed")
	crow.dummy_timer=0
	crow.advance(0.01)
	ck(crow.dummies.size()==2,"W14 replenishes dummy")
	a.free()

	var before_checks: int=host.checks
	for first in 10:
		for second in range(first+1,10):
			a=BattleArena.new()
			var b:=BattleArena.new()
			a.setup(527,[first,second])
			b.setup(527,[first,second])
			for tick in 10802:
				a.step(1.0/120)
				b.step(1.0/120)
				if tick%120==0:
					ck(snapshot(a)==snapshot(b),"M01 all45 seeded replay")
					for body in a.active_balls():
						ck(body.position.is_finite() and body.position.x>=body.radius-0.02 and body.position.y>=body.radius-0.02 and body.position.x<=a.arena_size.x-body.radius+0.02 and body.position.y<=a.arena_size.y-body.radius+0.02,"M02 all bodies in bounds")
				if a.finished:
					break
			ck(a.finished and a.event_limit_hits==0 and b.event_limit_hits==0,"M03 all45 terminate no solver cap")
			a.free()
			b.free()
	print("V04 matrix assertions=",host.checks-before_checks)
