class_name ImpactSkill
extends RefCounted
## 只计算单向伤害；direction 从攻击者指向防守者，速度来自碰前快照。
static func damage(attacker: Ball, defender: Ball, velocity: Vector2, target_velocity: Vector2, direction: Vector2, config: ImpactSkillConfig) -> float:
	var toward := float(velocity.x) * direction.x + float(velocity.y) * direction.y
	var target_toward := float(target_velocity.x) * direction.x + float(target_velocity.y) * direction.y
	var speed := minf(maxf(0.0, toward), maxf(0.0, toward - target_toward))
	var ratio := speed / config.reference_speed
	return attacker.attack * (attacker.mass / config.reference_mass) * ratio * ratio / (1.0 + defender.defense / config.defense_scale)
