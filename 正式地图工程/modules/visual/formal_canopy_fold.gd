extends "res://modules/visual/canopy_ripple_spring.gd"
## 原画围绕中心弹开，再收回中心；只由落入树冠触发。
func pulse() -> void:
    _age=0
    show()
    modulate.a=1
    scale=_base_scale*.04
func _process(delta: float) -> void:
    if not visible: return
    _age+=delta
    var u:=clampf(_age/.16,0,1)
    var t:=u-1.0
    var opening:=1.0+2.7*t*t*t+1.7*t*t
    var rebound:=1.0+.08*sin(maxf(0,_age-.16)*30)*exp(-12*maxf(0,_age-.16))
    var closing:=1.0-smoothstep(.45,.75,_age)
    scale=_base_scale*maxf(.04,opening)*rebound*closing
    if _age>=.75: reset()
