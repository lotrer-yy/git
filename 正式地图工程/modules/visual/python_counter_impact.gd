extends Node2D
## 最后一记Shift的接触闪光，短促扩散后消失，不生成贴图或碰撞。
var age: float = 1
func play_at(world_position: Vector2) -> void:
    global_position=world_position
    age=0
    show()
    queue_redraw()
func _process(delta: float) -> void:
    if age>=.22: return
    age+=delta
    queue_redraw()
    if age>=.22: hide()
func _draw() -> void:
    if age>=.22: return
    var u: float = age/.22
    var color := Color(1,.9,.5,1-u)
    draw_arc(Vector2.ZERO,18+u*70,0,TAU,40,color,5*(1-u),true)
    for i in 8:
        var direction := Vector2.RIGHT.rotated(float(i)*TAU/8)
        draw_line(direction*(12+u*35),direction*(36+u*70),color,5*(1-u),true)
