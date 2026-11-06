# 精简竞技场 Demo

Godot **4.6.3 stable** / GDScript。一个竞技场、两个球、1× / 2× / Pause 三个按钮；启动时暂停。这个 Demo 只展示状态、模拟和渲染的职责划分。角色、生命、临时状态、技能和外观已有数据字段与关联，但没有接入实际玩法，不包含伤害、技能执行或胜负规则。

## 运行

用 Godot 导入本目录的 `project.godot`，按 F5。点击 1× 或 2× 开始，Pause 暂停。切换倍率不改变速度向量，暂停后继续不会重新随机。

## 职责

- `scripts/ball.gd`：`Ball extends RefCounted`，保存运动、身份、生命、临时状态、技能和外观数据。没有初始化方法、碰撞方法、信号、绘制或逐帧回调，也不依赖场景树。
- `scripts/ball_temporary_state.gd` / `scripts/ball_skill_state.gd`：同样只含字段的 `RefCounted`，分别表示一个临时状态记录和一个技能关联及其运行态，不执行效果或技能。
- `scripts/arena.gd`：注册/移除球、设置初始状态、推进位置、处理碰撞，并发出 `wall_collided(ball, normal)` 和 `ball_collided(first, second)` 信号。球与球碰撞每对发一次通知。
- `scripts/ball_renderer.gd`：只读取竞技场共享的球列表并绘制，包含球的颜色、阴影和高光，不修改模拟状态。
- `scripts/main.gd`：组合 Arena 和 BallRenderer，创建两个 Ball，处理按钮及固定时间步。

`Ball.position` 是唯一权威位置，坐标相对于竞技场；位置和半径单位为逻辑像素，速度单位为像素/秒。Ball 不再是 Node2D，无需 `ball.tscn`，用 `Ball.new()` 创建。默认场地 640×680，球半径 24、质量 1、初始速率 140–230。

Ball 不做合法性修正，初始化和修改它的规则负责提供有效状态，例如正的半径和质量。渲染器与竞技场共享同一个数组；通过 `register_ball` / `remove_ball` 修改内容，不要另换一个数组而不更新渲染器。

## 新增的数据字段

这些字段是存储接口，不是已实现的战斗功能。`Main` 不为它们虚构初始值；`Arena.initialize`、移动和碰撞只处理原有模拟数据，`BallRenderer` 仍只按 `position`、`radius`、`color` 绘制，不解析皮肤。

- `character_id: StringName`：角色类型/配置标识；`character_definition: Resource`：对应的配置引用。多个球可以引用同一份角色配置。
- `instance_id: StringName`：这一个球的业务实例标识，与角色类型和 Godot 的 `Object.get_instance_id()` 不同；唯一性和分配由外部创建流程负责，`Ball.new()` 不自动生成。
- `team_id: StringName`：所属队伍标识。未指定阵营列表，也不决定友伤或同队是否碰撞；注册/移除仍按对象本身识别，不按这些标识去重。
- `current_health: Variant` / `max_health: Variant`：当前/最大生命。默认都是 `null`，表示尚未配置，**不等于 0 生命或死亡**。外部规则决定使用整数或浮点数、有效范围、初始值及变更；这里只原样存储，不钳制、不自动补满、不推导存活状态。`Variant` 本身不会阻止写入其他类型，正确类型也由外部提供。
- `temporary_states: Array[BallTemporaryState]`：当前关联的临时状态记录。每条含 `state_id: StringName`、`state_definition: Resource` 和 `runtime: Dictionary`。外部系统决定是否有持续时间、层数等字段，负责添加、更新和移除；这里不定义效果、叠加或过期规则。
- `skills: Array[BallSkillState]`：技能关联列表。每条含 `skill_id: StringName`、`skill_definition: Resource` 和 `runtime: Dictionary`，把一个关联与其运行态放在同一条记录中，不需要维护平行数组。相同技能定义可以有多条独立记录；记录对象代表本球的这一次关联。外部系统决定运行态是否包含冷却、次数等字段，这里不指定数值、不计时、不触发技能。
- `skin_id: StringName` / `appearance_definition: Resource`：皮肤标识与外观配置引用。与已有 `color` 并存，只保存关联，不加载资源、不改变画面，也不规定颜色与皮肤的优先级。

所有新增标识默认 `&""`（未分配），所有配置引用默认 `null`（未关联），两个数组和各记录的 `runtime` 默认空。空运行态表示没有提供运行数据，不等于技能已就绪、被禁用或状态已过期。`Resource` 是无具体配置结构的引用占位；标识与引用如何解析、匹配及校验由外部配置层负责。原始出场位置、初始方向/角度属于开战配置，未在球里重复保存第二份权威状态。

### 可变状态的归属

- 每次 `Ball.new()` 都有独立的两个数组；每次 `BallTemporaryState.new()` / `BallSkillState.new()` 都有独立的 `runtime` 字典。每个球、每次临时状态/技能关联必须创建新记录。即使共享同一份定义，也不共享可变运行态。
- 配置/外观 `Resource` 可以有意共享，外部使用方应将它们视为只读。这里不冻结资源，不隐式复制对象。
- GDScript 的数组、字典和 `RefCounted` 都有引用语义。直接把另一个球的数组、记录或嵌套容器赋过来，会主动制造共享；字段声明不能阻止这种外部赋值。浅复制也不能隔离嵌套状态。
- 从模板创建实例时，为每次关联创建新记录。若模板运行态只含值和数组/字典，可用 `template_runtime.duplicate(true)` 深复制嵌套容器；其中若含 `Object` / `Resource`，仍需外部明确决定共享只读定义还是另建可变实例。不要用数组的深复制代替新建记录对象。
- 移除、重新注册或销毁场景都不会清空外部仍持有的球及其运行态。重置、存档、销毁关联等生命周期规则留给外部系统。

## 模拟边界

- 无重力、摩擦或阻尼，墙和球采用完全弹性碰撞。保留原有解析连续碰撞检测（CCD），不同时使用刚体引擎。
- 固定步长为 1/120 秒，倍率仅决定推进的步数。球间碰撞保持总动量和总动能；碰固定墙不保持两球系统总动量。
- 每个子步最多处理 128 次碰撞，超限会报错并丢弃剩余子步。当前初始化仅针对两个球，不承诺任意拥挤多体系统。
- 后台/失焦停止推进，单次渲染回调最多接收 0.1 秒，长卡顿不会补算大量时间。
- 使用浮点运算，不承诺跨 CPU 或引擎版本位级一致。

## 自动测试

在本目录运行：

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_ball_state.gd
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 5
```

第一份测试验证纯状态对象、未配置语义、字段读写、实例/嵌套容器独立性、共享定义、注册/移除、碰撞通知、渲染绑定，以及模拟和渲染不修改新增数据；第二份保留原物理和主场景控制回归。测试中的示例标识和数值仅为测试夹具，不是玩法默认值。检查退出码和输出中的脚本错误，不要仅看退出码。最新执行结果见 `TEST_RESULTS.md`。

此目录不包含 Android 构建、旧战斗工程或自动 CI 配置。无界面测试不等于画面、触屏或真机验证。
