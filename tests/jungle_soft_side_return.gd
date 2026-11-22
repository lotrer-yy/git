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
    var assist = layout.get_node("SoftSideReturn")
    assist.set_physics_process(false)
    for rope in layout.vines: rope.set_physics_process(false)
    await physics_frame
    body.global_position = Vector2(960,25000)
    body.velocity = Vector2(700,-300)
    assist._physics_process(1.0/120)
    check(body.velocity==Vector2(700,-300),"The middle of the jungle keeps all original momentum")
    for direction in [-1,1]:
        body.global_position = Vector2(34 if direction<0 else 1886,25000)
        check(body.move_and_collide(Vector2(direction*160,0),true)==null,"The former wall has no hard collision across the swing zone")
        body.global_position = Vector2(80 if direction<0 else 1840,25000)
        body.velocity = Vector2(direction*3000,-300)
        var max_outside: float = 0
        var returned: bool = false
        var max_jump: float = 0
        for frame in 360:
            var before: Vector2 = body.global_position
            var vertical_speed: float = body.velocity.y
            assist._physics_process(1.0/120)
            check(is_equal_approx(body.velocity.y,vertical_speed),"Soft return does not change throw height")
            body.move_and_collide(body.velocity/120)
            max_jump = maxf(max_jump,before.distance_to(body.global_position))
            max_outside = maxf(max_outside,-body.global_position.x if direction<0 else body.global_position.x-1920)
            if frame>12 and body.global_position.x>80 and body.global_position.x<1840:
                returned = true
                break
        print("SOFT_RETURN direction=",direction," overshoot=",max_outside," frame_displacement=",max_jump)
        check(max_outside>50 and max_outside<550,"Player may leave the frame briefly but cannot fly arbitrarily far")
        check(returned and max_jump<30,"Flight slides back continuously without snapping or rebounding off a wall")
    var rope = layout.vines[-1]
    rope.reset()
    rope.global_position = Vector2(100,24600)
    body.global_position = Vector2(-120,25000)
    rope.rider_offset = Vector2(60,90)
    rope.catch(body,Vector2(-600,0),body.global_position)
    rope.grip_length = 400
    rope.rope.load_index = roundi(400/rope.rope.segment_length)
    climber.adopt_vine(rope)
    body.velocity = Vector2(-600,-120)
    var before_previous: PackedVector2Array = rope.rope.previous.duplicate()
    var before_position: Vector2 = body.global_position
    assist._physics_process(1.0/120)
    check(rope.rider==body and body.global_position==before_position,"Hanging return keeps grip and never teleports the body")
    check(rope.rope.previous[rope.rope.load_index].x<before_previous[rope.rope.load_index].x,"Return adds inward momentum to the actual loaded rope point")
    var before_x: float = body.global_position.x
    for frame in 360:
        assist._physics_process(1.0/120)
        rope._physics_process(1.0/120)
    check(rope.rider==body and body.global_position.x>before_x,"Swinging can continue through the soft side zone without sticking")
    print("JUNGLE_SOFT_RETURN_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
