extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func ticks(count:int=5):
    for i in count:await physics_frame
    await process_frame
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    var link=game.get_node("OceanLink")
    var stage=link.get_node("FishStage")
    var fish=stage.fish
    var breath=link.get_node("Breath")
    await create_timer(.85).timeout
    check(not stage.active and fish.is_visible_in_tree() and not stage.possession.enabled,"Fish exists and patrols before the hell exit, without early possession")
    check(not stage.host.is_in_group("possessable_hosts"),"Hell selection cannot pick the ocean fish")
    var fish_spawn:Vector2=fish.position
    await create_timer(.2).timeout
    check(fish.position.distance_to(fish_spawn)>1,"Fish patrol is already running before the transition")
    game.soul.position=game.demon.position+Vector2(-90,0)
    await ticks()
    check(game.possession.request_possession(),"Hell possession still works")
    await create_timer(2.6).timeout
    game.demon.get_node("Movement").enabled=false
    game.demon.get_node("Input").enabled=false
    game.demon.global_position=link.vortex.global_position+Vector2(0,70)
    game.demon.velocity=Vector2(0,-600)
    game.camera.set_follow_target(game.demon,true)
    var camera_id=root.get_camera_2d().get_instance_id()
    var patrol_before_activation:=0.0
    for i in 600:
        await process_frame
        if link.stage==link.Stage.ERUPTING:
            patrol_before_activation=fish.get_node("Patrol")._time
        if link.stage==link.Stage.OCEAN:break
    check(stage.active and fish.is_visible_in_tree(),"Real volcano exit activates the fish in the original map")
    check(fish.get_node("Patrol")._time>=patrol_before_activation,"Ocean arrival does not respawn the fish or reset its existing patrol")
    check(breath.active and game.player==game.demon,"Emerged demon remains the breath-holding controlled actor")
    check(not link.has_node("Ocean") and not link.has_node("ApproachSteps"),"No old ocean scene or approach platforms are imported")
    check(fish.get_node("Movement").get_script().resource_path.ends_with("swim_motor.gd"),"Fish reuses the existing inertial swimming code")
    game.demon.get_node("Movement").enabled=false
    game.demon.global_position=fish.global_position+Vector2(-600,67)
    await ticks()
    check(not fish.get_node("Visual/SelectedSprite").visible,"Fish selection is hidden outside the possession range")
    game.demon.global_position=fish.global_position+Vector2(-110,67)
    await ticks()
    var selected=fish.get_node("Visual/SelectedSprite")
    check(selected.visible and not fish.get_node("Visual/Sprite").visible,"Nearby demon selects the fish using its separate selection image")
    var selection_art: Texture2D = selected.texture
    var correct_art: bool = selection_art.resource_path.ends_with("selected_right.png") if fish.get_node("Visual/Sprite").flip_h else selection_art is AtlasTexture and selection_art.atlas.resource_path.ends_with("fish_selected_v001.png")
    check(correct_art and not selected.flip_h,"Selection follows fish facing using supplied artwork without mirroring SHIFT lettering")
    var key=InputEventKey.new()
    key.physical_keycode=KEY_SHIFT
    key.location=KEY_LOCATION_LEFT
    key.pressed=true
    root.push_input(key,true)
    await process_frame
    check(stage.possession.state==PossessionController.State.TRANSFERRING,"Left Shift starts the reused soul transfer")
    check(not breath.active,"Leaving the demon cancels the player's drowning deadline")
    check(not game.demon.get_node("Input").enabled and not game.demon.get_node("Movement").enabled,"Abandoned demon no longer receives player input")
    await create_timer(1.0,true,false,true).timeout
    check(game.player==fish and stage.host.claimed,"Transfer hands player control to the fish")
    check(fish.get_node("Teleport").enabled and is_zero_approx(fish.get_node("Teleport").cooldown_remaining),"Possession Shift enables blink without casting it on the same press")
    check(not selected.visible and fish.get_node("Visual/Sprite").visible,"Possessed fish returns to its normal image")
    check(not fish.get_node("Patrol").enabled,"Player control stops automatic patrol")
    check(not game.soul.visible and not game.dead,"Soul hides inside the fish without ending the round")
    check(root.get_camera_2d().get_instance_id()==camera_id,"The original display camera follows the fish")
    var reader=fish.get_node("Input")
    reader.external_control=true
    reader.move_axis=1.0
    reader.up_held=true
    var before:Vector2=fish.global_position
    await create_timer(.4).timeout
    check(fish.global_position.x>before.x+10 and fish.global_position.y<before.y-8,"Reused swimming responds to rightward and upward input")
    reader.clear()
    breath.breath_duration=.01
    await create_timer(.3).timeout
    check(not game.dead,"Expired abandoned-demon breath cannot kill the fish player")
    game.restart()
    check(not stage.active and fish.is_visible_in_tree() and not stage.host.claimed,"Restart resets the fish and keeps it present in the ocean")
    check(game.player==game.soul and not breath.active,"Restart returns control to the original hell ghost")
    check(is_equal_approx(Engine.time_scale,1.0),"Transfer slow motion is cleared")
    print("FORMAL_OCEAN_FISH_FAILURES=",failures.size())
    game.queue_free()
    for i in 3:await process_frame
    quit(0 if failures.is_empty() else 1)
