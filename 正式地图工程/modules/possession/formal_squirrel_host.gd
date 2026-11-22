extends PossessableHost
## 附身保留正在摆荡的绳索与惯性，只把借力操作交给玩家。
func _ready() -> void:
    super._ready()
    remove_from_group("possessable_hosts")
    add_to_group("formal_jungle_hosts")
func freeze_for_transfer() -> void:
    var momentum: Vector2 = body.velocity
    super.freeze_for_transfer()
    body.velocity = momentum
    body.transferring = true
    body.vine.pump_axis = 0
func take_control() -> void:
    var momentum: Vector2 = body.velocity
    super.take_control()
    body.transferring = false
    body.remove_from_group("idle_vine_squirrels")
    body.collision_layer = 2
    body.collision_mask = 16 | 32
    body.get_node("VineClimber").adopt_vine(body.vine)
    motor.enabled = false
    body.velocity = momentum
    body.set_active(true)
func reset() -> void:
    super.reset()
    body.transferring = false
    body.collision_layer = 0
    body.collision_mask = 0
    body.add_to_group("idle_vine_squirrels")
