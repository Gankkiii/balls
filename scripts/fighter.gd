class_name Fighter
extends Ball
## Shared fighter state; all durations use simulation seconds.
var health := 120.0
var max_health := 120.0
var cd_one := 0.0
var cd_two := 3.0
var action := "idle"
var action_left := 0.0
var stored_velocity := Vector2.ZERO
var world: Arena
var title := "Fighter"
var rng := RandomNumberGenerator.new()

func stationary() -> bool:
	return action == "inflate" or action == "lay"

func inverse_mass() -> float:
	return 0.0 if stationary() else 1.0 / mass

func begin_stationary(next_action: String) -> void:
	stored_velocity = velocity
	velocity = Vector2.ZERO
	action = next_action

func resume_motion() -> void:
	velocity = stored_velocity
	if velocity.length_squared() < 1:
		velocity = Vector2(150, 90)
	action = "idle"

func advance(dt: float) -> void:
	cd_one = maxf(0, cd_one - dt)
	cd_two = maxf(0, cd_two - dt)

func hit(damage: float, _self_blast: bool = false) -> void:
	health = maxf(0, health - damage)
	queue_redraw()

func skill_names() -> Array[String]:
	return ["Skill 1", "Skill 2"]

func state_name() -> String:
	return action
