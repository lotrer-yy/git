extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func ticks(count: int):
    for i in count: await physics_frame
    await process_frame
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var actor = game.demon
    var motor = actor.get_node("Movement")
    var reader = actor.get_node("Input")
    reader.enabled = true
    reader.external_control = true
    motor.enabled = true
    # The real demon body/motor traverses the authored right-hand ball cliff.
    # Keep the inactive test actor separate from the player's death flow.
    for direction in [1,-1]:
        actor.position = Vector2(1390 if direction==1 else 1630,50250)
        motor.reset()
        reader.clear()
        await ticks(40)
        check(actor.is_on_floor(),"Demon lands on the visible cliff roof")
        reader.move_axis = direction
        var blocked := false
        for i in 64:
            await physics_frame
            if i>20 and actor.is_on_wall() and absf(actor.velocity.x)<50: blocked=true
        check(not blocked,"Walking across the cliff center does not hit an invisible vertical face")
        check(actor.position.x>1590 if direction==1 else actor.position.x<1430,"Demon can cross the middle of the platform in both directions")
    actor.position = Vector2(1525,50250)
    motor.reset()
    reader.clear()
    await ticks(40)
    var feet_y: float = actor.position.y
    reader.jump_pressed = true
    reader.jump_held = true
    await ticks(2)
    reader.jump_pressed = false
    await ticks(12)
    check(actor.position.y<feet_y-70 and actor.velocity.y<0,"Demon can jump normally from the formerly stuck position")
    var space = game.get_world_2d().direct_space_state
    var side = PhysicsRayQueryParameters2D.create(Vector2(1200,50430),Vector2(1700,50430),8)
    var under = PhysicsRayQueryParameters2D.create(Vector2(1650,50780),Vector2(1650,50450),8)
    var side_hit = space.intersect_ray(side)
    var under_hit = space.intersect_ray(under)
    check(not side_hit.is_empty() and side_hit.collider==game.get_node("Terrain/BallCliff"),"The authored cliff side remains solid from outside")
    check(not under_hit.is_empty() and under_hit.collider==game.get_node("Terrain/BallCliff"),"The authored cliff underside still blocks upward entry")
    print("BALL_CLIFF_WALK_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
