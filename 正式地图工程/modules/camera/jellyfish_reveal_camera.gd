extends Node2D
## 水母登场拉远同一台正式相机；接近海面后归还构图。
signal reveal_started
signal reveal_finished
@export var reveal_seconds: float=1.8
@export var return_seconds: float=1.0
@export var wide_zoom: float=.78
@export var minimum_wide_seconds: float=2.0
@export var restore_depth: float=2300.0
@export var fish_readability_scale: float=1.35
enum State { WAITING, REVEALING, WIDE, RETURNING, FINISHED }
var state: State=State.WAITING
var elapsed:=0.0
var _wide_elapsed:=0.0
var _pending:=false
var _rest_zoom:=Vector2.ONE
var _return_zoom:=Vector2.ONE
var _rest_scale:=Vector2.ONE
var _return_scale:=Vector2.ONE
var _band: int=-1
@onready var stage: Node=get_parent()
@onready var level: Node=stage.get_parent().get_parent()
@onready var camera: FollowCamera=level.get_node_or_null("Camera")
@onready var fish: CharacterBody2D=get_node("../Fish")
@onready var sprite: Sprite2D=fish.get_node("Visual/Sprite")
@onready var boss: Node2D=get_node("../JellyfishBoss")
@onready var margins: ColorRect=$WaterMargins
func _ready() -> void:
    process_priority=5
    top_level=true
    if level is Node2D: global_transform=level.global_transform
    _rest_scale=sprite.scale
    margins.hide()
    boss.appeared.connect(func(): _pending=true)
func _process(delta: float) -> void:
    if not is_instance_valid(camera) or not stage.active or stage.level.dead: return
    if state==State.WAITING:
        if _pending and stage.level.player==fish and not stage.possession.shot.active:
            _rest_zoom=camera.zoom
            state=State.REVEALING
            elapsed=0
            margins.show()
            _update_band()
            reveal_started.emit()
        return
    if state==State.FINISHED: return
    var shore=stage.get_node("ShoreExit")
    var grab=stage.get_node("SurfaceGrab")
    if state==State.WIDE: _wide_elapsed+=delta
    var near_surface: bool=fish.position.y<=shore.surface_y+restore_depth
    var surface_sequence: bool=shore.state!=shore.State.SWIMMING or grab.state in [grab.State.WARNING,grab.State.REACHING,grab.State.CAUGHT]
    if state!=State.RETURNING and ((near_surface and state==State.WIDE and _wide_elapsed>=minimum_wide_seconds) or surface_sequence or stage.level.player!=fish):
        state=State.RETURNING
        elapsed=0
        _return_zoom=camera.zoom
        _return_scale=sprite.scale
    elapsed+=delta
    if state==State.REVEALING:
        var u:=smoothstep(0,reveal_seconds,elapsed)
        camera.zoom=_rest_zoom.lerp(Vector2.ONE*wide_zoom,u)
        sprite.scale=_rest_scale*lerpf(1,fish_readability_scale,u)
        if elapsed>=reveal_seconds:
            state=State.WIDE
            _wide_elapsed=0
            reveal_finished.emit()
    elif state==State.RETURNING:
        # If the surface camera has already taken ownership, do not compete with it.
        if grab.shot._owned:
            _finish_return(false)
            return
        var u:=smoothstep(0,return_seconds,elapsed)
        camera.zoom=_return_zoom.lerp(_rest_zoom,u)
        sprite.scale=_return_scale.lerp(_rest_scale,u)
        if elapsed>=return_seconds: _finish_return()
    _update_band()
func finish_for_surface() -> void:
    if state not in [State.WAITING,State.FINISHED]: _finish_return()
func _finish_return(restore_zoom: bool=true) -> void:
    if restore_zoom: camera.zoom=_rest_zoom
    sprite.scale=_rest_scale
    margins.hide()
    state=State.FINISHED
func _update_band() -> void:
    var band:=clampi(int(floor(level.to_local(camera.global_position).y/2048)),14,19)
    if band==_band: return
    _band=band
    var material: ShaderMaterial=margins.material
    material.set_shader_parameter("map_origin",global_position)
    material.set_shader_parameter("map_scale",global_scale)
    material.set_shader_parameter("map_band",float(band))
    material.set_shader_parameter("map_above",load("res://assets/art/reference_map/%02d.png"%(band-1)))
    material.set_shader_parameter("map_current",load("res://assets/art/reference_map/%02d.png"%band))
    material.set_shader_parameter("map_below",load("res://assets/art/reference_map/%02d.png"%(band+1)))
func reset() -> void:
    if state not in [State.WAITING,State.FINISHED] and is_instance_valid(camera): camera.zoom=_rest_zoom
    state=State.WAITING
    elapsed=0
    _wide_elapsed=0
    _pending=false
    _band=-1
    sprite.scale=_rest_scale
    margins.hide()
