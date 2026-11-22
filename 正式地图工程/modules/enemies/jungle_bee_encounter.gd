extends Node2D
## 蜂巢脱落信号只生成一只蜜蜂；蜜蜂留在世界坐标，不跟随落下的蜂巢。
const STINGER = preload("res://modules/enemies/jungle_bee_stinger.gd")
const BEE = preload("res://modules/enemies/jungle_bee.gd")
@onready var stage: Node = get_node("../..")
@onready var body: CharacterBody2D = get_node("../Squirrel")
func _ready() -> void:
    z_index=12
    if stage.has_node("ShoreExit"):
        var level: Node = stage.get_parent().get_parent()
        if level.has_signal("died"): level.died.connect(reset)
    for hive in get_node("../Beehives").get_children():
        hive.dropped.connect(_spawn.bind(hive))
func is_active() -> bool:
    return stage.has_node("ShoreExit") and stage.active and not stage.level.dead and stage.level.player==body and body.get_node("Host").claimed
func _spawn(hive: Sprite2D) -> void:
    if not is_active(): return
    var bee:=CharacterBody2D.new()
    bee.set_script(BEE)
    bee.encounter=self
    bee.ranged=hive.bee_variant==1
    add_child(bee)
    bee.global_position=hive.to_global(Vector2(0,210))
func defeat_player() -> void:
    if is_active(): stage.level.die(&"bee")
func fire_stinger(origin: Vector2,aim: Vector2) -> void:
    if not is_active() or not is_on_screen(origin): return
    var needle:=Node2D.new()
    needle.set_script(STINGER)
    needle.encounter=self
    add_child(needle)
    needle.global_position=origin
    needle.launch(aim)
func _physics_process(_delta: float) -> void:
    if not is_active() and get_child_count()>0: reset()
func flight_bounds() -> Rect2:
    var rect: Rect2 = _view_rect().grow(400)
    rect.position.x=80
    rect.size.x=1760
    return rect
func _view_rect() -> Rect2:
    var camera: Camera2D = stage.level.camera
    var size: Vector2 = camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)
func is_on_screen(point: Vector2) -> bool:
    return _view_rect().grow(-60).has_point(point)
func enemies() -> Array:
    return get_children().filter(func(bee): return bee.is_in_group("jungle_bees") and not bee.is_queued_for_deletion())
func reset() -> void:
    for bee in get_children():
        bee.set_physics_process(false)
        bee.hide()
        bee.queue_free()
