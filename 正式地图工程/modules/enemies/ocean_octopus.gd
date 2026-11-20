extends Node2D
## 上游时从视野上方遇见，缓慢经过镜头；屏幕墨迹由独立模块接收信号。
signal ink_sprayed
signal appeared
enum State { WAITING, ENTERING, SWIMMING, SQUASHING, INKING, EXITING }
@export var spawn_interval: float = 3.0
@export var automatic_spawning: bool = true
@export var proximity_radius: float = 230.0
@export var visible_seconds: float = 5.0
@export var swim_amplitude: float = 28.0
@export var swim_period: float = 2.4
@export var lateral_amplitude: float = 18.0
@export var lateral_period: float = 6.0
@export var enabled: bool = false:
    set(value):
        if enabled == value: return
        enabled = value
        if is_node_ready(): reset()
var target: CharacterBody2D
var camera: Camera2D
var state: State = State.WAITING
var cycle_elapsed: float = 0.0
var state_elapsed: float = 0.0
var _side: int = 1
var _anchor := Vector2.ZERO
var _visit_elapsed: float = 0.0
var _previous_player_y: float = 0.0
var _sprayed: bool = false
var _finishing_visit: bool = false
var _anchors: Dictionary
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Art

func _ready() -> void:
    _anchors = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/ocean/octopus/anchors.json"))
    sprite.frame_changed.connect(_register_frame)
    sprite.animation_changed.connect(_register_frame)
    reset()

func configure(player: CharacterBody2D, view: Camera2D) -> void:
    target = player
    camera = view
    _previous_player_y = player.global_position.y

func _physics_process(delta: float) -> void:
    if not enabled or not is_instance_valid(target) or not is_instance_valid(camera): return
    if _finishing_visit and state == State.WAITING: return
    var rising := target.global_position.y < _previous_player_y-.01
    _previous_player_y = target.global_position.y
    cycle_elapsed += delta
    state_elapsed += delta
    if state != State.WAITING:
        _visit_elapsed += delta
        _follow_view()
        if _visit_elapsed >= visible_seconds:
            hide()
            sprite.pause()
            _change_state(State.WAITING)
    match state:
        State.WAITING:
            if automatic_spawning and not _finishing_visit and cycle_elapsed >= spawn_interval and rising: _appear()
        State.ENTERING:
            if _visit_elapsed >= visible_seconds*.2: _change_state(State.SWIMMING)
        State.SWIMMING:
            if not _finishing_visit and not _sprayed and _visit_elapsed <= visible_seconds-.3-8.0/12.0 and global_position.distance_to(target.global_position) <= proximity_radius:
                _change_state(State.SQUASHING)
            elif _visit_elapsed >= visible_seconds*.8:
                _change_state(State.EXITING)
        State.SQUASHING:
            if state_elapsed < .1:
                visual.scale = Vector2.ONE.lerp(Vector2(1.18,.8),smoothstep(0,.1,state_elapsed))
            elif state_elapsed < .21:
                visual.scale = Vector2(1.18,.8).lerp(Vector2(.92,1.12),smoothstep(.1,.21,state_elapsed))
            else:
                visual.scale = Vector2(.92,1.12).lerp(Vector2.ONE,smoothstep(.21,.3,state_elapsed))
            if state_elapsed >= .3:
                visual.scale = Vector2.ONE
                _sprayed = false
                sprite.play(&"ink")
                _change_state(State.INKING)
        State.INKING:
            if not _sprayed and state_elapsed >= 3.0/12.0:
                _sprayed = true
                var teleport := target.get_node_or_null("Teleport")
                if teleport == null or not teleport.is_invulnerable(): ink_sprayed.emit()
            if state_elapsed >= 8.0/12.0:
                sprite.play(&"swim")
                _change_state(State.SWIMMING)
    visual.scale.x = absf(visual.scale.x)*(-1.0 if _side>0 else 1.0)

func _process(_delta: float) -> void:
    if enabled and state != State.WAITING: _follow_view()

func _view_rect() -> Rect2:
    var size := camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)

func _appear() -> void:
    cycle_elapsed = 0.0
    _visit_elapsed = 0.0
    _sprayed = false
    _side = -_side
    var view := _view_rect()
    var player_screen := target.global_position-view.position
    _anchor = player_screen+Vector2(float(_side)*180,0)
    visual.scale = Vector2(-1.0 if _side>0 else 1.0,1.0)
    sprite.play(&"swim")
    _change_state(State.ENTERING)
    _follow_view()
    show()
    appeared.emit()

func _follow_view() -> void:
    var view := _view_rect()
    # 章鱼相对上游镜头向下经过，不再横向快速入场或喷完立即退场。
    var phase := clampf(_visit_elapsed/visible_seconds,0.0,1.0)
    var margin := minf(130.0,view.size.x*.4)
    var drift := sin(_visit_elapsed*TAU/lateral_period)*lateral_amplitude
    var bob := sin(_visit_elapsed*TAU/swim_period)*swim_amplitude*sin(phase*PI)
    var point := Vector2(clampf(_anchor.x+drift,margin,view.size.x-margin),lerpf(-100.0,view.size.y+110.0,phase)+bob)
    global_position = view.position+point

func _change_state(next: State) -> void:
    state = next
    state_elapsed = 0.0

func finish_current_visit() -> void:
    # 鲨鱼击落只停止新交互；当前游动、受惊和吐墨动画仍按原进度完成。
    _finishing_visit = true
    process_mode = Node.PROCESS_MODE_ALWAYS

func _register_frame() -> void:
    var pivot: Array = _anchors[sprite.animation][sprite.frame]
    var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
    sprite.offset = texture.get_size()*.5-Vector2(pivot[0],pivot[1])
    sprite.scale = Vector2.ONE*(.42 if sprite.animation==&"swim" else .48)

func reset() -> void:
    process_mode = Node.PROCESS_MODE_INHERIT
    _finishing_visit = false
    state = State.WAITING
    cycle_elapsed = 0.0
    state_elapsed = 0.0
    _side = 1
    _sprayed = false
    _visit_elapsed = 0.0
    if is_instance_valid(target): _previous_player_y = target.global_position.y
    hide()
    visual.scale = Vector2.ONE
    sprite.play(&"swim")
    sprite.stop()
    _register_frame()
