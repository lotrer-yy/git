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
    var sprite = fish.get_node("Visual/Sprite")
    var visual = fish.get_node("Visual")
    check(sprite.texture==shore.stranded_texture,"Landing swaps to the supplied struggling artwork")
    check(shore.stranded_texture.region==shore.dead_texture.region,"Stranded and cross-eye art use identical framing")
    var landed_point: Vector2 = fish.global_position
    var poses: Array[Vector2] = []
    var colors: Array[float] = []
    for seconds in [.12,.3,2.5,5.5]:
        shore.elapsed = seconds-.01
        shore._physics_process(.01)
        poses.append(visual.position)
        colors.append(visual.modulate.g)
        var rect: Rect2 = sprite.get_rect()
        var lowest := -INF
        for corner in [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:
            lowest = maxf(lowest,fish.to_local(sprite.to_global(corner)).y)
        check(lowest<=31.1,"Flopping original art never sinks under its ground contact")
    check(poses[0]!=poses[1],"Struggle has real upward slap motion rather than a stationary tint")
    check(colors[0]>colors[2] and colors[2]>colors[3],"Fish turns progressively red over the stranded interval")
    check(not game.dead,"Struggling fish remains alive before the full interval")
    var death_signals: Array[int] = []
    shore.died_on_shore.connect(func(): death_signals.append(1))
    shore.elapsed = shore.stranding_duration-.005
    shore._physics_process(.01)
    check(shore.state==shore.State.DEAD and game.dead and game.death_reason==&"stranded","Timed suffocation enters the real shore death flow")
    check(sprite.texture==shore.dead_texture and visual.rotation==0 and visual.scale==Vector2.ONE,"Death stops struggling and uses supplied cross-eye art")
    check(sprite.position==Vector2(8,-11.5) and visual.position==shore.struggle.rest_position,"Texture swap preserves the ground anchor")
    check(visual.modulate.g<.5 and fish.visible,"Dead fish stays red and visible instead of vanishing immediately")
    shore.release_soul()
    check(death_signals.size()==1,"Shore death is emitted exactly once")
    await process_frame
    await create_timer(.15,true,false,true).timeout
    var flow = game.get_node("DeathFlow")
    check(not flow.overlay.visible and fish.visible,"Cross-eye pose is visible before the death overlay")
    game.camera.set_follow_target(fish,true)
    game.camera.global_position = fish.global_position
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.make_current()
    game.camera.force_update_scroll()
    if DisplayServer.get_name()!="headless":
        await process_frame
        await process_frame
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/work/fish-stranded-death.png")
    await create_timer(1.2,true,false,true).timeout
    check(flow.overlay.visible,"Existing death overlay appears after the cross-eye hold")
    stage.reset()
    check(sprite.texture!=shore.dead_texture and visual.modulate==Color.WHITE,"Retry restores swimming art and clears red suffocation tint")
    print("STRANDED_FISH_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
