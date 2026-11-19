extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)

func make_game() -> Node2D:
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    game.get_node("Fork").set_physics_process(false)
    for actor in [game.soul, game.demon]:
        actor.get_node("Movement").enabled = false
        actor.get_node("Input").enabled = false
        actor.velocity = Vector2.ZERO
    return game

func run() -> void:
    # Approach the actual scene geometry using the real collision bodies.
    for actor_name in ["Soul", "Demon"]:
        var game = await make_game()
        var actor = game.get_node(actor_name)
        game.player = actor
        actor.get_node("Visual").show()
        if actor_name=="Demon":
            actor.get_node("Visual").set_process(false)
            actor.get_node("Visual").scale=Vector2(1.3,.72)
        # The visible right-facing spike is at (674.5, 50840).
        actor.global_position = game.to_global(Vector2(800,50892))
        for i in 60:
            actor.move_and_collide(Vector2(-4,0))
            await physics_frame
            await process_frame
            if game.dead: break
        check(game.dead and game.death_reason==&"impact", actor_name+" dies on physical contact with the side spike")
        if game.dead:
            var proportions_ok:=true
            for i in 480:
                if game.get_node("DeathFlow").overlay.visible: break
                await process_frame
                var corpse=game.get_node("DeathFlow").death_animation.corpse
                if actor_name=="Demon" and is_instance_valid(corpse):
                    proportions_ok=proportions_ok and absf(corpse.scale.x-corpse.scale.y)<.001
            check(proportions_ok,"Side-spike death keeps original artwork proportions throughout the animation")
            check(game.get_node("DeathFlow").overlay.visible, "Side spike uses the normal death interface")
        game.queue_free()
        for i in 3: await process_frame

    var game = await make_game()
    game.player = game.demon
    # Safe top surface above the same spike must remain safe.
    game.demon.global_position = game.to_global(Vector2(615,50762))
    for i in 12:
        await physics_frame
        await process_frame
    check(not game.dead, "Standing on the rock top above the spike remains safe")
    # Inactive actor touching the spike must not kill the controlled actor.
    game.soul.global_position = game.to_global(Vector2(700,50892))
    for i in 12:
        await physics_frame
        await process_frame
    check(not game.dead, "An inactive actor does not trigger player death")
    game.queue_free()
    for i in 3: await process_frame
    print("SIDE_SPIKE_DEATH_FAILURES=", failures.size())
    quit(0 if failures.is_empty() else 1)
