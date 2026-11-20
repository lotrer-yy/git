extends Node2D
## 原画沿连续脊线变形：根部固定、身体先发力、末端稍迟跟进。
@export var segments: int = 48
@export var tip_lag_seconds: float = 0.035
@export var follow_through: float = 0.12
@export var ripple_radians: float = 0.025
@export var root_lift_degrees: float = 28.0
@export var root_slap_degrees: float = 18.0
var outline := PackedVector2Array()
var strike_centerline := PackedVector2Array()
var reach: float = 260.0
var _mesh: Polygon2D
var _rect: Rect2
var _pivot: Vector2
var _upper := PackedVector2Array()
var _lower := PackedVector2Array()
var _spine := PackedVector2Array()
var _angles := PackedFloat32Array()
var _time: float = 0.0
var _emerge: float
var _raise: float
var _strike: float
var _retract: float

func configure(texture: Texture2D, frame: Dictionary, material: Material) -> void:
    var r: Array = frame.region
    _rect = Rect2(r[0],r[1],r[2],r[3])
    _pivot = Vector2(frame.pivot[0],frame.pivot[1])
    reach = _rect.size.x-_pivot.x-4.0
    _mesh = Polygon2D.new()
    _mesh.texture = texture
    _mesh.material = material
    add_child(_mesh)
    var uv := PackedVector2Array()
    var faces: Array[PackedInt32Array] = []
    var image := texture.get_image()
    for i in segments+1:
        var x := _rect.size.x*float(i)/float(segments)
        uv.append(_rect.position+Vector2(x,0))
        uv.append(_rect.position+Vector2(x,_rect.size.y))
        if i < segments:
            faces.append(PackedInt32Array([i*2,i*2+2,i*2+1]))
            faces.append(PackedInt32Array([i*2+1,i*2+2,i*2+3]))
        # 原画黑边确定实际外轮廓，碰撞也使用同一条连续变形脊线。
        var source_x := clampi(int(_rect.position.x+x),int(_rect.position.x),int(_rect.end.x)-1)
        var top := -1
        var bottom := -1
        for y in int(_rect.size.y):
            var c := image.get_pixel(source_x,int(_rect.position.y)+y)
            if minf(c.r,minf(c.g,c.b)) < 0.85:
                if top < 0: top = y
                bottom = y
        if top >= 0:
            _upper.append(Vector2(x,top)-_pivot)
            _lower.append(Vector2(x,bottom)-_pivot)
    _mesh.uv = uv
    _mesh.polygons = faces
    # 保持脊线弧长；抬手不是把原图拉长，拍下也不是整张图旋转。
    var point := Vector2.ZERO
    strike_centerline.append(point)
    for i in segments:
        var s := (float(i)+.5)/float(segments)
        point += Vector2.RIGHT.rotated(deg_to_rad(root_slap_degrees)+0.52*pow(s,1.4))*reach/float(segments)
        strike_centerline.append(point)

func sample(time: float, emerge: float, raising: float, strike: float, retract: float) -> void:
    _time = time
    _emerge = emerge
    _raise = raising
    _strike = strike
    _retract = retract
    _spine.clear()
    _angles.clear()
    _spine.append(Vector2.ZERO)
    _angles.append(_root_angle())
    var point := Vector2.ZERO
    for i in segments:
        var s := (float(i)+.5)/float(segments)
        point += Vector2.RIGHT.rotated(_angle(s))*reach/float(segments)
        _spine.append(point)
        _angles.append(_angle(float(i+1)/float(segments)))
    var vertices := PackedVector2Array()
    for i in segments+1:
        var x := _rect.size.x*float(i)/float(segments)-_pivot.x
        vertices.append(_deform(Vector2(x,-_pivot.y)))
        vertices.append(_deform(Vector2(x,_rect.size.y-_pivot.y)))
    _mesh.polygon = vertices
    outline.clear()
    for p in _upper: outline.append(_deform(p))
    for i in range(_lower.size()-1,-1,-1): outline.append(_deform(_lower[i]))

func _ease(value: float) -> float:
    var u := clampf(value,0.0,1.0)
    return u*u*u*(u*(u*6.0-15.0)+10.0)

func _angle(s: float) -> float:
    var t := _time-tip_lag_seconds*pow(s,1.4)
    var bend := _pose(t,1.75,0.52,follow_through)
    var envelope := sin(PI*clampf(_time/(_emerge+_raise+_strike+_retract),0.0,1.0))
    return _root_angle()+bend*pow(s,1.4)+sin(_time*14.0-s*5.0)*ripple_radians*s*s*envelope

func _root_angle() -> float:
    # 围绕墙后根部摆动，扩大挥拍幅度；末端仍独立弯曲和滞后。
    return _pose(_time,deg_to_rad(root_lift_degrees),deg_to_rad(root_slap_degrees),deg_to_rad(6.0))

func _pose(t: float, lift: float, slap: float, recoil: float) -> float:
    var strike_start := _emerge+_raise
    var recover_start := strike_start+_strike
    var bend: float
    if t < _emerge:
        bend = -0.16*lift/1.75*sin(PI*_ease(t/_emerge))
    elif t < strike_start:
        bend = -lift*_ease((t-_emerge)/_raise)
    elif t < recover_start:
        bend = lerpf(-lift,slap,_ease((t-strike_start)/_strike))
    else:
        var u := (t-recover_start)/_retract
        bend = lerpf(slap,-recoil,_ease(u/.42)) if u < .42 else lerpf(-recoil,0.0,_ease((u-.42)/.58))
    return bend

func _deform(rest: Vector2) -> Vector2:
    var u := rest.x/reach
    var s := clampf(u,0.0,1.0)*float(segments)
    var index := mini(int(s),segments-1)
    var center := _spine[index].lerp(_spine[index+1],s-float(index))
    var angle := lerpf(_angles[index],_angles[index+1],s-float(index))
    if u < 0.0: center = Vector2(rest.x,0).rotated(_root_angle())
    if u > 1.0: center += Vector2.RIGHT.rotated(angle)*(rest.x-reach)
    return center+Vector2(-sin(angle),cos(angle))*rest.y
