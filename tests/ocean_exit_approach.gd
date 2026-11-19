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
	game.possession.request_possession()
	await create_timer(2.6).timeout
	var link=game.get_node("OceanLink")
	var reader=game.demon.get_node("Input")
	var motor=game.demon.get_node("Movement")
	reader.external_control=true
	reader.clear()
	game.demon.global_position=SURFACE.landing_on(game.get_node("Platforms/Breakable09"))+Vector2(0,-4)
	motor.reset()
	await create_timer(.2).timeout
	check(game.demon.is_on_floor(),"Author's last upper platform supports the player")
	for index in 6:
		var start_y:float=game.demon.global_position.y
		var target:Vector2=link.get_node("ApproachSteps/Step%02d"%(index+1)).global_position if index<5 else link.vortex.global_position
		reader.jump_pressed=true
		reader.jump_held=true
		var reached=false
		for frame in 220:
			await physics_frame
			var difference:float=target.x-game.demon.global_position.x
			reader.move_axis=clampf(difference/45.0,-1.0,1.0)
			if game.demon.velocity.y<0:reader.jump_pressed=false
			if link.stage!=link.Stage.HELL:
				reached=index==5
				break
			if game.demon.is_on_floor() and game.demon.global_position.y<start_y-100:
				reached=true
				break
			if game.dead:break
		check(reached,"Real controller reaches exit route step %d"%(index+1))
		print("STEP",index+1," POSITION=",game.demon.global_position," STAGE=",link.stage)
		reader.jump_pressed=false
		if not reached:break
	check(link.stage==link.Stage.CAPTURING,"Actual upward jump triggers the volcano exit")
	print("EXIT_APPROACH_FAILURES=",failures.size())
	game.queue_free()
	for i in 3:await process_frame
	quit(0 if failures.is_empty() else 1)
