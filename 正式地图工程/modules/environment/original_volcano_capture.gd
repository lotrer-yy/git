extends "res://modules/environment/vortex_exit.gd"
## 在原画火山口以中心等比例钻入，不覆盖原画。
func _animate_capture(progress: float) -> void:
    _body.global_position = _start.lerp(_mouth.global_position,progress)
    var amount := lerpf(1.0,0.06,progress)
    _visual.scale = Vector2.ONE*amount
    _visual.position = _visual.get_node("Sprite").position*(1.0-amount)
    _visual.rotation = 0.0
    _visual.modulate.a = 1.0-smoothstep(0.7,1.0,progress)

func reset() -> void:
    if is_instance_valid(_visual): _visual.position = Vector2.ZERO
    super.reset()
