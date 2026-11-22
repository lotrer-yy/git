extends Node2D
## 舌头独立放在嘴缘前方，跟随前端嘴唇，咬合前收回。
const FRONTS = [Vector2(309,149),Vector2(337,215),Vector2(299,218),Vector2(310,244),Vector2(350,274),Vector2.ZERO,Vector2.ZERO,Vector2(309,149)]
var amount: float = 0
func configure(frame: int,time: float) -> void:
    position = FRONTS[frame]
    visible = frame in [0,1,2,3,4,7]
    amount = .65+.35*sin(time*11)*sin(time*11)
    if frame==4: amount*=.8
    queue_redraw()
func _draw() -> void:
    if not visible: return
    var path := PackedVector2Array()
    for i in 17:
        var u: float = float(i)/16
        path.append(Vector2(50*u*amount,sin(u*PI)*5-3*u))
    draw_polyline(path,Color.BLACK,6,true)
    var end: Vector2 = path[-1]
    draw_line(end,end+Vector2(12,-8)*amount,Color.BLACK,5,true)
    draw_line(end,end+Vector2(12,5)*amount,Color.BLACK,5,true)
    draw_circle(Vector2.ZERO,3,Color.BLACK)
