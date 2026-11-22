extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed = true
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    var fish = stage.fish
    var motor = fish.get_node("Movement")
    motor.set_physics_process(false)
    fish.get_node("Patrol").stop()
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
    var grab = stage.get_node("SurfaceGrab")
    grab.set_physics_process(false)
    var shore = stage.get_node("ShoreExit")
    shore.set_physics_process(false)
    var blink = fish.get_node("Teleport")
    fish.position = Vector2(960,shore.surface_y+1000)
    fish.velocity = Vector2(0,-420)
    game.get_node("CameraAttention").enabled = false
    game.camera.set_process(false)
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.offset = Vector2.ZERO
    game.camera.global_position = fish.global_position
    grab._physics_process(.01)
    check(grab.blocks_exit(),"Four-wave encounter holds the surface route until it is complete")
    for wave in 4:
        for i in 200:
            if grab.state==grab.State.WARNING: break
            grab._physics_process(.01)
        check(grab.state==grab.State.WARNING,"Every round starts with a visible warning")
        check(grab._warning_arms.size()==4 and grab._warning_arms[0].thickness>=110,"Each wave presents four substantially thicker tentacles")
        grab._on_blink(fish.global_position,fish.global_position+Vector2(180,-120))
        var reached := false
        for i in 350:
            fish.position += fish.velocity*.01
            game.camera.global_position = fish.global_position
            grab._physics_process(.01)
            if grab.state==grab.State.REACHING and not reached:
                reached = true
                var size: Vector2 = game.camera.get_viewport_rect().size/game.camera.zoom
                var view := Rect2(game.camera.global_position-size*.5,size).grow(-60)
                check(view.has_point(grab._previous_tip),"Every grab launches from a tip that is actually inside the camera")
                check(grab._arm.wave_amplitude>=80,"Grab retains a clearly curved body rather than a straight pole")
            if grab.rounds_completed>wave: break
        check(reached and grab.rounds_completed==wave+1,"Each dodge completes exactly one actual attack round")
        check(not game.dead,"Dodging four waves does not cause a scripted death")
        if wave<3:
            fish.position.y = shore.surface_y-2
            fish.velocity.y = -420
            fish.get_node("Input").external_control = true
            fish.get_node("Input").up_held = true
            shore._physics_process(.01)
            check(shore.state==shore.State.SWIMMING,"The shore leap waits for all four warned rounds")
            grab._physics_process(.01)
            check(fish.position.y>=shore.surface_y+220,"The last water section retains the fish until the sequence ends")
    check(grab.state==grab.State.FINISHED and not grab.blocks_exit() and grab.attacks_started==4,"Exactly four real attacks release the route to shore")
    fish.position.y = shore.surface_y-2
    fish.velocity.y = -420
    fish.get_node("Input").up_held = true
    shore._physics_process(.01)
    check(shore.state==shore.State.AIRBORNE,"After the fourth round normal W-to-shore movement works again")
    grab.reset()
    check(grab.rounds_completed==0 and grab.attacks_started==0,"Retry resets all four-round progression")
    print("SURFACE_FOUR_WAVE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
