extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var snake = load("res://scenes/enemies/python_bite_animation.tscn").instantiate()
    root.add_child(snake)
    snake.set_process(false)
    check(snake.frames.size()==8,"Eight distinct jaw and neck attack poses are registered")
    for i in 8:
        check(snake.frames[i].region.end.x<=snake.SHEET.get_width() and snake.frames[i].region.end.y<=snake.SHEET.get_height(),"Atlas frames stay within the alpha sheet")
    snake.sample(.42)
    var tongue = snake.layers[0].get_node("Tongue")
    check(tongue.visible and tongue.z_index>0 and tongue.position.x>250,"Open-mouth tongue attaches to the front lip and renders ahead of the jaw")
    snake.sample(.6)
    check(not snake.layers[0].get_node("Tongue").visible,"Snapping bite fully retracts the tongue")
    var events: Array[String] = []
    snake.bite_started.connect(func(): events.append("bite"))
    snake.bite_finished.connect(func(): events.append("finished"))
    snake.play_bite()
    for i in 180: snake._process(1.0/120)
    check(events==["bite","finished"],"One playback emits one bite and one completed event")
    check(not snake.playing and snake.scale==Vector2.ONE and snake.rotation==0,"Attack settles back to the exact resting transform")
    var image = snake.SHEET.get_image()
    check(image.get_pixel(0,0).a==0,"Sprites retain true alpha transparency")
    print("PYTHON_BITE_ANIMATION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
