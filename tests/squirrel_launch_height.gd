extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var layout = load("res://scenes/levels/formal_jungle_layout.tscn").instantiate()
    root.add_child(layout)
    layout.set_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false) # Isolate free-flight height from map edge assistance.
    var body = layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    body.set_physics_process(false)
    var climber = body.get_node("VineClimber")
    var motor = body.get_node("Movement")
    var reader = body.get_node("Input")
    climber.set_physics_process(false)
    motor.set_physics_process(false)
    reader.external_control = true
    reader.move_axis = 0
    reader.jump_held = false
    for vine in layout.vines: vine.set_physics_process(false)
    climber.vine._rider_velocity = Vector2(650,-650)
    Input.action_release(&"possess")
    climber._physics_process(1.0/120)
    body.global_position = Vector2(10000,20000)
    var start: Vector2 = body.global_position
    var peak: float = start.y
    for frame in 240:
        await physics_frame
        motor._physics_process(1.0/120)
        peak = minf(peak,body.global_position.y)
    var rise: float = start.y-peak
    print("SQUIRREL_THROW_RISE=",rise)
    check(rise>425 and rise<=455,"A typical upward swing release rises approximately 450 pixels in actual flight")
    check(body.global_position.x>start.x+1500,"Extra lift retains useful sideways travel")
    # Passing the lowest point now adds upward lift instead of a nearly flat exit.
    var rope = layout.vines[-1]
    rope.catch(body,Vector2.ZERO,body.global_position)
    climber.adopt_vine(rope)
    rope._rider_velocity = Vector2(900,0)
    climber.detach(false)
    check(body.velocity.y < -1000,"A fast horizontal swing gains meaningful lift when released at the bottom")
    rope.catch(body,Vector2.ZERO,body.global_position)
    climber.adopt_vine(rope)
    rope._rider_velocity = Vector2(400,300)
    climber.detach(false)
    check(body.velocity.y>0,"Releasing on the downward phase still respects release timing")
    print("SQUIRREL_LAUNCH_HEIGHT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
