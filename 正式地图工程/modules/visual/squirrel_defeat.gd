extends Node2D
## 被击中立即换作者晕倒原图；使用图集区域与白底透明着色器保留源素材。
const ART=preload("res://assets/art/characters/squirrel/formal/stunned.png")
var corpse: Sprite2D
var level: Node
@onready var body: CharacterBody2D=get_parent()
func _ready() -> void:
    level=body
    while level!=null and not level.has_signal("died"): level=level.get_parent()
    var region:=AtlasTexture.new()
    region.atlas=ART
    region.region=Rect2(518,2551,217,160)
    region.filter_clip=true
    corpse=Sprite2D.new()
    corpse.texture=region
    corpse.z_index=3
    var material:=ShaderMaterial.new()
    material.shader=preload("res://shaders/white_paper_cutout.gdshader")
    corpse.material=material
    add_child(corpse)
    corpse.hide()
    if level!=null: level.died.connect(_on_death)
func _on_death() -> void:
    if level.player!=body: return
    body.get_node("AirSpin").stop(false)
    var visual: Node2D=body.get_node("Visual")
    var source: Sprite2D=visual.get_node("Sprite")
    # 对齐现有身体中心和朝向，不带入3240像素画布的留白。
    corpse.global_transform=visual.global_transform*source.transform
    corpse.scale*=208.0/217.0
    corpse.flip_h=source.flip_h
    corpse.show()
    source.hide()
    visual.get_node("SelectedSprite").hide()
    body.get_node("Input").enabled=false
    body.get_node("Input").clear()
    body.get_node("Movement").enabled=false
    body.get_node("VineClimber").set_physics_process(false)
    body.velocity=Vector2.ZERO
    body.set_active(false)
func reset() -> void:
    if is_instance_valid(corpse): corpse.hide()
    body.get_node("Visual/Sprite").show()
    body.get_node("VineClimber").set_physics_process(true)
