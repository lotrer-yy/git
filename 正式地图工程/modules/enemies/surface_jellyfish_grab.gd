extends Node2D
## 海面前的一次追尾缠绕：固定出手方向，瞬移避开或挣脱，不产生额外死亡。
const TENDRIL = preload("res://modules/visual/jellyfish_net_tendril.gd")
const WARNING = preload("res://modules/visual/tentacle_warning.gd")
const CAUGHT_ART = preload("res://assets/art/characters/fish/abilities/entangled.png")
enum State { WAITING, WARNING, REACHING, CAUGHT, FINISHED }
@export var trigger_depth: float = 1100.0
@export var warning_seconds: float = 1.4
@export var warning_rise_speed: float = 260.0
@export var anticipation_seconds: float = 0.0
@export var reach_seconds: float = .38
@export var recent_blink_seconds: float = .7
var state: State = State.WAITING
var elapsed: float = 0
var _since_blink: float = 100
var _warning_arms: Array[Node2D] = []
var _arm: Node2D
var _caught_art: Sprite2D
var _restore_motor: bool = false
var _restore_visual: bool = true
var _previous_tip := Vector2.ZERO
@onready var stage: Node2D = get_parent()
@onready var fish: CharacterBody2D = get_node("../Fish")
@onready var blink: Node = fish.get_node("Teleport")
@onready var motor: Node = fish.get_node("Movement")
@onready var visual: Node2D = fish.get_node("Visual")
@onready var shore: Node = stage.get_node("ShoreExit")
func _ready() -> void:
    z_index = 14
    blink.teleported.connect(_on_blink)
func _physics_process(delta: float) -> void:
    if not stage.active or stage.level.dead or stage.level.player!=fish: return
    _since_blink += delta
    if shore.state!=shore.State.SWIMMING:
        if state in [State.WARNING,State.REACHING,State.CAUGHT]: _finish()
        return
    if state==State.WAITING:
        var depth: float = fish.position.y-shore.surface_y
        if depth>trigger_depth or depth<80 or fish.velocity.y>-40: return
        if _since_blink<recent_blink_seconds or blink.is_invulnerable():
            state = State.FINISHED
        else:
            _begin_warning()
        return
    elapsed += delta
    if state==State.WARNING:
        _sample_warning(delta)
        if elapsed>=warning_seconds: _begin_reach()
    elif state==State.REACHING:
        _arm.sample(elapsed)
        _arm.body.collision_layer = 0
        _arm.dangerous = false
        var tip: Vector2 = _arm.to_global(_arm.centerline[-1])
        var center: Vector2 = fish.get_node("Collision").global_position
        if elapsed>=anticipation_seconds and not blink.is_invulnerable():
            var closest := Geometry2D.get_closest_point_to_segment(center,_previous_tip,tip)
            if closest.distance_to(center)<_arm.thickness*.5+24:
                _catch()
        _previous_tip = tip
        if state==State.REACHING and elapsed>anticipation_seconds+reach_seconds+.18: _finish()
    elif state==State.CAUGHT:
        var spring := sin(elapsed*22)*exp(-elapsed*8)
        _caught_art.scale = Vector2(1+spring*.28,1-spring*.20)
        _caught_art.rotation = spring*.10
func _begin_warning() -> void:
    state = State.WARNING
    elapsed = 0
    var camera: Camera2D = stage.level.camera
    var size := camera.get_viewport_rect().size/camera.zoom
    var view := Rect2(camera.global_position+camera.offset-size*.5,size)
    for i in 4:
        var arm := TENDRIL.new()
        arm.thickness = 62
        arm.charge_seconds = 0
        arm.strike_seconds = .4
        var x: float = view.position.x+view.size.x*(.20+float(i)*.20)
        arm.position = to_local(Vector2(x,view.end.y+240))
        arm.start = Vector2.ZERO
        arm.finish = Vector2(-35 if i%2==0 else 35,-430)
        arm.curve_height = 25 if i%2==0 else -25
        add_child(arm)
        var warning := WARNING.new()
        warning.name = "Warning"
        warning.position = arm.finish+Vector2(0,-85)
        arm.add_child(warning)
        arm.sample(0)
        arm.body.collision_layer = 0
        arm.dangerous = false
        _warning_arms.append(arm)
func _sample_warning(delta: float) -> void:
    for i in _warning_arms.size():
        var arm := _warning_arms[i]
        # 按自身速度向上游动，不复制相机位置；微微摆动并带蓄力回弹。
        arm.position.y -= warning_rise_speed*delta
        arm.rotation = sin(elapsed*4.8+i*1.4)*.045
        arm.sample(maxf(0,elapsed-float(i)*.07))
        arm.body.collision_layer = 0
        arm.dangerous = false
        arm.get_node("Warning").sample(elapsed-.20-float(i)*.07)
func _begin_reach() -> void:
    state = State.REACHING
    elapsed = 0
    var center: Vector2 = fish.get_node("Collision").global_position
    var predicted: Vector2 = center+(fish.velocity*reach_seconds).limit_length(240)
    var nearest := INF
    for candidate in _warning_arms:
        var tip: Vector2 = candidate.to_global(candidate.centerline[-1])
        if tip.distance_to(center)<nearest:
            nearest = tip.distance_to(center)
            _arm = candidate
    for candidate in _warning_arms:
        candidate.get_node("Warning").hide()
        if candidate!=_arm:
            candidate.create_tween().tween_property(candidate,"modulate:a",0.0,.25)
    _previous_tip = _arm.to_global(_arm.centerline[-1])
    _arm.initial_reach = _arm.start.distance_to(_arm.finish)
    _arm.finish = _arm.to_local(predicted)
    _arm.charge_seconds = anticipation_seconds
    _arm.strike_seconds = reach_seconds
    _arm.geometry_locked = false
func _catch() -> void:
    state = State.CAUGHT
    elapsed = 0
    _restore_motor = motor.enabled
    _restore_visual = visual.visible
    motor.enabled = false
    fish.velocity = Vector2.ZERO
    visual.hide()
    _caught_art = Sprite2D.new()
    _caught_art.texture = CAUGHT_ART
    _caught_art.position = Vector2(8,7)
    _caught_art.flip_h = fish.get_node("Visual/Sprite").flip_h
    _caught_art.z_index = 1
    fish.add_child(_caught_art)
func _on_blink(_from: Vector2, _destination: Vector2) -> void:
    _since_blink = 0
    if state in [State.WARNING,State.REACHING,State.CAUGHT]: _finish()
func _finish() -> void:
    if state==State.CAUGHT:
        motor.enabled = _restore_motor and not stage.level.dead
        visual.visible = _restore_visual
    if is_instance_valid(_caught_art):
        _caught_art.queue_free()
        _caught_art = null
    for arm in _warning_arms:
        if is_instance_valid(arm): arm.queue_free()
    _warning_arms.clear()
    _arm = null
    state = State.FINISHED
func reset() -> void:
    _finish()
    state = State.WAITING
    elapsed = 0
    _since_blink = 100
