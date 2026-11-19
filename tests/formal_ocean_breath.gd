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
    var breath=link.get_node("Breath")
    var sprite=game.demon.get_node("Visual/Sprite")
    var selected=game.demon.get_node("Visual/SelectedSprite")
    await create_timer(.85).timeout
    check(not breath.active and breath.elapsed==0.0,"Breath timer stays inactive in hell")
    game.soul.position=game.demon.position+Vector2(-90,0)
    await ticks()
    check(selected.visible and not sprite.visible,"Approaching ghost shows the selection artwork")
    check(selected.texture is AtlasTexture and selected.texture.atlas.resource_path.ends_with("hell_demon_selected_v001.png"),"Selection uses the author's SHIFT artwork")
    game.get_node("Fork").reset()
    check(selected.texture is AtlasTexture and selected.texture.atlas.resource_path.ends_with("hell_demon_selected_v001.png"),"Fork reset preserves the possession selection artwork")
    game.soul.position=game.demon.position+Vector2(-500,0)
    await ticks()
    check(not selected.visible and sprite.visible,"Leaving selection range restores the normal artwork")
    game.soul.position=game.demon.position+Vector2(-90,0)
    await ticks()
    check(game.possession.request_possession(),"Possession starts")
    await create_timer(2.6).timeout
    check(not selected.visible and sprite.visible,"Possession finishes on the normal artwork")
    var normal_texture=sprite.texture
    var normal_position:Vector2=sprite.position
    game.demon.get_node("Movement").enabled=false
    game.demon.get_node("Input").enabled=false
    game.demon.global_position=link.vortex.global_position+Vector2(0,70)
    game.demon.velocity=Vector2(0,-600)
    game.camera.set_follow_target(game.demon,true)
    for i in 600:
        await process_frame
        if link.stage==link.Stage.OCEAN:break
        if link.stage==link.Stage.ERUPTING:
            check(breath.active and sprite.texture is AtlasTexture and sprite.texture.atlas==breath.LIVE_ART,"The very first eruption frame already uses the breath-holding expression")
            check(breath.elapsed==0.0,"The scripted eruption does not consume playable breath time")
        else:
            check(not breath.active and breath.elapsed==0.0,"Entry and camera travel do not consume breath")
    check(link.stage==link.Stage.OCEAN and breath.active,"Real volcano eruption starts breath automatically")
    check(sprite.texture is AtlasTexture and sprite.texture.atlas==breath.LIVE_ART,"Emerged demon uses the supplied breath-holding expression")
    var first_green:float=game.demon.get_node("Visual").modulate.g
    # Shorten only the integration fixture; the authored default remains sixteen seconds.
    breath.breath_duration=1.2
    await create_timer(.55).timeout
    check(game.demon.get_node("Visual").modulate.g<first_green,"The breath-holding demon becomes progressively redder")
    check(not game.dead,"Demon remains alive before breath expires")
    await create_timer(.8).timeout
    check(game.dead and game.death_reason==&"drown","Breath timeout triggers actual drowning death")
    check(sprite.texture is AtlasTexture and sprite.texture.atlas==breath.DEAD_ART,"Death swaps to the author's cross-eyed death artwork")
    check(not game.demon.get_node("Input").enabled or game.process_mode==Node.PROCESS_MODE_DISABLED,"Drowning ends player control")
    check(is_instance_valid(breath.corpse) and breath.corpse.visible,"Dead expression remains visible before sinking")
    var corpse_start:Vector2=breath.corpse.global_position
    await create_timer(.6).timeout
    check(breath.corpse.global_position.y>corpse_start.y,"Drowned body sinks instead of using the hell bounce")
    var flow=game.get_node("DeathFlow")
    for i in 1000:
        if flow.overlay.state==flow.overlay.State.OPEN:break
        await process_frame
    check(flow.overlay.state==flow.overlay.State.OPEN,"Drowning completes into the existing death interface")
    flow.overlay.retry.pressed.emit()
    for i in 1800:
        await process_frame
        if flow.state==flow.State.PLAYING:break
    check(flow.state==flow.State.PLAYING and not game.dead,"Drowning can retry normally")
    check(not breath.active and breath.elapsed==0.0 and not is_instance_valid(breath.corpse),"Retry cleans up breath, tint and corpse")
    check(sprite.texture==normal_texture and sprite.position==normal_position,"Retry restores the original hell artwork and alignment")
    check(game.demon.get_node("Visual").modulate==Color.WHITE,"Retry clears the underwater redness")
    game.soul.position=game.demon.position+Vector2(-90,0)
    await ticks()
    check(selected.visible and selected.texture.atlas.resource_path.ends_with("hell_demon_selected_v001.png"),"Possession selection artwork still works after drowning retry")
    print("FORMAL_OCEAN_BREATH_FAILURES=",failures.size())
    game.queue_free()
    for i in 3:await process_frame
    quit(0 if failures.is_empty() else 1)
