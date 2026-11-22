extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func advance(net: Node,seconds: float):
    for i in ceili(seconds/.01): net._physics_process(.01)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed = true
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    var fish = stage.fish
    fish.get_node("Patrol").stop()
    fish.get_node("Movement").enabled = false
    fish.position = Vector2(960,36000)
    for child in ["Shark","Octopus","SideTentacle","PinkSharks","JellyfishBoss"]: stage.get_node(child).process_mode = Node.PROCESS_MODE_DISABLED
    fish.get_node("Movement").enabled=true
    fish.get_node("Input").enabled=true
    fish.get_node("Teleport").enabled=true
    var stun=fish.get_node("Stun")
    stun.set_physics_process(false)
    var texture: Texture2D=fish.get_node("Visual/Sprite").texture
    check(stun.apply(Vector2.RIGHT),"Wall tentacle can apply nonlethal stun")
    check(not game.dead and not fish.get_node("Teleport").try_teleport(Vector2.RIGHT),"Stun is nonlethal and temporarily pauses blinking")
    check(fish.get_node("Visual/Sprite").texture==texture,"Stun keeps the exact original fish artwork")
    check(not stun.apply(Vector2.LEFT),"Repeated contact cannot stack stun")
    for tick in 60: stun._physics_process(.01)
    check(fish.get_node("Movement").enabled and fish.get_node("Input").enabled and fish.get_node("Teleport").enabled,"Movement and blink restore after the short stun")
    check(stun.is_protected(),"Recovery retains brief protection from wall tentacles")
    for tick in 130: stun._physics_process(.01)
    check(not stun.is_protected() and fish.get_node("Visual/Sprite").material==null,"Protection and spiral eye expire cleanly")
    check(stun.apply(Vector2.LEFT),"A later separate attack can stun again")
    stage.reset()
    check(not stun.is_protected() and not fish.get_node("Host").claimed,"Replay clears all stun state")
    print("FISH_TENTACLE_STUN_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
