extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
	if not ok:failures.append(message);push_error(message)
func settle(seconds:float):await create_timer(seconds).timeout
func spawn_at(manager:Node,point:Vector2)->Node2D:
	var enemy=manager.ENEMY.instantiate()
	enemy.encounter=manager
	enemy.position=manager.to_local(point)
	manager.get_node("Enemies").add_child(enemy)
	enemy.shot.connect(manager._shoot)
	return enemy
func run():
	var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await settle(.85)
	game.soul.position=game.demon.position+Vector2(-90,0)
	for i in 5:await physics_frame
	check(game.possession.request_possession(),"Possession begins")
	await settle(2.6)
	var manager=game.get_node("FlyingEnemies")
	manager.reset()
	await process_frame
	check(manager.spawn_interval==5.0,"Default spawn interval is five seconds")
	await settle(4.7)
	check(manager.enemies().is_empty(),"No enemy appears before the first five seconds")
	await settle(.45)
	check(manager.total_spawned==1 and manager.enemies().size()==1,"Exactly one enemy appears at the first interval")
	check(game.get_node("CameraAttention")._incoming_seconds>0,"New arrival sends a directional camera hint")
	var left_arrival=manager.enemies()[0]
	check(left_arrival.global_position.x<game.camera.world_bounds.position.x,"First enemy spawns beyond the left map edge")
	check(left_arrival.mode==left_arrival.Mode.ENTERING and not left_arrival.is_in_group("fork_targets"),"Off-map enemy cannot attack or steal the lock before entering")
	var right_arrival=manager.spawn_one()
	check(is_instance_valid(right_arrival) and right_arrival.global_position.x>game.camera.world_bounds.end.x,"Next enemy alternates to the right map edge")
	var entry_wait:=0.0
	while left_arrival.mode==left_arrival.Mode.ENTERING and entry_wait<5.0:
		await settle(.05)
		entry_wait+=.05
	check(left_arrival.mode==left_arrival.Mode.FLYING and left_arrival.is_in_group("fork_targets"),"Enemy flies naturally into the level before becoming targetable")
	check(left_arrival.flight.max_speed>=240,"Flying enemies use the increased flight speed")
	left_arrival.global_position=game.demon.global_position+Vector2(260,-220)
	left_arrival.flight.max_speed=0
	right_arrival.global_position=game.camera.world_bounds.position-Vector2(200,200)
	for i in 5:await physics_frame
	check(game.get_node("Fork").selected==left_arrival,"Enemy that entered from outside becomes selectable without needing to leave and reenter the sensor")
	manager.enabled=false
	manager.reset()
	await process_frame
	var rig=game.get_node("Fork")
	game.demon.get_node("Movement").enabled=false
	game.demon.get_node("Input").enabled=false
	game.demon.velocity=Vector2.ZERO
	var ball=game.get_node("Fork/Targets/Target02")
	game.demon.global_position=ball.global_position+Vector2(-260,260)
	game.camera.set_follow_target(game.demon,true)
	var enemy=spawn_at(manager,game.demon.global_position+Vector2(-450,-350))
	for i in 8:await physics_frame
	check(rig.selected==enemy,"A farther visible enemy takes priority over a nearer ball")
	check(enemy.lock.visible,"Enemy uses the supplied lock indicator")
	var position:Vector2=game.demon.global_position
	rig.enemy_hit_chance=0
	rig._throw()
	check(not rig.held and rig.lodged==null,"Enemy attack leaves the hero empty handed without enabling teleport")
	await settle(.6)
	check(is_instance_valid(enemy) and not enemy.is_defeated(),"Forced miss leaves the enemy alive")
	check(rig.held and not rig.flying and not rig.fork.visible,"Missed fork returns automatically")
	check(game.demon.global_position==position,"Enemy attack never teleports the hero")
	check(game.demon.get_node("Visual").scale.distance_to(Vector2.ONE)>.005,"Recall gives the hero a visible elastic pulse")
	for i in 5:await physics_frame
	rig.enemy_hit_chance=1
	rig._throw()
	await settle(.28)
	check(is_instance_valid(enemy) and enemy.is_defeated(),"Forced hit defeats the enemy")
	check(enemy.art.texture==enemy.DEAD,"Enemy uses the supplied dead artwork")
	var full_spin:=false
	while is_instance_valid(enemy):
		full_spin=full_spin or enemy.get_node("Visual").rotation-enemy._death_rotation>=TAU-.01
		await process_frame
	check(full_spin,"Defeated enemy completes one full turn before disappearing")
	check(rig.held and not rig.flying,"Hit fork also returns automatically")
	check(rig.selected==ball,"Ball targeting resumes once the enemy is defeated")
	rig.enemy_hit_chance=.8
	rig._combat_rng.seed=8421
	var hits:=0
	for i in 1000:
		if rig._combat_rng.randf()<rig.enemy_hit_chance:hits+=1
	check(hits>750 and hits<850,"Configured hit chance produces an eighty percent distribution")
	manager.reset()
	await process_frame
	game.demon.global_position=game.to_global(Vector2(500,51796))
	game.camera.set_follow_target(game.demon,true)
	manager.enabled=true
	var flyer=spawn_at(manager,game.demon.global_position+Vector2(260,-260))
	var first:Vector2=flyer.global_position
	var frame_a=flyer.art.texture
	await settle(.15)
	check(flyer.art.texture!=frame_a,"Wing artwork alternates")
	game.demon.collision_layer=0
	var waited:=0.0
	while manager.total_shots==0 and waited<4.0:
		await settle(.05)
		waited+=.05
	check(flyer.global_position.distance_to(first)>20,"Enemy follows a smooth flight route")
	check(manager.total_shots>0,"Enemy telegraphs and throws a fork toward the player")
	check(not game.dead,"Enemy windup leaves time to react")
	manager.reset()
	await process_frame
	var screen_half:Vector2=game.camera.get_viewport_rect().size*.5/game.camera.zoom
	var offscreen=spawn_at(manager,game.camera.global_position-Vector2(0,screen_half.y+200))
	offscreen.flight.max_speed=0
	offscreen._cooldown=0
	var previous_shots:int=manager.total_shots
	await settle(.6)
	check(manager.total_shots==previous_shots and offscreen.mode!=offscreen.Mode.WINDUP,"Off-screen enemy cannot prepare or fire an attack")
	offscreen.mode=offscreen.Mode.WINDUP
	offscreen._state_time=offscreen.windup_seconds-.01
	await settle(.05)
	check(manager.total_shots==previous_shots and offscreen.mode!=offscreen.Mode.WINDUP,"Leaving the screen cancels a pending throw")
	manager._shoot(game.demon.global_position,offscreen.global_position)
	check(manager.total_shots==previous_shots,"Projectile emitter also rejects off-screen origins")
	manager.reset()
	await process_frame
	game.demon.collision_layer=2
	manager.spawn_interval=.03
	manager.max_alive=3
	await settle(.25)
	check(manager.enemies().size()==3,"Encounter respects its live enemy cap")
	manager.spawn_interval=5.0
	manager.max_alive=6
	manager.reset()
	await process_frame
	var safe_position:Vector2=game.demon.global_position
	manager._shoot(safe_position+Vector2(0,-55),safe_position+Vector2(200,-300))
	game.demon.global_position+=Vector2(160,0)
	await settle(.7)
	check(not game.dead,"Enemy fork aims at the committed position and can be dodged")
	game.demon.global_position=safe_position
	manager.reset()
	await process_frame
	# Sweep a hostile fork directly into the active player.
	manager._shoot(game.demon.global_position+Vector2(0,-55),game.demon.global_position+Vector2(0,-300))
	await settle(.6)
	check(game.dead,"Hostile fork sweep triggers the existing death flow")
	game.restart()
	await process_frame
	check(manager.enemies().is_empty() and manager.get_node("Projectiles").get_child_count()==0,"Restart clears enemies and projectiles")
	check(manager.elapsed==0 and rig.held,"Restart resets the five-second timer and hero fork")
	print("FLYING_ENEMY_FAILURES=",failures.size()," CHANCE_HITS=",hits)
	game.queue_free()
	for i in 3:await process_frame
	quit(0 if failures.is_empty() else 1)
