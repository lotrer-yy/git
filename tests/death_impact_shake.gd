extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
	if not ok: failures.append(message);push_error(message)
func run():
	var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await create_timer(.85).timeout
	game.soul.position=game.demon.position+Vector2(-90,0)
	for i in 5:await physics_frame
	check(game.possession.request_possession(),"Possession begins")
	await create_timer(2.6).timeout
	game.demon.get_node("Movement").enabled=false
	game.demon.get_node("Input").enabled=false
	game.demon.velocity=Vector2.ZERO
	var original:Vector2=game.demon.global_position
	game.die()
	await process_frame
	await process_frame
	var flow=game.get_node("DeathFlow")
	var animation=flow.death_animation
	check(is_instance_valid(animation.corpse),"Demon death creates the visual replacement")
	var start:Vector2=animation.corpse.global_position
	var view:Vector2=game.camera.global_position
	check(not game.demon.get_node("Visual").visible,"Normal visual is hidden during death")
	check(not flow.overlay.visible,"End card waits for the death arc")
	game.die()
	var peak:=0.0
	for sample in 26:
		await create_timer(.01,true,false,true).timeout
		peak=maxf(peak,(game.camera.offset*game.camera.zoom).length())
	check(peak>0.05 and peak<=5.01,"Death shake is visible and capped at five screen pixels")
	check(game.camera.offset.is_zero_approx(),"Shake finishes at exactly zero before the corpse falls")
	check(animation.corpse.global_position.y<start.y-25,"Death bounces visibly upward")
	await create_timer(.55,true,false,true).timeout
	check(animation.corpse.global_position.y>start.y+50,"Death then falls downward")
	check(game.demon.global_position.is_equal_approx(original),"Death arc never moves the physical player")
	check(game.camera.global_position.is_equal_approx(view),"Camera stays at the death location")
	await create_timer(1.0,true,false,true).timeout
	check(not animation.corpse.visible and flow.overlay.visible,"Corpse falls away before the end interface")
	for i in 1200:
		await process_frame
		if flow.overlay.state==flow.overlay.State.OPEN:break
	flow.impact_shake.play(game.camera,true)
	var fall_peak:=0.0
	for sample in 16:
		await create_timer(.01,true,false,true).timeout
		fall_peak=maxf(fall_peak,(game.camera.offset*game.camera.zoom).length())
	check(fall_peak<=1.76,"Falling death uses a lighter shake")
	flow.impact_shake.strength_pixels=0
	flow.impact_shake.play(game.camera)
	check(game.camera.offset.is_zero_approx(),"Zero strength disables death shake")
	flow.impact_shake.strength_pixels=5
	flow.overlay.retry.pressed.emit()
	for i in 1800:
		await process_frame
		if flow.state==flow.State.PLAYING:break
	check(flow.state==flow.State.PLAYING,"Retry still returns to play")
	check(not is_instance_valid(animation.corpse),"Retry cleans up the corpse")
	check(game.get_node("Fork").held,"Retry restores the held fork")
	print("DEMON_DEATH_FAILURES=",failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
