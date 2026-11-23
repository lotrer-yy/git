extends Node2D
## 48 张独立绘制姿态：翅膀关节、羽毛遮挡和表情均来自序列原画。
const ART = preload("res://assets/art/sky/formal/eagle_flap_redrawn_48.png")
const FRAME_COUNT = 48
const CELL_SIZE = 512
const ATLAS_COLUMNS = 8
@export_range(0.1, 5.0) var cycle_seconds: float = 1.35
var sprite: Sprite2D
var frame_index: int = 0
var _clock: float = 0.0
var _frames: Array[AtlasTexture] = []

func _ready() -> void:
    sprite = Sprite2D.new()
    sprite.use_parent_material = true
    # Shared scale keeps the original eagle's world-space body size.
    sprite.scale = Vector2.ONE * (1595.0 / 384.0)
    add_child(sprite)
    for index in FRAME_COUNT:
        var frame := AtlasTexture.new()
        frame.atlas = ART
        frame.region = Rect2(Vector2(index % ATLAS_COLUMNS, index / ATLAS_COLUMNS) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
        frame.filter_clip = true
        _frames.append(frame)
    sample_frame(0)

func _process(delta: float) -> void:
    if not is_visible_in_tree(): return
    _clock = fposmod(_clock + delta, maxf(cycle_seconds, 0.1))
    var cursor := _clock / maxf(cycle_seconds, 0.1) * FRAME_COUNT
    var index := int(floor(cursor))
    if index != frame_index: sample_frame(index)

func sample_frame(index: int) -> void:
    frame_index = posmod(index, FRAME_COUNT)
    if is_instance_valid(sprite) and not _frames.is_empty():
        sprite.texture = _frames[frame_index]

func reset() -> void:
    _clock = 0.0
    sample_frame(0)
