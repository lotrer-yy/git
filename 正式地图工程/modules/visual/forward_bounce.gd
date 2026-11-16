extends Node2D
## 向前蹬出的弹跑表现。只动美术，不改变路线和镜头跟踪点。
@export var runner_path: NodePath = ^".."
@export var forward_distance: float = 12.0
@export var forward_lean_degrees: float = 7.0
@export var stiffness: float = 420.0
@export var damping: float = 22.0
var _shape: Vector2 = Vector2.ONE
var _shape_velocity: Vector2 = Vector2.ZERO
@onready var runner: Node2D = get_node(runner_path)

func _ready() -> void:
	process_priority = 1

func _process(delta: float) -> void:
	if not runner.running:
		return
	var phase: float = fmod(runner.elapsed * runner.cadence, 1.0)
	var stance: float = 1.0 - clampf(runner.airborne_fraction, 0.2, 0.8)
	var energy: float = smoothstep(0.0, 0.5, runner.elapsed)
	var desired_shape: Vector2 = Vector2.ONE
	var lean: float = forward_lean_degrees
	if phase < stance:
		var u: float = phase / stance
		var landing: float = exp(-u * 12.0)
		var charge: float = smoothstep(0.55, 1.0, u)
		position = Vector2(forward_distance * cos(u * PI), 0.0) * energy
		desired_shape += Vector2(0.22, -0.22) * landing + Vector2(0.12, -0.12) * charge
		lean += 2.0 * charge
	else:
		var u: float = (phase - stance) / (1.0 - stance)
		var launch: float = exp(-u * 5.0)
		var arc: float = sin(u * PI)
		position = Vector2(-forward_distance * cos(u * PI), -runner.hop_height * arc) * energy
		desired_shape += Vector2(0.20, -0.10) * launch + Vector2(-0.045, 0.07) * arc
		lean += 4.0 * launch
	desired_shape = Vector2.ONE.lerp(desired_shape, energy)
	# 目标姿态可以快速变化，实际形变由弹簧连续追上，接地处不再突然切换。
	var remaining: float = minf(delta, 0.1)
	while remaining > 0.0:
		var step: float = minf(remaining, 1.0 / 240.0)
		_shape_velocity += ((desired_shape - _shape) * stiffness - _shape_velocity * damping) * step
		_shape += _shape_velocity * step
		remaining -= step
	scale = _shape
	rotation = lerp_angle(rotation, deg_to_rad(lean) * energy, 1.0 - exp(-18.0 * delta))
