extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var layout = load("res://scenes/levels/formal_jungle_layout.tscn").instantiate()
    root.add_child(layout)
    layout.set_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    var body = layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    body.set_physics_process(false)
    var climber = body.get_node("VineClimber")
    climber.detach(false)
    climber.set_physics_process(false)
    var motor = body.get_node("Movement")
    motor.set_physics_process(false)
    var reader = body.get_node("Input")
    reader.external_control = true
    reader.move_axis = 0
    reader.jump_held = false
    for rope in layout.vines: rope.set_physics_process(false)
    var arcs: Array = []
    var times: Array[float] = []
    for speed in [1.0,.8]:
        motor.reset()
        motor.momentum_flight_speed = speed
        body.global_position = Vector2(10000,20000)
        motor.launch_with_momentum(Vector2(1137.5,-sqrt(2*2200*450)))
        var samples: Array[float] = []
        var peak: float = 20000
        var finish: float = 0
        for frame in range(300):
            var previous: Vector2 = body.global_position
            await physics_frame
            motor._physics_process(1.0/120)
            peak = minf(peak,body.global_position.y)
            var target_x: float = 10000+float(samples.size()+1)*400
            if samples.size()<4 and body.global_position.x>=target_x:
                samples.append(lerpf(previous.y,body.global_position.y,(target_x-previous.x)/(body.global_position.x-previous.x)))
                finish = (frame+1)/120.0
        check(samples.size()==4,"Both speeds reach the same horizontal sample positions")
        check(20000-peak>435 and 20000-peak<455,"Both flight speeds keep the 450-pixel rise")
        arcs.append(samples)
        times.append(finish)
    var error: float = 0
    for i in 4: error=maxf(error,absf(arcs[0][i]-arcs[1][i]))
    print("SLOW_FLIGHT_ARC_MAX_ERROR=",error," TIME_RATIO=",times[1]/times[0])
    check(error<6,"Height at identical horizontal positions stays the same within physics-step tolerance")
    check(times[1]/times[0]>1.23 and times[1]/times[0]<1.27,"Same flight path takes approximately 25 percent longer")
    print("SQUIRREL_SLOW_ARC_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
