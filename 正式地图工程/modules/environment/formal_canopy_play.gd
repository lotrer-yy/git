extends Node
@export_range(.3,1.0) var buried_scale: float=.6
const BOUNCER=preload("res://modules/movement/canopy_bouncer.gd")
const SPRING=preload("res://modules/visual/formal_canopy_fold.gd")
const CLIP=preload("res://shaders/formal_canopy_squirrel.gdshader")
var bouncer: Node
var fold: Sprite2D
var _sprite: Sprite2D
var _original_material: Material
var _original_sprite_scale:=Vector2.ONE
var _clip_material: ShaderMaterial
var _edge_profile: ImageTexture
var _landing_open:=false
@onready var crown: Node2D=get_parent()
func _ready() -> void:
    process_priority=5
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
    var pixels: Image=fold.texture.get_image()
    var edges:=Image.create(pixels.get_width(),1,false,Image.FORMAT_RF)
    for x in pixels.get_width():
        var edge:=1.0
        for y in pixels.get_height():
            if pixels.get_pixel(x,y).a>.5:
                edge=float(y)/pixels.get_height()
                break
        edges.set_pixel(x,0,Color(edge,0,0))
    _edge_profile=ImageTexture.create_from_image(edges)
    fold.offset=Vector2.ZERO
    fold.z_index=16
    fold.visible=false
    crown.add_child.call_deferred(fold)
func begin(body: CharacterBody2D,x: float) -> void:
    _sprite=body.get_node("Visual/Sprite")
    _original_material=_sprite.material
    _original_sprite_scale=_sprite.scale
    _clip_material=ShaderMaterial.new()
    _clip_material.shader=CLIP
    _clip_material.set_shader_parameter("edge_profile",_edge_profile)
    _sprite.material=_clip_material
    body.get_node("Visual").reset()
    body.get_node("VineClimber").set_physics_process(false)
    crown.layout.get_node("SoftSideReturn").set_physics_process(false)
    bouncer.begin(body,x)
    _sync_lip()
func _place_fold(x: float) -> void:
    fold.position=Vector2(x+34,crown.canopy_y(x)+crown.bounce_inset+2+fold.texture.get_height()*.5)
func pulse(x: float) -> void:
    if bouncer._velocity.y<0:
        _place_fold(x)
        fold.pulse()
        _landing_open=false
        _sprite.scale=_original_sprite_scale*buried_scale
    elif not _landing_open:
        _place_fold(x)
        fold.pulse()
        _landing_open=true
    _sync_lip()
func _predict_landing(p: Vector2) -> float:
    var x: float=p.x
    for i in 2:
        var contact: float=crown.canopy_y(x)+crown.bounce_inset+40
        var distance: float=maxf(0,contact-p.y)
        var vy: float=bouncer._velocity.y
        var time: float=(sqrt(vy*vy+2*bouncer.gravity*distance)-vy)/bouncer.gravity
        x=clampf(p.x+bouncer._velocity.x*minf(time,.22),290,1630)
    return x
func _process(_delta: float) -> void:
    if not is_instance_valid(bouncer) or not bouncer.enabled: return
    var p: Vector2=crown.to_local(bouncer.body.global_position)
    var surface: float=crown.canopy_y(p.x)+crown.bounce_inset
    if not bouncer.buried and bouncer._velocity.y>0 and p.y>surface-65:
        if not _landing_open:
            var destination:=_predict_landing(p)
            bouncer.landing_target_x=destination
            pulse(destination)
    elif bouncer._velocity.y<0:
        _landing_open=false
    if bouncer._velocity.y>0:
        var sink:=smoothstep(surface-160,surface+150,p.y)
        _sprite.scale=_original_sprite_scale*lerpf(1.0,buried_scale,sink)
    elif not bouncer.buried:
        var emerge:=1.0-smoothstep(surface-90,surface+bouncer.burial_depth,p.y)
        _sprite.scale=_original_sprite_scale*lerpf(buried_scale,1.0,emerge)
    _sync_lip()
func _sync_lip() -> void:
    if not is_instance_valid(_clip_material): return
    var size: Vector2=fold.texture.get_size()*fold.global_scale.abs()
    if not fold.visible: size=fold.texture.get_size()*crown.global_scale.abs()
    _clip_material.set_shader_parameter("lip_origin",fold.global_position-Vector2(0,size.y*.5))
    _clip_material.set_shader_parameter("lip_size",size.max(Vector2.ONE))
func reset() -> void:
    if is_instance_valid(bouncer): bouncer.reset()
    if is_instance_valid(fold): fold.reset()
    if is_instance_valid(_sprite):
        _sprite.material=_original_material
        _sprite.scale=_original_sprite_scale
    crown.layout.get_node("SoftSideReturn").set_physics_process(true)
