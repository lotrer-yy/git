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
    var hive=layout.get_node("Beehives/Beehive07")
    var encounter=layout.get_node("BeeEncounter")
    hive.set_physics_process(false)
    check(encounter.get_child_count()==0,"No bees before a hive drops")
    body.global_position=hive.to_global(Vector2(0,167.5))+Vector2(0,50)
    hive._physics_process(.01)
    hive._physics_process(.4)
    check(encounter.get_child_count()==0,"Shaking remains a warning before the bee emerges")
    hive._physics_process(.51)
    check(encounter.get_child_count()==1,"Exactly one bee pops out when the hive drops")
    var bee=encounter.get_child(0)
    bee.set_physics_process(false)
    var spawn: Vector2=bee.global_position
    hive._physics_process(.3)
    check(encounter.get_child_count()==1 and bee.global_position==spawn,"Bee is independent of falling hive and never spawns twice")
    check(bee.visual.texture.resource_path.ends_with("/bee.png"),"Bee uses supplied artwork")
    game.camera.global_position=body.global_position
    for tick in 50: bee._physics_process(.01)
    check(bee.mode==bee.Mode.FLYING and bee.global_position.y<spawn.y,"Bee pops upward then enters flight")
    check(bee.flight.get_script().resource_path.ends_with("/flying_motion.gd"),"Reuses the hell demon flight code")
    bee.global_position=body.global_position+Vector2(-230,-180)
    bee.cooldown=0
    bee._physics_process(.01)
    check(bee.mode==bee.Mode.WINDUP,"Visible bee warns before attacking")
    var locked: Vector2=bee._aim
    body.global_position.x+=120
    bee._physics_process(.56)
    check(bee.mode==bee.Mode.DARTING and bee._aim==locked,"Dart locks the warning position instead of homing")
    bee._set_mode(bee.Mode.DARTING)
    bee._hit=false
    bee.global_position=body.global_position+Vector2(-90,-50)
    bee._dart_velocity=Vector2(950,0)
    bee._physics_process(.01)
    for tick in 10:
        if bee.mode==bee.Mode.DARTING: bee._physics_process(.01)
    check(bee._hit and not game.dead,"A sting knocks back but does not kill the squirrel")
    var ranged_hives: int=0
    for nest in layout.get_node("Beehives").get_children():
        ranged_hives+=nest.bee_variant
    check(ranged_hives==3,"Seven hives are evenly split: four dash bees and three ranged bees")
    var nest2=layout.get_node("Beehives/Beehive06")
    encounter._spawn(nest2)
    var bee2=encounter.enemies().back()
    bee2.set_physics_process(false)
    check(bee2.ranged and bee2.visual.texture.resource_path.ends_with("/bee2.png"),"Second hive type spawns the supplied second bee")
    bee2.global_position=body.global_position+Vector2(230,-180)
    bee2.lifetime=1
    bee2._set_mode(bee2.Mode.WINDUP)
    bee2._aim=body.global_position+Vector2(0,-50)
    var count_before: int=encounter.get_child_count()
    bee2._physics_process(.56)
    check(bee2.mode==bee2.Mode.RECOVERING and encounter.get_child_count()==count_before+1,"Second bee fires a stinger instead of dashing")
    check(encounter.enemies().size()==2,"Projectiles are excluded from flight separation neighbors")
    var needle=encounter.get_child(encounter.get_child_count()-1)
    needle.set_physics_process(false)
    var shot_velocity: Vector2=needle.velocity
    body.global_position.x+=100
    needle._physics_process(.01)
    check(is_equal_approx(needle.velocity.x,shot_velocity.x),"Stinger follows its launch arc without homing")
    needle.global_position=body.global_position+Vector2(-60,-50)
    needle.velocity=Vector2(680,0)
    needle._physics_process(.02)
    check(needle.is_queued_for_deletion() and not game.dead,"Stinger impact is nonlethal and consumes the projectile")
    game.die(&"impact")
    encounter._physics_process(.01)
    check(bee.is_queued_for_deletion() and not bee.visible,"Death immediately stops active bees")
    layout.reset()
    check(bee.is_queued_for_deletion() and not bee.visible and hive.state==hive.State.HANGING,"Replay removes bees and restores hives")
    print("JUNGLE_BEES_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
