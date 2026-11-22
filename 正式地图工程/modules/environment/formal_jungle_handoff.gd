extends Node
## 岸上鱼到最低藤蔓松鼠的独立附身衔接。
@onready var stage: Node2D = get_parent()
@onready var possession: PossessionController = get_node("../JunglePossession")
@onready var shore: Node = get_node("../ShoreExit")
func _ready() -> void:
    possession.soul_initially_hidden = true
    possession.possession_started.connect(_started)
    possession.possession_finished.connect(_finished)
func _physics_process(_delta: float) -> void:
    if possession.state!=PossessionController.State.ROAMING: return
    possession.enabled = stage.active and not stage.level.dead and stage.level.player==stage.fish and shore.state==shore.State.STRANDED
func _started(_host: PossessableHost) -> void:
    stage.level.player = possession.soul
    stage.fish.get_node("Teleport").enabled = false
    shore.release_soul()
func _finished(host: PossessableHost) -> void:
    stage.level.player = host.body
func reset() -> void:
    possession.reset()
    possession.enabled = false
func cancel() -> void:
    if possession.state==PossessionController.State.TRANSFERRING: possession.reset()
    possession.enabled = false
    possession.clear_selection()
