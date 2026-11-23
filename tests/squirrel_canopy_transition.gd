extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    layout.set_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    body.set_physics_process(false)
    var motor=body.get_node("Movement")
    motor.set_physics_process(false)
    body.get_node("VineClimber").set_physics_process(false)
    body.get_node("VineClimber").reset()
    for vine in layout.vines: vine.set_physics_process(false)
    game.camera.set_process(false)
    var transition=layout.get_node("CanopyTransition")
    transition.set_physics_process(false)
    transition.travel.set_process(false)
    body.global_position=layout.to_global(Vector2(930,21100))
    check(not transition._can_enter(),"Flight below the canopy does not start a cinematic")
    body.global_position=layout.to_global(Vector2(930,20580))
    check(transition._can_enter(),"The controlled squirrel entering the actual dark leaf underside triggers the exit")
    transition._physics_process(.01)
    check(transition.state==transition.State.BURROWING and game.exit_in_progress,"Canopy entry starts once and protects the transition")
    check(not body.get_node("VineClimber").is_physics_processing() and body.transferring and not motor.enabled and not body.get_node("Input").enabled,"The cinematic owns movement and input")
    check(not layout.get_node("BeeEncounter").enabled and body.z_index<14,"The squirrel burrows behind leaves with bee attacks stopped")
    transition._physics_process(.46)
    check(not body.visible and transition.travel.active,"Squirrel remains hidden during the upward camera trip")
    transition.travel._process(2)
    check(body.visible and transition.state==transition.State.EMERGING,"Camera arrival starts the canopy emergence")
    transition._physics_process(.4)
    check(body.z_index>14,"Emerging squirrel moves in front of the canopy")
    transition._physics_process(.5)
    check(transition.state==transition.State.COMPLETE and motor.enabled and not body.transferring and not game.exit_in_progress,"Landing restores normal play without retriggering")
    check(abs(body.position.y-transition.canopy_y(body.position.x))<3,"The squirrel lands on the authored crown outline")
    await physics_frame
    await physics_frame
    var query=PhysicsRayQueryParameters2D.create(body.global_position+Vector2(0,-30),body.global_position+Vector2(0,40),32)
    var hit=body.get_world_2d().direct_space_state.intersect_ray(query)
    check(not hit.is_empty() and hit.collider==transition._surface,"Canopy has real floor collision at the visual landing point")
    for frame in 15:
        await physics_frame
        motor._physics_process(1.0/60)
    check(body.is_on_floor(),"Normal squirrel physics remains standing on the canopy")
    transition.reset()
    check(transition.state==transition.State.WAITING and body.z_index==10 and layout.get_node("BeeEncounter").enabled,"Replay restores normal layers and encounters")
    print("SQUIRREL_CANOPY_TRANSITION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
