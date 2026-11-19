extends SceneTree
const SURFACE=preload("res://modules/environment/hell_surface.gd")
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
	if not ok:failures.append(message);push_error(message)
func run():
	var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await create_timer(.85).timeout
	game.soul.position=game.demon.position+Vector2(-90,0)
	for i in 5:await physics_frame
	check(game.possession.request_possession(),"Possession begins")
	await create_timer(2.6).timeout
	game.camera.zoom=Vector2.ONE*1.35
	var body=game.demon
	var reader=body.get_node("Input")
	reader.external_control=true
	reader.clear()
	var cliff=game.get_node("Terrain/BallCliff")
	var point:Vector2=SURFACE.landing_on(cliff)
	for polygon in cliff.get_children():
		if polygon is CollisionPolygon2D:
			var surface:Vector2=SURFACE.top_at(polygon,1390)
			if is_finite(surface.y):point=surface
	body.global_position=point+Vector2(0,-4)
	body.get_node("Movement").reset()
	game.camera.clear_impulse()
	game.camera.set_follow_target(body,true)
	await create_timer(2.0).timeout
	var attention=game.get_node("CameraAttention")
	var mechanism=game.get_node("Platforms/Static06")
	var top:Vector2=SURFACE.landing_on(mechanism)
	var size:Vector2=game.camera.get_viewport_rect().size
	var target_screen:Vector2=(top-game.camera.global_position)*game.camera.zoom+size*.5
	var player_screen:Vector2=(body.global_position-game.camera.global_position)*game.camera.zoom+size*.5
	check(body.is_on_floor(),"Reproduced player is standing on the screenshot cliff")
	check(game.get_node("Fork").selected==game.get_node("Fork/Targets/Target02"),"The fork still selects the same nearby ball")
	check(attention._platform_interest==mechanism,"Camera previews the next upper mechanism instead of the ball behind the player")
	check(target_screen.y>65 and target_screen.y<size.y-120,"Upper mechanism is fully inside the frame")
	check(player_screen.y<size.y-60,"Player retains room below the feet")
	check(game.camera.zoom.is_equal_approx(Vector2.ONE*1.35),"Route preview does not zoom the game out")
	print("NEXT_MECHANISM_SCREEN=",target_screen," PLAYER_FEET_SCREEN=",player_screen," INTEREST=",attention._platform_interest.name)
	attention.enabled=false
	await create_timer(1.0).timeout
	check(not game.camera.precise_framing,"Disabling guide restores the normal follow dead zone")
	game.restart()
	check(not game.camera.precise_framing and game.camera.framing_bias.is_zero_approx(),"Restart clears the route guide")
	print("NEXT_MECHANISM_FAILURES=",failures.size())
	game.queue_free()
	for i in 3:await process_frame
	quit(0 if failures.is_empty() else 1)
