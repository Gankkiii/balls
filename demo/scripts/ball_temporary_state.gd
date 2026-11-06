class_name BallTemporaryState
extends RefCounted
## One temporary-state occurrence on one Ball. Data only, no application/expiry.
## Definition references may be shared read-only. Runtime must remain local.

var state_id: StringName = &""
var state_definition: Resource = null
# External systems decide the schema, including whether duration/stacks exist.
# Empty means no runtime values have been supplied, not expired/inactive.
var runtime: Dictionary = {}
