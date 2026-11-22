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
        if level.has_signal("died"): level.died.connect(_on_player_defeated)
    for hive in get_node("../Beehives").get_children():
        hive.dropped.connect(_spawn.bind(hive))
func can_simulate() -> bool:
    return stage.has_node("ShoreExit") and stage.active and stage.level.player==body and body.get_node("Host").claimed
func is_active() -> bool:
    return can_simulate() and not stage.level.dead
func _on_player_defeated() -> void:
    if can_simulate(): process_mode=Node.PROCESS_MODE_ALWAYS
func bee_deflected() -> void:
    body.get_node("AirSpin").play_deflect_pulse()
func _spawn(hive: Sprite2D) -> void:
    if not is_active(): return
    var bee:=CharacterBody2D.new()
    bee.set_script(BEE)
    bee.encounter=self
    bee.ranged=hive.bee_variant==1
    add_child(bee)
    bee.global_position=hive.to_global(Vector2(0,210))
func player_spinning() -> bool:
    return body.get_node("AirSpin").is_invulnerable()
func target_position() -> Vector2:
    if player_spinning(): return body.get_node("AirSpin").sprite.global_position
    var art: Sprite2D = body.get_node("Visual/Sprite")
    # 以可见躯干为目标，包含挂藤时的视觉偏移、摆动倾斜和翻转。
    var torso:=Vector2(art.texture.get_width()*.14*(1 if art.flip_h else -1),-art.texture.get_height()*.05)
    return art.to_global(torso)
func predicted_target(seconds: float) -> Vector2:
    return target_position()+(body.velocity*seconds).limit_length(140)
func intercept_target(origin: Vector2,attack_speed: float,max_lead: float = .3) -> Vector2:
    var target: Vector2=target_position()
    var motion: Vector2=body.velocity.limit_length(1700)
    var offset: Vector2=target-origin
    var a: float=motion.length_squared()-attack_speed*attack_speed
    var b: float=2*offset.dot(motion)
    var c: float=offset.length_squared()
    var time: float=offset.length()/maxf(attack_speed,1)
    var discriminant: float=b*b-4*a*c
    if absf(a)>.001 and discriminant>=0:
        var first: float=(-b-sqrt(discriminant))/(2*a)
        var second: float=(-b+sqrt(discriminant))/(2*a)
        if first>0 and second>0: time=minf(first,second)
        elif first>0: time=first
        elif second>0: time=second
    return target+(motion*clampf(time,.02,max_lead)).limit_length(420)
func defeat_player() -> void:
    if is_active() and not player_spinning(): stage.level.die(&"bee")
func fire_stinger(origin: Vector2,aim: Vector2) -> void:
    if not is_active() or not is_on_screen(origin): return
    var needle:=Node2D.new()
    needle.set_script(STINGER)
    needle.encounter=self
    add_child(needle)
    needle.global_position=origin
    needle.launch(aim)
func _physics_process(_delta: float) -> void:
    if not can_simulate() and get_child_count()>0: reset()
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
    process_mode=Node.PROCESS_MODE_INHERIT
    for bee in get_children():
        bee.set_physics_process(false)
        bee.hide()
        bee.queue_free()
