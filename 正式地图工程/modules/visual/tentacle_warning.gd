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
    var u := clampf(seconds/.20,0,1)
    var pop := 1+2.7*pow(u-1,3)+1.7*pow(u-1,2)
    sprite.scale = Vector2.ONE*.65*maxf(.05,pop)
    sprite.modulate.a = 1.0 if seconds<.24 else .25+.75*(.5+.5*cos((seconds-.24)*TAU*5))
