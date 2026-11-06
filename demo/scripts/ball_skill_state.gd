class_name BallSkillState
extends RefCounted
## 一个球的一次技能关联，只保存数据，不执行释放、冷却或次数消耗。
## 同一技能定义可以关联多次，但每次关联应有独立记录和运行态。

## 技能配置标识。
var skill_id: StringName = &""
## 技能配置资源引用。
var skill_definition: Resource = null
## 本次技能关联的独立运行数据。
var runtime: Dictionary = {}
