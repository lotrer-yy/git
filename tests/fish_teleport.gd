extends SceneTree
var failures: Array[String] = []
var cast_count: int = 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func ticks(count: int = 5):
    for i in count: await physics_frame
    await process_frame
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var stage = game.get_node("OceanLink/FishStage")
    var fish = stage.fish
    var blink = fish.get_node("Teleport")
    var motor = fish.get_node("Movement")
    var reader = fish.get_node("Input")
    check(not blink.try_teleport(Vector2.RIGHT), "Unpossessed fish cannot cast")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    reader.external_control = true
    reader.clear()
    motor.enabled = false
    fish.get_node("Visual").reset()
    # Empty test space, away from authored geometry; only the test wall is added.
    var origin = Vector2(10000, 20000)
    fish.global_position = origin
    fish.velocity = Vector2.ZERO
    blink.teleported.connect(func(_a, _b): cast_count += 1)
    check(blink.try_teleport(Vector2(1,-1)), "Diagonal blink starts")
    check(not fish.get_node("Visual").visible, "Departure uses the supplied burst in place of the fish")
    check(not blink.try_teleport(Vector2.RIGHT), "Repeated presses cannot queue a second cast")
    await create_timer(.12).timeout
    check(absf(fish.global_position.distance_to(origin)-320)<.2, "Diagonal travel is normalized to 320 pixels")
    check(fish.get_node("Visual").visible and cast_count==1, "Arrival restores fish exactly once")
    check(fish.velocity.is_zero_approx(), "Arrival clears previous velocity")
    check(not blink.try_teleport(Vector2.RIGHT), "Cooldown blocks immediate recast")
    await create_timer(.8).timeout
    var wall = StaticBody2D.new()
    wall.collision_layer = 16
    wall.collision_mask = 0
    var shape = CollisionShape2D.new()
    var rectangle = RectangleShape2D.new()
    rectangle.size = Vector2(20,1000)
    shape.shape = rectangle
    wall.add_child(shape)
    game.add_child(wall)
    wall.global_position = origin+Vector2(180,0)
    fish.global_position = origin
    await ticks()
    check(blink.try_teleport(Vector2.RIGHT), "Blink can approach a wall")
    await create_timer(.12).timeout
    check(fish.global_position.x>origin.x+100 and fish.global_position.x<origin.x+140, "Whole fish collision stops before wall rather than crossing it")
    check(not fish.test_move(fish.global_transform,Vector2.ZERO), "Arrival is outside the wall")
    blink.reset()
    check(not blink.try_teleport(Vector2.RIGHT) and is_zero_approx(blink.cooldown_remaining), "Blocked blink neither spends cooldown nor animates")
    check(not blink.is_invulnerable(), "A blocked teleport grants no invulnerability")
    fish.global_position = origin
    blink.reset()
    fish.get_node("Visual/Sprite").flip_h = false
    var key = InputEventKey.new()
    key.physical_keycode = KEY_SHIFT
    key.location = KEY_LOCATION_LEFT
    key.pressed = true
    root.push_input(key,true)
    await create_timer(.12).timeout
    check(absf(fish.global_position.x-(origin.x-320))<.2, "Shift without WASD blinks along left-facing artwork")
    blink.reset()
    fish.global_position = origin
    reader.move_axis = 1
    key.echo = true
    root.push_input(key,true)
    await create_timer(.08).timeout
    check(fish.global_position.distance_to(origin)<.2, "Holding Shift does not auto-repeat")
    key.echo = false
    key.location = KEY_LOCATION_RIGHT
    root.push_input(key,true)
    await create_timer(.08).timeout
    check(fish.global_position.distance_to(origin)<.2, "Right Shift matches existing possession key restriction")
    check(blink.try_teleport(Vector2.UP), "Next cast can start")
    stage.reset()
    var reset_position: Vector2 = fish.global_position
    await create_timer(.12).timeout
    check(fish.global_position.distance_to(reset_position)<20 and not blink.enabled and not blink._busy, "Reset cancels pending teleport and clears control")
    check(blink._effects.is_empty() and fish.get_node("Visual").visible, "Reset removes skill bursts and restores visibility")
    print("FISH_TELEPORT_FAILURES=",failures.size())
    game.queue_free()
    await ticks(3)
    quit(0 if failures.is_empty() else 1)
