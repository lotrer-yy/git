extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func flight_hits(start: Vector2, velocity: Vector2, target: SwingVine, reader: Node, motor: Node, jump_time: float) -> bool:
    var pos: Vector2 = start
    var speed: Vector2 = velocity
    var jumped: bool = false
    var step: float = 1.0/60
    for frame in 150:
        var time: float = frame*step
        if jump_time>=0 and time>=jump_time and not jumped:
            speed.y=minf(speed.y,-motor.air_jump_speed*motor.momentum_flight_speed)
            jumped=true
        speed.y=minf(speed.y+motor.gravity*pow(motor.momentum_flight_speed,2)*step,motor.max_fall_speed*motor.momentum_flight_speed)
        pos+=speed*step
        var hands: Vector2 = pos+Vector2(-60,-90)
        var grip := Vector2(target.global_position.x,clampf(hands.y,target.global_position.y+35,target.global_position.y+target.length))
        if hands.distance_to(grip)<=target.grab_radius-30: return true
    return false
func run():
    var layout = load("res://scenes/levels/formal_jungle_layout.tscn").instantiate()
    root.add_child(layout)
    layout.set_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    var body = layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    body.set_physics_process(false)
    body.collision_mask=0
    var climber = body.get_node("VineClimber")
    var reader = body.get_node("Input")
    var motor = body.get_node("Movement")
    climber.set_physics_process(false)
    motor.set_physics_process(false)
    reader.external_control=true
    reader.move_axis=0
    reader.jump_held=false
    reader.down_held=false
    for vine in layout.vines: vine.set_physics_process(false)
    Input.action_press(&"possess")
    var route = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/jungle/formal/swing_route.json"))
    for link in range(route.route.size()-1):
        var source: SwingVine = layout.get_node("InteractiveVines/"+route.route[link])
        var target: SwingVine = layout.get_node("InteractiveVines/"+route.route[link+1])
        var passes: int = 0
        var without_jump: int = 0
        for fraction in [.45,.65,.85]:
            climber.reset()
            source.reset()
            source.rider_offset=Vector2(60,90)
            body.global_position=source.to_global(source.rope.sample(source.length*fraction))+source.rider_offset
            source.catch(body,Vector2(260,0),body.global_position)
            source.grip_length=source.length*fraction
            climber.adopt_vine(source)
            motor.enabled=false
            for frame in 1200:
                climber._physics_process(1.0/120)
                source._physics_process(1.0/120)
                if frame<180 or frame%20!=0: continue
                if body.velocity.x*(target.global_position.x-body.global_position.x)<0: continue
                var start: Vector2 = body.global_position
                var before: Vector2 = body.velocity
                var grip_length: float = source.grip_length
                climber.detach(false)
                var launch: Vector2 = body.velocity
                for jump_time in [-1.0,.35,.6,.85]:
                    if flight_hits(start,launch,target,reader,motor,jump_time):
                        passes+=1
                        if jump_time<0: without_jump+=1
                        break
                source.rider=body
                source.grip_length=grip_length
                source.rope.load_index=clampi(roundi(grip_length/source.rope.segment_length),1,source.segment_count)
                climber.vine=source
                motor.enabled=false
                body.global_position=start
                body.velocity=before
        print("ROUTE_LINK=",source.name,"->",target.name," viable_release_samples=",passes," no_double_jump=",without_jump)
        check(passes>=3,"Every required link has multiple release opportunities with a 30-pixel catch margin")
    Input.action_release(&"possess")
    print("JUNGLE_DESIGNED_ROUTE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
