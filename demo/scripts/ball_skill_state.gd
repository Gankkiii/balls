class_name BallSkillState
extends RefCounted
## 一个球的一次技能关联，只保存数据，不执行释放、冷却或次数消耗。
## 同一技能定义可以关联多次，但每次关联应有独立记录和运行态。

## 技能的配置标识，用于说明“是哪种技能”；空值表示未指定。
var skill_id: StringName = &""
## 对应技能配置资源的引用；null 表示未关联，不会按 skill_id 自动查找。
var skill_definition: Resource = null
## 这一次技能关联的可变运行数据，每次新建记录都有独立的空字典。
## 外部系统决定是否存放冷却、剩余次数等数据，以及如何更新它们。
## 空字典仅表示未提供运行数据，不表示技能已就绪或被禁用。
var runtime: Dictionary = {}
