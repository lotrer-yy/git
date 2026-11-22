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
