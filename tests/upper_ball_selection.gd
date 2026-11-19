extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func tick():
    for i in 5:await physics_frame
    await process_frame
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    await create_timer(.85).timeout
    game.soul.position=game.demon.position+Vector2(-90,0)
    for i in 5:await physics_frame
    check(game.possession.request_possession(),"Possession starts")
    await create_timer(2.6).timeout
    var rig=game.get_node("Fork")
    var demon=game.demon
    demon.get_node("Movement").enabled=false
    demon.get_node("Input").enabled=false
    demon.velocity=Vector2.ZERO
    demon.global_position=game.to_global(Vector2(960,51000))
    var origin:Vector2=demon.global_position
    var balls=rig.targets
    balls[0].global_position=origin+Vector2(0,60)
    balls[1].global_position=origin+Vector2(20,-60)
    balls[2].global_position=origin+Vector2(200,-220)
    balls[3].global_position=origin+Vector2(-410,-220)
    await tick()
    check(rig.selected==balls[2],"A farther upper ball wins over closer balls below the model top")
    check(balls[0].state==0 and balls[1].state==0,"Lower and body-height balls stay unselected")
    balls[2].global_position=origin+Vector2(5000,-5000)
    await tick()
    check(rig.selected==balls[3],"Selection falls back to another eligible upper ball")
    balls[3].global_position=origin+Vector2(0,150)
    await tick()
    check(rig.selected==null,"No target is selected when all nearby balls are too low")
    var sprite:Sprite2D=demon.get_node("Visual/Sprite")
    var head_y:float=demon.to_global(sprite.position+Vector2(0,sprite.get_rect().position.y)).y
    balls[0].global_position=Vector2(origin.x,head_y-1)
    await tick()
    check(rig.selected==balls[0],"Ball just above the model top is eligible")
    balls[0].global_position.y=head_y+1
    await tick()
    check(rig.selected==null and balls[0].state==0,"Ball crossing below the model top immediately clears selection")
    balls[0].global_position.y=head_y-40
    await tick()
    check(rig.selected==balls[0],"Upper ball can be selected again")
    demon.global_position.y-=100
    await tick()
    check(rig.selected==null and balls[0].state==0,"Jumping above a ball removes its selection")
    rig.selected=balls[0]
    balls[0].set_state(1)
    rig._throw()
    check(not rig.flying and rig.held and rig.selected==null,"Input cannot throw at a stale lower-ball selection")
    print("UPPER_BALL_SELECTION_FAILURES=",failures.size())
    game.queue_free()
    for i in 3:await process_frame
    quit(0 if failures.is_empty() else 1)
