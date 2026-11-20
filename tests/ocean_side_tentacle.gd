extends SceneTree
var failures: Array[String] = []
var attacks: Array[int] = []
var watching_camera: Camera2D
var maximum_shake: float = 0.0
func _process(_delta):
    if is_instance_valid(watching_camera): maximum_shake=maxf(maximum_shake,watching_camera.offset.length())
    return false
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var stage = game.get_node("OceanLink/FishStage")
    var trap = stage.get_node("SideTentacle")
    var fish = stage.fish
    trap.attack_started.connect(func(side: int): attacks.append(side))
    var y = 38000.0
    var bounds: Vector2 = trap._bounds_at(y)
    fish.get_node("Patrol").stop()
    fish.get_node("Movement").enabled = false
    fish.position = Vector2(bounds.x+180,y)
    trap.linger_elapsed = 1.99
    await create_timer(.05).timeout
    check(attacks.is_empty() and is_zero_approx(trap.linger_elapsed),"An unpossessed fish never triggers the trap")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    fish.get_node("Movement").enabled = false
    fish.get_node("Input").external_control = true
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.set_follow_target(fish,true)
    watching_camera=game.camera
    await create_timer(.95).timeout
    check(attacks.is_empty() and trap.linger_elapsed>.8,"A short stay near the left wall does not attack early")
    fish.position.x = (bounds.x+bounds.y)*.5
    await create_timer(.05).timeout
    check(is_zero_approx(trap.linger_elapsed),"Returning to the middle clears the exposure timer")
    fish.position.x = bounds.y-180
    await create_timer(1.05).timeout
    check(attacks.is_empty() and trap.linger_elapsed>.9,"A separate short right-wall stay is not accumulated with the left stay")
    fish.position.x = bounds.x+180
    await create_timer(.03).timeout
    check(trap.linger_elapsed<.06,"Switching walls restarts the two-second timer")
    await create_timer(1.88).timeout
    check(attacks.is_empty(),"No attack occurs before two continuous seconds on the same side")
    await create_timer(.14).timeout
    check(attacks==[-1] and trap.attacking,"Two seconds at the left wall starts a left-wall attack")
    check(trap._anchor.x<trap._bounds_at(y-trap.spawn_above_pixels).x and trap._rig.scale.x>0,"Left tentacle is rooted behind the wall and faces into the water")
    check(absf(trap._anchor.y-(y-340.0))<.01,"Left tentacle emerges 340 pixels above the fish to block its upward route")
    check(trap.z_index<game.get_node("WorldLayers/OceanWalls").z_index,"Wall foreground covers the tentacle root")
    check(fish.get_node("Teleport").try_teleport(Vector2.RIGHT),"Fish can use its real Shift skill during the attack anticipation")
    await create_timer(trap.emerge_seconds+trap.raise_seconds+trap.strike_seconds+trap.retract_seconds+.1).timeout
    check(not game.dead and not trap.attacking,"Blinking beyond the locked attack avoids damage and the arm retracts")
    trap.reset()
    trap.linger_seconds = .05
    fish.position = Vector2(bounds.y-180,y)
    fish.velocity = Vector2.ZERO
    game.camera.set_follow_target(fish,true)
    await create_timer(.09).timeout
    check(attacks==[-1,1] and trap._rig.scale.x<0 and trap._anchor.x>trap._bounds_at(y-trap.spawn_above_pixels).y,"Right wall attack mirrors the arm while preserving its root")
    check(absf(trap._anchor.y-(y-340.0))<.01,"Right tentacle uses the same above-fish emergence height")
    for i in 160:
        await physics_frame
        if game.dead: break
    check(game.dead and game.death_reason==&"tentacle","The visible fast slap kills a fish that remains in its actual silhouette")
    await create_timer(.025).timeout
    check(is_instance_valid(trap.corpse) and trap.corpse.visible,"Hit creates a visible fish death body instead of immediately hiding it")
    var start_y: float = trap.corpse.global_position.y
    var zoom: Vector2 = game.camera.zoom
    var flow = game.get_node("DeathFlow")
    check(not flow.overlay.visible,"Death screen waits while the fish is knocked down")
    await create_timer(.18).timeout
    check(maximum_shake>0.01,"Tentacle hit fires the existing brief screen shake")
    check(trap.corpse.global_position.y>start_y+120,"Slapped fish is driven downward with a strong initial impulse")
    check(not fish.get_node("Input").enabled and not fish.get_node("Movement").enabled,"Dead fish cannot continue swimming or blinking")
    await create_timer(.75).timeout
    check(game.camera.offset.is_zero_approx() and game.camera.zoom.is_equal_approx(zoom),"Shake returns to zero without altering established camera zoom")
    check(not trap.corpse.visible and flow.overlay.visible,"Fish leaves the screen before the existing death overlay appears")
    flow._retry.call_deferred()
    for i in 600:
        await process_frame
        if flow.state==flow.State.PLAYING and not game.dead: break
    check(not game.dead and game.player==game.soul,"Existing retry flow returns to the original ghost entry")
    check(not trap.attacking and is_zero_approx(trap.linger_elapsed) and not is_instance_valid(trap.corpse),"Retry clears pending tentacles, timer and fish death body")
    check(fish.get_node("Visual").visible and not stage.host.claimed,"Retry restores the fish's ordinary patrol state")
    print("OCEAN_SIDE_TENTACLE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
