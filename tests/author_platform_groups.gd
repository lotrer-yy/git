extends SceneTree

const SURFACE = preload("res://modules/environment/hell_surface.gd")
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
	await physics_frame
	for node in game.find_children("*", "Node", true, false) + [game]:
		node.set_process(false)
		node.set_physics_process(false)
	var probe := CharacterBody2D.new()
	probe.collision_layer = 2
	probe.collision_mask = 8
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 37
	shape.height = 112
	collision.shape = shape
	collision.position.y = -56
	probe.add_child(collision)
	root.add_child(probe)
	for number in [2,3]:
		var target = game.get_node("Fork/Targets/Target%02d" % number)
		var art: Sprite2D = target.get_node(target.platform_art_path)
		for state in range(3):
			target.set_state(state)
			check(target.art.visible == (state!=0),"Composite normal ball and state art never overlap")
			check(art.material.get_shader_parameter("hide_ball") == (state!=0),"Old ball disappears when the state changes")
		target.set_state(0)
		var body = game.get_node("Terrain/BallCliff" if number==2 else "Platforms/Static05")
		var polygon: CollisionPolygon2D = body.get_node("Collision")
		var top := SURFACE.landing_on(body)
		probe.global_position = top - Vector2(0,60)
		for frame in range(60):
			probe.velocity = Vector2(0,240)
			probe.move_and_slide()
			await physics_frame
			if probe.is_on_floor():break
		check(probe.is_on_floor(),"Author platform supports a demon-sized body")
		if probe.get_slide_collision_count()>0:
			check(probe.get_slide_collision(0).get_collider()==body,"Standing contact matches the intended group")
		if number==2:
			for frame in range(3):await physics_frame
			check(not game.get_node("Hazards/Hazard09").overlaps_body(probe),"Standing on the cliff is safe; only its spike is dangerous")
		probe.global_position = Vector2(-500,-500)
		var rig = game.get_node("Fork")
		rig.lodged = target
		target.set_state(2)
		rig._swap_and_bounce()
		await create_timer(1.4).timeout
		check(not rig.swapping and not rig.launching,"Grouped target completes its exchange and bounce")
		for frame in range(50):
			game.demon.velocity = Vector2(0,120)
			game.demon.move_and_slide()
			await physics_frame
			if game.demon.is_on_floor():break
		check(game.demon.is_on_floor() and game.demon.global_position.y < target.global_position.y-30,"Bounce reaches the upper platform instead of clipping into its side")
		rig.reset()
	print("AUTHOR_PLATFORM_GROUP_FAILURES=",failures)
	quit(1 if failures else 0)
