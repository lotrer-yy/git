extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var flex = load("res://modules/visual/tentacle_flex_visual.gd").new()
    root.add_child(flex)
    var frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/ocean/tentacle/anchors.json")).frames
    flex.configure(load("res://assets/art/ocean/tentacle/slap_sheet.png"),frames[0],null)
    # 以比正式 0.16 秒拍下更快的 0.12 秒测试连续性。
    var previous = PackedVector2Array()
    var maximum_step := 0.0
    for i in 145:
        flex.sample(float(i)/120.0,.28,.34,.12,.40)
        check(flex._deform(Vector2.ZERO).length()<.0001,"Root pivot remains fixed during both swing and body flex")
        var length := 0.0
        for j in flex._spine.size()-1: length += flex._spine[j].distance_to(flex._spine[j+1])
        check(absf(length-flex.reach)<.001,"Body bends without stretching its spine length")
        var vertices: PackedVector2Array = flex._mesh.polygon
        if not previous.is_empty():
            for j in vertices.size(): maximum_step=maxf(maximum_step,previous[j].distance_to(vertices[j]))
        previous = vertices
    check(maximum_step<65.0,"Consecutive physics samples deform smoothly through the larger rapid slap")
    flex.sample(.62,.28,.34,.12,.40)
    check(flex._root_angle()<deg_to_rad(-27.0),"Windup visibly swings upward around the root")
    flex.sample(.74,.28,.34,.12,.40)
    check(flex._root_angle()>deg_to_rad(17.0),"Strike swings the root downward as well as bending the tip")
    for boundary in [.28,.62,.74,.908,1.14]:
        flex.sample(boundary-.00001,.28,.34,.12,.40)
        previous = flex._mesh.polygon
        flex.sample(boundary+.00001,.28,.34,.12,.40)
        for j in previous.size(): check(previous[j].distance_to(flex._mesh.polygon[j])<.2,"Adjacent animation phases have no frame-swap discontinuity")
    flex.sample(0,.28,.34,.12,.40)
    var rest: PackedVector2Array = flex._mesh.polygon
    flex.sample(1.20,.28,.34,.12,.40)
    for i in rest.size(): check(rest[i].distance_to(flex._mesh.polygon[i])<.001,"Follow-through settles back to the exact rest shape")
    check(flex.outline.size()>60,"Contact silhouette follows the flexing original-art outline")
    print("TENTACLE_FLEX_MOTION_FAILURES=",failures.size()," MAX_LOCAL_STEP=",maximum_step)
    quit(0 if failures.is_empty() else 1)
