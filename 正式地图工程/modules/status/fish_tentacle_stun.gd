extends Node
## 侧墙触手只造成短暂眩晕；原鱼图仅在眼睛区域绘制螺旋。
signal stunned
signal recovered
@export var stun_seconds: float=.55
@export var dizzy_seconds: float=1.0
@export var protection_seconds: float=1.8
var stun_remaining: float=0
var dizzy_remaining: float=0
var protection_remaining: float=0
var _locked: bool=false
var _elapsed: float=0
var _input_enabled: bool=false
var _motor_enabled: bool=false
var _teleport_enabled: bool=false
var _rest_material: Material
var _dizzy_material: ShaderMaterial
@onready var body: CharacterBody2D=get_parent()
@onready var stage: Node=body.get_parent()
@onready var reader: Node=body.get_node("Input")
@onready var motor: Node=body.get_node("Movement")
@onready var teleport: Node=body.get_node("Teleport")
@onready var visual: Node2D=body.get_node("Visual")
@onready var art: Sprite2D=visual.get_node("Sprite")
func _ready() -> void:
    process_physics_priority=-15
    process_priority=10
    _rest_material=art.material
    _dizzy_material=ShaderMaterial.new()
    _dizzy_material.shader=preload("res://shaders/fish_dizzy_eye.gdshader")
func _can_play() -> bool:
    return stage.active and stage.host.claimed and stage.level.player==body and not stage.level.dead and not stage.level.exit_in_progress and stage.get_node("ShoreExit").state==stage.get_node("ShoreExit").State.SWIMMING
func is_protected() -> bool:
    return protection_remaining>0
func apply(direction: Vector2=Vector2.RIGHT) -> bool:
    if not _can_play() or is_protected() or teleport.is_invulnerable(): return false
    stun_remaining=stun_seconds
    dizzy_remaining=dizzy_seconds
    protection_remaining=protection_seconds
    _elapsed=0
    _locked=true
    _input_enabled=reader.enabled
    _motor_enabled=motor.enabled
    _teleport_enabled=teleport.enabled
    reader.enabled=false
    reader.clear()
    motor.enabled=false
    teleport.enabled=false
    body.velocity=Vector2(signf(direction.x)*130,60)
    art.material=_dizzy_material
    visual.play_selection_pulse()
    stunned.emit()
    return true
func _physics_process(delta: float) -> void:
    if not _can_play():
        if protection_remaining>0: reset(false)
        return
    protection_remaining=maxf(0,protection_remaining-delta)
    dizzy_remaining=maxf(0,dizzy_remaining-delta)
    if _locked:
        stun_remaining=maxf(0,stun_remaining-delta)
        body.velocity=body.velocity.move_toward(Vector2(0,70),300*delta)
        body.move_and_slide()
        if stun_remaining<=0:
            _restore_controls()
            recovered.emit()
    if dizzy_remaining<=0 and art.material==_dizzy_material: art.material=_rest_material
func _process(delta: float) -> void:
    if dizzy_remaining<=0: return
    _elapsed+=delta
    _dizzy_material.set_shader_parameter("phase",_elapsed*5)
    visual.rotation=sin(_elapsed*17)*.10
func _restore_controls() -> void:
    if _locked and _can_play():
        reader.enabled=_input_enabled
        motor.enabled=_motor_enabled
        teleport.enabled=_teleport_enabled
    _locked=false
func reset(restore_controls: bool=true) -> void:
    if restore_controls: _restore_controls()
    _locked=false
    stun_remaining=0
    dizzy_remaining=0
    protection_remaining=0
    art.material=_rest_material
    visual.rotation=0
