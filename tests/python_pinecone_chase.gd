extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout = stage.get_node("JungleLayout")
    layout.set_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    var body = layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    body.set_physics_process(false)
    var motor = body.get_node("Movement")
    motor.set_physics_process(false)
    var climber = body.get_node("VineClimber")
    climber.set_physics_process(false)
    var reader = body.get_node("Input")
    game.player=body
    game.get_node("CameraAttention").enabled=false
    game.camera.set_process(false)
    game.camera.zoom=Vector2.ONE*1.35
    game.camera.offset=Vector2.ZERO
    game.camera.global_position=Vector2(960,29350)
    var enemy = layout.get_node("PythonEncounter")
    enemy.set_physics_process(false)
    for cone in layout.get_node("Pinecones").get_children(): cone.set_physics_process(false)
    for tick in 300: enemy._physics_process(.01)
    check(enemy.state==enemy.State.WAITING and not enemy.pivot.visible,"Snake cannot appear while shore is still visible")
    body.global_position=Vector2(960,28000)
    game.camera.global_position=Vector2(960,27855)
    for tick in 45: enemy._physics_process(.01)
    check(enemy.state==enemy.State.ENTERING and enemy.pivot.global_position.y>enemy.view_rect().end.y,"Snake begins below the screen only after ground leaves the view")
    var before: Vector2 = enemy.pivot.global_position
    game.camera.global_position.y-=250
    enemy._physics_process(.01)
    check(enemy.pivot.global_position.distance_to(before)<10,"Moving camera never teleports the chasing snake")
    game.camera.global_position=Vector2(960,27855)
    for tick in 300: enemy._physics_process(.01)
    check(enemy.state!=enemy.State.WAITING and enemy.pivot.global_position.y<before.y,"Snake swims upward through world coordinates")
    check(enemy.attacks_started>0,"An exposed pursuing snake actually starts a normal lunge without QTE")
    check(enemy.get_node_or_null("Sequence")==null,"No sequence prompt or slow-motion controller is instantiated")
    check(reader.enabled and not reader.external_control and Engine.time_scale==1,"Pursuit never starts bullet time or steals input")
    var cone = layout.get_node("Pinecones/Pinecone08")
    cone.global_position=body.global_position+Vector2(0,-50)
    cone._origin=cone.position
    cone._physics_process(.01)
    check(cone.state==cone.State.CARRIED,"Contact automatically picks up the author's pinecone")
    cone._physics_process(.15)
    check(cone.state==cone.State.FLYING and cone.velocity.length()>500,"Pickup automatically throws toward the real snake head without a key")
    for tick in 500:
        cone._physics_process(.01)
        enemy._physics_process(.01)
        if cone.state==cone.State.SPENT: break
    check(enemy.counters==1 and enemy.state==enemy.State.STAGGERED and not cone.visible,"Pinecone actually travels to the snake and interrupts it on impact")
    check(Engine.time_scale==1 and reader.enabled,"Projectile hit leaves movement and game speed normal")
    var head_y: float = enemy.pivot.global_position.y
    for tick in 100: enemy._physics_process(.01)
    check(enemy.pivot.global_position.y>head_y+100,"Hit visibly knocks the snake downward away from the squirrel")
    layout.reset()
    check(not enemy.pivot.visible and enemy.state==enemy.State.WAITING and cone.state==cone.State.HANGING and cone.visible,"Replay restores all cones and removes the old chase")
    body.get_node("Host").take_control()
    game.player=body
    cone.global_position=body.global_position+Vector2(0,-50)
    cone._origin=cone.position
    cone._physics_process(.01)
    cone._physics_process(.2)
    check(cone.state==cone.State.CARRIED,"Picking a cone before the snake emerges holds it instead of firing at empty space")
    enemy._begin_entrance()
    cone._physics_process(.01)
    check(cone.state==cone.State.FLYING,"A held cone throws automatically when the snake appears")
    game.die(&"impact")
    cone._physics_process(.01)
    check(not enemy.pivot.visible and not cone.visible and Engine.time_scale==1,"Death cleans up both chase and in-flight cone without changing time")
    print("PYTHON_PINECONE_CHASE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
