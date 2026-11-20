extends SceneTree
var failures: Array[String] = []
var hits := 0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var fish = load("res://scenes/actors/fish.tscn").instantiate()
    root.add_child(fish)
    fish.get_node("Host").take_control()
    fish.get_node("Patrol").stop()
    fish.get_node("Input").external_control = true
    var camera := Camera2D.new()
    camera.zoom = Vector2.ONE*1.35
    root.add_child(camera)
    camera.make_current()
    var shark = load("res://scenes/enemies/ocean_shark.tscn").instantiate()
    root.add_child(shark)
    shark.configure(fish,camera)
    shark.enabled = true
    shark.spawn_interval = 100
    shark.player_hit.connect(func(_direction):hits+=1)
    for input_axis in [Vector2(0,-1),Vector2(1,-1),Vector2(-1,-1)]:
        for side in [-1,1]:
            shark.reset()
            fish.position = Vector2.ZERO
            fish.velocity = Vector2.ZERO
            fish.get_node("Input").move_axis = input_axis.x
            fish.get_node("Input").up_held = true
            camera.position = fish.position
            camera.force_update_scroll()
            shark._side = -side
            var before := hits
            shark._begin_lock()
            var direction := Vector2.ZERO
            var committed := false
            for step in 300:
                await physics_frame
                camera.position = fish.position
                camera.force_update_scroll()
                if shark.state == shark.State.DASHING and not committed:
                    direction = shark.dash_direction
                    committed = true
                    var lead: Vector2 = shark.locked_point-shark._target_center()
                    check(lead.dot(fish.velocity)>0,"Shark leads the swimming fish at launch")
                    check(lead.length()<=180.01,"Prediction remains a small bounded advance")
                elif committed and shark.state==shark.State.DASHING:
                    check(shark.dash_direction==direction,"Lead does not turn into post-launch homing")
                if hits>before: break
            print("SHARK_REAL_INPUT=",input_axis," SIDE=",side," HIT=",hits>before)
            check(hits==before+1,"Steady real fish swimming %s must be intercepted from side %d" % [input_axis,side])
    # 发射以后瞬移到射线侧面，预判点和航向不再变化。
    shark.reset()
    fish.get_node("Movement").enabled = false
    fish.position = Vector2.ZERO
    fish.velocity = Vector2(0,-420)
    camera.position = fish.position
    camera.force_update_scroll()
    shark.position = Vector2(-450,-100)
    shark.show()
    shark._begin_dash()
    var direction: Vector2 = shark.dash_direction
    var point: Vector2 = shark.locked_point
    fish.position += direction.orthogonal()*500
    fish.velocity = Vector2.ZERO
    var before := hits
    for step in 80:
        await physics_frame
        if shark.state!=shark.State.DASHING: break
        check(shark.dash_direction==direction and shark.locked_point==point,"Late dodge cannot move the committed intercept")
    check(hits==before,"A sideways dodge after launch still avoids the shark")
    shark.reset()
    print("SHARK_PREDICTION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
