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
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 37
	capsule.height = 112
	shape.shape = capsule
	shape.position.y = -56
	probe.add_child(shape)
	root.add_child(probe)
	var tested := 0
	for index in range(9,19):
		var platform = game.get_node("Platforms/Breakable%02d" % index)
		if platform.collision == null:
			check(platform.broken and not platform.sprite.visible,"Removed platform remains inactive")
			continue
		tested += 1
		var collision: CollisionPolygon2D = platform.collision
		check(collision.scale == Vector2.ONE,"Collision has no old vertical stretch")
		var image: Image = platform.sprite.texture.get_image()
		for offset in [-75.0,0.0,75.0]:
			var x: float = platform.sprite.global_position.x + offset
			var surface := SURFACE.top_at(collision,x)
			probe.global_position = surface - Vector2(0,70)
			probe.velocity = Vector2.ZERO
			probe.reset_physics_interpolation()
			await physics_frame
			for step in range(50):
				probe.velocity = Vector2(0,240)
				probe.move_and_slide()
				await physics_frame
				if probe.is_on_floor(): break
			check(probe.is_on_floor(),"Demon-sized body lands on %s" % platform.name)
			if probe.get_slide_collision_count() > 0:
				check(probe.get_slide_collision(0).get_collider()==platform,"Contact is the intended platform")
			var pixel: Vector2 = platform.sprite.to_local(probe.global_position) + image.get_size()*0.5
			var pixel_x := clampi(roundi(pixel.x),0,image.get_width()-1)
			var visible_top := 0
			while image.get_pixel(pixel_x,visible_top).a < 0.5:
				visible_top += 1
			check(pixel.y >= visible_top - 1 and pixel.y <= visible_top + 10,"Feet match the visible art surface")
		print("FOOT_CONTACT_3_POINTS_PASS ", platform.name)
	check(tested==9,"Nine existing breakable platforms tested")
	var brittle = game.get_node("Platforms/Breakable18")
	var saved_polygon: PackedVector2Array = brittle.collision.polygon.duplicate()
	var saved_art: Transform2D = brittle.sprite.transform
	var saved_pieces := [brittle.pieces[0].transform,brittle.pieces[1].transform]
	probe.global_position = SURFACE.top_at(brittle.collision,brittle.sprite.global_position.x) - Vector2(0,1)
	probe.velocity = Vector2(0,120)
	probe.move_and_slide()
	probe.add_to_group("hell_players")
	brittle.set_physics_process(true)
	for frame in range(ceili(2.0 * Engine.physics_ticks_per_second)):
		probe.velocity = Vector2(0,120)
		probe.move_and_slide()
		await physics_frame
		check(brittle.collision.polygon == saved_polygon,"Animation never rewrites the edited collider")
		if brittle.loaded and brittle.progress < 1.48:
			check(not brittle.broken and not brittle.collision.disabled,"Full support remains before 1.5 seconds")
			check(brittle.sprite.visible and brittle.sprite.modulate.a==1.0,"No transparent overlapping full art")
			check(not brittle.pieces[0].visible and not brittle.pieces[1].visible,"Fragments appear only after separation")
		if brittle.broken: break
	print("BREAK_TRIGGER_STATE loaded=",brittle.loaded," progress=",brittle.progress," processing=",brittle.is_physics_processing()," probe_floor=",probe.is_on_floor()," collisions=",probe.get_slide_collision_count())
	check(brittle.loaded and brittle.broken,"Standing triggers one complete fracture")
	check(absf(brittle.progress-1.5)<0.02,"Fracture takes 1.5 seconds")
	var break_frame := Engine.get_physics_frames()
	await physics_frame
	check(brittle.collision.disabled and not brittle.sprite.visible,"Breaking removes support and intact art together")
	for other in game.platforms:
		if other == brittle or other.kind != "breakable": continue
		check(is_zero_approx(other.sprite.material.get_shader_parameter("fracture_amount")),"Other platforms do not share crack state")
	var first: Vector2 = brittle.pieces[0].position
	await create_timer(0.12).timeout
	var second: Vector2 = brittle.pieces[0].position
	await create_timer(0.12).timeout
	var third: Vector2 = brittle.pieces[0].position
	check(third.y-second.y > second.y-first.y + 5,"Debris accelerates instead of resetting its position")
	check(third.x < first.x and brittle.pieces[1].rotation > 0 and brittle.pieces[0].rotation < 0,"Pieces separate and rotate independently")
	await create_timer(1.3).timeout
	check(not brittle.pieces[0].visible and not brittle.pieces[1].visible,"Debris disappears after falling")
	probe.remove_from_group("hell_players")
	probe.global_position = Vector2(-500,-500)
	var remaining := ceili(4.9 * Engine.physics_ticks_per_second) - (Engine.get_physics_frames() - break_frame)
	for frame in range(maxi(0,remaining)): await physics_frame
	check(brittle.broken and brittle.collision.disabled and not brittle.sprite.visible,"Platform stays absent until the five-second cooldown")
	for frame in range(ceili(0.2 * Engine.physics_ticks_per_second)): await physics_frame
	check(not brittle.broken and not brittle.collision.disabled and brittle.sprite.visible,"Platform automatically returns five seconds after breaking")
	check(brittle.collision.polygon == saved_polygon,"Respawn preserves the edited polygon")
	check(brittle.sprite.scale != saved_art.get_scale(),"Respawn plays an elastic pop")
	var half_height: float = brittle.sprite.texture.get_height() * 0.5
	check(absf(brittle.sprite.position.y-half_height*brittle.sprite.scale.y-(saved_art.origin.y-half_height*saved_art.get_scale().y))<0.1,"Elastic pop keeps the visible standing edge fixed")
	await create_timer(0.35).timeout
	check(brittle.sprite.transform.is_equal_approx(saved_art),"Elastic pop returns to the original size and position")
	probe.add_to_group("hell_players")
	probe.global_position = SURFACE.top_at(brittle.collision,brittle.sprite.global_position.x) - Vector2(0,1)
	for frame in range(ceili(2.0 * Engine.physics_ticks_per_second)):
		probe.velocity = Vector2(0,120)
		probe.move_and_slide()
		await physics_frame
		if brittle.broken: break
	check(brittle.loaded and brittle.broken,"Regenerated platform can be stepped on and broken again")
	probe.remove_from_group("hell_players")
	probe.global_position = Vector2(-500,-500)
	brittle.reset()
	await physics_frame
	check(not brittle.loaded and not brittle.broken and not brittle.collision.disabled,"Restart restores support and trigger")
	check(brittle.sprite.visible and brittle.sprite.transform == saved_art,"Restart restores the intact art")
	for i in range(2):
		check(not brittle.pieces[i].visible and brittle.pieces[i].transform==saved_pieces[i],"Restart restores registered fragment positions")
	check(brittle.is_physics_processing(),"Platform can break again after restart")
	print("BREAKABLE_PLATFORM_FAILURES=",failures)
	quit(1 if failures else 0)
