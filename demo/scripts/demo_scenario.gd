class_name DemoScenario
extends Control

# 每个 balls_*.tscn 声明自己的数量、配置和 Arena 子场景。
# 共用初始化与播放逻辑，场景不依赖 main 或它的按钮。
const FIXED_DT := 1.0 / 120.0
# 在完整物理步之间检查；单个昂贵物理步仍可能超过预算。
const FRAME_BUDGET_USEC := 12000
@export_range(1, 100) var ball_count := 1
@export var ball_config: BallConfig
var arena: Arena
var ball_renderer: BallRenderer
var rate := 0
var accumulator := 0.0
var suspended := false
var scenario_seed := -1
var budget_limited := false

func _ready() -> void:
	arena = $Arena
	resized.connect(_fit_arena)
	ball_renderer = BallRenderer.new()
	ball_renderer.balls = arena.balls
	arena.add_child(ball_renderer)
	for i in ball_count:
		var ball := Ball.new()
		ball.character_definition = ball_config
		# 展示配色留在渲染层；两球仍使用原来的青绿与橙色。
		var color := Color.from_hsv(fmod(i * 0.61803398875, 1.0), 0.57, 0.95)
		if i < 2:
			color = Color("50e0bd") if i == 0 else Color("ffb45f")
		ball_renderer.set_display_color(ball, color)
		arena.register_ball(ball)
	scenario_seed = randi() if scenario_seed < 0 else scenario_seed
	arena.initialize_demo(scenario_seed)
	_fit_arena()
	set_rate(1)

func _fit_arena() -> void:
	if not is_instance_valid(arena):
		return
	var fit := minf(size.x / arena.arena_size.x, size.y / arena.arena_size.y)
	arena.scale = Vector2.ONE * fit
	arena.position = (size - arena.arena_size * fit) * 0.5

func set_rate(value: int) -> void:
	rate = value if value in [0, 1, 2] and arena.last_error.is_empty() else 0
	accumulator = 0.0

func advance_real_time(delta: float) -> void:
	if rate == 0 or suspended:
		return
	# 长卡顿不补算；完整步之间检查墙钟预算，避免大量积压阻挡触摸。
	accumulator += minf(delta, 0.1) * rate
	var start_usec := Time.get_ticks_usec()
	while accumulator + 1e-12 >= FIXED_DT:
		if not arena.step(FIXED_DT):
			set_rate(0)
			return
		accumulator -= FIXED_DT
		if Time.get_ticks_usec() - start_usec >= FRAME_BUDGET_USEC:
			budget_limited = true
			accumulator = 0.0
			break

func _process(delta: float) -> void:
	advance_real_time(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		accumulator = 0.0
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
		accumulator = 0.0
