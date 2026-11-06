# 精简竞技场 Demo

Godot **4.6.3 stable** / GDScript。一个竞技场、两个球、1× / 2× / Pause 三个按钮；启动时暂停。这个 Demo 只展示状态、模拟和渲染的职责划分。角色、生命、临时状态、技能和外观已有数据字段与关联，但没有接入实际玩法，不包含伤害、技能执行或胜负规则。

## 运行

用 Godot 导入本目录的 `project.godot`，按 F5。点击 1× 或 2× 开始，Pause 暂停。切换倍率不改变速度向量，暂停后继续不会重新随机。

## 职责

- `scripts/ball.gd`：`Ball extends RefCounted`，保存运动、身份、生命、临时状态、技能和外观数据。没有初始化方法、碰撞方法、信号、绘制或逐帧回调，也不依赖场景树。
- `scripts/ball_temporary_state.gd` / `scripts/ball_skill_state.gd`：同样只含字段的 `RefCounted`，分别表示一个临时状态记录和一个技能关联及其运行态，不执行效果或技能。
- `scripts/arena.gd`：注册/移除球、设置初始状态、推进位置、处理碰撞，并发出 `wall_collided(ball, normal)` 和 `ball_collided(colliding_balls: Array[Ball])` 信号。同一时刻的球间碰撞只发一次去重列表通知，见下文。
- `scripts/collision_solver.gd`：从同一份速度快照联立求同刻接触冲量，返回整批结果，不直接修改 Ball。
- `scripts/ball_config.gd` / `configs/default_ball.tres`：简单球配置及 Demo 默认资源，当前只定义初始速率范围。
- `scripts/ball_renderer.gd`：只读取竞技场共享的球列表并绘制，包含球的颜色、阴影和高光，不修改模拟状态。Demo 配色通过渲染器的 `set_display_color` 设置，`Ball` 不再定义 `color`。
- `scripts/main.gd`：组合 Arena 和 BallRenderer，创建两个 Ball，处理按钮及固定时间步。

`Ball.position` 是唯一权威位置，坐标相对于竞技场；位置和半径单位为逻辑像素，速度单位为像素/秒。Ball 不再是 Node2D，无需 `ball.tscn`，用 `Ball.new()` 创建。默认场地 640×680，球半径 24、质量 1、初始速率 140–230。

Ball 不做合法性修正，初始化和修改它的规则负责提供有效状态，例如正的半径和质量。渲染器与竞技场共享同一个数组；通过 `register_ball` / `remove_ball` 修改内容，不要另换一个数组而不更新渲染器。

## 新增的数据字段

这些字段是存储接口，不是已实现的战斗功能。`Main` 只为 `character_definition` 显式关联默认 `BallConfig`，不为其他玩法字段虚构初始值；`Arena.initialize`、移动和碰撞只处理原有模拟数据，`BallRenderer` 只从 Ball 读取 `position`、`radius`，颜色由渲染器自己的展示配置提供，暂不解析皮肤。

- `character_id: StringName`：角色类型/配置标识；`character_definition: Resource`：对应的配置引用。多个球可以引用同一份角色配置；当前 Demo 使用 `BallConfig`，见初始速率配置。
- `instance_id: StringName`：这一个球的业务实例标识，与角色类型和 Godot 的 `Object.get_instance_id()` 不同；唯一性和分配由外部创建流程负责，`Ball.new()` 不自动生成。
- `team_id: StringName`：所属队伍标识。未指定阵营列表，也不决定友伤或同队是否碰撞；注册/移除仍按对象本身识别，不按这些标识去重。
- `current_health: Variant` / `max_health: Variant`：当前/最大生命。默认都是 `null`，表示尚未配置，**不等于 0 生命或死亡**。外部规则决定使用整数或浮点数、有效范围、初始值及变更；这里只原样存储，不钳制、不自动补满、不推导存活状态。`Variant` 本身不会阻止写入其他类型，正确类型也由外部提供。
- `temporary_states: Array[BallTemporaryState]`：当前关联的临时状态记录。每条含 `state_id: StringName`、`state_definition: Resource` 和 `runtime: Dictionary`。外部系统决定是否有持续时间、层数等字段，负责添加、更新和移除；这里不定义效果、叠加或过期规则。
- `skills: Array[BallSkillState]`：技能关联列表。每条含 `skill_id: StringName`、`skill_definition: Resource` 和 `runtime: Dictionary`，把一个关联与其运行态放在同一条记录中，不需要维护平行数组。相同技能定义可以有多条独立记录；记录对象代表本球的这一次关联。外部系统决定运行态是否包含冷却、次数等字段，这里不指定数值、不计时、不触发技能。
- `skin_id: StringName` / `appearance_definition: Resource`：皮肤标识与外观配置引用。只保存关联，不加载资源、不改变画面。`Ball` 不再保存 `color`；当前 Demo 配色仍由渲染器单独管理，尚未接入皮肤解析。

所有新增标识默认 `&""`（未分配），所有配置引用默认 `null`（未关联），两个数组和各记录的 `runtime` 默认空。空运行态表示没有提供运行数据，不等于技能已就绪、被禁用或状态已过期。角色配置目前已有 `BallConfig`，其他 `Resource` 仍是无具体配置结构的引用占位；标识与引用如何解析、匹配由外部配置层负责。原始出场位置、初始方向/角度属于开战配置，未在球里重复保存第二份权威状态。

### `character_id` 和 `character_definition` 的区别

- `character_id` 是角色配置的“名字/编号”，回答“这个球是哪种角色”。例如两个球都属于同一种角色，它们可以有相同的 `character_id`。
- `character_definition` 是实际角色配置对象的引用。可以理解为前者是“配置的名字”，后者是“配置内容的入口”。字段类型仍为 `Resource`，当前 Demo 实际关联 `BallConfig`，仅包含初始速率上下限；还没有添加其他角色配置项。
- `instance_id` 才是“场上具体哪一个球”的业务标识，由外部创建流程分配并保证唯一，不是角色类型标识。

ID 与配置引用不会自动同步或互相查找，是否匹配由外部配置层保证。两者不是必须同时存在的设计要求：保留 ID 可以用于后续配置查找或存档，保留引用可以直接访问配置，但这些用途现在还没有实现。Demo 通过直接引用 `.tres` 配置资源提供初始速率，没有按 ID 查找配置的逻辑。

`Ball`、`BallTemporaryState`、`BallSkillState` 中的每个字段均有紧邻声明的中文注释，说明含义、单位或未配置值。`color` 不参与物理模拟，已从 Ball 移至渲染层的 Demo 配色；渲染器按 Godot 对象 ID 保存“弱引用＋颜色”记录，并检查弱引用仍指向同一个球，不依赖列表顺序或业务 `instance_id`。外部仍持有的球移除后再注册会保留原配色；配色记录不强持有球，无其他引用时球会正常释放。设置配色和每帧更新都会清理已销毁球的记录，避免反复增删后累积。配色不作为玩法状态或皮肤配置。

### 可变状态的归属

- 每次 `Ball.new()` 都有独立的两个数组；每次 `BallTemporaryState.new()` / `BallSkillState.new()` 都有独立的 `runtime` 字典。每个球、每次临时状态/技能关联必须创建新记录。即使共享同一份定义，也不共享可变运行态。
- 配置/外观 `Resource` 可以有意共享，外部使用方应将它们视为只读。这里不冻结资源，不隐式复制对象。
- GDScript 的数组、字典和 `RefCounted` 都有引用语义。直接把另一个球的数组、记录或嵌套容器赋过来，会主动制造共享；字段声明不能阻止这种外部赋值。浅复制也不能隔离嵌套状态。
- 从模板创建实例时，为每次关联创建新记录。若模板运行态只含值和数组/字典，可用 `template_runtime.duplicate(true)` 深复制嵌套容器；其中若含 `Object` / `Resource`，仍需外部明确决定共享只读定义还是另建可变实例。不要用数组的深复制代替新建记录对象。
- 移除、重新注册或销毁场景都不会清空外部仍持有的球及其运行态。重置、存档、销毁关联等生命周期规则留给外部系统。

## 初始速率配置

初始速率现在由 `BallConfig` 保存，不再是 Arena 的导出字段。可在 Godot 编辑器打开 `configs/default_ball.tres` 调整：

- `min_initial_speed`：随机初始速率下限，单位像素/秒。
- `max_initial_speed`：随机初始速率上限。上下限相同表示固定速率，均为 0 表示静止出场。

默认资源仍为 **140–230**，没有改变原 Demo 的位置、随机方向、随机采样顺序或同种子的初始结果。`Main` 为两个球的 `character_definition` 显式关联这份资源；要逐球配置，可给不同的球关联不同 `BallConfig`。未关联（`null`）时 Arena 读取默认资源，但不会反向填写 Ball 的字段。

配置必须满足有限数值 `0 <= min_initial_speed <= max_initial_speed`，并且速率范围能转换为有限的单精度 `Vector2`、长度平方不溢出，正速率不下溢为零。这是数值表示边界，不是额外玩法限速。非空但不是 `BallConfig` 的角色配置，或不合法、不可表示的速率范围，会报错并取消整次初始化。Arena 先生成所有球的位置和速度并验证有限性，全部成功后才统一写回、重置计数；生成阶段失败同样不留下部分初始化的球。配置可以共享，Arena 只读取、不修改；修改配置只影响下次 `initialize`，不会追溯改变运行中的 `Ball.velocity`。本次未增加配置界面、方向配置或额外玩法规则。

## 同一时刻的碰撞

CCD 先找真正的最早碰撞时间，再把与它相差不超过 `TIME_EPS = 1e-9` 秒的候选收为一批。不同时间即使落在同一个 1/120 秒固定步里，也分别计算和通知。已经接触的静止球链和相关墙面一起参与约束；存在正间隙的非候选接触不会因“离得很近”而提前加入。

这批接触从同一份碰撞前速度计算耦合冲量，全部算完后一次性写回速度，再发送通知。互不相连的碰撞在方程中彼此独立，但它们处于同一时刻，所以仍合并到一个通知列表。不能将独立二球公式逐对套用，也不能将独立冲量简单相加。

### 通知接口

- `ball_collided(colliding_balls: Array[Ball])`：同一个碰撞时刻至多一次，包含所有发生实际球间冲量的 Ball，按对象去重。这是参与者列表，**不表示列表内任意两球都直接相撞**，也不保证排列顺序。
- 两球碰撞时列表长度为 2；三球连锁碰撞通常为 3；两组互不相连的二球在同刻碰撞则一次通知 4 个参与者。仅碰墙、静止无冲量和无关球不混入此列表。
- `wall_collided(ball, normal)` 保持原接口；每个实际有冲量的墙接触发一次，角落可能有两个法线。原本静止贴墙的球若通过同刻球间冲量受墙约束，也会通知。
- 所有回调开始前，整批球和墙的速度结果都已写回。通知数组独立于 `Arena.balls`；列表内仍是原 Ball 引用。监听者应将进一步物理修改排到通知结束后，避免后一个监听者读到前一个监听者主动改写的状态。

原先连接两个参数的回调必须迁移为一个列表参数，例如：

```gdscript
func _on_ball_collided(colliding_balls: Array[Ball]) -> void:
    for ball in colliding_balls:
        print(ball.instance_id)
```

### 选定的多体冲击模型

无摩擦，恢复系数为 1，不允许接触产生拉力。设碰前法向速度为 `u = Jv`、接触耦合矩阵为 `A = J M^-1 Jᵀ`，联立求非负冲量 `λ`，使 `Aλ + 2u >= 0` 且 `λᵀ(Aλ + 2u) = 0`。用带对角预调节的投影迭代求解；每轮所有冲量同时更新，不按球对先后写回。原本分离的已有接触如果被整组冲击重新压紧，在同一时刻继续联立处理，结束后仍只通知一次。

在数值容差内，该约定保持动能；不碰墙时保持系统总动量。**三个及以上刚体同时碰撞，单靠守恒不足以选出唯一结果**。这是明确选定的模型，并非宣称真实材料都这样碰撞。例如三个等质量、已接触的直线球初速度为 `(v, 0, 0)` 时，本模型得到 `(-v/3, 2v/3, 2v/3)`，不是逐次二球碰撞常见的牛顿摆结果。对称的 `(v, 0, -v)` 则得到 `(-v, 0, v)`。

## 模拟边界

- 无重力、摩擦或阻尼，保留解析连续碰撞检测（CCD），不同时使用刚体引擎。
- 固定步长为 1/120 秒，倍率仅决定推进的步数；碰固定墙不保持球系统总动量。
- Godot 的 `Vector2` 为单精度。求解和 CCD 标量使用双精度，检测与求解共用随速度大小调整的容差，避免双精度结果写回后产生的微小负法向残差被误当成反复新碰撞。低于该容差的接近视为静止接触，不承诺任意微小速度或任意量级数据的精确表现。
- 初始位置应合法。已有轻微数值重叠不超过 `1e-4` 像素时不做顺序位置修正；较大的非法初始重叠仍沿用原修正，不承诺密集穿插状态的唯一结果。当前随机初始化仍只保证两个球合法放置；多球测试显式提供合法接触布局。
- 每个子步最多处理 128 个碰撞时刻；每批最多 128 轮同刻冲击，每轮求解最多 4096 次迭代。极端质量比、长接触链或密集病态布局可能不收敛；中间量和最终结果也需保持有限、可写回单精度状态。失败会显式报错，记录 `solver_failures`，不提交部分速度或发送该批通知，并丢弃剩余子步；`event_limit_hits` 单独记录 CCD 事件超限。失败前已经推进到的撞击位置和模拟时间仍保留。
- 后台/失焦停止推进，单次渲染回调最多接收 0.1 秒，长卡顿不会补算大量时间。
- 使用浮点运算，不承诺跨 CPU 或引擎版本位级一致。

## 自动测试

在本目录运行：

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_ball_state.gd
godot --headless --path . --script tests/test_ball_config.gd
godot --headless --path . --script tests/test_simultaneous_collisions.gd
godot --headless --path . --script tests/test_collision_solver_failure.gd
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 5
```

状态测试验证纯状态对象、字段与生命周期；配置测试验证默认兼容、逐球配置与原子拒绝；同刻碰撞测试覆盖对称三球、不同质量、静止链、独立组、墙与角落、时间容差、排列一致性、随机旋转接触链及守恒；原回归保留长时间二球物理与主场景控制。

配置测试故意触发 15 次错误日志，求解失败路径测试故意触发 4 次错误日志，分别有 `EXPECTED CONFIG ERROR` / `EXPECTED ERROR` 标记；它们用来确认错误配置、不收敛及数值溢出不会部分修改状态。其他测试不应有引擎/脚本错误。检查退出码、最终失败数和日志，不要仅看退出码。最新执行结果见 `TEST_RESULTS.md`。

此目录不包含 Android 构建、旧战斗工程或自动 CI 配置。无界面测试不等于画面、触屏或真机验证。
