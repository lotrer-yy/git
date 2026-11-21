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
    check(absf(boss.global_position.x-960)<.1,"Boss keeps its world lane")
    check(boss.state==boss.State.PRESENT,"Entrance settles into background presence")
    var a: PackedVector2Array = boss.visual.mesh.polygon.duplicate()
    boss.visual.sample(.4)
    var b: PackedVector2Array = boss.visual.mesh.polygon.duplicate()
    boss.visual.sample(1.1)
    check(a!=b and b!=boss.visual.mesh.polygon,"Bell and tentacles deform continuously")
    check(boss.z_index>0 and boss.z_index<15,"Boss sits between background and creatures")
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
