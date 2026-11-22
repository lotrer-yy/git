extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    body.set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    body.get_node("VineClimber").set_physics_process(false)
    game.camera.set_process(false)
    var climber=body.get_node("VineClimber")
    var spin=body.get_node("AirSpin")
    climber.detach(false)
    check(spin.active and spin.sprite.visible and not body.get_node("Visual/Sprite").visible,"Releasing a real vine starts the authored air-spin pose")
    var velocity_before: Vector2=body.velocity
    spin.sample(.25/spin.turns_per_second)
    check(spin.sprite.scale.x<.25 and absf(spin.sprite.global_rotation)<.001,"Quarter-turn narrows horizontally without rolling the body")
    spin.sample(.5/spin.turns_per_second)
    check(spin.sprite.flip_h!=body.get_node("Visual/Sprite").flip_h,"Half-turn reverses the horizontal facing")
    check(body.velocity==velocity_before,"Air animation never changes launch momentum")
    climber.adopt_vine(body.vine)
    spin._process(.01)
    check(not spin.active and body.get_node("Visual/Sprite").visible,"Catching a vine restores the normal sprite")
    climber.detach(false)
    game.die(&"bee")
    check(not spin.active and not spin.sprite.visible and body.get_node("Defeat").corpse.visible,"Defeat immediately replaces air spin with stunned expression")
    layout.reset()
    check(not spin.active and not spin.sprite.visible and body.get_node("Visual/Sprite").visible,"Replay restores the normal pose")
    print("SQUIRREL_AIR_SPIN_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
