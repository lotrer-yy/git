extends Node
## 同一主角在原海图中的憋气状态；喷出后启动，重来清理，不影响地狱状态。
const LIVE_ART = preload("res://assets/art/characters/hell_demon_drowning_v001.png")
const DEAD_ART = preload("res://assets/art/characters/hell_demon_dead_v001.png")
@export var breath_duration: float = 16.0
@export var initial_redness: float = 0.15
@export var critical_color: Color = Color(1.0,0.28,0.28)
@export var dead_hold_seconds: float = 0.7
@export var sink_speed: float = 200.0
var active: bool = false
var elapsed: float = 0.0
var corpse: Sprite2D
var _rest_texture: Texture2D
var _rest_position: Vector2
var _motion: Tween
@onready var level: Node2D = get_parent().get_parent()
@onready var body: CharacterBody2D = level.get_node("Demon")
@onready var visual: Node2D = body.get_node("Visual")
@onready var sprite: Sprite2D = visual.get_node("Sprite")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _region(image: Texture2D) -> AtlasTexture:
    var result := AtlasTexture.new()
    result.atlas = image
    result.region = Rect2(1656,2770,144,134)
    result.filter_clip = true
    return result

func start() -> void:
    if active: return
    _rest_texture = sprite.texture
    _rest_position = sprite.position
    sprite.texture = _region(LIVE_ART)
    sprite.position = Vector2(0,-67)
    visual.modulate = Color.WHITE.lerp(critical_color,initial_redness)
    elapsed = 0.0
    active = true

func _process(delta: float) -> void:
    if not active or level.dead or level.exit_in_progress: return
    elapsed = minf(elapsed+delta,breath_duration)
    var progress := clampf(elapsed/maxf(breath_duration,.01),0.0,1.0)
    visual.modulate = Color.WHITE.lerp(critical_color,lerpf(initial_redness,1.0,progress))
    if progress >= 1.0:
        active = false
        sprite.texture = _region(DEAD_ART)
        level.die(&"drown")

func play_death() -> void:
    # 先展示原画叉眼死亡表情，再缓缓沉出屏幕；只移动视觉替身。
    active = false
    corpse = Sprite2D.new()
    corpse.texture = _region(DEAD_ART)
    corpse.flip_h = sprite.flip_h
    corpse.modulate = visual.modulate
    corpse.z_index = 40
    add_child(corpse)
    corpse.global_transform = body.global_transform*sprite.transform
    visual.hide()
    var bottom: float = level.camera.global_position.y+level.camera.get_viewport_rect().size.y*.5/level.camera.zoom.y
    var distance := maxf(180.0,bottom+144.0*absf(corpse.global_scale.y)-corpse.global_position.y)
    _motion = create_tween().set_ignore_time_scale(true)
    _motion.tween_interval(dead_hold_seconds)
    _motion.tween_property(corpse,"global_position",corpse.global_position+Vector2(0,distance),distance/sink_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    await _motion.finished
    corpse.hide()

func reset() -> void:
    active = false
    elapsed = 0.0
    if _motion != null: _motion.kill()
    if is_instance_valid(corpse):
        corpse.queue_free()
        corpse = null
    if _rest_texture != null:
        sprite.texture = _rest_texture
        sprite.position = _rest_position
        _rest_texture = null
    visual.modulate = Color.WHITE
