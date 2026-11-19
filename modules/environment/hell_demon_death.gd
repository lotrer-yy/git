extends Node2D
## 只播放死亡替身；角色碰撞、相机和机关保持冻结，重来不继承抛物线。
const ART = preload("res://assets/art/hell/new/demon_dead.png")
@export var jump_speed: float = 650.0
@export var fall_gravity: float = 2200.0
@export var squash_seconds: float = 0.07
var corpse: Sprite2D
var _original: Node2D
var _was_visible: bool
var _motion: Tween
var _origin: Vector2
var _rest_scale: Vector2
var _rest_rotation: float

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func play(body: Node2D, camera: Camera2D, has_fork: bool) -> void:
    reset()
    _original = body.get_node("Visual")
    _was_visible = _original.visible
    var source: Sprite2D = _original.get_node("Sprite")
    corpse = Sprite2D.new()
    corpse.texture = ART
    corpse.flip_h = source.flip_h
    # 两张原图左上绘制坐标相同，保留身体原位，不因画布留白不同横跳。
    corpse.offset = (ART.get_size() - source.texture.get_size()) * 0.5
    if corpse.flip_h: corpse.offset.x *= -1.0
    if not has_fork:
        var material := ShaderMaterial.new()
        material.shader = preload("res://shaders/demon_held_fork.gdshader")
        material.set_shader_parameter("has_fork", false)
        corpse.material = material
    corpse.z_index = 40
    add_child(corpse)
    corpse.global_transform = source.global_transform
    _original.hide()
    _origin = corpse.global_position
    _rest_scale = corpse.scale
    _rest_rotation = corpse.rotation
    var bottom := camera.global_position.y + camera.get_viewport_rect().size.y * 0.5 / camera.zoom.y
    var distance := maxf(500.0, bottom + ART.get_height() * absf(corpse.global_scale.y) - _origin.y)
    var seconds := (jump_speed + sqrt(jump_speed * jump_speed + 2.0 * fall_gravity * distance)) / fall_gravity
    _motion = create_tween().set_ignore_time_scale(true)
    _motion.tween_property(corpse, "scale", _rest_scale * Vector2(1.22, 0.78), squash_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _motion.tween_method(_sample, 0.0, seconds, seconds)
    await _motion.finished
    corpse.hide()

func _sample(t: float) -> void:
    corpse.global_position = _origin + Vector2(0.0, -jump_speed * t + 0.5 * fall_gravity * t * t)
    var settle := minf(t / 0.14, 1.0)
    corpse.scale = _rest_scale * Vector2(1.22, 0.78).lerp(Vector2(0.94, 1.06), settle)
    corpse.rotation = _rest_rotation + deg_to_rad(12.0) * minf(t / 0.5, 1.0)

func reset() -> void:
    if _motion != null: _motion.kill()
    if is_instance_valid(corpse):
        corpse.queue_free()
        corpse = null
    if is_instance_valid(_original): _original.visible = _was_visible
    _original = null
