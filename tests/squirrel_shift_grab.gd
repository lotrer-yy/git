extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var layout = load("res://scenes/levels/formal_jungle_layout.tscn").instantiate()
    root.add_child(layout)
    var body = layout.get_node("Squirrel")
    var host = body.get_node("Host")
    var climber = body.get_node("VineClimber")
    var reader = body.get_node("Input")
    host.take_control()
    body.set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    climber.set_physics_process(false)
    reader.external_control = true
    climber.detach(false)
    var target = layout.vines[-2]
    body.global_position = target.to_global(target.rope.sample(target.length*.7))-climber.hands_offset
    reader.down_held = true
    climber._physics_process(.4)
    check(climber.vine==null,"S controls downward climbing without starting a new grab")
    Input.action_press(&"possess")
    climber._physics_process(.01)
    check(climber.vine==target and target.rider==body,"Held Shift grabs a nearby thin vine")
    reader.down_held = false
    reader.jump_held = true
    reader.move_axis = -1
    climber._physics_process(.01)
    check(target.climb_axis==-1 and not body.get_node("Movement").enabled,"W still climbs while the assisted rope owns the body movement")
    climber.detach(true)
    climber._physics_process(.1)
    check(climber.vine==null,"Jump release has a cooldown before held Shift can catch again")
    body.global_position = Vector2(10000,10000)
    climber._physics_process(.4)
    check(climber.vine==null,"Holding Shift far from vines never grabs the decorative main trunk")
    body.global_position = target.to_global(target.rope.sample(target.length*.6))-climber.hands_offset
    climber._physics_process(.01)
    check(climber.vine==target,"Keeping Shift held catches when entering range without another key press")
    target._rider_velocity = Vector2(-710,-900)
    reader.move_axis = 1
    Input.action_release(&"possess")
    climber._physics_process(.01)
    check(climber.vine==null and target.rider==null,"Releasing Shift actually detaches the squirrel")
    check(body.velocity.is_equal_approx(Vector2(-710,-900)),"Release inherits rope velocity without an arbitrary upward or sideways kick")
    reader.move_axis = 0
    reader.jump_held = false
    var motor = body.get_node("Movement")
    var before: Vector2 = body.velocity
    motor._physics_process(1.0/120)
    check(is_equal_approx(body.velocity.x,before.x),"No-input air braking does not erase the inherited sideways momentum")
    check(body.velocity.y < -800 and body.velocity.y>before.y,"A released throw follows gravity without a W-release height cutoff")
    Input.action_press(&"possess")
    climber._physics_process(.1)
    check(climber.vine==null,"Immediately pressing Shift again respects the release cooldown")
    Input.action_release(&"possess")
    climber._physics_process(.4)
    check(climber.vine==null,"Releasing Shift prevents automatic new grabs")
    for direction in [-1.0,1.0]:
        layout.reset()
        host.take_control()
        reader.external_control = true
        reader.jump_held = false
        reader.down_held = false
        reader.move_axis = direction
        Input.action_press(&"possess")
        var rope = climber.vine
        var found: bool = false
        for frame in 1440:
            reader.move_axis = signf(body.velocity.x) if absf(body.velocity.x)>8 else direction
            climber._physics_process(1.0/120)
            rope._physics_process(1.0/120)
            if frame>60 and body.velocity.x*direction>160:
                found = true
                break
        check(found,"Physical rope reaches a useful swinging speed in each direction")
        var inherited: Vector2 = body.velocity
        Input.action_release(&"possess")
        climber._physics_process(1.0/120)
        check(climber.vine==null and body.velocity.is_equal_approx(inherited),"Actual swinging velocity is preserved exactly when Shift is released")
        check(body.velocity.x*direction>160,"Releasing during left/right swing throws the squirrel in that direction")
        motor.reset()
        check(not motor._carried_momentum,"Reset clears the rope launch state for normal ground jumps")
    print("SQUIRREL_SHIFT_GRAB_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
