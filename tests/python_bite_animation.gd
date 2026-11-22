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
    snake.sample(0)
    var tongue = snake.layers[0].get_node("Tongue")
    check(tongue.visible and tongue.position==Vector2(301,149),"Idle tongue starts inside the front lip outline")
    var original_length: float = tongue.amount
    snake.sample(.04)
    check(tongue.amount<original_length and tongue.amount>0,"Tongue retracts into the mouth before anticipation")
    for time in [.08,.15,.3,.42,.52,.56,.6,.75,.9,1.0]:
        snake.sample(time)
        for layer in snake.layers:
            check(not layer.get_node("Tongue").visible,"Both animation layers hide the tongue throughout opening, lunging and snapping")
    snake.sample(snake.total_duration+.1)
    check(not snake.layers[0].get_node("Tongue").visible,"Tongue stays retracted briefly after the bite settles")
    var last_amount: float = 0
    var max_step: float = 0
    for frame in 41:
        snake.sample(snake.total_duration+.11+frame*.01)
        var amount: float = snake.layers[0].get_node("Tongue").amount
        check(amount>=last_amount,"Idle tongue extends monotonically from inside the mouth")
        max_step=maxf(max_step,amount-last_amount)
        last_amount=amount
    check(max_step<.06 and is_equal_approx(last_amount,1),"Tongue grows continuously rather than popping into full length")
    var events: Array[String] = []
    snake.bite_started.connect(func(): events.append("bite"))
    snake.bite_finished.connect(func(): events.append("finished"))
    snake.play_bite()
    for i in 180: snake._process(1.0/120)
    check(events==["bite","finished"],"One playback emits one bite and one completed event")
    check(not snake.playing and snake.scale==Vector2.ONE and snake.rotation==0,"Attack settles back to the exact resting transform")
    for i in 60: snake._process(1.0/120)
    check(is_equal_approx(snake.layers[0].get_node("Tongue").amount,1) and not snake._returning,"Live playback finishes the smooth tongue return after its bite event")
    var image = snake.SHEET.get_image()
    check(image.get_pixel(0,0).a==0,"Sprites retain true alpha transparency")
    print("PYTHON_BITE_ANIMATION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
