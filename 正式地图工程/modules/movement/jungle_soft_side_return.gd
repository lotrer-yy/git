extends Node
## 地图边缘外为柔和缓冲区，不碰撞、不瞬移；飞行与挂藤都顺势滑回。
@export var left_edge: float = -220.0
@export var right_edge: float = 2140.0
@export var stiffness: float = 24.0
@export var outward_damping: float = 5.0
@export var max_acceleration: float = 16000.0
@onready var layout: Node2D = get_parent()
@onready var body: CharacterBody2D = get_node("../Squirrel")
func _ready() -> void:
    process_physics_priority = -4
func _physics_process(delta: float) -> void:
    if not body.get_node("Host").claimed or body.transferring: return
    var x: float = layout.to_local(body.global_position).x
    var depth: float = left_edge-x if x<left_edge else (right_edge-x if x>right_edge else 0.0)
    if is_zero_approx(depth): return
    var inward: float = signf(depth)
    var speed: float = body.velocity.dot(layout.global_transform.x.normalized())
    # 在边缘处力度为零，越出去回拉越明显。顺着回来的方向不施加刹车。
    var weight: float = smoothstep(0,180,absf(depth))
    var acceleration: float = depth*stiffness
    if speed*inward<0: acceleration-=speed*outward_damping*weight
    var impulse: Vector2 = layout.global_transform.x.normalized()*clampf(acceleration,-max_acceleration,max_acceleration)*delta
    var rope: SwingVine = body.get_node("VineClimber").vine
    if is_instance_valid(rope) and rope.rider==body:
        var local_impulse: Vector2 = rope.global_transform.basis_xform_inv(impulse)
        rope.rope.add_velocity(rope.grip_length,local_impulse)
    else:
        body.velocity+=impulse
