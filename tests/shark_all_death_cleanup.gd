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
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    stage.fish.get_node("Movement").enabled = false
    var shark = stage.get_node("Shark")
    shark.set_physics_process(false)
    shark.set_process(false)
    for reason in [&"tentacle",&"jellyfish_net",&"pink_shark",&"shark",&"stranded",&"impact"]:
        for dashing in [false,true]:
            game.dead = false
            shark.enabled = true
            shark._begin_lock()
            if dashing: shark._begin_dash()
            game.dead = true
            game.death_reason = reason
            stage._on_player_died()
            var fixed: Vector2 = shark.global_position
            shark._physics_process(.2)
            shark._process(.2)
            check(shark.state==shark.State.WAITING and not shark.visible and not shark.enabled,"Every death cause cancels locking and committed sharks: "+str(reason))
            check(shark.global_position==fixed,"Dead-player shark can no longer advance or attack")
    game.dead = false
    shark.enabled = true
    shark._begin_lock()
    shark._begin_dash()
    game.dead = true
    shark._physics_process(.1)
    check(not shark.visible and shark.state==shark.State.WAITING,"Shark self-check also cancels a dash if death callback has not run yet")
    print("SHARK_ALL_DEATH_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
