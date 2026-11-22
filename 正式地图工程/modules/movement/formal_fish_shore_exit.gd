extends FishShoreExit
## 只接入旧出水动作，岸线碰撞使用正式长地图的位置。
@onready var stage: Node2D = get_parent()
func _physics_process(delta: float) -> void:
    if not stage.active or stage.level.dead or stage.level.player!=_fish: return
    super._physics_process(delta)
    _fish.get_node("Teleport").enabled = state==State.SWIMMING
