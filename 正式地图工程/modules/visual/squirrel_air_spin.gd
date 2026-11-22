extends Node2D
## 松藤后用作者团身原画连续后空翻，只作用于视觉，不改变身体碰撞、抛物线或二段跳。
const ART=preload("res://assets/art/characters/squirrel/formal/backflip.png")
@export var slow_turns_per_second: float=1.2
@export var fast_turns_per_second: float=2.0
var _turn_direction: float=1.0
var active: bool=false
var elapsed: float=0
var turns_per_second: float=2
var sprite: Sprite2D
@onready var body: CharacterBody2D=get_parent()
@onready var source: Sprite2D=body.get_node("Visual/Sprite")
func _ready() -> void:
    process_priority=10
    var atlas:=AtlasTexture.new()
    atlas.atlas=ART
    atlas.region=Rect2(127,2291,147,146)
    atlas.filter_clip=true
    sprite=Sprite2D.new()
    sprite.texture=atlas
    sprite.offset=Vector2(.5,0)
    sprite.z_index=2
    var material:=ShaderMaterial.new()
    material.shader=preload("res://shaders/white_paper_cutout.gdshader")
    sprite.material=material
    add_child(sprite)
    sprite.hide()
    body.get_node("VineClimber").released.connect(begin)
func begin(launch_velocity: Vector2) -> void:
    if not body.get_node("Host").claimed: return
    active=true
    elapsed=0
    _turn_direction=1.0
    turns_per_second=lerpf(slow_turns_per_second,fast_turns_per_second,clampf(launch_velocity.length()/1600,0,1))
    source.hide()
    body.get_node("Visual/SelectedSprite").hide()
    sprite.show()
    sample(0)
func _process(delta: float) -> void:
    if not active: return
    var level: Node=body.get_node("Defeat").level
    if level!=null and level.dead:
        stop(false)
        return
    if body.get_node("VineClimber").vine!=null or body.is_on_floor() or not body.get_node("Host").claimed:
        stop()
        return
    elapsed+=delta
    sample(elapsed)
func sample(time: float) -> void:
    var phase: float=time*TAU*turns_per_second*_turn_direction
    var pop: float=1+.08*sin(minf(time/.18,1)*PI)
    sprite.global_position=source.global_position
    sprite.global_rotation=body.global_rotation+phase
    sprite.global_scale=body.global_scale*1.1*pop
    sprite.flip_h=source.flip_h
    sprite.offset.x=-10.5 if source.flip_h else .5
func stop(restore: bool=true) -> void:
    active=false
    elapsed=0
    if is_instance_valid(sprite): sprite.hide()
    if restore: source.show()
func reset() -> void:
    stop()
