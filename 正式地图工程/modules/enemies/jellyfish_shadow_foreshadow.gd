extends Node2D
## 正式 Boss 登场前的远景帧动画：收伞、冲游、滑行，与深层视差一起运动。
@export var enabled: bool = false
@export var parallax_ratio: float = .76
@export var opacity: float = .85
@export var fade_seconds: float = .9
@export var size_multiplier: float = .55
@export var swim_cycle_seconds: float = 2.2
@export var charge_retreat: float = 18.0
@export var dash_distance: float = 110.0
@export var glide_distance: float = 45.0
const POSE_TIMES = [0.0,.15,.3,.4,.52,.66,.8,.9,1.0]
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
var _clock: float = 0.0
var _render: Polygon2D
var _material: ShaderMaterial
var _pivots: Array
var _art_scale: float = 1.0
@onready var sprite: AnimatedSprite2D = $Art

func _ready() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/ocean/jellyfish/shadow_swim_anchors.json"))
    _pivots = data.pivots
    _art_scale = data.scale
    sprite.frame_changed.connect(_on_frame)
    _render = Polygon2D.new()
    _render.polygon = PackedVector2Array([Vector2(-300,-130),Vector2(240,-130),Vector2(240,400),Vector2(-300,400)])
    _material = sprite.material.duplicate()
    var frame := sprite.sprite_frames.get_frame_texture(&"swim",0) as AtlasTexture
    _material.set_shader_parameter("atlas",frame.atlas)
    _material.set_shader_parameter("atlas_size",frame.atlas.get_size())
    _render.material = _material
    add_child(_render)
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
    _clock += delta
    var cycles := floorf(_clock/swim_cycle_seconds)
    var phase := fposmod(_clock,swim_cycle_seconds)/swim_cycle_seconds
    var travel: float
    if phase<.32:
        travel = -charge_retreat*smoothstep(0,.32,phase)
    elif phase<.52:
        travel = _segment(-charge_retreat,dash_distance-charge_retreat,0,80,swim_cycle_seconds*.2,(phase-.32)/.2)
    else:
        var u := clampf((phase-.52)/.48,0,1)
        travel = _segment(dash_distance-charge_retreat,dash_distance+glide_distance-charge_retreat,80,0,swim_cycle_seconds*.48,u)
    var stride := dash_distance+glide_distance-charge_retreat
    _drift = Vector2(.4,-.916515).normalized()*(cycles*stride+travel)+Vector2(3,-8)*_clock
    _sample_pose(phase)
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

func _segment(from: float, to: float, from_speed: float, to_speed: float, seconds: float, u: float) -> float:
    # Hermite 曲线在前冲和滑行交接处保持同样的速度，避免突然一顿。
    var squared := u*u
    var cubed := squared*u
    return (2*cubed-3*squared+1)*from+(cubed-2*squared+u)*from_speed*seconds+(-2*cubed+3*squared)*to+(cubed-squared)*to_speed*seconds

func _on_frame() -> void:
    if _pivots.is_empty(): return
    var pivot: Array = _pivots[sprite.frame]
    var texture := sprite.sprite_frames.get_frame_texture(&"swim",sprite.frame)
    sprite.offset = texture.get_size()*.5-Vector2(pivot[0],pivot[1])
    sprite.scale = Vector2.ONE*_art_scale*size_multiplier

func _sample_pose(phase: float) -> void:
    for i in 8:
        if phase>=POSE_TIMES[i+1]: continue
        var next := (i+1)%8
        var a := sprite.sprite_frames.get_frame_texture(&"swim",i) as AtlasTexture
        var b := sprite.sprite_frames.get_frame_texture(&"swim",next) as AtlasTexture
        var pa: Array = _pivots[i]
        var pb: Array = _pivots[next]
        _material.set_shader_parameter("from_region",Vector4(a.region.position.x,a.region.position.y,a.region.size.x,a.region.size.y))
        _material.set_shader_parameter("to_region",Vector4(b.region.position.x,b.region.position.y,b.region.size.x,b.region.size.y))
        _material.set_shader_parameter("from_anchor",Vector2(pa[0],pa[1]))
        _material.set_shader_parameter("to_anchor",Vector2(pb[0],pb[1]))
        _material.set_shader_parameter("pose_blend",(phase-POSE_TIMES[i])/(POSE_TIMES[i+1]-POSE_TIMES[i]))
        _render.scale = Vector2.ONE*_art_scale*size_multiplier
        return

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
    _clock = 0
    sprite.stop()
    sprite.hide()
    sprite.frame = 0
    _on_frame()
    _sample_pose(0)
    modulate.a = opacity
    hide()
