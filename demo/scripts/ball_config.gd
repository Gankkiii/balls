class_name BallConfig
extends Resource
## 球的简单配置，可由多个 Ball.character_definition 共享引用。
## 只保存配置值，不保存或修改某个球的运行状态。
## 初始速率范围应满足 0 <= min_initial_speed <= max_initial_speed。
## 正速率及其平方须能用 Vector2 的单精度数值表示；Arena 初始化时验证。

## 初始化时随机速率的下限（像素/秒），不包含方向。
@export_range(0.0, 1000.0, 0.1, "or_greater") var min_initial_speed: float = 140.0
## 初始化时随机速率的上限（像素/秒）；与下限相同可配置固定速率。
@export_range(0.0, 1000.0, 0.1, "or_greater") var max_initial_speed: float = 230.0
