extends "res://modules/environment/vortex_exit.gd"
## 主角保持正常比例钻到原火山口图层后，由口沿前景自然遮住身体。
func _animate_capture(progress: float) -> void:
    _body.global_position = _start.lerp(_mouth.global_position,progress)
    _visual.scale = Vector2.ONE
    _visual.position = Vector2.ZERO
    _visual.rotation = 0.0
    _visual.modulate.a = 1.0

func reset() -> void:
    if is_instance_valid(_visual): _visual.position = Vector2.ZERO
    super.reset()
