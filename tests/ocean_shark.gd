extends SceneTree
var failures: Array[String] = []
var simulation_time: float = 0.0
var locks: Array[float] = []
var dashes: int = 0
var hits: int = 0

func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func advance(shark: Node,seconds: float):
    for i in ceili(seconds/.01):
        simulation_time += .01
        shark._physics_process(.01)
        if shark.state==shark.State.LOCKING: shark._follow_lock_view()

func run():
    var player := CharacterBody2D.new()
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = 24
    capsule.height = 48
    collision.name = "Collision"
    collision.shape = capsule
    player.add_child(collision)
    root.add_child(player)
    var view := Camera2D.new()
    root.add_child(view)
    view.make_current()
    var shark = load("res://scenes/enemies/ocean_shark.tscn").instantiate()
    root.add_child(shark)
    shark.configure(player,view)
    shark.enabled = true
    shark.set_physics_process(false)
    shark.set_process(false)
    shark.lock_started.connect(func():locks.append(simulation_time))
    shark.dash_started.connect(func():dashes+=1)
    advance(shark,1.99)
    check(shark.state==shark.State.WAITING and not shark.visible,"No shark appears before two active seconds")
    advance(shark,.03)
    check(shark.state==shark.State.LOCKING and shark.visible,"Two seconds starts the visible locking phase")
    advance(shark,.3)
    var screen_offset: Vector2 = shark.global_position-shark._view_rect().position
    view.global_position += Vector2(200,-120)
    shark._follow_lock_view()
    check((shark.global_position-shark._view_rect().position).is_equal_approx(screen_offset),"Locking shark follows the moving camera without screen drift")
    player.position += Vector2(80,0)
    advance(shark,.4)
    check(shark.locked_point.is_equal_approx(collision.global_position),"Locking keeps aiming at the player's actual collider")
    advance(shark,.24)
    check(shark.state==shark.State.LOCKING and dashes==0,"Lock lasts one second")
    advance(shark,.06)
    check(shark.state==shark.State.DASHING and dashes==1,"Dash begins after the one-second lock")
    var direction: Vector2 = shark.dash_direction
    player.global_position += direction.orthogonal()*500
    var origin: Vector2 = shark.global_position
    advance(shark,.08)
    check(shark.dash_direction.is_equal_approx(direction),"Player can dodge a committed dash; the shark does not bend after firing")
    check(shark.global_position.distance_to(origin)>60,"Dash is fast and moves continuously")
    advance(shark,5.1)
    check(locks.size()==2 and absf(locks[1]-locks[0]-6.0)<.03,"The six-second cadence is measured between appearances")
    shark.dash_direction = Vector2.RIGHT
    player.global_position = Vector2.ZERO
    check(shark._touches_target(Vector2(-700,0),Vector2(700,0)),"Swept body contact detects a fast crossing without tunneling")
    check(not shark._touches_target(Vector2(-700,170),Vector2(700,170)),"The cyan aura and distant trails cannot damage the player")
    shark._face(Vector2.LEFT)
    check((shark.visual.to_global(Vector2.UP)-shark.global_position).y<0,"Left-facing shark remains upright")
    for animation in [&"windup",&"dash"]:
        shark.sprite.animation = animation
        for frame in range(3):
            shark.sprite.frame = frame
            shark._register_frame()
            check(shark.sprite.material.get_shader_parameter("clean_edges"),"Dash frames enable clean silhouettes instead of the blue aura")
            var index: int = frame+(3 if animation==&"dash" else 0)
            var pivot: Array = shark._anchors.frames[index].pivot
            var texture: Texture2D = shark.sprite.sprite_frames.get_frame_texture(animation,frame)
            var center: Vector2 = shark.sprite.to_global(Vector2(pivot[0],pivot[1])-texture.get_size()*.5+shark.sprite.offset)
            check(center.distance_to(shark.global_position)<.01,"All six author frames preserve their registered body pivot")
    shark.enabled = false
    check(not shark.visible and shark.state==shark.State.WAITING and is_zero_approx(shark.cycle_elapsed),"Disable cancels the pending attack and clock")
    shark.enabled = true
    shark.player_hit.connect(func(_direction):hits+=1)
    view.global_position = Vector2.ZERO
    player.global_position = Vector2.ZERO
    shark.global_position = Vector2(-100,0)
    shark.dash_speed = 80
    shark.show()
    shark._begin_dash()
    advance(shark,1.2)
    check(hits==1 and shark.visible and shark.state==shark.State.DASHING,"A hit is reported once while the shark keeps charging beyond the former timeout")
    var hit_position: Vector2 = shark.global_position
    shark.enabled = false
    advance(shark,.3)
    check(shark.visible and shark.global_position.x>hit_position.x+20,"Disabling new attacks does not interrupt an ongoing charge")
    advance(shark,(shark._view_rect().size.x+1000)/shark.dash_speed)
    check(not shark.visible and shark.state==shark.State.WAITING and shark._fully_offscreen(),"Shark disappears only after its complete graphic leaves the viewport")
    shark.enabled = true
    player.global_position = Vector2(0,500)
    shark.global_position = Vector2.ZERO
    shark.state = shark.State.DASHING
    shark.state_elapsed = 0
    shark.dash_direction = Vector2.RIGHT
    shark._face(Vector2.RIGHT)
    shark.show()
    advance(shark,1.2)
    check(shark.visible and shark.state==shark.State.DASHING and hits==1,"A missed charge also keeps moving without a fixed timeout")
    shark.reset()
    player.global_position = Vector2.ZERO
    for side in [-1,1]:
        shark._side = -side
        shark._begin_lock()
        shark.state_elapsed = .2
        shark._follow_lock_view()
        var anchor: Vector2 = shark._view_rect().position+shark._screen_anchor
        check((shark.global_position.x-anchor.x)*-side>20,"Both entrance directions overshoot slightly before settling")
        shark.state_elapsed = .36
        shark._follow_lock_view()
        var floating_y: float = shark.global_position.y
        check(absf(shark.global_position.x-anchor.x)<.01,"Entrance rebounds smoothly to its screen anchor")
        shark.state_elapsed = .55
        shark._follow_lock_view()
        check(absf(shark.global_position.y-anchor.y)<=shark.bob_pixels and absf(shark.global_position.y-floating_y)>2,"Locking includes a small changing water bob")
        shark.state_elapsed = shark.lock_seconds
        shark._follow_lock_view()
        var pull: Vector2 = shark.global_position-anchor
        var aim: Vector2 = (player.global_position-anchor).normalized()
        check(pull.dot(aim)<-40 and absf(pull.cross(aim))<.01,"Windup retreats opposite the aimed direction on both sides")
        var launch_position: Vector2 = shark.global_position
        shark._begin_dash()
        check(shark.global_position.is_equal_approx(launch_position),"Dash begins at the pulled-back position without snapping")
    shark.queue_free()
    player.queue_free()
    view.queue_free()
    await process_frame

    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var stage = game.get_node("OceanLink/FishStage")
    var fish = stage.fish
    var enemy = stage.get_node("Shark")
    check(not enemy.enabled and not enemy.visible,"Shark is inactive during the hell phase")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    fish.get_node("Patrol").stop()
    fish.get_node("Movement").enabled = false
    fish.get_node("Input").external_control = true
    fish.position = Vector2(960,38000)
    stage.get_node("SideTentacle").set_physics_process(false)
    var blink = fish.get_node("Teleport")
    blink.anticipation_seconds = .12
    check(blink.try_teleport(Vector2.UP) and blink.is_invulnerable(),"Successful teleport grants immunity immediately during preparation")
    game.die(&"shark")
    game.die(&"tentacle")
    check(not game.dead,"Central death handling rejects damage during teleport")
    check(not enemy._touches_target(fish.global_position-Vector2(500,0),fish.global_position+Vector2(500,0)),"Shark sweeps ignore an invulnerable player")
    await create_timer(.15).timeout
    check(not blink._busy and blink.is_invulnerable(),"Arrival keeps immunity while the arrival burst is visible")
    game.die(&"impact")
    check(not game.dead,"Arrival protection also rejects environmental damage")
    await create_timer(.22).timeout
    check(not blink.is_invulnerable(),"Teleport protection expires after arrival")
    blink.reset()
    check(blink.try_teleport(Vector2.DOWN),"A new teleport can begin after reset")
    blink.reset()
    check(not blink.is_invulnerable(),"Reset cancels immunity together with the pending teleport")
    blink.anticipation_seconds = .04
    fish.position = Vector2(960,38000)
    enemy.reset()
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.set_follow_target(fish,true)
    var octopus = stage.get_node("Octopus/First")
    var ink = stage.get_node("InkOverlay")
    var prepared_octopus := false
    stage.get_node("PinkSharks/Lane1").position.y = fish.position.y
    # 这里仅观察粉鲨鱼续游，致死碰撞由粉鲨鱼独立测试覆盖。
    stage.get_node("PinkSharks/Lane1").player_hit.disconnect(Callable(stage,"_on_pink_shark_hit"))
    Engine.time_scale = 4.0
    for i in 360:
        await physics_frame
        if not prepared_octopus and enemy.state==enemy.State.LOCKING and enemy.state_elapsed>.7:
            octopus.enabled = true
            octopus._appear(fish.global_position+Vector2(300,-100))
            octopus._visit_elapsed = 1.4
            octopus._change_state(octopus.State.SWIMMING)
            ink.splash()
            prepared_octopus = true
        if game.dead:break
    Engine.time_scale = 1.0
    check(game.dead and game.death_reason==&"shark","Real ocean-stage dash hits the controlled fish")
    check(not enemy.enabled and not enemy.visible and enemy.state==enemy.State.WAITING,"Death immediately removes the attacking shark")
    check(prepared_octopus and octopus.enabled and octopus.visible and octopus._visit_elapsed>1.4,"An actual shark hit keeps the octopus alive at its existing visit progress")
    check(ink.visible,"Shark impact does not erase existing screen ink")
    var octopus_elapsed: float = octopus._visit_elapsed
    var pink_lane = stage.get_node("PinkSharks/Lane1")
    var pink_distance: float = pink_lane.distance
    var death_position: Vector2 = enemy.global_position
    await create_timer(.16,true,false,true).timeout
    check(enemy.global_position==death_position,"Shark stops moving while the death animation freezes the level")
    check(octopus.visible and octopus._visit_elapsed>octopus_elapsed+.1,"Octopus animation and movement continue through the real death freeze")
    check(pink_lane.running and pink_lane.distance>pink_distance+15 and pink_lane.lead.visible and pink_lane.follower.visible,"Cyan-shark death leaves the fixed pink-shark pair running and visible")
    var knockback = stage.get_node("SharkKnockback")
    check(is_instance_valid(knockback.corpse) and not fish.get_node("Visual").visible,"Shark creates an independent impact animation using the original fish art")
    var corpse: Sprite2D = knockback.corpse
    check(corpse.global_position.x>knockback._origin.x+50 and corpse.global_position.y<knockback._origin.y-30,"Impact launches the fish sideways and upward")
    check(absf(corpse.global_rotation-knockback._rotation)>.1,"The launched fish rotates without being squashed")
    var saved_scale := corpse.global_scale
    await create_timer(.4,true,false,true).timeout
    var before_fall := corpse.global_position
    await create_timer(.15,true,false,true).timeout
    check(corpse.global_position.y>before_fall.y+20,"Fish turns over the apex and accelerates downward along the parabola")
    check(corpse.global_scale.is_equal_approx(saved_scale),"Impact keeps the character artwork at its original proportions")
    check(not enemy.visible and enemy.state==enemy.State.WAITING,"The hitting shark remains hidden throughout the death sequence")
    var flow = game.get_node("DeathFlow")
    for i in 40:
        if flow.overlay.visible:break
        await create_timer(.05,true,false,true).timeout
    check(flow.overlay.visible,"Existing death screen appears after the fish falls")
    await flow._retry()
    await create_timer(.8).timeout
    check(not game.dead and not stage.active and not enemy.enabled and not enemy.visible and is_zero_approx(enemy.cycle_elapsed),"Retry restores the original entry and clears all shark state")
    check(not is_instance_valid(knockback.corpse) and fish.get_node("Visual").visible,"Retry removes the impact corpse and restores the fish artwork")
    check(not octopus.enabled and not octopus.visible and not octopus._finishing_visit and not ink.visible,"Retry clears the preserved octopus and screen ink")
    print("OCEAN_SHARK_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
