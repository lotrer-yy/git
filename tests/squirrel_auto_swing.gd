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
    var host = body.get_node("Host")
    var climber = body.get_node("VineClimber")
    var reader = body.get_node("Input")
    host.take_control()
    body.set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    climber.set_physics_process(false)
    reader.external_control = true
    reader.move_axis = 0
    reader.jump_held = false
    reader.down_held = false
    Input.action_press(&"possess")
    var rope = climber.vine
    check(climber.visited_vines.has(rope.get_instance_id()),"The initial possessed vine counts as already grabbed")
    var first_peak: float = 0
    var later_peak: float = 0
    var highest: float = 0
    for frame in 3600:
        climber._physics_process(1.0/120)
        rope._physics_process(1.0/120)
        var radius: Vector2 = rope.rope.sample(rope.grip_length)
        var angle: float = absf(atan2(radius.x,radius.y))
        if frame<120: first_peak = maxf(first_peak,angle)
        if frame>1200: later_peak = maxf(later_peak,angle)
        highest = maxf(highest,angle)
    print("AUTO_SWING_ANGLES=",rad_to_deg(first_peak),",",rad_to_deg(later_peak)," MAX=",rad_to_deg(highest))
    check(later_peak>first_peak+.05,"Holding Shift alone gradually increases the actual physical swing amplitude")
    check(highest<deg_to_rad(80),"Automatic pumping stays below an over-the-top rotation")
    var launch: Vector2 = body.velocity
    Input.action_release(&"possess")
    climber._physics_process(.01)
    check(climber.vine==null and signf(body.velocity.x)==signf(launch.x) and body.velocity.length()>launch.length()*1.5,"Letting go boosts the real swing momentum with enhanced lift while preserving its sideways direction")
    var old = layout.vines[-2]
    old.position = Vector2(5000,20000)
    var grip: Vector2 = old.to_global(old.rope.sample(old.length*.6))
    body.global_position = grip-climber.hands_offset
    Input.action_press(&"possess")
    climber._physics_process(.4)
    check(climber.vine==old,"A reachable old vine can still be grabbed")
    climber.detach(false)
    var fresh := SwingVine.new()
    fresh.length = old.length
    fresh.position = old.position+Vector2(35,0)
    layout.add_child(fresh)
    body.global_position = grip-climber.hands_offset
    climber._physics_process(.4)
    check(climber.vine==fresh,"An overlapping unvisited vine wins over a closer previously grabbed vine")
    climber.detach(false)
    body.global_position = grip-climber.hands_offset
    climber._physics_process(.4)
    check(climber.vine==old,"When all overlapping vines were grabbed, nearest reachable vine wins")
    climber.detach(false)
    var distant := SwingVine.new()
    distant.position = old.position+Vector2(500,0)
    layout.add_child(distant)
    body.global_position = grip-climber.hands_offset
    climber._physics_process(.4)
    check(climber.vine==old,"An unvisited vine outside grab range cannot override a reachable vine")
    climber.reset()
    check(climber.visited_vines.is_empty(),"Replay clears the visited-vine history")
    Input.action_release(&"possess")
    print("SQUIRREL_AUTO_SWING_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
