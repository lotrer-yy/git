extends Node2D
## 固定场景落点的分批射击；可用于钉柱子和出口箭雨，不依赖角色控制。
signal arrow_fired(index: int)
signal arrow_landed(index: int)
@export var camera_path: NodePath = ^"../../../DescentCamera"
@export var arrow_scene: PackedScene
@export var target_paths: Array[NodePath] = []
@export var first_delay: float = 0.18
@export var shot_interval: float = 0.22
@export var flight_duration: float = 0.44
@export var arc_height: float = 35.0
@export var launch_height: float = 110.0
@export var attached_z_index: int = 1
@export var rest_duration: float = 3.0
var started: bool = false
var elapsed: float = 0.0
var fired_count: int = 0
var landed_count: int = 0
@onready var camera: Camera2D = get_node(camera_path)

func start() -> void:
	if not started:
		started = true

func _process(delta: float) -> void:
	if not started or fired_count >= target_paths.size():
		return
	elapsed += delta
	while fired_count < target_paths.size() and elapsed >= first_delay + fired_count * shot_interval:
		_fire(fired_count)
		fired_count += 1

func _fire(index: int) -> void:
	var target: Node2D = get_node(target_paths[index])
	var arrow: Node2D = arrow_scene.instantiate()
	arrow.name = "Arrow%d" % (index + 1)
	add_child(arrow)
	arrow.flight_duration = flight_duration
	arrow.arc_height = arc_height + (index % 3) * 8.0
	arrow.rest_duration = rest_duration
	arrow.aim_at_surface(target, attached_z_index)
	arrow.landed.connect(_on_landed.bind(index))
	var half_width: float = get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)
	var origin: Vector2 = Vector2(camera.global_position.x - half_width - 140.0, target.global_position.y - launch_height - (index % 3) * 24.0)
	arrow.launch(origin, target.global_position)
	arrow_fired.emit(index)

func _on_landed(index: int) -> void:
	landed_count += 1
	arrow_landed.emit(index)
