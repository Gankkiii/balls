# R02 新制视觉整合包：接入清单（已确认交付版）

版本：`R02-visual-remake-v2`。**这是用户批准后重新制作的视觉素材，不是找回的旧R02原件。** 原`R02-materials.zip`及旧材料保留；本版独立存于`art-deliveries/R02/visual-remake-v2/`。本文以该新包目录为根描述相对路径；游戏代码路径以balls仓库根为准。

状态：**用户审阅少字修订稿后明确确认“按这版交付”。本确认针对素材与接入清单，不代表游戏内验收通过。** 本轮没有修改游戏代码/玩法/物理或受保护规则，点点后续接入。

## 1. 本轮明确决定

- A像素风、横屏、极简信息方向、锻造兔持宽刀均已确认，不再开放短剑/细剑候选。
- 用户已确认重制对象为**倒霉鸭、锻造兔及其道具**（不是炸弹母鸡）；横屏为**左右状态区+浅色场地**。
- 宽刀**真实碰撞当帧直接命中并回收**，没有等待前摇后才扣血；不改碰撞、伤害、冷却、移动、随机或模拟规则。
- 沿用获授权的合并册角色事实；新独立摘录为`docs/characters/unlucky_duck.md`和`docs/characters/forge_rabbit.md`，不新增背景/技能设定。
- 用户审阅新版后明确要求继续减少常驻文字。UI已按头像/图标+关键数字方案精简；减少文字不减少既有操作、真实状态或玩法功能。用户已审阅并确认按少字版交付。
- 本版只重制本轮指定视觉，不给其余8角色追加未授权造型/系统；原7条选用音效逐字复用，不重新合成冒称原音效。

## 2. 代码与素材基线

- 检查游戏提交：`190eb33f1acfc107c433c0155170c0046927d4c1`；该提交只增加旧交付目录，游戏代码仍以`018884b2589c6957687d3bdab1f0e9b27c77a528`为基础。负责人如发现更新，以最终基线记录为准。
- 旧参考素材：ball_art_review `e626fb7753205258a42d67a201f1baa29d5e2476`；仅作风格/设定追溯，不从其RGB板或影片截图提取原素材。
- Godot项目声明4.6.3、GL Compatibility、120Hz；默认`scenes/showcase.tscn`，视口1100×780。真正物理场地`BattleArena.arena_size=Vector2(700,600)`。
- 新视觉分为`payload/usable/visual/characters/`、`ui/`、`environment/`、`vfx/`；源、单帧、帧条和制作manifest位于对应分类内，具体实际文件以本包盘点manifest为准。
- 数值、血量、倒计时、蓄伤和冷却必须游戏动态绘制；任何预览中的示意数字都不是烘焙游戏UI输入。

## 3. 横屏坐标及根节点接口

|项|本轮制作接口|接入要求|
|---|---|---|
|基准画布|1100×780|整体采用canvas_items/keep等比显示；不能只拉长素材让圆体视觉失真|
|真实场地映射|700×600，UI左上(200,90)，视觉缩放1:1|`screen_position=(200,90)+world_position`；原物理位置不变，不把背景位置写回模型|
|左右状态面板|最终修正为左(10,90,160,600)，右(930,90,160,600)；原180宽方案因场边宽刀遮挡弃用|不压进场地，不遮挡场边碰撞；面板只是UI，不是新墙体|
|场地边框|720×620，内场左上anchor(10,10)，UI放置(190,80)|内区恰好落在(200,90)的700×600场地；装饰边不新增物理尺寸|
|人物帧|96×96 RGBA；身体origin(48,56)，脚底(48,80)|物理身体位置对应body origin，脚底局部是(0,24)。不是把脚底直接当圆体中心|
|人物朝向|主朝右，左向镜像|建议视觉子树以身体origin为pivot镜像；模型位置/速度不旋转，不镜像场上HUD与文字|

推荐表现层节点：根Node2D在真实角色世界位置，内部Sprite/AnimatedSprite保持统一origin；例如Sprite2D centered=false时position设`(-48,-56)`；centered=true时position设`(0,-8)`（画布中心48,48，身体origin48,56）。镜像围绕身体origin进行，不能围绕画布左边翻转导致身体跳位。点点需按Godot具体节点设置实际验证；本文不是已运行的节点工程。

## 4. 角色与道具接入

实际制作manifest：`payload/usable/visual/characters/character_manifest.json`。全部角色帧96×96 RGBA、帧条左到右无间隙；各动作目录单帧按`frame_00.png`递增，与manifest顺序一致。每帧alpha_bbox/时长/hash均在manifest，脚本和SVG是真实新制源，不是旧R02恢复件。

|实际文件路径|帧数；时长ms；loop|对象与使用方式|
|---|---|---|
|`payload/usable/visual/characters/duck/idle_strip.png`|4帧；160/160/160/160；循环|默认滑行/待机视觉，不驱动物理位置|
|`payload/usable/visual/characters/duck/cast_strip.png`|4帧；100/100/120/160；单次|真实鸭技能触发后的视觉，不创建cast玩法状态或延迟技能|
|`payload/usable/visual/characters/duck/impact_strip.png`|4帧；70/80/100/120；单次|鸭真实受击反馈，不生成伤害|
|`payload/usable/visual/characters/duck/recover_strip.png`|4帧；100/120/120/160；单次|受击后纯表现回收，不回血/无敌/改变运动|
|`payload/usable/visual/characters/rabbit/idle_strip.png`|4帧；160/160/160/160；循环|持宽刀常态视觉，仍可真实蓄伤|
|`payload/usable/visual/characters/rabbit/forge_strip.png`|6帧；160/100/80/90/110/160；循环|真实forge状态循环，index2小锤接触铁砧并触发anvil|
|`payload/usable/visual/characters/rabbit/temper_strip.png`|4帧；140/140/140/140；循环|temper_left>0时淬炼表现，失效/被消耗立即结束|
|`payload/usable/visual/characters/rabbit/hit_recover_strip.png`|4帧；70/80/110/160；单次|真实有效碰撞当帧index0命中并wide_hit，然后回收，无前摇|

默认入口是`payload/usable/visual/characters/duck/default.png`及`rabbit/default.png`（后者同characters根）。静态入口不替代完整动作；角色初始朝右，向左整套视觉同pivot镜像。

|道具实际路径|尺寸；anchor/含义|用法与边界|
|---|---|---|
|`payload/usable/visual/characters/props/broad_blade.png`|96×96；(48, 72) / grip attachment|独立透明新制道具；不是碰撞形状。注意角色动作帧已含相应道具时不重复叠放|
|`payload/usable/visual/characters/props/forge_hammer.png`|96×96；(48, 68) / grip attachment|独立透明新制道具；不是碰撞形状。注意角色动作帧已含相应道具时不重复叠放|
|`payload/usable/visual/characters/props/anvil.png`|96×96；(48, 80) / ground baseline|独立透明新制道具；不是碰撞形状。注意角色动作帧已含相应道具时不重复叠放|
|`payload/usable/visual/characters/props/lightning_rod.png`|96×96；(48, 82) / ground baseline|独立透明新制道具；不是碰撞形状。注意角色动作帧已含相应道具时不重复叠放|

人物源：`payload/usable/visual/characters/source/build_characters.py`及`source/svg/`。角色帧已烘焙本动作宽刀/锻造道具的画面，独立props作为重用/分层可选输入；同一动作不能既显示烘焙刀又再叠一把刀。接入需看实际帧及制作说明，不靠文件名猜。


- 鸭：绑定`UnluckyDuck`的`cloud_holder/storm_left/rods/lightning_flash/strike_position/health/cd_one/cd_two`。`cast`、`impact`等素材标签是视觉状态，不是代码里已有的新技能状态。
- 兔：绑定`ForgeRabbit.action`（现idle/forge）、`stored_damage`、`temper_left`、`action_left`与CD。新`hit_recover`是纯表现标签；第0帧命中，后续回收，不设置物理前摇。
- 锻造：小锤和铁砧只作forge作业表现，接触帧事件触发anvil声，不给锤增战斗伤害。
- 道具：宽刀、小锤、铁砧、避雷针的透明源由人物岗制作。贴到角色或世界节点时按各自manifest anchor；禁止将其外形自动生成新碰撞盒。
- 人物身体radius仍24。宽刀长度、光效、云或道具alpha bbox不扩伤害/保护范围。

### 真实命中而非动画推导伤害

`ForgeRabbit.contact()`会当帧`other.hit(stored_damage×增益)`，随后清空stored_damage与temper_left。表现必须读取该真实结果立即播放命中帧+wide_hit，然后回收；不能先从起手帧计时再调用hit。动画的“接触”标记只同步音画，**不调用或重复游戏伤害**。

当前showcase用`arena.step()`前后字段差分推测事件，没有统一的有效命中/落雷事件队列。同一固定步出现雷击与碰撞时可能误归因。建议点点增加只读表现事件（事件序号、模拟时刻、源/目标、伤害/保护结果）而不改真实计算/随机顺序；这属于后续代码需求，不是本包已存在API。

## 5. UI组件与数据绑定

对应清单：`payload/usable/visual/ui/ui_manifest.json`与布局`payload/usable/visual/ui/layout.json`，使用说明`payload/usable/visual/ui/README.md`；分别列实际尺寸/源/九宫格用途与完整区域坐标/绑定/安全区。以下组件已经有实际输出；最终hash与数量以制作/总盘点manifest为准。

|文件/文件组（均在payload/usable/visual/ui/）|规格|目标及用法|
|---|---|---|
|`png/status_panel.png`、`png/control_strip.png`、`png/inset_panel.png`|64×64、64×40、48×32，RGBA|左右状态板/公共控制条/数值底板，按manifest九宫格边距拉伸中心，不拉伸像素边框|
|`png/hp_track.png`、`png/hp_frame.png`|128×16|health/max_health轨道与上框；内填充x4,y4,w120,h8|
|`png/hp_fill_gold.png`、`png/hp_fill_purple.png`|120×8|TextureProgressBar横向裁切，不能用来暗示无上限蓄伤封顶|
|`png/skill_slot_normal.png`、`png/skill_slot_ready.png`、`png/skill_slot_disabled.png`|64×64|自动技能状态。ready只表CD归零，用槽/图形反馈，不常驻READY/AUTOSKILLS文字；busy/不可打断用辅助形状，不能假装可打断|
|`png/cooldown_overlay.png`|56×56|冷却裁切/径向填充；绑定真实CD，不烘焙数字|
|`png/cooldown_ring_track.png`、`png/cooldown_ring_fill.png`|40×40|可选冷却环纹理，实际进度由代码裁切|
|`png/badge_ready.png`、`png/badge_busy.png`|16×16|形状辅助，不仅靠颜色，不把就绪与可打断混淆|
|`png/button_normal.png`、`png/button_hover.png`、`png/button_pressed.png`、`png/button_disabled.png`|48×48|对应Button四状态，按manifest九宫格应用；除倍率1×/2×/3×外优先图标，解释放info详情|
|`png/icon_pause.png`、`png/icon_play.png`、`png/icon_replay.png`、`png/icon_new_seed.png`、`png/icon_speed.png`、`png/icon_sound_on.png`、`png/icon_sound_off.png`、`png/icon_roster.png`、`png/icon_info.png`、`png/icon_clock.png`、`png/icon_heart.png`|各24×24|公共操作/状态符号；原操作保持原功能，info只做现有状态/术语详情呈现，不新增玩法。info详情UI需点点实现，当前游戏没有现成info API|
|`png/icon_skill_timer.png`、`png/icon_skill_rod.png`、`png/icon_skill_forge.png`、`png/icon_skill_temper.png`、`png/icon_status_cloud.png`、`png/icon_status_stored_damage.png`|各32×32|对应鸭两技能、兔两技能、持云状态、无上限蓄伤；不要把状态图标作为主动释放技能按钮|
|`source/*.svg`、`source/build_ui.py`|实际可编辑SVG与制作脚本|本轮新源，非截图裁剪；复现时先把ui目录复制到新的临时目录，再运行该副本的source/build_ui.py；它以脚本父目录为输出根，勿直接在已交付版本运行覆盖|

控制条区域(480,706,600,58)，共9个图标点击区（含info），各48×48参考点击区；info局部rect(488,5,48,48)，UI全局(968,711,48,48)；事件文字区域(210,716,260,32)，标题安全区(200,12,700,44)，底边56。左右面板内头像槽(56,20,48,48)，HP数(52,100,96,28)，HP轨道(12,136,136,20)，两技能槽(12,324,64,64)/(84,324,64,64)，CD数(12,400,64,24)/(84,400,64,24)。其他本地坐标与控件绑定见layout.json，不能把头像UI缩放当成身体碰撞映射。

### 用户反馈后的精简信息策略

- 常驻：头像/角色识别图标、当前HP数、真实云倒计时、真实无上限蓄伤数、四技能图标；CD仅在`>0`时显示剩余数字，归零用图形就绪反馈，不显示READY文字。
- 图形状态：淬炼用glow，避雷针数量用小图示；云归属仍须由挂在真实holder的云/清楚归属图形表达。不能只减掉文字后把真实归属、增益或保护资源藏没。
- 默认不显示：长标题、常驻角色名、技能英文、READY/AUTOSKILLS、杆数量文字、temper ×1.5说明和底部占位/常驻教程句；旧资产包含的可选文字区域不用自动显示。
- 操作：倍率`1×/2×/3×`保留数字，其余暂停/继续、同局重看、换种子、静音、全部角色以图标保留；不能借精简删除功能。
- 事件提示：只有真实事件发生才短暂出现，结束后清空；不为填空持续显示故事句、假伤害或占位文字。
- seed/time/术语与增益详细解释收进info详情，保持可查。这是纯UI呈现需求，不改变模拟/数值；当前游戏没有现成info节点/方法，点点后续实现，不能写成已接入。

`layout.json.visible_text_policy`已写明默认可见/隐藏、非文字状态、info及事件反馈规则，`text_revision_status`已同步为用户确认交付状态。示例当前常驻文本精确22个非空白字符（原示例160），只是生成脚本实际文字清单计数，不是OCR，不代表所有战斗状态都固定22字。新预览为1100×828，上方48px是游戏画布外的审阅说明，实际游戏区仍1100×780；说明不能贴入游戏。

动态数据绑定与最终坐标以本次精简`layout.json`为准。宽刀蓄伤不设分母上限；若info中给出淬炼后预计刀伤，应明确`stored_damage*(1.5 if temper_left>0 else 1)`，不能混称已造成伤害。默认精简面不常驻这条乘数说明。

## 6. 场景与VFX接口

具体制作manifest为`payload/usable/visual/environment/manifest.json`与`payload/usable/visual/vfx/manifest.json`。以下是已经落地文件的实测/制作元数据，不代表游戏已接入。

|环境实际文件（路径前缀payload/usable/visual/environment/）|尺寸/anchor|用途|
|---|---|---|
|`arena_floor.png`、`arena_floor.svg`|700×600；anchor(0, 0)|flat noncolliding playfield background; 1:1 visual mapping of existing 700x600 simulation|
|`arena_wood_frame.png`、`arena_wood_frame.svg`|720×620；anchor(10, 10)|outside-only decorative rails; never added as collision geometry|
|`corner_inlay.png`、`corner_inlay.svg`|64×64；anchor(0, 0)|optional flat decorative inlay outside the playable interior; rotate by 90deg for other corners|
|`screen_surround.png`、`screen_surround.svg`|1100×780；anchor(0, 0)|outer composition backdrop only; UI and arena are separate layers|

VFX各6逻辑帧，横条左到右无间隔；每个ID具有同名`ID.png`首帧、`ID_strip.png`条、`frames/ID/ID_00.png`至`ID_05.png`及同名SVG源，路径前缀`payload/usable/visual/vfx/`。动画应使用manifest各帧时长，不能只用统一fps抹平非均匀节奏。

|实际条路径|每帧尺寸；anchor|帧时长ms/loop|真实用途|
|---|---|---|---|
|`payload/usable/visual/vfx/cloud_idle_strip.png`|128×80；(64, 68)|160/160/160/160/160/160；循环|Follow actual cloud_holder at a head-top attachment point; numeric countdown remains live UI|
|`payload/usable/visual/vfx/cloud_transfer_strip.png`|128×128；(64, 64)|40/50/60/60/70/80；单次|Once at actual collision-based transfer endpoints; do not delay cloud ownership|
|`payload/usable/visual/vfx/lightning_strike_strip.png`|128×192；(64, 172)|30/40/45/45/50/60；单次|At actual unprotected strike_position from strike result, frame0 immediate|
|`payload/usable/visual/vfx/rod_protected_strip.png`|128×128；(64, 64)|35/45/50/55/60/70；单次|Only actual protected strike branch; center at consumed rod/protected target as confirmed by event|
|`payload/usable/visual/vfx/forge_sparks_strip.png`|96×96；(48, 68)|35/45/50/55/60/70；单次|At small-hammer/anvil visual contact frame while forge state is active; never blade damage|
|`payload/usable/visual/vfx/temper_aura_strip.png`|96×96；(48, 56)|100/100/100/100/100/100；循环|While actual temper_left > 0; stop immediately on expiry or collision consumption|
|`payload/usable/visual/vfx/broad_sword_hit_strip.png`|96×96；(48, 48)|30/40/45/50/55/65；单次|Actual effective broad-sword collision contact, frame0 immediate; no anticipation or delayed damage|

帧数与不同画面数分别记录在manifest；循环回位可能重复，不能把42个逻辑帧说成42个不同画面。场地floor必须显示700×600内区；边框720×620的anchor(10,10)是内场偏移，不是物理世界原点。环境/VFX制作源为`payload/usable/visual/build_environment_vfx.py`及各SVG；保留相对目录后可复现，实际依赖及命令见制作说明。


场边可视护栏：人物/宽刀可视区域横向保留x170..930，不能让侧栏压到真实场边武器；上方效果越界应采用单独表现裁剪/前后层控制；云挂点需按alpha bbox在可视区内clamp，只改云显示偏移，不能改实际持云者或角色位置。表现裁剪不改变世界位置、碰撞或攻击。最终组合场边预览证明及残余限制见QA，不用原180宽稿声称终稿可读性。

VFX与人物分离，锚点不能混用：云挂在持有者头顶挂点；落雷定位真实`strike_position`；保护环定位实际保护目标；锻打火花定位铁砧接触点；淬炼光环围绕兔body origin；宽刀命中火花定位有效命中位置。若事件未发生，不因动画到了某帧制造假命中/雷击。

所有VFX都应随模拟时间推进、暂停冻结、恢复不补播；重开/切场清理。3×时限定表现实例数量但不能吞掉/改变真实伤害。未授权屏幕震动、hit-stop或扩大光效覆盖的攻击范围，不随素材接入擅加。

## 7. 原7条音效映射

路径均为`payload/usable/audio/`，逐字复用上次真实R02音效，48kHz/16bit PCM/mono、不循环。

|文件|时长|事件绑定|
|---|---:|---|
|`anvil_forge.wav`|0.32s|forge小锤实际视觉接触帧，一次/周期，不在每次绘制时触发|
|`sword_wide_swing.wav`|0.31s|如保留独立刃风，跟本次即时命中/回收表现事件；不能播放一个额外预备动作并延迟伤害。与hit并发需混音实测，不因文件存在就强制叠播|
|`sword_wide_hit.wav`|0.39s|真实有效宽刀命中当帧一次；替换现showcase的sword_short_hit加载|
|`duck_cloud_transfer.wav`|0.26s|真实contact造成持云者切换；strike后新轮回鸭要区别语义，不默认当碰撞转移|
|`duck_countdown_tick.wav`|0.095s|模拟剩余时间向下跨整数；改雷表跳变不补历史tick|
|`duck_countdown_final.wav`|0.17s|向下跨余1秒，替代普通tick，不叠播|
|`duck_lightning.wav`|0.68s|真实strike；保护/未保护结果由原逻辑决定，不按预览片固定现实7秒触发|

原说明优先级/ducking/音量/并发只是建议，实际游戏混音需点点验证。暂停音源播放头，静音不积攒旧事件；恢复/重开/切场不补播。倍速短音保持原音高/长度是原提案，不能因此改模拟。没有新增避雷专用WAV则应如实标示，不拿别声冒充。

## 8. 点点需要接入/修改的文件

|文件|现状|需要做的表现接入|
|---|---|---|
|`scenes/showcase.tscn`、`scripts/showcase.gd`|纯Control+代码绘制；默认鸭兔，ORIGIN(270,140)/ZOOM0.8，与新图坐标不一致|将显示映射改为新布局(200,90)/1:1并引入透明角色/环境/UI/VFX；模型位置不变。替换draw_duck/draw_rabbit与代码场景，不保留双份重叠绘制|
|`scripts/showcase.gd.advance()`与音频preload|当前短剑hit、字段差分事件、forge进入时响一次|改wide_hit；即时有效命中事件驱动hit_recover第0帧；锻打/云/倒计时/落雷按真实结果；不得靠动画重复结算|
|`scenes/main.tscn`、`scripts/main.gd`|随机10角色“全部角色”入口，另一套文本UI|本轮只有双角色新视觉；main可继续可用，若同步极简UI用同组件但不谎称其他8角色已重制，不改选人/种子|
|`scripts/fighter_hud.gd`、`scripts/fighter.gd`|默认跟随血条/两CD框，边缘翻侧/clamp|新侧面状态区接管对应信息时避免旧HUD重复；保留数据语义与场边可读性，不误显示就绪可打断|
|`scripts/forge_rabbit.gd`、`scripts/unlucky_duck.gd`|权威玩法与技能逻辑|只读查接口或增加无副作用的表现事件；不改变contact/strike/伤害/CD/保护规则|
|`scripts/battle_arena.gd`、`scripts/arena.gd`、`scripts/ball.gd`|权威模拟、圆体碰撞与位置|保持700×600物理场地、半径质量、固定步、随机序列和结算不变；视觉边框/宽刀不变成新墙或新刀碰撞|

## 9. 仍待完成/未验证与验收

- 本版新制资产必须与实际制作manifest逐路径/尺寸/帧序/源文件对应，透明边缘、锚点和首帧命中由QA复查；打包后新目录解压对hash，不复用旧包验收结论。
- 制作布局是横屏原件，不需要竖屏；但手机横屏安全区、场边/重叠、大蓄伤数值、文本可读性、3×事件密度仍需点点实际接入测试。
- 自动回归仍运行真实Godot：`godot --headless --editor --import --quit`、`godot --headless --script tests/run_tests.gd`、`godot --headless --script tests/test_characters.gd`。检查ERROR/FAIL和退出码，用例数/断言数/manual-device NOT RUN分别报告。
- 本轮美术包校验、源文件可复现或预览图成功不等于游戏接入通过；真机、实际触控/扬声器、人工听审、Godot音画事件同步不能未测声称通过。
- 其余8角色新视觉、完整游戏所有页面、追加音效/音乐及玩法改动不在本轮范围；不把范围外内容写成全部齐全。
