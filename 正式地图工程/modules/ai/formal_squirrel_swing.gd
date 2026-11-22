extends CharacterBody2D
## 松鼠以摆动速度借力，实际推动物理绳；不直接动画平移藤蔓。
@export var vine_path: NodePath
@export var grip_fraction: float = .64
@export var swing_width: float = 215.0
@export var pumping_strength: float = .85
var vine: SwingVine
var active: bool = false
var selected: bool = false
var transferring: bool = false
var _direction: float = 1.0
@onready var pose: Node2D = $Visual
func _ready() -> void:
    $Movement.boundary_hit.connect(_on_boundary_hit)
    process_physics_priority = -10
    process_priority = 1
    add_to_group("idle_vine_squirrels")
    vine = get_node(vine_path) as SwingVine
    reset()
func reset() -> void:
    if not is_instance_valid(vine): return
    $VineClimber.reset()
    $Host.reset()
    if vine.rider==self: vine.release()
    _direction = 1.0
    # 从一个小倾角开始，整条绳的各段都保持原长。
    for i in range(1,vine.rope.points.size()):
        var point: Vector2 = Vector2(0,vine.rope.segment_length*i).rotated(.28)
        vine.rope.points[i] = point
        vine.rope.previous[i] = point
    vine.rider_offset = Vector2(60,90)
    global_position = vine.to_global(vine.rope.sample(vine.length*grip_fraction))+vine.rider_offset
    vine.catch(self,Vector2(260,0),global_position)
    vine.grip_length = vine.length*grip_fraction
    vine.pump_axis = 0
    pose.rotation = 0
    set_selected(false)
func set_active(value: bool) -> void:
    active = value
    set_physics_process(value)
    set_process(value)
func set_selected(value: bool) -> void:
    selected = value
    $Visual/Sprite.visible = not value
    $Visual/SelectedSprite.visible = value
func _physics_process(_delta: float) -> void:
    if not active or vine.rider!=self or $Host.claimed or transferring: return
    var grip: Vector2 = vine.rope.sample(vine.grip_length)
    var speed: float = velocity.x
    if absf(speed)>8: _direction = signf(speed)
    # 两侧逐渐收力，在经过最低点时借力；没有固定轨迹或瞬间换向。
    var edge: float = smoothstep(swing_width*.75,swing_width,absf(grip.x))
    vine.pump_axis = lerpf(_direction*pumping_strength,-signf(grip.x)*pumping_strength,edge)
    vine.climb_axis = 0
func _process(delta: float) -> void:
    var attached: SwingVine = $VineClimber.vine if $Host.claimed else vine
    if attached==null or attached.rider!=self: return
    $Visual/Sprite.flip_h = false
    # 手的位置固定在绳上，身体根据摆幅倾斜。
    pose.rotation = lerp_angle(pose.rotation,-attached.angle*.55,1-exp(-8*delta))

func _on_boundary_hit(collision: KinematicCollision2D, incoming: Vector2) -> void:
    $Movement.launch_with_momentum(bounce_from_boundary(collision,incoming))
func bounce_from_boundary(collision: KinematicCollision2D, incoming: Vector2) -> Vector2:
    var normal := collision.get_normal()
    var result := Vector2(normal.x*clampf(absf(incoming.x)*.8,380,1300),incoming.y)
    move_and_collide(normal*5)
    # 事件触发短促横向压扁，再由既有弹簧平滑回弹。
    $Visual._spring_position = Vector2(.7,1.2)
    $Visual._spring_velocity = Vector2(2.5,-1.5)
    return result
