extends Node
## 循环后的出口与减速：只推进地层和终点地图，不管理首页退场。
signal arrived
@export var strata_path: NodePath = ^"../DescentWorld"
@export var map_path: NodePath = ^"../DescentWorld/ArrivalMap"
@export var loop_pages_before_exit: int = 1
@export var braking_distance: float = 1100.0
var finished: bool = false
var current_speed: float = 0.0
var _travelled: float = 0.0
var _target_distance: float
var _map_origin: float
var _braking: bool = false
var _brake_elapsed: float = 0.0
var _brake_duration: float
var _brake_start_speed: float
var _brake_length: float
var _brake_travelled: float = 0.0
@onready var strata: Node2D = get_node(strata_path)
@onready var opening_map: Node2D = get_node(map_path)

func _ready() -> void:
	_map_origin = strata.loop_origin + maxf(loop_pages_before_exit, 1) * strata.page_height
	# StopFrame 决定最终构图，地图左边缘始终在屏幕左侧。
	var frame: Marker2D = opening_map.get_node("StopFrame")
	_target_distance = _map_origin + frame.position.y - (strata.loop_origin + 540.0)
	_place_map()

func advance(pixels: float, incoming_speed: float, delta: float) -> float:
	if finished:
		return 0.0
	current_speed = incoming_speed
	if not _braking:
		var lead := maxf(_target_distance - _travelled - braking_distance, 0.0)
		if pixels < lead:
			_move(pixels)
			return current_speed
		_move(lead)
		_braking = true
		_brake_start_speed = maxf(incoming_speed, 1.0)
		_brake_length = _target_distance - _travelled
		_brake_duration = maxf(2.0 * _brake_length / _brake_start_speed, 0.001)
		delta *= clampf((pixels - lead) / maxf(pixels, 0.001), 0.0, 1.0)
	_brake_elapsed = minf(_brake_elapsed + delta, _brake_duration)
	var u := _brake_elapsed / _brake_duration
	var distance := _brake_length * (2.0 * u - u * u)
	_move(distance - _brake_travelled)
	_brake_travelled = distance
	current_speed = _brake_start_speed * (1.0 - u)
	if u >= 1.0:
		finished = true
		current_speed = 0.0
		arrived.emit()
	return current_speed

func _move(pixels: float) -> void:
	var step := maxf(pixels, 0.0)
	_travelled += step
	strata.advance(step)
	_place_map()

func _place_map() -> void:
	opening_map.position = Vector2(0, _map_origin - _travelled)
