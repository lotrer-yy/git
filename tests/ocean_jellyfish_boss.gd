extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var player := CharacterBody2D.new()
    player.position = Vector2(1100,38800)
    root.add_child(player)
    var camera := Camera2D.new()
    root.add_child(camera)
    camera.position = player.position
    camera.zoom = Vector2.ONE*1.35
    camera.make_current()
    camera.force_update_scroll()
    var boss = load("res://scenes/enemies/ocean_jellyfish_boss.tscn").instantiate()
    root.add_child(boss)
    boss.configure(player,camera)
    boss.set_physics_process(false)
    check(not boss.visible,"Boss is hidden before the ocean ascent")
    boss.enabled = true
    boss._physics_process(.01)
    for i in 600: boss._physics_process(.01)
    check(not boss.visible,"Waiting without ascending cannot trigger the entrance")
    player.position.y -= 899
    boss._physics_process(.01)
    check(not boss.visible,"Boss waits for the intended ascent distance")
    player.position.y -= 2
    camera.position = player.position
    camera.force_update_scroll()
    boss._physics_process(.01)
    check(boss.visible and boss.state==boss.State.RISING,"Ascending far enough starts the giant entrance")
    var crown: float = boss.global_position.y-boss.visual.ART.get_height()*.19*boss.artwork_scale
    var bottom: float = camera.get_screen_center_position().y+camera.get_viewport_rect().size.y*.5/camera.zoom.y
    check(crown>bottom+90,"Complete head begins below the view")
    var initial: Vector2 = boss.global_position
    camera.position += Vector2(180,-500)
    camera.force_update_scroll()
    check(boss.global_position==initial,"Camera panning never directly moves the boss")
    for step in 500:
        player.velocity = Vector2(0,-420)
        player.position += player.velocity*.01
        camera.position = player.position
        camera.force_update_scroll()
        boss._physics_process(.01)
    check(boss.global_position.y<initial.y-1000,"Boss swims upward into the moving view")
    check(absf(boss.global_position.x-960)<=111,"Boss sways within its own world lane")
    check(boss.state==boss.State.PRESENT,"Entrance settles into background presence")
    check(boss.artwork_scale>=.9,"Boss is large enough to extend behind the side walls")
    var static_geometry: PackedVector2Array = boss.visual.mesh.polygon.duplicate()
    var leftmost := INF
    var rightmost := -INF
    var nearest := INF
    var farthest := -INF
    for step in 800:
        player.velocity = Vector2(0,-420)
        player.position += player.velocity*.01
        boss._physics_process(.01)
        var gap: float = boss.global_position.y-player.global_position.y
        leftmost = minf(leftmost,boss.global_position.x)
        rightmost = maxf(rightmost,boss.global_position.x)
        nearest = minf(nearest,gap)
        farthest = maxf(farthest,gap)
    check(farthest-nearest>160,"Boss makes visible relative progress and falls back rather than remaining attached to the player")
    check(rightmost-leftmost>120,"Boss also makes noticeable independent lateral progress")
    check(boss.visual.mesh.polygon==static_geometry,"Animation does not rebuild the CPU mesh every tick")
    var a: PackedVector2Array = boss.visual.deformed_vertices(0)
    boss.visual.sample(.4)
    var b: PackedVector2Array = boss.visual.deformed_vertices(.4)
    boss.visual.sample(1.1)
    check(a!=b and b!=boss.visual.deformed_vertices(1.1),"Bell and tentacles deform continuously")
    var visual = boss.visual
    var eyes := Vector2(0,700-visual.ART.get_height()*.19)
    visual.update_gaze(visual.to_global(eyes+Vector2(-800,-500)),1)
    check(visual.left_gaze.x<-.5 and visual.right_gaze.x<-.5,"Both eyes look left toward the actual player position")
    visual.update_gaze(visual.to_global(eyes+Vector2(800,500)),1)
    check(visual.left_gaze.x>.5 and visual.right_gaze.x>.5,"Both eyes turn right as the player passes")
    check(visual.left_gaze.y>.4 and visual.right_gaze.y>.4,"Eyes also track vertical motion")
    visual.update_gaze(visual.to_global(eyes),1)
    check(visual.left_gaze.x>.5 and visual.right_gaze.x<-.5,"Each eye independently converges on a player between the eyes")
    visual.left_gaze = Vector2.ZERO
    visual.right_gaze = Vector2.ZERO
    visual.sample(.4)
    var neutral: PackedVector2Array = visual.deformed_vertices(.4)
    for gaze in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2(.7,.7)]:
        visual.left_gaze = gaze
        visual.right_gaze = gaze
        visual.sample(.4)
        var moved: PackedVector2Array = visual.deformed_vertices(.4)
        var eyes_moved := false
        for i in moved.size():
            if visual._eye_weights[i]>.9 and moved[i].distance_to(neutral[i])>20: eyes_moved = true
            if is_zero_approx(visual._eye_weights[i]):
                check(moved[i].is_equal_approx(neutral[i]),"Gaze cannot move the mouth, bell border or tentacles")
        check(eyes_moved,"The painted eyes actually move within the face")
        var intact := true
        for face in visual.mesh.polygons:
            if (moved[face[1]]-moved[face[0]]).cross(moved[face[2]]-moved[face[0]])<=0: intact = false
        check(intact,"Eye tracking never folds or tears the textured mesh")
    check(boss.z_index>0 and boss.z_index<15,"Boss sits between background and creatures")
    var final_gaps: Array[float] = []
    for step in 4000:
        player.velocity = Vector2(0,-420)
        player.position += player.velocity*.01
        if step%400==0: player.position.y -= 320
        boss._physics_process(.01)
        if step>3500: final_gaps.append(boss.global_position.y-player.global_position.y)
    var shallow_crown: float = boss.global_position.y-boss.visual.ART.get_height()*.19*boss.artwork_scale
    check(shallow_crown>=boss.surface_y+boss.minimum_crown_depth,"Boss crown stays in deep water")
    check(final_gaps.min()>1000,"Fish leaves the boss behind near the surface")
    boss.reset()
    check(not boss.visible and not boss.enabled,"Retry clears entrance and motion")
    var display := Camera2D.new()
    root.add_child(display)
    display.make_current()
    camera.global_position = Vector2(900,34000)
    boss._begin_entrance()
    crown = boss.global_position.y-boss.visual.ART.get_height()*.19*boss.artwork_scale
    bottom = camera.global_position.y+camera.get_viewport_rect().size.y*.5/camera.zoom.y
    check(absf(crown-bottom-100)<.1,"Full opening also places the boss below the virtual game camera view")
    display.queue_free()
    boss.reset()
    boss.queue_free()
    await process_frame
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    var stage = game.get_node("OceanLink/FishStage")
    var actual = stage.get_node("JellyfishBoss")
    check(not actual.enabled and not actual.visible,"Formal hell never shows the sea boss early")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage._physics_process(.01)
    check(actual.enabled,"Controlling the ocean fish enables boss progression")
    check(actual.z_index<stage.fish.z_index and actual.z_index<game.get_node("WorldLayers/OceanWalls").z_index,"Real fish and walls remain in front")
    stage.reset()
    check(not actual.enabled and not actual.visible,"Real stage reset clears the boss")
    print("JELLYFISH_BOSS_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
