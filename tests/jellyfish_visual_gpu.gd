extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func capture(view: SubViewport) -> PackedByteArray:
    await process_frame
    await RenderingServer.frame_post_draw
    return view.get_texture().get_image().get_data()
func run():
    var view := SubViewport.new()
    view.size = Vector2i(400,500)
    view.transparent_bg = true
    view.world_2d = World2D.new()
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var visual = load("res://modules/visual/jellyfish_pulse_visual.gd").new()
    view.add_child(visual)
    visual.position = Vector2(200,100)
    visual.scale = Vector2.ONE*.16
    var reference := Polygon2D.new()
    reference.texture = visual.ART
    reference.uv = visual.mesh.uv
    reference.polygons = visual.mesh.polygons
    reference.position = visual.position
    reference.scale = visual.scale
    view.add_child(reference)
    for time in [.4,1.8]:
        visual.left_gaze = Vector2(.7,-.6)
        visual.right_gaze = Vector2(-.5,-.7)
        visual.sample(time)
        reference.hide()
        visual.show()
        var gpu: PackedByteArray = await capture(view)
        reference.polygon = visual.deformed_vertices(time)
        reference.show()
        visual.hide()
        var cpu: PackedByteArray = await capture(view)
        var error := 0.0
        var samples := 0
        for pixel in range(0,gpu.size(),4):
            if gpu[pixel+3]==0 and cpu[pixel+3]==0: continue
            for channel in 4:
                error += absf(float(gpu[pixel+channel])-float(cpu[pixel+channel]))
                samples += 1
        error /= maxf(samples,1)
        print("JELLYFISH_GPU_REFERENCE_MEAN_BYTE_ERROR=",error)
        if error>.6:
            failures+=1
            push_error("GPU pulse and gaze must match the original CPU deformation")
    print("JELLYFISH_GPU_FAILURES=",failures)
    quit(0 if failures==0 else 1)
