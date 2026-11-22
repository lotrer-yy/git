extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func contains_physics(node: Node) -> bool:
    if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D: return true
    for child in node.get_children():
        if contains_physics(child): return true
    return false
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    var layout = game.get_node("OceanLink/FishStage/JungleLayout")
    layout.set_process(false)
    check(layout.global_transform==game.global_transform,"Layout aligns to the original long map even if OceanLink was moved in the editor")
    check(layout.vines.size()==9,"All nine supplied hanging vines are laid out separately")
    check(not contains_physics(layout.get_node("DecorativeTrunks")),"Large main vines never contain standing collision or interaction bodies")
    check(layout.get_node("DecorativeTrunks/MainVines").position==Vector2(0,20143),"Main vine sheet matches the author's reference position")
    check(not layout.get_node("DecorativeTrunks/MainVines").is_in_group("swing_vines"),"Main vine artwork cannot be grabbed as a rope")
    var layout_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/jungle/formal/layout_notes.json"))
    for vine in layout.vines:
        check(vine is SwingVine and vine.is_in_group("swing_vines"),"Only the hanging vine nodes expose the real grab interface")
        var region: Rect2 = vine.get_meta("source_region")
        var design: Dictionary = layout_data.designed_vines[layout.vines.find(vine)]
        check(vine.position==Vector2(design.anchor[0],design.anchor[1]) and vine.length==design.length,"Each rope matches the designed reachable swing route")
        check(is_equal_approx(vine.rope.segment_length*vine.rope.segments,vine.length),"Visual rope and interactive length stay aligned")
        check(not vine.is_physics_processing(),"Distant jungle ropes sleep during the hell opening")
    game.camera.global_position = Vector2(960,28500)
    layout._update_nearby()
    check(layout.vines[-1].is_physics_processing() and not layout.vines[0].is_physics_processing(),"Only ropes near the current camera run their solver")
    var vine = layout.vines[-2]
    var grip: Vector2 = vine.to_global(vine.rope.sample(vine.length*.65))
    check(vine.can_grab(grip),"The thin authored vine is actually grabbable")
    var probe := CharacterBody2D.new()
    var shape := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = 24
    capsule.height = 48
    shape.shape = capsule
    probe.add_child(shape)
    probe.collision_layer = 2
    probe.collision_mask = 16
    root.add_child(probe)
    probe.global_position = grip+Vector2(0,60)
    vine.catch(probe,Vector2(180,-20),probe.global_position-Vector2(100,0))
    check(vine.rider==probe,"Thin vine reuses the real rope catch implementation")
    vine._physics_process(.01)
    check(vine.release().is_finite() and vine.rider==null,"The rope can release its rider normally")
    probe.global_position = Vector2(960,22000)
    check(probe.move_and_collide(Vector2(0,1000),true)==null,"A body passes through the decorative main trunk instead of standing on it")
    layout.reset()
    check(vine.rider==null and vine.rope.load_index==-1,"Replay resets all vine interactions")
    print("FORMAL_JUNGLE_LAYOUT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
