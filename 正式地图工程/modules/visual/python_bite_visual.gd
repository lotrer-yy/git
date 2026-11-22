extends Node2D
## 8 个真正张嘴/咬合姿势，注册到同一颈根；连续缩放旋转、短交叉淡化补足帧间运动。
signal bite_started
signal bite_finished
const SHEET = preload("res://assets/art/jungle/python/bite-sheet-v2.png")
const TONGUE = preload("res://modules/visual/python_tongue.gd")
const POSES = [0,1,2,3,4,5,6,7,0]
const DURATIONS = [.08,.17,.12,.14,.065,.11,.14,.16,.15]
@export var playback_speed: float = 1.0
var playing: bool = false
var elapsed: float = 0
var total_duration: float = 0
var layers: Array[Sprite2D] = []
var frames: Array[AtlasTexture] = []
var bases: Array[Vector2] = []
var _struck: bool = false
var _returning: bool = false
var _initial_tongue: float = 1
func _ready() -> void:
    var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/jungle/python/bite_frames.json"))
    for item in data.frames:
        var texture := AtlasTexture.new()
        texture.atlas = SHEET
        texture.region = Rect2(item.region[0],item.region[1],item.region[2],item.region[3])
        texture.filter_clip = true
        frames.append(texture)
        bases.append(Vector2(item.base[0],item.base[1]))
    for i in 2:
        var layer := Sprite2D.new()
        layer.centered = false
        add_child(layer)
        var tongue := Node2D.new()
        tongue.set_script(TONGUE)
        tongue.name = "Tongue"
        tongue.z_index=2
        layer.add_child(tongue)
        layers.append(layer)
    for duration in DURATIONS: total_duration+=duration
    sample(-1)
func play_bite() -> void:
    _initial_tongue=layers[0].get_node("Tongue").amount
    _returning=false
    elapsed=0
    _struck=false
    playing=true
    sample(0)
func _process(delta: float) -> void:
    if not playing and not _returning: return
    elapsed+=delta*playback_speed
    sample(elapsed)
    if playing and not _struck and elapsed>=.51:
        _struck=true
        bite_started.emit()
    if playing and elapsed>=total_duration:
        playing=false
        _returning=true
        bite_finished.emit()
    if elapsed>=total_duration+.45: _returning=false
func sample(time: float) -> void:
    if frames.is_empty(): return
    var index: int = 0
    var t: float = maxf(0,time)
    while index<DURATIONS.size()-1 and t>=DURATIONS[index]:
        t-=DURATIONS[index]
        index+=1
    var blend_window: float = .012 if index in [3,4,5,6] else .025
    var blend: float = smoothstep(maxf(0,DURATIONS[index]-blend_window),DURATIONS[index],t) if index<POSES.size()-1 else 0
    for layer_index in 2:
        var frame: int = POSES[mini(index+layer_index,POSES.size()-1)]
        layers[layer_index].texture=frames[frame]
        layers[layer_index].position=-bases[frame]
        layers[layer_index].get_node("Tongue").configure(frame,time,total_duration,_initial_tongue)
        layers[layer_index].modulate.a=(1-blend) if layer_index==0 else blend
    var charge: float = smoothstep(.08,.44,time)*(1-smoothstep(.46,.535,time))
    var strike: float = smoothstep(.49,.55,time)*(1-smoothstep(.63,.82,time))
    var spring: float = sin(maxf(0,time-.62)*29)*exp(-maxf(0,time-.62)*8) if time>.62 else 0
    # 颈根不平移，冲刺由原图伸颈和弹性拉伸完成。
    scale=Vector2(1-charge*.06+strike*.10+spring*.025,1+charge*.025-strike*.06-spring*.025)
    rotation=-charge*.065+strike*.045+spring*.018

    if time>=total_duration:
        scale=Vector2.ONE
        rotation=0
