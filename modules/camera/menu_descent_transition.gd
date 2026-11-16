extends Node
## 蓄力、连续加速下潜与循环交接；只通过信号通知 UI 退场。
signal descent_started
signal loop_started
enum State { IDLE, CHARGE, DESCENDING, LOOPING }
@export var camera_path: NodePath = ^"../DescentCamera"
@export var strata_path: NodePath = ^"../DescentWorld"
@export var charge_duration: float = 0.28
@export var acceleration_duration: float = 1.05
@export var descent_speed: float = 930.0
var state: State = State.IDLE
var elapsed: float = 0.0
var _launch_time: float = 0.0
@onready var camera: Camera2D = get_node(camera_path)
@onready var strata: Node2D = get_node(strata_path)

func start() -> void:
	if state != State.IDLE:
		return
	state = State.CHARGE
	elapsed = 0.0

func _process(delta: float) -> void:
	if state == State.IDLE:
		return
	if state == State.LOOPING:
		strata.advance(descent_speed * delta)
		return
	if state == State.CHARGE:
		var used := minf(delta, charge_duration - elapsed)
		elapsed += used
		var amount := smoothstep(0.0, charge_duration, elapsed)
		camera.position.y = 540.0 - 10.0 * amount
		camera.zoom = Vector2.ONE * (1.0 + 0.035 * amount)
		if elapsed < charge_duration:
			return
		state = State.DESCENDING
		descent_started.emit()
		delta -= used
	_launch_time += delta
	var u := minf(_launch_time / acceleration_duration, 1.0)
	# smoothstep 速度曲线的解析积分，避免按帧累加造成顿挫或速度差。
	var distance := descent_speed * acceleration_duration * (u * u * u - 0.5 * u * u * u * u)
	if _launch_time > acceleration_duration:
		distance += descent_speed * (_launch_time - acceleration_duration)
	var y := 530.0 + distance
	camera.zoom = Vector2.ONE * lerpf(1.035, 1.0, smoothstep(0.0, 0.65, _launch_time))
	var handoff: float = strata.loop_origin + 540.0
	if y >= handoff:
		camera.position.y = handoff
		strata.advance(y - handoff)
		state = State.LOOPING
		loop_started.emit()
	else:
		camera.position.y = y
