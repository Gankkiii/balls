class_name Ball
extends RefCounted
## 只保存一个球的运行状态，不执行初始化、碰撞、技能或绘制。
## Arena 修改运动数据；BallRenderer 读取位置和半径，配色由渲染层保存。
## 玩法字段只是数据接口，不代表已经实现对应规则。

## 球心在竞技场局部坐标中的当前位置，单位为逻辑像素；唯一权威位置。
var position: Vector2 = Vector2.ZERO
## 当前速度向量，x/y 分量决定方向和速率，单位为逻辑像素/秒。
var velocity: Vector2 = Vector2.ZERO
## 球的半径，单位为逻辑像素；同时用于碰撞和绘制，外部应提供正数。
var radius: float = 24.0
## 球的质量，使用相对单位；影响碰撞中的速度变化，外部应提供正数。
var mass: float = 1.0

## 角色类型的配置标识，用于说明“是哪种角色”；空值表示尚未指定。
## 同种角色的多个球可以使用相同标识，不用于区分单个球。
var character_id: StringName = &""
## 角色配置资源的引用，用于取得该角色的具体配置；null 表示尚未关联。
## 与 character_id 的关系是“配置的名字”与“配置对象”，不会自动查找或校验。
## 当前仅用通用 Resource 占位，尚未定义配置结构；多个球可以只读共享。
var character_definition: Resource = null
## 当前这个球的业务实例标识，用于区分同角色的不同球；由外部保证唯一。
## 空值表示未分配，与 Godot 的 Object.get_instance_id() 不是一回事。
var instance_id: StringName = &""
## 球所属的队伍标识；空值表示未指定，不在这里决定友伤或同队碰撞。
var team_id: StringName = &""

## 当前生命值；null 表示尚未配置，不等于 0，也不据此自动判断死亡。
## 外部规则负责提供整数或浮点数；此处不钳制、不回血、不扣血。
var current_health: Variant = null
## 最大生命值；null 表示尚未配置。范围、与当前生命的关系均由外部规则处理。
var max_health: Variant = null

## 这个球当前关联的临时状态记录列表；默认独立空数组，不自动应用或移除效果。
## 每次关联应新建记录，只读配置可共享，可变运行态应由各记录独立持有。
var temporary_states: Array[BallTemporaryState] = []
## 这个球的技能关联及其运行态列表；默认独立空数组，不自动释放技能或计时。
## 同一技能可关联多次，但每次关联都应新建 BallSkillState 记录。
var skills: Array[BallSkillState] = []

## 皮肤的配置标识；空值表示未指定，只保存关联，不加载或切换外观。
var skin_id: StringName = &""
## 外观配置资源的引用；null 表示尚未关联，当前渲染器尚不解析该资源。
## 可与其他球只读共享；具体配置结构及其与 skin_id 的匹配由外部负责。
var appearance_definition: Resource = null
