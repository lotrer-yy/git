extends FishShoreExit
## 旧出水运动加正式岸上原画；挣扎、缺氧变红及叉眼死亡依次交接。
const STRUGGLE = preload("res://modules/visual/stranded_fish_visual.gd")
var struggle = STRUGGLE.new()
@onready var stage: Node2D = get_parent()
func _ready() -> void:
    super._ready()
    struggle.configure(_visual,_sprite)
    landed_on_shore.connect(func(): _sprite.position = Vector2(8,-11.5))
func _physics_process(delta: float) -> void:
    if not stage.active or stage.level.dead or stage.level.player!=_fish: return
    if stage.get_node("SurfaceGrab").blocks_exit(): return
    super._physics_process(delta)
    if state==State.STRANDED: struggle.sample(elapsed,stranding_duration)
    _fish.get_node("Teleport").enabled = state==State.SWIMMING
func release_soul() -> void:
    if state==State.DEAD: return
    state = State.DEAD
    _sprite.texture = dead_texture
    struggle.settle_dead()
    _fish.velocity = Vector2.ZERO
    _motor.enabled = false
    _reader.enabled = false
    _reader.clear()
    died_on_shore.emit()
func play_death() -> void:
    # 冻结关卡后仍展示叉眼尸体，再交给已有死亡界面。
    await get_tree().create_timer(death_hold_duration,true,false,true).timeout
func reset() -> void:
    super.reset()
    if struggle.visual!=null: struggle.reset()

func start_on_shore(world_x: float) -> void:
    # 快捷入口直接进入正常落岸后的状态，坐标取编辑器中的原岸线碰撞。
    reset()
    var bank: CollisionShape2D = stage.get_node("OriginalShoreBank/Collision")
    var top: Vector2 = bank.to_global(Vector2(0,-bank.shape.size.y*.5))
    var collision: CollisionShape2D = _fish.get_node("Collision")
    var bounds: Rect2 = collision.shape.get_rect()
    var bottom: float = -INF
    for point in [bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]:
        bottom = maxf(bottom,(collision.transform*point).y)
    _fish.global_position = Vector2(world_x,top.y-bottom)
    _fish.velocity = Vector2.ZERO
    _fish.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
    _motor.enabled = false
    _reader.clear()
    _visual.set_process(false)
    state = State.STRANDED
    elapsed = 0
    _sprite.texture = stranded_texture
    _sprite.position = Vector2(8,-11.5)
    _visual.rotation = 0
    _fish.get_node("Teleport").enabled = false
    struggle.sample(0,stranding_duration)
    _fish.reset_physics_interpolation()
    landed_on_shore.emit()
