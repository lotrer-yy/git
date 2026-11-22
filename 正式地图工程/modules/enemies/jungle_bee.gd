extends CharacterBody2D
## 复用地狱小恶魔飞行模块；只用作者蜜蜂原图，蓄力后锁定方向冲刺蜇击。
signal stung
const FLIGHT = preload("res://modules/enemies/flying_motion.gd")
const ART = preload("res://assets/art/jungle/formal/bee.png")
enum Mode { EMERGING, FLYING, WINDUP, DARTING, RECOVERING }
@export var attack_interval: float = 3.5
@export var warning_seconds: float = .55
var encounter: Node
var mode: Mode = Mode.EMERGING
var elapsed: float = 0
var lifetime: float = 0
var cooldown: float = 1.5
var flight: Node
var visual: Sprite2D
var _aim := Vector2.ZERO
var _dart_velocity := Vector2.ZERO
var _hit: bool = false
func _ready() -> void:
    collision_layer=0
    collision_mask=32
    motion_mode=MOTION_MODE_FLOATING
    var shape:=CollisionShape2D.new()
    shape.shape=CircleShape2D.new()
    shape.shape.radius=45
    add_child(shape)
    visual=Sprite2D.new()
    visual.texture=ART
    visual.scale=Vector2.ONE*.52
    add_child(visual)
    flight=Node.new()
    flight.set_script(FLIGHT)
    add_child(flight)
    flight.max_speed=340
    flight.acceleration=650
    flight.orbit_radius=Vector2(290,95)
    flight.setup(int(get_instance_id()),-1 if get_instance_id()%2==0 else 1)
    add_to_group("jungle_bees")
    velocity=Vector2(0,-300)
    _pose(0)
func is_defeated() -> bool:
    return is_queued_for_deletion()
func _physics_process(delta: float) -> void:
    if not is_instance_valid(encounter) or not encounter.is_active():
        queue_free()
        return
    elapsed+=delta
    lifetime+=delta
    var target: Vector2 = encounter.body.global_position+Vector2(0,-50)
    if global_position.distance_to(target)>1900:
        queue_free()
        return
    if mode==Mode.EMERGING:
        velocity=velocity.move_toward(Vector2.ZERO,delta*500)
        move_and_slide()
        if elapsed>=.45: _set_mode(Mode.FLYING)
    elif mode==Mode.FLYING:
        flight.tick(self,target,encounter.flight_bounds(),delta,encounter.enemies())
        cooldown-=delta
        if cooldown<=0 and global_position.distance_to(target)<650 and encounter.is_on_screen(global_position):
            _aim=target
            _set_mode(Mode.WINDUP)
    elif mode==Mode.WINDUP:
        velocity=velocity.move_toward(Vector2.ZERO,delta*1100)
        move_and_slide()
        if not encounter.is_on_screen(global_position):
            cooldown=.6
            _set_mode(Mode.FLYING)
        elif elapsed>=warning_seconds:
            _dart_velocity=(_aim-global_position).normalized()*950
            _hit=false
            _set_mode(Mode.DARTING)
    elif mode==Mode.DARTING:
        var before: Vector2 = global_position
        velocity=_dart_velocity
        move_and_slide()
        var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target,before,global_position)
        if not _hit and closest.distance_to(target)<70 and encounter.is_on_screen(global_position):
            _hit=true
            var direction: Vector2 = (target-before).normalized()
            encounter.body.get_node("Movement").launch_with_momentum(Vector2(direction.x*350,180))
            encounter.body.get_node("Visual").play_selection_pulse()
            stung.emit()
            _set_mode(Mode.RECOVERING)
        elif elapsed>=.32: _set_mode(Mode.RECOVERING)
    elif mode==Mode.RECOVERING:
        velocity=velocity.move_toward(Vector2.ZERO,delta*1400)
        move_and_slide()
        if elapsed>=.65:
            cooldown=attack_interval
            _set_mode(Mode.FLYING)
    _pose(delta)
func _set_mode(value: Mode) -> void:
    mode=value
    elapsed=0
func _pose(delta: float) -> void:
    # 原图朝左；以小恶魔同样的倾身表现运动，翅膀以整图短促弹性轻颤表现。
    visual.flip_h=velocity.x>15 if absf(velocity.x)>15 else visual.flip_h
    var pop: float = 1.0
    if lifetime<.45:
        var u: float = clampf(lifetime/.45,0,1)
        pop=1+2.70158*pow(u-1,3)+1.70158*pow(u-1,2)
    var stretch: float = 1+sin(lifetime*42)*.025
    if mode==Mode.WINDUP: stretch=1+sin(elapsed*40)*.07
    elif mode==Mode.DARTING: stretch=.84
    visual.scale=Vector2.ONE*.52*maxf(.05,pop)*Vector2(1/stretch,stretch)
    var lean: float = clampf(velocity.x/950,-1,1)*.25
    visual.rotation=lerp_angle(visual.rotation,lean,1-exp(-delta*12))
