extends Node
## 距离驱动脚步，受控角色才发声；空中、AI巡逻、画外或预载阶段保持安静。
@export var stride: float = 85.0
var _distance: float = 0.0
var _previous: Vector2
@onready var body: CharacterBody2D = get_parent()
func _ready() -> void:
 _previous=body.global_position
 process_physics_priority=5
func _physics_process(_delta: float) -> void:
 var distance:=absf(body.global_position.x-_previous.x)
 _previous=body.global_position
 var input=body.get_node_or_null("Input")
 if input==null or not input.enabled or not body.is_on_floor() or absf(body.velocity.x)<30.0 or distance>80.0:
  _distance=0.0
  return
 _distance+=distance
 if _distance>=stride:
  _distance=fmod(_distance,stride)
  var screen_point:=body.get_global_transform_with_canvas().origin
  if body.is_visible_in_tree() and get_viewport().get_visible_rect().grow(80.0).has_point(screen_point):
   get_node("/root/Sfx").play(&"step",body.global_position,0.5 if body.name==&"Soul" else 0.85)
