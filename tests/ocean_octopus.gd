extends SceneTree
var failures: Array[String] = []
var shots: int = 0
var appearances: Array[float] = []
var clock: float = 0.0

func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func advance(enemy: Node,seconds: float,ascent_speed: float = 0.0):
    for i in ceili(seconds/.01):
        clock += .01
        enemy.target.global_position.y -= ascent_speed*.01
        enemy.camera.global_position.y -= ascent_speed*.01
        enemy._physics_process(.01)

func run():
    var player := CharacterBody2D.new()
    root.add_child(player)
    var camera := Camera2D.new()
    root.add_child(camera)
    camera.make_current()
    var enemy = load("res://scenes/enemies/ocean_octopus.tscn").instantiate()
    root.add_child(enemy)
    enemy.configure(player,camera)
    enemy.enabled = true
    enemy.set_physics_process(false)
    enemy.set_process(false)
    enemy.ink_sprayed.connect(func():shots+=1)
    enemy.appeared.connect(func():appearances.append(clock))
    advance(enemy,5.1)
    check(not enemy.visible,"Waiting without player ascent does not create a timed sideways entrance")
    advance(enemy,.01,420)
    var appeared_at := clock
    check(enemy.visible and enemy.state==enemy.State.ENTERING,"Player ascent reveals a ready octopus above the view")
    var view: Rect2 = enemy._view_rect()
    check(enemy.global_position.y<view.position.y and absf(enemy.global_position.x-player.global_position.x)<200,"Entrance begins above the player rather than beyond a side edge")
    var previous: Vector2 = enemy.global_position
    var previous_screen: Vector2 = enemy.global_position-view.position
    advance(enemy,.5,420)
    var displacement: Vector2 = enemy.global_position-previous
    check(displacement.y<0 and absf(displacement.y)<420*.5,"Octopus rises in the world more slowly than the ascending player")
    var screen_position: Vector2 = enemy.global_position-enemy._view_rect().position
    check(screen_position.y>previous_screen.y,"The ascending player's camera sees the octopus drift downward")
    check(absf(screen_position.x-previous_screen.x)>3 and absf(screen_position.x-previous_screen.x)<20,"Swimming has gentle lateral drift")
    advance(enemy,.51,420)
    check(enemy.state==enemy.State.SWIMMING,"Slow upper entrance completes before interaction")
    var drift_before: Vector2 = enemy.global_position-enemy._view_rect().position
    player.global_position = enemy.global_position
    advance(enemy,.01)
    check(enemy.state==enemy.State.SQUASHING and shots==0,"Close approach triggers duang before ink")
    advance(enemy,.08)
    check(enemy.visual.scale.x>1 and enemy.visual.scale.y<1 and shots==0,"Duang first squashes sideways without spraying")
    advance(enemy,.11)
    check(enemy.visual.scale.y>1 and shots==0,"Duang rebounds upward before spraying")
    advance(enemy,.13)
    check(enemy.state==enemy.State.INKING and enemy.sprite.animation==&"ink" and shots==0,"Ink animation starts after the rebound")
    advance(enemy,.26)
    check(shots==1,"Screen splatter starts when the first ink jet appears")
    advance(enemy,.42)
    check(enemy.state==enemy.State.SWIMMING and enemy.visible and shots==1,"After spraying the octopus remains swimming for the rest of its five-second visit")
    var drift_after: Vector2 = enemy.global_position-enemy._view_rect().position
    check(drift_after.y>drift_before.y,"Duang and ink do not reset downward screen progress")
    player.position = Vector2(9000,9000)
    advance(enemy,maxf(0,appeared_at+4.98-clock))
    check(enemy.visible,"The visit still exists just before five seconds")
    advance(enemy,.04)
    check(not enemy.visible and not enemy._view_rect().has_point(enemy.global_position),"The five-second visit ends below the viewport")
    advance(enemy,.01,420)
    check(appearances.size()==2 and appearances[1]-appearances[0]>=5.0,"Another visit waits for the interval and renewed ascent")
    check(enemy.visual.scale.x<0,"The alternating visitor faces its ink jet toward the player")
    player.position = Vector2(9000,9000)
    advance(enemy,5.02)
    check(not enemy.visible and shots==1,"A visit without proximity also lasts five seconds and exits without ink")
    enemy.enabled = false
    check(not enemy.visible and is_zero_approx(enemy.cycle_elapsed),"Disable clears encounter and timing")
    enemy.enabled = true
    enemy._appear()
    enemy._visit_elapsed = .6
    enemy._follow_view()
    var base_y: float = enemy._view_rect().position.y+lerpf(-100,enemy._view_rect().size.y+110,.6/enemy.visible_seconds)
    check(enemy.global_position.y-base_y>10,"Water bob visibly lifts and lowers the octopus relative to its main path")
    enemy._visit_elapsed = 1.8
    enemy._follow_view()
    base_y = enemy._view_rect().position.y+lerpf(-100,enemy._view_rect().size.y+110,1.8/enemy.visible_seconds)
    check(enemy.global_position.y-base_y< -24,"The stronger bob also reaches a clear opposite phase")
    for action in [enemy.State.SWIMMING,enemy.State.SQUASHING,enemy.State.INKING]:
        enemy.reset()
        enemy._appear()
        enemy._visit_elapsed = 2
        enemy._change_state(action)
        enemy.state_elapsed = .05
        enemy.sprite.play(&"ink" if action==enemy.State.INKING else &"swim")
        enemy.finish_current_visit()
        check(enemy.visible and enemy.state==action and is_equal_approx(enemy._visit_elapsed,2),"Shark impact preserves the current octopus action and lifetime")
        advance(enemy,.05)
        check(enemy.visible and enemy.state==action and enemy._visit_elapsed>2,"The preserved action continues rather than freezing")
        advance(enemy,3.0)
        advance(enemy,6,420)
        check(not enemy.visible and enemy.state==enemy.State.WAITING,"The old visit exits naturally without spawning a replacement during death")
    enemy.reset()
    check(enemy.process_mode==Node.PROCESS_MODE_INHERIT and not enemy._finishing_visit,"Retry removes the death continuation mode")

    var ink = load("res://scenes/effects/ocean_ink_overlay.tscn").instantiate()
    root.add_child(ink)
    ink.splash()
    ink.set_process(false)
    ink._process(2.99)
    check(ink.visible and is_equal_approx(ink.splatter.modulate.a,1),"Ink stays opaque for three seconds")
    ink._process(.51)
    check(absf(ink.splatter.modulate.a-.5)<.01,"Ink fades gradually during the fourth second")
    ink.splash()
    ink.set_process(false)
    check(is_zero_approx(ink.elapsed) and is_equal_approx(ink.splatter.modulate.a,1),"A fresh splatter restarts its own hold and fade")
    ink._process(4.01)
    check(not ink.visible and is_zero_approx(ink.splatter.modulate.a),"Ink disappears after three-second hold plus one-second fade")
    check(ink.splatter.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Ink does not intercept controls")
    enemy.queue_free()
    player.queue_free()
    camera.queue_free()
    ink.queue_free()
    await process_frame

    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    await create_timer(.85).timeout
    var stage = game.get_node("OceanLink/FishStage")
    var encounters = stage.get_node("Octopus")
    var octopus = encounters.get_node("First")
    var overlay = stage.get_node("InkOverlay")
    check(not octopus.enabled and not overlay.visible,"Hell phase never shows octopus or ink")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.fish.get_node("Patrol").stop()
    stage.fish.get_node("Movement").enabled = false
    stage.fish.position = Vector2(960,38000)
    await physics_frame
    await physics_frame
    check(encounters.enabled,"Possessed ocean fish enables octopus encounters")
    var teleport = stage.fish.get_node("Teleport")
    check(teleport.try_teleport(Vector2.UP),"Real fish teleport can start during an octopus encounter")
    octopus.enabled = true
    octopus.state = octopus.State.INKING
    octopus.state_elapsed = .24
    octopus._sprayed = false
    octopus._physics_process(.02)
    check(not overlay.visible,"Teleport immunity prevents screen ink at the spray moment")
    teleport.reset()
    octopus.ink_sprayed.emit()
    check(overlay.visible and not game.dead,"Ink signal reaches the screen overlay without damaging the fish")
    stage.reset()
    check(not overlay.visible and not octopus.visible and not octopus.enabled and is_zero_approx(octopus.cycle_elapsed),"Stage reset clears ink and the complete encounter")
    print("OCEAN_OCTOPUS_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
