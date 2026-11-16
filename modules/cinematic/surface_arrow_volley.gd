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
@export var random_interval_range: Vector2 = Vector2.ZERO
@export var flight_variation: float = 0.0
@export var launch_variation: float = 0.0
var _next_shot: float = 0.0
var _rng := RandomNumberGenerator.new()
var started: bool = false
var elapsed: float = 0.0
var fired_count: int = 0
var landed_count: int = 0
@onready var camera: Camera2D = get_node(camera_path)

func start() -> void:
	if not started:
		started = true
		_rng.randomize()
		_next_shot = first_delay

func _process(delta: float) -> void:
	if not started or fired_count >= target_paths.size():
		return
	elapsed += delta
	while fired_count < target_paths.size() and elapsed >= _next_shot:
		_fire(fired_count)
		fired_count += 1
		if random_interval_range.y > 0.0:
			_next_shot += maxf(0.005,_rng.randf_range(random_interval_range.x,random_interval_range.y))
		else:
			_next_shot += maxf(0.005,shot_interval)

func _fire(index: int) -> void:
	var target: Node2D = get_node(target_paths[index])
	var arrow: Node2D = arrow_scene.instantiate()
	arrow.name = "Arrow%d" % (index + 1)
	add_child(arrow)
	arrow.flight_duration = maxf(0.1,flight_duration + _rng.randf_range(-flight_variation,flight_variation))
	arrow.arc_height = arc_height + (index % 3) * 8.0
	arrow.rest_duration = rest_duration
	arrow.aim_at_surface(target, attached_z_index)
	arrow.landed.connect(_on_landed.bind(index))
	var half_width: float = get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)
	var origin: Vector2 = Vector2(camera.global_position.x - half_width - 140.0, target.global_position.y - launch_height - _rng.randf_range(0.0,launch_variation))
	arrow.launch(origin, target.global_position)
	arrow_fired.emit(index)

func _on_landed(index: int) -> void:
	landed_count += 1
	arrow_landed.emit(index)
