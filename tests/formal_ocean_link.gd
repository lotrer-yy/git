extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    await create_timer(.85).timeout
    var link=game.get_node("OceanLink")
    var display_id=root.get_camera_2d().get_instance_id()
    check(link.get_node_or_null("Ocean")==null,"No duplicate ocean prototype is loaded")
    check(link.find_children("*","Sprite2D",true,false).is_empty(),"Passage adds no replacement map artwork")
    var original_tiles=game.get_node("Map/ImageTiles").get_child_count()
    var platform_positions:Array[Vector2]=[]
    for platform in game.get_node("Platforms").get_children():platform_positions.append(platform.position)
    check(not link.vortex.try_capture(game.soul),"Ghost cannot enter the demon crater")
    game.soul.position=game.demon.position+Vector2(-90,0)
    for i in 5:await physics_frame
    check(game.possession.request_possession(),"Demon can be possessed")
    await create_timer(2.6).timeout
    game.demon.get_node("Movement").enabled=false
    game.demon.get_node("Input").enabled=false
    game.demon.global_position=link.vortex.global_position+Vector2(0,70)
    game.camera.set_follow_target(game.demon,true)
    game.demon.velocity=Vector2(0,100)
    for i in 3:await physics_frame
    check(link.stage==link.Stage.HELL,"Falling at the crater does not trigger entry")
    game.demon.velocity=Vector2(0,-600)
    for i in 5:
        await physics_frame
        if link.stage!=link.Stage.HELL:break
    check(link.stage==link.Stage.CAPTURING,"Upward contact with the original crater starts entry")
    check(link.vortex.position.is_equal_approx(Vector2(940,41780)),"Entry matches the original hell ceiling")
    check(link.ocean_mouth.position.is_equal_approx(Vector2(990,38995)),"Exit matches the original seabed crater")
    game.die()
    check(not game.dead,"Death cannot interrupt the passage")
    var previous:Vector2=game.camera.global_position
    var largest:=0.0
    var uniform:=true
    var travelled:=false
    for i in 800:
        await process_frame
        var visual=game.demon.get_node("Visual")
        if link.stage in [link.Stage.CAPTURING,link.Stage.ERUPTING]:
            uniform=uniform and absf(visual.scale.x-visual.scale.y)<.001
        if link.stage==link.Stage.TRAVELLING:
            travelled=true
            largest=maxf(largest,game.camera.global_position.distance_to(previous))
        previous=game.camera.global_position
        if link.stage==link.Stage.OCEAN:break
    check(travelled and link.stage==link.Stage.OCEAN,"Entry travels through the original strata and erupts into the original ocean")
    check(uniform,"Entry and emergence preserve character proportions")
    check(largest<100,"Camera travels continuously through the original map")
    check(root.get_camera_2d().get_instance_id()==display_id,"The original display camera remains active")
    check(game.demon.global_position.y<link.ocean_mouth.global_position.y-150,"Same demon emerges above the original seabed crater")
    check(game.demon.get_node("Input").enabled and game.demon.get_node("Movement").enabled,"Player control returns after emergence")
    await create_timer(5.5).timeout
    check(game.demon.is_on_floor() and game.demon.global_position.y<39105,"The original seabed outline supports the demon after it falls back")
    check(game.get_node("Map/ImageTiles").get_child_count()==original_tiles,"Original map tiles are retained")
    check(game.get_node("Platforms").get_child_count()==platform_positions.size(),"No platforms were added to the author's layout")
    game.restart()
    check(link.stage==link.Stage.HELL and not link.vortex.active and not game.exit_in_progress,"Restart cleans up the passage")
    check(game.demon.get_node("Movement").gravity==2200.0,"Restart restores original hell movement")
    print("FORMAL_OCEAN_FAILURES=",failures.size()," MAX_CAMERA_STEP=",largest)
    game.queue_free()
    for i in 3:await process_frame
    quit(0 if failures.is_empty() else 1)
