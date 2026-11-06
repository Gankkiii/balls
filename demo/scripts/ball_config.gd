## 职责边界：共享配置定义；创建时复制半径和质量，初始化时读取速率；生命攻防由工厂复制到运行态。
class_name BallConfig
extends Resource
## 球的简单配置，可由多个 Ball.character_definition 共享引用。
## 只保存配置值，不保存或修改某个球的运行状态。
## 初始速率范围应满足 0 <= min_initial_speed <= max_initial_speed。
## 正速率及其平方须能用 Vector2 的单精度数值表示；BallFactory 初始化时通过 BallValidation 验证。

## 初始最大生命值，创建时用于初始化满血。
@export_range(1.0, 10000.0, 1.0, "or_greater") var max_health: float = 100.0
## 基础攻击力，用于撞击伤害。
@export_range(0.0, 1000.0, 1.0, "or_greater") var attack: float = 10.0
## 基础防御力，用于撞击伤害。
@export_range(0.0, 1000.0, 1.0, "or_greater") var defense: float = 0.0
## 大小采用半径（像素），创建球时写入 Ball.radius。
@export_range(0.1, 1000.0, 0.1, "or_greater") var radius: float = 24.0
## 重量采用相对质量，创建球时写入 Ball.mass。
@export_range(0.1, 1000.0, 0.1, "or_greater") var mass: float = 1.0

## 初始化时随机速率的下限（像素/秒），不包含方向。
@export_range(0.0, 1000.0, 0.1, "or_greater") var min_initial_speed: float = 140.0
## 初始化时随机速率的上限（像素/秒）；与下限相同可配置固定速率。
@export_range(0.0, 1000.0, 0.1, "or_greater") var max_initial_speed: float = 230.0

## 空引用表示不装备撞击技能。
@export var impact_skill: ImpactSkillConfig
