extends Node
## 只负责分镜节奏；角色弹跑、镜头运动各自由独立模块处理。
signal finished
@export var actors_path: NodePath = ^"../DescentWorld/ArrivalMap/ChaseActors"
@export var camera_motion_path: NodePath = ^"../ChaseCamera"
@export var prezoom_path: NodePath = ^"../PreChaseZoom"
@export var follow_time: float = 3.4
@export var mob_reveal_time: float = 1.35
@export var return_follow_time: float = 1.55
var active: bool = false
var completed: bool = false
var elapsed: float = 0.0
var stage: int = -1
@onready var actors: Node2D = get_node(actors_path)
@onready var motion: Node = get_node(camera_motion_path)

func _ready() -> void:
	get_node(prezoom_path).finished.connect(_begin_running)

func start() -> void:
	if active or completed:
		return
	active = true
	get_node(prezoom_path).play()

func _begin_running() -> void:
	stage = 0
	actors.visible = true
	actors.get_node("Ghost").start()
	actors.get_node("Mob").start()
	motion.track(actors.get_node("Ghost"), 160.0, 0.65)

func _process(delta: float) -> void:
	if completed:
		var mob: Node2D = actors.get_node("Mob")
		if mob.global_position.x > motion.camera.position.x + 2300.0:
			mob.running = false
			mob.visible = false
		return
	if not active or stage == -1:
		return
	elapsed += delta
	if stage == 0 and elapsed >= follow_time:
		stage = 1
		motion.track(actors.get_node("Mob/Focus"), 40.0, 0.32)
	elif stage == 1 and elapsed >= follow_time + mob_reveal_time:
		stage = 2
		motion.track(actors.get_node("Ghost"), 180.0, 0.36)
	elif stage == 2 and elapsed >= follow_time + mob_reveal_time + return_follow_time:
		stage = 3
		motion.lock_frame()
	elif stage == 3:
		var ghost: Node2D = actors.get_node("Ghost")
		var camera: Camera2D = motion.camera
		if ghost.global_position.x > camera.position.x + get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x) + 100.0:
			active = false
			completed = true
			ghost.running = false
			ghost.visible = false
			finished.emit()
