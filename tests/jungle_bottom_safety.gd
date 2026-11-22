extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    var stage = game.get_node("OceanLink/FishStage")
    var layout = stage.get_node("JungleLayout")
    layout.set_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    var body = layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    body.get_node("VineClimber").detach(false)
    body.get_node("VineClimber").set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    body.set_physics_process(false)
    for vine in layout.vines: vine.set_physics_process(false)
    await physics_frame
    var floor = layout.get_node("JungleFloor")
    check(floor.global_position==game.global_position,"Jungle floor remains aligned to the original map independently of OceanLink offset")
    var floor_shape = floor.get_node("Collision")
    var bank = stage.get_node("OriginalShoreBank/Collision")
    var bank_top: float = bank.to_global(Vector2(0,-bank.shape.size.y*.5)).y
    check(is_equal_approx(floor_shape.to_global(Vector2(0,-floor_shape.shape.size.y*.5)).y,bank_top),"Extended floor preserves the editor-adjusted original bank standing height")
    await physics_frame
    for x in [-1500,-600,-220,-1,0,32,960,1888,1920,2140,2520,3400]:
        body.global_position = Vector2(x,29100)
        var hit = body.move_and_collide(Vector2(0,3000))
        check(hit!=null and hit.get_collider() in [floor,stage.get_node("OriginalShoreBank")],"Continuous bottom catches fast falls even in both outside swing zones")
        body.move_and_collide(Vector2(0,10))
        check(absf(body.global_position.y-bank_top)<1,"Squirrel cannot fall below the jungle shore")
    body.global_position = Vector2(-400,29000)
    check(body.move_and_collide(Vector2(-300,0),true)==null,"Bottom closure does not restore a hard side wall")
    var fish: CharacterBody2D = stage.fish
    fish.global_position = Vector2(960,29550)
    var up_hit = fish.move_and_collide(Vector2(0,-1000),true)
    check(up_hit==null,"New squirrel-only floor cannot block the fish's ascent out of water")
    check((fish.collision_mask & 32)==0,"Fish does not collide with the jungle-only floor layer")
    body.global_position = Vector2(960,22000)
    check(body.move_and_collide(Vector2(0,1000),true)==null,"Thick main vine artwork is still not a standing surface")
    print("JUNGLE_BOTTOM_SAFETY_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
