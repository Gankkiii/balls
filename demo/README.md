# 精简竞技场 Demo

Godot **4.6.3 stable** / GDScript。一个竞技场、两个球、1× / 2× / Pause 三个按钮；启动时暂停。这个 Demo 只展示状态、模拟和渲染的职责划分，不包含角色、技能、伤害或胜负规则。

## 运行

用 Godot 导入本目录的 `project.godot`，按 F5。点击 1× 或 2× 开始，Pause 暂停。切换倍率不改变速度向量，暂停后继续不会重新随机。

## 职责

- `scripts/ball.gd`：`Ball extends RefCounted`，只保存 `position`、`velocity`、`radius`、`mass`、`color`。没有初始化方法、碰撞方法、信号、绘制或逐帧回调，也不依赖场景树。
- `scripts/arena.gd`：注册/移除球、设置初始状态、推进位置、处理碰撞，并发出 `wall_collided(ball, normal)` 和 `ball_collided(first, second)` 信号。球与球碰撞每对发一次通知。
- `scripts/ball_renderer.gd`：只读取竞技场共享的球列表并绘制，包含球的颜色、阴影和高光，不修改模拟状态。
- `scripts/main.gd`：组合 Arena 和 BallRenderer，创建两个 Ball，处理按钮及固定时间步。

`Ball.position` 是唯一权威位置，坐标相对于竞技场；位置和半径单位为逻辑像素，速度单位为像素/秒。Ball 不再是 Node2D，无需 `ball.tscn`，用 `Ball.new()` 创建。默认场地 640×680，球半径 24、质量 1、初始速率 140–230。

Ball 不做合法性修正，初始化和修改它的规则负责提供有效状态，例如正的半径和质量。渲染器与竞技场共享同一个数组；通过 `register_ball` / `remove_ball` 修改内容，不要另换一个数组而不更新渲染器。

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

第一份测试验证纯状态对象、实例独立性、注册/移除、碰撞通知以及渲染绑定；第二份保留原物理和主场景控制回归。检查退出码和输出中的脚本错误，不要仅看退出码。最新执行结果见 `TEST_RESULTS.md`。

此目录不包含 Android 构建、旧战斗工程或自动 CI 配置。无界面测试不等于画面、触屏或真机验证。
