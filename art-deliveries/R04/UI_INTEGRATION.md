# R04 选定左右 UI：独立原件接入说明

用户已接受R04并授权整理给点点。此目录交付实际独立PNG/SVG与参数，不是把评审大图裁成零件；本轮没有修改游戏、旧UI或团队配置，尚未完成真实游戏接入/真机验证。

## 先读路径与分类

- `metadata/ui.json`：65项实际PNG，逐项尺寸/源SVG/用途/九宫格/哈希。
- `metadata/ui_layout.json`：1100×780参考布局、700×600世界映射、10角色字段、控制回调和4组缺失图标。
- `assets/ui/`：R04原图程序机械导出的组件和已经在R04预览使用的原生操作图标。
- `assets/ui/environment/`：原生浅色场地、外木框、屏幕底层，分别700×600、720×620、1100×780，不含角色/HUD/数值；来自已交付R02原件，R04沿用，未从场景截图剥离。
- `assets/ui/retained/r02/`：旧R02的交互态、播放/静音、鸭兔4技能与状态符号、就绪/忙碌标记等，来源明确，**不是新画的R04组件**。
- `source/ui/`：独立SVG、原R04绘图程序副本、机械导出脚本及原生glyph输入；没有把手机截图或已合成主图当制作输入。

所有资源路径均相对整合包根。点点若复制到`res://assets/r04/ui/`等正式资源目录需更新项目引用；这里的res路径只是建议，未由本轮复制到游戏或修改预加载。

## 1. 布局、尺寸与适配

参考画布1100×780，仅横屏。左右状态面板均160×600，坐标(10,90)/(930,90)。物理世界仍700×600，表现左上(200,90)，1:1；外木框(190,80,720,620)仅外装饰，先于角色/特效绘制，不能新增碰撞或把宽刀/充气外观裁在物理圆内。屏幕底层(0,0,1100,780)。

以面板左上为局部原点：头像(56,20,48,48)引用真实透明角色PNG；HP心形(14,105,20,20)，当前HP字基线(42,122)，轨道(14,132,132,9)、内填充(16,134,128,5)；状态符号(14,189,28,28)、数值基线(54,213)；羊电量细条(14,232,132,5)。两个自动技能槽(12,330,56,56)/(88,330,56,56)，28图标相对槽(14,9,28,28)，CD遮罩相对槽(4,4,48,48)，数字基线(40,405)/(116,405)。这是R04原图程序参数，**不是旧R02 64槽坐标**。

全部框组件推荐九宫格边距left/top/right/bottom均8；仅拉伸中段/边，不缩放图标。现有`showcase.gd.nine_patch(path,rect,border)`支持统一边距，点点可传8；不要不经核对沿默认12。HP轨/填充都是矩形，不需九宫格；填充按比例裁宽度。28尺寸图标从原矢量按原预览大小导出，避免从24PNG非整数放大；24基础原件也留存。公共图标为24，倍率/心形另有原显示20尺寸。

Letterbox：先取设备safe rect，`s=min(safe_width/1100,safe_height/780)`；`offset=safe_origin+(safe_size-(1100,780)*s)/2`；世界点显示为`offset+((200,90)+world_position)*s`。角色、道具、反馈和UI同一等比映射；额外宽屏区域只留白/装饰，不改变Arena.arena_size、半径、速度、CD、随机或碰撞结果。48参考像素按钮要在实际设备保证至少44UI点；缩小时只能调整控制层布局/触控，不扩物理世界。safe area、触控、最大充气体积/大泡泡靠边遮栏、长数值均还要点点真测。

## 2. 状态绑定与绘制方式

- HP取`Fighter.health/max_health`；只HP可归一化，实时数值不烘焙。稻草人小HP条取真实60上限，不给不可受伤的TurtleShell造假HP。
- 正CD显示1位小数，遮罩高`48*clamp(remaining/actual_skill_CD,0,1)`，从顶向下覆盖；本包遮罩alpha0.24。CD归零用已画ready薄荷条，不写READY。ready只指CD0，不能打断原动作，必要busy符号保留。
- 每角色两技能仍自动释放，56槽不连接“点击施法”。保留物理/技能/伤害时刻，眨眼只跟实际HP下降，吸收、保护、隐藏另辨。
- 羊charge上限100可用细条，本体和一处羊毛共一个电库。泡泡level、兔stored_damage、刺数量、钉数量没有已知有限上限，不画伪满槽。泡泡所有level数字继续实时绘制；本UI资源符号不是世界泡泡或攻击判定图。
- 默认只HP、关键状态数值、正CD和1×2×3×；角色名/技能名/单位/种子/时间放info按需阅读。动态中文字沿项目现有`res://assets/arena-ui.otf`或项目已授权Font，不增加字体二进制。
- `scripts/fighter_hud.gd`现有近身HP/CD仍存在；新侧栏泛化到main时需避免双份HUD，不能把隐藏旧文本等同删数据或删游戏逻辑。

## 3. 控制与现代码

R04控制条(480,706,600,58)，9个48×48操作位于x=488/544/600/656/724/780/848/904/968、y711，分别暂停、1×、2×、3×、重看、新随机、声音、全部角色、信息。图标与倍率字基线详见layout JSON。原功能全部保留；布局是表现接入，不是本轮已应用到代码。

当前`showcase.gd`已有R02纹理、宽刀音效和`toggle_info()`，固定[5,6]鸭兔。它的`restart(false)`只换鸭兔种子，不能冒称10池随机。`main.gd.restart_battle(false)`才沿`arena.setup(match_seed)`从10角色池不重复抽2，原6个控制/Replay/暂停倍率应保留。main没有同名声音/详情接口，点点若把R04泛化到随机场景应复用showcase的表现能力，而非本包假称现成API。

## 4. 可用图标与仍缺项目

已画鱼：vacuum/eight/bubble；羊：wall/wool/bolt；龟：shell/spin；鸦：swap/feather/dummy，均独立24基础和28实际显示尺寸。旧鸭兔4技能与云/蓄伤符号保留在retained/r02，仍是32px旧图，中心摆位override见JSON。不要把64px旧disabled技能底板与56px新槽无差别替换。

**尚未画出充气球、炸弹母鸡、磁铁蟹、仙人掌各2技能专属UI图标和资源/状态符号。** 本轮只机械导出原图已存在部分，不能把角色展示图裁成“原UI图标”。4家族具体数据字段/时长均列layout；临时可保留空自动CD槽+数字，在info读`skill_names()`解释，这是代码显示建议，不冒充新图标已齐。后续若要专属图标需单独确认制作；不会在本包偷偷补画。

R04正常按钮原造型单独导出`control_button.png`；hover/pressed/disabled并未另设计R04样式，当前项目已用的R02完整按钮家族原样保留供继续引用。R04普通/ready技能槽由原程序已有分支直接导出；R04没有另画56px disabled态，不新增禁用规则。旧R02 busy/ready徽记只作既有可用输入，未声称当前所有角色都已绑定。

## 5. 源复现与验证

复制整个整合包到外部制作目录，运行`python3 source/ui/export_ui.py`。需要Python/Pillow/Inkscape；导出组件不画文字、不依赖字体、不读任何评审主图。脚本从`original_selected_ui.py` AST只读取原`Page/glyph`几何函数，不运行原合成/采样main；公共glyph与环境复制其独立原PNG/SVG。源副本会做空白/行尾规范化，不改变绘图几何；metadata记录实际副本SHA。

PNG建议nearest；图标可直接用SVG按目标密度渲染，框只按8px九宫格拉伸。SVG均提供源尺寸，部分公共20尺寸是原独立glyph的原程序显示缩放导出，未裁截图。

本岗会核PNG可解码/尺寸/透明通道、metadata/路径/源重现；Godot真实导入、游戏绑定、普通受击眨眼正确分支、暂停/倍速/重开/死亡/隐藏、所有10角色、真机可读与触控由点点接入后完整验证。未修改/删测试、未声称真实游戏或设备通过。

## 6. 逐文件索引

|ID|PNG路径|尺寸|九宫格LTRB|用途|
|---|---|---|---|---|
|status_panel|`assets/ui/status_panel.png`|160×600|[8, 8, 8, 8]|左右状态面板，无数字/角色|
|control_strip|`assets/ui/control_strip.png`|600×58|[8, 8, 8, 8]|公共控制底板，不带操作/文字|
|control_button|`assets/ui/control_button.png`|48×48|[8, 8, 8, 8]|R04预览正常按钮底板|
|auto_skill_slot|`assets/ui/auto_skill_slot.png`|56×56|[8, 8, 8, 8]|自动技能状态槽，不是施法按钮|
|auto_skill_slot_ready|`assets/ui/auto_skill_slot_ready.png`|56×56|[8, 8, 8, 8]|CD归零原图程序已有薄荷条，不表示可打断|
|hp_track|`assets/ui/hp_track.png`|132×9|无|英雄HP背景轨；内区[2,2,128,5]|
|hp_fill_blue|`assets/ui/hp_fill_blue.png`|128×5|无|英雄HP满宽填充，仅横向裁切|
|hp_fill_gold|`assets/ui/hp_fill_gold.png`|128×5|无|英雄HP满宽填充，仅横向裁切|
|hp_fill_mint|`assets/ui/hp_fill_mint.png`|128×5|无|英雄HP满宽填充，仅横向裁切|
|hp_fill_purple|`assets/ui/hp_fill_purple.png`|128×5|无|英雄HP满宽填充，仅横向裁切|
|charge_track|`assets/ui/charge_track.png`|132×5|无|已画羊电量细轨|
|charge_fill|`assets/ui/charge_fill.png`|132×5|无|已画羊电量满宽填充|
|object_hp_track|`assets/ui/object_hp_track.png`|44×5|无|稻草人HP轨；非独立英雄|
|object_hp_fill|`assets/ui/object_hp_fill.png`|42×3|无|稻草人HP填充，内区[1,1,42,3]|
|cd_overlay|`assets/ui/cd_overlay.png`|48×48|无|技能图标上方剩余CD遮罩，原透明度0.24|
|icon_bubble|`assets/ui/icon_bubble.png`|24×24|无|R04原绘bubble基础24图标；保留原始角色色，不含数值|
|icon_bubble_28|`assets/ui/icon_bubble_28.png`|28×28|无|R04原预览实际显示28尺寸的bubble图标，避免从24PNG非整数放大|
|icon_vacuum|`assets/ui/icon_vacuum.png`|24×24|无|R04原绘vacuum基础24图标；保留原始角色色，不含数值|
|icon_vacuum_28|`assets/ui/icon_vacuum_28.png`|28×28|无|R04原预览实际显示28尺寸的vacuum图标，避免从24PNG非整数放大|
|icon_eight|`assets/ui/icon_eight.png`|24×24|无|R04原绘eight基础24图标；保留原始角色色，不含数值|
|icon_eight_28|`assets/ui/icon_eight_28.png`|28×28|无|R04原预览实际显示28尺寸的eight图标，避免从24PNG非整数放大|
|icon_wall|`assets/ui/icon_wall.png`|24×24|无|R04原绘wall基础24图标；保留原始角色色，不含数值|
|icon_wall_28|`assets/ui/icon_wall_28.png`|28×28|无|R04原预览实际显示28尺寸的wall图标，避免从24PNG非整数放大|
|icon_wool|`assets/ui/icon_wool.png`|24×24|无|R04原绘wool基础24图标；保留原始角色色，不含数值|
|icon_wool_28|`assets/ui/icon_wool_28.png`|28×28|无|R04原预览实际显示28尺寸的wool图标，避免从24PNG非整数放大|
|icon_bolt|`assets/ui/icon_bolt.png`|24×24|无|R04原绘bolt基础24图标；保留原始角色色，不含数值|
|icon_bolt_28|`assets/ui/icon_bolt_28.png`|28×28|无|R04原预览实际显示28尺寸的bolt图标，避免从24PNG非整数放大|
|icon_shell|`assets/ui/icon_shell.png`|24×24|无|R04原绘shell基础24图标；保留原始角色色，不含数值|
|icon_shell_28|`assets/ui/icon_shell_28.png`|28×28|无|R04原预览实际显示28尺寸的shell图标，避免从24PNG非整数放大|
|icon_spin|`assets/ui/icon_spin.png`|24×24|无|R04原绘spin基础24图标；保留原始角色色，不含数值|
|icon_spin_28|`assets/ui/icon_spin_28.png`|28×28|无|R04原预览实际显示28尺寸的spin图标，避免从24PNG非整数放大|
|icon_dummy|`assets/ui/icon_dummy.png`|24×24|无|R04原绘dummy基础24图标；保留原始角色色，不含数值|
|icon_dummy_28|`assets/ui/icon_dummy_28.png`|28×28|无|R04原预览实际显示28尺寸的dummy图标，避免从24PNG非整数放大|
|icon_feather|`assets/ui/icon_feather.png`|24×24|无|R04原绘feather基础24图标；保留原始角色色，不含数值|
|icon_feather_28|`assets/ui/icon_feather_28.png`|28×28|无|R04原预览实际显示28尺寸的feather图标，避免从24PNG非整数放大|
|icon_swap|`assets/ui/icon_swap.png`|24×24|无|R04原绘swap基础24图标；保留原始角色色，不含数值|
|icon_swap_28|`assets/ui/icon_swap_28.png`|28×28|无|R04原预览实际显示28尺寸的swap图标，避免从24PNG非整数放大|
|icon_speed_display20|`assets/ui/icon_speed_display20.png`|20×20|无|R04实际20px显示的原始speed图标机械导出；未裁截图|
|icon_heart_display20|`assets/ui/icon_heart_display20.png`|20×20|无|R04实际20px显示的原始heart图标机械导出；未裁截图|
|icon_pause|`assets/ui/icon_pause.png`|24×24|无|原有公共操作或HP符号|
|icon_speed|`assets/ui/icon_speed.png`|24×24|无|原有公共操作或HP符号|
|icon_replay|`assets/ui/icon_replay.png`|24×24|无|原有公共操作或HP符号|
|icon_new_seed|`assets/ui/icon_new_seed.png`|24×24|无|原有公共操作或HP符号|
|icon_sound_on|`assets/ui/icon_sound_on.png`|24×24|无|原有公共操作或HP符号|
|icon_roster|`assets/ui/icon_roster.png`|24×24|无|原有公共操作或HP符号|
|icon_info|`assets/ui/icon_info.png`|24×24|无|原有公共操作或HP符号|
|icon_heart|`assets/ui/icon_heart.png`|24×24|无|原有公共操作或HP符号|
|retained_r02_badge_busy|`assets/ui/retained/r02/badge_busy.png`|16×16|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_badge_ready|`assets/ui/retained/r02/badge_ready.png`|16×16|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_button_disabled|`assets/ui/retained/r02/button_disabled.png`|48×48|[8, 8, 8, 8]|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_button_hover|`assets/ui/retained/r02/button_hover.png`|48×48|[8, 8, 8, 8]|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_button_normal|`assets/ui/retained/r02/button_normal.png`|48×48|[8, 8, 8, 8]|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_button_pressed|`assets/ui/retained/r02/button_pressed.png`|48×48|[8, 8, 8, 8]|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_play|`assets/ui/retained/r02/icon_play.png`|24×24|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_skill_forge|`assets/ui/retained/r02/icon_skill_forge.png`|32×32|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_skill_rod|`assets/ui/retained/r02/icon_skill_rod.png`|32×32|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_skill_temper|`assets/ui/retained/r02/icon_skill_temper.png`|32×32|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_skill_timer|`assets/ui/retained/r02/icon_skill_timer.png`|32×32|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_sound_off|`assets/ui/retained/r02/icon_sound_off.png`|24×24|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_status_cloud|`assets/ui/retained/r02/icon_status_cloud.png`|32×32|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_icon_status_stored_damage|`assets/ui/retained/r02/icon_status_stored_damage.png`|32×32|无|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|retained_r02_skill_slot_disabled|`assets/ui/retained/r02/skill_slot_disabled.png`|64×64|[12, 12, 12, 12]|保留既有交互态/鸭兔图标/播放静音状态/忙碌标记|
|environment_arena_floor|`assets/ui/environment/arena_floor.png`|700×600|无|已选浅色场地/外木框/屏幕底层，独立原件|
|environment_arena_wood_frame|`assets/ui/environment/arena_wood_frame.png`|720×620|无|已选浅色场地/外木框/屏幕底层，独立原件|
|environment_screen_surround|`assets/ui/environment/screen_surround.png`|1100×780|无|已选浅色场地/外木框/屏幕底层，独立原件|
