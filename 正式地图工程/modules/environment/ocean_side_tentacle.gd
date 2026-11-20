extends Node2D
## 同一侧连续停留才触发；计时、预备和拍击均不追踪已经离开的鱼。
signal attack_started(side: int)
signal fish_hit
const SHEET = preload("res://assets/art/ocean/tentacle/slap_sheet.png")
const ANCHORS = "res://assets/art/ocean/tentacle/anchors.json"
const WHITE_KEY = preload("res://shaders/tentacle_white_key.gdshader")
@export var edge_band_width: float = 320.0
@export var linger_seconds: float = 2.0
@export var artwork_scale: float = 1.7
@export var emerge_seconds: float = 0.14
@export var raise_seconds: float = 0.18
@export var strike_seconds: float = 0.10
@export var retract_seconds: float = 0.28
@export var cooldown_seconds: float = 0.8
@export var down_speed: float = 900.0
@export var down_gravity: float = 1800.0
var linger_elapsed: float = 0.0
var side: int = 0
var attacking: bool = false
var corpse: Sprite2D
var _clock: float = 0.0
var _cooldown: float = 0.0
var _hit: bool = false
var _anchor := Vector2.ZERO
var _rig: Node2D
var _sprite: Sprite2D
var _frames: Array
var _stroke := PackedVector2Array()
var _centerline := PackedVector2Array()
var _walls_image: Image
var _edge_cache: Dictionary = {}
var _death_motion: Tween
var _death_origin := Vector2.ZERO
var _death_rotation: float = 0.0
var _death_side: int = 0
@onready var stage: Node2D = get_parent()
@onready var level: Node2D = get_node("../../..")
@onready var fish: CharacterBody2D = get_node("../Fish")
@onready var walls: Sprite2D = level.get_node("WorldLayers/OceanWalls")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    z_index = 16 # 鱼 15、触手 16、侧墙 17：根部始终藏在原墙后。
    _frames = JSON.parse_string(FileAccess.get_file_as_string(ANCHORS)).frames
    _walls_image = walls.texture.get_image()
    _rig = Node2D.new()
    add_child(_rig)
    _sprite = Sprite2D.new()
    _sprite.texture = SHEET
    _sprite.centered = false
    _sprite.region_enabled = true
    _sprite.region_filter_clip_enabled = true
    var key := ShaderMaterial.new()
    key.shader = WHITE_KEY
    _sprite.material = key
    _rig.add_child(_sprite)
    _rig.hide()
    _build_stroke()

func _eligible() -> bool:
    var ocean_y: float = level.to_local(fish.global_position).y
    return stage.active and stage.host.claimed and level.player == fish and not level.dead and not level.exit_in_progress and level.visible and ocean_y >= 29978.0 and ocean_y <= 39138.0

func _physics_process(delta: float) -> void:
    if level.dead:
        linger_elapsed = 0.0
        if attacking and level.death_reason == &"tentacle":
            _clock += delta
            _sample_attack()
        return
    if not _eligible():
        linger_elapsed = 0.0
        if not level.dead and attacking: reset()
        return
    if attacking:
        _clock += delta
        _sample_attack()
        return
    _cooldown = maxf(0.0, _cooldown - delta)
    var next_side := _side_at_fish()
    if next_side == 0 or next_side != side or _cooldown > 0.0:
        linger_elapsed = 0.0
    side = next_side
    if side == 0 or _cooldown > 0.0: return
    linger_elapsed += delta
    if linger_elapsed >= linger_seconds: _begin_attack()

func _bounds_at(y: float) -> Vector2:
    var source_y := int(walls.to_local(to_global(Vector2(0,y))).y)
    source_y = clampi(source_y / 8 * 8, 0, _walls_image.get_height()-1)
    if _edge_cache.has(source_y): return _edge_cache[source_y]
    var middle := _walls_image.get_width()/2
    var left := 0
    var right := _walls_image.get_width()-1
    for x in range(middle, -1, -1):
        if _walls_image.get_pixel(x,source_y).a > 0.5:
            left = x
            break
    for x in range(middle, _walls_image.get_width()):
        if _walls_image.get_pixel(x,source_y).a > 0.5:
            right = x
            break
    var result := Vector2(to_local(walls.to_global(Vector2(left,source_y))).x, to_local(walls.to_global(Vector2(right,source_y))).x)
    _edge_cache[source_y] = result
    return result

func _side_at_fish() -> int:
    var point := to_local(fish.global_position)
    var bounds := _bounds_at(point.y)
    if point.x < bounds.x + edge_band_width: return -1
    if point.x > bounds.y - edge_band_width: return 1
    return 0

func _begin_attack() -> void:
    attacking = true
    _hit = false
    _clock = 0.0
    linger_elapsed = 0.0
    var point := to_local(fish.global_position)
    var bounds := _bounds_at(point.y)
    # 左墙向右伸，右墙向左伸；攻击地点在触发时锁定，之后可以躲开。
    var inward := -side
    _anchor = Vector2(bounds.x-28.0 if side < 0 else bounds.y+28.0, point.y)
    var local_x := (point.x-_anchor.x)/(float(inward)*artwork_scale)
    var closest := Vector2.ZERO
    var distance := INF
    for p in _centerline:
        if absf(p.x-local_x) < distance:
            closest = p
            distance = absf(p.x-local_x)
    _anchor.y -= closest.y*artwork_scale
    _rig.scale = Vector2(float(inward)*artwork_scale,artwork_scale)
    _rig.show()
    _sample_attack()
    attack_started.emit(side)

func _show_frame(index: int) -> void:
    var frame: Dictionary = _frames[index]
    var rect: Array = frame.region
    _sprite.region_rect = Rect2(rect[0],rect[1],rect[2],rect[3])
    _sprite.position = -Vector2(frame.pivot[0],frame.pivot[1])

func _sample_attack() -> void:
    var strike_start := emerge_seconds+raise_seconds
    var retract_start := strike_start+strike_seconds
    var finish := retract_start+retract_seconds
    var retreat := 0.0
    if _clock < emerge_seconds:
        _show_frame(0)
        retreat = 100.0*(1.0-smoothstep(0.0,emerge_seconds,_clock))
    elif _clock < strike_start:
        _show_frame(1 if _clock < emerge_seconds+raise_seconds*.5 else 2)
    elif _clock < retract_start:
        _show_frame(3 if _clock < strike_start+strike_seconds*.2 else 4)
    elif _clock < finish:
        _show_frame(5 if _clock < retract_start+retract_seconds*.4 else 0)
        retreat = 470.0*smoothstep(retract_start,finish,_clock)
    else:
        attacking = false
        side = 0
        _cooldown = cooldown_seconds
        _rig.hide()
        return
    _rig.position = _anchor + Vector2(float(side)*retreat,0)
    if _clock >= strike_start+strike_seconds*.2 and _clock < retract_start and not _hit and _touches_fish():
        _hit = true
        fish_hit.emit()
        level.die(&"tentacle")

func _build_stroke() -> void:
    # 从拍下那帧的原像素建立轮廓，伤害区域随朝向镜像，不用整张图的大方框。
    var frame: Dictionary = _frames[4]
    var rect: Array = frame.region
    var pivot := Vector2(frame.pivot[0],frame.pivot[1])
    var image := SHEET.get_image()
    var lower := PackedVector2Array()
    for x in range(12,int(rect[2])-5,5):
        var top := -1
        var bottom := -1
        for y in int(rect[3]):
            var c := image.get_pixel(int(rect[0])+x,int(rect[1])+y)
            if minf(c.r,minf(c.g,c.b)) < 0.85:
                if top < 0: top = y
                bottom = y
        if top < 0: continue
        _stroke.append(Vector2(x,top)-pivot)
        lower.append(Vector2(x,bottom)-pivot)
        _centerline.append(Vector2(x,(top+bottom)*.5)-pivot)
    lower.reverse()
    _stroke.append_array(lower)

func _touches_fish() -> bool:
    var shape := fish.get_node("Collision") as CollisionShape2D
    var center := _rig.to_local(shape.global_position)
    var radius: float = shape.shape.radius / artwork_scale
    if Geometry2D.is_point_in_polygon(center,_stroke): return true
    for i in _stroke.size():
        var nearest := Geometry2D.get_closest_point_to_segment(center,_stroke[i],_stroke[(i+1)%_stroke.size()])
        if center.distance_to(nearest) <= radius: return true
    return false

func play_death() -> void:
    fish.get_node("Input").enabled = false
    fish.get_node("Movement").enabled = false
    fish.velocity = Vector2.ZERO
    var sprite := fish.get_node("Visual/Sprite") as Sprite2D
    corpse = Sprite2D.new()
    corpse.texture = sprite.texture
    corpse.flip_h = sprite.flip_h
    corpse.z_index = -1 # 实际第 15 层，仍被海底侧墙遮挡。
    add_child(corpse)
    corpse.global_position = sprite.global_position
    corpse.global_scale = fish.global_scale
    corpse.global_rotation = sprite.global_rotation
    fish.get_node("Visual").hide()
    _death_origin = corpse.global_position
    _death_rotation = corpse.rotation
    _death_side = side
    var camera: FollowCamera = level.camera
    var bottom: float = camera.global_position.y+camera.get_viewport_rect().size.y*.5/camera.zoom.y
    var drop := maxf(180.0,bottom+120.0-_death_origin.y)
    var seconds := (sqrt(down_speed*down_speed+2.0*down_gravity*drop)-down_speed)/down_gravity
    _death_motion = create_tween().set_ignore_time_scale(true)
    _death_motion.tween_method(_sample_death,0.0,seconds,seconds)
    await _death_motion.finished
    if is_instance_valid(corpse): corpse.hide()

func _sample_death(t: float) -> void:
    corpse.global_position = _death_origin+Vector2(float(-_death_side)*85.0*t,down_speed*t+.5*down_gravity*t*t)
    corpse.rotation = _death_rotation+float(-_death_side)*.85*minf(t/.16,1.0)

func reset() -> void:
    if _death_motion != null: _death_motion.kill()
    if is_instance_valid(corpse): corpse.queue_free()
    corpse = null
    fish.get_node("Visual").show()
    linger_elapsed = 0.0
    side = 0
    attacking = false
    _hit = false
    _clock = 0.0
    _cooldown = 0.0
    _rig.hide()
