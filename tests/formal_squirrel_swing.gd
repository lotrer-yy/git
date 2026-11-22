extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var layout = load("res://scenes/levels/formal_jungle_layout.tscn").instantiate()
    root.add_child(layout)
    var camera := Camera2D.new()
    root.add_child(camera)
    camera.position = Vector2(960,10000)
    layout.configure(camera,Transform2D.IDENTITY)
    layout.set_process(false)
    var squirrel = layout.get_node("Squirrel")
    var vine = layout.vines[-1]
    check(vine.rider==squirrel,"Squirrel hangs from the lowest authored thin vine")
    check(not vine.is_physics_processing() and not squirrel.active,"Distant squirrel and rope both sleep")
    camera.position = Vector2(960,29000)
    layout._update_nearby()
    check(vine.is_physics_processing() and squirrel.active,"Both wake near the shore")
    squirrel.set_physics_process(false)
    squirrel.set_process(false)
    vine.set_physics_process(false)
    vine.set_process(false)
    var left: float = INF
    var right: float = -INF
    var max_step: float = 0
    var last: Vector2 = squirrel.global_position
    var max_stretch: float = 0
    for frame in range(3600):
        squirrel._physics_process(1.0/120)
        vine._physics_process(1.0/120)
        squirrel._process(1.0/120)
        var grip: Vector2 = vine.to_global(vine.rope.sample(vine.grip_length))
        check(squirrel.global_position.distance_to(grip+vine.rider_offset)<.01,"Hands follow the rope without sliding")
        if frame>600:
            left = minf(left,grip.x-vine.global_position.x)
            right = maxf(right,grip.x-vine.global_position.x)
        max_step = maxf(max_step,last.distance_to(squirrel.global_position))
        last = squirrel.global_position
        for i in range(vine.rope.segments):
            max_stretch = maxf(max_stretch,vine.rope.points[i].distance_to(vine.rope.points[i+1])/vine.rope.segment_length)
    print("SWING_RANGE=",left,",",right," MAX_STEP=",max_step," MAX_STRETCH=",max_stretch)
    check(left < -90 and right > 90,"Squirrel keeps swinging to both sides over thirty seconds")
    check(max_step<16,"No frame-to-frame pose jumps")
    check(max_stretch<1.35,"Rope keeps its segment lengths under load")
    squirrel.set_selected(true)
    check(squirrel.get_node("GraspPivot/SelectedSprite").visible and not squirrel.get_node("GraspPivot/Sprite").visible,"Authored selected artwork is available")
    layout.reset()
    check(vine.rider==squirrel and not squirrel.selected,"Replay restores the squirrel on its vine")
    print("FORMAL_SQUIRREL_SWING_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
