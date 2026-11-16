extends Node
## 侧墙弹出只驱动入场弧线；落地后交回已有移动与输入模块。
signal control_ready
@export var body_path: NodePath = ^"../Soul"
@export var spawn_path: NodePath = ^"../WallSpawn"
@export var landing_path: NodePath = ^"../LandingPoint"
@export var duration: float = 0.72
@export var arc_height: float = 65.0
@export var maximum_spawn_height: float = 110.0
@export var ground_shape_path: NodePath = ^"../Ground/Collision"
var _start_position: Vector2
var _landing_position: Vector2
var playing: bool = false
var completed: bool = false
var elapsed: float = 0.0
@onready var soul: CharacterBody2D = get_node(body_path)
@onready var start_point: Marker2D = get_node(spawn_path)
@onready var landing_point: Marker2D = get_node(landing_path)

func _ready() -> void:
	_landing_position = landing_point.position
	var ground: CollisionShape2D = get_node_or_null(ground_shape_path) as CollisionShape2D
	if ground != null and ground.shape is RectangleShape2D:
		# 使用编辑器里真实地面碰撞的上沿，地面改高后不再把落点埋进去。
		var shape: RectangleShape2D = ground.shape
		_landing_position.y = soul.get_parent().to_local(ground.to_global(Vector2(0, -shape.size.y * 0.5))).y
	_start_position = start_point.position
	_start_position.y = maxf(_start_position.y, _landing_position.y - maximum_spawn_height)
	soul.position = _start_position
	soul.get_node("Input").enabled = false
	soul.get_node("Movement").enabled = false
	soul.get_node("Collision").disabled = true

func play() -> void:
	if playing or completed:
		return
	playing = true
	soul.get_node("Movement").jumped.emit()

func _process(delta: float) -> void:
	if not playing:
		return
	elapsed = minf(elapsed + delta, duration)
	var u: float = elapsed / duration
	_landing_position = landing_point.position
	var ground: CollisionShape2D = get_node_or_null(ground_shape_path) as CollisionShape2D
	if ground != null and ground.shape is RectangleShape2D:
		# 使用编辑器里真实地面碰撞的上沿，地面改高后不再把落点埋进去。
		var shape: RectangleShape2D = ground.shape
		_landing_position.y = soul.get_parent().to_local(ground.to_global(Vector2(0, -shape.size.y * 0.5))).y
	_start_position = start_point.position
	_start_position.y = maxf(_start_position.y, _landing_position.y - maximum_spawn_height)
	soul.position = _start_position.lerp(landing_point.position, u) - Vector2(0, 4.0 * arc_height * u * (1.0 - u))
	if u >= 1.0:
		playing = false
		completed = true
		soul.get_node("Movement").reset()
		soul.get_node("Collision").set_deferred("disabled", false)
		soul.get_node("Movement").enabled = true
		soul.get_node("Input").enabled = true
		soul.get_node("Movement").landed.emit(750.0)
		control_ready.emit()
