extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func press(code: int,right: bool=false,echo_key: bool=false):
    var key := InputEventKey.new()
    key.physical_keycode=code
    key.pressed=true
    key.echo=echo_key
    key.location=KEY_LOCATION_RIGHT if right else KEY_LOCATION_LEFT
    root.push_input(key,true)
func release(code: int):
    var key := InputEventKey.new()
    key.physical_keycode=code
    key.pressed=false
    key.location=KEY_LOCATION_LEFT
    root.push_input(key,true)
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
    var body = layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    game.get_node("CameraAttention").enabled=false
    game.camera.set_process(false)
    game.camera.zoom=Vector2.ONE*1.35
    game.camera.global_position=body.global_position
    var encounter = layout.get_node("PythonEncounter")
    encounter.set_physics_process(false)
    var sequence = encounter.sequence
    sequence.set_process(false)
    var reader = body.get_node("Input")
    var motor = body.get_node("Movement")
    var climber = body.get_node("VineClimber")
    var original_scale: float = Engine.time_scale
    encounter._begin_attack()
    for tick in 300:
        encounter._physics_process(.01)
        if sequence.active: break
    check(sequence.active and encounter.state==encounter.State.SEQUENCE,"Onscreen imminent lunge automatically enters bullet time")
    check(sequence.prompt.visible and sequence.prompt.keys.size()==5,"All author-provided WASD plus final SHIFT icons appear")
    check(encounter.background_dim.visible and sequence.prompt.shade.color.a==0,"Only the world background is dimmed; UI shade cannot darken the actors")
    check(encounter.background_dim.get_index()<encounter.pivot.get_index() and body.z_index>encounter.z_index,"Dim layer is drawn behind the snake and squirrel")
    check(reader.external_control and not reader.enabled and not motor.enabled and not climber.is_physics_processing(),"Sequence input cannot leak into climbing, movement or air jumps")
    check(is_equal_approx(Engine.time_scale,original_scale*.12),"Bullet time scales the world only during the sequence")
    var old_remaining: float = sequence.remaining
    sequence._process(.12*.3)
    check(is_equal_approx(old_remaining-sequence.remaining,.3),"Deadline consumes real time rather than the slowed game time")
    press(KEY_S)
    check(sequence.index==0,"Wrong-order key does not advance")
    release(KEY_S)
    press(KEY_W,false,true)
    check(sequence.index==0,"Keyboard echo never counts")
    for key in [KEY_W,KEY_A,KEY_S,KEY_D]:
        press(key)
        release(key)
    check(sequence.active and sequence.index==4,"WASD alone is insufficient: final Shift is required")
    press(KEY_SHIFT,true)
    check(sequence.active,"Right Shift cannot confirm the counter")
    press(KEY_SHIFT)
    release(KEY_SHIFT)
    check(not sequence.active and sequence.index==5 and encounter.counters==1,"Left Shift completes the whole ordered sequence and triggers counter")
    check(Engine.time_scale==original_scale and not sequence.prompt.visible,"Success immediately restores time scale and hides the prompt")
    check(reader.enabled and not reader.external_control and motor.enabled and climber.is_physics_processing(),"Success restores normal squirrel controls")
    check(body.velocity.y<0 and not game.dead,"Success launches the squirrel into a nonlethal escape-counter")
    check(game.camera.zoom==Vector2.ONE*1.35,"Counter does not corrupt the normal camera zoom")
    encounter._physics_process(.8)
    check(encounter.state==encounter.State.WAITING,"Snake withdraws after the counter")
    encounter._physics_process(5)
    check(encounter.state==encounter.State.WAITING,"Next lunge leaves time to finish changing vines")
    encounter._begin_sequence()
    press(KEY_SHIFT)
    release(KEY_SHIFT)
    check(sequence.index==0,"A held or early Shift cannot skip the directional sequence")
    sequence.advance_real(1.51)
    check(not sequence.active and Engine.time_scale==original_scale and body.velocity.y>0 and not game.dead,"Timeout restores time and knocks the squirrel down without instant death")
    encounter._begin_sequence()
    encounter.reset()
    check(not sequence.active and Engine.time_scale==original_scale and reader.enabled,"Replay during bullet time clears the prompt and restores controls/time")
    encounter._begin_sequence()
    game.die(&"impact")
    check(not sequence.active and Engine.time_scale==original_scale,"Any player death cancels bullet time immediately")
    print("PYTHON_SEQUENCE_COUNTER_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
