extends Node2D
## 追逐期间持续射箭，随机疏密与落点；只表现追击，不参与伤害。
signal arrow_fired(index: int)
signal arrow_landed(index: int)
@export var ghost_path: NodePath = ^"../ChaseActors/Ghost"
@export var camera_path: NodePath = ^"../../../DescentCamera"
@export var arrow_scene: PackedScene
@export var first_delay: float = 0.65
@export var interval_range: Vector2 = Vector2(0.09,0.32)
@export var gap_range: Vector2 = Vector2(155.0,440.0)
var started: bool = false
var elapsed: float = 0.0
var fired_count: int = 0
var landed_count: int = 0
var _next_shot: float = 0.0
var _rng := RandomNumberGenerator.new()
@onready var ghost: Node2D = get_node(ghost_path)
@onready var camera: Camera2D = get_node(camera_path)

func _ready() -> void:
	process_priority = 5

func start() -> void:
	if started:
		return
	_rng.randomize()
	started = true
	_next_shot = first_delay

func stop() -> void:
	started = false

func _process(delta: float) -> void:
	if not started:
		return
	elapsed += delta
	while elapsed >= _next_shot:
		_fire(fired_count)
		fired_count += 1
		# 偶尔连续两三支更紧，随后略疏，避免均匀的机关枪节拍。
		var interval: float = _rng.randf_range(interval_range.x,interval_range.y)
		if _rng.randf() < 0.3:
			interval *= 0.4
		_next_shot += maxf(interval,0.025)

func _fire(index: int) -> void:
	var arrow: Node2D = arrow_scene.instantiate()
	arrow.name = "Arrow%d" % (index+1)
	add_child(arrow)
	arrow.flight_duration = _rng.randf_range(0.34,0.54)
	arrow.arc_height = _rng.randf_range(30.0,100.0)
	var half_width: float = get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)
	var origin := Vector2(camera.global_position.x-half_width-_rng.randf_range(80.0,200.0),ghost.global_position.y-_rng.randf_range(180.0,300.0))
	var gap: float = _rng.randf_range(maxf(gap_range.x,155.0),maxf(gap_range.y,155.0))
	var destination: Vector2 = ghost.global_position + Vector2(ghost.speed*arrow.flight_duration-gap,_rng.randf_range(32.0,52.0))
	arrow.landed.connect(_on_landed.bind(index))
	arrow.launch(origin,destination)
	arrow_fired.emit(index)

func _on_landed(index: int) -> void:
	landed_count += 1
	arrow_landed.emit(index)
