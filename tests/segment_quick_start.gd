extends SceneTree
var failures:Array[String]=[]
var started:Array[int]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func press(key:Key,control:bool=false):
    var event=InputEventKey.new()
    event.physical_keycode=key
    event.pressed=true
    event.ctrl_pressed=control
    root.push_input(event,true)
func wait_started(index:int,previous:int):
    for i in 600:
        if started.size()>previous and started.back()==index:return true
        await process_frame
    return false
func run():
    var shortcut=root.get_node("SegmentQuickStart")
    shortcut.segment_started.connect(func(index:int):started.append(index))
    var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    press(KEY_1)
    check(await wait_started(1,0),"Key 1 starts the hell entry directly from the menu")
    var game=current_scene
    check(game.scene_file_path.ends_with("formal_hell_entry.tscn"),"Shortcut uses the original formal-map scene")
    check(game.get_node("WallEntry").playing and not game.get_node("WallEntry").completed,"Key 1 replays the ghost popping out of the doorway")
    check(game.soul.visible and game.player==game.soul,"Key 1 begins as the original ghost")
    check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.35),"Key 1 matches the normal opening gameplay zoom")
    check(game.camera.target==game.soul and game.camera.is_processing() and root.get_camera_2d()==game.camera,"Key 1 enables normal ghost camera following")
    check(not game.has_node("OpeningChase"),"Menu chase and descent are skipped")
    await create_timer(.8).timeout
    check(game.get_node("WallEntry").completed and game.soul.get_node("Input").enabled,"Ghost entry restores playable control")
    var camera_before:Vector2=game.camera.global_position
    game.soul.get_node("Movement").enabled=false
    game.soul.position+=Vector2(1200,-700)
    await create_timer(.6).timeout
    check(game.camera.global_position.x>camera_before.x+100 and game.camera.global_position.y<camera_before.y-100,"Key 1 retains horizontal and vertical camera motion")
    var old_id:int=game.get_instance_id()
    var previous:int=started.size()
    press(KEY_2)
    check(await wait_started(2,previous),"Key 2 starts just before the hell exit transition")
    game=current_scene
    var link=game.get_node("OceanLink")
    check(game.get_instance_id()!=old_id,"Stage switch clears the previous scene")
    check(link.stage==link.Stage.HELL and not game.get_node("WallEntry").playing,"Key 2 waits below the original hell crater without triggering the transition")
    check(game.player==game.demon and game.demon.get_node("Host").claimed,"Ocean shortcut begins with the possessed demon")
    check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.35),"Key 2 matches normal gameplay zoom instead of widening the view")
    check(game.camera.target==game.demon and game.camera.is_processing() and game.get_node("CameraAttention").enabled,"Key 2 keeps demon following and mechanism framing enabled")
    var breath=link.get_node("Breath")
    check(not breath.active and game.demon.get_node("Input").enabled,"Key 2 leaves the demon controllable before ocean entry")
    check(game.demon.global_position.y>link.vortex.global_position.y,"Key 2 lands below the original hell exit")
    check(not link.has_node("Ocean") and not link.has_node("ApproachSteps"),"Shortcut does not import an old map or extra platforms")
    await create_timer(.2).timeout
    check(game.demon.is_on_floor(),"Shortcut uses the original last platform")
    var reader=game.demon.get_node("Input")
    reader.external_control=true
    reader.jump_pressed=true
    reader.jump_held=true
    for i in 170:
        await physics_frame
        reader.move_axis=clampf((link.vortex.global_position.x-game.demon.global_position.x)/45.0,-1.0,1.0)
        if game.demon.velocity.y<0:reader.jump_pressed=false
        if link.stage!=link.Stage.HELL:break
    check(link.stage==link.Stage.CAPTURING,"Player jump from shortcut position triggers the original transition")
    for i in 600:
        await process_frame
        if link.stage==link.Stage.OCEAN:break
    check(link.stage==link.Stage.OCEAN and game.demon.get_node("Input").enabled,"Ocean eruption restores player control")
    check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.35),"Shortcut volcano transition preserves normal gameplay framing")
    check(link.get_node("FishStage").active,"Ocean shortcut also activates fish selection and swimming")
    breath.breath_duration=.01
    for i in 60:
        await process_frame
        if game.dead:break
    check(game.dead,"Fixture enters the frozen drowning death state")
    Engine.time_scale=.3
    previous=started.size()
    press(KEY_1)
    check(await wait_started(1,previous),"Key 1 works during a frozen death sequence")
    game=current_scene
    check(not game.dead and is_equal_approx(Engine.time_scale,1.0),"Shortcut clears death and slow motion")
    # If two stage keys arrive together, the last requested stage wins.
    previous=started.size()
    press(KEY_1)
    press(KEY_2)
    check(await wait_started(2,previous),"Rapid input starts the last requested stage")
    game=current_scene
    var same_id:int=game.get_instance_id()
    previous=started.size()
    press(KEY_1,true)
    await create_timer(.1).timeout
    check(started.size()==previous and current_scene.get_instance_id()==same_id,"Control shortcuts do not trigger stage changes")
    print("SEGMENT_QUICK_START_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
