extends Node
## 声音接线与玩法解耦；按模块公开信号绑定，后台预载和画外角色保持安静。
const Steps = preload("res://modules/audio/actor_footsteps.gd")
@onready var sfx: Node = get_parent()

func _ready() -> void:
 get_tree().node_added.connect(_schedule)
 _walk(get_tree().root)

func _walk(node: Node) -> void:
 _schedule(node)
 for child in node.get_children(): _walk(child)

func _schedule(node: Node) -> void:
 _bind.call_deferred(node)

func audible(node: Node) -> bool:
 if not is_instance_valid(node) or not node.is_inside_tree(): return false
 var anchor:=_anchor(node)
 if anchor==null or not anchor.is_visible_in_tree(): return false
 var point:=anchor.get_global_transform_with_canvas().origin
 return get_viewport().get_visible_rect().grow(240.0).has_point(point)

func _anchor(node: Node) -> CanvasItem:
 var cursor:Node=node
 while cursor!=null:
  if cursor is CanvasItem: return cursor
  cursor=cursor.get_parent()
 return null

func sound(node: Node, event: StringName, strength: float = 1.0, ui: bool = false) -> void:
 if audible(node):
  var anchor:=_anchor(node)
  sfx.play(event,anchor.global_position if anchor is Node2D else Vector2.ZERO,strength,ui)

func bind0(node: Node, signal_name: StringName, event: StringName, strength: float = 1.0, ui: bool = false) -> void:
 if node.has_signal(signal_name): node.connect(signal_name,func():sound(node,event,strength,ui))

func _bind(node: Node) -> void:
 if not is_instance_valid(node) or not node.is_inside_tree() or node.has_meta("sfx_bound"): return
 node.set_meta("sfx_bound",true)
 if node.scene_file_path=="res://scenes/ui/main_menu.tscn": sfx.reset()
 if node is BaseButton and node.name in [&"Start",&"Settings"]:
  bind0(node,&"mouse_entered",&"hover",0.8,true)
  bind0(node,&"pressed",&"click",1.0,true)
  if node.name==&"Start": bind0(node,&"pressed",&"charge",0.7,true)
 var script:Script=node.get_script()
 if script==null: return
 match script.resource_path.get_file():
  "platformer_motor.gd":
   node.jumped.connect(func():sound(node,&"jump",0.8))
   node.landed.connect(func(speed:float):
    if speed>180.0: sound(node,&"land",clampf(speed/1300.0,0.2,1.0)))
   var steps:=Steps.new()
   node.get_parent().add_child(steps)
  "flap_motor.gd": bind0(node,&"flapped",&"flap",0.7)
  "possessable_host.gd": bind0(node,&"selected",&"select")
  "possession_controller.gd":
   node.possession_started.connect(func(host):sound(host.body,&"possess_in"))
   node.possession_finished.connect(func(host):sound(host.body,&"possess_out"))
  "menu_descent_transition.gd": node.descent_started.connect(func():sfx.start_descent(node))
  "loading_arrival_motion.gd": node.arrived.connect(sfx.release_descent)
  "loading_character_bounce.gd":
   bind0(node,&"entered",&"mini_pop",0.6,true)
   bind0(node,&"leaving",&"mini_pop",0.45,true)
  "elastic_pulse.gd":
   var parent:=node.get_parent()
   if parent.name in [&"Logo",&"God"]: bind0(node,&"pulsed",&"duang",0.6,true)
   elif parent.get_parent()!=null and parent.get_parent().get_script()!=null and parent.get_parent().get_script().resource_path.get_file()=="loading_character_bounce.gd":
    bind0(node,&"pulsed",&"mini_pop",0.28,true)
  "menu_bird_drag.gd":
   bind0(node,&"grabbed",&"duang",0.7)
   bind0(node,&"released",&"wall_pop",0.6)
  "cinematic_runner.gd":
   bind0(node,&"stepped",&"step",0.55 if node.name==&"Ghost" else 0.9)
  "opening_chase_director.gd":
   node.chase_started.connect(func():sfx.play(&"whoosh",Vector2.ZERO,0.7,true))
   node.ghost_returned.connect(func():sfx.play(&"whoosh",Vector2.ZERO,0.45,true))
   node.finished.connect(func():sfx.play(&"wall_enter",Vector2.ZERO,0.8,true))
  "near_miss_volley.gd", "surface_arrow_volley.gd":
   node.arrow_fired.connect(func(index:int):_arrow_fired(node,index))
  "pillar_game_handoff.gd":
   node.pan_started.connect(func():sfx.play(&"whoosh",Vector2.ZERO,0.45,true))
   node.finished.connect(func():sound(node.gameplay.get_node("Soul"),&"wall_pop"))
  "vortex_exit.gd": node.capture_started.connect(func(body):sound(body,&"wall_enter"))
  "volcano_launch.gd": node.erupted.connect(func():sfx.play(&"eruption",Vector2.ZERO,1.0,true))
  "fish_shore_exit.gd":
   bind0(node,&"landed_on_shore",&"land")
   bind0(node,&"died_on_shore",&"bubble",0.6)
  "drowning_source.gd": bind0(node,&"drowned",&"bubble",0.7)
  "canopy_sky_exit.gd": node.arrived.connect(func():sfx.play(&"rustle",Vector2.ZERO,0.8,true))
  "sky_heaven_exit.gd": node.arrived.connect(func(_ghost):sfx.play(&"chime",Vector2.ZERO,0.9,true))

func _arrow_fired(volley: Node, index: int) -> void:
 var arrow:Node2D=volley.get_node_or_null("Arrow%d"%(index+1))
 if arrow==null: return
 sound(arrow,&"arrow_fly",0.8)
 arrow.landed.connect(func():sound(arrow,&"arrow_hit",0.8))
