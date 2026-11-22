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
    body.set_physics_process(false)
    var climber = body.get_node("VineClimber")
    var motor = body.get_node("Movement")
    climber.detach(false)
    climber.set_physics_process(false)
    motor.set_physics_process(false)
    var reader = body.get_node("Input")
    reader.external_control = true
    reader.move_axis = 0
    reader.jump_held = false
    for vine in layout.vines: vine.set_physics_process(false)
    await physics_frame
    for direction in [-1,1]:
        body.global_position = Vector2(34 if direction<0 else 1886,25000)
        motor.launch_with_momentum(Vector2(direction*1500,-300))
        motor._physics_process(1.0/120)
        check(body.velocity.x*direction< -350,"Flying into either wall produces a real inward rebound")
        check(body.get_node("Visual")._spring_position.x<1,"Wall impact triggers squash and rebound feedback")
        var edge_x: float = body.global_position.x
        motor._physics_process(1.0/120)
        check((body.global_position.x-edge_x)*direction<0,"Squirrel moves away instead of sticking to the wall")
    var rope = layout.vines[-1]
    rope.reset()
    rope.global_position = Vector2(-200,24600)
    body.global_position = Vector2(34,25000)
    rope.rider_offset = Vector2(60,90)
    rope.catch(body,Vector2(-900,0),body.global_position)
    rope.grip_length = 310
    climber.adopt_vine(rope)
    body.velocity = Vector2(-900,0)
    rope._physics_process(1.0/120)
    check(rope.rider==body and body.velocity.x>350,"Hanging squirrel rebounds while keeping its grip")
    check(rope.rope.points[rope.rope.load_index].x>rope.rope.previous[rope.rope.load_index].x,"The loaded rope point also receives inward momentum")
    print("JUNGLE_WALL_BOUNCE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
