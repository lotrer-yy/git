extends Node2D
## 同一张作者原图连续收伞、舒展与触须滞后，不拆换帧图。
const ART = preload("res://assets/art/ocean/jellyfish/boss.png")
const COLUMNS = 36
const ROWS = 56
@export var pulse_period: float = 1.65
@export var bell_squeeze: float = .075
@export var tentacle_sway_pixels: float = 30.0
@export var gaze_max_pixels := Vector2(40,28)
@export var gaze_response: float = 12.0
var left_gaze := Vector2.ZERO
var right_gaze := Vector2.ZERO
var mesh: Polygon2D
var _rest := PackedVector2Array()
var _uv := PackedVector2Array()
var _eye_weights := PackedFloat32Array()
var _left_weights := PackedFloat32Array()
var _right_weights := PackedFloat32Array()

func _ready() -> void:
    mesh = Polygon2D.new()
    mesh.texture = ART
    add_child(mesh)
    var size := ART.get_size()
    for y in ROWS+1:
        for x in COLUMNS+1:
            var uv := Vector2(float(x)/COLUMNS,float(y)/ROWS)*size
            _uv.append(uv)
            _rest.append(uv-Vector2(size.x*.5,size.y*.19))
            # 原图两只眼睛的局部区域；眉毛、嘴和伞盖边缘不跟着平移。
            var vertical := smoothstep(480,530,uv.y)*(1-smoothstep(865,930,uv.y))
            var left := smoothstep(410,505,uv.x)*(1-smoothstep(658,750,uv.x))
            var right := smoothstep(1045,1141,uv.x)*(1-smoothstep(1296,1390,uv.x))
            _eye_weights.append(vertical*maxf(left,right))
            _left_weights.append(vertical*left)
            _right_weights.append(vertical*right)
    var faces: Array[PackedInt32Array] = []
    for y in ROWS:
        for x in COLUMNS:
            var a := y*(COLUMNS+1)+x
            faces.append(PackedInt32Array([a,a+1,a+COLUMNS+2]))
            faces.append(PackedInt32Array([a,a+COLUMNS+2,a+COLUMNS+1]))
    mesh.polygon = _rest
    mesh.uv = _uv
    mesh.polygons = faces
    sample(0)

func thrust_at(seconds: float) -> float:
    # 伞盖收紧后舒展时向上推进，与体态使用同一节拍。
    return pow(maxf(0,sin(TAU*(seconds/pulse_period-.25))),2)

func update_gaze(world_point: Vector2, delta: float) -> void:
    var point := to_local(world_point)
    var pivot := Vector2(ART.get_width()*.5,ART.get_height()*.19)
    var left_delta := point-(Vector2(581,695)-pivot)
    var right_delta := point-(Vector2(1218,699)-pivot)
    var response := 1-exp(-gaze_response*delta)
    left_gaze = left_gaze.lerp(Vector2(left_delta.x/420,left_delta.y/380).limit_length(1),response)
    right_gaze = right_gaze.lerp(Vector2(right_delta.x/420,right_delta.y/380).limit_length(1),response)

func sample(seconds: float) -> void:
    if mesh == null: return
    var phase := seconds/pulse_period
    var contract := maxf(0,sin(TAU*phase))
    var release := maxf(0,sin(TAU*(phase-.3)))
    var vertices := PackedVector2Array()
    vertices.resize(_rest.size())
    for i in _rest.size():
        var point := _rest[i]
        var v := _uv[i].y/ART.get_height()
        var tail := smoothstep(.39,1,v)
        var width := 1-bell_squeeze*contract*(1-tail)+bell_squeeze*.55*release*(1-tail)
        point.x *= width
        point.y *= 1+.05*contract*(1-tail)-.035*release*(1-tail)
        # 根部固定衔接，摆幅沿触须逐渐增加，末端晚半拍跟进。
        point.x += sin(TAU*phase-tail*4+_uv[i].x/ART.get_width()*2)*tentacle_sway_pixels*tail*tail
        point.y += sin(TAU*phase-tail*3)*16*tail*tail
        point += (left_gaze*_left_weights[i]+right_gaze*_right_weights[i])*gaze_max_pixels
        vertices[i] = point
    mesh.polygon = vertices
