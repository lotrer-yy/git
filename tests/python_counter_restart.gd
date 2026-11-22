extends SceneTree
var failures: Array[String] = []
var started: int = 0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func press4():
    var key := InputEventKey.new()
    key.physical_keycode=KEY_4
    key.pressed=true
    root.push_input(key,true)
func run():
    var quick = root.get_node("SegmentQuickStart")
    quick.segment_started.connect(func(index): started=index)
    var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    press4()
    for i in 500:
        await process_frame
        if started==4: break
    var stage = current_scene.get_node("OceanLink/FishStage")
    var body = stage.get_node("JungleLayout/Squirrel")
    body.get_node("Host").take_control()
    current_scene.player=body
    var encounter = stage.get_node("JungleLayout/PythonEncounter")
    encounter._begin_sequence()
    check(encounter.sequence.active and Engine.time_scale<.2,"Counter begins in the actual checkpoint scene")
    started=0
    await process_frame
    press4()
    for i in 500:
        await process_frame
        if started==4: break
    check(started==4 and Engine.time_scale==1,"Key4 reload during bullet time restores full speed")
    stage=current_scene.get_node("OceanLink/FishStage")
    check(stage.get_node("ShoreExit").state==2 and not stage.get_node("JungleLayout/PythonEncounter").sequence.active,"Checkpoint reload removes the old sequence and returns to the stranded fish")
    print("PYTHON_COUNTER_RESTART_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
