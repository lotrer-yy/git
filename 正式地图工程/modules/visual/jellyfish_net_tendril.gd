extends Node2D
## 原图沿连续脊线伸缩；伤害与阻挡复用同一条实际可见的中心线。
const ART = preload("res://assets/art/ocean/jellyfish/tentacle.png")
const SEGMENTS = 24
@export var thickness: float = 144.0
@export var charge_seconds: float = .6
@export var strike_seconds: float = .18
@export var cap_texture_pixels: float = 64.0
var start := Vector2.ZERO
var finish := Vector2.ZERO
var delay: float = 0.0
var centerline := PackedVector2Array()
var dangerous: bool = false
var mesh: Polygon2D
var sparks: Line2D
var body: StaticBody2D
var _shapes: Array[CollisionShape2D] = []
var geometry_locked: bool = false
var _last_electric_time: float = -INF

func _ready() -> void:
    mesh = Polygon2D.new()
    mesh.texture = ART
    add_child(mesh)
    sparks = Line2D.new()
    sparks.width = 2.6
    sparks.default_color = Color(.65,1,1,.85)
    sparks.antialiased = true
    add_child(sparks)
    body = StaticBody2D.new()
    body.collision_layer = 0
    body.collision_mask = 0
    add_child(body)
    for i in SEGMENTS:
        var collision := CollisionShape2D.new()
        var capsule := CapsuleShape2D.new()
        capsule.radius = thickness*.5
        capsule.height = thickness+1
        collision.shape = capsule
        body.add_child(collision)
        _shapes.append(collision)
    var uv := PackedVector2Array()
    var faces: Array[PackedInt32Array] = []
    for i in SEGMENTS+1:
        uv.append(Vector2(float(i)/SEGMENTS*ART.get_width(),0))
        uv.append(Vector2(float(i)/SEGMENTS*ART.get_width(),ART.get_height()))
        if i<SEGMENTS:
            var a := i*2
            faces.append(PackedInt32Array([a,a+2,a+3]))
            faces.append(PackedInt32Array([a,a+3,a+1]))
    mesh.uv = uv
    mesh.polygons = faces
    sample(0)

func sample(age: float) -> void:
    var t := age-delay
    visible = t>=0
    dangerous = t>=charge_seconds
    var layer := 16 if dangerous else 0
    if body.collision_layer!=layer: body.collision_layer = layer
    if t<0: return
    if geometry_locked:
        _update_electricity(age)
        return
    var axis := (finish-start).normalized()
    var normal := axis.orthogonal()
    var total := start.distance_to(finish)
    var reach := 0.0
    var bend := 0.0
    if t<charge_seconds:
        var emerge := 1-pow(1-clampf(t/.2,0,1),3)
        var windup := clampf((t-.2)/maxf(.01,charge_seconds-.2),0,1)
        reach = 160*emerge-40*sin(windup*PI)
        bend = 40*sin(windup*PI)
    else:
        var u := clampf((t-charge_seconds)/strike_seconds,0,1)
        reach = lerpf(160,total,1-pow(1-u,3))
        bend = -28*sin(u*PI)*exp(-u*2)
    reach = minf(reach,total)
    centerline.clear()
    var vertices := PackedVector2Array()
    var uv := PackedVector2Array()
    var electricity := PackedVector2Array()
    # 类似九宫格：圆头/黑边按粗度保留尺寸，只让中间长条伸缩。
    var cap_length := minf(cap_texture_pixels*thickness/ART.get_height(),reach*.45)
    var cap_ratio := cap_length/maxf(reach,.001)
    for i in SEGMENTS+1:
        var s := float(i)/SEGMENTS
        var point := start+axis*reach*s+normal*bend*sin(s*PI)
        centerline.append(point)
        vertices.append(point-normal*thickness*.5)
        vertices.append(point+normal*thickness*.5)
        var source_x: float
        if cap_ratio>0 and s<cap_ratio:
            source_x = s/cap_ratio*cap_texture_pixels
        elif cap_ratio>0 and s>1-cap_ratio:
            source_x = ART.get_width()-cap_texture_pixels+(s-1+cap_ratio)/cap_ratio*cap_texture_pixels
        else:
            source_x = lerpf(cap_texture_pixels,ART.get_width()-cap_texture_pixels,(s-cap_ratio)/maxf(1-2*cap_ratio,.001))
        uv.append(Vector2(source_x,0))
        uv.append(Vector2(source_x,ART.get_height()))
        electricity.append(point+normal*sin(s*45-age*9)*3.5*sin(s*PI))
    mesh.polygon = vertices
    mesh.uv = uv
    sparks.points = electricity
    sparks.modulate.a = .15 if not dangerous else smoothstep(charge_seconds,charge_seconds+.12,t)
    for i in SEGMENTS:
        var a := centerline[i]
        var b := centerline[i+1]
        _shapes[i].position = (a+b)*.5
        _shapes[i].rotation = (b-a).angle()+PI*.5
        _shapes[i].shape.height = a.distance_to(b)+thickness
    geometry_locked = t>=charge_seconds+strike_seconds
    _last_electric_time = age

func _update_electricity(age: float) -> void:
    if not is_visible_in_tree() or age-_last_electric_time<1.0/30: return
    _last_electric_time = age
    var normal := (finish-start).normalized().orthogonal()
    var points := PackedVector2Array()
    for i in centerline.size():
        var s := float(i)/SEGMENTS
        points.append(centerline[i]+normal*sin(s*45-age*9)*3.5*sin(s*PI))
    sparks.points = points

func touches(world_point: Vector2, radius: float) -> bool:
    if not dangerous: return false
    var point := to_local(world_point)
    for i in centerline.size()-1:
        if Geometry2D.get_closest_point_to_segment(point,centerline[i],centerline[i+1]).distance_to(point)<=radius+thickness*.5+3: return true
    return false
