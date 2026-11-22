extends Node2D
## 舌头独立放在嘴缘前方，跟随前端嘴唇，咬合前收回。
var amount: float = 0
func configure(frame: int,time: float) -> void:
    # 待机舌根压在前唇黑边内，不能从轮廓外悬空开始。
    position = Vector2(301,149)
    amount = 1-smoothstep(0,.075,time)
    # 蓄力初段收回；所有张嘴、冲刺、咬合和回弹姿势都不吐舌。
    visible = frame==0 and amount>.04
    queue_redraw()
func _draw() -> void:
    if not visible: return
    var path := PackedVector2Array()
    for i in 17:
        var u: float = float(i)/16
        path.append(Vector2(50*u*amount,(sin(u*PI)*5-3*u)*amount))
    draw_polyline(path,Color.BLACK,6,true)
    var end: Vector2 = path[-1]
    draw_line(end,end+Vector2(12,-8)*amount,Color.BLACK,5,true)
    draw_line(end,end+Vector2(12,5)*amount,Color.BLACK,5,true)
    draw_circle(Vector2.ZERO,3,Color.BLACK)
