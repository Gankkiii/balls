# R06四页面UI接入清单

**交付状态：R06四页范围已由用户确认；公共导航已确认统一仓库浅色顶部栏。**本清单依据R06指定方向竞技场B／仓库D默认展开／孵蛋B／主线D；用户已明确确认竞技场B、仓库D完整展开、孵蛋B详细流程、主线D占位；采用顶部四入口，继续暂停手机布局适配，仅保证素材可导入。用户最终确认四页统一为仓库浅色顶部栏，全部关键范围已明确。本文件不是游戏接入完成证明；当前交付资源和实施说明，不修改游戏、规则或受保护配置。

基线、函数、字段和建议新接口见`CODE_MAP.md`。已重新读取balls AGENTS、art-team全部规则、全部岗位配置、R04八角色独立设定和R02鸭兔独立设定。balls HEAD及本地origin/main为`3dd29e881d43b0be53170696633a6c118cd7d077`，评审库R06为`54d8f8d48966e1e7af5e8261d44ad31ab9258e55`。

## 当前方向、真实数据与未决项

已定全局：A像素、极简、横屏、兔宽刀。R06指定布局不重复改成A-D选项；上述四页范围已由用户明确批准为本版接入依据，排除评审debug。公共导航采用四页统一仓库浅色顶部栏，四入口顺序竞技场/主线/仓库/孵蛋；继续暂停手机布局适配，仅保障资源格式与导入，不保证横屏手机布局可用，不做手机重排或竖屏。

R06四页是1600×900浏览器原型，不是Godot截图，也不是拆分可用UI全集。仓库/孵蛋20样例中鱼♀、羊♂人工rank3/3，原make_samples是3/5、5/3；不能把fixture覆盖游戏或玩家存档。竞技场鱼HP110/120、羊120/120、电17.5、CD3.8/7.8与1.8/4.8、seed3103/time5.3都是人工布局状态，不是实录轨迹或新平衡。游戏绑定真实字段。

## 交付目录约定

拟提交到`balls/art-deliveries/R06-UI/`，对应评审R06；包内前缀约定`assets/ui/`、`assets/portraits/`、`assets/fonts/`、`reference/{arena,storage,hatch,story}/`、`source/`、`docs/`。实际逐件文件与用途见下表及metadata。整页图和浏览器原型放reference，不能混成动态UI可用组件。

字体岗/负责人已准备同家族完整简体中文OTF（从系统TTC face2导出、未改glyph）及OFL、版权与FONT_AUDIT.json；实际字体为`assets/fonts/NotoSansCJKsc-Regular.otf`，许可`assets/fonts/OFL-1.1.txt`、`UPSTREAM_COPYRIGHT.txt`，字体检查`FONT_AUDIT.json`、`GODOT_IMPORT.txt`、`GODOT_GLYPHS.txt`均位于同一目录。旧游戏227字字体不能直接宣称覆盖所有新文案；本包完整字体仍需Godot导入、中文/符号与排版验收。

## 源件、用途与资源状态

下表原制作路径以评审仓库R06根`sources/r06/`为基准；本包保留同结构于`source/r06/`，例如`arena/main.svg`实际在`source/r06/arena/main.svg`。整页PNG独立置于`reference/`；正式可导入原件位于`assets/`。

| 内容 | 实际原件 | 用途/使用方法 |
|---|---|---|
| 竞技场B | arena/main.svg、info.svg、source/*.svg、prototype.html、main.png、info.png、review.json | SVG含内嵌角色PNG与整页构图；PNG为参考效果，HTML按钮区域可读，不当sprite或整张背景覆盖动态HP/CD |
| 仓库D展开 | storage/source.html、source/build_storage.py、source/base.css、source/fixtures.json、main.png、info.png、individual.png、demo_child.png | HTML/CSS+源生成布局；完整属性默认常驻，截图只reference；原画像从游戏透明PNG复用 |
| 孵蛋B | hatch/prototype.html、app.js、style.css、flow.json、fixtures.json、fixtures.js、screens/*.png | HTML/CSS/JS是可编辑交互源，flow列状态/落点；screens是原型参考，不当Godot组件；fixture只测试 |
| 主线D | story/main.svg、detail.svg、source/*.svg、states/*、prototype.html | 目录/舞台/详情结构参考，所有地点A-D是占位，不编主线内容；整页图不冒充独立环境原件 |
| 既有人物/UI | balls assets/r04/characters/*、assets/r02/characters/{duck,rabbit}/*；assets/r04/ui/* | 已有原生透明PNG优先复用；尺寸/锚点沿既有metadata，兔宽刀不变；本轮不重制角色 |
| 文字/数值 | game_pages数据、main/arena实时状态；字体assets/arena-ui.otf | 用动态Label/控件绑定，不能把静态文字烘焙后伪称实时；字体许可随实际交付核验 |

本轮已有13项独立SVG节点机械导出PNG、17项嵌入原PNG、10张画像、完整字体及20张参考图。组件/布局参数见metadata/components.json和layout_tokens.json；它们不是已接入GodotTheme或四页完整控件。SVG可编辑不表示每个内嵌图片已独立导出，也不承诺所有颜色/文字可矢量编辑。


## 实际可导入文件索引（路径相对本包根）

所有组件静态PNG，非动画，无游戏事件/播放帧；PNG与对应SVG路径见下。九切值为L/T/R/B技术建议，尚未Godot九切验证，不是新视觉批准。保持阴影像素原尺寸，原可见按钮命中54×54，而其PNG59×60含阴影；技能槽可见64×64、PNG69×70。

|文件（assets/ui/）|尺寸px|九切建议L/T/R/B|用途与绑定|
|---|---:|---|---|
|`arena_status_panel.png`|235×606|8/8/13/14|双侧230×600卡底+阴影；数据单独绘制|
|`arena_control_button.png`|59×60|8/8/13/14|底部54×54控制底+阴影；绑定main相应控制|
|`arena_auto_skill_slot.png`|69×70|8/8/13/14|只读自动技能64×64底+阴影；cd_one/two|
|`arena_hp_track.png`|176×10|无|HP底轨；填充172×6按真实health/max_health|
|`arena_cd_overlay.png`|48×34|无|14%墨色半透明遮罩；静态示例遮罩；比例需合法实际周期，不能固定34px当总槽高|
|`arena_info_panel.png`|525×366|8/8/13/14|520×360详情底+阴影；info_open|
|`story_archive_panel.png`|424×677|10/10/16/17|档案面板416×668含居中描边/阴影|
|`story_action_button.png`|336×91|4/4/6/9|查看档案按钮332×84含描边/阴影；待定入口禁用|
|`story_entry_selected.png`|295×84|0/0/0/0|已选目录条目纯色底，绑定视图selected|
|`story_entry_normal.png`|295×84|0/0/0/0|普通目录条目底|
|`story_search_field.png`|362×64|2/2/2/2|360×62搜索底含居中描边；动态输入|
|`story_search_icon.png`|35×36|无|原搜索矢量图标；不依赖字体|
|`storage_trait_spark.png`|20×24|无|原DejaVu实际fallback字形，baseline20；装饰非特性效果|

每个组件对应`source/ui/components/{同名id}.svg`；机械导出源`source/ui/source/export_components.py`，输入源在`source/ui/source/input_scenes/`。请在独立副本执行脚本，它会写该副本`source/ui/{png,svg,metadata}/`，不会自动更新正式`assets/ui/`；核对后再按manifest复制，不能把生成目录名误当运行路径。

### 嵌入原PNG（17项）

|文件|尺寸|用途|
|---|---:|---|
|`assets/ui/embedded/arena_wood_frame.png`|720×620|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/arena_floor.png`|700×600|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/idle.png`|96×96|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/idle_c8586c95.png`|96×96|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/wool.png`|96×96|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_heart.png`|24×24|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_bubble_28.png`|28×28|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_vacuum_28.png`|28×28|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_eight_28.png`|28×28|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_info.png`|24×24|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_bolt_28.png`|28×28|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_wall_28.png`|28×28|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_wool_28.png`|28×28|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_pause.png`|24×24|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_replay.png`|24×24|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_new_seed.png`|24×24|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|
|`assets/ui/embedded/icon_sound_on.png`|24×24|原PNG图标/竞技场环境/画像；按original_game_paths识别用途，动态数据另绘|

### 画像（10项）

|文件|尺寸|用途|
|---|---:|---|
|`assets/portraits/puffer.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/chicken.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/bubble_fish.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/electric_sheep.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/magnet_crab.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/duck.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/rabbit.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/cactus.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/shell_turtle.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|
|`assets/portraits/crow.png`|96×96|仓库/孵蛋/状态卡角色画像；单帧非完整动画|

画像均96×96 RGBA单帧、nearest、keep_aspect_centered，不拉伸；它们用于卡片/仓库/亲本，不代表完整战斗动画。已有战斗帧继续从游戏assets/r04或r02复用，不能用头像替代动作。embedded的bubble/wool是独立物件原件，不可作为额外技能图标或新增物件规则。

17项embedded为原SVG image href逐字解码，来源对应metadata/embedded_assets.json，包含场地/框及原图标等；不是从参考图裁切。本包不重复全65项R04资源池；metadata/resource_inventory.json是盘点，不是承诺65项全在本包或均适合R06。

最终统一导航四图优先：`reference/final/arena.png`、`reference/final/storage.png`、`reference/final/hatch.png`、`reference/final/story.png`。原20图移至`reference/r06_original/{arena,storage,hatch,story}/`，仅作为完整子状态参照；见metadata/reference.json，全部1600×900。旧子状态接入时只替换为统一新header，其余业务流程按原型，不恢复旧导航。source/r06保留的原型不自动升级为runtime。

## 逐页实施和状态

### 公共导航

将四页映射GamePages现有0..3，保留切离竞技场暂停+停音、回竞技场不自动继续。同页导航不重置选中对象。单一owner建立导航；公共导航已确认统一仓库浅色顶部栏，不同时复制四套页内导航和评审网页导航。评审按钮、状态目录、重置样例不进入正式游戏。

### 竞技场B

左右卡读取当前两位英雄；HP条按health/max_health，显示数与精度需符合真实值；CD正值显示、自动技能仅只读。暂停、1/2/3倍、重演、新局、声音、详情对应现有main回调，不用原型变量驱动战斗。i打开同一信息窗，×关闭；模态遮挡点穿需要实现。详情seed/time/技能名随实时数据。

R06世界700×600@450,180等比1:1；现游戏1100×780、world700×600@200,90。1600稿接入应由视口/呈现布局变换处理，不改arena_size、radius、碰撞或实际位置。具体屏幕基准以最终布局metadata为准，手机布局继续暂停；禁止把原型里的坐标直接写物理状态。

泡泡level数字含1且无玩法上限；羊电共享一份，不因两条视线产生双倍伤；无上限蓄伤/数量不能用假封顶条。普通实际HP减少才眨眼，免伤/隐藏不伪受击。现有羊两线、鸭impact、兔眼层是已知表现缺口，与本次布局交接分列；不在本轮擅改技能。

### 仓库D默认展开

始终显示完整六属性×四数据列：生命/攻击/防御/速度/重量/大小；种族基础/先天/后天/最终。base/final仍待定，不能先天+后天造结果。画廊箭头、相邻卡、直接选择器都更新同一selected；前后边界禁用；实际仓库长度包括本机后代，不限网页20/21例。人物性别/Lv/编号、当前及另两特性、2个技能+n、余3技能跟随个体更新。属性说明浮层Esc/遮罩/×关闭后仍展开，不返回折叠旧主状态。

特性3全待设计，5技能仅前2有名，其他保持占位；不新增训练、培养、出战、稀有度、装备、排序删除等未有功能。仓库个体数据目前不驱动BattleArena随机战斗，不假称培养已影响战斗。

### 孵蛋B

当前真实mother/father初值-1。首次进入缺亲本状态，已选后返回保留同会话选择；图中鱼羊非正式预选。R06预选只是人工样例，不是更改初态指令。工作台→选母/父候选列表（性别过滤）→完整详情→使用/取消；临时候选不提前替换已选。只有真正换母亲重置平级选择，同母再使用保留。母最高不平级时技能1自动只读；平级二选一。详情包括三特性槽、五技能池、六属性四列。

规则/预览只展示种类、trait、初始Lv0、第一技能身份、rank与先天范围；不提前生成随机对象。确认取消保留选择；正式执行仅调用一次hatch_creature。真实保存成功后显示该实际child并可跳仓库选中；失败不入仓、不显示假“已保存”，返回预览/修改/再次确认；真实再次执行会重新随机，不承诺同一个失败结果。

child.level恒0；技能1rank在双亲各自最高rank含端点范围内随机，较高<10另有临时1%覆盖高值+1。技能2从母种5槽排除第一项抽剩余4，rank1..9权重9..1；六先天逐项双亲范围内随机，training0；特性/种类随母、性别随机。不要把旧preview“等级”歧义带入新UI，明确“技能强化+n”。保留当前临时概率标记，不把本轮美术接受升格成长期数值批准。

“演示成功/失败”“重置示例”“状态目录”“#21内存对象”是评审工具，不能进入正式游戏流程。确认界面只给真实执行入口与取消，不让玩家选择执行结果。后代不能固定sex0/rank2=2/取先天低值，也不能只从两个已命名技能抽取来绕过现有占位池。

### 主线D

按档案+舞台结构组织纯UI占位，目录/搜索/查看/详情/返回/说明均为待实现视图交互；无匹配有反馈、清搜索恢复、关闭回原选择，顶部返回竞技场遵守全局导航。地点A-D只是布局占位，同一占位舞台不能变成已确定地图原件。无章节/奖励/体力/进度/解锁机制，待定入口禁用，不造“开始战斗”绑定。

## 点击区域、适配和代码效果

R06真实热点可从各prototype.html的button位置、仓库CSS和hatch布局取得；导出后须用最终metadata/layout_tokens.json及metadata/hit_regions.json核验每个控件rect、z、enabled和返回目标，不以截图OCR猜测。竞技场底8控件R06为54×54@x550/614/678/742/806/870/934/998,y811；两侧i40×40@259,699与1295,699，info关闭54×54@995,278。它们是1600稿像素，不等于手机触控尺寸达标。公共导航顶部四入口已确认，皮肤已确认仓库浅色，最终热点以metadata/navigation.json为准；手机布局/安全区/触控未验证且本轮不做重排。

HP/电/CD填充、禁用/选中/hover/focus、滚动、模态、搜索无结果、提示消失、角色切换、真实结果页需代码实现；图片不是实时系统。新UI动效不得暂停伤害、改变模拟速度或增加硬直。切页/静音/重开/后台处理沿main现有生命周期，不新增音效或改变R04事件音高。

## 缺失、冲突与验证

- 已确认：R06四页作为接入依据、顶部四入口、排除评审debug、继续暂停手机布局适配且仅保证资源可导入。
- 所有关键范围已确认：公共导航统一仓库浅色顶部栏；不再待选。
- 运行实现尚未完成：组件原件已提供，完整运行状态、Godot控件与导航点击绑定仍需点点实现；不用整页截图替代。
- 未定：种族基础/最终公式、3特性效果、3未设计技能、培养关联、主线玩法；保持占位。
- 旧Puffer共享0.35秒与新每目标CD差异仍待用户核对；不在UI交接中自行改规则。

验收：每一导航进入/返回、切离pause+停音与回场不自动恢复；四页控件焦点/遮罩/禁用；竞技场所有10角色资源、HP0/满/大数/CD0/忙碌、1/2/3/暂停/重演/新局/静音/后台/结算；仓库所有20样例及真实新后代、6×4始终展开；孵蛋缺亲本/取消不改/平级/非平级/换母/预览无随机/确认只执行一次/失败不入仓/成功实child/保存重启恢复；主线空搜索与禁用待定入口。

点点开发后需真实Godot导入与完整原有回归，不删改测试以掩盖失败，分别报测试数/断言数、人工/设备NOT RUN。当前本文件验证仅只读核代码与源资料，未运行新UI、真实写盘、Godot接入或手机验收；网页桌面点击通过不等于游戏通过。

现有回归入口：在Godot4.6.3项目目录执行`godot --headless --editor --import --quit`、`godot --headless --script tests/run_tests.gd`、`godot --headless --script tests/test_characters.gd`；核输出错误与退出码，不用浏览器测试替代。页面/孵化子用例在tests/page_cases.gd、hatching_cases.gd，现有总runner是否覆盖由点点完整执行日志确认，不删测试。

## 图层、CSS实现与缺少的运行态

建议绘制顺序（实施建议，非新设计）：屏幕底色/环境→世界物件与人物→面板/画廊/表格→动态图标、HP、电、CD与文字→公共导航与底控制→模态遮罩/弹窗→焦点/状态提示。世界装饰不得遮挡碰撞关键对象，模态层阻挡后方点击。CSS阴影应单独下层绘制；阴影不扩展点击rect。

仓库/孵蛋本来是CSS，并无分层PNG全集，按`metadata/layout_tokens.json`及`source/ui/source/input_css/{storage,hatch}.css`用StyleBoxFlat/Container/Label/Grid控件复现。仓库面板bg#fcfaf2、border#bac7b8/2px、radius10、padding24、shadow5,5；孵蛋bg#fff9eb、border#243746/3px、padding22、直角，normal/primary/hover/disabled/danger参数保留原来源。CSS渐变/外阴影需shader或分层代码，不承诺一个StyleBox完全等价。

组件包含既有normal与主线selected；仓库按钮未画hover/pressed/disabled、竞技场未画全按钮状态，不称素材齐全。点点可沿现有引擎状态/原CSS产生必要反馈，但明显新皮肤先回报；焦点/禁用不能丢。Puffer/Chicken/MagnetCrab/Cactus专属技能和资源icon仍缺，保持现有1/2读数占位，不截角色图造图标。主线独立分层舞台仍未导出为运行环境包。导航已由用户最终选定仓库浅色顶部栏，以metadata/navigation.json与最终四图为准。

## 路径与审阅状态

上述assets、组件源与metadata按当前交付实物核对；新说明中的Godot控件/图层/接口扩展是实施建议，用户已批准的是R06四页范围与顶部四入口，不称其已逐条审批本文技术建议。字体导入证据只说明所记导入环境，不证明完整四页游戏或手机可用。最终QA/压缩包解压与SHA以主负责人实际QA记录为准，本岗位未执行打包/上传。

## 最终统一导航（用户已确认）

四页统一仓库浅色顶部栏，高92px，顺序竞技场→主线→仓库→孵蛋。最终颜色、按钮rect、选择/普通态以`metadata/navigation.json`为准，源`source/navigation/`；这属于本次确认的表现变更，不改switch_page路由和切页暂停语义。主线删除原底部旧导航，不因旧参考图恢复bottom nav；地点与舞台仍占位。孵蛋不保留原深色顶栏，竞技场不保留旧独立header。

文档位置为包内docs；在Markdown中需要点击链接时从docs使用相对上一级，例如[导航参数](../metadata/navigation.json)、[最终竞技场](../reference/final/arena.png)、[最终仓库](../reference/final/storage.png)、[最终孵蛋](../reference/final/hatch.png)、[最终主线](../reference/final/story.png)、[组件清单](../metadata/components.json)。文中代码路径均相对包根，不把docs当根目录。最终四图仍是参考图，不当整页runtime背景。

## 冻结补充：实际导航几何、字体与复用件

已读最终`metadata/navigation.json`：header_rect=[0,0,1600,92]；底色#faf8ef、底边#c2cbbd/2px，其余边0、直角。四按钮均138×54，y18，竞技场x813.71875、主线x963.71875、仓库x1113.71875、孵蛋x1263.71875。普通透明底/透明2px边；选中#d7e9dc、#648d7b/2px边、右下3px阴影#9db5a3。该平移阴影宜单独矩形层，StyleBoxFlat阴影映射未验证。文字22px Regular、#293d40；品牌x42、27px，源900字重层级需实际字体绑定，不声称Bold700与900完全等价。公共header在页面内容上层、模态遮罩下层，始终单一owner，原子状态不能再叠旧导航。

包根真实样式`source/navigation/source/navigation.css`；重建源`source/navigation/source/build.py`、捕获源`source/navigation/source/capture.cjs`。在独立`source/navigation`副本运行，按metadata中rebuild说明启动HTTP与捕获；不得把源内保留的原navigation.json相对路径当交付包根路径。components.json同理优先delivery_file/delivery_source，source_base_directory=source/ui。

字体完整两份：`assets/fonts/NotoSansCJKsc-Regular.otf`及`assets/fonts/NotoSansCJKsc-Bold.otf`；审计`assets/fonts/FONT_AUDIT.json`、`assets/fonts/FONT_BOLD_AUDIT.json`。正文与粗标题/强调要实际绑定Regular/Bold，不能只设置虚拟weight以为Godot自动取另一font。字体可导入不代表新布局与全部文案排版已验收，手机布局仍暂停。

12个真实复用件均在`assets/ui/reused/`，尺寸与SHA见`metadata/reused_assets.json`：

|文件|尺寸|用途|
|---|---:|---|
|icon_play.png|24×24|暂停后的继续图标|
|icon_sound_off.png|24×24|静音态|
|icon_skill_timer.png|32×32|鸭调整雷表|
|icon_skill_rod.png|32×32|鸭避雷针|
|icon_skill_forge.png|32×32|兔现场锻造|
|icon_skill_temper.png|32×32|兔淬火|
|icon_shell_28.png|28×28|龟入壳|
|icon_spin_28.png|28×28|龟壳纹旋转|
|icon_swap_28.png|28×28|鸦交换位置|
|icon_feather_28.png|28×28|鸦储羽技能|
|icon_feather.png|24×24|储羽状态|
|icon_dummy.png|24×24|稻草人状态|

所以泛用/鸭兔龟鸦已画图标并非全部缺少；仍缺充气球、母鸡、磁铁蟹、仙人掌专属技能家族。现有1/2占位可保持原行为，但不是本轮新定设计。不把复用资产扩展为新动作或玩法。

**CD与HP精度：** R06的48×34遮罩只是静态排版示例，不能由它反推百分比或满CD字段。Fighter仅有cd_one/cd_two剩余，未发现统一max_cd API。点点若做比例遮罩，应从各实际技能重置常量/现有逻辑取得对应周期，添加纯表现接口，不修改剩余计时；找不到合法分母时先显示真实剩余+就绪，不能随意设周期。HP直接跟真实health及max_health，不预设新的插值时长或延迟伤害反馈。

**音频/动画缺项：** 本包未制作导航、确认、成功/失败等新UI声音，也没有这些UI的专用动画序列帧。不要用战斗声音替代UI声；既有battle声音仍沿真实事件触发且不改计时。必要控件状态/淡入等若实现属于纯代码表现建议，不能写成包内已提供专门动画。最终孵蛋主图“确认孵蛋”只打开确认态，不立即执行；状态目录、重置示例、演示成功失败已从最终目标视图移除，历史R06 JS仅保留来源，不复制调试按钮到游戏。

## 原字形补件

仓库`✦`与`✣`不在完整Noto SC中，已按原浏览器实际DejaVu fallback字形分别提供`assets/ui/storage_trait_spark.png`、`assets/ui/storage_skill_asterisk.png`及同名SVG源。后者是第二技能行的通用符号，不是缺失四角色的专属技能图标。使用这两个原件，不依赖手机系统备用字体；许可和原轮廓证据见source/ui/licenses与metadata/symbol_provenance.json。

## 实测点击框

[点击区域实测](../metadata/hit_regions.json)记录统一导航派生参考中14个浏览器源状态的控件框及滚动裁剪框；公共导航以navigation.json为准。数据是1600×900设计坐标，不能直接当手机dp或Godot已绑定证据。被移除的评审调试控件不入运行清单；正式确认页真实执行按钮需点点按本清单实现，不能把原型中隐藏的人工结果按钮当实际执行。
