extends Node
const BOUNCER=preload("res://modules/movement/canopy_bouncer.gd")
const SPRING=preload("res://modules/visual/canopy_ripple_spring.gd")
const CLIP=preload("res://shaders/formal_canopy_squirrel.gdshader")
var bouncer: Node
var fold: Sprite2D
var _sprite: Sprite2D
var _original_material: Material
@onready var crown: Node2D=get_parent()
func _ready() -> void:
    if not InputMap.has_action(&"flap"):
        InputMap.add_action(&"flap")
        for code in [KEY_W,KEY_SPACE]:
            var key:=InputEventKey.new()
            key.physical_keycode=code
            InputMap.action_add_event(&"flap",key)
    # Parent bouncer to the formal crown, whose coordinates and ripple interface it uses.
    bouncer=BOUNCER.new()
    bouncer.foreground_z_override=15
    bouncer.surface_offset_y=crown.bounce_inset
    crown.add_child.call_deferred(bouncer)
    fold=SPRING.new()
    fold.texture=load("res://assets/art/jungle/formal/canopy_fold.png")
    fold.offset=Vector2(0,fold.texture.get_height()*.5)
    fold.z_index=16
    fold.visible=false
    crown.add_child.call_deferred(fold)
func begin(body: CharacterBody2D,x: float) -> void:
    _sprite=body.get_node("Visual/Sprite")
    _original_material=_sprite.material
    var material:=ShaderMaterial.new()
    material.shader=CLIP
    material.set_shader_parameter("crown",load("res://assets/art/reference_map/08.png"))
    material.set_shader_parameter("crown_origin",crown.layout.to_global(Vector2(0,16384+crown.bounce_inset)))
    material.set_shader_parameter("map_scale",crown.layout.global_scale)
    _sprite.material=material
    body.get_node("Visual").reset()
    body.get_node("VineClimber").set_physics_process(false)
    crown.layout.get_node("SoftSideReturn").set_physics_process(false)
    bouncer.begin(body,x)
func pulse(x: float) -> void:
    fold.position=Vector2(x+34,crown.canopy_y(x)+crown.bounce_inset+2)
    fold.pulse()
func reset() -> void:
    if is_instance_valid(bouncer): bouncer.reset()
    if is_instance_valid(fold): fold.reset()
    if is_instance_valid(_sprite): _sprite.material=_original_material
    crown.layout.get_node("SoftSideReturn").set_physics_process(true)
