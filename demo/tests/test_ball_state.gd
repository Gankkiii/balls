extends SceneTree
var failures := 0
var checks := 0
var cases := 0
var failed_cases := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func run_case(test: Callable) -> void:
	cases += 1
	var before := failures
	test.call()
	if failures != before:
		failed_cases += 1

func _initialize() -> void:
	call_deferred("run")

func test_defaults() -> void:
	var ball := Ball.new()
	check(ball.position == Vector2.ZERO, "default position")
	check(ball.velocity == Vector2.ZERO, "default velocity")
	check(ball.radius == 24.0, "default radius")
	check(ball.mass == 1.0, "default mass")
	var properties: Array = ball.get_script().get_script_property_list()
	check(not properties.any(func(property: Dictionary) -> bool: return property["name"] == "color"), "Ball does not store renderer colors")

func test_gameplay_defaults() -> void:
	var ball := Ball.new()
	check(ball.character_id == &"" and ball.character_definition == null, "character is unassigned")
	check(ball.instance_id == &"", "instance ID is assigned externally")
	check(ball.team_id == &"", "team is unassigned")
	check(ball.current_health == null and ball.max_health == null, "health has no invented initial value")
	check(ball.temporary_states.is_empty(), "no default temporary states")
	check(ball.skills.is_empty(), "no default skill associations")
	check(ball.skin_id == &"" and ball.appearance_definition == null, "appearance is unassigned")
	var temporary := BallTemporaryState.new()
	check(temporary.state_id == &"" and temporary.state_definition == null, "temporary-state definition is unassigned")
	check(temporary.runtime.is_empty(), "temporary-state runtime has no invented schema or values")
	var skill := BallSkillState.new()
	check(skill.skill_id == &"" and skill.skill_definition == null, "skill definition is unassigned")
	check(skill.runtime.is_empty(), "skill runtime has no invented schema or values")

func test_gameplay_storage() -> void:
	# These numbers/IDs are test fixtures, not gameplay defaults or decisions.
	var ball := Ball.new()
	ball.character_id = &"fixture_character"
	ball.character_definition = Resource.new()
	ball.instance_id = &"fixture_instance"
	ball.team_id = &"fixture_team"
	ball.skin_id = &"fixture_skin"
	ball.appearance_definition = Resource.new()
	ball.current_health = 0
	ball.max_health = 12.5
	check(ball.current_health != null and ball.current_health == 0, "zero health is distinct from unconfigured health")
	check(ball.max_health == 12.5, "external fractional health is stored exactly")
	ball.current_health = 20
	check(ball.current_health == 20 and ball.max_health == 12.5, "state does not clamp or invent health rules")
	check(ball.character_id == &"fixture_character" and ball.character_definition != null, "character association can be supplied")
	check(ball.instance_id == &"fixture_instance" and ball.team_id == &"fixture_team", "identity and team can be supplied")
	check(ball.skin_id == &"fixture_skin" and ball.appearance_definition != null, "appearance association can be supplied")
	ball.current_health = null
	ball.max_health = null
	check(ball.current_health == null and ball.max_health == null, "external owner can clear health back to unconfigured")

func test_instance_isolation() -> void:
	var first := Ball.new()
	var second := Ball.new()
	first.position = Vector2(50, 60)
	first.velocity = Vector2(10, -20)
	first.radius = 10
	first.mass = 2
	first.character_id = &"fixture_character"
	first.character_definition = Resource.new()
	first.instance_id = &"fixture_instance"
	first.team_id = &"fixture_team"
	first.current_health = 7
	first.max_health = 11
	first.skin_id = &"fixture_skin"
	first.appearance_definition = Resource.new()
	check(second.position == Vector2.ZERO, "positions are independent")
	check(second.velocity == Vector2.ZERO, "velocities are independent")
	check(second.radius == 24.0, "radii are independent")
	check(second.mass == 1.0, "masses are independent")
	check(second.character_id == &"" and second.character_definition == null, "character associations are independent")
	check(second.instance_id == &"" and second.team_id == &"", "identity and team are independent")
	check(second.current_health == null and second.max_health == null, "health values are independent")
	check(second.skin_id == &"" and second.appearance_definition == null, "appearance associations are independent")

func test_temporary_state_isolation() -> void:
	var first := Ball.new()
	var second := Ball.new()
	check(not is_same(first.temporary_states, second.temporary_states), "balls own separate temporary-state arrays")
	var definition := Resource.new()
	var left := BallTemporaryState.new()
	var right := BallTemporaryState.new()
	check(not is_same(left.runtime, right.runtime), "temporary-state records own separate runtime dictionaries")
	for state in [left, right]:
		state.state_id = &"fixture_state"
		state.state_definition = definition
		state.runtime[&"nested"] = {&"events": []}
	first.temporary_states.append(left)
	check(second.temporary_states.is_empty(), "appending a temporary state does not affect another ball")
	second.temporary_states.append(right)
	left.runtime[&"nested"][&"events"].append(&"fixture_event")
	left.runtime[&"fixture_value"] = 3
	check(right.runtime[&"nested"][&"events"].is_empty(), "nested temporary-state runtime does not leak across balls")
	check(not right.runtime.has(&"fixture_value"), "temporary-state runtime keys do not leak")
	check(is_same(left.state_definition, right.state_definition), "temporary-state definition may be shared read-only")
	first.temporary_states.clear()
	check(second.temporary_states.size() == 1, "clearing one temporary-state array leaves another intact")

func test_skill_state_isolation() -> void:
	var first := Ball.new()
	var second := Ball.new()
	check(not is_same(first.skills, second.skills), "balls own separate skill arrays")
	var definition := Resource.new()
	var left := BallSkillState.new()
	var repeated := BallSkillState.new()
	var right := BallSkillState.new()
	check(not is_same(left.runtime, repeated.runtime) and not is_same(left.runtime, right.runtime), "skill occurrences own separate runtime dictionaries")
	for skill in [left, repeated, right]:
		skill.skill_id = &"fixture_skill"
		skill.skill_definition = definition
		skill.runtime[&"nested"] = {&"events": []}
	first.skills.append(left)
	first.skills.append(repeated)
	check(second.skills.is_empty(), "appending skills does not affect another ball")
	second.skills.append(right)
	left.runtime[&"nested"][&"events"].append(&"fixture_event")
	left.runtime[&"fixture_value"] = 5
	check(repeated.runtime[&"nested"][&"events"].is_empty(), "repeated skill on the same ball has separate nested runtime")
	check(right.runtime[&"nested"][&"events"].is_empty(), "nested skill runtime does not leak across balls")
	check(not repeated.runtime.has(&"fixture_value") and not right.runtime.has(&"fixture_value"), "skill runtime keys do not leak")
	check(is_same(left.skill_definition, repeated.skill_definition) and is_same(left.skill_definition, right.skill_definition), "skill definitions may be shared read-only")
	first.skills.clear()
	check(second.skills.size() == 1, "clearing one skill array leaves another intact")

func test_shared_definitions() -> void:
	var first := Ball.new()
	var second := Ball.new()
	var character := Resource.new()
	var appearance := Resource.new()
	first.character_definition = character
	second.character_definition = character
	first.appearance_definition = appearance
	second.appearance_definition = appearance
	check(is_same(first.character_definition, second.character_definition), "balls may share read-only character definitions")
	check(is_same(first.appearance_definition, second.appearance_definition), "balls may share read-only appearance definitions")
	first.character_definition = null
	first.appearance_definition = null
	check(is_same(second.character_definition, character) and is_same(second.appearance_definition, appearance), "reassigning one ball's definition references does not affect another")

func test_state_only() -> void:
	for state in [Ball.new(), BallTemporaryState.new(), BallSkillState.new()]:
		check(state is RefCounted, "state uses reference-counted lifetime")
		check(not is_instance_of(state, Node), "state does not require a scene node")
		check(state.get_script().get_script_method_list().is_empty(), "state defines no behavior")
		check(state.get_script().get_script_signal_list().is_empty(), "collision notifications belong to Arena")

func gameplay_snapshot(ball: Ball) -> Dictionary:
	var states: Array = []
	for state in ball.temporary_states:
		states.append([state, state.state_id, state.state_definition, state.runtime.duplicate(true)])
	var skills: Array = []
	for skill in ball.skills:
		skills.append([skill, skill.skill_id, skill.skill_definition, skill.runtime.duplicate(true)])
	return {
		&"character_id": ball.character_id, &"character_definition": ball.character_definition,
		&"instance_id": ball.instance_id, &"team_id": ball.team_id,
		&"current_health": ball.current_health, &"max_health": ball.max_health,
		&"states": states, &"skills": skills,
		&"skin_id": ball.skin_id, &"appearance_definition": ball.appearance_definition,
	}

func test_external_system_boundaries() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.select_scenario(2)
	main.set_process(false)
	main.current_scenario.set_process(false)
	var first: Ball = main.current_scenario.arena.balls[0]
	var second: Ball = main.current_scenario.arena.balls[1]
	check(first.current_health == first.max_health and first.skills.size() == 1, "demo equips configured combat state")
	main.current_scenario.arena.combat_resolver = Callable()
	first.character_id = &"fixture_character"
	first.character_definition = BallConfig.new()
	first.instance_id = &"fixture_instance"
	first.team_id = &"fixture_team"
	first.current_health = 7
	first.max_health = 11
	first.skin_id = &"fixture_skin"
	first.appearance_definition = Resource.new()
	var temporary := BallTemporaryState.new()
	temporary.state_id = &"fixture_state"
	temporary.state_definition = Resource.new()
	temporary.runtime[&"nested"] = {&"values": [3, null]}
	first.temporary_states.append(temporary)
	var skill := BallSkillState.new()
	skill.skill_id = &"fixture_skill"
	skill.skill_definition = Resource.new()
	skill.runtime[&"nested"] = {&"values": [5, null]}
	first.skills.append(skill)
	var before := gameplay_snapshot(first)
	BallFactory.initialize_demo(main.current_scenario.arena.balls, main.current_scenario.arena.arena_size, 42)
	check(gameplay_snapshot(first) == before, "Factory initialization leaves gameplay data untouched")
	# Force both a wall and a pair collision without adding gameplay listeners.
	first.position = Vector2(first.radius + 1, 100)
	first.velocity = Vector2(-100, 0)
	second.position = Vector2(500, 500)
	second.velocity = Vector2.ZERO
	main.current_scenario.arena.step(0.02)
	check(first.velocity.x > 0, "boundary fixture exercises a wall collision")
	check(gameplay_snapshot(first) == before, "wall collisions do not apply damage or alter gameplay state")
	first.position = Vector2(100, 100)
	first.velocity = Vector2(100, 0)
	second.position = Vector2(150, 100)
	second.velocity = Vector2(-100, 0)
	main.current_scenario.arena.step(0.02)
	check(first.velocity.x < 0, "boundary fixture exercises a pair collision")
	check(gameplay_snapshot(first) == before, "pair collisions do not trigger skill or temporary-state rules")
	main.current_scenario.ball_renderer._process(1000)
	# Let the queued drawing callback run while simulation is disabled.
	await process_frame
	check(gameplay_snapshot(first) == before, "renderer callbacks leave all gameplay data untouched")
	main.current_scenario.arena.remove_ball(first)
	main.current_scenario.arena.register_ball(first)
	check(is_same(main.current_scenario.arena.balls.back(), first), "re-registration preserves the same gameplay state object")
	check(gameplay_snapshot(first) == before, "removal and re-registration preserve gameplay data")
	main.free()
	check(gameplay_snapshot(first) == before, "gameplay data can outlive the scene")

func test_registration() -> void:
	var arena := Arena.new()
	var ball := Ball.new()
	arena.register_ball(ball)
	arena.register_ball(ball)
	check(arena.balls.size() == 1, "registration is idempotent")
	check(is_same(arena.balls[0], ball), "Arena keeps the original state")
	check(arena.get_child_count() == 0, "simulation needs no rendering nodes")
	arena.remove_ball(ball)
	arena.remove_ball(ball)
	check(arena.balls.is_empty(), "removal is idempotent")
	check(is_instance_valid(ball), "removal does not destroy externally held state")
	arena.register_ball(ball)
	check(is_same(arena.balls[0], ball), "removed state can be registered again")
	arena.free()

func test_external_motion() -> void:
	var arena := Arena.new()
	var ball := Ball.new()
	ball.position = Vector2(100, 100)
	ball.velocity = Vector2(30, 40)
	arena.register_ball(ball)
	arena.step(1.0)
	check(ball.position == Vector2(130, 140), "Arena advances the stored position")
	check(ball.velocity == Vector2(30, 40), "unobstructed movement preserves velocity")
	arena.remove_ball(ball)
	arena.step(1.0)
	check(ball.position == Vector2(130, 140), "removed state is no longer simulated")
	arena.free()

func test_collision_notifications() -> void:
	var arena := Arena.new()
	var first := Ball.new()
	first.radius = 10
	first.position = Vector2(20, 100)
	first.velocity = Vector2(-100, 0)
	arena.register_ball(first)
	var wall_events: Array = []
	arena.wall_collided.connect(func(ball: Ball, normal: Vector2): wall_events.append([ball, normal]))
	arena.step(0.2)
	check(wall_events.size() == 1, "Arena emits one wall notification")
	if wall_events.size() == 1:
		check(is_same(wall_events[0][0], first), "wall notification identifies the ball")
		check(wall_events[0][1] == Vector2.RIGHT, "wall notification contains inward normal")
	var second := Ball.new()
	second.radius = 10
	first.position = Vector2(100, 100)
	first.velocity = Vector2(100, 0)
	second.position = Vector2(140, 100)
	second.velocity = Vector2(-100, 0)
	arena.register_ball(second)
	var pair_events: Array = []
	arena.ball_collided.connect(func(group: Array[Ball]): pair_events.append(group))
	arena.step(0.2)
	check(pair_events.size() == 1, "Arena emits one list notification for the collision group")
	if pair_events.size() == 1:
		check(is_same(pair_events[0][0], first) and is_same(pair_events[0][1], second), "pair notification identifies both balls")
	check(first.velocity == Vector2(-100, 0) and second.velocity == Vector2(100, 0), "notifications preserve elastic collision response")
	arena.free()

func test_renderer_binding() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.select_scenario(2)
	main.set_process(false)
	main.current_scenario.set_process(false)
	var arena: Arena = main.current_scenario.arena
	var renderer: BallRenderer = main.current_scenario.ball_renderer
	check(renderer.get_parent() == arena, "renderer uses arena-local coordinates")
	check(is_same(renderer.balls, arena.balls), "renderer reads the live state list")
	check(renderer.balls.size() == 2, "main scene creates two visible states")
	var first := arena.balls[0]
	check(renderer.display_color_for(first) == Color("50e0bd") and renderer.display_color_for(arena.balls[1]) == Color("ffb45f"), "renderer preserves demo ball colors")
	var at := first.position
	var motion := first.velocity
	renderer._process(1000)
	check(first.position == at and first.velocity == motion, "render updates do not advance simulation")
	arena.remove_ball(first)
	renderer._process(0)
	check(renderer.balls.size() == 1 and not renderer.balls.has(first), "renderer observes removal")
	arena.register_ball(first)
	check(renderer.balls.size() == 2 and is_same(renderer.balls[1], first), "renderer observes re-registration")
	check(renderer.display_color_for(first) == Color("50e0bd") and renderer.display_color_for(arena.balls[0]) == Color("ffb45f"), "renderer colors stay with balls after reordering")
	main.free()
	check(is_instance_valid(first), "state can outlive the main scene")

func test_renderer_color_isolation() -> void:
	var ball := Ball.new()
	var first := BallRenderer.new()
	var second := BallRenderer.new()
	check(first._display_colors.is_empty(), "renderer starts without per-ball colors")
	check(first.display_color_for(ball) == Color("55d6be"), "unconfigured ball uses renderer fallback color")
	check(first._display_colors.is_empty(), "reading fallback color does not mutate presentation state")
	first.set_display_color(ball, Color.RED)
	check(first.display_color_for(ball) == Color.RED, "renderer accepts a per-ball display color")
	first.set_display_color(ball, Color.BLUE)
	check(first.display_color_for(ball) == Color.BLUE, "renderer can replace an existing display color")
	check(first._display_colors.size() == 1, "replacing a display color does not accumulate records")
	check(second._display_colors.is_empty() and second.display_color_for(ball) == Color("55d6be"), "two views of the same ball have independent colors")
	check(ball.position == Vector2.ZERO and ball.velocity == Vector2.ZERO, "display colors do not alter ball motion")
	first.free()
	second.free()

func test_renderer_color_lifecycle() -> void:
	var arena := Arena.new()
	var renderer := BallRenderer.new()
	renderer.balls = arena.balls
	var survivor := Ball.new()
	var survivor_ref: WeakRef = weakref(survivor)
	arena.register_ball(survivor)
	renderer.set_display_color(survivor, Color.GREEN)
	arena.remove_ball(survivor)
	renderer._process(0)
	check(renderer.display_color_for(survivor) == Color.GREEN, "externally held removed ball keeps its presentation association")
	arena.register_ball(survivor)
	var released: Array[WeakRef] = []
	for i in 1000:
		var transient := Ball.new()
		released.append(weakref(transient))
		arena.register_ball(transient)
		renderer.set_display_color(transient, Color.RED)
		arena.remove_ball(transient)
		transient = null
	check(released.all(func(reference: WeakRef) -> bool: return reference.get_ref() == null), "renderer does not keep any of 1000 removed balls alive")
	check(renderer._display_colors.size() <= 2, "setting colors prunes expired records even without frame callbacks")
	renderer._process(0)
	check(renderer._display_colors.size() == 1, "frame cleanup removes expired records after repeated registration and removal")
	check(is_same(survivor_ref.get_ref(), survivor), "live registered ball survives presentation cleanup")
	check(renderer.display_color_for(survivor) == Color.GREEN, "live ball keeps its color during repeated registration and removal")
	arena.remove_ball(survivor)
	survivor = null
	check(survivor_ref.get_ref() == null, "final removed ball releases without waiting for presentation cleanup")
	renderer._process(0)
	check(renderer._display_colors.is_empty(), "renderer retains no color records after all balls are destroyed")
	renderer.free()
	arena.free()

func run() -> void:
	for test in [test_defaults, test_gameplay_defaults, test_gameplay_storage, test_instance_isolation, test_temporary_state_isolation, test_skill_state_isolation, test_shared_definitions, test_state_only, test_registration, test_external_motion, test_collision_notifications, test_renderer_binding, test_renderer_color_isolation, test_renderer_color_lifecycle]:
		run_case(test)
	# The renderer boundary test awaits a frame, so record it after completion.
	cases += 1
	var before := failures
	await test_external_system_boundaries()
	if failures != before:
		failed_cases += 1
	print("RESULT cases=%d passed=%d failed=%d checks=%d failures=%d" % [cases, cases - failed_cases, failed_cases, checks, failures])
	quit(1 if failures else 0)
