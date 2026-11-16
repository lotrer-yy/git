extends Node2D
## 横向视差：取决于镜头绝对位置，甩镜和 R 重播不会累积漂移。
@export var camera_path: NodePath = ^"../../../DescentCamera"
@export_range(0.0, 2.0) var motion_scale: float = 0.65
@export var reference_camera_x: float = 960.0
var _origin: Vector2
@onready var camera: Camera2D = get_node(camera_path)

func _ready() -> void:
	_origin = position
	process_priority = 200

func _process(_delta: float) -> void:
	position = _origin + Vector2((camera.position.x - reference_camera_x) * (1.0 - motion_scale), 0.0)
