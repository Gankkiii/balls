# R06 UI代码映射（只读核查）

检查：balls HEAD及本地origin/main=`3dd29e881d43b0be53170696633a6c118cd7d077`；评审R06=`54d8f8d48966e1e7af5e8261d44ad31ab9258e55`。未改代码、未运行新游戏验收。以下路径相对balls；R06路径相对ball_art_review。当前场景`scenes/main.tscn`→`scripts/main.gd`，`r04_view.gd`只表现，`game_pages.gd`CanvasLayer承载页面。

| 页面/功能 | 现有真实接口/字段 | R06表现与开发边界 |
|---|---|---|
| 四页导航 | game_pages._ready创建四tab；switch_page(index0竞技场/1主线/2仓库/3孵蛋) | 复用真实路由，不复制iframe postMessage；四页统一仓库浅色顶部栏已确认，高92px；四入口arena/story/storage/hatch，rect与颜色看metadata/navigation.json |
| 切离战斗 | switch_page从page0离开→main.set_rate(0)+stop_sounds；回0不恢复 | 保留原战局/选中倍率；不把切页当新战斗，返回后显式继续 |
| 战斗速率/暂停 | main.set_rate(1/2/3)、toggle_pause、selected_rate、rate | 读取真实状态，不复制原型paused/rate变量；固定dt1/120；不改BASE_TIME_SCALE |
| 新局/重演 | restart_battle(false/true)、match_seed、BattleArena.setup(seed) | New生成新seed随机10种选2；Replay同seed；清战斗/物件/表现与音频，使用selected_rate开始 |
| 静音/详情 | main.toggle_sound、sound_enabled；toggle_info→visual.info_open | 原型无实际声音，游戏已有真实声音；i/×可新增纯视图打开关闭绑定，不能改数据 |
| 双侧卡/HP/CD | r04_view.draw_panel；arena.heroes、health/max_health、cd_one/cd_two、skill_names | R06鱼110/120只是样例，禁止常量写入；CD0不显示倒计时不等于可手动释放 |
| 世界/物件 | main arena_size700x600,pos200,90；r04_view.ORIGIN200,90；draw_actor/_draw | R06世界700x600@450,180是1600x900稿；不得改physics来匹配稿，可建立只读显示变换 |
| 资源值 | Puffer.gas/immune_left；Sheep.charge/wool_active/wool_position/zapping；duck.storm_left/rods；rabbit.stored_damage/temper_left；Crow.feather/dummies；Turtle.shell/spin_left/action | 绑定真实每角色字段；无上限值用数字不画假封顶条；新卡不新增技能/增益 |
| 主线现状 | game_pages.build_story()仅占位文字 | R06档案目录/搜索/详情/返回均需新增视图逻辑；无关卡、解锁、奖励和进度接口，待定按钮禁用 |
| 仓库来源 | game_pages.make_samples/load_hatchlings/samples/selected | 20个临时固定示例+合法本机孵出对象；真实数据不使用R06内存#21对象替代 |
| 仓库选择 | build_storage、storage_selected(index)、show_detail | R06画廊前/后/下拉/相邻卡均调用相同选择更新；边界禁用；完整6×4默认常驻，无折叠旧状态 |
| 人物画像 | portrait_path(species)、portrait；R04八角色idle与R02鸭兔default | 复用既有透明原件，不能裁R06整页图当人物素材 |
| 个体资料 | creature_title、skill_name、TRAITS/STATS/SKILLS；c.species/sex/level/trait/skills/ranks/innate/training/number | 特性3全待设计；技能5仅前2有名；六属性生命攻击防御速度重量大小；基础/最终待定，后天当前0 |
| 亲本状态 | mother/father索引、tie_choice、build_breeding、refresh_breeding_preview | 原代码选择器直接提交；R06候选浏览+使用/取消需新增临时candidate，确认后写mother/father，不提前改数据 |
| 平级选择 | 母亲ranks[0]==ranks[1]才显示tie_choice，否则取最高 | 仅真正换母亲重置tie；同母亲再次“使用”不丢选择是R06要求的视图改进；父亲技能身份不继承 |
| 预览/规则/确认 | 目前refresh_breeding_preview内展示规则并直接hatch | 新增预览/确认/规则纯视图状态；预览只身份/范围不调用RNG；不增加耗材/等待/次数 |
| 真正执行 | hatch_creature→append_hatchling→成功samples.append/selected；hatch_notice | 只有正式确认提交调用一次；保存成功才到成功结果/仓库；失败不加入samples |
| 遗传rank | hatch_creature、random_skill_rank | child.level固定0；rank1由双亲各自最高rank区间抽取+临时1%突破，rank2权重9..1；旧preview“等级”应澄清技能强化 |
| 存盘/加载 | SAVE_PATH user://balls_hatchlings_v1.jsonl；append_hatchling/load_hatchlings/valid_hatchling | 保持追加/坏行跳过/不截断；真实失败重试再次调用会重新随机，不承诺相同结果；不可将原型内存postMessage当存档 |
| 生命周期 | main._notification、stop_sounds、_exit_tree、advance_real_time | 焦点丢失暂停音频/模拟积累；结算停止；UI新弹窗不擅自改模拟暂停规则 |

## 需要新增的纯表现接口（建议，不是假称已存在）

- 页面视图状态：主线条目/搜索/详情/说明；仓库说明浮层、画廊；孵蛋workbench/pick/detail/rules/preview/confirm/result/failure。
- 孵化结果回传可令现有hatch_creature提供“保存成功+child或selected”与“保存失败”视图结果；保留当前一次随机、先落盘再入仓顺序，不能再次随机只为拼结果页。
- 全局导航只能有一个UI owner；原型内部四导航与网页宿主切换按钮不可双重叠加。四页统一仓库浅色顶部栏已确认；主线移除旧底部导航，保留相同0..3路由。
- 模态层阻挡后方点击、Esc/关闭按原型指定返回，不能让确认按钮穿透或重复提交。

## 不移植的网页控制

孵蛋“状态目录”“重置示例”“演示保存失败”“演示成功结果”“人工#21”、静态fixture覆写、postMessage、网页适屏缩放/原尺寸滚动，以及浏览器QA专用状态注入均只用于评审。游戏正式确认页只由真实执行结果分支；不得提供玩家选择成功/失败的按钮，不强制后代sex0/rank2=2/先天较低值。

最终统一header源见包根source/navigation/，参数metadata/navigation.json；优先看reference/final/*.png。旧完整子状态改放reference/r06_original/，不能按旧图恢复不同header或主线bottom nav。文档从docs点击资源须用../metadata或../reference。

## 最终冻结参数

最终四图`reference/final/{arena,storage,hatch,story}.png`优先；原R06 debug仅历史source。统一header92px，四按钮138×54@y18，x813.71875/963.71875/1113.71875/1263.71875按arena/story/storage/hatch顺序调用switch_page(0..3)。StyleBox与颜色依metadata/navigation.json，CSS包根source/navigation/source/navigation.css。首进孵蛋仍缺亲本，确认孵蛋按钮仅去确认态；不能复制状态目录、重置示例、演示成功/失败进游戏。

CD字段仅剩余cd_one/two，无统一maxCD API；静态48×34遮罩不是百分比依据。比例须实际技能常量/逻辑周期作合法分母，纯表现接口不改计时，无分母先显示剩余与就绪。HP直接真实health，不新定插值延迟。12复用图标metadata/reused_assets.json真实存在；Regular/Bold两字体需实际绑定。新UI音效和专用动画帧未制作，保留现battle真实事件触发，不以battle音补UI。
