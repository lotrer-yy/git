extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var camera := Camera2D.new()
    camera.position = Vector2(960,38800)
    root.add_child(camera)
    var boss = load("res://scenes/enemies/ocean_jellyfish_boss.tscn").instantiate()
    root.add_child(boss)
    var shadow = load("res://scenes/enemies/jellyfish_shadow_foreshadow.tscn").instantiate()
    root.add_child(shadow)
    shadow.configure(camera,boss,960)
    shadow.set_physics_process(false)
    check(not shadow.visible,"Hell phase has no distant ocean shadow")
    check(shadow.sprite.sprite_frames.get_frame_count(&"swim")==8,"Shadow has eight distinct authored swimming frames")
    shadow.enabled = true
    shadow._physics_process(.01)
    shadow.sprite.pause()
    check(shadow.visible and not boss.visible,"Distant silhouette appears before the real boss")
    check(shadow.z_index<boss.z_index and shadow.z_index>0,"Shadow is behind the giant boss and in front of background")
    var before: Vector2 = shadow.global_position
    camera.position += Vector2(100,-300)
    shadow._physics_process(.01)
    var movement: Vector2 = shadow.global_position-before
    check(movement.y< -200 and movement.y> -280,"Depth parallax is partial movement, not a screen-fixed creature")
    var prior: Vector2 = shadow._velocity
    shadow.sprite.frame = 3
    check(shadow._velocity.y<prior.y-200,"Release frame propels the jellyfish forward after charge")
    for frame in 8:
        shadow.sprite.frame = frame
        var pivot: Array = shadow._pivots[frame]
        var texture: Texture2D = shadow.sprite.sprite_frames.get_frame_texture(&"swim",frame)
        var head: Vector2 = shadow.sprite.to_global(Vector2(pivot[0],pivot[1])-texture.get_size()*.5+shadow.sprite.offset)
        check(head.distance_to(shadow.global_position)<.01,"Every frame registers the bell at one stable anchor")
    shadow.sprite.pause()
    boss.appeared.emit()
    shadow._physics_process(.45)
    check(shadow.visible and shadow.modulate.a>0 and shadow.modulate.a<shadow.opacity,"Boss arrival smoothly fades the silhouette")
    shadow._physics_process(.5)
    check(not shadow.visible and shadow._finished,"Distant shadow disappears as the giant arrives")
    shadow.reset()
    check(not shadow.visible and not shadow.enabled and not shadow._finished,"Retry resets the eight-frame shadow and handoff")
    shadow.queue_free()
    boss.queue_free()
    await process_frame
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled = false
    root.add_child(game)
    current_scene = game
    var stage = game.get_node("OceanLink/FishStage")
    var actual = stage.get_node("JellyfishShadow")
    check(not actual.enabled,"Full hell entry never enables the shadow early")
    stage.activate()
    stage._physics_process(.01)
    actual._physics_process(.01)
    check(actual.visible and not stage.get_node("JellyfishBoss").visible,"Ocean activation shows foreshadowing before fish possession and boss entrance")
    stage.reset()
    check(not actual.visible and not actual.enabled,"Actual stage reset removes all old shadow motion")
    print("JELLYFISH_SHADOW_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
