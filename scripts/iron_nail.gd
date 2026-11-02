class_name IronNail
extends Node2D
var owner_fighter: Fighter
var mode := "rest"
var target := Vector2.ZERO
var velocity := Vector2.ZERO
var outward_left := 0.0
var gone := false
var hit_left := 0.0
const SPEED := 320.0
func advance(dt: float, world: Arena) -> void:
	hit_left = maxf(0, hit_left-dt)
	var old := position
	if mode == "wall" or mode == "return":
		if mode == "return":
			target = owner_fighter.position
		position = position.move_toward(target, SPEED*dt)
		if position.distance_to(target) < 0.01:
			if mode == "wall":
				mode = "return"
			else:
				if owner_fighter.repel_ready:
					owner_fighter.repel_ready = false
					var enemy: Fighter = world.enemy_of(owner_fighter)
					velocity = position.direction_to(enemy.position) * SPEED
					if velocity == Vector2.ZERO:
						velocity = Vector2.RIGHT * SPEED
					mode = "out"
					outward_left = 0.8
				else:
					gone = true
	elif mode == "out":
		position += velocity * minf(dt,outward_left)
		outward_left = maxf(0,outward_left-dt)
		position = position.clamp(Vector2(5,5),world.arena_size-Vector2(5,5))
		if outward_left == 0:
			mode = "rest"
	if old != position and hit_left <= 0:
		var enemy: Fighter = world.enemy_of(owner_fighter)
		var closest := Geometry2D.get_closest_point_to_segment(enemy.position,old,position)
		if closest.distance_to(enemy.position) <= enemy.radius + 5:
			enemy.hit(16)
			hit_left = 0.3
	queue_redraw()
func _draw() -> void:
	draw_line(Vector2(-6,-5),Vector2(6,5),Color("a3c5de") if mode == "rest" else Color("ffba70"),4)
	draw_line(Vector2(-9,-1),Vector2(-3,-9),Color("cadce9"),3)
