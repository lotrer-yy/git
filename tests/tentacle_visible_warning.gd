extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func tick(net: Node, seconds: float):
    for i in ceili(seconds/.01): net._physics_process(.01)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    var stage = game.get_node("OceanLink/FishStage")
    var fish = stage.fish
    fish.position = Vector2(960,35000)
    fish.get_node("Movement").enabled = false
    fish.get_node("Patrol").stop()
    fish.get_node("Teleport").enabled = true
    fish.get_node("Teleport")._invulnerability_remaining = 100
    game.camera.global_position = fish.global_position
    game.camera.offset = Vector2.ZERO
    game.camera.zoom = Vector2.ONE*.7
    var net = stage.get_node("BossTentacleNet")
    net.set_physics_process(false)
    net.enabled = true
    net._spawn_row()
    var arm = net.rows[0].arms[0]
    var warning = arm.get_node("Warning")
    var fixed_origin: Vector2 = arm.global_position
    var fixed_aim: Vector2 = arm.finish
    tick(net,.30)
    check(not arm.cancelled and warning.visible,"A visible emerging tentacle pops the supplied warning")
    check(warning.sprite.scale.x>.65,"Warning briefly overshoots its settled size for the pop")
    check(not arm.dangerous and arm.body.collision_layer==0,"Warning has no damage or collision")
    var first_alpha: float = warning.sprite.modulate.a
    tick(net,.23)
    check(warning.sprite.modulate.a!=first_alpha,"Warning visibly flashes before disappearing")
    fish.position += Vector2(160,-80)
    game.camera.global_position += Vector2(30,-20)
    tick(net,.45)
    check(not warning.visible and not arm.dangerous,"Warning disappears before a separate safe reaction pause")
    check(arm.global_position==fixed_origin and arm.finish==fixed_aim,"Fish and camera movement cannot steer or drag the aimed tentacle")
    tick(net,.58)
    check(arm.dangerous and arm.geometry_locked,"The warned attack eventually launches along its original direction")
    net.reset()
    net.enabled = true
    net._spawn_row()
    arm = net.rows[0].arms[0]
    tick(net,.30)
    game.camera.global_position.y -= 3000
    tick(net,1.5)
    check(arm.warning_confirmed and not arm.cancelled and arm.dangerous,"An already visible warning commits the fixed-direction attack even after the player swims past")
    net.reset()
    net.enabled = true
    game.camera.global_position.x += 4000
    net._spawn_row()
    tick(net,1.6)
    for candidate in net.rows[0].arms:
        check(candidate.cancelled and not candidate.dangerous,"A tentacle born outside the camera cannot ambush the fish")
    print("TENTACLE_VISIBLE_WARNING_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
