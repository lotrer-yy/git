extends Node
## 侧墙弹出只驱动入场弧线；落地后交回已有移动与输入模块。
signal control_ready
@export var body_path: NodePath = ^"../Soul"
@export var spawn_path: NodePath = ^"../WallSpawn"
@export var landing_path: NodePath = ^"../LandingPoint"
@export var duration: float = 0.95
@export var arc_height: float = 190.0
var playing: bool = false
var completed: bool = false
var elapsed: float = 0.0
@onready var soul: CharacterBody2D = get_node(body_path)
@onready var start_point: Marker2D = get_node(spawn_path)
@onready var landing_point: Marker2D = get_node(landing_path)

func _ready() -> void:
	soul.position = start_point.position
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
	soul.position = start_point.position.lerp(landing_point.position, u) - Vector2(0, 4.0 * arc_height * u * (1.0 - u))
	if u >= 1.0:
		playing = false
		completed = true
		soul.get_node("Movement").reset()
		soul.get_node("Collision").set_deferred("disabled", false)
		soul.get_node("Movement").enabled = true
		soul.get_node("Input").enabled = true
		soul.get_node("Movement").landed.emit(750.0)
		control_ready.emit()
