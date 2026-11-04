# R07 UI资源盘点（交付准备）

核对基线：评审仓库`ball_art_review@54d8f8d`的`sources/r06/`；游戏仓库`balls@3dd29e8`。已重新读取根规则、美术负责人/决定、UI岗位及10份独立角色设定（R04八份、R02鸭兔两份）。本轮不修改游戏、玩法、物理、角色或团队配置。用户已确认四页R06最终采用，顶部保留竞技场/主线/仓库/孵蛋四入口；继续暂停手机布局适配，本轮只保证资源可导入，真实手机NOT RUN。用户已进一步确认四页统一为仓库浅色顶部栏；本轮仅派生交付参考与导航token，不改已发布R06网页或游戏。

## 哪些是真原件

|来源|实际存在|分类/使用边界|
|---|---|---|
|R06竞技场B `arena/main.svg`,`info.svg`|1600×900完整矢量组合，嵌入项目原生角色/场地PNG；对应PNG和HTML原型|整图参考与可编辑场景源，**不是一张可直接替换HUD的素材**。元素可以从原SVG节点机械导出，不能裁PNG截图冒原件。|
|R06仓库D展开 `storage/source.html`|完整HTML/CSS/JS、固定/演示个体数据，`main/info/individual/demo_child.png`|PNG是浏览器整页参考；真正面板/按钮/表格来自CSS，不存在已经分层好的仓库PNG皮肤。以StyleBox参数和Godot控件复现。|
|R06孵蛋B `hatch/prototype.html`,`style.css`,`app.js`|工作台、选择、详情、规则、预览、确认、成功、失败、缺亲本、非并列等真实原型状态；10头像PNG|页面PNG仅状态参考，CSS/HTML/流程是制作源；`assets/`中的头像是项目已有原件副本，不是新增角色。成功图为人工内存示意，不是真实孵化/写盘。|
|R06主线D `story/main.svg`,`detail.svg`,`states/`|1600×900档案舞台组合SVG/PNG，4条目主/详情状态和HTML|全页参考。舞台树/房屋/地形有原SVG矢量节点，但尚无Godot独立舞台包；不假称这些图片已游戏接入。|
|游戏 `assets/r04/ui/`|65个独立PNG，其中3个竞技场环境；对应R04原始SVG/制作源在`art-deliveries/R04/source/ui/`|可真实复用原件，尺寸/透明/切片见`ui/metadata/resource_inventory.json`。R04面板160×600、技能槽56×56与R06的230×600、64×64不同，不能无说明混用。|
|游戏10角色头像|R04八个96×96 idle、R02鸭兔96×96 default，透明RGBA|可以直接复用，完整路径/alpha见同一清单；本轮不重画角色，不把整张角色展示图裁成头像。|

R06真实场景源与参考PNG按用途分开。`resource_inventory.json`逐文件列R06参考图的尺寸、分类和现有游戏原件，既有PNG的alpha由Pillow实测，不用“看起来透明”代替检查。

## 本轮已机械导出的14个独立组件

位于`ui/png/`与`ui/svg/`，逐项路径、尺寸、透明、来源选择器、PNG SHA及建议九宫格边距见`ui/metadata/components.json`；源原件保留在`ui/source/input_scenes/`。只选择原SVG图形节点、重设viewBox并从矢量渲染，不使用评审PNG裁剪，不包含角色名、HP、CD、技能名或其它动态文字。

|组件|PNG画布尺寸|原生可见尺寸与用法|
|---|---:|---|
|arena_status_panel|235×606|R06B可见230×600面板，额外右5/下6阴影；建议九宫格L/T/R/B=8/8/13/14。|
|arena_control_button|59×60|54×54按钮外加原阴影；同8/8/13/14。正常态原皮肤，不自行补hover/pressed为已确认。|
|arena_auto_skill_slot|69×70|64×64自动技能槽外加阴影；仅只读CD，不是施放按钮。|
|arena_hp_track|176×10|原HP底轨；蓝/黄动态填充用原色token或R04完整填充条，不烘焙110/120样例比例。|
|arena_cd_overlay|48×34|原14%深墨叠层；代码按真实CD裁高度，不是固定时长帧动画。|
|arena_info_panel|525×366|520×360弹窗外加阴影，文字单独绑定。|
|story_archive_panel|424×677|416×668档案面板，含居中3px描边与右下阴影，建议10/10/16/17。|
|story_action_button|336×91|332×84动作按钮，含居中描边与阴影；建议4/4/6/9。|
|story_entry_selected / normal|295×84各1|原已选/普通条目纯色底，拉伸即可，无新玩法状态。|
|story_search_field|362×64|360×62字段加居中2px描边；建议2/2/2/2，图标/提示/输入独立。|

|story_search_icon|35×36|原搜索圆与手柄矢量节点独立导出，不依赖字体。|
|storage_trait_spark|20×24|原✦字形按实际DejaVu fallback20px转path，基线y20；附字体许可，不是新增图标设计。|

|storage_skill_asterisk|26×30|原第二技能✣字形按实际DejaVu fallback25px转path，基线y25，#698f86；原13件保持逐字不变。|

边距是从已有几何推得的技术切片建议，尚未在Godot九宫格导入验证；允许在保留外观的前提下由点点按控件尺寸验证。阴影额外画布不计入按钮点击尺寸；命中目标按原54×54或实际布局定义，不能把阴影当点击区。

## CSS组件与缺少的状态

`ui/metadata/layout_tokens.json`记录四页原尺寸、颜色、边宽、圆角、padding、已出现的状态及布局。仓库、孵蛋更适合StyleBoxFlat+Container+Label/Table动态实现；CSS外轮廓、外阴影和渐变不保证能由一个StyleBox参数完全等价，需分层绘制或从真实源机械渲染。参数是源事实，不宣称已完成GodotTheme。

- 仓库有普通/已选画廊、操作/次操作、焦点样式，未画的按钮hover/pressed/disabled不擅自补作用户确认状态。
- 孵蛋有普通/primary/hover/disabled/danger和焦点源样式，可按已存在参数复现；失败/成功是界面状态，不改变保存或随机算法。
- 竞技场两技能始终自动CD。已有R04鱼/羊/龟/鸦及鸭兔图标真实可复用；充气球/母鸡/磁铁蟹/仙人掌专属技能及状态图标仍缺，不从角色图裁造图标。
- 主线档案条目、舞台、搜索仅结构占位，不能编关卡、进度、体力、奖励或战斗入口。
- 原源各页导航位置/视觉不同；本轮依据用户明确确认统一采用仓库浅色顶部栏，四入口已确认，详见final_navigation/navigation.json。手机布局适配已确认继续暂停。

## 字体许可与真实中文能力

原游戏`assets/arena-ui.otf`确为Noto Sans CJK SC Regular v2.004（字体name表含Adobe版权与OFL网址），附`assets/OFL.txt`为SIL OFL1.1；但它仅有227个cmap码位，**不是完整中文字库**。常用新导航、仓库、孵蛋汉字和♀♂大量缺失，不能因为字体名字含CJK就声称R06中文完整支持。清单附源文本全集扫描的缺字上界（含代码/注释/fixture，不等于精确可见字表），检查方法不是OCR。

主负责人负责同家族完整SC字库方案：从已授权系统NotoSansCJK-Regular.ttc的SC face2提供完整SC OTF，并附OFL/版权与覆盖检测；不新增字体视觉设计，本子任务不替换游戏字体、不重复打包。实际新字体文件名、SHA、样本覆盖与授权路径由主负责人最终清单为准，Godot/Android字体显示仍需验证。

## 接入界限与复核

世界逻辑仍700×600，R06效果图将其等比映射到`(450,180,700,600)`；不拉伸世界、不改碰撞/物理。当前游戏1100×780与R06参考1600×900是不同表现画布，不能直接把整图坐标写回模拟层。手机适配已确认暂停；安全区/真机未验证，统一导航皮肤已确认仓库浅色顶部栏。本稿不将旧R05手机示意夹带成已批准适配。

运行`python3 ui/source/export_components.py`可从保留的SVG源干净复建14PNG、14SVG和components.json；不依赖游戏或评审仓库。已有65资源的源清单由`audit_inventory.py`只读游戏/评审仓库生成。完整回归、Godot导入、真实手机、性能未在此子任务执行。制作源/资源整理完成不等于游戏已接入，也不等于点点已拿到远端包。

## 实际符号与fallback

R06四页实际源中未出现⌕/⏸/↺/✕，竞技场相关功能是已有原PNG图标，直接复用pause/replay/info及play/sound_off即可；不为不存在的符号制造新图标。仓库✦经Chromium CDP验证实际fallback到DejaVu Sans，现按原字形轮廓转path导出`storage_trait_spark`，许可在`ui/licenses/DejaVu-font-copyright.txt`，来源/字体SHA/基线在`symbol_provenance.json`。仓库ⓘ由完整Noto Sans CJK SC渲染，原227字子集不够，须使用本轮完整SC字库或既有信息图标（若替换应注明外观并非原圆圈i完全一致）。主线搜索已有circle/handle几何，现独立导出。

## 最终包与盘点范围不能混淆

65个R04组件仅是现有资源池盘点，不代表最终R06方案全部使用或应全部重复装包。主负责人将从R06竞技场原SVG的data:image/png逐字解码并以SHA匹配现有游戏原件，把**实际使用**的图标、环境、画像存为独立PNG；这是嵌入原件提取，不是截图裁片。未用R04件不混装为最终方案。14个新机械导出件与CSS参数负责还原R06已存在几何，动态文字仍由代码绑定。完整原CSS已保留`ui/source/input_css/{arena,storage,hatch,story}.css`，包含原选择器次序与优先级；JSON参数用于读懂组件，不声称抹平CSS层叠后就得到完全等价GodotTheme。

## 已确认最终导航组合

`final_navigation/{arena,storage,hatch,story}.png`为1600×900完整组合参考，仅替换用户已确认的仓库浅色顶部栏，保留R06原内容；主线旧底部四页切换按钮已去除。四图是reference，不能冒作独立组件。`final_navigation/source/navigation.css`与`navigation.json`给出92px栏高、底边2px、普通/已选颜色与原138×54按钮位置，去掉header的20固定示例统计和横屏/交互演示标签，只留BALLS与四入口。按钮沿原仓库实测坐标，不因删示例文字移动布局。CSS阴影3px偏移按原皮肤，Godot等效分层绘制需点点验证。原图source_nav_rects只是来源证据，最终布局以这份导航覆盖规范为准。

最终孵蛋目标参考已移除评审专用状态目录、重置示例和已选方向标签，主按钮为“确认孵蛋”（先进入原确认，不跳过确认）；人工成功/失败按钮不作为游戏目标控件。变更仅在final_navigation派生视图，历史R06 source/reference不改。

补充实际可见符号✣（U+2723）：仓库第二技能`.skills i`为25px、#698f86，完整Noto字库仍缺此glyph。CDP对`#skills>div:nth-child(2) i`独立验证DejaVuSans glyphCount1，现提供`storage_skill_asterisk`原fallback轮廓SVG/透明PNG及同一DejaVu许可，不依赖设备fallback。原13组件PNG/SVG SHA逐一未变；14件可从仅source复制的新空目录独立复现29文件完全一致。最终四导航参考图未修改。
