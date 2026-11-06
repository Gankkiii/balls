# 精简竞技场 Demo

Godot **4.6.3 stable** / GDScript。一个竞技场、**1 / 2 / 5 / 20 / 100 球**五个可选场景，保留 1× / 2× / Pause，增加 Restart；启动默认进入 1 球并按 1× 运动。当前包含撞击技能、双方伤害、血条和死亡移除；暂未加入胜负规则和其他技能。

## 运行

用 Godot **4.6.3** 导入本目录的 `project.godot`，按 F5。顶部点选球数即可切换场景，下方用 1× / 2× / Pause 控制。鼠标和触摸使用同一组按钮。

- 入口为 `scenes/main.tscn`，默认加载 1 球场景。`balls_1.tscn`、`balls_2.tscn`、`balls_5.tscn`、`balls_20.tscn`、`balls_100.tscn` 是独立内容场景，各自声明球数、配置资源和 Arena 子节点，不再继承 main。可分别打开按 F6 预览自动运动；完整选择器和播放按钮在 F5 主页面中。选择按钮实际加载对应场景文件。
- 选场景会重新创建准确数量的球、生成新种子、重置模拟时间与错误，并从 1× 开始。重复点选也会重开，不会叠加球。
- Restart 使用当前种子重现初始位置和速度，并回到 1×；1× / 2× / Pause 只改变推进速率，不改变球的速度向量，不会重新随机。
- 100 球是重载演示，明确提示可能慢于真实时间；**不保证手机或电脑实时运行**。控制器每帧在完整的 1/120 秒物理步之间检查 12 ms 墙钟预算，超时丢弃积压，不缩小物理步长、不偷偷降低球速。单个物理步仍可能超过预算，所以这不是严格帧时上限，2× 也不保证在重载时达到真实时间两倍。
- 初始化/运行失败会暂停，在场地区显示可滚动的完整原因；不依赖鼠标悬停。仍可选择其他场景或 Restart 恢复。
- 桌面版启动时以普通窗口居中显示，占当前显示器可用区域约 85%，保留标题栏并支持拖动缩放，窗口基准为 1280×720，界面随窗口尺寸重新布局。宽度至少 1000 且为横屏时，场景按钮排列为一行六列，按钮高度为 48；窄屏恢复三列和较大的按钮。竞技场等比缩放居中，窗口变化不改变球的物理状态。移动平台保留 720×1120 竖屏画布与安全区适配。

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

详细的文件边界与调用方向见 [文件职责说明](../docs/文件职责说明.md)。

## 职责与战斗流程

完整说明见 [文件职责与碰撞战斗调用流程](../docs/文件职责说明.md)。

Main 管页面与场景切换，DemoScenario 组织一局并注入战斗回调，BallFactory 创建并初始化球。Arena 检测碰撞并维护统一 CollisionEvent，CollisionSolver 只计算候选速度，CombatSystem 调用 ImpactSkill 计算候选生命。Arena 检查两边结果后统一提交速度、生命和死亡移除，最后通知；没有新增碰撞检测流程。

默认球拥有 100 生命、10 攻击、0 防御、半径 24、质量 1、初始速率 140～230，并装备 default_impact_skill.tres。伤害为攻击 × 质量比例 × 有效法向速度比例的平方，再按对方防御减伤。有效速度来自碰前快照，受双方接近速度限制。默认基准质量 1、基准速度 200、防御系数 100。

球顶血条显示生命，状态栏显示存活数量。死亡球在当前碰撞批次提交后移除，双方可同归于尽。Restart 创建新场景并恢复满血。暂未实现胜负、阵营规则和其他技能。配置中的 impact_skill 留空表示不装备撞击技能；未注入战斗回调的 Arena 仍可用于纯物理模拟。

Ball 是纯状态对象；新建时由工厂初始化生命、攻击、防御与独立技能记录。多个球可以共享只读配置，但不得共享可变运行记录。已有球的运动初始化只修改位置和速度，不重置战斗状态或 Arena 计数。初始化、出生布局和只读校验直接调用 BallFactory / BallValidation，不再通过 Arena 转发。

位置与半径单位是竞技场局部逻辑像素，速度单位为像素/秒。竞技场缩放只改变显示。BallRenderer 与 Arena 共享同一球列表，不可替换列表却忘记重新绑定。渲染颜色通过弱引用关联球，不影响球生命周期。

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

配置与放置的工厂失败直接检查返回结果，不期待错误日志；运行中的位置错误仍检查日志，求解失败路径测试故意触发 4 次错误日志，场景测试故意触发 1 次错误日志，分别有 `EXPECTED CONFIG ERROR` / `EXPECTED PLACEMENT ERROR` / `EXPECTED ERROR` / `EXPECTED SCENARIO ERROR` 标记；它们用来确认错误配置、不收敛及数值溢出不会部分修改状态。其他测试不应有引擎/脚本错误。检查退出码、最终失败数和日志，不要仅看退出码。最新执行结果见 `TEST_RESULTS.md`。

此目录包含 Android 导出预设和操作说明，不提交构建产物或旧战斗工程。无界面布局和合成触摸测试不等于画面、真实触屏或手机验证。

### GitHub Actions 构建 APK

仓库根目录的 `.github/workflows/android-demo.yml` 使用 Godot 4.6.3、JDK 17 和 Android SDK 35，先运行全部回归，再导出 `balls-demo.apk`。在 Actions 中选择 **Build Balls demo Android APK**，点击 **Run workflow** 可手动构建所选分支；只有该工作流文件在 `main` 上变化时会自动构建，普通游戏代码提交不会自动运行，没有定时任务。

成功运行的 `balls-demo-android-apk` artifact 保留 14 天，包含 APK、SHA256 校验值、构建提交号、签名检查和回归日志。APK 包名为 `org.gankkiii.ballsdemo`，支持 ARMv7 和 ARM64，包含 1、2、5、20、100 球场景。它使用每次构建临时生成的调试签名，仅供测试；同包名旧版本可能需要先卸载才能安装新包，卸载会清除应用数据。没有发布到应用商店，也没有正式发行签名。

在仓库根目录运行 `python3 scripts/run_regression.py` 可执行与构建相同的导入、全部测试套件及启动冒烟，日志位于 `build/test-logs/`。可用环境变量 `GODOT_BIN` 指定 Godot 可执行文件。脚本同时检查退出码、结果失败数和预期错误标记，任何阶段失败都会阻止 APK 导出；真机安装、触控和性能仍需单独验证。

## VS Code 运行

安装 Godot Tools（geequlim.godot-tools），在 VS Code 打开仓库根目录。将工作区设置 `godotTools.editorPath.godot4` 指向本机 Godot 4.6.3 可执行文件，然后在“运行和调试”选择“运行球竞技场”并按 F5。启动配置已提交；机器专用的 `.vscode/settings.json` 不提交。
