extends Node
## 死亡冻结期间只写相机偏移，真实时间衰减，不改跟随中心或物理位置。
@export_range(0.0, 30.0) var strength_pixels: float = 18.0
@export_range(0.01, 0.4) var duration: float = 0.20
@export_range(0.0, 1.0) var fall_multiplier: float = 0.35
var _camera: FollowCamera
var _motion: Tween
var _strength: float

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 35

func play(camera: FollowCamera, falling: bool = false) -> void:
    stop()
    _camera = camera
    _camera.clear_impulse()
    _strength = strength_pixels * (fall_multiplier if falling else 1.0)
    if _strength <= 0.0: return
    _motion = create_tween().set_ignore_time_scale(true)
    _motion.tween_method(_sample, 0.0, 1.0, duration)
    _motion.tween_callback(stop)

func _sample(u: float) -> void:
    var envelope := pow(1.0 - u, 1.4)
    var pixels := Vector2(sin(u * TAU * 2.0) * 0.45, -cos(u * TAU * 1.5)) * _strength * envelope
    var center := _camera.global_position
    _camera.offset = _camera._clamp_center(center + pixels / _camera.zoom) - center

func stop() -> void:
    if _motion != null:
        _motion.kill()
        _motion = null
    if is_instance_valid(_camera): _camera.offset = Vector2.ZERO
    _camera = null
