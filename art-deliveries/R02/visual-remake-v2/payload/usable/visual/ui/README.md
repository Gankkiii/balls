# R02 左右状态极简横屏 UI：本轮重制原件

用户已确认左右状态区、浅色场地、横屏极简。本目录是本轮全新制作的可导入UI组件与原始SVG源，不是找回的旧R02源，不从任何评审图/截图/视频裁切。制作不改游戏代码或团队配置。

## 文件

- `source/*.svg`：每个组件独立、可编辑的原始几何源，像素对齐，无外部图片、字体或网络依赖。
- `png/*.png`：对应尺寸的独立RGBA PNG，供Godot导入；动态文字/HP/CD/技能数字不烘焙。
- `source/build_ui.py`：本轮原创源构建程序，读取自身几何定义，使用Inkscape导出PNG，不读取旧图片。重新运行须在用户授权的制作任务内，避免覆盖已审核交付版本。
- `ui_manifest.json`：每项尺寸、用途、源/导出路径、SHA256及九宫格边距；边距顺序为left,top,right,bottom。
- `layout.json`：1100×780横屏布局、左右状态、场地视觉映射、安全区与数据绑定。
- `../../../../reference/previews/ui/`：原件组合的布局/组件预览，仅检查用，不可作为游戏原件拆图或替代独立组件。

## 统一规格

深蓝灰描边#243746、奶油面#F7EBCD、浅木#D9BA8C、金黄#EFC65B、珊瑚#E77D65、紫#B89ACF、薄荷#8FBDB1。SVG使用crispEdges及整数坐标；PNG导入建议nearest，关闭mipmap。PNG内透明边角有意保留，不加一整块底色。

左右面板160×600，参考位置(10,90)、(930,90)；中间700×600场地@(200,90)，外框720×620@(190,80)。两侧各留30像素视觉护栏，角色/宽刀不得裁切到物理地板；装饰边框应先于角色绘制。标题区域底边为56，避开上墙兔耳。 这些只是视觉/UI坐标，不改变物理场地。实际Arena仍700×600单位。未把场地/角色/数字合并为一张不可拆图。

## 减字交付修订（用户已确认按这版交付）

按用户“字多需减少”的反馈，游戏画布只常驻头像、心形+当前HP、云+倒计时、刀/∞+无上限蓄伤、技能图标及正CD数字、三个倍率标签。角色名、READY、技能名、AUTO SKILLS、Rod1/2、Temper1.5x、常驻事件提示、Seed/time和长标题都默认隐藏。就绪用已有描边/徽记，针数量用两个针图标，淬炼用图标/边框，不改变规则或删除原功能。第9个info图标建议展开查看种子/时间、最大HP、单位及术语；这是需点点新增的纯UI详情，不是已有API。

实际示例字串由preview源逐条记录，非OCR：旧默认160个非空白Unicode字符，新稿22个；真实状态数值变长时字符数也会变化。`UI_TEXT_METRICS.json`列出原字串和坐标。审阅图片1100×828，顶部48px为画布外“示意数据/非实机”caption；游戏画布仍1100×780，从图中(0,48)开始，caption不算游戏UI常驻字。用户已明确确认“按这版交付”。该确认针对本轮少字交付方案，不代表游戏内接入或真机验证通过。

## 接入规则

|组件|建议Godot节点/方法|边界|
|---|---|---|
|status_panel/control_strip/inset_panel/button四态|NinePatchRect 或 StyleBoxTexture，按manifest设置边距|只拉伸边/中心，不拉伸图标；button真实输入范围至少44设备UI点，参考图为48×48|
|hp_track/hp_frame/hp_fill_gold/purple|轨道和框分层；TextureProgressBar或裁切fill|只绑定health/max_health；fill裁切，不改变伤害/生命值。禁止用HP条给无上限stored_damage造假上限|
|skill_slot_normal/ready/disabled|自动技能状态底板，不连接点击施放|ready只表示CD<=0；不可打断动作仍加busy徽记|
|cooldown_overlay|Overlay TextureProgressBar按剩余CD比例裁切|remaining/实际CD，不能按绘制帧计时；普通白色/灰色遮罩视觉不定义技能规则|
|cooldown_ring_track/fill|可选径向TextureProgressBar|和方遮罩二选一，极简界面不要重复两套进度；默认建议方遮罩+实时秒数|
|badge_ready/busy|小状态标记|不能以ready覆盖真实busy。disabled仅真实不可用状态|
|icon_pause/play/speed/replay/new_seed/sound/roster|独立TextureRect置入操作按钮|仅倍率1×/2×/3×常驻；当前静音用图标状态，其他辅助标签按需info显示|
|icon_skill_timer/rod/forge/temper|32×32独立技能图标|分别映射改雷表/避雷针/现场打铁/淬炼；锻造小锤不等于战斗武器，宽刀攻击仍由角色素材承担|
|icon_status_cloud/stored_damage|32×32状态图标+实时数值|云归属和倒计时来自真实模拟；stored_damage数值无上限，不放“蓄满”槽|

点击控件只是既有暂停/倍率/重看/新种子/声音/全部角色操作，不添加游戏系统。头像区域应引用本轮角色原PNG，不从旧截图裁出头像。本文未附新字体二进制；实际中文字体与许可证由点点按游戏具体文件核查。

## 适配和验证

先按设备safe rect均匀缩放1100×780参考画布；多余区域作为装饰边，不能扩大物理场地。若缩放后按钮小于44设备UI点，需要只对控制层抬高物理UI尺寸并在底边余量重排，不能简单压缩触控目标。必须由点点在实际设备测试。

已验证：SVG逐文件导出、PNG格式/尺寸/透明通道、源文件无嵌入图片、独立组件与manifest一致。未验证：游戏内节点接入、触控/安全区、CJK文本/极端长数值、实际游戏中的96×96角色动作与左右状态区重叠（本轮已做静态alpha包围盒和组合墙边预览检查）。预览是新原件组合图，不是游戏实机截图。

来源：本任务新编写几何图形，无下载第三方图形、无现有截图输入。Inkscape仅为源导出工具；未把其程序或系统字体打包进来。本声明不构成排他权或法律审计结论。

## 源复现前提

仅复现36个组件可复制整个ui目录到外部制作区，运行`python3 source/build_ui.py`（需要Inkscape），不依赖截图或游戏文件。组合审阅图用`python3 source/build_preview.py`，需要同级`characters/`、`environment/`的新制原件，因此应复制完整visual目录到外部制作区；该脚本会自行创建ui/preview目录，不依赖包内已附预览文件。预览文字使用系统DejaVu Sans，只渲染说明，不分发字体二进制；需要Pillow与该环境字体。生成预览仍只是原件组合，不是游戏实机渲染。


交付预览归档说明：本包预览在 `reference/previews/ui/`（包根），而制作源会在新副本下自建preview目录。组合图不是可导入组件或实机截图。
