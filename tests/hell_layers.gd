extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var background: Node2D = game.get_node("Map/ImageTiles")
	check(background.scene_file_path=="res://scenes/map/hell_background.tscn","Backdrop is an independently replaceable scene")
	check(not background.get_meta("temporary_composite"),"Legacy patched background is not active")
	check(background.get_child_count()==26,"Other world regions remain in the background scene")
	for i in range(19,26):
		var tile: Sprite2D = background.get_node("Tile%02d" % i)
		check(tile.position==Vector2(0,i*2048),"Clean background tiles form a continuous image")
		check(tile.scale==Vector2.ONE,"Background stays at original resolution")
		check(tile.get_meta("full_texture")=="res://assets/art/hell/layers/background/%02d.png" % i,"Editor uses author's clean background")
		check(tile.get_meta("runtime_texture")==tile.get_meta("full_texture"),"Streaming cannot restore a patched backdrop")
	background.hide()
	for side in ["Left","Right"]:
		var walls: Node2D = game.get_node("WorldLayers/Walls/"+side)
		check(walls.get_child_count()==6 and walls.is_visible_in_tree(),"Walls remain visible without the background")
	for name in ["Ground","Lava"]:
		var art: Sprite2D = game.get_node("WorldLayers/"+name+"/Art")
		check(art.is_visible_in_tree(),"Starting ground and lava are independent layers")
	var rocks := 0
	var spikes := 0
	for art in game.find_children("*", "Sprite2D", true, false):
		if art.name.begins_with("RockArt"):
			rocks += 1
			check(art.is_visible_in_tree() and art.texture.resource_path.contains("/new/rock"),"Large rocks use the author's standalone sprites")
		if art.name.begins_with("SpikeArt"):
			spikes += 1
			check(art.is_visible_in_tree() and art.texture.resource_path.ends_with("/spike.png"),"Standalone spikes remain outside the background")
	check(rocks==9 and spikes==6,"Standalone rocks and spikes remain outside the two author groups")
	for target in game.get_node("Fork").targets:
		var original: Vector2 = target.global_position
		for state in range(3):
			target.set_state(state)
			var art: Sprite2D = target.art
			var pivots := [Vector2(67,66.5),Vector2(81,82.5),Vector2(113,66.5)]
			var centre := art.to_global(pivots[state]-art.texture.get_size()*0.5+art.offset)
			check(centre.is_equal_approx(original),"All target states keep the same registration")
			check(art.is_visible_in_tree() or (state==0 and not target.platform_art_path.is_empty()),"Normal grouped balls use the author composite exactly once")
			check(not art.material.get_shader_parameter("clip_normal"),"Old baked-map clipping mask is not used")
			check(art.z_index==(-10 if state==0 else 0),"Foreground controls occlusion for normal and selected states")
		target.set_state(0)
	background.show()
	await create_timer(0.15).timeout
	check(game.get_node("TextureStreamer").is_view_ready(),"Independent backdrop still streams before the camera handoff")
	print("HELL_LAYER_FAILURES=",failures)
	quit(1 if failures else 0)
