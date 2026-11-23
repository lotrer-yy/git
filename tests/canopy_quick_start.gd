extends SceneTree
var failures: Array[String]=[]
var started:=0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func press_five():
    var key:=InputEventKey.new()
    key.physical_keycode=KEY_5
    key.pressed=true
    root.push_input(key,true)
func wait_start():
    for i in 600:
        await process_frame
        if started==5: return
func run():
    root.get_node("SegmentQuickStart").segment_started.connect(func(index): started=index)
    var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    press_five()
    await wait_start()
    check(started==5,"Key 5 starts the canopy preview from the menu")
    var stage=current_scene.get_node("OceanLink/FishStage")
    var layout=stage.get_node("JungleLayout")
    var body=layout.get_node("Squirrel")
    var transition=layout.get_node("CanopyTransition")
    check(current_scene.player==body and body.get_node("Host").claimed,"Preview starts already possessing the squirrel")
    check(body.get_node("VineClimber").vine==layout.vines[0],"Preview starts on the uppermost thin vine")
    check(not body.get_node("Input").enabled,"The automatic launch cannot be steered off course")
    for i in 720:
        await physics_frame
        if transition.state==transition.State.COMPLETE: break
    check(transition.state==transition.State.COMPLETE,"With no player input, the real launch enters the crown and completes the cinematic")
    check(not current_scene.dead and body.get_node("Input").enabled and not body.transferring,"Landing safely restores player control")
    started=0
    press_five()
    await wait_start()
    check(started==5 and current_scene.get_node("OceanLink/FishStage/JungleLayout/CanopyTransition").state==0,"Repeated key 5 starts a clean preview")
    started=0
    press_five()
    await wait_start()
    check(started==5 and not current_scene.dead,"Key 5 can also restart during the automatic launch")
    print("CANOPY_QUICK_START_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
