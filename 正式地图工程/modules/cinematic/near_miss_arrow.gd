extends Node2D
## 单支视觉箭：固定抛物线、沿切线转向、落地轻颤；不参与角色碰撞或伤害。
signal landed
@export var flight_duration: float = 0.5
@export var arc_height: float = 80.0
@export var artwork_angle_degrees: float = 15.0
@export var rest_duration: float = 1.6
var flying: bool = false
var impact: bool = false
var elapsed: float = 0.0
var rest_time: float = 0.0
var start_point: Vector2
var end_point: Vector2
var _rest_angle: float = 0.0
var surface_target: Node2D
var attached_z_index: int = 1

func aim_at_surface(target: Node2D, landing_z_index: int) -> void:
	surface_target = target
	attached_z_index = landing_z_index
	# 柱子在视差更新后才确定本帧位置，箭在它之后更新。
	process_priority = 230

func _ready() -> void:
	process_priority = 6

func launch(from: Vector2, to: Vector2) -> void:
	start_point = from
	end_point = to
	global_position = from
	flying = true
	_apply_flight(0.0)

func _process(delta: float) -> void:
	if flying:
		elapsed = minf(elapsed + delta, flight_duration)
		var u: float = elapsed / flight_duration
		_apply_flight(u)
		if u >= 1.0:
			flying = false
			impact = true
			if is_instance_valid(surface_target):
				# 钉住后归属落点，随柱子一起运动，不能漂在屏幕上。
				reparent(surface_target, true)
				position = Vector2.ZERO
				z_index = attached_z_index
			_rest_angle = rotation
			landed.emit()
	elif impact:
		rest_time += delta
		rotation = _rest_angle + deg_to_rad(4.0) * sin(rest_time * 75.0) * exp(-rest_time * 16.0)
		if rest_time > rest_duration:
			modulate.a = 1.0 - clampf((rest_time - rest_duration) / 0.3, 0.0, 1.0)
		if rest_time >= rest_duration + 0.3:
			queue_free()

func _apply_flight(u: float) -> void:
	if is_instance_valid(surface_target):
		end_point = surface_target.global_position
	global_position = start_point.lerp(end_point,u) - Vector2(0,4.0 * arc_height * u * (1.0-u))
	var tangent: Vector2 = end_point - start_point - Vector2(0,4.0 * arc_height * (1.0-2.0*u))
	rotation = tangent.angle() - deg_to_rad(artwork_angle_degrees)
