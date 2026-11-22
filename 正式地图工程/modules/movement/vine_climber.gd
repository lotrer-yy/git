class_name VineClimber
extends Node
## 可配置抓取与松手抛出；W/S 攀爬，自动或 A/D 借力，优先未抓过的可达藤蔓。
const SWING_ASSIST = preload("res://modules/movement/vine_swing_assist.gd")
@export_range(1,3) var launch_multiplier: float = 1.0
@export var max_launch_speed: float = 2600.0
@export var automatic_swing: bool = false
@export_range(30,75) var automatic_swing_angle: float = 62.0
@export var prefer_unvisited_vines: bool = false
@export var release_on_grab_release: bool = false
@export var grab_action: StringName = &""
@export var allow_mantle: bool = true
@export var hands_offset := Vector2(0,-60)
@export var grip_body_offset := Vector2(78,60)
var visited_vines: Dictionary = {}
var _swing_assist = SWING_ASSIST.new()
var grip_side: float = 1.0
var vine: SwingVine
var jump_origin: Vector2
var _body: CharacterBody2D
var _motor: PlatformerMotor
var _reader: PlatformerInput
var _host: PossessableHost
var _cooldown: float = 0.0
var _wait_for_grab_release: bool = false
var _mantle_time: float = -1.0
var _mantle_start: Vector2
var _mantle_end: Vector2
func _ready() -> void:
	process_physics_priority = -5
	_body = get_parent()
	_motor = _body.get_node("Movement")
	_reader = _body.get_node("Input")
	_host = _body.get_node("Host")
	jump_origin = _body.global_position
	_motor.jumped.connect(func(): jump_origin=_body.global_position)
	if not InputMap.has_action(&"vine_release"):
		InputMap.add_action(&"vine_release")
		var key := InputEventKey.new()
		key.physical_keycode=KEY_SPACE
		InputMap.action_add_event(&"vine_release",key)
	if grab_action!=&"" and not InputMap.has_action(grab_action):
		InputMap.add_action(grab_action)
		var grab_key := InputEventKey.new()
		grab_key.physical_keycode = KEY_SHIFT
		grab_key.location = KEY_LOCATION_LEFT
		InputMap.action_add_event(grab_action,grab_key)
func _physics_process(delta: float) -> void:
	_cooldown=maxf(0,_cooldown-delta)
	if not _grab_held():
		_wait_for_grab_release=false
	if not _host.claimed:
		return
	if _mantle_time>=0:
		_mantle_time+=delta
		var blend:=smoothstep(0,0.25,_mantle_time)
		_body.move_and_collide(_mantle_start.lerp(_mantle_end,blend)-_body.global_position)
		if blend>=1:
			_mantle_time=-1
			_motor.enabled=true
			_motor.reset()
		return
	if vine != null:
		visited_vines[vine.get_instance_id()] = true
		if release_on_grab_release and not _grab_held():
			detach(false)
			return
		vine.climb_axis=float(_reader.down_held)-float(_reader.jump_held)
		vine.pump_axis=_swing_assist.pump(vine,_body.velocity,delta,_reader.move_axis,automatic_swing_angle) if automatic_swing else _reader.move_axis
		if Input.is_action_just_pressed(&"vine_release"):
			detach(true)
		elif vine.grip_length>=vine.length-1.0 and _reader.down_held:
			detach(false)
			_body.velocity.y=maxf(_body.velocity.y,120.0)
			_wait_for_grab_release=true
		elif allow_mantle and vine.grip_length<=40 and _reader.jump_held:
			var anchor:=vine.global_position
			var side:float=-1 if vine.position.x<900 else 1
			detach(false)
			_motor.enabled=false
			_mantle_time=0
			_mantle_start=_body.global_position
			_mantle_end=anchor+Vector2(side*105,-155)*_body.global_scale
		return
	if _grab_held() and _cooldown<=0 and not _wait_for_grab_release:
		try_grab()
func _grab_held() -> bool:
	return _reader.down_held if grab_action==&"" else Input.is_action_pressed(grab_action)

func try_grab() -> bool:
	if not _host.claimed:
		return false
	var hands:=_body.global_position+hands_offset*_body.global_scale
	var nearest: SwingVine
	var distance:=INF
	var chosen_visited: bool = true
	for node in get_tree().get_nodes_in_group("swing_vines"):
		var candidate:=node as SwingVine
		var current_distance:=hands.distance_to(candidate.closest_grip(hands))
		if not candidate.can_grab(hands): continue
		var seen: bool = prefer_unvisited_vines and visited_vines.has(candidate.get_instance_id())
		if nearest==null or (chosen_visited and not seen) or (seen==chosen_visited and current_distance<distance):
			nearest=candidate
			distance=current_distance
			chosen_visited=seen
	if nearest==null:
		return false
	if _body.is_on_floor():
		jump_origin=_body.global_position
	var grip:=nearest.closest_grip(hands)
	grip_side=signf(_body.global_position.x-grip.x) if absf(_body.global_position.x-grip.x)>15 else 1.0
	nearest.rider_offset=Vector2(grip_body_offset.x*grip_side,grip_body_offset.y)*_body.global_scale
	nearest.catch(_body,_body.velocity,jump_origin)
	adopt_vine(nearest)
	_motor.enabled=false
	return true
func adopt_vine(value: SwingVine) -> void:
	vine=value
	visited_vines[value.get_instance_id()]=true
	_swing_assist.reset()

func detach(jump: bool) -> void:
	if vine==null:
		return
	visited_vines[vine.get_instance_id()]=true
	var exit_velocity:=vine.release()
	vine=null
	_motor.enabled=true
	_motor.reset()
	var launch := (exit_velocity*launch_multiplier).limit_length(max_launch_speed)+(Vector2(_reader.move_axis*120,-440) if jump else Vector2.ZERO)
	_motor.launch_with_momentum(launch)
	jump_origin=_body.global_position
	_cooldown=0.3
func reset() -> void:
	visited_vines.clear()
	_swing_assist.reset()
	if vine!=null:
		vine.release()
	vine=null
	_mantle_time=-1
	_cooldown=0
	_wait_for_grab_release=false
	_motor.enabled=true
