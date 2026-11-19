extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
	if not ok: failures.append(message);push_error(message)
func wait_for(predicate:Callable,frames:int=2400)->bool:
	for i in frames:
		if predicate.call():return true
		await process_frame
	return false
func run():
	var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await process_frame
	menu.get_node("Start").pressed.emit()
	var handoff=menu.get_node("GameHandoff")
	check(await wait_for(func():return handoff.switched and handoff.gameplay.get_node("WallEntry").completed,7000),"Real opening reaches formal map")
	var game=handoff.gameplay
	var link=game.get_node("OceanLink")
	check(await wait_for(func():return is_instance_valid(link.ocean)),"Ocean preloads in the background")
	var display_id=root.get_camera_2d().get_instance_id()
	check(link.ocean.launch.elapsed==0.0,"Hidden ocean does not erupt early")
	check(not link.vortex.try_capture(game.soul),"Unpossessed ghost cannot enter the demon exit")
	game.soul.position=game.demon.position+Vector2(-90,0)
	for i in 5:await physics_frame
	check(game.possession.request_possession(),"Formal demon can be possessed")
	await create_timer(2.6).timeout
	game.demon.get_node("Movement").enabled=false
	game.demon.get_node("Input").enabled=false
	game.demon.global_position=link.vortex.global_position+Vector2(0,100)
	game.camera.set_follow_target(game.demon,true)
	game.demon.velocity=Vector2(0,100)
	check(not link.vortex.try_capture(game.demon),"Falling into the exit does not trigger it")
	await process_frame
	game.demon.velocity=Vector2(0,-600)
	check(link.vortex.try_capture(game.demon),"Upward possessed body triggers capture")
	check(not game.demon.get_node("Input").enabled,"Capture locks movement input")
	game.die()
	check(not game.dead,"Exit cannot race the death interface")
	check(await wait_for(func():return link.stage==link.Stage.TRAVELLING),"Capture flows into the strata camera move")
	var previous:Vector2=game.camera.global_position
	var largest:=0.0
	var monotonic:=true
	while link.stage==link.Stage.TRAVELLING:
		await process_frame
		var point:Vector2=game.camera.global_position
		largest=maxf(largest,point.distance_to(previous))
		if point.y>previous.y+.01:monotonic=false
		previous=point
	check(link.stage==link.Stage.OCEAN,"Transition arrives in ocean")
	check(monotonic and largest<180,"Camera travels upward without a scene-cut jump")
	check(root.get_camera_2d().get_instance_id()==display_id,"The opening display camera stays active through both worlds")
	check(game.camera.global_position.distance_to(link.transition._end)<3,"Ocean arrival adopts the final camera pose")
	check(await wait_for(func():return not link.ocean.launch.active),"Volcano preparation and eruption complete")
	check(link.ocean.demon.get_node("Input").enabled,"Demon control is restored after eruption")
	check(link.ocean.possession.enabled,"Fish possession is available after eruption")
	link.ocean.demon.get_node("Movement").enabled=false
	link.ocean.demon.global_position=link.ocean.fish.get_node("Host").focus_position()+Vector2(-90,0)
	link.ocean.demon.velocity=Vector2.ZERO
	await create_timer(.2).timeout
	check(link.ocean.possession.request_possession(),"Ocean demon can begin transferring into the fish")
	check(await wait_for(func():return link.ocean.player==link.ocean.fish),"Fish possession completes in the connected world")
	check(link.ocean.fish.get_node("Input").enabled,"Fish receives swim control")
	var key=InputEventKey.new()
	key.physical_keycode=KEY_R
	key.pressed=true
	root.push_input(key,true)
	await process_frame
	check(current_scene==menu and link.ocean.launch.active,"R restarts the ocean instead of reloading the opening")
	check(not root.has_node("Sfx"),"Withdrawn sounds remain absent")
	print("FORMAL_OCEAN_FAILURES=",failures.size()," MAX_CAMERA_STEP=",largest)
	menu.queue_free()
	for i in 3:await process_frame
	quit(0 if failures.is_empty() else 1)
