class_name CombatSystem
extends RefCounted
## 同刻事件先汇总伤害，再计算候选生命；不修改 Ball，不检测碰撞。
func resolve(events: Array) -> CombatResult:
	var result := CombatResult.new()
	var damage_by_ball: Dictionary = {}
	for event: CollisionEvent in events:
		if not event.confirmed or event.ball_b == null:
			continue
		for ball in [event.ball_a, event.ball_b]:
			var error := BallValidation.combat_ball_error(ball)
			if not error.is_empty():
				result.error = error
				return result
		for side in 2:
			var attacker: Ball = event.ball_a if side == 0 else event.ball_b
			var defender: Ball = event.ball_b if side == 0 else event.ball_a
			# 未配置生命的纯物理球不参与战斗；死亡球不造成后续伤害。
			if attacker.current_health == null or defender.current_health == null or attacker.current_health <= 0 or defender.current_health <= 0:
				continue
			for skill in attacker.skills:
				if skill.skill_id != &"impact":
					continue
				var config := skill.skill_definition as ImpactSkillConfig
				var error := BallValidation.impact_config_error(config)
				if not error.is_empty():
					result.error = error
					return result
				var amount := ImpactSkill.damage(attacker, defender, event.velocity_a_before if side == 0 else event.velocity_b_before, event.velocity_b_before if side == 0 else event.velocity_a_before, -event.normal if side == 0 else event.normal, config)
				if not is_finite(amount) or amount < 0.0:
					result.error = "Impact damage is not finite and nonnegative"
					return result
				if not damage_by_ball.has(defender):
					damage_by_ball[defender] = []
				damage_by_ball[defender].append(amount)
	for ball: Ball in damage_by_ball:
		# 固定累加顺序，避免事件排列改变浮点求和结果。
		var amounts: Array = damage_by_ball[ball]
		amounts.sort()
		var total := 0.0
		for amount in amounts:
			total += amount
		if not is_finite(total):
			result.error = "Total impact damage overflow"
			return result
		result.health[ball] = maxf(0.0, ball.current_health - total)
		if result.health[ball] == 0.0:
			result.dead.append(ball)
	return result
