class_name CollisionSolver
extends RefCounted
## 联立求解同一时刻的无摩擦、完全弹性接触，不直接修改 Ball。
## 接触约定：normal 是作用在 a 上的单位法线，b == -1 表示固定墙。
## 这是一种明确选定的刚体多点冲击模型，不是所有真实材料的唯一解。

const VELOCITY_EPS := 1e-7
const FLOAT32_EPS := 1.1920928955078125e-7
const SOLVE_REL_EPS := 1e-11
const MAX_ITERATIONS := 4096
const MAX_WAVES := 128

static func resolve(balls: Array[Ball], contacts: Array) -> Dictionary:
	var input_error := BallValidation.solver_input_error(balls, contacts)
	if not input_error.is_empty():
		return {"ok": false, "error": input_error}
	var velocities := PackedFloat64Array()
	for ball in balls:
		velocities.append(ball.velocity.x)
		velocities.append(ball.velocity.y)
	var affected: Dictionary = {}
	for wave in MAX_WAVES:
		var incoming: Array = []
		var speeds := PackedFloat64Array()
		var has_impact := false
		for index in contacts.size():
			var contact: Dictionary = contacts[index]
			var speed := _normal_speed(contact, velocities)
			var tolerance := velocity_tolerance(contact.normal, velocities[2 * contact.a], velocities[2 * contact.a + 1], velocities[2 * contact.b] if contact.b >= 0 else 0.0, velocities[2 * contact.b + 1] if contact.b >= 0 else 0.0)
			if not is_finite(speed) or not is_finite(tolerance):
				return {"ok": false, "error": "Contact solver normal velocity exceeded numeric range"}
			if speed < -tolerance:
				has_impact = true
			# 静止接触也参与联立，以传递接触链与墙面的约束。
			if speed <= tolerance:
				incoming.append(index)
				speeds.append(speed)
		if not has_impact:
			if not BallValidation.solver_velocities_are_representable(velocities):
				return {"ok": false, "error": "Contact result is not representable as finite Vector2 velocities and squared speeds"}
			return {"ok": true, "velocities": velocities, "contacts": affected.keys()}
		var impulses := _solve_impulses(balls, contacts, incoming, speeds)
		if impulses.is_empty():
			return {"ok": false, "error": "Simultaneous contact solver did not converge or exceeded numeric range"}
		# 每轮从同一份速度快照求全部冲量，然后统一累加；不逐对改 Ball。
		var changes := PackedFloat64Array()
		changes.resize(velocities.size())
		for i in incoming.size():
			var impulse: float = impulses[i]
			if impulse <= 0.0:
				continue
			var index: int = incoming[i]
			var contact: Dictionary = contacts[index]
			affected[index] = true
			_accumulate(changes, contact.a, contact.normal, impulse / balls[contact.a].mass)
			if contact.b >= 0:
				_accumulate(changes, contact.b, contact.normal, -impulse / balls[contact.b].mass)
		for i in velocities.size():
			velocities[i] += changes[i]
			if not is_finite(velocities[i]):
				return {"ok": false, "error": "Contact solver velocity update exceeded numeric range"}
		# 原本分离的接触可能被整组冲击重新压紧，在同一时刻继续联立。
		# 外部在所有轮次结束前看不到中间态，也不会收到重复通知。
	return {"ok": false, "error": "Simultaneous contact wave safety limit reached"}

static func velocity_tolerance(normal: Vector2, ax: float, ay: float, bx: float = 0.0, by: float = 0.0) -> float:
	# Ball.velocity 是 float32 Vector2；double 解写回会产生几个 ULP 的法向残差。
	# CCD 与求解器共用此阈值，避免把舍入残差反复当成同刻新碰撞。
	var scale := absf(normal.x) * (absf(ax) + absf(bx)) + absf(normal.y) * (absf(ay) + absf(by))
	return VELOCITY_EPS + 4.0 * FLOAT32_EPS * scale

static func _accumulate(values: PackedFloat64Array, index: int, normal: Vector2, amount: float) -> void:
	values[2 * index] += normal.x * amount
	values[2 * index + 1] += normal.y * amount

static func _normal_speed(contact: Dictionary, velocities: PackedFloat64Array) -> float:
	var a: int = contact.a
	var b: int = contact.b
	var normal: Vector2 = contact.normal
	var x := velocities[2 * a]
	var y := velocities[2 * a + 1]
	if b >= 0:
		x -= velocities[2 * b]
		y -= velocities[2 * b + 1]
	return x * normal.x + y * normal.y

static func _coupling(left: Dictionary, right: Dictionary, balls: Array[Ball]) -> float:
	var weight := 0.0
	if left.a == right.a:
		weight += 1.0 / balls[left.a].mass
	if left.a == right.b:
		weight -= 1.0 / balls[left.a].mass
	if left.b >= 0:
		if left.b == right.a:
			weight -= 1.0 / balls[left.b].mass
		if left.b == right.b:
			weight += 1.0 / balls[left.b].mass
	var a: Vector2 = left.normal
	var b: Vector2 = right.normal
	# 显式 double 标量乘加，避免 Vector2.dot 的单精度累积误差。
	return weight * (float(a.x) * b.x + float(a.y) * b.y)

static func _solve_impulses(balls: Array[Ball], contacts: Array, incoming: Array, speeds: PackedFloat64Array) -> PackedFloat64Array:
	# A = J M^-1 J^T, u = J v。求 λ >= 0, Aλ + 2u >= 0,
	# λ·(Aλ + 2u) = 0：有冲量的接触恢复系数为 1，且不允许拉力。
	# 这也给出 ΔE = λ·u + 0.5 λ·Aλ = 0。
	var count := incoming.size()
	var scale := PackedFloat64Array()
	var rhs := PackedFloat64Array()
	var matrix: Array[PackedFloat64Array] = []
	var magnitude := 1.0
	for i in count:
		var contact: Dictionary = contacts[incoming[i]]
		var diagonal := _coupling(contact, contact, balls)
		if not is_finite(diagonal) or diagonal <= 0.0:
			return PackedFloat64Array()
		scale.append(sqrt(diagonal))
		rhs.append(2.0 * speeds[i] / scale[i])
		if not is_finite(rhs[i]):
			return PackedFloat64Array()
		magnitude = maxf(magnitude, absf(rhs[i]))
	var bound := 0.0
	for i in count:
		var row := PackedFloat64Array()
		var row_sum := 0.0
		for j in count:
			var value := _coupling(contacts[incoming[i]], contacts[incoming[j]], balls) / (scale[i] * scale[j])
			if not is_finite(value):
				return PackedFloat64Array()
			row.append(value)
			row_sum += absf(value)
		matrix.append(row)
		bound = maxf(bound, row_sum)
	if not is_finite(bound) or bound <= 0.0:
		return PackedFloat64Array()
	var scaled_impulses := PackedFloat64Array()
	scaled_impulses.resize(count)
	# 对角预调节的投影梯度。整轮同时更新，结果不依赖接触遍历顺序；
	# 行和上界保证步长安全，也允许冗余（奇异）接触约束。
	for iteration in MAX_ITERATIONS:
		var next := PackedFloat64Array()
		var residual := 0.0
		for i in count:
			var gradient := rhs[i]
			for j in count:
				gradient += matrix[i][j] * scaled_impulses[j]
			if not is_finite(gradient):
				return PackedFloat64Array()
			var violation := absf(gradient) if scaled_impulses[i] > 0.0 else maxf(0.0, -gradient)
			residual = maxf(residual, violation)
			var value := scaled_impulses[i] - gradient / bound
			if not is_finite(value):
				return PackedFloat64Array()
			next.append(maxf(0.0, value))
		if residual <= SOLVE_REL_EPS * magnitude:
			for i in count:
				scaled_impulses[i] /= scale[i]
				if not is_finite(scaled_impulses[i]):
					return PackedFloat64Array()
			return scaled_impulses
		scaled_impulses = next
	return PackedFloat64Array()
