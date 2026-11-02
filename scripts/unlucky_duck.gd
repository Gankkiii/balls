class_name UnluckyDuck
extends Fighter
const STORM_DURATION := 7.0
const LIGHTNING_DAMAGE := 32.0
var cloud_holder: Fighter
var storm_left := STORM_DURATION
var rods: Array[Vector2] = []
var lightning_flash := 0.0
var strike_position := Vector2.ZERO
func _init() -> void:
	title = "UNLUCKY DUCK"
	color = Color("ffe378")
	cd_one = 3
	cd_two = 2
	ball_collided.connect(contact)
func contact(other: Ball) -> void:
	if world != null and other == world.enemy_of(self):
		cloud_holder = other if cloud_holder == self else self
func advance(dt: float) -> void:
	super.advance(dt)
	if cloud_holder == null:
		cloud_holder = self
	lightning_flash = maxf(0,lightning_flash-dt)
	storm_left -= dt
	if storm_left <= 0:
		strike()
	if cd_one <= 0:
		storm_left += 2 if cloud_holder == self else -2
		cd_one = 6
		if storm_left <= 0:
			strike()
	if cd_two <= 0 and rods.size() < 2:
		rods.append(position)
		cd_two = 6
	queue_redraw()
func strike() -> void:
	if cloud_holder == null:
		cloud_holder = self
	strike_position = cloud_holder.position
	lightning_flash = 0.25
	var protected := false
	for i in rods.size():
		if rods[i].distance_to(cloud_holder.position) <= 100:
			rods.remove_at(i)
			protected = true
			break
	if not protected:
		cloud_holder.hit(LIGHTNING_DAMAGE)
	cloud_holder = self
	storm_left = STORM_DURATION
func skill_names() -> Array[String]:
	return ["CHANGE TIMER","LIGHTNING ROD"]
func _draw() -> void:
	draw_circle(Vector2.ZERO,23,color)
	draw_circle(Vector2(12,-15),13,color)
	draw_colored_polygon(PackedVector2Array([Vector2(22,-18),Vector2(38,-12),Vector2(22,-8)]),Color("ffa74a"))
	draw_circle(Vector2(16,-19),3,Color("24354c"))
