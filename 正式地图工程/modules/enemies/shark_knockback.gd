extends Node2D
## 鲨鱼命中后的独立表现：短暂顿住、沿撞击方向弹起、抛物线落出视野。
@export var launch_speed: float = 900.0
@export var upward_speed: float = 650.0
@export var gravity: float = 1700.0
@export var spin_speed: float = 2.2
@export var hit_pause_seconds: float = 0.05
var impact_direction := Vector2.RIGHT
var corpse: Sprite2D
var _victim: CharacterBody2D
var _motion: Tween
var _origin := Vector2.ZERO
var _velocity := Vector2.ZERO
var _rotation: float = 0.0
var _side: float = 1.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func play(body: CharacterBody2D, camera: Camera2D, direction: Vector2) -> void:
    reset()
    _victim = body
    body.get_node("Input").enabled = false
    body.get_node("Movement").enabled = false
    body.velocity = Vector2.ZERO
    var sprite := body.get_node("Visual/Sprite") as Sprite2D
    corpse = Sprite2D.new()
    corpse.texture = sprite.texture
    corpse.flip_h = sprite.flip_h
    corpse.flip_v = sprite.flip_v
    add_child(corpse)
    corpse.global_transform = sprite.global_transform
    body.get_node("Visual").hide()
    _origin = corpse.global_position
    _rotation = corpse.global_rotation
    _side = -1.0 if direction.x<0 else 1.0
    _velocity = Vector2(_side*launch_speed,-upward_speed+clampf(direction.y,-1.0,1.0)*120.0)
    var bottom := camera.global_position.y+camera.get_viewport_rect().size.y*.5/camera.zoom.y
    var drop := maxf(180.0,bottom+120.0-_origin.y)
    var seconds := (-_velocity.y+sqrt(_velocity.y*_velocity.y+2.0*gravity*drop))/gravity
    _motion = create_tween().set_ignore_time_scale(true)
    _motion.tween_interval(hit_pause_seconds)
    _motion.tween_method(_sample_arc,0.0,seconds,seconds)
    await _motion.finished
    if is_instance_valid(corpse): corpse.hide()

func _sample_arc(t: float) -> void:
    corpse.global_position = _origin+_velocity*t+Vector2(0,.5*gravity*t*t)
    corpse.global_rotation = _rotation+_side*spin_speed*t

func reset() -> void:
    if _motion != null:
        _motion.kill()
        _motion = null
    if is_instance_valid(corpse): corpse.queue_free()
    corpse = null
    if is_instance_valid(_victim): _victim.get_node("Visual").show()
    _victim = null
    impact_direction = Vector2.RIGHT
