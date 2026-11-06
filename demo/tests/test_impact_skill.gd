extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
func _initialize() -> void:
	var a := Ball.new()
	var b := Ball.new()
	a.attack = 10
	var config := ImpactSkillConfig.new()
	check(ImpactSkill.damage(a, b, Vector2(200, 0), Vector2.ZERO, Vector2.RIGHT, config) == 10, "baseline damage")
	a.mass = 2
	check(ImpactSkill.damage(a, b, Vector2(200, 0), Vector2.ZERO, Vector2.RIGHT, config) == 20, "mass scales damage")
	a.mass = 1
	check(ImpactSkill.damage(a, b, Vector2(400, 0), Vector2.ZERO, Vector2.RIGHT, config) == 40, "speed squared")
	b.defense = 100
	check(ImpactSkill.damage(a, b, Vector2(200, 0), Vector2.ZERO, Vector2.RIGHT, config) == 5, "defense halves damage")
	b.defense = 0
	check(ImpactSkill.damage(a, b, Vector2(200, 0), Vector2(100, 0), Vector2.RIGHT, config) == 2.5, "pursuit limited by relative speed")
	check(ImpactSkill.damage(a, b, Vector2(0, 200), Vector2.ZERO, Vector2.RIGHT, config) == 0, "tangent causes no damage")
	check(ImpactSkill.damage(a, b, Vector2.ZERO, Vector2(-200, 0), Vector2.RIGHT, config) == 0, "stationary target does not retaliate")
	check(ImpactSkill.damage(a, b, Vector2(100, 0), Vector2(200, 0), Vector2.RIGHT, config) == 0, "separating causes no damage")
	for value in [0.0, -1.0, NAN, INF]:
		config.reference_speed = value
		check(not BallValidation.impact_config_error(config).is_empty(), "invalid skill rejected")
	print("IMPACT RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
