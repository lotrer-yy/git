extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var eagle=load("res://modules/visual/eagle_flap_visual.gd").new()
    root.add_child(eagle)
    eagle.set_process(false)
    var first: PackedVector2Array=eagle.vertices_for_frame(0)
    check(first==eagle.vertices_for_frame(24),"The 24-frame animation loops seamlessly")
    var distinct: Dictionary={}
    var head_index:=0
    var wing_index:=0
    var head_distance:=INF
    var wing_distance:=INF
    for i in eagle._uv.size():
        var p: Vector2=eagle._uv[i]
        if p.distance_to(Vector2(790,420))<head_distance:
            head_distance=p.distance_to(Vector2(790,420)); head_index=i
        if p.distance_to(Vector2(100,150))<wing_distance:
            wing_distance=p.distance_to(Vector2(100,150)); wing_index=i
    var pixels: Image=eagle.ART.get_image()
    var inverted:=0
    var wing_min:=INF
    var wing_max: float=-INF
    for frame in 24:
        var vertices: PackedVector2Array=eagle.vertices_for_frame(frame)
        distinct[hash(vertices)]=true
        wing_min=minf(wing_min,vertices[wing_index].y)
        wing_max=maxf(wing_max,vertices[wing_index].y)
        var bob: float=-8*sin(TAU*frame/24.0)
        check(vertices[head_index].is_equal_approx(eagle._rest[head_index]+Vector2(0,bob)),"Face artwork stays undeformed")
        for face in eagle.mesh.polygons:
            var uv: Vector2=(eagle._uv[face[0]]+eagle._uv[face[1]]+eagle._uv[face[2]])/3.0
            if pixels.get_pixel(clampi(int(uv.x),0,1594),clampi(int(uv.y),0,1060)).a<.5: continue
            var a: Vector2=vertices[face[0]]
            var b: Vector2=vertices[face[1]]
            var c: Vector2=vertices[face[2]]
            if (b-a).cross(c-a)<=0: inverted+=1
    check(distinct.size()==24,"All 24 rendered poses are distinct")
    check(wing_max-wing_min>350,"Both strokes have a visible, substantial wing span movement")
    check(inverted==0,"Opaque wing triangles never turn inside out")
    eagle.sample_frame(12)
    eagle.reset()
    check(eagle.frame_index==0 and eagle.mesh.polygon==first,"Restart resets the original-art wing mesh")
    print("EAGLE_FLAP_24_FAILURES=",failures.size(),"; INVERTED=",inverted)
    quit(0 if failures.is_empty() else 1)
