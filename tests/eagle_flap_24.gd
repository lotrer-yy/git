extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var eagle = load("res://modules/visual/eagle_flap_visual.gd").new()
    root.add_child(eagle)
    eagle.set_process(false)
    check(eagle._frames.size() == 48, "All 48 illustrated frames are loaded")
    var pixels: Image = eagle.ART.get_image()
    check(pixels.get_size() == Vector2i(4096, 3072), "Atlas has eight columns and six rows")
    var distinct: Dictionary = {}
    for index in 48:
        eagle.sample_frame(index)
        var frame: AtlasTexture = eagle.sprite.texture
        check(frame.atlas == eagle.ART, "Every pose shares the same atlas")
        var region: Rect2i = frame.region
        distinct[hash(pixels.get_region(region).get_data())] = true
        check(pixels.get_pixel(region.position.x, region.position.y).a == 0, "Frame corners remain transparent")
    check(distinct.size() == 48, "All 48 source drawings are distinct")
    eagle.sample_frame(48)
    check(eagle.frame_index == 0, "Frame selection wraps at the loop boundary")
    eagle._process(eagle.cycle_seconds * .25)
    check(eagle.frame_index == 12, "Playback advances at the configured cycle speed")
    eagle.hide()
    eagle._process(eagle.cycle_seconds * .25)
    check(eagle.frame_index == 12, "Hidden eagle pauses playback")
    eagle.reset()
    check(eagle.frame_index == 0 and eagle._clock == 0, "Reveal restart resets animation")
    check(eagle.sprite.use_parent_material, "Cloud masking material reaches the animated sprite")
    print("EAGLE_FLAP_24_FAILURES=", failures.size())
    quit(0 if failures.is_empty() else 1)
