extends Node
## 树冠过场、树冠跳出及鱼到松鼠、松鼠到鸟的独立音效装配。
@onready var level: Node2D = get_parent()
@onready var stage: Node2D = level.get_node("OceanLink/FishStage")
@onready var layout: Node2D = stage.get_node("JungleLayout")

func _ready() -> void:
    var crown: Node = layout.get_node("CanopyTransition")
    crown.started.connect(func():Sfx.play(&"sky_transition"))
    crown.play.bouncer.jumped.connect(func():Sfx.play(&"squirrel_jump"))
    var eagle: Node = layout.get_node("SkyEagle")
    eagle.screeched.connect(func():Sfx.play(&"eagle_call"))
    eagle.get_node("Eagle").downstroke.connect(_on_eagle_flap)
    eagle.get_node("Hail").ice_melted.connect(func():Sfx.play(&"sky_ice_break"))
    for controller in [stage.get_node("JunglePossession"),layout.get_node("CanopyPossession")]:
        controller.possession_started.connect(_on_transfer_started)
        controller.possession_finished.connect(_on_transfer_finished)

func _on_transfer_started(_host: PossessableHost) -> void:
    Sfx.play(&"soul_exit")

func _on_transfer_finished(_host: PossessableHost) -> void:
    Sfx.play(&"fish_enter")

func _on_eagle_flap() -> void:
    if not level.dead: Sfx.play(&"eagle_flap")
