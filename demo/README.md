# 精简竞技场 Demo

Godot **4.6.3 stable** / GDScript。一个竞技场、**1 / 2 / 5 / 20 / 100 球**五个可选场景，保留 1× / 2× / Pause，增加 Restart；启动默认进入 1 球并按 1× 运动。这个 Demo 只展示状态、模拟和渲染的职责划分。角色、生命、临时状态、技能和外观已有数据字段与关联，但没有接入实际玩法，不包含伤害、技能执行或胜负规则。

## 运行

用 Godot **4.6.3** 导入本目录的 `project.godot`，按 F5。顶部点选球数即可切换场景，下方用 1× / 2× / Pause 控制。鼠标和触摸使用同一组按钮。

- 入口为 `scenes/main.tscn`，默认加载 1 球场景。`balls_1.tscn`、`balls_2.tscn`、`balls_5.tscn`、`balls_20.tscn`、`balls_100.tscn` 是独立内容场景，各自声明球数、配置资源和 Arena 子节点，不再继承 main。可分别打开按 F6 预览自动运动；完整选择器和播放按钮在 F5 主页面中。选择按钮实际加载对应场景文件。
- 选场景会重新创建准确数量的球、生成新种子、重置模拟时间与错误，并从 1× 开始。重复点选也会重开，不会叠加球。
- Restart 使用当前种子重现初始位置和速度，并回到 1×；1× / 2× / Pause 只改变推进速率，不改变球的速度向量，不会重新随机。
- 100 球是重载演示，明确提示可能慢于真实时间；**不保证手机或电脑实时运行**。控制器每帧在完整的 1/120 秒物理步之间检查 12 ms 墙钟预算，超时丢弃积压，不缩小物理步长、不偷偷降低球速。单个物理步仍可能超过预算，所以这不是严格帧时上限，2× 也不保证在重载时达到真实时间两倍。
- 初始化/运行失败会暂停，在场地区显示可滚动的完整原因；不依赖鼠标悬停。仍可选择其他场景或 Restart 恢复。
- 以 Android **竖屏**为目标，720×1120 逻辑画布使用 expand 缩放，场地在剩余空间内等比适配。9 个按钮最小高度为 100 逻辑像素，320×568 竖屏约 44.4 像素。Android 安全区会转换成逻辑边距，避免刘海/系统栏遮住按钮。窄矮窗口和横屏不是触摸尺寸保证范围。

## Android 手机导出

`export_presets.cfg` 包含 **Android** 预设：普通 APK 导出、ARM64 + ARMv7、包名 `org.gankkiii.ballsdemo`、竖屏、不申请网络权限。没有签名密码、机器本地 SDK 路径或密钥写入仓库。构建输出 `build/` 已忽略。

1. 安装 Godot **4.6.3 stable**，在编辑器的“管理导出模板”安装**相同版本**的导出模板。
2. 安装完整 **OpenJDK 17**（不是只有 Java runtime）与 Android SDK，包括 Platform Tools、Build Tools 和对应 Android 平台。SDK 版本和组件以 [Godot 4.6 Android 导出文档](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html) 为准。
3. 在 Godot 的 Editor Settings → Export → Android 设置 Java SDK Path 和 Android SDK Path。需要 `adb`、`apksigner` 和可用的调试签名配置；这些属于本机环境，不提交到仓库。
4. **打开 `demo/project.godot`**，选择 Project → Export → Android → Export Project，勾选 Export With Debug，导出 `.apk`。也可从仓库根目录执行：

```bash
mkdir -p demo/build
godot --headless --path demo --export-debug Android build/balls-demo.apk
```

5. 将调试 APK 安装到允许安装该来源应用的 Android 手机上，或在已授权的 USB 调试设备上用 `adb install -r demo/build/balls-demo.apk`。打开后即可点选五个场景；先验证 1/2/5 球，再测 20/100 球、暂停/继续、重开和切后台恢复。

这是开发调试 APK 流程，不是应用商店发布配置。正式发布需自己的 release 签名和商店要求，不要把私钥或密码放进仓库。

本次环境缺 Android SDK、导出模板与完整 JDK，实际尝试导出后被这些缺项阻挡，**没有生成或验证 APK，也没有做 Android 真机测试**。已有预设不等于构建已成功。

## 职责

- `scripts/ball.gd`：`Ball extends RefCounted`，保存运动、身份、生命、临时状态、技能和外观数据。没有初始化方法、碰撞方法、信号、绘制或逐帧回调，也不依赖场景树。
- `scripts/ball_temporary_state.gd` / `scripts/ball_skill_state.gd`：同样只含字段的 `RefCounted`，分别表示一个临时状态记录和一个技能关联及其运行态，不执行效果或技能。
- `scripts/arena.gd`：注册/移除球、验证并设置初始状态、为 Demo 自动放置、推进位置、处理碰撞，并发出 `wall_collided(ball, normal)` 和 `ball_collided(colliding_balls: Array[Ball])` 信号。同一时刻的球间碰撞只发一次去重列表通知，见下文。
- `scripts/collision_solver.gd`：从同一份速度快照联立求同刻接触冲量，返回整批结果，不直接修改 Ball。
- `scripts/ball_config.gd` / `configs/default_ball.tres`：简单球配置及 Demo 默认资源，当前只定义初始速率范围。
- `scripts/ball_renderer.gd`：只读取竞技场共享的球列表并绘制，包含球的颜色、阴影和高光，不修改模拟状态。Demo 配色通过渲染器的 `set_display_color` 设置，`Ball` 不再定义 `color`。
- `scripts/main.gd`：页面外壳，加载和释放当前场景，处理选择、重启、播放按钮、错误提示和手机安全区布局。
- `scripts/demo_scenario.gd`：五个内容场景共用的脚本，负责创建球与渲染器、初始化种子、固定时间步、倍率、后台暂停和帧预算；不依赖 main，物理算法仍在 Arena 中。
- `scenes/balls_*.tscn`：每个场景自己的内容入口。修改某个场景的球数、配置或增加节点，在对应文件中完成；相同播放行为只维护一份 `demo_scenario.gd`。新增同类场景后，将它加入 main 的 `SCENES` 和 `SCENARIO_COUNTS` 即可加入选择器。

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

默认资源仍为 **140–230**。`initialize_demo` 保留原两球 Demo 合法布局的位置、随机方向、采样顺序和同种子的初始结果；更多球使用网格位置。`Main` 为场景内每个球的 `character_definition` 显式关联这份资源；要逐球配置，可给不同的球关联不同 `BallConfig`。未关联（`null`）时 Arena 读取默认资源，但不会反向填写 Ball 的字段。

配置必须满足有限数值 `0 <= min_initial_speed <= max_initial_speed`，并且速率范围能转换为有限的单精度 `Vector2`、长度平方不溢出，正速率不下溢为零。这是数值表示边界，不是额外玩法限速。非空但不是 `BallConfig` 的角色配置，或不合法、不可表示的速率范围，会报错并取消整次初始化。Arena 先生成所有球的位置和速度并验证有限性，全部成功后才统一写回、重置计数；生成阶段失败同样不留下部分初始化的球。配置可以共享，Arena 只读取、不修改；修改配置只影响下次 `initialize` 或 `initialize_demo`，不会追溯改变运行中的 `Ball.velocity`。本次未增加配置界面、方向配置或额外玩法规则。

## 初始位置与运行中纠正

- `initialize(seed_value, initial_positions)` 接收与 `balls` 顺序对应的位置数组，返回 `{ok, error}`。只验证玩家指定的位置，不自动调整。通过后一起写入位置、按各球 `BallConfig` 采样的速度，并重置时间和计数；失败保留全部球状态、配置引用和计数，仅更新 `last_error` 并输出错误。
- `validate_positions(positions)` 是只读检查，返回 `{ok, error}`。场地尺寸必须有限且为正；球不能为空或重复引用，半径必须有限、为正、可表示且直径不超过场地，质量必须有限且为正。位置必须是有限 `Vector2`。越界和两球重叠深度不得超过 `POSITION_EPS = 1e-4` 像素；容差内的位置原样保留，错误标明从 0 开始的球索引。初始化还验证速度配置与生成结果。
- `generate_demo_positions(seed_value)` 只生成位置，不修改球，返回 `{ok, positions}` 或 `{ok: false, error}`。原两球随机位置合法时保留；否则在有限数量的矩形网格中选择每格都能容纳最大球的一种。默认 640×680 场地可放置 100 个半径 24 的球。网格是保守的自动放置方法，失败不代表任意排列都不可能，尤其是半径差异很大时；可改用显式合法位置。
- `initialize_demo(seed_value)` 组合自动放置和整批初始化。五个 Demo 场景和原随机初始化测试共用此入口，没有增加玩法或改动默认速度。
- `_correct_positions()` 在临时位置数组中交替处理墙和球对，每轮复查全部约束，最多 512 轮。成功后才一次性提交，返回 `{ok, error, iterations}`；失败返回 `{ok: false, error}`，不写回任何尝试位置，也不改变速度。已经合法的状态不会漂移。质量权重先缩放，避免直接求倒数或质量和溢出。
- `step(dt)` 返回是否成功；位置、速度或时间无效、位置纠正不收敛时停止该次推进，增加 `position_failures` 并记录 `last_error`。在步首纠正失败时不会进入 CCD、推进时间或发出碰撞通知。碰撞求解和事件次数失败也返回 `false`；已经完成的碰撞和时间不回滚。主场景收到失败后暂停并显示原因，不反复推进失败状态。

这不是通用圆形装箱求解器，也不保证任意密集穿插布局都能纠正。`POSITION_EPS` 是绝对像素容差，不随球半径缩放；远小于该容差的球无法据此获得有意义的分离精度。迭代次数有上限不等于实时性能保证，密集非法布局可能用满预算。没有新增玩家摆球 UI；显式位置入口可供以后接入。

## 同一时刻的碰撞

CCD 先找真正的最早碰撞时间，再把与它相差不超过 `TIME_EPS = 1e-9` 秒的候选收为一批。不同时间即使落在同一个 1/120 秒固定步里，也分别计算和通知。已经接触的静止球链和相关墙面一起参与约束；存在正间隙的非候选接触不会因“离得很近”而提前加入。

`Arena._wall_time(ball, horizon)` 负责预测单个球在时间窗口内最早撞墙的时间，返回 `time` 和 `contacts`。每个墙接触保留自己的 `time` 和朝向场内的 `normal`，角落可以同时返回两面墙；窗口内不撞墙时为 `INF` 和空列表。`_next_event` 汇总墙与球对预测，再按全场最早时刻筛选，保持原有时间容差和碰撞行为。

到达事件时刻后，`_wall_contacts(ball, seeded_normals)` 检查单球与四面墙的接触，返回朝场内的法线；`_pair_contact(a, b, seeded)` 检查两球接触，返回从 b 指向 a 的 `normal`，未接触时返回空字典。默认只接受零间隙或重叠；显式同刻 CCD 种子允许仍有正间隙。`_contacts_at_event` 负责调用这两个函数、补上球索引，再筛选本批种子连通的接触链，保持原有顺序和行为。

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
- 初始化拒绝超出 `1e-4` 像素容差的重叠或越界。运行中的位置纠正采用上述有限迭代和原子提交，不承诺密集穿插状态的唯一结果或必然收敛。
- 每个子步最多处理 128 个碰撞时刻；每批最多 128 轮同刻冲击，每轮求解最多 4096 次迭代。极端质量比、长接触链或密集病态布局可能不收敛；中间量和最终结果也需保持有限、可写回单精度状态。失败会显式报错，记录 `solver_failures`，不提交部分速度或发送该批通知，并丢弃剩余子步；`event_limit_hits` 单独记录 CCD 事件超限。失败前已经推进到的撞击位置和模拟时间仍保留。
- 后台/失焦停止推进，单次渲染回调最多接收 0.1 秒，长卡顿不会补算大量时间；超出上述帧预算时也丢弃积压，保留每个已完成物理步的结果。
- 使用浮点运算，不承诺跨 CPU 或引擎版本位级一致。

## 自动测试

在本目录运行：

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_ball_state.gd
godot --headless --path . --script tests/test_ball_config.gd
godot --headless --path . --script tests/test_demo_scenarios.gd
godot --headless --path . --script tests/test_arena_placement.gd
godot --headless --path . --script tests/test_wall_time.gd
godot --headless --path . --script tests/test_contact_detection.gd
godot --headless --path . --script tests/test_simultaneous_collisions.gd
godot --headless --path . --script tests/test_collision_solver_failure.gd
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 5
```

场景测试覆盖五个独立入口、32 个种子的初始化、每种数量 3 个种子的短时推进、全部球对的独立几何检查、真实按钮信号/合成触摸派发、重开/切换/暂停、资源释放、帧预算和错误恢复，以及竖屏布局和安全区换算；状态测试验证纯状态对象、字段与生命周期；配置测试验证默认兼容、逐球配置与原子拒绝；位置测试覆盖 100 球放置和推进、显式位置、容差、非法数据、连锁/墙面纠正及不可行布局的原子失败；撞墙预测测试覆盖四面墙、角落、零时刻、速度与时间容差，并与抽取前的事件算法进行随机逐项对照；接触检测测试覆盖球墙/球球接触、正间隙种子、法线顺序、连通链和独立组，并与抽取前算法进行随机逐项对照；同刻碰撞测试覆盖对称三球、不同质量、静止链、独立组、墙与角落、时间容差、排列一致性、随机旋转接触链及守恒；原回归保留长时间二球物理与主场景控制。

配置测试故意触发 15 次错误日志，位置测试故意触发 33 次错误日志，求解失败路径测试故意触发 4 次错误日志，场景测试故意触发 1 次错误日志，分别有 `EXPECTED CONFIG ERROR` / `EXPECTED PLACEMENT ERROR` / `EXPECTED ERROR` / `EXPECTED SCENARIO ERROR` 标记；它们用来确认错误配置、不收敛及数值溢出不会部分修改状态。其他测试不应有引擎/脚本错误。检查退出码、最终失败数和日志，不要仅看退出码。最新执行结果见 `TEST_RESULTS.md`。

此目录包含 Android 导出预设和操作说明，不提交构建产物或旧战斗工程。无界面布局和合成触摸测试不等于画面、真实触屏或手机验证。

### GitHub Actions 构建 APK

仓库根目录的 `.github/workflows/android-demo.yml` 使用 Godot 4.6.3、JDK 17 和 Android SDK 35，先运行全部回归，再导出 `balls-demo.apk`。在 Actions 中选择 **Build Balls demo Android APK**，点击 **Run workflow** 可手动构建所选分支；只有该工作流文件在 `main` 上变化时会自动构建，普通游戏代码提交不会自动运行，没有定时任务。

成功运行的 `balls-demo-android-apk` artifact 保留 14 天，包含 APK、SHA256 校验值、构建提交号、签名检查和回归日志。APK 包名为 `org.gankkiii.ballsdemo`，支持 ARMv7 和 ARM64，包含 1、2、5、20、100 球场景。它使用每次构建临时生成的调试签名，仅供测试；同包名旧版本可能需要先卸载才能安装新包，卸载会清除应用数据。没有发布到应用商店，也没有正式发行签名。

在仓库根目录运行 `python3 scripts/run_regression.py` 可执行与构建相同的导入、9 套测试及启动冒烟，日志位于 `build/test-logs/`。可用环境变量 `GODOT_BIN` 指定 Godot 可执行文件。脚本同时检查退出码、结果失败数和预期错误标记，任何阶段失败都会阻止 APK 导出；真机安装、触控和性能仍需单独验证。
