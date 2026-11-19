extends SceneTree
const S=preload("res://modules/environment/hell_surface.gd")
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
	if not ok:failures.append(message);push_error(message)
func run():
	var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	game.get_node("FlyingEnemies").enabled=false # 单项检查不运行定时敌人。
	root.add_child(game)
	current_scene=game
	await create_timer(.85).timeout
	game.soul.position=game.demon.position+Vector2(-90,0)
	for i in 5:await physics_frame
	game.possession.request_possession()
	await create_timer(2.6).timeout
	var cliff=game.get_node("Terrain/Rock06")
	var art=cliff.get_node("RockArt03")
	var polygon=cliff.get_node("_CollisionShape2D_115")
	check(is_equal_approx(art.scale.x,art.scale.y),"Left cliff uses the original artwork proportions")
	var top:float=art.position.y-art.region_rect.size.y*art.scale.y*.5
	check(absf(top-(-313.0))<.001,"Cliff top does not move when restoring height")
	check(is_equal_approx(art.scale.x,.66848816),"Horizontal size remains unchanged")
	var reader=game.demon.get_node("Input")
	reader.external_control=true
	reader.clear()
	for x in [350.0,425.0]:
		game.demon.global_position=S.top_at(polygon,x)+Vector2(0,-3)
		game.demon.get_node("Movement").reset()
		await create_timer(.35).timeout
		var supported=false
		for i in game.demon.get_slide_collision_count():
			if game.demon.get_slide_collision(i).get_collider()==cliff:supported=true
		check(game.demon.is_on_floor() and supported,"Left cliff still supports the character")
		check(not game.dead,"Standing on the cliff does not trigger a hazard")
	print("LEFT_CLIFF_FAILURES=",failures.size())
	game.queue_free()
	for i in 3:await process_frame
	quit(0 if failures.is_empty() else 1)
