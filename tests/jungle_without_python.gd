extends SceneTree
func _initialize(): run.call_deferred()
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    var layout = game.get_node("OceanLink/FishStage/JungleLayout")
    assert(layout.get_node_or_null("PythonEncounter")==null,"Removed snake must not be instantiated")
    assert(layout.get_node_or_null("Pinecones")==null,"Old snake-targeting cones must not remain active")
    layout.reset()
    assert(layout.get_node("InteractiveVines").get_child_count()==9)
    assert(layout.has_node("Squirrel"))
    print("JUNGLE_WITHOUT_PYTHON_OK")
    quit()
