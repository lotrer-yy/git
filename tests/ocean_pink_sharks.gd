extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)

func run():
    var standalone = load("res://scenes/enemies/pink_shark_lane.tscn").instantiate()
    root.add_child(standalone)
    standalone.set_physics_process(false)
    var player := CharacterBody2D.new()
    root.add_child(player)
    var camera := Camera2D.new()
    root.add_child(camera)
    camera.make_current()
    standalone.configure(player,camera)
    standalone.running = true
    standalone.damage_enabled = true
    standalone.position.y = 10000
    standalone._physics_process(1)
    check(not standalone.started and is_zero_approx(standalone.distance) and not standalone.lead.visible,"Offscreen lanes wait without moving or exposing sharks")
    standalone.position.y = 0
    standalone._physics_process(0)
    check(standalone.started and standalone.lead.visible and is_equal_approx(standalone.lead.position.x,standalone.left_edge),"First visibility starts the first shark outside the current left camera edge")
    check(standalone.sharks.size()==4,"Each lane contains four individual sharks")
    check(is_equal_approx(standalone.lead.scale.x,.416),"Artwork and collider scale are 0.8 times the previous 0.52 scale")
    standalone.damage_enabled = false
    standalone.distance = 1300
    standalone._place_pair()
    var start: Vector2 = standalone.lead.position
    standalone._physics_process(1)
    check(is_equal_approx(standalone.lead.position.x,start.x+450),"Pink sharks move right near the controlled fish speed")
    check(absf(standalone.lead.position.y)<=14 and absf(standalone.lead.position.y-start.y)>5,"Water flow adds clearly changing vertical bob without shifting the fixed lane height")
    check(is_equal_approx(standalone.lead.position.x-standalone.follower.position.x,340),"The train maintains a front-to-back gap")
    for i in range(1,4):
        check(is_equal_approx(standalone.sharks[i-1].position.x-standalone.sharks[i].position.x,340),"All four sharks preserve their queue spacing")
    standalone.distance = standalone.right_edge-standalone.left_edge+standalone.following_gap*(standalone.sharks.size()-1)-.1
    standalone._place_pair()
    check(standalone.lead.position.x>standalone.right_edge,"The lead swims completely out before cycling")
    standalone._physics_process(.01)
    check(standalone.lead.position.x<standalone.left_edge+standalone.swim_speed*.01,"The next crossing starts beyond the left boundary")
    for shark in standalone.sharks:
        var sprite: AnimatedSprite2D = shark.get_node("Art")
        check(sprite.sprite_frames.get_frame_count(&"mouth")==6 and sprite.sprite_frames.get_animation_loop(&"mouth"),"All four sharks loop the six original mouth frames")
        for frame in range(6):
            sprite.frame = frame
            var pivot: Array = standalone._anchors[frame]
            var eye_anchor := sprite.to_global(Vector2(pivot[0],pivot[1])-Vector2(256,256)+sprite.offset)
            check(eye_anchor.distance_to(shark.global_position)<.01,"Every mouth frame preserves the registered body origin")
        check(shark.get_node("Collision") is CollisionPolygon2D,"Each shark has a separately editable polygon collider")
    standalone.direction = -1
    standalone.distance = 700
    standalone._place_pair()
    start = standalone.lead.position
    standalone._physics_process(1)
    check(is_equal_approx(standalone.lead.position.x,start.x-450) and standalone.lead.scale.x<0,"Reverse lanes move and face left with their colliders mirrored")
    check(is_equal_approx(standalone.follower.position.x-standalone.lead.position.x,340),"Reverse followers enter behind the leading shark")
    standalone.reset()
    check(not standalone.started and not standalone.lead.visible,"Reset rearms visibility triggering and hides the waiting train")
    check(not standalone.running and not standalone.damage_enabled,"Explicit reset stops and restores a lane")
    standalone.queue_free()
    player.queue_free()
    camera.queue_free()
    await process_frame

    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var stage = game.get_node("OceanLink/FishStage")
    var lanes = stage.get_node("PinkSharks").get_children()
    check(lanes.size()==4,"Formal ocean contains exactly four fixed lanes")
    for i in range(4):
        check(lanes[i].sharks.size()==4 and lanes[i].direction==(1 if i%2==0 else -1),"All sixteen sharks are distributed across alternating-direction lanes")
        check(not lanes[i].running and not lanes[i].damage_enabled,"Hell phase has no active ocean trap damage")
        if i>0: check(is_equal_approx(lanes[i-1].position.y-lanes[i].position.y,1832),"All four traps are evenly spaced over the ocean route")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    var fish = stage.fish
    check(absf(lanes[0].swim_speed-fish.get_node("Movement").max_horizontal_speed)<fish.get_node("Movement").max_horizontal_speed*.1,"Pink-shark speed stays within ten percent of the actual player's horizontal speed")
    fish.get_node("Patrol").stop()
    fish.get_node("Movement").enabled = false
    fish.get_node("Input").external_control = true
    stage.get_node("Shark").set_physics_process(false)
    stage.get_node("Octopus").set_physics_process(false)
    stage.get_node("SideTentacle").set_physics_process(false)
    var lane = lanes[0]
    fish.global_position = Vector2(960,lane.global_position.y)
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.set_follow_target(fish,true)
    stage._physics_process(0)
    lane._physics_process(0)
    lane.distance = 960-lane.left_edge
    lane._place_pair()
    check(lane.started and not lanes[1].started,"Only the newly visible lane begins; distant lanes remain ready")
    var blink = fish.get_node("Teleport")
    blink.anticipation_seconds = .12
    check(blink.try_teleport(Vector2.UP),"Fish can teleport away from a fixed trap")
    await create_timer(.05).timeout
    check(not game.dead and blink.is_invulnerable(),"Physical overlap during teleport immunity causes no pink-shark death")
    await create_timer(.35).timeout
    check(not game.dead,"The teleported fish escapes the lane safely")
    blink.reset()
    fish.global_position = lane.lead.global_position
    for i in range(12):
        await physics_frame
        if game.dead: break
    check(game.dead and game.death_reason==&"pink_shark","Real polygon contact kills the fish through the existing death flow")
    var before: float = lane.distance
    var sprite: AnimatedSprite2D = lane.lead.get_node("Art")
    var frame_before := sprite.frame
    await create_timer(.35,true,false,true).timeout
    check(lane.running and lane.distance>before+40,"Pink shark continues moving during the actual player-death freeze")
    check(sprite.frame!=frame_before and sprite.is_playing(),"Mouth animation also continues through player death")
    for other in lanes:
        check(other.running and not other.damage_enabled,"Death only suppresses repeated damage")
        for shark in other.sharks:
            check(shark.visible==other.started,"Death preserves active sharks and does not reveal waiting lanes")
    var preserved: float = lane.distance
    stage.get_node("Shark").reset()
    stage.get_node("Octopus").reset()
    check(is_equal_approx(lane.distance,preserved) and lane.running,"Resetting cyan shark and octopus does not affect pink-shark state")
    var flow = game.get_node("DeathFlow")
    for i in range(40):
        if flow.overlay.visible: break
        await create_timer(.05,true,false,true).timeout
    check(flow.overlay.visible,"Pink shark hit reaches the existing death screen after knockback")
    await flow._retry()
    await create_timer(.8).timeout
    for other in lanes:
        check(not other.running and not other.damage_enabled,"Explicit retry restores all lane phases without leaving active damage")
    print("OCEAN_PINK_SHARK_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
