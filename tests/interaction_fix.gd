extends SceneTree
const SURFACE = preload("res://modules/environment/hell_surface.gd")
var failures := 0
func check(value: bool,label: String) -> void:
    if not value:
        failures += 1
        push_error(label)
func center_of(target: Node2D, state: int) -> Vector2:
    var pivots := [Vector2(67,66.5),Vector2(81,82.5),Vector2(113,66.5)]
    return target.art.to_global(pivots[state]-target.art.texture.get_size()*0.5+target.art.offset)
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await create_timer(0.8).timeout
    var ground_y: float = SURFACE.top_at(game.get_node("Ground/Collision"),game.soul.global_position.x).y
    check(absf(game.soul.global_position.y-ground_y)<3,"Ghost emerges onto edited ground")
    check(absf(game.demon.global_position.y-SURFACE.top_at(game.get_node("Ground/Collision"),game.demon.global_position.x).y)<3,"Demon begins on edited ground")
    game.soul.position=game.demon.position+Vector2(-90,0)
    await physics_frame
    await physics_frame
    check(game.possession.request_possession(),"Original possession still works")
    await create_timer(0.65).timeout
    check(game.demon.get_node("Host").claimed,"Demon receives control")
    var rig = game.get_node("Fork")
    var target = rig.targets[0]
    var before: Vector2=target.global_position
    target.position += Vector2(-10,-10)
    for state in range(3):
        target.set_state(state)
        check(center_of(target,state).is_equal_approx(target.global_position),"State art center matches the same target root")
        check(target.get_node("Art") is Sprite2D,"Exactly one art node per target")
    target.set_state(0)
    game.position += Vector2(1200,-1800)
    game.demon.get_node("Movement").enabled=false
    game.demon.global_position=target.get_node("SwapPoint").global_position+Vector2(-260,260)
    for i in range(5):await physics_frame
    check(rig.selected==target,"Plugin acquires relocated target in translated level")
    check(target.state==1,"Selected target switches to locked art")
    check(center_of(target,1).is_equal_approx(target.global_position),"Lock never offsets target")
    rig._throw()
    var flight = rig.motion
    rig._throw()
    check(rig.motion==flight,"Repeated input cannot create competing projectiles")
    await create_timer(0.6).timeout
    check(rig.lodged==target and target.state==2,"Fork stays lodged until exchange")
    check(target.art.scale.y<1,"Hit art remains compressed")
    check(center_of(target,2).is_equal_approx(target.global_position),"Compressed art preserves pivot")
    var previous: Vector2=game.demon.global_position
    rig._swap_and_bounce()
    check(rig.swapping,"Exchange has a distinct animation phase")
    check(not game.demon.get_node("Input").enabled,"Input locked during exchange")
    await create_timer(0.16).timeout
    check(game.demon.global_position.distance_to(target.get_node("SwapPoint").global_position)<2,"Exchange uses safe marker in global space")
    check(rig.fork.global_position.distance_to(previous+Vector2(0,-60))<2,"Fork takes old demon position")
    await create_timer(1.3).timeout
    check(not rig.swapping and not rig.launching,"Exchange and launch complete")
    check(game.demon.get_node("Input").enabled,"Input restored after launch")
    check(game.demon.global_position.y<target.global_position.y,"Launch reaches the upper region")
    game.restart()
    await physics_frame
    check(absf(game.demon.position.y-ground_y)<3,"Restart uses saved edited spawn")
    check(not rig.flying and not rig.swapping and not rig.launching,"Restart cancels interaction states")
    for ball in rig.targets:
        check(ball.state==0 and center_of(ball,0).is_equal_approx(ball.global_position),"Restart restores one normal target")
    print("INTERACTION_FIX_FAILURES=",failures)
    game.queue_free()
    await process_frame
    quit(1 if failures else 0)
