class_name CombatResult
extends RefCounted
## 候选结果，不修改球。以 Ball 引用为键，避免死亡移除后下标变化。
var error := ""
var health: Dictionary[Ball, float] = {}
var dead: Array[Ball] = []
