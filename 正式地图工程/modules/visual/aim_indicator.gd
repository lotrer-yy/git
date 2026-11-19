extends Sprite2D
## 独立瞄准图层：出现时围绕中心等比例弹出，取消时立即清理动画。
@export_range(0.01, 1.0) var initial_scale: float = 0.08
@export_range(1.0, 1.5) var overshoot_scale: float = 1.16
@export var grow_seconds: float = 0.09
@export var settle_seconds: float = 0.16
var _pop: Tween

func reveal() -> void:
    if visible:
        return
    if _pop != null:
        _pop.kill()
    scale = Vector2.ONE * initial_scale
    show()
    _pop = create_tween()
    _pop.tween_property(self, "scale", Vector2.ONE * overshoot_scale, grow_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _pop.tween_property(self, "scale", Vector2.ONE, settle_seconds).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func conceal() -> void:
    if _pop != null:
        _pop.kill()
        _pop = null
    hide()
    scale = Vector2.ONE
