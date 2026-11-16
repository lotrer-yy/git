extends Node
## 跟拍角色构图点，在角色移动后更新；缩放后的完整视野约束在地图内。
@export var camera_path: NodePath = ^"../DescentCamera"
@export var map_path: NodePath = ^"../DescentWorld/ArrivalMap"
@export var minimum_x: float = 960.0
@export var maximum_x: float = 4858.18
@export var map_height: float = 1260.60606
var active: bool = false
var target: Node2D
var lead: float = 0.0
var _blend: float = 0.0
var _duration: float = 1.0
var _from: Vector2
var _velocity: Vector2 = Vector2.ZERO
var _locked: bool = false
@onready var camera: Camera2D = get_node(camera_path)
@onready var map: Node2D = get_node(map_path)

func _ready() -> void:
	process_priority = 100

func _left_bound() -> float:
	return minimum_x - 960.0 + get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)

func _right_bound() -> float:
	return maximum_x + 960.0 - get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)

func _clamp_view(point: Vector2) -> Vector2:
	var half_height: float = get_viewport().get_visible_rect().size.y / (2.0 * camera.zoom.y)
	return Vector2(clampf(point.x, _left_bound(), _right_bound()), clampf(point.y, map.global_position.y + half_height, map.global_position.y + map_height - half_height))

func track(actor: Node2D, offset: float, duration: float) -> void:
	target = actor
	lead = offset
	_from = camera.position
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
		var decay: float = exp(-10.0 * delta)
		camera.position = _clamp_view(camera.position + _velocity * (1.0 - decay) / 10.0)
		_velocity *= decay
		return
	_blend = minf(_blend + delta, _duration)
	var u: float = _blend / _duration
	var weight: float = u * u * (3.0 - 2.0 * u)
	var destination: Vector2 = _clamp_view(target.global_position + Vector2(lead, 0.0))
	var desired: Vector2 = _from.lerp(destination, weight)
	var remaining: float = delta
	while remaining > 0.0:
		var step: float = minf(remaining, 1.0 / 240.0)
		_velocity += ((desired - camera.position) * 225.0 - _velocity * 30.0) * step
		camera.position = _clamp_view(camera.position + _velocity * step)
		remaining -= step
