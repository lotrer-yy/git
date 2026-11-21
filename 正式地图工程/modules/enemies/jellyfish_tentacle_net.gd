extends Node2D
## 从玩家前上方侧墙预警，一次预判后固定方向穿刺。
signal row_started(height: float)
signal player_hit(direction: Vector2)
const WARNING = preload("res://modules/visual/tentacle_warning.gd")
const TENDRIL = preload("res://modules/visual/jellyfish_net_tendril.gd")
@export var enabled: bool = false
@export var wave_interval: float = 1.8
@export var minimum_ascent: float = 180.0
@export var spawn_ahead_pixels: float = 360.0
@export var tentacle_thickness: float = 144.0
@export var half_row_height: float = 60.0
@export var charge_seconds: float = 1.35
@export var strike_seconds: float = .18
@export var prediction_seconds: float = .05
@export var maximum_rows: int = 6
var rows: Array[Dictionary] = []
var target: CharacterBody2D
var boss: Node2D
var edge_provider: Node2D
var camera: Camera2D
var _elapsed: float = 0.0
var _last_row_y: float = INF
var _side: int = -1
var _hit: bool = false
var _blink_grace: float = 0.0

func configure(player: CharacterBody2D, jellyfish: Node2D, walls: Node2D) -> void:
    if is_instance_valid(target):
        var old_blink := target.get_node_or_null("Teleport")
        if old_blink!=null and old_blink.teleported.is_connected(_on_teleported):
            old_blink.teleported.disconnect(_on_teleported)
    target = player
    var blink := target.get_node_or_null("Teleport")
    if blink!=null: blink.teleported.connect(_on_teleported)
    camera = jellyfish.camera
    boss = jellyfish
    edge_provider = walls

func _physics_process(delta: float) -> void:
    if not enabled or not is_instance_valid(target): return
    _elapsed += delta
    _blink_grace = maxf(0,_blink_grace-delta)
    var fish_y := to_local(target.global_position).y
    if _blink_grace<=0 and boss.state==boss.State.PRESENT and _elapsed>=wave_interval and (_last_row_y==INF or _last_row_y-fish_y>=minimum_ascent): _spawn_row()
    var remove: Array[Dictionary] = []
    for row in rows:
        row.age += delta
        row.dodge_grace = maxf(0,row.dodge_grace-delta)
        var row_top: float = row.node.position.y
        var center: Vector2 = target.get_node("Collision").global_position
        for tendril in row.arms:
            var t: float = row.age-tendril.delay
            if not tendril.cancelled and not tendril.warning_confirmed and t>=.28:
                var tip: Vector2 = tendril.to_global(tendril.start+(tendril.finish-tendril.start).normalized()*150)
                # 确认露头和预警被看到后便承诺出手；游出镜头不会取消或转向。
                if _view_rect().grow(-20).has_point(tip):
                    tendril.warning_confirmed = true
                else:
                    tendril.cancel()
            tendril.sample(row.age)
            var warning: Node2D = tendril.get_node("Warning")
            warning.sample(t-.18)
            if tendril.cancelled: warning.hide()
            row_top = minf(row_top,row.node.position.y+minf(tendril.start.y,tendril.finish.y))
            var local_center: Vector2 = tendril.to_local(center)
            var nearby: bool = local_center.y>=minf(tendril.start.y,tendril.finish.y)-tentacle_thickness and local_center.y<=maxf(tendril.start.y,tendril.finish.y)+tentacle_thickness
            var teleport := target.get_node_or_null("Teleport")
            if row.dodge_grace<=0 and nearby and not _hit and (teleport==null or not teleport.is_invulnerable()) and tendril.touches(center,24):
                _hit = true
                player_hit.emit(Vector2(float(-_side),-.5))
        if row_top-fish_y>1900: remove.append(row)
    for row in remove:
        row.node.queue_free()
        rows.erase(row)

func _spawn_row() -> void:
    _elapsed = 0
    var point := to_local(target.global_position)
    _last_row_y = point.y
    var root := Node2D.new()
    add_child(root)
    var view := _view_rect()
    root.position.y = clampf(point.y-spawn_ahead_pixels,to_local(view.position).y+240,to_local(view.end).y-150)
    var bounds: Vector2 = edge_provider._bounds_at(root.position.y)
    var arms: Array[Node2D] = []
    for i in 2:
        var side := _side if i==0 else -_side
        var tendril := TENDRIL.new()
        tendril.thickness = tentacle_thickness
        tendril.charge_seconds = charge_seconds
        tendril.strike_seconds = strike_seconds
        tendril.delay = float(i)*.18
        tendril.start = Vector2(bounds.x-80 if side<0 else bounds.y+80,-half_row_height)
        tendril.finish = Vector2(bounds.y+80 if side<0 else bounds.x-80,half_row_height)
        root.add_child(tendril)
        _aim_tendril(tendril)
        var exposed: Vector2 = tendril.start+(tendril.finish-tendril.start).normalized()*150
        var warning := WARNING.new()
        warning.name = "Warning"
        warning.position = exposed+Vector2(0,-100)
        tendril.add_child(warning)
        if not view.grow(-20).has_point(tendril.to_global(exposed)):
            tendril.cancel()
        tendril.sample(0)
        arms.append(tendril)
    rows.append({"node":root,"arms":arms,"age":0.0,"aim_frozen":true,"dodge_grace":0.0})
    _side = -_side
    if rows.size()>maximum_rows:
        var old: Dictionary = rows.pop_front()
        old.node.queue_free()
    row_started.emit(root.position.y)

func _aim_tendril(tendril: Node2D) -> void:
    # 只在生成时预判一次；蓄力、瞬移和镜头移动均不改变射线。
    var aim: Vector2 = tendril.to_local(target.get_node("Collision").global_position+target.velocity*prediction_seconds)
    var dx: float = aim.x-tendril.start.x
    if absf(dx)<80: dx = 80.0 if tendril.finish.x>tendril.start.x else -80.0
    var slope := clampf((aim.y-tendril.start.y)/dx,-1.5,1.5)
    tendril.finish.y = tendril.start.y+slope*(tendril.finish.x-tendril.start.x)

func _view_rect() -> Rect2:
    if not is_instance_valid(camera): return Rect2()
    var size := camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)

func _on_teleported(_from: Vector2, _destination: Vector2) -> void:
    # 瞬移骗过正在蓄力的整组触手，延迟的第二根也不能重新锁定落点。
    for row in rows:
        row.aim_frozen = true
        row.dodge_grace = .65
    _blink_grace = .65

func reset() -> void:
    enabled = false
    for row in rows: row.node.queue_free()
    rows.clear()
    _elapsed = 0
    _last_row_y = INF
    _side = -1
    _hit = false
    _blink_grace = 0
