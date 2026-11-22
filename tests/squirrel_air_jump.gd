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
    var motor = body.get_node("Movement")
    var reader = body.get_node("Input")
    climber.set_physics_process(false)
    motor.set_physics_process(false)
    reader.external_control = true
    for rope in layout.vines: rope.set_physics_process(false)
    reader.jump_held = true
    climber.detach(true)
    check(motor.air_jumps_remaining==1,"Leaving a vine grants one air jump")
    body.global_position = Vector2(10000,20000)
    reader.jump_pressed = true
    motor._physics_process(1.0/120)
    check(motor.air_jumps_remaining==1,"The same held jump that leaves the rope cannot consume the air jump")
    reader.jump_held = false
    reader.jump_pressed = false
    motor._physics_process(1.0/120)
    body.velocity = Vector2(700,300)
    reader.jump_held = true
    reader.jump_pressed = true
    motor._physics_process(1.0/120)
    check(motor.air_jumps_remaining==0 and body.velocity.y< -900,"A fresh jump press propels the falling squirrel upward exactly once")
    check(is_equal_approx(body.velocity.x,700),"Air jump preserves horizontal flight momentum")
    reader.jump_held = false
    reader.jump_pressed = false
    motor._physics_process(1.0/120)
    body.velocity.y = 300
    reader.jump_pressed = true
    reader.jump_held = true
    motor._physics_process(1.0/120)
    check(body.velocity.y>0 and motor.air_jumps_remaining==0,"A third jump is unavailable before landing or catching a vine")
    reader.jump_pressed = false
    reader.jump_held = false
    body.global_position = Vector2(960,29300)
    body.velocity = Vector2(0,300)
    for frame in 120:
        await physics_frame
        motor._physics_process(1.0/120)
        if body.is_on_floor(): break
    check(body.is_on_floor() and motor.air_jumps_remaining==1,"Landing on jungle ground restores the air jump")
    motor.air_jumps_remaining = 0
    var rope = layout.vines[-2]
    body.global_position = rope.to_global(rope.rope.sample(rope.length*.6))-climber.hands_offset
    check(climber.try_grab() and motor.air_jumps_remaining==1,"Catching another thin vine restores the air jump")
    climber.detach(false)
    check(motor.air_jumps_remaining==1,"Releasing Shift keeps the restored air jump")
    print("SQUIRREL_AIR_JUMP_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
