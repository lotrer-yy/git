extends Node
## 只负责分镜节奏；角色弹跑、镜头运动各自由独立模块处理。
signal finished
@export var actors_path: NodePath = ^"../DescentWorld/ArrivalMap/ChaseActors"
@export var camera_motion_path: NodePath = ^"../ChaseCamera"
@export var follow_time: float = 4.8
@export var mob_reveal_time: float = 2.0
@export var return_follow_time: float = 2.1
var active: bool = false
var completed: bool = false
var elapsed: float = 0.0
var stage: int = 0
@onready var actors: Node2D = get_node(actors_path)
@onready var motion: Node = get_node(camera_motion_path)

func start() -> void:
	if active or completed:
		return
	active = true
	actors.visible = true
	actors.get_node("Ghost").start()
	actors.get_node("Mob").start()
	motion.track(actors.get_node("Ghost"), 220.0, 1.2)

func _process(delta: float) -> void:
	if completed:
		var mob: Node2D = actors.get_node("Mob")
		if mob.global_position.x > motion.camera.position.x + 2300.0:
			mob.running = false
			mob.visible = false
		return
	if not active:
		return
	elapsed += delta
	if stage == 0 and elapsed >= follow_time:
		stage = 1
		motion.track(actors.get_node("Mob/Focus"), 40.0, 0.42)
	elif stage == 1 and elapsed >= follow_time + mob_reveal_time:
		stage = 2
		motion.track(actors.get_node("Ghost"), 200.0, 0.48)
	elif stage == 2 and elapsed >= follow_time + mob_reveal_time + return_follow_time:
		stage = 3
		motion.lock_frame()
	elif stage == 3:
		var ghost: Node2D = actors.get_node("Ghost")
		var camera: Camera2D = motion.camera
		if ghost.global_position.x > camera.position.x + 1100.0:
			active = false
			completed = true
			ghost.running = false
			ghost.visible = false
			finished.emit()
