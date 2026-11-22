extends Node2D
## 碰到原画松果即拾取并自动投向蛇头；有转向的实际飞行轨迹与扫掠命中。
signal collected
signal struck_snake
const ART = preload("res://assets/art/jungle/python/pinecone.png")
enum State { HANGING, CARRIED, FLYING, SPENT }
@export var pickup_radius: float = 100.0
@export var projectile_speed: float = 1100.0
var state: State = State.HANGING
var elapsed: float = 0
var velocity := Vector2.ZERO
var sprite: Sprite2D
var _origin := Vector2.ZERO
@onready var body: CharacterBody2D = get_node("../../Squirrel")
@onready var enemy: Node2D = get_node("../../PythonEncounter")
func _ready() -> void:
    z_index=12
    _origin=position
    sprite=Sprite2D.new()
    sprite.texture=ART
    sprite.scale=Vector2.ONE*1.25
    add_child(sprite)
func _physics_process(delta: float) -> void:
    if not enemy.can_play():
        if state in [State.CARRIED,State.FLYING]:
            state=State.SPENT
            hide()
        return
    elapsed+=delta
    if state==State.HANGING:
        position=_origin+Vector2(0,sin(elapsed*2)*7)
        sprite.rotation=sin(elapsed*1.5)*.08
        if global_position.distance_to(body.global_position+Vector2(0,-50))<=pickup_radius:
            state=State.CARRIED
            elapsed=0
            collected.emit()
    elif state==State.CARRIED:
        global_position=body.global_position+Vector2(55,-90)
        sprite.scale=Vector2.ONE*(1.25+sin(minf(elapsed,.15)/.15*PI)*.25)
        if elapsed>=.12 and enemy.is_targetable():
            state=State.FLYING
            elapsed=0
            velocity=(enemy.target_position()-global_position).normalized()*projectile_speed*.7
    elif state==State.FLYING:
        if not enemy.is_targetable() or elapsed>4:
            state=State.SPENT
            hide()
            return
        var target: Vector2 = enemy.target_position()
        var desired: Vector2 = (target-global_position).normalized()*projectile_speed
        velocity=velocity.lerp(desired,1-exp(-delta*9))
        var before: Vector2 = global_position
        var after: Vector2 = before+velocity*delta
        var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target,before,after)
        global_position=after
        sprite.rotation+=delta*12
        sprite.scale=Vector2.ONE*1.1
        if closest.distance_to(target)<90:
            if enemy.hit_by_pinecone(closest,velocity): struck_snake.emit()
            state=State.SPENT
            hide()
func reset() -> void:
    state=State.HANGING
    elapsed=0
    velocity=Vector2.ZERO
    position=_origin
    show()
    sprite.scale=Vector2.ONE*1.25
    sprite.rotation=0
