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
    $Shark.configure(fish,get_node("../../Camera"))
    $Shark.player_hit.connect(_on_shark_hit)
    $Octopus.configure(fish,get_node("../../Camera"))
    $Octopus.ink_sprayed.connect($InkOverlay.splash)
    for lane in $PinkSharks.get_children():
        lane.configure(fish,get_node("../../Camera"))
        lane.player_hit.connect(_on_pink_shark_hit)

func _physics_process(_delta: float) -> void:
    var y: float = level.to_local(fish.global_position).y
    var can_attack: bool = active and host.claimed and level.player == fish and not level.dead and not level.exit_in_progress and level.visible and y >= 29978.0 and y <= 39138.0
    $Shark.enabled = can_attack
    for lane in $PinkSharks.get_children(): lane.damage_enabled = can_attack
    if not (level.dead and level.death_reason in [&"shark",&"pink_shark"]):
        $Octopus.enabled = can_attack
        if not can_attack: $InkOverlay.reset()

func _on_shark_hit(direction: Vector2) -> void:
    $SharkKnockback.impact_direction = direction
    level.die(&"shark")

func _on_pink_shark_hit(direction: Vector2) -> void:
    $SharkKnockback.impact_direction = direction
    level.die(&"pink_shark")

func activate() -> void:
    if active: return
    active = true
    process_mode = Node.PROCESS_MODE_INHERIT
    show()
    # 避免第二个控制器在地狱开场期间隐藏共用幽灵。
    possession.soul_initially_hidden = true
    possession.reset()
    possession.enabled = true

func _on_transfer_started(_chosen_host: PossessableHost) -> void:
    breath.release_soul()
    level.player = level.soul

func _on_transfer_finished(chosen_host: PossessableHost) -> void:
    level.player = chosen_host.body
    fish.get_node("Teleport").enabled = true
    for lane in $PinkSharks.get_children(): lane.running = true

func _on_player_died() -> void:
    if not active: return
    $Shark.enabled = false
    for lane in $PinkSharks.get_children(): lane.damage_enabled = false
    if level.death_reason in [&"shark",&"pink_shark"]:
        $Octopus.finish_current_visit()
        $InkOverlay.process_mode = Node.PROCESS_MODE_ALWAYS
    else:
        $Octopus.enabled = false
        $InkOverlay.reset()
    fish.get_node("Teleport").enabled = false
    fish.get_node("Teleport").reset()
    if possession.state == PossessionController.State.TRANSFERRING:
        possession.reset()
    possession.enabled = false
    possession.clear_selection()

func reset() -> void:
    for lane in $PinkSharks.get_children(): lane.reset()
    $Octopus.enabled = false
    $Octopus.reset()
    $InkOverlay.reset()
    $InkOverlay.process_mode = Node.PROCESS_MODE_INHERIT
    $Shark.enabled = false
    $Shark.reset()
    $SharkKnockback.reset()
    $SideTentacle.reset()
    fish.get_node("Teleport").enabled = false
    fish.get_node("Teleport").reset()
    if active: possession.reset()
    possession.enabled = false
    fish.position = _spawn
    fish.get_node("Patrol").center = _spawn
    host.reset()
    active = false
    show()
    process_mode = Node.PROCESS_MODE_INHERIT
