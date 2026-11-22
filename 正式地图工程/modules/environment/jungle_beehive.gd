extends Sprite2D
## 松鼠靠近后抖动预警，再脱离主藤蔓下落；每轮只触发一次。
signal loosened
signal dropped
enum State { HANGING, SHAKING, FALLING, GONE }
@export_enum("冲刺蜜蜂", "射刺蜜蜂") var bee_variant: int = 0
@export var trigger_radius: float = 430.0
@export var warning_seconds: float = 0.9
@export var fall_gravity: float = 1450.0
var state: State = State.HANGING
var elapsed: float = 0.0
var velocity := Vector2.ZERO
var _origin := Vector2.ZERO
var _rest_rotation: float = 0.0
var _rest_scale := Vector2.ONE
@onready var body: CharacterBody2D = get_node("../../Squirrel")
@onready var stage: Node = get_node("../../..")
func _ready() -> void:
    _origin=position
    _rest_rotation=rotation
    _rest_scale=scale
func _physics_process(delta: float) -> void:
    if not stage.has_node("ShoreExit") or not stage.active or stage.level.dead: return
    if state==State.HANGING:
        if stage.level.player!=body or not body.get_node("Host").claimed: return
        var center: Vector2 = to_global(Vector2(0,texture.get_height()*.5))
        if center.distance_to(body.global_position+Vector2(0,-50))<=trigger_radius:
            state=State.SHAKING
            elapsed=0
            loosened.emit()
    elif state==State.SHAKING:
        elapsed+=delta
        var u: float = clampf(elapsed/warning_seconds,0,1)
        var phase: float = elapsed*30+u*u*20
        rotation=_rest_rotation+sin(phase)*lerpf(.025,.14,u)
        position=_origin+Vector2(sin(phase*1.2)*lerpf(2,10,u),sin(phase*.7)*3)
        if elapsed>=warning_seconds:
            state=State.FALLING
            elapsed=0
            velocity=Vector2(sin(phase)*65,160)
            _drop_pop(0)
            dropped.emit()
    elif state==State.FALLING:
        elapsed+=delta
        _drop_pop(elapsed)
        velocity.y+=fall_gravity*delta
        position+=velocity*delta
        rotation+=delta*.65
        if elapsed>=4:
            state=State.GONE
            hide()
func _drop_pop(time: float) -> void:
    # 脱落时向下拉长，随后横向回弹，短促衰减并准确恢复原尺寸。
    if time>=.4:
        scale=_rest_scale
        return
    var stretch: float = 1+.24*cos(time*27)*exp(-time*10)
    scale=_rest_scale*Vector2(1.0/stretch,stretch)
func reset() -> void:
    state=State.HANGING
    elapsed=0
    velocity=Vector2.ZERO
    position=_origin
    rotation=_rest_rotation
    show()
