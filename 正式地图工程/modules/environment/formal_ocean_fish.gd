extends Node2D
## 仅装配旧鱼角色、附身和游泳程序；原海图与地形仍由正式场景提供。
var active: bool = false
var _spawn: Vector2
@onready var level: Node2D = get_parent().get_parent()
@onready var fish: CharacterBody2D = $Fish
@onready var possession: PossessionController = $Possession
@onready var host: PossessableHost = $Fish/Host
@onready var breath: Node = get_node("../Breath")

func _ready() -> void:
    _spawn = fish.position
    # 海洋宿主只供海洋控制器选择，地狱幽灵不会跨阶段选择它。
    host.remove_from_group("possessable_hosts")
    host.add_to_group("formal_ocean_fish_hosts")
    possession.possession_started.connect(_on_transfer_started)
    possession.possession_finished.connect(_on_transfer_finished)
    level.died.connect(_on_player_died)

func activate() -> void:
    if active: return
    active = true
    process_mode = Node.PROCESS_MODE_INHERIT
    show()
    fish.position = _spawn
    fish.reset_physics_interpolation()
    host.reset()
    fish.get_node("Patrol").center = _spawn
    # 避免第二个控制器在地狱开场期间隐藏共用幽灵。
    possession.soul_initially_hidden = true
    possession.reset()
    possession.enabled = true

func _on_transfer_started(_chosen_host: PossessableHost) -> void:
    breath.release_soul()
    level.player = level.soul

func _on_transfer_finished(chosen_host: PossessableHost) -> void:
    level.player = chosen_host.body

func _on_player_died() -> void:
    if not active: return
    if possession.state == PossessionController.State.TRANSFERRING:
        possession.reset()
    possession.enabled = false
    possession.clear_selection()

func reset() -> void:
    if not active: return
    possession.reset()
    possession.enabled = false
    fish.position = _spawn
    fish.get_node("Patrol").center = _spawn
    host.reset()
    active = false
    hide()
    process_mode = Node.PROCESS_MODE_DISABLED
