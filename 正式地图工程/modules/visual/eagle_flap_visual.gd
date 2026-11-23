extends Node2D
## 同一张作者原画的 24 姿态网格拍翅；头、表情与身体不重绘。
const ART=preload("res://assets/art/sky/formal/eagle.png")
const FRAME_COUNT=24
const COLUMNS=64
const ROWS=44
const DRAW_SIZE=Vector2(1595,1061)
@export var cycle_seconds: float=1.0
@export var downstroke_radians: float=.72
@export var upstroke_radians: float=.24
var mesh: Polygon2D
var frame_index: int=0
var _clock:=0.0
var _uv:=PackedVector2Array()
var _rest:=PackedVector2Array()
func _ready() -> void:
    mesh=Polygon2D.new()
    mesh.texture=ART
    mesh.use_parent_material=true
    add_child(mesh)
    for y in ROWS+1:
        for x in COLUMNS+1:
            var uv:=Vector2(float(x)/COLUMNS,float(y)/ROWS)*DRAW_SIZE
            _uv.append(uv)
            _rest.append(uv-DRAW_SIZE*.5)
    var wings: Array[PackedInt32Array]=[]
    var body: Array[PackedInt32Array]=[]
    for y in ROWS:
        for x in COLUMNS:
            var a:=y*(COLUMNS+1)+x
            var center_x: float=(x+.5)*DRAW_SIZE.x/COLUMNS
            var faces: Array[PackedInt32Array]=[PackedInt32Array([a,a+1,a+COLUMNS+2]),PackedInt32Array([a,a+COLUMNS+2,a+COLUMNS+1])]
            if center_x<610 or center_x>980: wings.append_array(faces)
            else: body.append_array(faces)
    wings.append_array(body)
    mesh.uv=_uv
    mesh.polygons=wings
    sample_frame(0)
func _process(delta: float) -> void:
    if not is_visible_in_tree(): return
    _clock=fmod(_clock+delta,cycle_seconds)
    var index:=int(floor(_clock/cycle_seconds*FRAME_COUNT))
    if index!=frame_index: sample_frame(index)
func vertices_for_frame(index: int) -> PackedVector2Array:
    var phase:=float(posmod(index,FRAME_COUNT))/FRAME_COUNT
    var wave:=cos(TAU*phase)
    var angle:=lerpf(-downstroke_radians,upstroke_radians,(wave+1)*.5)
    var bob: float=-8*sin(TAU*phase)
    var vertices:=PackedVector2Array()
    vertices.resize(_rest.size())
    for i in _uv.size():
        var p:=_uv[i]
        var right: bool=p.x>DRAW_SIZE.x*.5
        var root:=Vector2(980,465) if right else Vector2(610,465)
        # Tail and feet remain attached to the body as the wing silhouette tapers in.
        var taper:=smoothstep(780,940,p.y)
        var edge:=lerpf(980,1140,taper) if right else lerpf(610,450,taper)
        var weight:=smoothstep(edge,edge+145,p.x) if right else 1.0-smoothstep(edge-145,edge,p.x)
        var outer:=clampf(absf(p.x-root.x)/650,0,1)
        var lag:=.09*outer
        var feather_angle:=angle+.11*outer*(cos(TAU*(phase-lag))-wave)
        var turn: float=-feather_angle if right else feather_angle
        var v:=p-root
        # Front-facing stroke: rotate the span upward/downward with modest foreshortening.
        var moved:=Vector2(v.x*cos(turn),v.y*cos(turn)+v.x*sin(turn))+root
        var result:=p.lerp(moved,weight)
        vertices[i]=result-DRAW_SIZE*.5+Vector2(0,bob)
    return vertices
func sample_frame(index: int) -> void:
    frame_index=posmod(index,FRAME_COUNT)
    mesh.polygon=vertices_for_frame(frame_index)
func reset() -> void:
    _clock=0
    sample_frame(0)
