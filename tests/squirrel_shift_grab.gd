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
    check(target.climb_axis==-1 and target.pump_axis==-1,"W and A/D still control climbing and swinging")
    climber.detach(true)
    climber._physics_process(.1)
    check(climber.vine==null,"Jump release has a cooldown before held Shift can catch again")
    body.global_position = Vector2(10000,10000)
    climber._physics_process(.4)
    check(climber.vine==null,"Holding Shift far from vines never grabs the decorative main trunk")
    body.global_position = target.to_global(target.rope.sample(target.length*.6))-climber.hands_offset
    climber._physics_process(.01)
    check(climber.vine==target,"Keeping Shift held catches when entering range without another key press")
    Input.action_release(&"possess")
    climber.detach(false)
    climber._physics_process(.4)
    check(climber.vine==null,"Releasing Shift prevents automatic new grabs")
    print("SQUIRREL_SHIFT_GRAB_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
