class_name Ball
extends RefCounted
## 保存一颗球的身份、配置关联，以及战斗中需要记录的状态。
## 只保存一个球的运行状态，不执行初始化、碰撞、技能或绘制。
## Arena 修改运动数据；BallRenderer 读取位置和半径，配色由渲染层保存。
## 战斗规则由 CombatSystem / ImpactSkill 计算，Arena 统一提交；其他玩法字段仍可为空。

## 球心位置（竞技场局部坐标，像素）。
var position: Vector2 = Vector2.ZERO
## 当前速度向量（像素/秒）。
var velocity: Vector2 = Vector2.ZERO
## 球半径（像素）。
var radius: float = 24.0
## 球的相对质量。
var mass: float = 1.0

## 角色类型标识。
var character_id: StringName = &""
## 角色配置资源引用。
var character_definition: Resource = null
## 外部分配的球实例唯一标识。
var instance_id: StringName = &""
## 所属队伍标识。
var team_id: StringName = &""

## 当前生命值，null 表示未配置。
var current_health: Variant = null
## 最大生命值，null 表示未配置。
var max_health: Variant = null

## 临时状态记录列表。
var temporary_states: Array[BallTemporaryState] = []
## 技能记录列表。
var skills: Array[BallSkillState] = []

## 皮肤配置标识。
var skin_id: StringName = &""
## 外观配置资源引用。
var appearance_definition: Resource = null

## 当前攻击和防御，由工厂从配置复制。
var attack := 0.0
var defense := 0.0
