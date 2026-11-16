extends Node
## 独立横向运镜模块。转场追踪移动目标，边界外不露底。
@export var camera_path: NodePath = ^"../DescentCamera"
@export var minimum_x: float = 960.0
@export var maximum_x: float = 4858.18
var active: bool = false
var target: Node2D
var lead: float = 0.0
var _blend: float = 0.0
var _duration: float = 1.0
var _from: float = 960.0
var _velocity: float = 0.0
var _locked: bool = false
@onready var camera: Camera2D = get_node(camera_path)

func track(actor: Node2D, offset: float, duration: float) -> void:
	target = actor
	lead = offset
	_from = camera.position.x
	_blend = 0.0
	_duration = maxf(duration, 0.01)
	_locked = false
	active = true

func lock_frame() -> void:
	_locked = true

func _process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		return
	if _locked:
		# 收镜时缓缓卸掉跟随速度，再让幽灵超过固定画框。
		var decay: float = exp(-10.0 * delta)
		camera.position.x = clampf(camera.position.x + _velocity * (1.0 - decay) / 10.0, minimum_x, maximum_x)
		_velocity *= decay
		return
	_blend = minf(_blend + delta, _duration)
	var u: float = _blend / _duration
	var weight: float = u * u * (3.0 - 2.0 * u)
	var destination: float = clampf(target.global_position.x + lead, minimum_x, maximum_x)
	var desired: float = lerpf(_from, destination, weight)
	# 二阶跟随吸收转向交接处的速度差，快速平移也不会突然刹停。
	var remaining: float = delta
	while remaining > 0.0:
		var step: float = minf(remaining, 1.0 / 240.0)
		_velocity += ((desired - camera.position.x) * 225.0 - _velocity * 30.0) * step
		camera.position.x = clampf(camera.position.x + _velocity * step, minimum_x, maximum_x)
		remaining -= step
