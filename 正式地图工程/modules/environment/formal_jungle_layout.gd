extends Node2D
## 按作者示例排版；只有垂挂细藤蔓进入抓取组，粗主藤蔓没有碰撞。
var camera: Camera2D
var _elapsed: float = 0
@onready var vines: Array[Node] = $InteractiveVines.get_children()
func _ready() -> void:
    for vine in vines:
        vine.set_physics_process(false)
        vine.set_process(false)
func configure(view: Camera2D, map_transform: Transform2D) -> void:
    camera = view
    global_transform = map_transform
    _update_nearby()
func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed<.15: return
    _elapsed = 0
    _update_nearby()
func _update_nearby() -> void:
    if not is_instance_valid(camera): return
    var half: float = camera.get_viewport_rect().size.y*.5/camera.zoom.y
    var center: float = camera.global_position.y+camera.offset.y
    for vine in vines:
        var top: float = vine.global_position.y
        var bottom: float = top+vine.length
        var near: bool = vine.rider!=null or (top<center+half+900 and bottom>center-half-900)
        vine.set_physics_process(near)
        vine.set_process(near)
func reset() -> void:
    for vine in vines: vine.reset()
    _update_nearby()
