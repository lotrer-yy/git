extends Node
## 一整串 WASD+左Shift 共用现实时间截止；只认新按键，慢动作/退出均精确复原。
signal completed(success: bool)
const PROMPT = preload("res://modules/visual/python_sequence_prompt.gd")
const SEQUENCE = [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SHIFT]
@export var duration: float = 1.5
@export var time_scale_ratio: float = .12
var active: bool = false
var index: int = 0
var remaining: float = 0
var saved_time_scale: float = 1
var prompt: CanvasLayer
var held: Dictionary = {}
func _ready() -> void:
    prompt=PROMPT.new()
    add_child(prompt)
func begin() -> bool:
    if active: return false
    saved_time_scale=Engine.time_scale
    active=true
    index=0
    remaining=duration
    held.clear()
    for key in SEQUENCE:
        if Input.is_physical_key_pressed(key): held[key]=true
    Engine.time_scale=saved_time_scale*time_scale_ratio
    prompt.begin()
    prompt.sample(index,remaining,duration,0)
    return true
func _process(delta: float) -> void:
    if not active: return
    advance_real(delta/maxf(Engine.time_scale,.001))
func advance_real(delta: float) -> void:
    if not active: return
    remaining=maxf(0,remaining-delta)
    prompt.sample(index,remaining,duration,delta)
    if remaining<=0: _finish(false)
func _input(event: InputEvent) -> void:
    if not active or not event is InputEventKey: return
    var code: int = event.physical_keycode if event.physical_keycode!=0 else event.keycode
    # 全局试玩入口仍可在子弹时间中重载；离开树时取消并还原时间。
    if code in [KEY_1,KEY_2,KEY_3,KEY_4]: return
    if code not in SEQUENCE and code!=KEY_SPACE: return
    get_viewport().set_input_as_handled()
    if code==KEY_SHIFT and event.location==KEY_LOCATION_RIGHT: return
    if not event.pressed:
        held.erase(code)
        return
    if event.echo or held.has(code): return
    held[code]=true
    if code!=SEQUENCE[index]:
        prompt.flash_wrong()
        return
    index+=1
    prompt.sample(index,remaining,duration,0)
    if index==SEQUENCE.size(): _finish(true)
func _finish(success: bool) -> void:
    if not active: return
    active=false
    Engine.time_scale=saved_time_scale
    prompt.hide()
    completed.emit(success)
func cancel() -> void:
    if active: Engine.time_scale=saved_time_scale
    active=false
    held.clear()
    if is_instance_valid(prompt): prompt.hide()
func _exit_tree() -> void:
    cancel()
