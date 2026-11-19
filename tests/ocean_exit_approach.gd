extends SceneTree
const SURFACE=preload("res://modules/environment/hell_surface.gd")
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    await create_timer(.85).timeout
    game.soul.position=game.demon.position+Vector2(-90,0)
    for i in 5:await physics_frame
    check(game.possession.request_possession(),"Possession begins")
    await create_timer(2.6).timeout
    var link=game.get_node("OceanLink")
    check(not link.has_node("ApproachSteps"),"No extra approach platforms")
    check(not link.has_node("VolcanoMouth") and not link.has_node("ConnectingStrata"),"No imported artwork covers the original map")
    var reader=game.demon.get_node("Input")
    var motor=game.demon.get_node("Movement")
    reader.external_control=true
    reader.clear()
    game.demon.global_position=SURFACE.landing_on(game.get_node("Platforms/Breakable09"))+Vector2(0,-4)
    game.camera.set_follow_target(game.demon,true)
    motor.reset()
    await create_timer(.2).timeout
    check(game.demon.is_on_floor(),"Original last platform supports the player")
    reader.jump_pressed=true
    reader.jump_held=true
    for frame in 170:
        await physics_frame
        reader.move_axis=clampf((link.vortex.global_position.x-game.demon.global_position.x)/45.0,-1.0,1.0)
        if game.demon.velocity.y<0:reader.jump_pressed=false
        if link.stage!=link.Stage.HELL:break
    check(link.stage==link.Stage.CAPTURING,"A single real jump from the original platform reaches the original crater")
    print("EXIT_APPROACH_FAILURES=",failures.size()," POSITION=",game.demon.global_position)
    game.queue_free()
    for i in 3:await process_frame
    quit(0 if failures.is_empty() else 1)
