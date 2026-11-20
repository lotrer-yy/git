extends SceneTree
var failures: int = 0

func _initialize(): run.call_deferred()

func black_pixels(image: Image) -> int:
    var count := 0
    for y in image.get_height():
        for x in image.get_width():
            var color := image.get_pixel(x,y)
            if color.a>.8 and maxf(color.r,maxf(color.g,color.b))<.05:
                count += 1
    return count

func run():
    var viewport := SubViewport.new()
    viewport.size = Vector2i(640,360)
    viewport.transparent_bg = true
    viewport.world_2d = World2D.new()
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var shark = load("res://scenes/enemies/ocean_shark.tscn").instantiate()
    viewport.add_child(shark)
    shark.set_physics_process(false)
    shark.set_process(false)
    shark.position = Vector2(340,180)
    shark._face(Vector2.RIGHT)
    shark.show()
    for animation in [&"idle",&"windup",&"dash"]:
        shark.sprite.animation = animation
        for frame in shark.sprite.sprite_frames.get_frame_count(animation):
            shark.sprite.frame = frame
            shark._register_frame()
            shark.sprite.material.set_shader_parameter("outline_pixels",0.0)
            await process_frame
            await RenderingServer.frame_post_draw
            var before := black_pixels(viewport.get_texture().get_image())
            shark.sprite.material.set_shader_parameter("outline_pixels",4.0)
            await process_frame
            await RenderingServer.frame_post_draw
            var image := viewport.get_texture().get_image()
            var after := black_pixels(image)
            if after<before+300:
                failures += 1
                push_error("Missing black outline: %s/%d before=%d after=%d" % [animation,frame,before,after])
    print("OCEAN_SHARK_OUTLINE_FAILURES=",failures)
    viewport.queue_free()
    await process_frame
    quit(0 if failures==0 else 1)
