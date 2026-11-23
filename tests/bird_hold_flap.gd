extends SceneTree
var failures: Array[String]=[]
var flaps:=0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var bird=load("res://scenes/actors/formal_canopy_bird.tscn").instantiate()
    root.add_child(bird)
    bird.position=Vector2(960,1000)
    bird.get_node("Host").take_control()
    bird.get_node("Movement").flapped.connect(func(): flaps+=1)
    Input.action_press(&"flap")
    for i in 100: await physics_frame
    check(flaps>=3 and bird.position.y<800,"Holding W repeatedly flaps and climbs without more key presses")
    Input.action_release(&"flap")
    var count:=flaps
    for i in 65: await physics_frame
    check(flaps==count and bird.velocity.y>0,"Releasing W stops automatic flaps and gravity resumes the fall")
    var motor=bird.get_node("Movement")
    var reader=bird.get_node("Input")
    reader.external_control=true
    reader.jump_held=true
    reader.jump_pressed=false
    for i in 60: await physics_frame
    check(flaps==count,"NPC external control cannot trigger held-player flapping")
    reader.jump_held=false
    reader.jump_pressed=true
    await physics_frame
    await physics_frame
    check(flaps==count+1,"Existing AI single-flap commands still work")
    print("BIRD_HOLD_FLAP_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
