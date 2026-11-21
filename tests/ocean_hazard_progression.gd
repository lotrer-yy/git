extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
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
    var fish = stage.fish
    fish.get_node("Patrol").stop()
    fish.get_node("Movement").enabled = false
    var octopus = stage.get_node("Octopus")
    fish.position = Vector2(960,38500)
    stage._physics_process(0)
    check(not octopus.enabled,"Octopus cannot spawn in the ocean entrance section")
    fish.position.y = 35000
    stage._physics_process(0)
    check(octopus.enabled,"Octopus encounters are enabled in the middle ocean section")
    fish.position.y = 32000
    stage._physics_process(0)
    check(not octopus.enabled,"Octopus encounters stop outside the middle section")
    var shark = stage.get_node("Shark")
    shark.set_physics_process(false)
    shark.reset()
    shark._physics_process(1.99)
    check(shark.state==shark.State.WAITING,"First shark waits until two seconds after fish control")
    shark._physics_process(.02)
    check(shark.state==shark.State.LOCKING,"First shark begins appearing at two seconds")
    shark._finish_attack()
    shark._physics_process(2)
    check(shark.state==shark.State.WAITING,"Later sharks retain their longer attack interval")
    var net = stage.get_node("BossTentacleNet")
    net.set_physics_process(false)
    net.enabled = true
    game.camera.global_position = fish.global_position
    game.camera.offset = Vector2.ZERO
    game.camera.zoom = Vector2.ONE*.7
    net._spawn_row()
    var row: Dictionary = net.rows[0]
    row.age = 2
    row.aim_frozen = true
    row.node.position.y = fish.position.y+2000
    for arm in row.arms:
        arm.finish.y = -2400
    fish.get_node("Teleport")._invulnerability_remaining = 1
    net._physics_process(.01)
    check(row.node.visible and net.rows.has(row),"A diagonal tendril is neither hidden nor retired while its tip is still above the player")
    var arm = row.arms[0]
    fish.global_position = arm.to_global(arm.centerline[12])
    net._on_teleported(Vector2.ZERO,fish.global_position)
    fish.get_node("Teleport")._invulnerability_remaining = 0
    net._physics_process(.02)
    check(not game.dead,"Blink grace prevents a delayed strike from immediately hitting the destination")
    check(row.node.visible,"Blink breaks aim without making the physical tendril disappear")
    print("OCEAN_HAZARD_PROGRESSION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
