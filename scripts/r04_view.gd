extends Control
## Presentation only. Reads authoritative combat state, never changes simulation.
const ORIGIN := Vector2(200,90)
const ROOT := "res://assets/r04/"
const OLD := "res://assets/r02/"
var game: Control
var cache := {}
var previous_hp := {}
var blink_left := {}
var previous_action := {}
var flower_left := 0.0
var rabbit_hit_left := 0.0
var info_open := false
var font: Font
var last_position := {}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	font=load("res://assets/arena-ui.otf")

func reset() -> void:
	previous_hp.clear()
	blink_left.clear()
	previous_action.clear()
	last_position.clear()
	flower_left=0
	rabbit_hit_left=0

func observe_before_step(arena: BattleArena) -> void:
	for actor in arena.heroes:
		previous_hp[actor]=actor.health
		previous_action[actor]=actor.action
		last_position[actor]=actor.position

func observe_after_step(arena: BattleArena, dt: float) -> void:
	for actor in arena.heroes:
		blink_left[actor]=maxf(0.0,float(blink_left.get(actor,0.0))-dt)
		if previous_hp.has(actor) and actor.health < previous_hp[actor] and float(blink_left.get(actor,0.0))<=0:
			blink_left[actor]=0.24
		if actor is Cactus and last_position.has(actor) and actor.position != last_position[actor]:
			flower_left=0.30
	flower_left=maxf(0.0,flower_left-dt)
	rabbit_hit_left=maxf(0.0,rabbit_hit_left-dt)

func tex(path: String) -> Texture2D:
	if not cache.has(path):
		cache[path]=load(path)
	return cache[path]

func img(path: String, rect: Rect2, color: Color=Color.WHITE) -> void:
	var t:=tex(path)
	if t: draw_texture_rect(t,rect,false,color)

func centered(path: String, pos: Vector2, scale_value: float=1.0, pivot: Vector2=Vector2(48,48), flip: bool=false, color: Color=Color.WHITE) -> void:
	var t:=tex(path)
	if not t: return
	draw_set_transform(pos,0,Vector2(-scale_value if flip else scale_value,scale_value))
	draw_texture(t,-pivot,color)
	draw_set_transform(Vector2.ZERO)

func strip(path: String,pos: Vector2,frame: int,pivot: Vector2,scale_value: float=1.0,flip: bool=false) -> void:
	var t:=tex(path)
	if not t: return
	draw_set_transform(pos,0,Vector2(-scale_value if flip else scale_value,scale_value))
	draw_texture_rect_region(t,Rect2(-pivot,Vector2(96,96)),Rect2(frame*96,0,96,96))
	draw_set_transform(Vector2.ZERO)

func label(value: String, at: Vector2, size: int=18, color: Color=Color("243746")) -> void:
	if font: draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func actor_id(actor: Fighter) -> String:
	if actor is Puffer: return "puffer"
	if actor is Chicken: return "chicken"
	if actor is BubbleFish: return "bubble_fish"
	if actor is ElectricSheep: return "electric_sheep"
	if actor is MagnetCrab: return "magnet_crab"
	if actor is Cactus: return "cactus"
	if actor is ShellTurtle: return "shell_turtle"
	if actor is Crow: return "crow"
	if actor is UnluckyDuck: return "duck"
	if actor is ForgeRabbit: return "rabbit"
	return ""

func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.arena): return
	var arena: BattleArena=game.arena
	if arena.heroes.size()!=2: return
	img(ROOT+"ui/environment/screen_surround.png",Rect2(0,0,1100,780))
	img(ROOT+"ui/environment/arena_wood_frame.png",Rect2(190,80,720,620))
	img(ROOT+"ui/environment/arena_floor.png",Rect2(200,90,700,600))
	for egg in arena.eggs:
		if egg.exploded:
			draw_circle(ORIGIN+egg.position,egg.blast_radius,Color(1,0.55,0.22,maxf(0.0,egg.blast_left)*1.2))
		else:
			var name := "egg_large_" if egg.large else "egg_small_"
			name += "armed.png" if egg.armed else "rest.png"
			centered(ROOT+"characters/chicken/objects/"+name,ORIGIN+egg.position,0.65 if egg.large else 0.45)
			if egg.armed: label("%.1f"%egg.fuse,ORIGIN+egg.position+Vector2(-12,-22),14)
	for bubble in arena.bubbles:
		var bucket := 1 if bubble.level==1 else 2
		var bpath := ROOT+"characters/bubble_fish/objects/bubble_level_%d.png"%bucket
		var fade: float=exp(-0.19*log(float(bubble.level))/log(2.0))
		var base_fade: float=exp(-0.19*log(float(bucket))/log(2.0))
		var r: float=(10.0+148.0*fade)/(10.0+148.0*base_fade)
		var g: float=(44.0+161.0*fade)/(44.0+161.0*base_fade)
		var b: float=(61.0+153.0*fade)/(61.0+153.0*base_fade)
		centered(bpath,ORIGIN+bubble.position,bubble.size_radius()/32.0,Vector2(48,48),false,Color(r,g,b))
		if bubble.absorb_left>0: draw_arc(ORIGIN+bubble.position,105,0,TAU,48,Color(0.4,0.7,0.8,0.35),1.5)
		label(str(bubble.level),ORIGIN+bubble.position+Vector2(-6,5),14)
	for nail in arena.nails:
		centered(ROOT+"characters/magnet_crab/objects/nail_"+("rest.png" if nail.mode=="rest" else "moving.png"),ORIGIN+nail.position,0.42)
	for actor in arena.heroes:
		if actor is ElectricSheep:
			if actor.wool_active: centered(ROOT+"characters/electric_sheep/objects/wool.png",ORIGIN+actor.wool_position,0.65)
			if actor.zapping:
				var enemy: Fighter=arena.enemy_of(actor)
				for pos in [actor.position,actor.wool_position]:
					if pos == actor.wool_position and not actor.wool_active: continue
					if pos.distance_to(enemy.position)<=ElectricSheep.RANGE+enemy.radius: draw_line(ORIGIN+pos,ORIGIN+enemy.position,Color("f0c43c"),3)
		elif actor is Cactus:
			for thorn in actor.thorns: centered(ROOT+"characters/cactus/objects/thorn.png",ORIGIN+thorn,0.4)
		elif actor is MagnetCrab and actor.wall_flash>0:
			var start: Array=[Vector2.ZERO,Vector2(700,0),Vector2.ZERO,Vector2(0,600)]
			var finish: Array=[Vector2(0,600),Vector2(700,600),Vector2(700,0),Vector2(700,600)]
			draw_line(ORIGIN+start[actor.magnetic_wall],ORIGIN+finish[actor.magnetic_wall],Color("e77d65"),5)
		elif actor is Crow:
			for dummy in actor.dummies:
				centered(ROOT+"characters/crow/objects/dummy.png",ORIGIN+dummy.position,0.85,Vector2(48,56))
				draw_rect(Rect2(ORIGIN+dummy.position+Vector2(-20,-38),Vector2(40,4)),Color("a98463"))
				draw_rect(Rect2(ORIGIN+dummy.position+Vector2(-20,-38),Vector2(40*dummy.health/dummy.max_health,4)),Color("83c899"))
		elif actor is ShellTurtle and actor.shell:
			if actor.shell.spin_left>0:
				strip(ROOT+"characters/shell_turtle/animations/shell_markings_spin/strip.png",ORIGIN+actor.shell.position,int(arena.simulation_time/0.12)%12,Vector2(48,48),0.9)
			else: centered(ROOT+"characters/shell_turtle/objects/shell_rest.png",ORIGIN+actor.shell.position,0.9)
		elif actor is UnluckyDuck:
			for rod in actor.rods: centered(OLD+"characters/props/lightning_rod.png",ORIGIN+rod,0.75,Vector2(48,82))
			if actor.cloud_holder:
				var cloud: Vector2=ORIGIN+actor.cloud_holder.position+Vector2(0,-45)
				cloud.x=clampf(cloud.x,238,862); cloud.y=maxf(110,cloud.y)
				var t:=tex(OLD+"vfx/cloud_idle_strip.png")
				if t: draw_texture_rect_region(t,Rect2(cloud-Vector2(64,68),Vector2(128,80)),Rect2((int(arena.simulation_time/0.16)%6)*128,0,128,80))
				label("%.1f"%actor.storm_left,cloud+Vector2(-15,-20),16)
			if actor.lightning_flash>0: draw_line(ORIGIN+actor.strike_position-Vector2(0,90),ORIGIN+actor.strike_position,Color("efc65b"),5)
	for actor in arena.heroes:
		draw_actor(actor,arena.simulation_time)
	img(ROOT+"ui/control_strip.png",Rect2(480,706,600,58))
	for i in 2: draw_panel(arena.heroes[i],i)
	if arena.finished: label(arena.result,Vector2(210,741),18)
	if info_open:
		draw_rect(Rect2(280,210,540,280),Color("f7ebcd"))
		draw_rect(Rect2(280,210,540,280),Color("243746"),false,3)
		label("种子 %d   时间 %.1f 秒"%[game.match_seed,arena.simulation_time],Vector2(305,255),20)
		for i in 2:
			var a:=arena.heroes[i]
			var names:=a.skill_names()
			label("%s   %s / %s"%[a.title,names[0],names[1]],Vector2(305,305+i*55),16)

func draw_actor(actor: Fighter,time: float) -> void:
	if actor is ShellTurtle and actor.action=="hidden": return
	var id:=actor_id(actor)
	if id.is_empty(): return
	var flip:=actor.velocity.x < 0
	var damaged:=float(blink_left.get(actor,0.0))>0
	var at:=ORIGIN+actor.position
	if actor is UnluckyDuck or actor is ForgeRabbit:
		var file:="idle_strip.png"
		var frames:=4
		var frame:=int(time/0.16)%4
		if actor is ForgeRabbit and rabbit_hit_left>0:
			file="hit_recover_strip.png"
			var elapsed:=0.42-rabbit_hit_left
			frame=0 if elapsed<0.07 else (1 if elapsed<0.15 else (2 if elapsed<0.26 else 3))
		elif actor is ForgeRabbit and actor.action=="forge":
			file="forge_strip.png"; frames=6; frame=int(time/0.12)%6
		elif actor is ForgeRabbit and actor.temper_left>0:
			file="temper_strip.png"; frame=int(time/0.14)%4
		elif actor is UnluckyDuck and damaged:
			file="impact_strip.png"; frame=mini(3,int((0.24-float(blink_left.get(actor,0.0)))/0.09))
		strip(OLD+"characters/"+id+"/"+file,at,frame,Vector2(48,56),1.0,flip)
		return
	var base:=ROOT+"characters/"+id+"/"
	var pivots: Dictionary={"puffer":Vector2(48,48),"chicken":Vector2(44,56),"bubble_fish":Vector2(52,52),"electric_sheep":Vector2(42,44),"magnet_crab":Vector2(48,56),"cactus":Vector2(48,56),"shell_turtle":Vector2(48,56),"crow":Vector2(48,56)}
	var scales: Dictionary={"puffer":1.2,"chicken":1.0,"bubble_fish":0.86,"electric_sheep":1.0,"magnet_crab":0.86,"cactus":0.77,"shell_turtle":0.92,"crow":0.92}
	var pivot: Vector2=pivots[id]
	var scale_value: float=scales[id]
	var path:=base+("hurt.png" if damaged else "idle.png")
	if actor is Puffer:
		var ratio: float=clampf(actor.gas/100.0,0.0,1.0)
		var sample := 0 if ratio < 0.20 else (40 if ratio < 0.45 else (50 if ratio < 0.75 else 100))
		path=base+"gas_samples/gas_%03d%s.png"%[sample,"_blink" if damaged and actor.immune_left<=0 else ""]
		scale_value=1.2*(1.0+ratio)/(1.0+sample/100.0)
		centered(path,at,scale_value,pivot,flip)
		if actor.immune_left>0: centered(base+"objects/"+("absorb_segments_burst.png" if actor.action=="burst" else "absorb_segments.png"),at,scale_value,pivot,flip)
		return
	if actor is Chicken:
		if actor.action=="lay": path=base+("poses/lay_hurt.png" if damaged else "poses/lay.png")
		elif actor.action=="run":
			strip(base+("animations/panic_run_blink/strip.png" if damaged else "animations/panic_run/strip.png"),at,int(time/0.12)%4,pivot,scale_value,flip)
			return
	if actor is Crow and actor.feather: path=base+("poses/feather_stored_hurt.png" if damaged else "poses/feather_stored.png")
	if actor is Cactus and flower_left>0: path=base+("poses/flower_lit_hurt.png" if damaged else "poses/flower_lit.png")
	centered(path,at,scale_value,pivot,flip)

func draw_panel(actor: Fighter,index: int) -> void:
	var x:=10 if index==0 else 930
	var id:=actor_id(actor)
	img(ROOT+"ui/status_panel.png",Rect2(x,90,160,600))
	var image_path: String=(OLD+"characters/"+id+"/default.png") if actor is UnluckyDuck or actor is ForgeRabbit else (ROOT+"characters/"+id+"/idle.png")
	img(image_path,Rect2(x+56,110,48,48))
	img(ROOT+"ui/icon_heart_display20.png",Rect2(x+14,195,20,20))
	label("%d"%ceili(actor.health),Vector2(x+42,212),20)
	img(ROOT+"ui/hp_track.png",Rect2(x+14,226,132,9))
	draw_rect(Rect2(x+16,228,128*clampf(actor.health/actor.max_health,0,1),5),Color("efc65b") if index==0 else Color("b89acf"))
	var icon_pairs: Dictionary={"bubble_fish":["icon_vacuum_28.png","icon_eight_28.png"],"electric_sheep":["icon_wall_28.png","icon_wool_28.png"],"shell_turtle":["icon_shell_28.png","icon_spin_28.png"],"crow":["icon_swap_28.png","icon_feather_28.png"]}
	var cds: Array=[actor.cd_one,actor.cd_two]
	for j in 2:
		var pos:=Vector2(x+14+j*70,414)
		img(ROOT+("ui/auto_skill_slot_ready.png" if cds[j]<=0 else "ui/auto_skill_slot.png"),Rect2(pos,Vector2(56,56)))
		if icon_pairs.has(id): img(ROOT+"ui/"+icon_pairs[id][j],Rect2(pos+Vector2(14,14),Vector2(28,28)))
		elif id=="duck" or id=="rabbit":
			var icon: String=(["icon_skill_timer.png","icon_skill_rod.png"] if id=="duck" else ["icon_skill_forge.png","icon_skill_temper.png"])[j]
			img(ROOT+"ui/retained/r02/"+icon,Rect2(pos+Vector2(12,12),Vector2(32,32)))
		else: label(str(j+1),pos+Vector2(21,35),20)
		if cds[j]>0: label("%.1f"%cds[j],pos+Vector2(12,76),15)
	if actor is Puffer: label("%d%%"%actor.gas,Vector2(x+52,305),20)
	elif actor is ElectricSheep: label("%d%%"%actor.charge,Vector2(x+52,305),20)
	elif actor is ForgeRabbit: label("%d"%actor.stored_damage,Vector2(x+52,305),20)
	elif actor is Crow: label("%d / 2"%actor.dummies.size(),Vector2(x+52,305),20)
	elif actor is UnluckyDuck: label("%.1f"%actor.storm_left,Vector2(x+52,305),20)
