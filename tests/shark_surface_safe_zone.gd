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
    fish.get_node("Movement").enabled = false
    fish.get_node("Patrol").stop()
    var shark = stage.get_node("Shark")
    shark.set_physics_process(false)
    shark.set_process(false)
    var boundary: float = stage.get_node("ShoreExit").surface_y+stage.shark_surface_safe_depth
    fish.position = Vector2(960,boundary+500)
    stage._physics_process(0)
    check(shark.enabled,"Deep-water shark still attacks below the safe zone")
    shark._begin_lock()
    fish.position.y = boundary
    stage._physics_process(0)
    check(not shark.enabled and not shark.visible and shark.state==shark.State.WAITING,"Entering the last 1200 pixels cancels a shark already locking")
    for i in 10: shark._physics_process(1)
    check(not shark.visible,"Waiting at the surface cannot spawn more sharks")
    fish.position.y = boundary+100
    stage._physics_process(0)
    shark._begin_lock()
    shark._begin_dash()
    check(shark.state==shark.State.DASHING,"Fixture starts an actual committed dash")
    fish.position.y = boundary-200
    stage._physics_process(0)
    check(not shark.visible and shark.state==shark.State.WAITING,"A committed dash also retires on entry to shallow water")
    stage._on_shark_hit(Vector2.UP)
    check(not game.dead,"A late same-frame shark contact cannot kill fish inside the safe zone")
    fish.position.y = boundary+500
    stage._physics_process(0)
    check(shark.enabled and is_zero_approx(shark.cycle_elapsed),"Returning to deep water starts a fresh attack timer")
    print("SHARK_SURFACE_SAFE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
