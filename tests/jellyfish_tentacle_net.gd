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
    var boss = stage.get_node("JellyfishBoss")
    var net = stage.get_node("BossTentacleNet")
    net.set_physics_process(false)
    net.enabled = true
    advance(net,2)
    check(net.rows.is_empty(),"Tentacle nets wait until the giant boss has appeared")
    boss.state = boss.State.PRESENT
    advance(net,.01)
    check(net.rows.size()==1 and net.rows[0].arms.size()==2,"Boss lays two crossing tendrils from opposing walls")
    var row: Dictionary = net.rows[0]
    check(row.arms[0].thickness==144 and row.arms[0]._shapes[0].shape.radius==72,"Boss tendril and physical collision are both four times thicker")
    check(row.node.position.y>fish.position.y,"The row starts below the fish, leaving the upward route open")
    check(not row.arms[0].dangerous and row.arms[0].body.collision_layer==0,"Visible windup does not create an invisible dangerous wall")
    var initial_root: Vector2 = row.node.global_position
    fish.get_node("Teleport")._invulnerability_remaining = 10
    fish.position.y -= 80
    advance(net,.25)
    check(row.node.global_position==initial_root,"Windup keeps its root fixed inside the wall")
    var aimed = row.arms[0]
    var aimed_center: Vector2 = aimed.to_local(fish.get_node("Collision").global_position)
    var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(aimed_center,aimed.start,aimed.finish)
    check(nearest.distance_to(aimed_center)<1,"Windup aims through the fish instead of underneath it")
    var blink_aims := [row.arms[0].finish,row.arms[1].finish]
    var before_blink: Vector2 = fish.global_position
    fish.position.x += 120
    fish.get_node("Teleport").teleported.emit(before_blink,fish.global_position)
    advance(net,.05)
    check(row.arms[0].finish==blink_aims[0] and row.arms[1].finish==blink_aims[1],"Blink breaks both current and delayed tendril aim instead of tracking its destination")
    check(row.aim_frozen and net._blink_grace>0,"Blink also grants a brief pause before another aimed wave")
    var locked_finish: Vector2
    advance(net,.24)
    locked_finish = aimed.finish
    fish.position.x += 180
    advance(net,.10)
    check(aimed.finish==locked_finish,"Aim locks before the strike so the player can dodge")
    advance(net,.9)
    check(row.arms[0].dangerous and row.arms[1].dangerous,"Both wall-to-wall strokes become live after their readable windup")
    check(row.arms[0].centerline[-1].distance_to(row.arms[0].finish)<.1,"The straight original stretches all the way into the opposite wall")
    var fixed: Vector2 = row.node.global_position
    game.camera.global_position += Vector2(300,-1000)
    fish.position.y -= 400
    advance(net,.01)
    check(row.node.global_position==fixed,"Finished net stays in its world water section when fish and camera move")
    advance(net,.4)
    check(net.rows.size()==2 and net.rows[1].node.position.y<row.node.position.y,"Further ascent progressively adds another row behind the fish")
    var arm = row.arms[0]
    var middle: Vector2 = arm.to_global(arm.centerline[12])
    check(arm.touches(middle,24),"Damage follows the actual visible tendril geometry")
    check(not arm.touches(middle+Vector2(0,-150),24),"Water well above the net remains safe")
    fish.global_position = middle+Vector2(0,-130)
    await physics_frame
    await physics_frame
    var blocked = fish.move_and_collide(Vector2(0,260),true)
    check(blocked!=null,"A full fish-body downward sweep is blocked by the formed net")
    var highest := INF
    for existing in net.rows:
        for tendril in existing.arms:
            highest = minf(highest,tendril.to_global(tendril.start).y)
            highest = minf(highest,tendril.to_global(tendril.finish).y)
    fish.global_position = Vector2(960,highest-200)
    var upward = fish.move_and_collide(Vector2(0,-120),true)
    check(upward==null,"The escape route above the fish remains open")
    var teleport = fish.get_node("Teleport")
    teleport._invulnerability_remaining = 1
    teleport.enabled = true
    fish.global_position = middle
    advance(net,.01)
    check(not game.dead,"Teleport immunity is respected by electric contact")
    teleport._invulnerability_remaining = 0
    advance(net,.01)
    check(game.dead and game.death_reason==&"jellyfish_net","Contact with energized original art enters the real death flow")
    await create_timer(.08,true,false,true).timeout
    check(is_instance_valid(stage.get_node("SharkKnockback").corpse),"Net death plays the real fish impact animation instead of jumping straight to the overlay")
    stage.reset()
    check(net.rows.is_empty() and not net.enabled,"Retry removes every old tendril, collider and electric strand")
    print("JELLYFISH_NET_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
