# 仓库 · 完整资料默认页

本轮按用户确认的仓库D“默认就是副状态”整理：`main.png`与`source.html`唯一默认均为横向个体画廊＋完整六属性来源矩阵。没有复制上轮折叠概览主状态，没有收起属性的入口；本轮不选择新方案，也不做手机适配。固定1600×900可交互HTML是UI演示，非实际Godot界面或游戏实时数据。

## 页面数据

读取本轮共用`../fixtures.json`的20固定示例（10种类×♀♂）；鱼♀及羊♂技能等级人工统一3/3，其余固定个体按game_pages公式。默认母鱼♀Lv.0，先天34/41/48/12/19/26、后天全0。六属性每项均显示种族基础/先天/后天/最终，基础与最终待定。当前与另两特性保持待设计；五技能池仅已有两个有确定名字，其余不编效果。切换到别的固定个体时显示该个体已有技能等级与先天值，不沿用母鱼数据。

页面可以接收孵蛋演示结果并显示唯一#21人工示例；重发替换同一个示例，不无限增加。只存在当前iframe内存中，刷新消失，不读取或写入游戏、本机存档或浏览器持久存储。`demo_child.png`明确是人工结果排版，不是实际孵化记录。

## 可见按钮与去向

- 四全局导航：竞技场、主线、孵蛋发送同源`{type:'r06-nav',page:'arena'|'story'|'hatch'}`给父整合页；仓库按钮保持当前仓库与选择。独立打开时提示从整合页导航。
- 画廊‹ / ›：选择前后一个个体，边界禁用，不改变属性计算。
- 个体下拉：可直接选择20固定示例，接收到演示后代后新增唯一#21入口。
- 相邻角色卡：直接选择该个体并同步形象、性别、等级、特性、技能和完整属性。中心卡点击保持当前选择。
- 属性说明：打开说明浮层；关闭按钮、点击遮罩或Esc返回默认完整资料，属性不折叠。

同源父页可发送`{type:'r06-demo-child',child}`；仅接受`event.source===parent`且`event.origin===location.origin`。child使用game_pages结构：species 0..9，sex0/1，level0..100，trait，两个不同skills0..4/ranks1..10，六项innate1..50、training0..100且总和<=200。demo编号统一21；此校验仅防止UI示例失效，不扩展游戏规则。

## 文件与重建

- 默认：`main.png`、`source.html`。
- 说明：`info.png`；切换个体：`individual.png`；人工后代：`demo_child.png`。
- 制作源：`source/build_storage.py`、`source/base.css`、`source/fixtures.json`、`source/demo_child.json`。fixtures副本只作重建后备，优先读取本轮共享fixture。
- 重建：`python3 source/build_storage.py`；浏览器检查：`python3 source/verify_storage.py`。需要Python3、Playwright、Chromium与Noto Sans CJK SC；人物从当前仓库`/workspace/balls/assets/r04`及鸭兔`assets/r02`透明原件读取，内嵌到HTML，nearest显示，不重新设计人物或宽刀。

自检覆盖默认完整矩阵、20个体切换、共享父样例、说明开关、同源导航/接收、后代替换与不使用存储API；结果`qa.json`。这些是浏览器原型检查，不是游戏回归或真机验证。未修改游戏、玩法、物理、团队配置，未commit/push。字体使用环境Noto Sans CJK（OFL1.1），未复制字体；没有外部插画或私密资料。
