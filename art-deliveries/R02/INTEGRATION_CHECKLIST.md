# R02 素材接入清单（已确认交付版）

版本：`R02-handoff-existing-materials-2026-11-03`。状态：**用户已确认“按此清单交付，缺失项保留说明”。本确认针对现存材料交接范围，不代表缺失素材已经补齐、游戏已接入或新布局/动画方案获批。** 本文仅整理第二轮真实存在文件和当前代码；没有制作新角色/布局、没有修改游戏代码或玩法。此包是现存材料重整，不是找回的完整原始制作包。

本文所有 `payload/` 相对路径均以 `art-deliveries/R02/` 为根；游戏路径以 balls 仓库根为准。可直接使用的音效在 `payload/usable/audio/`；`payload/reference/original-review/` 完整保留评审仓库原件，其中的图片、影片、旧候选及历史文字仅用于追溯，不可整目录自动导入游戏。

## 1. 已确认范围与依据

- A像素风；战斗极简信息布局；只考虑横屏；锻造兔采用第二轮 `broad_sword` 宽剑/宽刀，不另设计细长剑。
- 本轮用户允许：没有完整原包时重新整理一份R02整合包；沿用合并角色设定册，仅整理、不新增设定。
- 合并册是 `payload/reference/original-review/docs/character/CHARACTER_BIBLE.md`。其“待选剑型”是制作时历史状态，**本轮明确宽刀选择覆盖该状态**。没有据此篡改原件、改受保护决定或新建“已经确定”的角色设定。
- 兔造型：淡紫长耳、浅色高光、棕金围裙；宽刀特征为宽阶梯刃、较长刃身、较宽护手、紫色中脊。锻造情景用小锤与铁砧，攻击用宽刀，不能把锤声配成剑命中。
- 鸭造型：暖黄身体、橙嘴/脚、珊瑚帽，无手持武器。雷云转移、倒计时、落雷、避雷针均服从现有游戏规则。
- 当前没有找到各角色独立Markdown、R02透明角色原帧及完整原始制作包。用户授权沿用合并册不等于这些原件已经存在或已补齐。

## 2. 检查基线

|对象|已核实版本/状态|
|---|---|
|balls游戏代码|`018884b2589c6957687d3bdab1f0e9b27c77a528`（本轮开始读取时main）；交付提交应只增加art-deliveries/R02，不改此代码基线|
|ball_art_review原件|`e626fb7753205258a42d67a201f1baa29d5e2476`|
|游戏环境声明|Godot 4.6.3、GL Compatibility、120Hz固定步|
|启动入口|`project.godot`的`run/main_scene=res://scenes/showcase.tscn`|
|现有横屏|viewport 1100×780、窗口990×702、stretch canvas_items/keep；物理场地700×600。这些是代码现状，不是已完成新横屏UI稿|
|实际检查|showcase/main/ball/arena场景；showcase.gd、main.gd、forge_rabbit.gd、unlucky_duck.gd、fighter.gd、fighter_hud.gd、ball.gd、battle_arena.gd；角色册、事件/来源文档、原件尺寸与WAV头信息|

## 3. 可直接导入的选用音效（7项）

以下均从第二轮评审仓库独立WAV逐字复制，不是从视频提取或临时合成。实际读取：48,000Hz、16bit PCM、单声道WAV，非循环；时长如下。音效可作为导入输入，**不表示已经完成游戏内事件绑定或人工听审**。

|文件路径|时长|用途/对象|真实绑定点和使用方式|
|---|---:|---|---|
|`payload/usable/audio/anvil_forge.wav`|0.32s|锻造兔小锤接铁砧|`ForgeRabbit.action=="forge"`期间由表现动画的接触帧事件触发；不能每绘制帧播放。现showcase只在进入forge时播放一次，与接触帧尚未对齐|
|`payload/usable/audio/sword_wide_swing.wav`|0.31s|宽刀挥击|表现层真实出手事件触发一次；没有有效命中时也不能臆造命中声。现代码没有独立挥击事件，需新增只读表现调度|
|`payload/usable/audio/sword_wide_hit.wav`|0.39s|宽刀有效命中|由`ForgeRabbit.contact()`的实际有效命中结果触发；现showcase仍加载短剑hit，应切为此文件。不要为了声音/动画延后`other.hit()`|
|`payload/usable/audio/duck_cloud_transfer.wav`|0.26s|鸭的雷云转移|`UnluckyDuck.contact()`造成持云者变化时一次；需区分碰撞转移与strike后的新轮回鸭，不能把状态变化都默认解释为碰撞|
|`payload/usable/audio/duck_countdown_tick.wav`|0.095s|雷云普通倒计时|模拟剩余时间向下跨整数阈值触发；改雷表±2秒跳变不要补播历史tick。当前无此文件播放逻辑|
|`payload/usable/audio/duck_countdown_final.wav`|0.17s|雷云最后一秒|向下跨余1秒阈值时替代普通tick，不叠播。当前无此文件播放逻辑|
|`payload/usable/audio/duck_lightning.wav`|0.68s|真实落雷|绑定`UnluckyDuck.strike()`结果，不能写死现实7秒循环；保护分支是否播放何声按原事件语义与后续实现确认。现showcase仅未保护分支使用该WAV|

导入建议：Godot AudioStreamWAV→AudioStreamPlayer/SFX总线；总线初始音量、ducking和并发规则见原音效说明，但这些是**原提案，不是已经实装/实测的参数**。现showcase每次`play_sample()`创建AudioStreamPlayer、volume_db=-10、finished后释放，和原文建议SFX总线初始-6dB不是同一层配置；点点应以实测混音定值，不把两个值机械相加。

## 4. 原始参考件与逐项缺口

以下 `R` 表示 `payload/reference/original-review/`，表格中各条保留实际完整路径，避免点点误将参考图当可导入角色。

|路径|已知规格/实际内容|对应对象与正确用途|缺口/限制|
|---|---|---|---|
|`payload/reference/original-review/docs/character/CHARACTER_BIBLE.md`|R02-A-characters-0.1合并册|鸭/兔外观、道具、动作含义、像素规格依据|不是独立角色文档；旧候选状态由本轮四项决定覆盖|
|`payload/reference/original-review/docs/character/weapon_candidates.png`|1200×560 RGB、无透明通道，候选比较板|辨认第二轮宽刀外观/与短剑对照|不是透明角色图、不是精灵表，禁止裁截图冒充原帧|
|`payload/reference/original-review/docs/ui/ui_minimal.png`|780×1688 RGB竖屏整张概念稿|已选“极简信息方向”的历史参考|图中仍有短剑比较样例；既不是本轮宽刀横屏最终稿，也不是UI组件/图标源。不能拉伸/旋转后称横屏适配完成|
|`payload/reference/original-review/docs/ui/ui_simple.png`、`ui_balanced.png`、`ui_detailed.png`（同目录）|均780×1688 RGB|只保留原评审对照与追溯|本轮未选，不作为接入目标，不新增竖屏适配|
|`payload/reference/original-review/docs/motion/rabbit_broad_demo.mp4`|960×540封面配套宽刀概念样片；具体容器参数以交付manifest实读值为准|查看锻造/宽刀挥击/命中表现与音色关系|不是游戏录像、不是透明帧序列、不得从视频提取截图充作原始角色素材|
|`payload/reference/original-review/docs/motion/rabbit_broad_demo_cover.png`|960×540 RGB|宽刀样片封面|仅参考|
|`payload/reference/original-review/docs/motion/rabbit_broad_demo_mix.wav`|整段宽刀展示混音|同步参考|不能取代各游戏事件独立WAV；不能整体循环为战斗配音|
|`payload/reference/original-review/docs/motion/duck_demo.mp4`、`duck_demo_cover.png`、`duck_demo_mix.wav`（同目录）|鸭概念样片、960×540 RGB封面、混音|雷云倒计时及落雷参考|不是实机/真实战斗时序，不冒充动画帧资产|
|`payload/reference/original-review/docs/motion/events.json`|原声明50fps、48kHz；包含短剑/宽刀/鸭三条展示时间线|只采用`rabbit_broad_demo`作宽刀展示参考；鸭用`duck_demo`|原件短剑条目为未选历史，不默认导入；0.28/1.00/2.72/2.80s不能变成真实战斗固定定时器|
|`payload/reference/original-review/docs/motion/rabbit_demo.mp4`、`rabbit_demo_cover.png`、`rabbit_demo_mix.wav`（同目录）|未选短剑样片/封面/混音|原件完整追溯|不作为本轮宽刀接入材料|
|`payload/reference/original-review/docs/audio/sword_short_swing.wav`、`sword_short_hit.wav`（同目录）|48kHz/16bit/mono；0.19s、0.27s|未选短剑历史候选|不得用它们冒充宽刀音色；原件保留不代表选中|
|`payload/reference/original-review/docs/audio/event_rules.md`、`sources.md`（同目录）|R02-A-audio-0.1规则建议与来源|事件语义、混音/暂停/倍速/清理建议及程序原创来源记录|原件“剑型待选/仅本地”是历史制作状态，后续公开授权与本轮选择覆盖；不可把建议称已实现|
|`payload/reference/original-review/docs/ui/font_license.md`、`font_license_evidence.txt`（同目录）|原NotoSansCJK字体与OFL证据|了解原PNG文字来源|没有字体二进制；不是当前游戏`assets/arena-ui.otf`授权的替代证明。后续若分发字体须重新核查具体文件及许可证|
|`payload/reference/original-review/docs/PUBLIC_RELEASE.md`|后续公开授权与范围原记录|解释早期文档“仅本地”的时效|原文“全部源素材/生成源随包”等陈述不能当作本次已找回；以本包manifest实际文件为准|
|`payload/reference/original-review/docs/qa/REPORT.md`|历史本地验收报告|了解曾做过哪些概念检查及限制|其提及的完整帧/QA JSON等在当前可取仓库未找到；本轮不复用历史结论冒充现包完成验证|
|`payload/reference/original-review/README.md`、`docs/index.html`、`docs/web/`|原评审入口、脚本与样式|完整保留相对链接与原公开呈现，离线HTTP参考|本轮不更新/发布评审网页；网页仍会展示旧候选，不代表用户重新开放选择|

其余原件逐文件路径、尺寸、时长、字节与SHA256以包内实际文件manifest为准；不能依据原文引用了某个文件就假称该文件在本包存在。

## 5. 角色帧规格：只有原文声明，当前找不到原件

原设定册描述如下，但本包没有这些透明PNG/strip/GIF、asset_manifest或生成源码，故表中**不是可用素材文件路径**，只是后续寻找原件时的核对线索。不能据此重绘/生成替代品并称R02原始成果。

|原文描述的资产|原文声明|已知播放方式与接入边界|
|---|---|---|
|宽刀兔idle|64×64 RGBA；4帧strip 256×64；每帧160ms|可循环，仅视觉；未实际导入验证|
|宽刀兔attack|6帧strip 384×64；120/100/70/80/130/160ms|index2挥击、index3命中姿势；游戏接触即扣血，不能让概念前摇覆盖真实规则|
|宽刀兔forge|4帧strip 256×64；180/100/80/180ms|index2小锤敲铁砧；匹配锻造语义，不是锤攻击|
|宽刀兔temper|4帧strip 256×64；每帧160ms|原文已注明重复关键姿势，不是完整动画|
|鸭idle/cast/impact|各4帧strip 256×64；每帧160ms|idle轻动、cast少量火花、impact重复姿势；不是全套连续技能动作|

原建议脚底锚点(32,60)未经Godot验证；物理身体中心与脚底不是一回事。`Ball.radius=24`，宽刀长度、铁砧、火花和视觉包围盒均不扩大碰撞/攻击范围。后续若找回帧，nearest采样、帧条左到右/无间隔、整数像素缩放、翻转及脚底对齐需实际测试；GIF合并重复帧后的数量不替代manifest逻辑帧数。

## 6. 点点需要检查/修改的游戏位置（本轮未修改）

|代码/场景|当前实际状态|后续接入要求|
|---|---|---|
|`scenes/showcase.tscn`、`scripts/showcase.gd`|默认Control场景；`draw_duck()/draw_rabbit()`直接代码绘制，并不加载第二轮角色原PNG。`restart()`固定鸭兔[5,6]，隐藏arena后另画表现|角色原帧缺失，因此本包不能完成贴图换装；以后取得真实帧再加Sprite2D/AnimatedSprite2D或AtlasTexture表现。保留BattleArena为唯一模拟源，不新增碰撞|
|`scripts/showcase.gd`音频preload与`advance()`|目前cue_sword_hit为`assets/audio/sword_short_hit.wav`；锻造只在进入forge时响一次；未播放wide_swing和两个tick文件|换用本包wide_hit；按真实表现事件接wide_swing、锻造接触帧和倒计时。路径迁移可由点点放到`assets/audio/r02/`等正式资源目录，并更新引用；那是建议路径，不是本包已存在路径|
|`scripts/showcase.gd._draw()`|场景地板、云、避雷针、转移圈、雷击、伤害字、四技能图标与UI都是代码生成；兔蓄伤数字真实但`blade/60`条形截顶|本包未找到相应独立场景/图标/UI/特效资源。可保持代码表现，具体横屏极简排版待点点实现/评审，不能从竖屏图剥图当素材。蓄伤无上限，不能让条形满格暗示60上限|
|`scenes/main.tscn`、`scripts/main.gd`|“全部角色”入口；随机10角色、文本状态牌和按钮，与showcase是另一套UI|本轮可用素材仅鸭兔参考与7音效，不代表10角色完成A风格重制。横屏极简适配若覆盖main需另改表现层，不动随机选人/种子与模拟规则|
|`scripts/fighter_hud.gd`、`scripts/fighter.gd`|默认每个Fighter建立跟随HUD，场边会翻侧和clamp|避免新UI与既有HUD重复；冷却ready只表CD归零，不能误称可以打断当前不可打断动作。血条绑定health/max_health|
|`scripts/forge_rabbit.gd`|`action`仅idle/forge；无attack状态、无结构化音画事件信号；`contact()`当帧扣伤害，再归零stored_damage/temper_left|只读表现绑定stored_damage、temper_left、action/cd；如要攻击动画需新增纯表现状态或事件，不能新增前摇伤害延迟、剑碰撞盒/额外射程|
|`scripts/unlucky_duck.gd`|真实字段cloud_holder、storm_left、rods、lightning_flash、strike_position；contact转云、strike结算保护与伤害；CD可改雷表|真实转移/strike/保护分支驱动表现；不能照概念视频写死7秒。避雷保护独立音效当前找不到原件，现showcase是play_cue即时合成，不冒充本轮WAV|
|`scripts/battle_arena.gd`、`scripts/arena.gd`、`scripts/ball.gd`|BattleArena为真实模拟；Arena负责位置/圆形碰撞；ball有ball_collided/wall_collided信号|仅列供点点查阅，物理算法、半径、质量、伤害、CD、随机数序列与结算不得因美术接入修改|

### 事件接口：已有与建议必须分清

已有：Ball的`ball_collided/wall_collided`信号；Fighter的health/cd/action；鸭的真实字段和`strike()`；兔的`contact()`。现showcase在`arena.step()`前后比较血量、蓄伤、holder和flash推测表现事件。

尚无：统一的有效命中/挥击/落雷/保护/转移音画事件队列。字段差分在同一固定步雷击与碰撞并发时可能误归因；不能写成已有可靠API。建议点点在不改变模拟计算与随机调用顺序的条件下提供只读表现事件（序号、模拟时刻、源/目标、有效伤害、保护标记）；这是后续实现建议，不是本轮已做代码。

### 动画、声音与模拟的边界

- 角色位置、云归属、伤害与结算服从真实模拟。美术不能增加射程、击退、停顿、随机扰动、伤害延迟或修改技能/物理数值。
- 如果后续取得attack六帧，碰撞发生当帧就必须反馈命中；如何接预备/回收帧需后续实际方案，不能让完整0.29s前摇推迟已发生伤害。当前原帧缺失，本轮不替用户/点点新定动画策略。
- 1×/2×/3×统一模拟时间；动画时刻跟随模拟，短音保持原音高和长度是原音频提案，实际混音待测试。
- 暂停要冻结动画/事件与音源播放头，恢复不重触发。现toggle_pause处理AudioStreamPlayer，但切后台只停模拟，音源暂停仍需核对与改进。
- 静音期间事件状态照常推进但不积攒历史声；重开/切场/结算时清理旧音源、特效节点、队列和去重状态，禁止恢复时补播旧事件。

## 7. 当前找不到原件/未完成项

|类别|当前事实|建议处理|
|---|---|---|
|角色|找不到鸭/宽刀兔透明单帧、精灵条、完整动作原文件，也找不到其生成源码、asset_manifest/character_bible JSON|本轮只交现有角色板/设定/样片参考；请继续寻找旧任务文件/原包，不能裁板/抽视频帧冒充原件|
|场景|找不到第二轮独立竞技场背景、tile、场景源文件|点点可暂沿用现有场景表现代码；本轮不另设计/生成|
|UI|找不到横屏极简最终稿、可编辑分层稿、血条/按钮/状态组件、布局manifest|竖屏minimal仅历史方向参考；点点后续实现横屏代码布局并再评审，本轮不编造尺寸/坐标/适配完成状态|
|图标|找不到独立技能/状态图标透明PNG/SVG源|现游戏图标为代码绘制，不能从整图截图拆出后称R02原件|
|动效|找不到透明VFX帧/粒子原资源、动画工程及渲染源码；现有MP4是合成概念样片|保留样片和events作语义参考；实际落雷/转移/命中效果需点点代码实现或后续获授权补素材|
|音效源码|7条选用WAV齐备；当前找不到原文提及的build_audio.py、build_environment.json、audio_metrics.json|保留原来源记录并说明测量/源码原件缺失，不声称完整可复现原包|
|字体|找不到原R02字体二进制（原文明确未分发）|现有PNG可参考；若游戏分发字体，核查具体文件来源/OFL，不以图片字体说明替代许可证|
|角色文档|各角色独立Markdown当前未找到，现有合并册|用户已允许本轮沿用合并册，禁止自行扩写设定|

本轮没有需要再让用户重选风格/UI密度/方向/武器的问题。**用户已确认按本清单交付，并保留缺失项说明**；横屏具体布局、缺失原素材的制作及新的动画实现方案均不在本轮定稿范围，不把建议视作已批准设计。

## 8. 接入验证清单与当前验证边界

以下是点点接入后的检查要求，不是本岗位已执行的接入结果；包的完整性、解压、哈希等本轮证据另见交付验收报告。

- 资源：Godot实际导入7条WAV无错误；将来拿到原帧后查透明边缘、帧序、脚底/身体中心、左右翻转、nearest与z顺序。宽刀与锻造小锤/铁砧不可串用。
- 语义：有真实有效命中才播wide_hit；雷云归属、倒计时跳变、保护/落雷、蓄伤与淬炼一致；不制造额外伤害/范围或虚假蓄伤上限。
- 生命周期：1×/2×/3×、暂停/恢复、切后台、静音、同局重看、新种子、死亡/结算、切回全部角色，不堆叠/补播旧声音或残留效果。
- 横屏：实际屏幕安全区、长数值、场边、重叠状态、四技能冷却、按钮触控；不要求竖屏适配。整张竖屏稿不能替代这些检查。
- 自动回归：`godot --headless --editor --import --quit`、`godot --headless --script tests/run_tests.gd`、`godot --headless --script tests/test_characters.gd`；检查ERROR/FAIL与退出码。用例通过数、断言数与manual/device NOT RUN分别报告。
- 未验证：实际素材接入、渲染/动画/碰撞同步、手机真机、触控、扬声器及人工听感。本岗位本轮只读代码/文件规格，不宣称这些通过。
