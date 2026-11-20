extends CanvasLayer
## 与世界坐标和相机缩放分离的屏幕墨迹，不拦截玩家操作。
@export var hold_seconds: float = 3.0
@export var fade_seconds: float = 1.0
@export var expand_seconds: float = .2
var elapsed: float = 0.0
@onready var splatter: TextureRect = $Splatter

func _ready() -> void:
    reset()

func splash() -> void:
    elapsed = 0.0
    splatter.modulate.a = 1.0
    splatter.pivot_offset = splatter.size*.5
    splatter.scale = Vector2.ONE*.55
    show()
    set_process(true)

func _process(delta: float) -> void:
    elapsed += delta
    var expand := 1.0-pow(1.0-clampf(elapsed/expand_seconds,0,1),3)
    splatter.scale = Vector2.ONE*lerpf(.55,1.0,expand)
    splatter.modulate.a = 1.0-clampf((elapsed-expand_seconds-hold_seconds)/fade_seconds,0.0,1.0)
    if elapsed >= expand_seconds+hold_seconds+fade_seconds: reset()

func reset() -> void:
    elapsed = 0.0
    hide()
    set_process(false)
    if is_instance_valid(splatter):
        splatter.modulate.a = 0.0
        splatter.scale = Vector2.ONE
