extends Node2D
## 最后跟拍幽灵时触发的三箭分镜，只调度投射物，不改变跑动或镜头。
signal arrow_fired(index: int)
signal arrow_landed(index: int)
@export var ghost_path: NodePath = ^"../ChaseActors/Ghost"
@export var camera_path: NodePath = ^"../../../DescentCamera"
@export var arrow_scene: PackedScene
@export var first_delay: float = 0.55
@export var shot_interval: float = 0.28
@export var miss_gaps: PackedFloat32Array = PackedFloat32Array([170.0,145.0,122.0])
var started: bool = false
var elapsed: float = 0.0
var fired_count: int = 0
var landed_count: int = 0
@onready var ghost: Node2D = get_node(ghost_path)
@onready var camera: Camera2D = get_node(camera_path)

func _ready() -> void:
	process_priority = 5

func start() -> void:
	if started:
		return
	started = true

func _process(delta: float) -> void:
	if not started or fired_count >= 3:
		return
	elapsed += delta
	while fired_count < 3 and elapsed >= first_delay + fired_count * shot_interval:
		_fire(fired_count)
		fired_count += 1

func _fire(index: int) -> void:
	var arrow: Node2D = arrow_scene.instantiate()
	arrow.name = "Arrow%d" % (index+1)
	add_child(arrow)
	var half_width: float = get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)
	var origin: Vector2 = Vector2(camera.global_position.x-half_width-120.0,ghost.global_position.y-220.0)
	origin.y += [-20.0,10.0,-10.0][index]
	# 用预计飞行结束时的位置留出脚后方空隙。发射后不再跟踪角色。
	var gap: float = maxf(miss_gaps[index] if index < miss_gaps.size() else 122.0,110.0)
	var destination: Vector2 = ghost.global_position + Vector2(ghost.speed*arrow.flight_duration-gap, [34.0,40.0,36.0][index])
	arrow.landed.connect(_on_landed.bind(index))
	arrow.launch(origin,destination)
	arrow_fired.emit(index)

func _on_landed(index: int) -> void:
	landed_count += 1
	arrow_landed.emit(index)
