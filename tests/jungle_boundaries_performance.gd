extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var layout = load("res://scenes/levels/formal_jungle_layout.tscn").instantiate()
    root.add_child(layout)
    layout.set_process(false)
    var body = layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    var climber = body.get_node("VineClimber")
    climber.detach(false)
    body.set_physics_process(false)
    climber.set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    for vine in layout.vines: vine.set_physics_process(false)
    await physics_frame
    for height in [20500,25000,29300]:
        for direction in [-1,1]:
            body.global_position = Vector2(960,height)
            var hit = body.move_and_collide(Vector2(direction*8000,0))
            check(hit!=null and hit.get_collider()==layout.get_node("SideBoundaries"),"High-speed flight hits the invisible side boundary")
            check(body.global_position.x>=32 and body.global_position.x<=1888,"Squirrel stays inside the original 1920-pixel map")
    body.global_position = Vector2(960,29300)
    check(body.move_and_collide(Vector2(0,-8000),true)==null,"Side walls do not add a ceiling or block the jungle climbing route")
    var vine = layout.vines[0]
    var before: PackedVector2Array = vine.rope.points.duplicate()
    vine._physics_process(.1)
    check(vine.rope.points==before and not vine._ribbon_dirty,"Untouched static vines skip physics and mesh updates")
    check(vine._ribbon.get_child_count()==1,"Each vine uses one mesh instead of 24 polygon nodes")
    var mesh = vine._ribbon.get_child(0)
    check(mesh.uv.size()==(vine.segment_count+1)*2 and mesh.polygons.size()==vine.segment_count*2,"Single mesh retains continuous original UV and all bend segments")
    var uv: PackedVector2Array = mesh.uv.duplicate()
    var bent: PackedVector2Array = before.duplicate()
    bent[10].x=30
    vine._ribbon.update_points(bent)
    check(mesh.uv==uv and mesh.polygon[20].x!=0,"Bending only changes mesh vertices, preserving texture registration")
    var rope = layout.vines[-1]
    rope._physics_process(.01)
    check(rope._ribbon_dirty,"Released rope continues to update during the settling interval")
    rope._process(.01)
    check(not rope._ribbon_dirty,"New vertices are submitted only once per physics update")
    print("JUNGLE_BOUNDARIES_PERFORMANCE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
