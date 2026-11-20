extends CanvasLayer
## 与世界坐标和相机缩放分离的屏幕墨迹，不拦截玩家操作。
@export var hold_seconds: float = 3.0
@export var fade_seconds: float = 1.0
var elapsed: float = 0.0
@onready var splatter: TextureRect = $Splatter

func _ready() -> void:
    reset()

func splash() -> void:
    elapsed = 0.0
    splatter.modulate.a = 1.0
    show()
    set_process(true)

func _process(delta: float) -> void:
    elapsed += delta
    splatter.modulate.a = 1.0-clampf((elapsed-hold_seconds)/fade_seconds,0.0,1.0)
    if elapsed >= hold_seconds+fade_seconds: reset()

func reset() -> void:
    elapsed = 0.0
    hide()
    set_process(false)
    if is_instance_valid(splatter): splatter.modulate.a = 0.0
