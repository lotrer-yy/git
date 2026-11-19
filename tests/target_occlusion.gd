extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
	if not ok:failures.append(message);push_error(message)
func effective_z(item:CanvasItem)->int:
	var result=item.z_index
	var current=item
	while current.z_as_relative:
		current=current.get_parent() as CanvasItem
		if current==null:break
		result+=current.z_index
	return result
func run():
	var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	game.get_node("FlyingEnemies").enabled=false # 单项检查不运行定时敌人。
	root.add_child(game)
	current_scene=game
	await process_frame
	game.get_node("Fork").set_physics_process(false)
	for ball in game.get_node("Fork/Targets").get_children():
		var layer:int=effective_z(ball.art)
		var position:Vector2=ball.global_position
		for state in [1,2,0]:
			ball.set_state(state)
			check(effective_z(ball.art)==layer,"Target layer stays fixed when its state changes")
			await create_timer(.4).timeout
			check(effective_z(ball.art)==layer,"Target layer stays fixed after bounce completion")
		ball.bounce_on_teleport()
		check(effective_z(ball.art)==layer,"Teleport bounce does not lift the target in front")
		await create_timer(.4).timeout
		check(effective_z(ball.art)==layer and ball.global_position==position,"Bounce preserves depth and target position")
		if ball._platform_art!=null:
			check(layer<=effective_z(ball._platform_art),"Composite platform remains in front of the independent ball")
		check(layer<effective_z(game.get_node("WorldLayers/Walls")),"Side walls remain in front of the target")
		print(ball.name," FIXED_Z=",layer)
	print("TARGET_OCCLUSION_FAILURES=",failures.size())
	game.queue_free()
	for i in 3:await process_frame
	quit(0 if failures.is_empty() else 1)
