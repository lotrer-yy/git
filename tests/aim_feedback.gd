extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func run() -> void:
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    var manager=game.get_node("FlyingEnemies")
    manager.enabled=false
    root.add_child(game)
    current_scene=game
    await create_timer(.85).timeout
    game.soul.position=game.demon.position+Vector2(-90,0)
    for i in 5: await physics_frame
    check(game.possession.request_possession(),"Possession begins")
    await create_timer(2.6).timeout
    var rig=game.get_node("Fork")
    game.demon.get_node("Movement").enabled=false
    game.demon.get_node("Input").enabled=false
    game.demon.velocity=Vector2.ZERO
    var ball=game.get_node("Fork/Targets/Target02")
    game.demon.global_position=ball.global_position+Vector2(-260,260)
    game.camera.set_follow_target(game.demon,true)
    await create_timer(.1).timeout
    var origin: Vector2=game.demon.global_position+Vector2(0,-60)
    var candidate:=Vector2.ZERO
    var found:=false
    for i in 72:
        var point: Vector2=origin+Vector2.RIGHT.rotated(TAU*float(i)/72.0)*760.0
        if manager.is_on_screen(point,rig.enemy_lock_screen_inset) and game.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin,point,9)).is_empty():
            candidate=point
            found=true
            break
    check(found,"Test finds a visible unobstructed enemy beyond the former lock range")
    var enemy=manager.ENEMY.instantiate()
    enemy.encounter=manager
    enemy.position=manager.to_local(candidate)
    manager.get_node("Enemies").add_child(enemy)
    for i in 3: await physics_frame
    check(rig.selected==enemy and enemy.lock.visible,"Visible enemy at 760 units locks within three physics frames")
    check(rig.lock_distance==610.0,"Ball lock range stays unchanged")
    var half: Vector2=game.camera.get_viewport_rect().size*.5/game.camera.zoom
    var edge: Vector2=game.camera.global_position+Vector2(half.x-40,0)
    check(manager.is_on_screen(edge,rig.enemy_lock_screen_inset) and not manager.is_on_screen(edge),"Aim can appear near the edge while enemy attack margins stay unchanged")
    rig.set_physics_process(false)
    enemy.set_state(0)
    enemy.set_state(1)
    check(enemy.lock.scale.x<.1,"Indicator starts as a tiny centered icon")
    var center: Vector2=enemy.lock.position
    var overshot:=false
    for i in 44:
        await process_frame
        check(absf(enemy.lock.scale.x-enemy.lock.scale.y)<.001,"Indicator keeps its proportions")
        check(enemy.lock.position==center,"Indicator center remains fixed")
        overshot=overshot or enemy.lock.scale.x>1.1
        if i==4:
            var scale_before: Vector2=enemy.lock.scale
            enemy.set_state(1)
            check(enemy.lock.scale==scale_before,"Repeated lock does not restart the pop")
    check(overshot and enemy.lock.scale.distance_to(Vector2.ONE)<.001,"Indicator overshoots and settles at its original size")
    check(enemy.get_node("Visual").scale==Vector2.ONE,"Only the icon pops, leaving enemy artwork unchanged")
    enemy.set_state(0)
    enemy.set_state(1)
    enemy.set_state(0)
    await create_timer(.3).timeout
    check(not enemy.lock.visible and enemy.lock.scale==Vector2.ONE,"Unlock cancels the animation without a stale icon")
    enemy.set_state(1)
    enemy.take_hit()
    check(not enemy.lock.visible,"Defeat immediately clears the lock")
    print("AIM_FEEDBACK_FAILURES=",failures.size())
    game.queue_free()
    for i in 3: await process_frame
    quit(0 if failures.is_empty() else 1)
