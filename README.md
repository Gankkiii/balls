# Balls Auto Battle — v0.2

Godot **4.6.3 stable + GDScript**。原光滑竞技场上新增充气角色与炸弹母鸡、自动技能、左侧冷却显示。Android ARM64 横屏。

## 打开与运行

导入 `project.godot`，F5运行。开局暂停，默认倍率1×；点击1×/2×/3×开始或继续，Pause暂停。**新版1×＝原2×，新版2×＝原4×，新版3×＝原6×。**所有移动、技能CD、充气、蹲蛋、引信都使用同一模拟时间。物理步长仍为1/120秒，不是将速度向量翻倍。

战斗一方HP归零结束，90模拟秒未结束则平局。当前没有重开按钮，重新启动游戏开始新一局。

## 角色规则

### 充气角色
- 被动普攻：气满100立即放气，移动加速，碰撞敌人造成36伤害，同目标接触伤害间隔0.35模拟秒。普通碰撞无伤害。
- 技能1 INFLATE：原地充气，每秒40气，CD6秒。充满直接进入放气。
- 技能2 ABSORB：免伤2.5秒，期间受到攻击按伤害×1.8充气，CD9秒。
- 放气每秒消耗25气，速度基于进入时基础速率提高2.5倍，放空结束。

### 炸弹母鸡
- 被动普攻：每1.7秒下小蛋；只有敌人碰到才触发0.8秒引信，爆炸按当时位置判定，半径70，伤害24。可以跑出范围躲掉。
- 技能1 PANIC RUN：随机乱跑1秒，每0.18秒重新选方向，速度1.8倍，CD5秒。
- 技能2 BIG EGG：原地蹲3秒，生成大蛋，落地1.5秒后爆炸，半径125、伤害62，CD10秒。
- 自己的爆炸只受20%伤害。自己不会触发小蛋引信，但在爆炸范围内仍会受伤。
- 外观用代码绘制头、冠、喙、身体、翅膀和脚；圆形碰撞体保持稳定，后续可换AnimatedSprite2D像素图。

双方暂定120 HP。数值仅用于机制原型，尚未做平衡性验收。蛋最多32个，22秒后清理。

技能冷却就绪自动释放，不可打断的动作期间排队。两个技能同时就绪优先技能2，避免技能1反复执行导致技能2饿死。CD从施放开始计算。UI READY表示冷却完成，不代表能打断当前动作。

## 代码结构

- `Ball`：位置、速度、质量、半径、绘制和碰撞信号，唯一位置状态是Node2D.position。
- `Arena`：圆形连续碰撞检测、运动、场地与碰撞响应。
- `Fighter`：Ball子类，HP、CD、动作与临时站桩。
- `Puffer` / `Chicken`：角色机制和外观，普通身体碰撞不伤血。
- `BombEgg`：触发、引信、范围伤害、显示。
- `BattleArena`：Arena子类，统一固定步推进角色、物理、蛋、胜负。
- `main.gd`：横屏主界面与左侧HUD、基准时间×2以及倍率。
- `baseline.gd` / `baseline.tscn`：保留原物理原型控制器用于旧回归测试，不是默认游戏画面。

站桩期间角色逆质量为0，作为不可推动的圆形障碍；动作结束恢复运动。游戏技能主动改变速度/质量约束，不要求战斗全过程动能守恒；无技能基础物理仍保持原守恒验收。

## 测试与提交门禁

```bash
godot --headless --editor --import --quit
godot --headless --script tests/run_tests.gd
godot --headless --script tests/test_characters.gd
```

先通过全部自动回归才能提交GitHub。查看输出中的ERROR与FAIL，不仅看退出码。不得删除或放宽旧测试来掩盖错误。详见 `AGENTS.md`、`tests/TEST_CASES.md`、`tests/CHARACTER_CASES.md`。人工画面/真机测试单独标记，不计入自动通过数量。

## Android

安装匹配的Godot导出模板及Android SDK/JDK，配置调试签名后：

```bash
godot --headless --export-debug Android build/balls-v0.2.apk
```

最低Android7.0，arm64-v8a。使用非Gradle预构建模板，配置见export_presets.cfg。项目不包含签名私钥。

GitHub Actions为**仅手动触发**。在Actions中运行`Test and build Android APK`，成功后下载`smooth-arena-android-apk`产物，解压得到APK。产物保留14天。工作流每次生成临时调试签名，因此不同次构建可能无法覆盖安装旧包，正式发行前应配置稳定签名；卸载旧包会清除本地数据。

当前状态和实际检查见TEST_RESULTS.md；构建和验签成功不代表已在真实手机上测试。
