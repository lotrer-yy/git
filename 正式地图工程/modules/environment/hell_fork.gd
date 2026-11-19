extends Node2D
## 锁定来自 Nodes Plus；动作按投叉、插中、交换和弹射顺序执行。
const SURFACE = preload("res://modules/environment/hell_surface.gd")
signal exchanged(body: Node2D)
signal interaction_reset
@export_range(0.0,1.0) var enemy_hit_chance: float = 0.8
var _enemy_attack_target: Node2D
var _combat_rng := RandomNumberGenerator.new()
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
    _combat_rng.randomize()
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
    if is_instance_valid(nearest) and nearest.is_in_group("hell_flying_enemies"):
        nearest=null
        var best_ball:=INF
        for candidate in detector.get_all_targets():
            if is_instance_valid(candidate) and not candidate.is_in_group("hell_flying_enemies"):
                var gap:float=detector.global_position.distance_squared_to(candidate.global_position)
                if gap<best_ball:best_ball=gap;nearest=candidate
    var best_enemy := lock_distance*lock_distance
    # 动态入场的敌人不能只依赖 Area 首次进入事件：入场时它尚不可选。
    for candidate in get_tree().get_nodes_in_group("hell_flying_enemies"):
        if not is_instance_valid(candidate) or not candidate.is_in_group("fork_targets") or candidate.is_defeated() or not candidate.encounter.is_on_screen(candidate.global_position):continue
        var distance:float=detector.global_position.distance_squared_to(candidate.global_position)
        if distance<best_enemy and get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(detector.global_position,candidate.global_position,9)).is_empty():
            best_enemy=distance
            nearest=candidate
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
    if selected.is_in_group("hell_flying_enemies"):
        _throw_at_enemy()
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
    if is_instance_valid(_enemy_attack_target): _enemy_attack_target.set_state(0)
    _enemy_attack_target = null
    _visual.scale = Vector2.ONE
    _visual.position = Vector2.ZERO
    _visual.set_process(true)
    detector.clear_target()
    for target in targets:
        target.set_state(0)

func camera_interest() -> Node2D:
    if is_instance_valid(_enemy_attack_target): return _enemy_attack_target
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

func _throw_at_enemy() -> void:
    var victim:Node2D=selected
    selected=null
    _enemy_attack_target=victim
    flying=true
    _set_held(false)
    fork.global_position=demon.global_position+Vector2(45*demon.get_node("Movement").facing,-65)
    fork.show()
    var start:=fork.global_position
    var hit:=_combat_rng.randf()<enemy_hit_chance
    var miss_point:=victim.global_position+Vector2(145 if _combat_rng.randf()<.5 else -145,-105)
    motion=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    motion.tween_method(func(u:float):
        var destination:Vector2=victim.global_position if hit and is_instance_valid(victim) else miss_point
        fork.global_position=start.lerp(destination,u)
        fork.global_rotation=(destination-start).angle()-deg_to_rad(fork_tip_angle_degrees),0.0,1.0,.23)
    motion.tween_callback(func():
        if is_instance_valid(victim):
            victim.set_state(0)
            if hit: victim.take_hit()
        _enemy_attack_target=null)
    motion.tween_callback(_return_enemy_fork)

func _return_enemy_fork() -> void:
    var start:=fork.global_position
    motion=create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    motion.tween_method(func(u:float):
        var hand:=demon.global_position+Vector2(45*demon.get_node("Movement").facing,-65)
        fork.global_position=start.lerp(hand,u)
        fork.global_rotation=(hand-start).angle()-deg_to_rad(fork_tip_angle_degrees),0.0,1.0,.23)
    motion.tween_callback(func():
        fork.hide()
        _set_held(true)
        flying=false
        _visual.play_fork_recall_pulse())
