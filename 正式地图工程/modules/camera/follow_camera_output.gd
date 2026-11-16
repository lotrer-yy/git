extends Node
## 游戏跟随模块只计算视野，由同一台开场相机继续显示整个世界。
@export var source_path: NodePath = ^"../Camera"
var output_camera: Camera2D
var enabled: bool = false
@onready var source: Camera2D = get_node(source_path)

func _ready() -> void:
	process_priority = 50

func _process(_delta: float) -> void:
	if enabled and is_instance_valid(output_camera):
		output_camera.global_position = source.global_position
		output_camera.zoom = source.zoom
		output_camera.offset = source.offset
