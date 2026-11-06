class_name BallTemporaryState
extends RefCounted
## 一个球的一次临时状态关联，只保存数据，不执行效果或过期处理。
## 同一份定义可以只读共享，每次关联的可变运行态应独立保存。

## 临时状态的配置标识，用于说明“是哪种状态”；空值表示未指定。
var state_id: StringName = &""
## 对应临时状态配置资源的引用；null 表示未关联，不会按 state_id 自动查找。
var state_definition: Resource = null
## 这一次状态关联的可变运行数据，每次新建记录都有独立的空字典。
## 外部系统决定是否存放持续时间、层数等数据，以及如何更新或移除它们。
## 空字典仅表示未提供运行数据，不表示已过期或未激活。
var runtime: Dictionary = {}
