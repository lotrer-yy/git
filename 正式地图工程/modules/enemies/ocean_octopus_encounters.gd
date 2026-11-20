extends Node2D
## 两只轮换接续：每三秒遇见一只，每只仍完整经过画面五秒。
signal ink_sprayed
signal appeared(octopus: Node2D)
@export var spawn_interval: float = 3.0
@export var enabled: bool = false:
    set(value):
        if enabled == value: return
        enabled = value
        if is_node_ready(): reset()
var target: CharacterBody2D
var cycle_elapsed: float = 0.0
var _previous_player_y: float = 0.0
var _side: int = 1
var _finishing_visit: bool = false
@onready var visitors: Array[Node] = get_children()

func _ready() -> void:
    for visitor in visitors:
        visitor.ink_sprayed.connect(func(): ink_sprayed.emit())
    reset()

func configure(player: CharacterBody2D, camera: Camera2D) -> void:
    target = player
    _previous_player_y = player.global_position.y
    for visitor in visitors: visitor.configure(player,camera)

func _physics_process(delta: float) -> void:
    if not enabled or _finishing_visit or not is_instance_valid(target): return
    cycle_elapsed += delta
    var rising := target.global_position.y<_previous_player_y-.01
    _previous_player_y = target.global_position.y
    if cycle_elapsed<spawn_interval or not rising: return
    for visitor in visitors:
        if visitor.state!=visitor.State.WAITING: continue
        visitor.enabled = true
        visitor._side = _side
        visitor._appear()
        _side = visitor._side
        cycle_elapsed = 0.0
        appeared.emit(visitor)
        return

func finish_current_visit() -> void:
    _finishing_visit = true
    process_mode = Node.PROCESS_MODE_ALWAYS
    for visitor in visitors: visitor.finish_current_visit()

func reset() -> void:
    cycle_elapsed = 0.0
    _side = 1
    _finishing_visit = false
    process_mode = Node.PROCESS_MODE_INHERIT
    if is_instance_valid(target): _previous_player_y = target.global_position.y
    for visitor in visitors:
        visitor.enabled = false
        visitor.reset()
