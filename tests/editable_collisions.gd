extends SceneTree
var count := 0
func inspect(node: Node, actor: bool = false) -> void:
    actor = actor or node is CharacterBody2D
    if node is CollisionPolygon2D:
        assert(node.polygon.size() >= 3)
        count += 1
    if node is CollisionShape2D:
        assert(actor, "Map collision must be an editable polygon: " + str(node.get_path()))
    for child in node.get_children():inspect(child,actor)
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    var collision: CollisionPolygon2D = game.get_node("Platforms/Static01/Collision")
    var edited := collision.polygon
    edited[0] += Vector2(7, -3)
    collision.polygon = edited
    root.add_child(game)
    assert(collision.polygon == edited, "Startup overwrote the edited polygon")
    inspect(game)
    assert(count >= 50)
    assert(game.get_node("Platforms").get_child_count() == game.platforms.size())
    print("EDITABLE_POLYGONS=", count, " STARTUP_PRESERVES_EDITS=PASS")
    game.queue_free()
    await process_frame
    await process_frame
    quit()
