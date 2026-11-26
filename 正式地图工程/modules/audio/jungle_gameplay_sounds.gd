extends Node
## 丛林音效独立装配；每只蜜蜂拥有自己的嗡鸣，击败时只停止该只。
@onready var level: Node2D = get_parent()
@onready var stage: Node2D = level.get_node("OceanLink/FishStage")
@onready var layout: Node2D = stage.get_node("JungleLayout")
@onready var squirrel: CharacterBody2D = layout.get_node("Squirrel")

func _ready() -> void:
    stage.get_node("ShoreExit").landed_on_shore.connect(_on_fish_landed)
    squirrel.get_node("Movement").jumped.connect(_on_jump)
    squirrel.get_node("Movement").landed.connect(_on_landed)
    var climber: Node = squirrel.get_node("VineClimber")
    climber.released.connect(_on_release)
    climber.grabbed.connect(_on_grab)
    climber.jumped_from_vine.connect(_on_jump)
    var encounter: Node = layout.get_node("BeeEncounter")
    encounter.bee_spawned.connect(_on_bee_spawned)
    encounter.stinger_fired.connect(func():Sfx.play(&"bee_stinger"))
    for hive in layout.get_node("Beehives").get_children():
        hive.loosened.connect(func():Sfx.play(&"hive_hit"))

func _controlled() -> bool:
    return level.player==squirrel and not level.dead and squirrel.get_node("Host").claimed

func _on_fish_landed() -> void:
    if level.player==stage.fish and not level.dead: Sfx.play(&"fish_shore_leap")

func _on_jump() -> void:
    if _controlled(): Sfx.play(&"squirrel_jump")

func _on_landed(_impact: float) -> void:
    if _controlled(): Sfx.play(&"squirrel_land")

func _on_release(_velocity: Vector2) -> void:
    if _controlled(): Sfx.play(&"vine_release")

func _on_grab() -> void:
    if _controlled(): Sfx.play(&"vine_grab")

func _on_bee_spawned(bee: CharacterBody2D) -> void:
    var buzz := AudioStreamPlayer2D.new()
    buzz.name = "Buzz"
    buzz.bus = &"SFX"
    buzz.stream = load(Sfx.FOLDER+Sfx.levels.bee_buzz.file).duplicate()
    buzz.stream.loop = true
    buzz.volume_db = Sfx.levels.bee_buzz.gain_db
    buzz.max_distance = 2200.0
    buzz.process_mode = Node.PROCESS_MODE_ALWAYS
    bee.add_child(buzz)
    buzz.play()
    bee.defeated.connect(func():
        buzz.stop()
        Sfx.play(&"bee_defeat"))
