extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    root.get_node("SegmentQuickStart").start_segment(2)
    await root.get_node("SegmentQuickStart").segment_started
    var game=current_scene
    game.get_node("FlyingEnemies").enabled=false
    var link=game.get_node("OceanLink")
    var reader=game.demon.get_node("Input")
    await create_timer(.2).timeout
    reader.external_control=true
    reader.jump_pressed=true
    reader.jump_held=true
    for i in 170:
        await physics_frame
        reader.move_axis=clampf((link.vortex.global_position.x-game.demon.global_position.x)/45.0,-1.0,1.0)
        if game.demon.velocity.y<0:reader.jump_pressed=false
        if link.stage!=link.Stage.HELL:break
    for i in 600:
        await process_frame
        if link.stage==link.Stage.OCEAN:break
    check(link.stage==link.Stage.OCEAN,"Real exit transition reaches the ocean handoff")
    var camera=game.camera
    var camera_id=root.get_camera_2d().get_instance_id()
    var previous:Vector2=camera.global_position
    var start:Vector2=previous
    var zoom:Vector2=camera.zoom
    var elapsed:=0.0
    var early_speed:=0.0
    var largest_step:=0.0
    for i in 180:
        await process_frame
        var dt:float=game.get_process_delta_time()
        var step:float=camera.global_position.distance_to(previous)*camera.zoom.y
        elapsed+=dt
        if elapsed<=.12:early_speed=maxf(early_speed,step/maxf(dt,.001))
        largest_step=maxf(largest_step,step)
        previous=camera.global_position
        check(camera.zoom.is_equal_approx(zoom),"Handoff does not introduce a zoom pop")
        check(root.get_camera_2d().get_instance_id()==camera_id,"Handoff keeps the same display camera")
    check(early_speed<40.0,"Stationary eruption camera resumes gently rather than immediately chasing the demon")
    check(largest_step<8.0,"Ocean follow remains continuous after handoff")
    check(camera.target==game.demon and camera.global_position.distance_to(start)>3.0,"Camera resumes following the demon after the blend")
    check(game.demon.get_node("Input").enabled,"Camera blend does not delay player control")
    print("OCEAN_CAMERA_HANDOFF_FAILURES=",failures.size()," EARLY_SPEED=",early_speed," MAX_STEP=",largest_step)
    quit(0 if failures.is_empty() else 1)
