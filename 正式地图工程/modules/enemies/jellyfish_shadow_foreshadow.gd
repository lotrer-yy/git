extends Node2D
## 正式 Boss 登场前的远景帧动画：收伞、冲游、滑行，与深层视差一起运动。
@export var enabled: bool = false
@export var parallax_ratio: float = .76
@export var opacity: float = .85
@export var fade_seconds: float = .9
var camera: Camera2D
var boss: Node2D
var _center_x: float = 960.0
var _started: bool = false
var _finished: bool = false
var _departing: bool = false
var _fade_elapsed: float = 0.0
var _camera_origin := Vector2.ZERO
var _anchor := Vector2.ZERO
var _drift := Vector2.ZERO
var _velocity := Vector2(8,-18)
var _pivots: Array
var _art_scale: float = 1.0
@onready var sprite: AnimatedSprite2D = $Art

func _ready() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/ocean/jellyfish/shadow_swim_anchors.json"))
    _pivots = data.pivots
    _art_scale = data.scale
    sprite.frame_changed.connect(_on_frame)
    reset()

func configure(view: Camera2D, jellyfish: Node2D, center_x: float) -> void:
    camera = view
    boss = jellyfish
    _center_x = center_x
    boss.appeared.connect(_on_boss_appeared)

func _physics_process(delta: float) -> void:
    if not enabled or _finished or not is_instance_valid(camera): return
    if not _started:
        if boss.state!=boss.State.DORMANT: return
        _started = true
        _camera_origin = camera.global_position+camera.offset
        _anchor = Vector2(_center_x,_camera_origin.y-190)
        show()
        sprite.play(&"swim")
    _velocity = _velocity.lerp(Vector2(8,-18),1-exp(-delta*2.3))
    _drift += _velocity*delta
    global_position = _anchor+(camera.global_position+camera.offset-_camera_origin)*parallax_ratio+_drift
    if _departing:
        _fade_elapsed += delta
        modulate.a = opacity*(1-smoothstep(0,fade_seconds,_fade_elapsed))
        if _fade_elapsed>=fade_seconds:
            _finished = true
            sprite.stop()
            hide()
    else:
        modulate.a = opacity

func _on_frame() -> void:
    if _pivots.is_empty(): return
    var pivot: Array = _pivots[sprite.frame]
    var texture := sprite.sprite_frames.get_frame_texture(&"swim",sprite.frame)
    sprite.offset = texture.get_size()*.5-Vector2(pivot[0],pivot[1])
    sprite.scale = Vector2.ONE*_art_scale
    if _started and not _departing and sprite.frame==3: _velocity += Vector2(42,-220)

func _on_boss_appeared() -> void:
    _departing = true
    _fade_elapsed = 0

func reset() -> void:
    enabled = false
    _started = false
    _finished = false
    _departing = false
    _fade_elapsed = 0
    _drift = Vector2.ZERO
    _velocity = Vector2(8,-18)
    sprite.stop()
    sprite.frame = 0
    _on_frame()
    modulate.a = opacity
    hide()
