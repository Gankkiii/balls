# R04 给点点的资源接入说明

本包根目录为 `art-deliveries/R04/`；本文所有 `assets/`、`metadata/`、`reference/` 相对该目录。**这是已获用户认可的R04视觉与新声音的开发移交，不是已接入游戏、人工听审或真机验收通过。** 用户本轮明确要求“先这样吧，做资源包让点点写代码”；历史SETTING/review.json里的“网页only”“声音待试听”记录的是此前制作/评审状态，由本轮移交授权覆盖，不删除或篡改历史原件。R03旧声音已被否决，不在本包复用。

本轮只整理、原生导出与交付，不修改游戏脚本/场景/玩法/物理或受保护团队配置。点点按本文与实际metadata实施；出现新玩法/方向歧义再问用户，普通导入、绑定、回归不重复要求用户选择已定方向。

## 1. 基线及已确认表现

- 最新检查 `Gankkiii/balls@d202089`（完整SHA见`metadata/baseline.json`）；其相对`3134f2b8dd0fe250b01e1e7d3c829da5c54aaa47`仅更改网页岗位配置，游戏源码一致。已实际读取8角色、Bubble/BombEgg/IronNail/TurtleShell/Scarecrow、BattleArena、Fighter/Ball、main/showcase及R04八份SETTING、R02鸭兔独立设定。
- 包内独立角色文档：`docs/characters/puffer.md`、`chicken.md`、`bubble_fish.md`、`electric_sheep.md`、`magnet_crab.md`、`cactus.md`、`shell_turtle.md`、`crow.md`（均同目录）；当前决定与历史状态覆盖说明见`docs/DECISIONS.md`、`docs/HANDOFF_STATUS.md`。
- R04来源为已公开审阅版本 `Gankkiii/ball_art_review@33d13fc`，具体完整SHA与逐文件hash由总manifest记录。头像、原生透明件、独立事件WAV为可用输入；网页展示PNG/GIF/试听拼接只放reference，不当sprite/游戏事件音源。
- 已定A像素风、横屏、极简左右状态区+浅色场地；鸭与宽刀兔保持R02，不在本轮重做。
- 充气球：圆薄荷软刺气团+分段蓝色吸收罩；普通实际损血仅眨眼，免伤吸收不假掉血。没有新增河豚物种或毒刺玩法。
- 母鸡：长颈扇尾、斑点蛋、腿尾摆惊跑；声音是急促母鸡“咯咯咯”，不是公鸡打鸣或鸭叫。
- 泡泡鱼：流线叉尾、单层加粗泡边、等级渐深且保留实时数字；八向为八个分离1级小泡。
- 羊：圆团云绒本体有两条可见小短腿；羊毛团无脸无腿、不是第二只羊。
- 蟹：横向马蹄磁钳；仅实际移动的铁钉有短轨迹。
- 仙人掌：高柱花冠有双眼、落刺短亮、换位仅花冠短亮；不奔跑、不回血。
- 龟：长颈短足本体+独立圆拱空壳；仅壳纹旋转，不加壳外发光圈或冲刺。
- 乌鸦：宽身披翼+拼布稻草人；真实换位两端短羽光，不画飞羽弹道。

## 2. 入口、尺寸和导入规则

游戏现在有两个入口：默认 `scenes/showcase.tscn`/`scripts/showcase.gd`固定鸭兔，已实际加载`assets/r02/`纹理、wide_hit音和鸭兔presentation信号；`scenes/main.tscn`/`scripts/main.gd`是10角色随机池、原代码绘制与文本UI。不能写“鸭兔还未接入”，也不能把默认鸭兔演示换成随机池当成用户授权的玩法变化。

交付目录带`.gdignore`，用于避免源脚本/参考图参与项目导入；不能把ignored交付树直接当成已导入的res资源。先选择复制本包`assets/`内容到正式`res://assets/r04/`并执行Godot导入，例如`assets/characters/puffer/idle.png`→`res://assets/r04/characters/puffer/idle.png`，音效→`res://assets/r04/audio/`，UI→`res://assets/r04/ui/`，保持分类内相对关系；本包`assets/characters/id/...`是交付路径，不宣称当前正式项目已存在同名资源。点点可建立共用表现层，让main的全部角色使用R04八角色+既有R02鸭兔；showcase继续鸭兔演示或复用同层，具体是否调整默认入口归点点开发安排，不作为本包待批准阻塞点；本轮不改入口，也不自行改变随机机制。

所有可用图片必须按导出metadata的实际尺寸、alpha、body origin/物件anchor导入；PNG nearest、UI图标不启用平滑/模糊或破坏像素的非等比拉伸。**不要把原生96画布、显示缩放与物理radius24混为同一数值**；身体节点仍在真实模拟位置，视觉子树偏移由anchor决定。左右镜像围绕身体origin/物件pivot，不镜像HUD文字，也不让身体跳位。

原生角色/物件实际目录为`assets/characters/{id}/idle.png`、`hurt.png`、`animations/{name}/frame_00.png`与`strip.png`、`objects/{name}.png`，逐项实际路径/参数由`metadata/characters.json`给出（见后续资产表）。source身体参考点、handoff建议挂点与已在游戏验证的绑定是三种不同状态；前4不能统一硬写(48,56)，后4原review的(48,56)也仍属未实机验证约定。展示图、整张参考板、GIF解码帧均不能替代原生导出；没有透明动作帧的表现必须如实写代码控制或未提供，不拿截图补齐。

### 原生帧也有组合语义，不能自动当独立对象

- Puffer气量对照帧按`gas`选择/缩放，不按时间依次循环把角色强行充满；`immune_left`与burst可并存，本包已导出独立`objects/absorb_segments.png`与`absorb_segments_burst.png`供当前状态叠蓝罩，不令视觉选择反过来取消burst。
- R04泡泡鱼“八泡合成”概念动作帧含演示泡，本包已从可用sprite中排除，不等于八个真实Bubble。运行时仍逐个使用world.bubbles位置/level渲染；不能播放合成假泡再重复画真实泡。若无body-only对应动作，使用idle身体+真实泡，合成帧只参考，不裁截图补源。
- 鸡`lay_2/lay_3`含蛋合成帧已排除，包内`poses/lay.png`不含蛋；旧概念帧只能在真实`spawn_egg`对应时点作表现参考；不在3秒蹲蛋尚未完成时先画假蛋，也不与独立BombEgg双绘。
- metadata中各文件notes、animations.usage、missing等限制优先于“文件在assets目录”这一事实；某帧可导入不等于适合不加选择地放到动画循环。独立物件必须按真实对象状态实例化/清理。

### 实际角色/物件路径与挂点（131原生PNG/条已冻结）

`metadata/characters.json`逐项列131原生PNG/strip的尺寸/alpha bbox/hash、逐帧顺序/时长/loop、source参考中心及建议挂点。所有单帧/物件为96×96 RGBA，strip宽=96×帧数；**runtime_origin_verified全为false**，技术挂点不是已在Godot验证的角色中心。美术轮廓/毛/尾/钳不用于反推物理半径。

|角色|原生主体/闭眼路径|attachment origin；Sprite2D centered=true的position|挂点依据与尺度|
|---|---|---|---|
|充气球|`assets/characters/puffer/idle.png`；`assets/characters/puffer/hurt.png`|(48, 48)；(0, 0)|Explicit source gas-body centre (24,24) logical pixels ×2. 可选body-fit起点1.2，不是定稿比例|
|炸弹母鸡|`assets/characters/chicken/idle.png`；`assets/characters/chicken/hurt.png`|(44, 56)；(4, -8)|Explicit source torso centre (22,28) logical pixels ×2; head/leg movement remains local artwork. 可选body-fit起点1.333333，不是定稿比例|
|泡泡鱼|`assets/characters/bubble_fish/idle.png`；`assets/characters/bubble_fish/hurt.png`|(52, 52)；(-4, -4)|Declared handoff attachment near the approved polygonal body centre; no prior game-origin binding exists. 可选body-fit起点0.857143，不是定稿比例|
|触电羊|`assets/characters/electric_sheep/idle.png`；`assets/characters/electric_sheep/hurt.png`|(42, 44)；(6, 4)|Explicit source fleece-core centre (21,22) logical pixels ×2; legs extend below this point. 可选body-fit起点1.0，不是定稿比例|
|磁铁蟹|`assets/characters/magnet_crab/idle.png`；`assets/characters/magnet_crab/hurt.png`|(48, 56)；(0, -8)|R04 review metadata declared body_origin=(48,56); not runtime-verified. 可选body-fit起点0.857143，不是定稿比例|
|仙人掌|`assets/characters/cactus/idle.png`；`assets/characters/cactus/hurt.png`|(48, 56)；(0, -8)|R04 review metadata declared body_origin=(48,56); not runtime-verified. 可选body-fit起点0.774194，不是定稿比例|
|脱壳乌龟|`assets/characters/shell_turtle/idle.png`；`assets/characters/shell_turtle/hurt.png`|(48, 56)；(0, -8)|R04 review metadata declared body_origin=(48,56); not runtime-verified. 可选body-fit起点0.923077，不是定稿比例|
|乌鸦|`assets/characters/crow/idle.png`；`assets/characters/crow/hurt.png`|(48, 56)；(0, -8)|R04 review metadata declared body_origin=(48,56); not runtime-verified. 可选body-fit起点0.923077，不是定稿比例|

Sprite2D centered=false时局部position为负attachment origin；centered=true按表。以上针对默认右向。**左向不要只flip_h而忘记非居中锚点**：可绕真实body root镜像整个视觉子树（含局部偏移），或按metadata的mirrored_attachment_origin重算offset；Canvas边界x'=96-x、像素索引x'=95-x不可混用。实际贴边/重叠/身体与碰撞关系需点点验证。

|实际动作条路径|帧数/不重复画面；帧时长ms；loop|使用方式|
|---|---|---|---|
|`assets/characters/puffer/animations/hurt/strip.png`|4/2；140×4；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Trigger only actual HP decrease; restore current pose afterward. Puffer immune hits use absorption instead. Do not loop as an idle.|
|`assets/characters/chicken/animations/hurt/strip.png`|4/2；140×4；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Trigger only actual HP decrease; restore current pose afterward. Puffer immune hits use absorption instead. Do not loop as an idle.|
|`assets/characters/chicken/animations/panic_run/strip.png`|4/4；120×4；循环|Selected leg/tail sway only while existing action=run; world direction, speed and one-second duration remain code-controlled.|
|`assets/characters/chicken/animations/panic_run_blink/strip.png`|4/4；120×4；循环|Closed-eye counterpart at the SAME panic_run phase. Do not restart run/frame0 on damage; eye closure duration is independent presentation feedback.|
|`assets/characters/bubble_fish/animations/hurt/strip.png`|4/2；140×4；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Trigger only actual HP decrease; restore current pose afterward. Puffer immune hits use absorption instead. Do not loop as an idle.|
|`assets/characters/electric_sheep/animations/hurt/strip.png`|4/2；140×4；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Trigger only actual HP decrease; restore current pose afterward. Puffer immune hits use absorption instead. Do not loop as an idle.|
|`assets/characters/magnet_crab/animations/hurt/strip.png`|8/2；90×8；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Source R04 eye-blink sequence only. Trigger actual HP decrease; hidden turtle and shell do not hurt. Not an immunity duration.|
|`assets/characters/cactus/animations/hurt/strip.png`|8/2；90×8；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Source R04 eye-blink sequence only. Trigger actual HP decrease; hidden turtle and shell do not hurt. Not an immunity duration.|
|`assets/characters/shell_turtle/animations/hurt/strip.png`|8/2；90×8；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Source R04 eye-blink sequence only. Trigger actual HP decrease; hidden turtle and shell do not hurt. Not an immunity duration.|
|`assets/characters/shell_turtle/animations/shell_markings_spin/strip.png`|12/2；120×12；循环|Only shell markings change. Same outer alpha silhouette and canvas; repeat only actual spin_left>0. No glow, body rotation or automatic dash.|
|`assets/characters/crow/animations/hurt/strip.png`|8/2；90×8；单次|IDLE BODY ONLY; do not override run/lay/gas/stored-pose state. Source R04 eye-blink sequence only. Trigger actual HP decrease; hidden turtle and shell do not hurt. Not an immunity duration.|

特别注意：shell_markings_spin针对独立壳，逐帧attachment origin为(48,48)，不是龟本体(48,56)。每条strip左到右、无间隔、每格96×96；单帧`animations/{id}/frame_00.png`等完整列在metadata。时间只是原R04概念帧节奏，不是CD/受伤无敌时长；重复闭眼格不是更多独立动作。

|独立原生对象/状态路径|用途与使用限制|
|---|---|
|`assets/characters/puffer/gas_samples/gas_000.png`|Source visual radius=10 logical px; at gas100 source also contains accepted burst trail.；局部anchor(48, 48)|
|`assets/characters/puffer/gas_samples/gas_000_blink.png`|Only actual HP loss with matching gas/burst pose. If immune_left>0 uses absorption instead; never switch to empty idle on hit.；局部anchor(48, 48)|
|`assets/characters/puffer/gas_samples/gas_040.png`|Source visual radius=14 logical px; at gas100 source also contains accepted burst trail.；局部anchor(48, 48)|
|`assets/characters/puffer/gas_samples/gas_040_blink.png`|Only actual HP loss with matching gas/burst pose. If immune_left>0 uses absorption instead; never switch to empty idle on hit.；局部anchor(48, 48)|
|`assets/characters/puffer/gas_samples/gas_050.png`|Source visual radius=15 logical px; at gas100 source also contains accepted burst trail.；局部anchor(48, 48)|
|`assets/characters/puffer/gas_samples/gas_050_blink.png`|Only actual HP loss with matching gas/burst pose. If immune_left>0 uses absorption instead; never switch to empty idle on hit.；局部anchor(48, 48)|
|`assets/characters/puffer/gas_samples/gas_100.png`|Source visual radius=20 logical px; at gas100 source also contains accepted burst trail.；局部anchor(48, 48)|
|`assets/characters/puffer/gas_samples/gas_100_blink.png`|Only actual HP loss with matching gas/burst pose. If immune_left>0 uses absorption instead; never switch to empty idle on hit.；局部anchor(48, 48)|
|`assets/characters/puffer/objects/absorb_segments.png`|Only immune_left>0. Segments are one absorption style, not shield layers; may coexist with burst.；局部anchor(48, 48)|
|`assets/characters/puffer/objects/absorb_segments_burst.png`|Only immune_left>0. Segments are one absorption style, not shield layers; may coexist with burst.；局部anchor(48, 48)|
|`assets/characters/chicken/poses/lay.png`|No egg baked in. Hold only while action=lay; code spawns the independent large egg after its real timer.；局部anchor(44, 56)|
|`assets/characters/chicken/poses/lay_hurt.png`|Use only actual HP loss while lay; do not reset crouch/action_left or show an extra egg.；局部anchor(44, 56)|
|`assets/characters/chicken/objects/egg_small_rest.png`|Selected spotted pattern. Small egg arms after enemy contact (0.8s); large egg arms on landing (1.5s). No fuse number baked in; armed ring is visual only.；局部anchor(48, 48)|
|`assets/characters/chicken/objects/egg_small_armed.png`|Selected spotted pattern. Small egg arms after enemy contact (0.8s); large egg arms on landing (1.5s). No fuse number baked in; armed ring is visual only.；局部anchor(48, 48)|
|`assets/characters/chicken/objects/egg_large_rest.png`|Selected spotted pattern. Small egg arms after enemy contact (0.8s); large egg arms on landing (1.5s). No fuse number baked in; armed ring is visual only.；局部anchor(48, 48)|
|`assets/characters/chicken/objects/egg_large_armed.png`|Selected spotted pattern. Small egg arms after enemy contact (0.8s); large egg arms on landing (1.5s). No fuse number baked in; armed ring is visual only.；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_1.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_2.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_4.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_8.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_16.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_32.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_64.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/bubble_fish/objects/bubble_level_128.png`|Single continuous rim, source nominal radius32px. Numbers intentionally NOT baked in: bind actual Bubble.level including 1. Same-size sample compares colour only; world radius remains min(54,9+sqrt(level)*3).；局部anchor(48, 48)|
|`assets/characters/electric_sheep/objects/wool.png`|One selected round wool clump: no face/legs and no independent charge pool. Place only at actual wool_position.；局部anchor(48, 48)|
|`assets/characters/magnet_crab/objects/nail_rest.png`|Resting nail is harmless; no moving trail.；局部anchor(48, 48)|
|`assets/characters/magnet_crab/objects/nail_moving.png`|Moving nail source colour only; use actual IronNail.mode/position/velocity. Trail is independent VFX, not another damage object.；局部anchor(48, 48)|
|`assets/characters/cactus/poses/flower_lit.png`|Only successful reposition triggers this brief flower state; no healing/extra invulnerability.；局部anchor(48, 56)|
|`assets/characters/cactus/poses/flower_lit_hurt.png`|Keep the current flower state on actual HP loss; no healing or pose reset.；局部anchor(48, 56)|
|`assets/characters/cactus/objects/thorn.png`|Independent selected thorn, no added lifetime. Landing glint belongs to an event effect; code controls placement/contact damage.；局部anchor(48, 48)|
|`assets/characters/shell_turtle/objects/shell_rest.png`|Separate physical TurtleShell; hidden turtle body is not drawn again. Shell is not damageable.；局部anchor(48, 48)|
|`assets/characters/crow/poses/feather_stored.png`|Do not also overlay the independent feather object on this combined stored-state pose.；局部anchor(48, 56)|
|`assets/characters/crow/poses/feather_stored_hurt.png`|Uses the original appended feather geometry ops. Keep feather state on HP loss; do not consume it or reset the pose.；局部anchor(48, 56)|
|`assets/characters/crow/objects/dummy.png`|Selected patchwork scarecrow, stationary world object, HP60; not a weapon or an attacking minion.；局部anchor(48, 48)|
|`assets/characters/crow/objects/dummy_damaged.png`|Damaged patchwork state. Actual health/collision and reflection remain code-controlled.；局部anchor(48, 48)|
|`assets/characters/crow/objects/feather.png`|Stored feather or contact repair cue, never a flying damage projectile.；局部anchor(48, 48)|

Puffer气量样本实际仅0/40/50/100，100样本已烘焙固定左下尾迹，不代表任意真实velocity方向，不能硬播它作通用burst身体。运行时优先idle/对应闭眼身体基底按gas缩放，尾迹沿`-velocity`独立代码绘制；稀疏样本只作形态参照。若使用已膨胀样本，**不可再乘相同气量倍数而双重膨胀**；body-fit起点与动态1+gas/100缩放分清层次。

已机械导出11种保姿态闭眼配对：鸡run四phase、鸡蹲蛋、Puffer四气量样本、仙人掌亮花、乌鸦储羽。鸡`panic_run_blink`应保持当前run phase切同编号闭眼，不从frame0重开；lay/flower_lit/feather_stored选相应_hurt。它们不意味着新增动作设计或额外无敌。其余未提供姿态用眼层代码处理，普通`hurt.png`/hurt序列仅idle参考。

新包没有新绘完整idle呼吸/行走循环；`idle.png`是认可静态姿态。已原生导出惊跑、受击眨眼、壳纹旋转及必要独立状态/物件；缺少完整吸附嘴部动作、蟹行走/施法、乌鸦扇翼/换位身体动作等时，用静态体+真实代码效果，不把网页舞台位移/GIF切图当这些动画。逐角色缺失项以metadata.missing为准。

## 3. 每角色实际代码接口与表现绑定

以下函数均是已读代码存在的方法；“表现事件”是建议点点新加的无副作用接口，不是已存在信号。

|角色/脚本|已有方法与状态|素材/表现接入与不可改变的规则|
|---|---|---|
|Puffer，`scripts/puffer.gd`|`advance()`、`start_burst()`、`hit()`、`_on_contact()`、`visual_radius()`；`gas/immune_left/impact_cooldown/action`|idle/inflate/immune/burst视觉随真实状态。视觉半径`24*(1+gas/100)`、最大48，不改物理半径24。免伤`immune_left>0`可与burst共存，不只看action==immune。共享接触冷却0.35秒跨多敌对物件，不是每目标独立。免伤把伤害×1.8变气，HP不减不眨眼；满气不再增气仍可能是实际吸收，不可只用气量差分猜吸收。|
|Chicken，`scripts/chicken.gd`、`egg.gd`|`advance()`、`hit()`；`action idle/run/lay`；`BattleArena.spawn_egg()`、`BombEgg.setup()/advance()/explode()`|腿尾摆只配真实run，蹲蛋配lay。小蛋非主人活动Fighter接触后才armed/fuse0.8；大蛋生成立即armed/fuse1.5。爆炸按真实explode结果和位置，不以接触替代。自身爆炸伤害×0.2仍实际扣HP则可眨眼。绘制大小/引信环不改小蛋70/24与大蛋125/62范围/伤害。|
|BubbleFish，`bubble_fish.gd`、`bubble.gd`|`BubbleFish.advance()`；`BattleArena.spawn_bubble()/step_bubbles()`；`Bubble.level/launch_left/absorb_left/gone`|普通吐泡、吸附、八向分别绑定对应spawn调用。融合在step_bubbles使level相加后表现；1级无伤，>=2真实hit才命中反馈。level无上限，radius`min(54,9+sqrt(level)*3)`仅尺寸封顶。单层圈/色深/实时等级数字按第5节，不把色表最大档当等级上限。|
|ElectricSheep，`electric_sheep.gd`|`_wall_charge()`、`advance()`、`discharge()`；`charge/wool_active/wool_position/zapping`|本体两条腿必须保留；羊毛无脸腿，只有一个点，与本体共用charge。撞墙+30至100；DROP_WOOL新点替旧点。持续放电耗25/秒、伤害20/秒按实际spent比例，不能按动画每次闪电再伤20。两处覆盖不双算；实际first_target路径可被敌对物件截住。|
|MagnetCrab，`magnet_crab.gd`、`iron_nail.gd`|`advance()`、`magnetize()`、`IronNail.advance()`；`mode rest/wall/return/out`|静止钉无伤、无危险轨迹；仅位置实际改变的钉画短尾。wall→return→out/rest随mode；repel_ready只是储备，只有返回钉真弹出才播弹飞声。钳是肢体，不新增近战伤害。移动伤16/0.3秒、速度320及扫线检测不改。|
|Cactus，`cactus.gd`|`inverse_mass()`、`contact()`、`advance()`、`step_thorns()`；`thorns/position`|本体不动、无行走腿；contact敌伤18。SCATTER瞬间生成5个静止刺点，落刺只短亮，不画持续飞行刺弹或新寿命。REGROW成功换位置只花冠短亮；不是回血/免伤。刺点命中伤12并消失，不能凭闪光再伤。|
|ShellTurtle，`shell_turtle.gd`、`turtle_shell.gd`|`contact()/hit()/enter_shell()/advance()`；`TurtleShell.contact()/start_spin()/advance()`；`action idle/seek/hidden`|本体与壳独立。未隐藏本体撞敌自损12；hidden关physics/visible、免伤并跟随壳，不渲染露出的身体/眨眼。壳hit()无效，永不套掉血眨眼。start_spin先把壳速度置0保存，壳纹转≠自动冲刺；接触原有18/27伤害和spin冲量保持。出壳仅找到合法位置时成功，不能定时强出壳。|
|Crow，`crow.gd`、`scarecrow.gd`|`advance()/contact()`、`Scarecrow.hit()`；`dummy_timer/feather/dummies`|宽身披翼，拼布草人最多2。换位只在合法位置成功后两端羽光，固定第一个草人，不自由选点。储羽碰自家存活受伤草人修25HP并消耗，满血不消耗；不是羽弹攻击。草人静止、60HP/半径20、承伤实际值反到主人敌方英雄，不新增主动攻击/递归反伤。|

## 4. 受击：只对真实HP减少眨眼

**全局普通受击只眨眼同样约束鸭兔，不因复用R02而例外。** 鸭兔造型不重设计，本包不新增其独立blink原件；点点需保持原造型/当前姿态加眼层。统一损血判断条件为对每个实际可伤害对象比较`hp_before`与该次伤害结算后的`hp_after`，仅`hp_after<hp_before`触发短眨眼。**incoming damage数值>0、发生碰撞、动画“命中帧”或信号参数damage>0都不保证实际损血。** Puffer吸收、ShellTurtle.hidden、不可受伤TurtleShell均不得普通眨眼；稻草人反伤最终落到哪个英雄，按各对象实际HP变化各自处理。

现有`Fighter.hit()`和上述8类没有统一actual_damage信号。建议点点在真实结算后追加只读表现事件，载明actor/target、实际HP前后、来源、模拟时刻和唯一事件序号；保留原结算/随机调用顺序，不能为发事件二次调用hit。R02兔已有`presentation_hit(target,damage)`也只是请求伤害数，不保证对吸收/隐藏目标实际掉血；跨角色通用层仍必须看实际HP。

R04的`hurt.png`闭眼基准来自idle；本轮另有11种保姿态配对，但仍不是所有动作的全套受击帧；受击时仍保持当前action、气量尺度、移动与lay/panic等身体姿态，只更新对应眼部。不能切一张idle-hurt把充气体缩小或把蹲蛋鸡站起来。若当前姿态没有对应闭眼帧，点点按源眼部几何/眼位处理短眨眼；这属于代码表现工作，不能宣称本包已经提供每动作受击全套。眨眼期间当前动作相位仍随模拟推进，不能为眨眼从run/forge等动作frame0重新开始；结束恢复当前真实姿态，不强制回idle。

持续电可能每固定步真实少量损HP，表现层可合并短时间内的同类眨眼触发，避免每帧重启把眼睛永久闭上；合并仅视觉，不吞伤害/改DPS/隐藏实时HP。眨眼不加无敌、硬直、击退、hitstop、位移或新的伤害闪白。

## 5. 泡泡等级颜色与显示

已确认的渐深映射：`t=exp(-0.19*log2(level))`；浅端RGB(158,205,214)、深端(10,44,61)，逐通道`round(deep+(light-deep)*t)`。只用于`level>=1`的显示，不改变level的64位整数存储。不能在16、128或导出色表最后一项截断level；8bit色域最终可见差别趋小不等于等级封顶。

保留每泡实时等级数字（包括1），单层边；1级浅色2px边、融合等级4px边为R04参考显示规格，实际世界尺寸仍由`Bubble.size_radius()`决定。导出多档纹理只是色深例子，不是新等级枚举。等级/尺寸、吸附圈105、八向泡与伤害语义不得被“更深色/更粗边”改写。

## 6. 32条独立事件WAV及精确触发位置

全部路径前缀`assets/audio/`；均48kHz、16bit PCM、mono，不默认循环。

**已实测的Godot 4.6.3导入参数：** Import面板Compression Mode设Disabled（`compress/mode=0`），保持`force/8_bit=false`、`force/mono=false`、`force/max_rate=false`、`edit/trim=false`、`edit/normalize=false`、`edit/loop_mode=0`，再Reimport。新工程默认`compress/mode=2`会转成QOA（AudioStreamWAV.format=3），并非源WAV损坏；本包独立导入已在明确关闭压缩后严格核对PCM16/48000Hz/mono。正式项目配置本轮未改，点点也可用`[importer_defaults]`下的`wav`字典设置新导入默认。详见`metadata/audio.json`与`qa/import/import-parameters.json`。32事件与8段`*_audition.wav`不是同一类：后者只放reference/audio，绝不整体用于战斗循环。原音频manifest的awaiting状态被本轮移交认可覆盖，但不据此声称人耳/设备验收。

|文件名|时长s|真实代码触发及去重|
|---|---:|---|
|`puffer_inflate.wav`|0.55|`Puffer.advance()`真正begin_stationary("inflate")后进入态一次，不每帧播放|
|`puffer_absorb.wav`|0.31|`Puffer.hit()`在immune_left>0且incoming damage>0的实际吸收请求时；HP不减，不套受伤声/眨眼。满气吸收仍不能凭gas差为0误判|
|`puffer_release.wav`|0.90|`Puffer.start_burst()`实际开始一次；不是对burst每固定步重播|
|`puffer_contact.wav`|0.31|`_on_contact()`通过burst/impact_cooldown/敌对筛选后有效接触，按共享0.35计时；若目标免伤未损HP，不伪造受伤反馈|
|`chicken_panic_cluck.wav`|0.82|`Chicken.advance()`真实进入run；急促母鸡咯声，非公鸡/鸭；不跟每次随机转向重播整段|
|`chicken_egg_drop.wav`|0.21|`BattleArena.spawn_egg()`/`BombEgg.setup()`真实生成蛋一次，不再按同一帧视觉落地二次播|
|`chicken_fuse.wav`|0.58|小蛋`BombEgg.advance()`首次armed或大蛋setup立即armed的引信事件；短片不是0.8/1.5引信时长本身，不改爆炸计时|
|`chicken_explosion.wav`|0.63|`BombEgg.explode()`首次exploded结果一次；不能接触就提前播爆炸|
|`bubble_fish_spit.wav`|0.29|`BubbleFish.advance()`普通1级spawn/实际吐泡事件；八向一次技能不要同帧强叠8段全音量|
|`bubble_fish_merge.wav`|0.48|`BattleArena.step_bubbles()`同主人融合level相加确定后的每个真实融合事件；不对渲染重叠假播|
|`bubble_fish_vacuum.wav`|0.68|BubbleFish的cd_one分支真实创建吸附泡一次；不按absorb_left每帧播|
|`bubble_fish_hit.wav`|0.24|step_bubbles里level>=2且first_target真实接触/伤害结果；1级消失不播成有效伤害|
|`electric_sheep_bleat.wav`|0.94|角色声可选强调，不是已有新技能或定时羊叫机制；若使用，挂已有羊事件并限并发，不新增战斗状态|
|`electric_sheep_charge.wav`|0.44|`_wall_charge()`真实撞墙充电事件；不能因电量环每帧重绘发声|
|`electric_sheep_wool.wav`|0.24|`advance()`cd_two分支实际设置新wool_position一次，旧羊毛换位不当新角色生成|
|`electric_sheep_discharge.wav`|0.63|`discharge()`真实zapping开始/持续状态管理；该WAV是持续电片段，非无缝循环工程，不按1/120秒重复。若需持续音，用音源生命周期淡入/尾音/限流，不更改攻击间隔|
|`magnet_crab_drop.wav`|0.29|`BattleArena.spawn_nail()`真实生成一次；静止钉接触无伤不得播hit|
|`magnet_crab_magnet.wav`|0.70|`MagnetCrab.magnetize()`实际墙磁化命令一次；不是每枚钉/每帧全叠|
|`magnet_crab_moving_hit.wav`|0.34|`IronNail.advance()`old!=position且hit_left<=0且first_target返回后的真实移动命中；rest无|
|`magnet_crab_repel.wav`|0.40|IronNail返回到主人并consume repel_ready、mode转out时；仅处于弹钉准备态repel_ready或按钮CD0不播弹飞|
|`cactus_scatter.wav`|0.30|`Cactus.advance()`cd_one分支生成5刺的真实批次一次，不新增机枪连发|
|`cactus_land.wav`|0.14|该批刺实际放置的短视觉提示，可按批次/限并发；不伪造飞行落地延迟，不额外伤害|
|`cactus_regrow.wav`|0.52|cd_two分支free_position有效并真正position变化后一次；失败找位不播成功换位|
|`cactus_flower.wav`|0.13|同一次成功REGROW的花冠短亮可选声；不是独立回血技能。与regrow同事件混音可二选一，不能因为包内有文件强叠|
|`shell_turtle_enter.wav`|0.47|`ShellTurtle.enter_shell()`真实进入hidden结果，不在seek开始就提前播成功入壳|
|`shell_turtle_spin.wav`|0.82|`TurtleShell.start_spin()`实际壳纹旋转开始；不按帧播，不新增冲刺/壳外光圈|
|`shell_turtle_contact.wav`|0.40|`TurtleShell.contact()`筛敌对后真实壳击；不是本体自损12的替代语义，也不代表壳自己受伤|
|`shell_turtle_exit.wav`|0.36|`ShellTurtle.advance()`找到合法at并真正visible/physics恢复出壳后；action_left=0但找位失败不播|
|`crow_caw.wav`|1.02|角色声可选强调，若绑定成功生成草人/换位等已有事件需标为表现选择；不是新乌鸦声波伤害或羽弹|
|`crow_swap.wav`|0.46|`Crow.advance()`双位置合法并真正交换position后；失败尝试不播成功换位|
|`crow_repair.wav`|0.55|`Crow.contact()`自家受伤存活草人health实增且feather消费后；满血/非自己草人无修复声|
|`crow_reflect.wav`|0.27|`Scarecrow.hit()`actual>0、真实反伤结算一次；反到免伤目标时不套该英雄的HP受伤声/眨眼|

“事件id/序号”去重是建议新增表现元数据，目前除Ball碰撞、鸭兔presentation信号外8角色没有上述全部独立音画信号；表列函数位置并非可直接connect的现成信号。不要把`*_audition`编排start_s当真实技能时序。可选角色声/花冠声没有新增玩法触发条件，包内提供不等于强制自动播放全部文件。

## 7. 横屏UI、现有控制与代码绘制效果

目标仍1100×780、世界700×600、左右状态区/浅场地。世界到画布参考变换`(200,90)+world_position`，不改`BattleArena.arena_size`。main目前arena节点位于(370,70)，showcase现ORIGIN(200,90)；统一表现层时应改显示变换，不把UI坐标写回物理position。

R04 UI可用件在`assets/ui/`、实际尺寸记录`metadata/ui.json`、布局记录`metadata/ui_layout.json`、详细接入说明`UI_INTEGRATION.md`。组件只承载底板/图标/条形，实时HP/等级/CD/资源数另画，整张primary/stress或反馈GIF只reference。当前showcase已有`toggle_info()`，main没有同名现成接口；复用信息层时不要误称两入口API相同。常驻仅关键数字/图标，保留暂停/继续、1×/2×/3×、同局重看、新随机、声音、全部角色和信息详情；技能槽是自动技能状态，不点击施法。CD0用图形ready，非可打断许可；忙碌状态不因CD归零消失。seed/time/术语收info，原有功能不可因少字删掉。

已能机械导出的专属技能图标为鱼/羊/龟/鸦；充气球/鸡/蟹/仙人掌的独立专属技能glyph当前未画，不新增设计、不阻止本轮交付。点点可先沿原有技能1/2数字+真实CD与角色头像表示，明确是临时UI展示而非声称新专属图标已齐。鸭兔原4技能图标继续复用R02。

main有10角色随机池；本包8角色主体+R02鸭兔可供10类角色主体表现接入，但不代表所有特效/动作/专属UI图标都齐全；不改随机选人、种子或重放规则。`FighterHUD`旧跟随条与侧面状态区避免重复；道具HP（如Scarecrow）和壳无HP语义分清。

### 已落地UI组件/布局

`metadata/ui.json`逐项列65个可用PNG、对应SVG来源/原件复用、尺寸、hash与用途；`metadata/ui_layout.json`列实际rect/letterbox/10角色数据适配器，`UI_INTEGRATION.md`为UI专门说明。所有UI资源origin是左上(0,0)，基础框nine-slice边距LTRB=(8,8,8,8)；条形按本身内边距裁切，不把HP/电量纹理用于无上限等级/蓄伤百分比。

|实际路径（多文件同目录）|尺寸|用途|
|---|---|---|
|`assets/ui/status_panel.png`|160×600|左(10,90)，右(930,90)；无名字/数值烘焙|
|`assets/ui/control_strip.png`、`control_button.png`（同目录）|600×58；48×48|控制底板(480,706)与正常按钮；保留旧交互状态见retained|
|`assets/ui/auto_skill_slot.png`、`auto_skill_slot_ready.png`（同目录）|56×56|R04自动技能状态槽，不是点击施法按钮。不能把旧64槽无差别混入|
|`assets/ui/hp_track.png`、`hp_fill_blue.png`、`hp_fill_gold.png`、`hp_fill_mint.png`、`hp_fill_purple.png`（同目录）|132×9轨；128×5填充|仅health/max_health；轨道内padding2，按真实HP裁切|
|`assets/ui/charge_track.png`、`charge_fill.png`（同目录）|132×5|仅共享羊电量charge/100，不是双电库|
|`assets/ui/object_hp_track.png`、`object_hp_fill.png`（同目录）|44×5轨；42×3填充|独立稻草人HP，内padding1；不能给不可受伤壳画假HP|
|`assets/ui/cd_overlay.png`|48×48|剩余CD/实际技能总CD，从顶部覆盖剩余高度；透明度0.24|
|`assets/ui/icon_vacuum_28.png`、`icon_eight_28.png`、`icon_wall_28.png`、`icon_wool_28.png`、`icon_shell_28.png`、`icon_spin_28.png`、`icon_swap_28.png`、`icon_feather_28.png`（同目录）|28×28|鱼/羊/龟/鸦八个技能glyph；24基础版本也在同目录供复用，不把两版当不同技能|
|`assets/ui/icon_bubble_28.png`、`icon_bolt_28.png`、`icon_dummy_28.png`（同目录）|28×28|鱼泡数、羊电量、鸦草人数的状态glyph|
|`assets/ui/icon_heart_display20.png`、`icon_speed_display20.png`（同目录）|20×20|R04实际显示尺寸原生导出；其24px基础版仍保留|
|`assets/ui/icon_pause.png`、`icon_replay.png`、`icon_new_seed.png`、`icon_sound_on.png`、`icon_roster.png`、`icon_info.png`（同目录）|24×24|既有操作符号，不把图标选择当新玩法|
|`assets/ui/retained/r02/icon_play.png`、`icon_sound_off.png`、`badge_ready.png`、`badge_busy.png`（同目录）|24px图标；16px徽记|R02真实原件保留，继续显示播放/静音/忙碌状态，不是R04新设计|
|`assets/ui/retained/r02/button_normal.png`、`button_hover.png`、`button_pressed.png`、`button_disabled.png`（同目录）|48×48|保留既有交互态，未新增禁用玩法规则|
|`assets/ui/retained/r02/icon_skill_timer.png`、`icon_skill_rod.png`、`icon_skill_forge.png`、`icon_skill_temper.png`（同目录）|32×32|鸭兔原四技能；R04槽内使用layout指定32px尺寸/offset覆盖，不硬套28图标偏移|
|`assets/ui/retained/r02/icon_status_cloud.png`、`icon_status_stored_damage.png`（同目录）|32×32|鸭云、兔无上限蓄伤状态；不重绘、不改规则|
|`assets/ui/retained/r02/skill_slot_disabled.png`|64×64|仅legacy保留，没有另画R04 56px禁用态；不得不经调整替代56槽|
|`assets/ui/environment/screen_surround.png`、`arena_floor.png`、`arena_wood_frame.png`（同目录）|1100×780；700×600；720×620|原浅场地/外边框的可用原生副本，分别放(0,0)/(200,90)/(190,80)；外边不改墙体|

局部布局与原R04程序一致：头像(56,20,48,48)；HP轨(14,132,132,9)、填充(16,134,128,5)，加面板左上后global y=222/224；两技能槽(12,330,56,56)/(88,330,56,56)，CD数字baseline(40,405)/(116,405)。它们是新R04拆件，不能照抄R02 64px槽旧坐标。其余图标/资源数字/羊电量/羽毛位置见layout，所有数字由状态实时绘制。

|操作区域|main现有/待复用接口|showcase现有接口|
|---|---|---|
|pause；(488, 711, 48, 48)|set_rate(0) /保留暂停恢复语义|toggle_pause()|
|speed1；(544, 711, 48, 48)|set_rate(1)|set_speed(1)|
|speed2；(600, 711, 48, 48)|set_rate(2)|set_speed(2)|
|speed3；(656, 711, 48, 48)|set_rate(3)|set_speed(3)|
|replay；(724, 711, 48, 48)|restart_battle(true)|restart(true)|
|new_random；(780, 711, 48, 48)|restart_battle(false)：10池不重复抽2|restart(false)：当前只换固定鸭兔种子，不是10池随机|
|sound；(848, 711, 48, 48)|当前main无toggle_sound，新增泛化声音UI需点点接音频层|toggle_sound()|
|roster；(904, 711, 48, 48)|保留main随机战斗入口/现有返回导航；不得新增玩法|open_original()|
|info；(968, 711, 48, 48)|main没有同名接口，按当前showcase详情读状态复用UI逻辑|toggle_info()已存在|

main原本没有`open_original()`同名方法或单独返回导航方法；roster图标在main只表示当前已处10池路由，具体导航由点点按现有入口安排，不能假造已存在的回调或新增手动选人玩法。main也原本没有声音切换/详情同名函数，点点复用音频与信息层时必须实现相应UI接口；不能只写connect到不存在方法。showcase“新随机”目前只换固定鸭兔种子，与main从10池选2是不同语义，不借按钮换图暗改它。

|roster id/角色|两技能完整CD（不是初始CD）|专属图标状态|
|---|---|---|
|0 / puffer|6 / 9秒|该家族专属图标未画，null保持缺失说明|
|1 / chicken|5 / 10秒|该家族专属图标未画，null保持缺失说明|
|2 / bubble_fish|7 / 9秒|已导出，路径见role_adapters|
|3 / electric_sheep|5 / 7秒|已导出，路径见role_adapters|
|4 / magnet_crab|7 / 6秒|该家族专属图标未画，null保持缺失说明|
|5 / unlucky_duck|6 / 6秒|已导出，路径见role_adapters|
|6 / forge_rabbit|7 / 8秒|已导出，路径见role_adapters|
|7 / cactus|6 / 9秒|该家族专属图标未画，null保持缺失说明|
|8 / shell_turtle|9 / 8秒|已导出，路径见role_adapters|
|9 / crow|7 / 6秒|已导出，路径见role_adapters|

安全区/letterbox：先扣设备safe area，`s=min(safe_width/1100,safe_height/780)`，整体居中；world_to_screen=`offset+((200,90)+world_position)*s`。宽屏额外边只能装饰留白，不能变大物理arena。48参考按钮实际设备要检验>=44UI点；必要时只调整控制层触控布局，不增加世界边界。导出未验证Puffer满气/高等级泡贴边与侧栏遮挡，点点必须实测，不擅用缩物理半径解决。

以下效果若没有专用透明帧/粒子资源，应由点点基于真实事件代码绘制，不从网页截图裁出冒充素材：气量动态缩放/吸收罩叠层/放气尾迹、泡泡实时等级颜色和数字及105吸附提示、电链实际first_target路径、磁化墙/移动钉短尾、刺点落地短亮/REGROW花冠、壳纹旋转、换位两端短羽光。角色导出的关键帧可参与这些表现，但不自动构成完整运行时状态机/特效系统。

## 8. 鸭兔R02复用边界

本包`assets/ui/environment/`也提供浅场地/边框/屏幕底图的原生可用副本，来源是本仓库既有`assets/r02/environment/arena_floor.png`（700×600）、`arena_wood_frame.png`（720×620）与`screen_surround.png`（1100×780）。可沿既有R02路径或统一R04显示资源路径，但不因复制底图再造另一物理场地。

不复制/重做鸭兔。本仓库已有 `art-deliveries/R02/visual-remake-v2/`完整包、`assets/r02/`已集成视觉，以及`assets/audio/`R02鸭兔音效；后续接入8角色时继续使用当前showcase的wide_hit、forge、cloud_transfer、lightning及已集成倒计时等。R02原7条包括wide_swing，但“原包有文件”不代表当前showcase已经播放全部7条；以实际preload/事件使用为准，不新增未请求的鸭兔声音设计。

### 鸭兔普通眨眼仍有代码适配项

当前`showcase.gd`的`duck_impact_left`会选`assets/r02/characters/duck/impact_strip.png`；这不等于普通眨眼实现。点点不能因复用R02继续普通受击压扁/闪白/整身换姿态等反馈，应按实际HP下降在原鸭兔造型眼层处理短眨眼，并保持兔攻击/锻造等当前动作相位。真实攻击命中、雷击等专有事件VFX与普通受伤眨眼分开，不能混用以造假伤害或删除真实事件信息。

R02正式`assets/r02/`中没有独立hurt/blink命名的鸭兔PNG，本R04也未重制这两角色闭眼素材：**鸭/兔独立blink原件缺失，需代码眼层适配**。这不是已齐的文件项，也不构成另造角色的授权；保持原造型、只改眼部表现即可。

鸭兔独立设定不在本R04包新建，位于本仓库既有`art-deliveries/R02/visual-remake-v2/docs/characters/unlucky_duck.md`与`art-deliveries/R02/visual-remake-v2/docs/characters/forge_rabbit.md`。这些旧文“未接入/没有presentation信号”如与最新源码冲突，视为历史制作说明；当前`ForgeRabbit.presentation_hit`、`UnluckyDuck.presentation_strike`已实际存在。宽刀接触当帧命中不加前摇、不延迟真实伤害。

## 9. 生命周期与验收

- 所有动作/特效计时跟真实模拟时间，暂停冻结，恢复不重播越过事件；倍速不改变物理规则，短SFX保持原音高/长度并管理并发，不把试听段整体变速当游戏时钟。
- 连续电/充气等声音片段不是已制作无缝loop；生命周期由状态管理，暂停/静音/切后台/重开/切场/结算时停止或暂停、清待播队列。恢复不补静音期间历史声。
- 重开清掉旧对象和表现节点/尾迹/草人壳状态、事件去重号；同种子游戏状态须与原逻辑一致。视觉随机如需装饰应单独RNG，不能消耗模拟RNG。
- 先按metadata检查每个原生PNG/帧尺寸/alpha/anchor和条形顺序，再Godot导入。检查2羊腿清楚、羊毛无脸腿、母鸡不是鸭/公鸡、宽刀不改细、龟壳无额外外光圈。
- 覆盖八角色及鸭兔混合对战、免伤+burst并存、无效hit不眨眼、Scarecrow反伤、连续电、融合高等级与8向泡、满/空资源、壳hidden/合法退出失败、站桩/贴边/重叠/大数字、暂停/1×2×3×/静音/切后台/同种子重看/新随机。
- 必须运行真实Godot导入和完整既有回归：`godot --headless --editor --import --quit`，`godot --headless --script tests/run_tests.gd`，`godot --headless --script tests/test_characters.gd`。查ERROR/FAIL和退出码，独立用例/断言/manual-device NOT RUN分开报告；不删放宽测试。
- 本包资源字节/解压/metadata自检及原生导出可复现结果见QA_REPORT；它们不证明游戏内渲染/音画事件同步/人工听感/真实设备通过。没有实际执行的项目保持NOT RUN。
