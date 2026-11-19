extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene = menu
    var display = menu.get_node("DescentCamera")
    var handoff = menu.get_node("GameHandoff")
    var display_id: int = display.get_instance_id()
    handoff.finished.connect(func():
        check(handoff.gameplay.camera.global_position.distance_to(display.global_position)<.1,"Gameplay adopts the final pan view without a position jump"))
    menu._start_game()
    var saw_pan = false
    var original_zoom = Vector2.ONE * 1.35
    for i in 9000:
        await process_frame
        if is_instance_valid(handoff.gameplay):
            handoff.gameplay.get_node("FlyingEnemies").enabled = false
        if handoff.panning and handoff.playing:
            saw_pan = true
            check(display.zoom.is_equal_approx(original_zoom),"Original handoff pans without adding a zoom-out")
        if handoff.switched and handoff.gameplay.get_node("WallEntry").completed: break
    check(handoff.switched and saw_pan,"Real main-menu opening reaches the formal hell handoff")
    if not handoff.switched: quit(1); return
    var game = handoff.gameplay
    var camera = game.camera
    check(camera.zoom.is_equal_approx(original_zoom) and display.zoom.is_equal_approx(original_zoom),"Normal opening preserves the original 1.35x gameplay framing")
    check(camera.is_processing() and game.get_node("CameraOutput").enabled,"Handoff enables gameplay following and display output")
    check(root.get_camera_2d().get_instance_id()==display_id,"Opening keeps the same display camera")
    game.soul.position = game.demon.position+Vector2(-90,0)
    for i in 5: await physics_frame
    check(game.possession.request_possession(),"Normal opening allows demon possession")
    await create_timer(2.6).timeout
    check(game.player==game.demon and camera.target==game.demon,"Possession hands camera following to the controlled demon")
    check(camera.zoom.distance_to(original_zoom)<.001 and display.zoom.distance_to(original_zoom)<.001,"Possession close-up recovers to the original gameplay framing")
    var before: Vector2 = camera.global_position
    var display_before: Vector2 = display.global_position
    game.demon.get_node("Movement").enabled = false
    game.demon.global_position += Vector2(100,-900)
    await create_timer(1.5).timeout
    check(camera.global_position.distance_to(before)>100,"Camera continues moving upward after entering hell and possessing demon")
    check(display.global_position.distance_to(display_before)>100 and display.global_position.distance_to(camera.global_position)<1,"Displayed view receives the gameplay camera movement")
    # At 1x the 1920-wide level fills the viewport and clamps all horizontal motion.
    # Preserve the original ability to follow across the hell corridor at 1.35x.
    before = camera.global_position
    game.demon.global_position.x = game.position.x+1500
    await create_timer(1.5).timeout
    check(camera.global_position.x>before.x+100,"Original framing retains horizontal following space")
    check(not game.dead,"Camera validation is performed during live gameplay")
    print("MAIN_MENU_CAMERA_HANDOFF_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
