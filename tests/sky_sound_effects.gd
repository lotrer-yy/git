extends SceneTree
var failures: Array[String] = []
var counts: Dictionary = {}
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func count(cue: StringName) -> int: return counts.get(cue,0)
func run():
    root.get_node("Sfx").played.connect(func(cue):counts[cue]=counts.get(cue,0)+1)
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    game.get_node("RisingLava").process_mode = Node.PROCESS_MODE_DISABLED
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed = true
    game.get_node("CameraAttention").enabled = false
    game.died.disconnect(game.get_node("DeathFlow")._on_death)
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab"]:
        stage.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
    var layout = stage.get_node("JungleLayout")
    var squirrel = layout.get_node("Squirrel")
    var bird = layout.get_node("Bird")
    var shore = stage.get_node("ShoreExit")
    shore.set_physics_process(false)
    stage.fish.get_node("Movement").set_physics_process(false)
    stage.fish.get_node("Patrol").stop()
    shore.state = shore.State.STRANDED
    stage.fish.global_position = squirrel.global_position+Vector2(100,80)
    stage.get_node("JungleHandoff")._physics_process(.01)
    var transfer = stage.get_node("JunglePossession")
    check(transfer.request_possession(),"Fish to squirrel transfer starts")
    check(count(&"soul_exit")==1 and count(&"fish_enter")==0,"Fish exit sounds before squirrel entry")
    check(not transfer.request_possession(),"Repeated fish transfer is rejected")
    await transfer.possession_finished
    check(count(&"fish_enter")==1,"Squirrel entry sounds exactly once")
    var crown = layout.get_node("CanopyTransition")
    crown.set_physics_process(false)
    crown.travel.set_process(false)
    crown._begin()
    check(count(&"sky_transition")==1,"Actual canopy transition sounds once")
    var before := count(&"squirrel_jump")
    crown._begin_emerge()
    var bounce = crown.play.bouncer
    bounce.set_physics_process(false)
    check(count(&"squirrel_jump")==before+1,"Initial squirrel emergence jump sounds")
    bounce.buried = true
    bounce.launch()
    bounce.launch()
    check(count(&"squirrel_jump")==before+2,"Each real canopy jump sounds, rejected repeat stays silent")
    bird.get_node("Patrol").set_physics_process(false)
    bird.get_node("Movement").set_physics_process(false)
    squirrel.global_position = bird.global_position+Vector2(0,80)
    layout.get_node("CanopyBirdStage")._physics_process(0)
    var bird_transfer = layout.get_node("CanopyPossession")
    check(bird_transfer.request_possession(),"Squirrel to bird transfer starts")
    check(count(&"soul_exit")==2 and count(&"fish_enter")==1,"Squirrel exit sounds before bird entry")
    await bird_transfer.possession_finished
    check(count(&"fish_enter")==2 and game.player==bird,"Bird entry sounds once after transfer")
    bird.get_node("Movement").set_physics_process(false)
    bird.get_node("Boost").set_physics_process(false)
    game.camera.set_process(false)
    game.camera.global_position = bird.global_position
    game.camera.zoom = Vector2.ONE
    var sky = layout.get_node("SkyEagle")
    sky.set_process(false)
    sky.eagle.set_process(false)
    sky._begin()
    sky._process(sky.reveal_seconds+.01)
    sky.eagle._process(sky.eagle.cycle_seconds*.4)
    check(count(&"eagle_flap")==1,"Visible eagle power stroke sounds once")
    sky._process(sky.circling_seconds+.01)
    check(count(&"eagle_call")==1 and sky.eagle.screaming,"Call sounds when mouth opens")
    sky.eagle._process(.1)
    check(count(&"eagle_flap")==1,"Calling pose does not falsely flap")
    sky._process(sky.screech_seconds+.01)
    check(count(&"eagle_flap")==2,"Departure power stroke sounds")
    sky.eagle.hide()
    sky.eagle._process(2)
    check(count(&"eagle_flap")==2,"Hidden eagle cannot make new wingbeats")
    var hail = sky.get_node("Hail")
    hail.set_physics_process(false)
    hail.reset()
    hail._spawn_row()
    var stone: Dictionary = hail.stones[0]
    for other in hail.stones.slice(1): other.art.queue_free()
    hail.stones.clear()
    hail.stones.append(stone)
    bird.global_position = stone.art.global_position+Vector2(0,40)
    var fire = bird.get_node("Boost")
    bird.get_node("Input").external_control = false
    fire.heat = 1.0
    fire.tick(.01,true)
    hail._physics_process(.01)
    check(not game.dead and count(&"sky_ice_break")==0,"Initial burning contact has not completed a melt")
    hail._physics_process(hail.melt_seconds+.01)
    check(not game.dead and count(&"sky_ice_break")==1,"Successful melt sounds once while bird survives")
    hail._physics_process(.01)
    check(count(&"sky_ice_break")==1,"Removed ice cannot repeat audio")
    fire.reset()
    hail._spawn_row()
    var solid: Dictionary = hail.stones[0]
    for other in hail.stones.slice(1): other.art.queue_free()
    hail.stones.clear()
    hail.stones.append(solid)
    bird.global_position = solid.art.global_position+Vector2(0,40)
    hail._previous_target = bird.global_position
    hail._physics_process(.01)
    check(game.dead and count(&"bird_death")==1,"Unprotected lethal ice contact sounds bird death")
    check(count(&"sky_ice_break")==1 and count(&"death")==0 and count(&"squirrel_death")==0,"Lethal ice does not add melt or wrong death sounds")
    game.die(&"hail")
    check(count(&"bird_death")==1,"Repeated death contact stays silent")
    await create_timer(1,true,false,true).timeout
    game.queue_free()
    for i in 3: await process_frame
    print("SKY_SOUND_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
