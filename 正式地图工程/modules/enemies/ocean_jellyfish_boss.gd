extends Node2D
## 背景巨物登场：随上游进度唤醒，以世界速度从下方追入，不改相机。
signal appeared
enum State { DORMANT, RISING, PRESENT }
@export var enabled: bool = false
@export var ascent_before_entrance: float = 900.0
@export var artwork_scale: float = .56
@export var head_offset_below_player: float = 130.0
@export var maximum_rise_speed: float = 1100.0
@export var acceleration: float = 2200.0
@export var pulse_push: float = 210.0
var target: CharacterBody2D
var camera: Camera2D
var state: State = State.DORMANT
var _start_y: float = 0.0
var _has_baseline: bool = false
var _center_x: float = 960.0
var _clock: float = 0.0
var _vertical_speed: float = 0.0
@onready var visual: Node2D = $Visual

func _ready() -> void:
    reset()

func configure(player: CharacterBody2D, view: Camera2D, center_x: float = 960.0) -> void:
    target = player
    camera = view
    _center_x = center_x

func _physics_process(delta: float) -> void:
    if not enabled or not is_instance_valid(target) or not is_instance_valid(camera): return
    if not _has_baseline:
        _start_y = target.global_position.y
        _has_baseline = true
    if state == State.DORMANT:
        if _start_y-target.global_position.y >= ascent_before_entrance: _begin_entrance()
        return
    _clock += delta
    visual.sample(_clock)
    var desired_y := target.global_position.y+head_offset_below_player
    var error := desired_y-global_position.y
    var desired_speed := clampf(target.velocity.y+error*2.4-visual.thrust_at(_clock)*pulse_push,-maximum_rise_speed,180)
    _vertical_speed = move_toward(_vertical_speed,desired_speed,acceleration*delta)
    global_position.y += _vertical_speed*delta
    if state == State.RISING and _clock>2 and absf(error)<180: state = State.PRESENT

func _begin_entrance() -> void:
    # 正常开场沿用显示相机，Camera 是计算视野的虚拟机位；两条入口都读同一世界构图。
    var view_bottom := camera.global_position.y+camera.offset.y+camera.get_viewport_rect().size.y*.5/camera.zoom.y
    var crown_to_pivot: float = visual.ART.get_height()*.19*artwork_scale
    global_position = Vector2(_center_x,view_bottom+crown_to_pivot+100)
    _clock = 0
    _vertical_speed = 0
    state = State.RISING
    visual.scale = Vector2.ONE*artwork_scale
    visual.sample(0)
    show()
    appeared.emit()

func reset() -> void:
    enabled = false
    state = State.DORMANT
    _has_baseline = false
    _clock = 0
    _vertical_speed = 0
    hide()
    if is_instance_valid(visual):
        visual.scale = Vector2.ONE*artwork_scale
        visual.sample(0)
