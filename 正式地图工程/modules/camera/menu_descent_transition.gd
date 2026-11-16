extends Node
## 蓄力、连续加速下潜与循环交接；只通过信号通知 UI 退场。
signal descent_started
signal loop_started
enum State { IDLE, CHARGE, DESCENDING, LOOPING, ARRIVED }
@export var camera_path: NodePath = ^"../DescentCamera"
@export var strata_path: NodePath = ^"../DescentWorld"
@export var arrival_path: NodePath = ^"../ArrivalMotion"
@export var charge_duration: float = 0.28
@export var acceleration_duration: float = 1.05
@export var descent_speed: float = 930.0
@export var ongoing_acceleration: float = 240.0
@export var maximum_speed: float = 3200.0
var current_speed: float = 0.0
var state: State = State.IDLE
var elapsed: float = 0.0
var _launch_time: float = 0.0
@onready var camera: Camera2D = get_node(camera_path)
@onready var strata: Node2D = get_node(strata_path)
@onready var arrival: Node = get_node_or_null(arrival_path)

func start() -> void:
	if state != State.IDLE:
		return
	state = State.CHARGE
	elapsed = 0.0

func _process(delta: float) -> void:
	if state == State.IDLE or state == State.ARRIVED:
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
	var previous_distance := _distance_at(_launch_time)
	_launch_time += delta
	var distance := _distance_at(_launch_time)
	current_speed = _speed_at(_launch_time)
	if state == State.LOOPING:
		_advance_loop(distance - previous_distance, delta)
		return
	var y := 530.0 + distance
	camera.zoom = Vector2.ONE * lerpf(1.035, 1.0, smoothstep(0.0, 0.65, _launch_time))
	var handoff: float = strata.loop_origin + 540.0
	if y >= handoff:
		camera.position.y = handoff
		state = State.LOOPING
		loop_started.emit()
		_advance_loop(y - handoff, delta)
	else:
		camera.position.y = y

func _advance_loop(pixels: float, delta: float) -> void:
	if is_instance_valid(arrival):
		current_speed = arrival.advance(pixels, current_speed, delta)
		if arrival.finished:
			state = State.ARRIVED
	else:
		strata.advance(pixels)

func _speed_at(time: float) -> float:
	var duration := maxf(acceleration_duration, 0.001)
	if time < duration:
		return descent_speed * smoothstep(0.0, duration, time)
	return minf(maxf(maximum_speed, descent_speed),
		descent_speed + maxf(ongoing_acceleration, 0.0) * (time - duration))

func _distance_at(time: float) -> float:
	# 统一用解析积分计算全程距离，进入循环和达到最高速度时都不重置运动。
	var duration := maxf(acceleration_duration, 0.001)
	var u := clampf(time / duration, 0.0, 1.0)
	var distance := descent_speed * duration * (u * u * u - 0.5 * u * u * u * u)
	var tail := maxf(time - duration, 0.0)
	var acceleration := maxf(ongoing_acceleration, 0.0)
	if acceleration <= 0.0:
		return distance + descent_speed * tail
	var cap := maxf(maximum_speed, descent_speed)
	var accelerating := minf(tail, (cap - descent_speed) / acceleration)
	return distance + descent_speed * accelerating + 0.5 * acceleration * accelerating * accelerating + cap * (tail - accelerating)
