extends Node2D
## 锁定来自 Nodes Plus；动作按投叉、插中、交换和弹射顺序执行。
const SURFACE = preload("res://modules/environment/hell_surface.gd")
signal exchanged(body: Node2D)
signal interaction_reset
@export var lock_distance: float = 610.0
@export var fork_tip_angle_degrees: float = -25.0
@export var throw_seconds: float = 0.28
@export var launch_seconds: float = 0.9
var demon: CharacterBody2D
var targets: Array[Node2D] = []
var selected: Node2D
var lodged: Node2D
var held: bool = true
var flying: bool = false
var launching: bool = false
var swapping: bool = false
var fork: Sprite2D
var motion: Tween
var _arrival_feedback: Tween
var detector: Area2D
var _visual: Node2D
var _held_material: ShaderMaterial
var _destination: Node2D
var _launch_start: Vector2

func _ready() -> void:
    demon = get_parent().get_node("Demon")
    _visual = demon.get_node("Visual")
    _held_material = ShaderMaterial.new()
    _held_material.shader = preload("res://shaders/demon_held_fork.gdshader")
    _visual.get_node("Sprite").material = _held_material
    _visual.get_node("SelectedSprite").material = _held_material
    fork = $ForkSprite
    targets.assign($Targets.get_children())
    detector = load("res://addons/nodes_plus/nodes/target2D.gd").new()
    detector.name = "TargetSensor"
    detector.auto_acquire = false
    detector.valid_groups.assign(["fork_targets"])
    detector.collision_layer = 0
    detector.collision_mask = 64
    var shape := CircleShape2D.new()
    shape.radius = lock_distance
    var collision := CollisionShape2D.new()
    collision.shape = shape
    detector.add_child(collision)
    add_child(detector)

func _physics_process(_delta: float) -> void:
    detector.global_position = demon.global_position + Vector2(0,-60)
    if not demon.get_node("Host").claimed or flying or launching or swapping or is_instance_valid(lodged):
        return
    detector.acquire_nearest()
    var nearest: Node2D = detector.get_target()
    if nearest == selected:
        return
    if is_instance_valid(selected):
        selected.set_state(0)
    selected = nearest
    if is_instance_valid(selected):
        selected.set_state(1)

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed(&"possess") or event.is_echo() or not demon.get_node("Host").claimed:
        return
    if event is InputEventKey and event.location == KEY_LOCATION_RIGHT:
        return
    if flying or launching or swapping:
        return
    if is_instance_valid(lodged):
        _swap_and_bounce()
    elif is_instance_valid(selected):
        _throw()
    else:
        return
    get_viewport().set_input_as_handled()

func _throw() -> void:
    if flying or swapping or launching or not is_instance_valid(selected):
        return
    flying = true
    lodged = selected
    selected = null
    fork.global_position = demon.global_position + Vector2(50*demon.get_node("Movement").facing,-70)
    var incoming := (lodged.global_position-fork.global_position).angle()
    fork.global_rotation = incoming - deg_to_rad(fork_tip_angle_degrees)
    lodged.hit_angle = incoming
    fork.show()
    _set_held(false)
    var start := fork.global_position
    motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    motion.tween_method(func(u: float): fork.global_position = start.lerp(lodged.global_position,u),0.0,1.0,throw_seconds)
    motion.tween_callback(func():
        flying = false
        lodged.set_state(2)
        fork.hide())

func _swap_and_bounce() -> void:
    if flying or swapping or launching or not is_instance_valid(lodged):
        return
    _destination = null
    var distance := INF
    var candidates: Array = get_tree().get_nodes_in_group("hell_platforms")
    candidates.append_array(get_parent().get_node("Terrain").get_children())
    for body in candidates:
        if body is AnimatableBody2D and body.broken:
            continue
        var point: Vector2 = SURFACE.landing_on(body)
        if not is_finite(point.y) or point.y >= lodged.global_position.y-40:
            continue
        var gap := point.distance_to(lodged.global_position)
        if gap < distance:
            distance = gap
            _destination = body
    if _destination == null:
        return
    if motion != null:
        motion.kill()
    swapping = true
    _lock_control()
    _visual.set_process(false)
    _visual.position = Vector2.ZERO
    motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    motion.tween_property(_visual,"scale",Vector2(0.08,0.12),0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    motion.tween_callback(_exchange)
    motion.tween_property(_visual,"scale",Vector2(1.24,0.78),0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    motion.tween_callback(_release_ball)

func _lock_control() -> void:
    demon.get_node("Movement").enabled = false
    demon.get_node("Input").enabled = false
    demon.get_node("Input").clear()
    demon.velocity = Vector2.ZERO

func _exchange() -> void:
    demon.global_position = lodged.get_node("SwapPoint").global_position
    fork.hide()
    lodged.bounce_on_teleport()
    _set_held(true)
    demon.reset_physics_interpolation()
    exchanged.emit(demon)

func _release_ball() -> void:
    lodged = null
    if _arrival_feedback != null: _arrival_feedback.kill()
    _arrival_feedback = create_tween()
    _arrival_feedback.tween_property(_visual,"scale",Vector2.ONE,0.26).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
    swapping = false
    launching = true
    fork.hide()
    _launch_start = demon.global_position
    motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    motion.tween_method(_sample_launch,0.0,1.0,launch_seconds)
    motion.tween_callback(_end_launch)

func _sample_launch(u: float) -> void:
    var finish: Vector2 = SURFACE.landing_on(_destination)
    var height := maxf(180.0,(_launch_start.y-finish.y)*0.4)
    var point := _launch_start.lerp(finish,u)-Vector2(0,4.0*height*u*(1.0-u))
    var collision := demon.move_and_collide(point-demon.global_position)
    if collision != null:
        motion.kill()
        _end_launch()

func _end_launch() -> void:
    launching = false
    if _arrival_feedback != null: _arrival_feedback.kill()
    _visual.scale = Vector2.ONE
    _visual.position = Vector2.ZERO
    _visual.set_process(true)
    demon.get_node("Movement").enabled = true
    demon.get_node("Input").enabled = true
    demon.get_node("Movement").landed.emit(650.0)

func reset() -> void:
    interaction_reset.emit()
    if motion != null:
        motion.kill()
    if _arrival_feedback != null:
        _arrival_feedback.kill()
    fork.hide()
    _set_held(true)
    selected = null
    lodged = null
    flying = false
    swapping = false
    launching = false
    _visual.scale = Vector2.ONE
    _visual.position = Vector2.ZERO
    _visual.set_process(true)
    detector.clear_target()
    for target in targets:
        target.set_state(0)

func camera_interest() -> Node2D:
    if launching and is_instance_valid(_destination):
        return _destination
    if is_instance_valid(lodged):
        return lodged
    return selected if is_instance_valid(selected) else null

func _set_held(value: bool) -> void:
    held = value
    _held_material.set_shader_parameter("has_fork", held)
    var texture = load("res://assets/art/hell/new/right.png")
    _visual.get_node("Sprite").texture = texture
    _visual.get_node("SelectedSprite").texture = texture
