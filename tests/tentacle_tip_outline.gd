extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func run():
    var viewport := SubViewport.new()
    viewport.size = Vector2i(800,400)
    viewport.transparent_bg = true
    viewport.world_2d = World2D.new()
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var arm = load("res://modules/visual/jellyfish_net_tendril.gd").new()
    viewport.add_child(arm)
    for side in [-1,1]:
        arm.start = Vector2(400,200)
        arm.finish = Vector2(400+side*600,200)
        for time in [.18,.4,.62]:
            arm.sample(time)
            await process_frame
            await RenderingServer.frame_post_draw
            var picture: Image = viewport.get_texture().get_image()
            var tip: Vector2 = arm.centerline[-1]
            var axis: Vector2 = (arm.finish-arm.start).normalized()
            var reach: float = absf((arm.centerline[-1]-arm.start).dot(axis))
            var black := 0
            for offset in range(1,48):
                var sample_index := clampf((1-float(offset)/reach)*(arm.centerline.size()-1),0,arm.centerline.size()-1.001)
                var index := int(sample_index)
                var point := Vector2i(arm.centerline[index].lerp(arm.centerline[index+1],sample_index-index)+axis.orthogonal()*16)
                if not Rect2i(Vector2i.ZERO,picture.get_size()).has_point(point): continue
                var color := picture.get_pixelv(point)
                if color.a>.6 and maxf(color.r,maxf(color.g,color.b))<.12: black+=1
            print("TIP_SIDE=",side," AGE=",time," BLACK_PIXELS=",black)
            if black<12:
                failures+=1
                push_error("Short emerging tip must retain a visible original black cap")
            if side==1 and is_equal_approx(time,.4): picture.save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/work/tentacle-tip-outline.png")
    print("TENTACLE_TIP_OUTLINE_FAILURES=",failures)
    quit(0 if failures==0 else 1)
