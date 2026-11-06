class_name BallSkillState
extends RefCounted
## One skill association on one Ball. Data only, no casting or cooldown logic.
## Multiple records may reference the same definition with separate runtime.

var skill_id: StringName = &""
var skill_definition: Resource = null
# External systems decide the schema, including whether cooldown/charges exist.
# Empty means no runtime values have been supplied, not ready/disabled.
var runtime: Dictionary = {}
