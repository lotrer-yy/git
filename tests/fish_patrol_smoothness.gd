extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var fish=load("res://scenes/actors/fish.tscn").instantiate()
    root.add_child(fish)
    var visual=fish.get_node("Visual")
    var reader=fish.get_node("Input")
    var patrol=fish.get_node("Patrol")
    var previous_angle:float=visual.rotation
    var largest_step:=0.0
    var pitch_reversals:=0
    var previous_pitch:=0
    var distance:=0.0
    var previous:Vector2=fish.position
    for i in 600:
        await process_frame
        largest_step=maxf(largest_step,absf(angle_difference(previous_angle,visual.rotation)))
        var pitch:=int(signf(visual.rotation)) if absf(visual.rotation)>.015 else 0
        if pitch!=0:
            if previous_pitch!=0 and pitch!=previous_pitch:pitch_reversals+=1
            previous_pitch=pitch
        previous_angle=visual.rotation
        distance+=fish.position.distance_to(previous)
        previous=fish.position
    check(reader.use_analog_thrust,"Patrol uses continuous rather than on-off vertical thrust")
    check(largest_step<.045,"Patrol artwork does not twitch between steep input-driven angles")
    check(pitch_reversals<8,"Patrol pitch changes gradually rather than trembling every frame")
    check(distance>100 and absf(fish.position.y-patrol.center.y)<100,"Fish keeps swimming within its patrol band")
    patrol.stop()
    reader.external_control=true
    reader.enabled=true
    reader.move_axis=1.0
    reader.up_held=true
    var before:Vector2=fish.position
    await create_timer(.4).timeout
    check(not reader.use_analog_thrust,"Stopping patrol clears automatic thrust for player control")
    check(fish.position.x>before.x+10 and fish.position.y<before.y-8,"Original player swimming controls remain responsive")
    print("FISH_PATROL_FAILURES=",failures.size()," MAX_ANGLE_STEP=",largest_step," PITCH_REVERSALS=",pitch_reversals)
    fish.queue_free()
    for i in 3:await process_frame
    quit(0 if failures.is_empty() else 1)
