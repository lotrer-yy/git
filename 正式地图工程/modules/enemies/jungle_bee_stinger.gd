extends "res://modules/enemies/enemy_fork.gd"
## 复用小恶魔投射物的抛物线发射，命中改为推开松鼠。
const ART = preload("res://assets/art/jungle/formal/bee_stinger.png")
func _ready() -> void:
    add_to_group("bee_stingers")
    var art:=Sprite2D.new()
    art.texture=ART
    art.scale=Vector2.ONE*.6
    add_child(art)
func _physics_process(delta: float) -> void:
    if not is_instance_valid(encounter) or not encounter.is_active():
        hide()
        queue_free()
        return
    _age+=delta
    if _age>lifetime:
        queue_free()
        return
    var previous: Vector2 = global_position
    var next: Vector2 = previous+velocity*delta+Vector2(0,gravity*delta*delta*.5)
    velocity.y+=gravity*delta
    var center: Vector2 = encounter.body.global_position+Vector2(0,-50)
    var closest: Vector2 = Geometry2D.get_closest_point_to_segment(center,previous,next)
    var hits_player: bool = closest.distance_to(center)<55 and encounter.is_on_screen(closest)
    var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(previous,next,32))
    if not hit.is_empty() and (not hits_player or previous.distance_squared_to(hit.position)<previous.distance_squared_to(closest)):
        hide()
        queue_free()
        return
    if hits_player:
        encounter.body.get_node("Movement").launch_with_momentum(Vector2(signf(velocity.x)*300,150))
        encounter.body.get_node("Visual").play_selection_pulse()
        hide()
        queue_free()
        return
    global_position=next
    rotation=velocity.angle()+PI*.5
