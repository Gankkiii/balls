class_name Ball
extends RefCounted
## Pure runtime state. Arena changes it; BallRenderer only reads it.
## Position is in arena-local pixels, velocity in pixels per second.

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var radius: float = 24.0
var mass: float = 1.0
var color: Color = Color("55d6be")
