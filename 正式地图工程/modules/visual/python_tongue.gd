extends Node2D
## 舌头独立放在嘴缘前方，跟随前端嘴唇，咬合前收回。
var amount: float = 0
func configure(frame: int,time: float,attack_duration: float,initial_amount: float=1.0) -> void:
    position = Vector2(301,149)
    if time<0:
        amount=1
    elif time<.075:
        amount=initial_amount*(1-smoothstep(0,.075,time))
    else:
        # 咬完恢复站姿后停120毫秒，再用300毫秒从嘴里慢慢伸出。
        amount=smoothstep(attack_duration+.12,attack_duration+.42,time)
    visible=frame==0 and amount>.001
    modulate.a=smoothstep(0,.08,amount)
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
