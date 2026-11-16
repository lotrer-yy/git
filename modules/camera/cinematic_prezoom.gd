extends Node
## 进场前推镜；完成后才放出角色，独立于追逐跟拍。
signal finished
@export var camera_path: NodePath = ^"../DescentCamera"
@export_range(1.0, 1.6) var close_zoom: float = 1.35
@export var map_path: NodePath = ^"../DescentWorld/ArrivalMap"
@export var focus_height: float = 800.0
@export var duration: float = 0.8
var playing: bool = false
var _tween: Tween
@onready var camera: Camera2D = get_node(camera_path)

func play() -> void:
	if playing:
		return
	playing = true
	var half_width: float = get_viewport().get_visible_rect().size.x / (2.0 * close_zoom)
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "zoom", Vector2.ONE * close_zoom, duration)
	# 以地图左侧为入场框，推近时不裁掉幽灵入场的左边缘。
	_tween.tween_property(camera, "position:x", half_width, duration)
	var map: Node2D = get_node(map_path)
	_tween.tween_property(camera, "position:y", map.global_position.y + focus_height, duration)
	_tween.chain().tween_callback(_complete)

func _complete() -> void:
	playing = false
	finished.emit()
