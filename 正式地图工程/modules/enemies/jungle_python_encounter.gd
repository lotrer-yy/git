extends Node2D
## 巨蛇急扑临身后触发限时 WASD+Shift；成功脱险反击，失败打落但不直接死亡。
signal countered
signal player_struck
const BITE = preload("res://scenes/enemies/python_bite_animation.tscn")
const IMPACT = preload("res://modules/visual/python_counter_impact.gd")
const SEQUENCE = preload("res://modules/input/python_counter_sequence.gd")
enum State { WAITING, ENTERING, COILING, LUNGING, SEQUENCE, RECOVERING }
@export var first_attack_delay: float = 3.0
@export var attack_rest: float = 6.0
@export var warning_seconds: float = .95
@export var lunge_seconds: float = .22
var state: State = State.WAITING
var elapsed: float = 0
var attacks_started: int = 0
var counters: int = 0
var sequence: Node
var background_dim: Polygon2D
var impact: Node2D
var snake: Node2D
var pivot: Node2D
var _side: float = 1
var _start := Vector2.ZERO
var _coil := Vector2.ZERO
var _aim := Vector2.ZERO
var _strike_start := Vector2.ZERO
var _retreat_start := Vector2.ZERO
var _rest: float = 3
var _counter_success: bool = false
var _frozen: bool = false
var _reader_enabled: bool
var _reader_external: bool
var _motor_enabled: bool
var _climber_processing: bool
var _release_gate: bool = false
@onready var stage: Node = get_node("../..")
@onready var body: CharacterBody2D = get_node("../Squirrel")
@onready var reader: Node = body.get_node("Input")
@onready var motor: Node = body.get_node("Movement")
@onready var climber: Node = body.get_node("VineClimber")
func _ready() -> void:
    z_index=9
    # 同为z9时排在主藤蔓之后、蛇体之前；松鼠z10，不会被背景遮罩压暗。
    background_dim=Polygon2D.new()
    background_dim.color=Color(.015,.025,.015,.36)
    add_child(background_dim)
    background_dim.hide()
    pivot=Node2D.new()
    add_child(pivot)
    snake=BITE.instantiate()
    pivot.add_child(snake)
    snake.set_process(false)
    sequence=SEQUENCE.new()
    add_child(sequence)
    sequence.completed.connect(_resolve_sequence)
    impact=Node2D.new()
    impact.set_script(IMPACT)
    impact.z_index=4
    add_child(impact)
    impact.hide()
    pivot.hide()
    _rest=first_attack_delay
    if stage.has_node("ShoreExit") and stage.get_parent().get_parent().has_signal("died"):
        stage.get_parent().get_parent().died.connect(reset)
func _can_play() -> bool:
    if not stage.has_node("ShoreExit"): return false
    return stage.active and not stage.level.dead and stage.level.player==body and body.get_node("Host").claimed
func _view() -> Rect2:
    var camera: Camera2D = stage.level.camera
    var size: Vector2 = camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)
func _physics_process(delta: float) -> void:
    if _release_gate and _directions_released():
        _release_gate=false
        reader.external_control=_reader_external
        reader.clear()
    if not _can_play():
        if state!=State.WAITING: reset()
        return
    elapsed+=delta
    if state==State.WAITING:
        if elapsed>=_rest: _begin_attack()
    elif state==State.ENTERING:
        pivot.global_position=_start.lerp(_coil,smoothstep(0,.45,elapsed))
        snake.sample(-1)
        if elapsed>=.45:
            state=State.COILING
            elapsed=0
    elif state==State.COILING:
        # 前半段观察玩家，最后350毫秒方向锁定，不追着瞬移或镜头修正。
        if elapsed<warning_seconds-.35:
            _aim=_aim_position()
        snake.sample(.08+.35*clampf(elapsed/warning_seconds,0,1))
        if elapsed>=warning_seconds:
            state=State.LUNGING
            elapsed=0
            _strike_start=pivot.global_position
    elif state==State.LUNGING:
        var u: float = clampf(elapsed/lunge_seconds,0,1)
        pivot.global_position=_strike_start.lerp(_aim,u*u)
        snake.sample(.44+.12*u)
        var mouth: Vector2 = pivot.to_global(Vector2(330,-270))
        if u>=.7 and mouth.distance_to(body.global_position+Vector2(0,-50))<270 and _view().grow(80).has_point(mouth):
            _begin_sequence()
        elif u>=1:
            _begin_retreat(false)
    elif state==State.SEQUENCE:
        _update_dim()
        snake.sample(.55)
    elif state==State.RECOVERING:
        var u: float = smoothstep(0,.65,elapsed)
        pivot.global_position=_retreat_start+Vector2(-_side*(700 if _counter_success else 500)*u,100*u)
        snake.sample(.685+elapsed)
        if _counter_success:
            pivot.modulate=Color(1,1,1,1-u)
        if elapsed>=.7:
            pivot.hide()
            pivot.modulate=Color.WHITE
            state=State.WAITING
            elapsed=0
            _rest=attack_rest+(3 if attacks_started%2==0 else 0)
func _escape_direction() -> float:
    var nearest: Node2D
    var distance: float = INF
    for vine in get_parent().vines:
        if vine.global_position.y>=body.global_position.y-120: continue
        if climber.visited_vines.has(vine.get_instance_id()): continue
        var current: float = body.global_position.distance_to(vine.global_position)
        if current<distance:
            distance=current
            nearest=vine
    if is_instance_valid(nearest):
        var direction: float = signf(nearest.global_position.x-body.global_position.x)
        if direction!=0: return direction
    return -1 if body.global_position.x>960 else 1
func _aim_position() -> Vector2:
    var predicted: Vector2 = body.global_position+Vector2(0,-50)+(body.velocity*.15).limit_length(120)
    return predicted-Vector2(_side*330*1.6,-270*1.6)
func _begin_attack() -> void:
    if not _can_play(): return
    attacks_started+=1
    elapsed=0
    state=State.ENTERING
    _side=_escape_direction()
    pivot.scale=Vector2(_side*1.6,1.6)
    var view: Rect2 = _view()
    _coil=Vector2(view.position.x-120 if _side>0 else view.end.x+120,body.global_position.y+420)
    _start=_coil+Vector2(-_side*500,0)
    _aim=_aim_position()
    pivot.global_position=_start
    pivot.modulate=Color.WHITE
    pivot.show()
    snake.sample(-1)
func _begin_sequence() -> void:
    state=State.SEQUENCE
    elapsed=0
    _freeze_inputs()
    _update_dim()
    background_dim.show()
    sequence.begin()
func _update_dim() -> void:
    var view: Rect2 = _view().grow(200)
    background_dim.polygon=PackedVector2Array([to_local(view.position),to_local(Vector2(view.end.x,view.position.y)),to_local(view.end),to_local(Vector2(view.position.x,view.end.y))])
func _freeze_inputs() -> void:
    if _frozen: return
    _frozen=true
    _reader_enabled=reader.enabled
    _reader_external=reader.external_control
    _motor_enabled=motor.enabled
    _climber_processing=climber.is_physics_processing()
    reader.enabled=false
    reader.external_control=true
    reader.clear()
    motor.enabled=false
    climber.set_physics_process(false)
    if is_instance_valid(climber.vine): climber.vine.pump_axis=0
func _directions_released() -> bool:
    for key in [KEY_W,KEY_A,KEY_S,KEY_D]:
        if Input.is_physical_key_pressed(key): return false
    return true
func _restore_inputs(gate: bool) -> void:
    if not _frozen: return
    _frozen=false
    reader.enabled=_reader_enabled
    reader.clear()
    _release_gate=gate and not _directions_released()
    reader.external_control=true if _release_gate else _reader_external
    motor.enabled=_motor_enabled
    climber.set_physics_process(_climber_processing)
func _resolve_sequence(success: bool) -> void:
    if state!=State.SEQUENCE: return
    background_dim.hide()
    _restore_inputs(true)
    if is_instance_valid(climber.vine): climber.detach(false)
    if success:
        counters+=1
        impact.play_at(body.global_position+Vector2(-_side*55,-55))
        # 最后一记Shift确认脱险反击，向下一条藤蔓甩出；恢复正常飞行与抓绳。
        motor.launch_with_momentum(Vector2(_side*1000,-sqrt(2*motor.gravity*350)))
        body.get_node("Visual").play_possession_pulse()
        countered.emit()
    else:
        motor.launch_with_momentum(Vector2(-_side*500,420))
        body.get_node("Visual").play_selection_pulse()
        player_struck.emit()
    _begin_retreat(success)
func _begin_retreat(success: bool) -> void:
    _counter_success=success
    state=State.RECOVERING
    elapsed=0
    _retreat_start=pivot.global_position
func reset() -> void:
    if is_instance_valid(sequence): sequence.cancel()
    _restore_inputs(false)
    if _release_gate:
        reader.external_control=_reader_external
        reader.clear()
    _release_gate=false
    state=State.WAITING
    elapsed=0
    _rest=first_attack_delay
    attacks_started=0
    counters=0
    if is_instance_valid(background_dim): background_dim.hide()
    if is_instance_valid(impact): impact.hide()
    if is_instance_valid(pivot):
        pivot.hide()
        pivot.modulate=Color.WHITE
func _exit_tree() -> void:
    if is_instance_valid(sequence): sequence.cancel()
    if is_instance_valid(reader): _restore_inputs(false)
