extends Node
## 左右弧线航点 + 限加速度转向；先避墙，再处理同伴分离和接近航点。
@export var max_speed: float = 245.0
@export var acceleration: float = 480.0
@export var orbit_radius: Vector2 = Vector2(350,95)
@export var sweep_frequency: float = 0.88
@export var entry_speed: float = 480.0
@export var entry_acceleration: float = 1050.0
var _phase: float = 0.0
var _goal: Vector2
var _wait: float = 0.0
var _rng := RandomNumberGenerator.new()

func setup(seed_value: int, side: float = -1.0) -> void:
    _rng.seed = seed_value
    _wait = 0.0
    _phase = -PI*.5 if side<0 else PI*.5

func enter_tick(body: CharacterBody2D, point: Vector2, delta: float) -> bool:
    var direction:=point-body.global_position
    var desired:=direction.normalized()*entry_speed*clampf(direction.length()/110.0,.35,1.0)
    body.velocity=body.velocity.move_toward(desired,entry_acceleration*delta)
    body.global_position+=body.velocity*delta
    return direction.length()<20.0

func tick(body: CharacterBody2D, target: Vector2, bounds: Rect2, delta: float, neighbors: Array) -> void:
    _phase+=delta*sweep_frequency
    _goal=target+Vector2(sin(_phase)*orbit_radius.x,-220.0+sin(_phase*2.0+.4)*orbit_radius.y)
    _goal=_goal.clamp(bounds.position+Vector2(90,90),bounds.end-Vector2(90,90))
    var avoid := Vector2.ZERO
    var direction := body.velocity.normalized() if body.velocity.length()>20 else (_goal-body.global_position).normalized()
    for turn in [-0.65,0.0,0.65]:
        var ray := direction.rotated(turn)
        var query := PhysicsRayQueryParameters2D.create(body.global_position,body.global_position+ray*140.0,9,[body.get_rid()])
        var hit := body.get_world_2d().direct_space_state.intersect_ray(query)
        if not hit.is_empty():
            var normal: Vector2 = hit.normal
            avoid += normal*acceleration*1.8 + Vector2(-normal.y,normal.x)*signf(sin(float(body.get_instance_id())))*80.0
    var separation := Vector2.ZERO
    for other in neighbors:
        if other==body or not is_instance_valid(other) or other.is_defeated():continue
        var offset:Vector2=body.global_position-other.global_position
        if offset.length_squared()<200.0*200.0:separation+=offset.normalized()*acceleration*(1.0-offset.length()/200.0)
    var offset := _goal-body.global_position
    var desired := offset.normalized()*max_speed*minf(offset.length()/130.0,1.0)
    var personal := body.global_position-target
    if personal.length()<160.0:separation+=personal.normalized()*acceleration
    var budget := acceleration
    var force := avoid.limit_length(budget)
    budget-=force.length()
    var apart:=separation.limit_length(budget)
    force+=apart
    budget-=apart.length()
    force+=(desired-body.velocity).limit_length(budget)
    body.velocity=(body.velocity+force*delta).limit_length(max_speed)
    body.move_and_slide()
