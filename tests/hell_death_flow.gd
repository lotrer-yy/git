extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok:bool, message:String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func wait_for(predicate:Callable, frames:int=1200) -> bool:
	for i in frames:
		if predicate.call():return true
		await process_frame
	return false
func run() -> void:
	var menu=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await process_frame
	menu.get_node("Start").pressed.emit()
	var handoff=menu.get_node("GameHandoff")
	check(await wait_for(func():return handoff.switched and handoff.gameplay.get_node("WallEntry").completed,6000),"Actual opening reaches gameplay")
	var game=handoff.gameplay
	game.get_node("FlyingEnemies").enabled=false # 单项检查不运行定时敌人。
	var flow=game.get_node("DeathFlow")
	var ui=flow.overlay
	var active_id=root.get_camera_2d().get_instance_id()
	game.soul.get_node("Movement").enabled=false
	game.soul.global_position=game.to_global(Vector2(960,47500))
	game.camera.set_process(false)
	game.camera.adopt_view(game.to_global(Vector2(960,47380)),game.camera.zoom)
	await process_frame
	var death_view:Vector2=game.camera.global_position
	game.get_node("Hazards/Hazard09").body_entered.emit(game.soul)
	check(await wait_for(func():return ui.state==ui.State.ENTERING),"Hazard opens death interface")
	game.die()
	var frozen:Vector2=game.soul.global_position
	await create_timer(.35).timeout
	check(ui.retry.position.y<ui.home.position.y,"Retry enters before Home")
	check(game.soul.global_position.is_equal_approx(frozen),"World is frozen behind the overlay")
	check(await wait_for(func():return ui.state==ui.State.OPEN),"Death interface settles")
	check(ui.card.scale.is_equal_approx(Vector2.ONE),"Pop settles at its exact resting scale")
	check(is_equal_approx(ui.dim.color.a,ui.darkness),"Whole frame is dimmed")
	check(game.dead and game.process_mode==Node.PROCESS_MODE_DISABLED,"Dead state freezes gameplay")
	check(not root.has_node("Sfx"),"Withdrawn sounds remain absent")
	var retry_key:=InputEventKey.new()
	retry_key.physical_keycode=KEY_R
	retry_key.pressed=true
	root.push_input(retry_key,true)
	ui.retry.pressed.emit()
	ui.home.pressed.emit()
	check(flow.state==flow.State.RETURNING,"Repeated button input cannot change the pending action")
	var saw_travel=false
	var ghost_hidden_during_travel=true
	var previous_y:float=death_view.y
	var monotonic=true
	for i in 1800:
		await process_frame
		if flow.state==flow.State.RETURNING and not ui.visible:
			var y:float=game.camera.global_position.y
			if y>death_view.y+5:saw_travel=true
			if y<previous_y-.1:monotonic=false
			previous_y=y
			ghost_hidden_during_travel=ghost_hidden_during_travel and not game.soul.visible
		if flow.state==flow.State.PLAYING:break
	check(flow.state==flow.State.PLAYING and not game.dead,"Retry completes and releases the death guard")
	check(saw_travel and monotonic,"Camera travels smoothly down from the death location")
	check(ghost_hidden_during_travel,"Ghost stays inside the doorway until camera return completes")
	check(game.get_node("WallEntry").completed and game.soul.get_node("Input").enabled,"Doorway animation replays and restores controls")
	check(not game.demon.get_node("Host").claimed and not game.awake,"Demon returns to the sleeping unpossessed state")
	check(root.get_camera_2d().get_instance_id()==active_id,"Retry keeps the single existing display camera")
	check(not ui.visible and not menu.get_node("OpeningChase").active if "active" in menu.get_node("OpeningChase") else not ui.visible,"No new opening cutscene is launched")
	# Die after possession as well, including a partially broken platform.
	game.soul.position=game.demon.position+Vector2(-90,0)
	check(await wait_for(func():return game.awake,100),"Approach after retry wakes the demon")
	check(game.possession.request_possession(),"Possession remains functional after retry")
	check(await wait_for(func():return game.demon.get_node("Host").claimed,500),"Possession completes after retry")
	game.die()
	check(await wait_for(func():return ui.state==ui.State.OPEN),"A second death opens a fresh interface")
	ui.retry.pressed.emit()
	check(await wait_for(func():return flow.state==flow.State.PLAYING,1800),"Possessed demon death can retry")
	check(game.player==game.soul and not game.demon.get_node("Host").claimed,"Demon death restores the ghost as the controlled actor")
	game.soul.position=game.demon.position+Vector2(-90,0)
	check(await wait_for(func():return game.awake,100),"Demon wakes for another possession")
	check(game.possession.request_possession(),"A fresh transfer can start")
	await create_timer(.12,true,false,true).timeout
	game.die()
	check(await wait_for(func():return ui.state==ui.State.OPEN),"Death during a transfer still opens the interface")
	ui.retry.pressed.emit()
	check(await wait_for(func():return flow.state==flow.State.PLAYING,1800),"Death during slow-motion transfer can retry")
	check(is_equal_approx(Engine.time_scale,1.0),"Transfer time scale is reset before returning control")
	game.die()
	check(await wait_for(func():return ui.state==ui.State.OPEN),"Fresh death screen remains reusable")
	var old_scene_id:int=menu.get_instance_id()
	ui.home.pressed.emit()
	check(await wait_for(func():return is_instance_valid(current_scene) and current_scene.get_instance_id()!=old_scene_id,500),"Home changes to the homepage")
	check(current_scene.scene_file_path=="res://scenes/ui/main_menu.tscn","Home returns to the actual homepage scene")
	check(is_equal_approx(Engine.time_scale,1.0),"No slowed time leaks into the homepage")
	print("HELL_DEATH_RETRY_FAILURES=",failures.size())
	quit(0 if failures.is_empty() else 1)
