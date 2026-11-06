class_name Ball
extends RefCounted
## Pure runtime state. Arena changes motion; BallRenderer only reads it.
## Position is in arena-local pixels, velocity in pixels per second.
## Gameplay fields are storage only; no battle rules or defaults are implied.

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var radius: float = 24.0
var mass: float = 1.0
var color: Color = Color("55d6be")

# External configuration/creation owns IDs and references. Empty IDs and null
# references mean unassigned, not a particular character, team, or appearance.
var character_id: StringName = &""
var character_definition: Resource = null
var instance_id: StringName = &""
var team_id: StringName = &""

# Variant permits null (unconfigured) or a number supplied by external rules.
# No initial HP, clamping, alive/dead derivation, healing, or damage lives here.
var current_health: Variant = null
var max_health: Variant = null

# New arrays belong to this Ball. Create a new record for each occurrence;
# shared definition Resources are allowed, shared mutable runtime records are not.
var temporary_states: Array[BallTemporaryState] = []
var skills: Array[BallSkillState] = []

var skin_id: StringName = &""
var appearance_definition: Resource = null
