extends Node2D
## 提示固定在触手出场处：弹出、闪烁、消失，随后留出反应间隔。
const ART = preload("res://assets/art/ocean/jellyfish/warning.png")
var sprite: Sprite2D
func _ready() -> void:
    z_as_relative = false
    z_index = 20
    sprite = Sprite2D.new()
    sprite.texture = ART
    add_child(sprite)
    sample(-1)
func sample(seconds: float) -> void:
    visible = seconds>=0 and seconds<.72
    if not visible: return
    var amount := 1.0
    var lift := 0.0
    if seconds<.16:
        var u := seconds/.16
        amount = 1+2.7*pow(u-1,3)+1.7*pow(u-1,2)
    elif seconds<.57:
        # 每次弹跳更紧凑：先慢后快的四次 duang，不依靠透明闪烁冒充动作。
        var beats := [.16,.32,.43,.51,.57]
        for i in range(beats.size()-1):
            if seconds>=beats[i] and seconds<beats[i+1]:
                var u: float = (seconds-beats[i])/(beats[i+1]-beats[i])
                lift = sin(u*PI)*13
                amount = 1+sin(u*TAU)*.20
                break
    else:
        var u := clampf((seconds-.57)/.15,0,1)
        # 先向外回弹一下，再连续收缩消失。
        amount = (1+.35*sin(u*PI))*(1-pow(u,3))
        lift = -8*sin(u*PI)
    sprite.scale = Vector2(.65*maxf(.01,amount),.65*maxf(.01,amount+lift*.008))
    sprite.position.y = -lift
    sprite.modulate.a = 1.0-smoothstep(.64,.72,seconds)
