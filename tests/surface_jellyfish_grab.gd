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
    fish.position = Vector2(960,shore.surface_y+1500)
    fish.velocity = Vector2(0,-420)
    grab._physics_process(.01)
    check(grab.state==grab.State.WAITING,"Deep water cannot start the final grab")
    fish.position.y = shore.surface_y+1000
    game.get_node("CameraAttention").enabled = false
    game.camera.set_follow_target(fish,true)
    game.camera.set_process(false)
    game.camera.global_position = fish.global_position
    game.camera.zoom = Vector2.ONE*1.35
    grab._physics_process(.01)
    check(grab.state==grab.State.WARNING and grab._warning_arms.size()==4,"Four tendrils announce the final encounter before any grab")
    var first_position: Vector2 = grab._warning_arms[0].global_position
    for i in 60:
        fish.position += fish.velocity*.01
        game.camera.global_position = fish.global_position
        grab._physics_process(.01)
    check(grab.state==grab.State.WARNING and motor.enabled,"Warning leaves swimming available and cannot grab early")
    check(grab._warning_arms[0].rotation!=0 and grab._warning_arms[0].global_position.y<first_position.y,"Tendrils rise independently with a smooth sway")
    check(grab._warning_arms[0].get_node("Warning").visible,"Emerging tendrils visibly show the warning art")
    for arm in grab._warning_arms:
        check(not arm.dangerous and arm.body.collision_layer==0,"Every warning tendril is harmless")
    if DisplayServer.get_name()!="headless":
        game.camera.make_current()
        game.camera.force_update_scroll()
        await process_frame
        await process_frame
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/work/surface-grab-warning.png")
    for i in 82:
        fish.position += fish.velocity*.01
        game.camera.global_position = fish.global_position
        grab._physics_process(.01)
    check(grab.state==grab.State.REACHING,"Grab begins only after the full warning")
    for i in 65:
        fish.position += fish.velocity*.01
        grab._physics_process(.01)
        if grab.state==grab.State.CAUGHT: break
    check(grab.state==grab.State.CAUGHT,"A swimming fish that does not blink is caught by the reaching tip")
    check(not motor.enabled and not fish.get_node("Visual").visible and grab._caught_art.visible,"Capture stops swimming and displays the supplied entangled artwork")
    grab._physics_process(.06)
    check(grab._caught_art.scale!=Vector2.ONE,"Capture has a visible squash and rebound")
    grab._physics_process(1)
    check(not game.dead and grab.state==grab.State.CAUGHT,"Capture leaves the player a chance to escape rather than killing immediately")
    game.get_node("CameraAttention").enabled = false
    game.camera.set_follow_target(fish,true)
    game.camera.set_process(false)
    game.camera.global_position = fish.global_position
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.make_current()
    game.camera.force_update_scroll()
    if DisplayServer.get_name()!="headless":
        await process_frame
        await process_frame
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/work/surface-grab.png")
    check(blink.try_teleport(Vector2.UP),"Shift remains available while entangled")
    await create_timer(.12).timeout
    check(grab.state==grab.State.FINISHED and motor.enabled and fish.get_node("Visual").visible,"Actual blink frees the fish and restores ordinary swimming")
    check(grab._caught_art==null and grab._arm==null,"Escape removes both the wrapper art and the reaching arm")
    grab.reset()
    blink.reset()
    fish.position.y = shore.surface_y+600
    fish.velocity = Vector2(0,-420)
    grab._on_blink(Vector2.ZERO,fish.global_position)
    grab._physics_process(.01)
    check(grab.state==grab.State.FINISHED and grab._arm==null,"A timely blink just before the trap avoids it entirely")
    grab.reset()
    fish.position.y = shore.surface_y+600
    grab._physics_process(.01)
    check(grab.state==grab.State.WARNING,"Retry starts with warning rather than a surprise reach")
    check(blink.try_teleport(Vector2.RIGHT),"Player can dodge during the reaching animation")
    await create_timer(.12).timeout
    check(grab.state==grab.State.FINISHED and grab._arm==null,"Blink during reach makes the fixed-direction arm miss")
    stage.reset()
    check(grab.state==grab.State.WAITING and grab._arm==null,"Retry rearms one clean final grab")
    print("SURFACE_GRAB_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
