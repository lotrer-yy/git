extends SceneTree
var failures:Array[String]=[]
var exits_checked:int=0
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func check_exit(enemy:Node2D) -> void:
    var bounds:Rect2=enemy.art.get_global_transform_with_canvas()*enemy.art.get_rect()
    check(not bounds.intersects(root.get_visible_rect()),"Corpse is removed only after its complete artwork leaves the visible viewport")
    check(enemy.get_node("Visual").rotation-enemy._death_rotation>=TAU-.01,"Enemy completes its full death spin")
    exits_checked+=1
func run():
    var world=Node2D.new()
    root.add_child(world)
    var camera=Camera2D.new()
    world.add_child(camera)
    camera.make_current()
    for zoom in [1.0,.55,1.8]:
        camera.zoom=Vector2.ONE*zoom
        camera.position=Vector2.ZERO
        camera.force_update_scroll()
        await process_frame
        await process_frame
        var enemy=load("res://scenes/enemies/flying_demon.tscn").instantiate()
        enemy.position=Vector2(0,-root.get_visible_rect().size.y*.125/zoom)
        world.add_child(enemy)
        enemy.take_hit()
        # 在画布节点离树前读取坐标；父节点离树时子图案已失去画布变换。
        enemy.art.tree_exiting.connect(check_exit.bind(enemy))
        await create_timer(.9).timeout
        check(is_instance_valid(enemy),"A visible corpse survives past the former fixed deletion time")
        if not is_instance_valid(enemy):continue
        check(not enemy.lock.visible and not enemy.is_in_group("fork_targets"),"Dead enemy cannot attack or be targeted again")
        # Moving the camera with the falling corpse must keep it alive in view.
        for i in 36:
            camera.global_position=enemy.global_position
            camera.force_update_scroll()
            await process_frame
            if not is_instance_valid(enemy):break
        check(is_instance_valid(enemy),"Camera-followed corpse is not deleted while visible")
        for i in 600:
            if not is_instance_valid(enemy):break
            await process_frame
        check(not is_instance_valid(enemy),"Corpse is eventually released after falling out of view")
    check(exits_checked==3,"All three zoom levels completed off-screen cleanup")
    # A center outside the viewport is insufficient while part of the artwork remains.
    camera.zoom=Vector2.ONE
    camera.global_position=Vector2.ZERO
    camera.force_update_scroll()
    await process_frame
    var probe=load("res://scenes/enemies/flying_demon.tscn").instantiate()
    world.add_child(probe)
    probe.take_hit()
    probe.set_physics_process(false)
    probe.get_node("Visual").scale=Vector2.ONE
    probe.position=Vector2(0,root.get_visible_rect().size.y*.5+20)
    check(not probe._death_art_is_outside_view(),"Partially visible artwork below the screen edge is retained")
    probe.position.y+=500
    check(probe._death_art_is_outside_view(),"Fully off-screen artwork is eligible for cleanup")
    world.queue_free()
    for i in 3:await process_frame
    print("ENEMY_DEATH_OFFSCREEN_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
