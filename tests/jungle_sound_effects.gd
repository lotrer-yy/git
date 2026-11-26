extends SceneTree
var failures: Array[String] = []
var counts: Dictionary = {}
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func count(cue: StringName) -> int: return counts.get(cue,0)
func run():
    root.get_node("Sfx").played.connect(func(cue):counts[cue]=counts.get(cue,0)+1)
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    game.get_node("RisingLava").process_mode = Node.PROCESS_MODE_DISABLED
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed = true
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab","JungleHandoff"]:
        stage.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
    var shore = stage.get_node("ShoreExit")
    shore.set_physics_process(false)
    var fish = stage.fish
    fish.get_node("Movement").enabled = false
    fish.get_node("Input").external_control = true
    fish.get_node("Input").clear()
    fish.position = Vector2(960,shore.surface_y-2)
    fish.velocity = Vector2(0,-420)
    shore._physics_process(.01)
    check(count(&"fish_shore_leap")==0,"Surface contact without upward input stays silent")
    fish.get_node("Input").up_held = true
    shore._physics_process(.01)
    shore._physics_process(.01)
    check(count(&"fish_shore_leap")==1,"Actual fish leap sounds once")
    var layout = stage.get_node("JungleLayout")
    layout.set_process(false)
    for vine in layout.vines: vine.set_physics_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    var body = layout.get_node("Squirrel")
    var climber = body.get_node("VineClimber")
    var motor = body.get_node("Movement")
    var reader = body.get_node("Input")
    body.get_node("Host").take_control()
    game.player = body
    body.set_physics_process(false)
    climber.set_physics_process(false)
    motor.set_physics_process(false)
    reader.external_control = true
    reader.clear()
    check(count(&"vine_grab")==0,"Initial possession of hanging squirrel is not a new catch")
    climber.detach(true)
    check(count(&"vine_release")==1 and count(&"squirrel_jump")==1,"Jumping from vine sounds release and jump once")
    climber.detach(true)
    check(count(&"vine_release")==1,"Repeated release without vine stays silent")
    body.global_position = Vector2(10000,20000)
    motor._physics_process(.01)
    reader.jump_pressed = true
    reader.jump_held = true
    motor._physics_process(.01)
    check(count(&"squirrel_jump")==2,"Real extra air jump sounds")
    reader.clear()
    motor.reset()
    body.global_position = Vector2(960,29300)
    body.velocity = Vector2(0,300)
    for i in 240:
        await physics_frame
        motor._physics_process(1.0/120)
        if body.is_on_floor(): break
    check(body.is_on_floor() and count(&"squirrel_land")==1,"Actual ground landing sounds once")
    for i in 5: motor._physics_process(.01)
    check(count(&"squirrel_land")==1,"Standing on ground does not repeat landing")
    reader.jump_pressed = true
    reader.jump_held = true
    motor._physics_process(.01)
    check(count(&"squirrel_jump")==3,"Real ground jump sounds as well")
    reader.clear()
    var vine = layout.vines[-2]
    body.global_position = vine.to_global(vine.rope.sample(vine.length*.6))-climber.hands_offset
    check(climber.try_grab() and count(&"vine_grab")==1,"Actual vine catch sounds once")
    climber.detach(false)
    check(count(&"vine_release")==2 and count(&"squirrel_jump")==3,"Plain release sounds throw without inventing a jump")
    var encounter = layout.get_node("BeeEncounter")
    encounter.set_physics_process(false)
    var hive = layout.get_node("Beehives/Beehive07")
    for node in layout.get_node("Beehives").get_children(): node.set_physics_process(false)
    body.global_position = hive.to_global(Vector2(0,hive.texture.get_height()*.5))+Vector2(0,50)
    hive._physics_process(.01)
    check(count(&"hive_hit")==1,"Hive trigger sounds once")
    hive._physics_process(hive.warning_seconds+.01)
    var first = encounter.get_child(0)
    first.set_physics_process(false)
    check(first.get_node("Buzz").playing and first.get_node("Buzz").stream.loop,"Spawned bee starts its own looping buzz")
    encounter._spawn(layout.get_node("Beehives/Beehive06"))
    var second = encounter.get_child(1)
    second.set_physics_process(false)
    second.global_position = first.global_position+Vector2(100,0)
    game.camera.set_process(false)
    game.camera.global_position = body.global_position
    game.camera.offset = Vector2.ZERO
    encounter.fire_stinger(body.global_position,body.global_position+Vector2(200,0))
    check(count(&"bee_stinger")==1,"Actual spawned stinger sounds")
    encounter.fire_stinger(body.global_position+Vector2(10000,0),body.global_position)
    check(count(&"bee_stinger")==1,"Rejected offscreen stinger does not sound")
    first.deflect(body.global_position)
    first.deflect(body.global_position)
    check(count(&"bee_defeat")==1 and not first.get_node("Buzz").playing,"Defeated bee stops buzzing and sounds death once")
    check(second.get_node("Buzz").playing,"Other bee keeps its own buzz")
    game.die(&"bee")
    game.die(&"bee")
    check(count(&"squirrel_death")==1 and count(&"death")==0,"Squirrel death uses only new death clip once")
    check(second.get_node("Buzz").playing,"Player death does not stop surviving bee buzz")
    encounter.reset()
    await process_frame
    check(not is_instance_valid(second),"Reset removes bee and its audio together")
    await create_timer(2.8,true,false,true).timeout
    game.queue_free()
    for i in 3: await process_frame
    print("JUNGLE_SOUND_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
