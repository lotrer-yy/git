extends SceneTree
var failures: Array[String] = []
var shots: int = 0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var player := CharacterBody2D.new()
    root.add_child(player)
    var camera := Camera2D.new()
    root.add_child(camera)
    camera.make_current()
    var enemy = load("res://scenes/enemies/ocean_octopus.tscn").instantiate()
    root.add_child(enemy)
    enemy.configure(player,camera)
    enemy.enabled = true
    enemy.automatic_spawning = false
    enemy.set_physics_process(false)
    enemy.ink_sprayed.connect(func():shots+=1)
    for velocity in [Vector2.ZERO,Vector2(0,-420),Vector2(470,0),Vector2(-470,0),Vector2(470,-420),Vector2(0,680)]:
        enemy.reset()
        player.position = Vector2.ZERO
        player.velocity = velocity
        camera.position = player.position
        camera.force_update_scroll()
        enemy._appear(Vector2(-240,-180))
        var before := shots
        var locked_point := Vector2.INF
        var locked_direction := Vector2.ZERO
        var spray_error := INF
        for step in 300:
            player.position += velocity*.01
            camera.position = player.position
            camera.force_update_scroll()
            enemy._physics_process(.01)
            if enemy.state==enemy.State.DASHING:
                if locked_point==Vector2.INF:
                    locked_point = enemy._predicted_point
                    locked_direction = enemy._jet_direction
                    if velocity!=Vector2.ZERO:
                        check((locked_point-player.global_position).dot(velocity)>0,"Attack leads the fish along its actual swimming velocity")
                else:
                    check(enemy._predicted_point==locked_point and enemy._jet_direction==locked_direction,"Launched interception does not home onto the fish")
            if is_instance_valid(enemy._cloud): spray_error = minf(spray_error,player.position.distance_to(enemy._cloud.global_position))
            if shots>before: break
        print("PREDICTION_VELOCITY=",velocity," HIT=",shots>before," CLOSEST_INK=",spray_error)
        check(shots==before+1,"Steady swim %s must actually contact the predicted visible ink" % velocity)
    # 预判在出手时锁定：之后变向/瞬移仍能避开，墨团不能偷偷追着人。
    enemy.reset()
    player.position = Vector2.ZERO
    player.velocity = Vector2(0,-420)
    camera.position = player.position
    camera.force_update_scroll()
    enemy._appear(Vector2(-240,-180))
    var before := shots
    var dodged := false
    var locked_point := Vector2.ZERO
    for step in 260:
        if not dodged: player.position += player.velocity*.01
        camera.position = player.position
        camera.force_update_scroll()
        enemy._physics_process(.01)
        if not dodged and enemy.state==enemy.State.DASHING:
            locked_point = enemy._predicted_point
            player.position += Vector2(700,0)
            player.velocity = Vector2.ZERO
            dodged = true
        if dodged: check(enemy._predicted_point==locked_point,"Teleport cannot drag the locked spray point along")
    check(dodged and shots==before,"A deliberate dodge after windup still avoids the predicted spray")
    # 使用真实小鱼的加速度、阻力和速度上限，验证并非只命中静态夹具。
    var fish = load("res://scenes/actors/fish.tscn").instantiate()
    root.add_child(fish)
    fish.get_node("Host").take_control()
    fish.get_node("Patrol").stop()
    var motor = fish.get_node("Movement")
    var reader = fish.get_node("Input")
    reader.external_control = true
    motor.set_physics_process(true)
    enemy.set_physics_process(true)
    for axis in [Vector2(0,-1),Vector2(1,-1),Vector2(-1,-1)]:
        enemy.reset()
        fish.position = Vector2.ZERO
        fish.velocity = Vector2.ZERO
        reader.move_axis = axis.x
        reader.up_held = true
        reader.down_held = false
        enemy.configure(fish,camera)
        camera.position = fish.position
        camera.force_update_scroll()
        enemy._appear(Vector2(-240,-180))
        before = shots
        for step in 500:
            await physics_frame
            camera.position = fish.position
            camera.force_update_scroll()
            if shots>before: break
        print("REAL_SWIM_INPUT=",axis," HIT=",shots>before," VELOCITY=",fish.velocity)
        check(shots==before+1,"Real accelerating fish input %s must be intercepted by ink" % axis)
    fish.queue_free()
    enemy.set_physics_process(false)
    enemy.reset()
    enemy.queue_free()
    await process_frame
    print("OCTOPUS_PREDICTION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
