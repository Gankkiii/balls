class_name BallTemporaryState
extends RefCounted
## 一个球的一次临时状态关联，只保存数据，不执行效果或过期处理。
## 同一份定义可以只读共享，每次关联的可变运行态应独立保存。

## 临时状态配置标识。
var state_id: StringName = &""
## 临时状态配置资源引用。
var state_definition: Resource = null
## 本次状态关联的独立运行数据。
var runtime: Dictionary = {}
