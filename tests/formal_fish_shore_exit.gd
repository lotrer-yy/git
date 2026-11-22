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
    fish.get_node("Patrol").stop()
    fish.get_node("Movement").enabled = false
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
    var shore = stage.get_node("ShoreExit")
    shore.set_physics_process(false)
    var reader = fish.get_node("Input")
    reader.external_control = true
    reader.clear()
    fish.position = Vector2(960,shore.surface_y-2)
    fish.velocity = Vector2(0,-420)
    shore._physics_process(.01)
    check(shore.state==shore.State.SWIMMING,"Surface arrival without upward input cannot auto-leap")
    reader.up_held = true
    shore._physics_process(.01)
    check(shore.state==shore.State.AIRBORNE and fish.velocity.y<-1300,"Holding up launches the reused leap")
    check(not fish.get_node("Teleport").enabled,"Airborne fish cannot use underwater blink")
    await physics_frame
    var peak: float = fish.position.y
    for step in 250:
        await physics_frame
        shore._physics_process(1.0/Engine.physics_ticks_per_second)
        peak = minf(peak,fish.position.y)
        if shore.state==shore.State.STRANDED: break
    print("SHORE_PEAK=",peak," END=",fish.position," STATE=",shore.state)
    check(peak<29400,"Leap clears the original visible shore")
    check(shore.state==shore.State.STRANDED,"Fish lands on the formal shoreline")
    check(fish.get_node("Visual/Sprite").texture!=null,"Shore keeps current fish artwork")
    game.camera.set_follow_target(fish,true)
    game.camera.global_position = fish.global_position
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.make_current()
    game.camera.force_update_scroll()
    if DisplayServer.get_name()!="headless":
        await process_frame
        await process_frame
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/work/fish-shore-preview.png")
    stage.reset()
    check(shore.state==shore.State.SWIMMING and fish.motion_mode==CharacterBody2D.MOTION_MODE_FLOATING,"Retry restores underwater movement state")
    print("FORMAL_FISH_SHORE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)

