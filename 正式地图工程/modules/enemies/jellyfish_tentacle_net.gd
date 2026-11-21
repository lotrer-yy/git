extends Node2D
## 从下方侧墙蓄力瞄准玩家，刺出后固定于原水域。
signal row_started(height: float)
signal player_hit(direction: Vector2)
const TENDRIL = preload("res://modules/visual/jellyfish_net_tendril.gd")
@export var enabled: bool = false
@export var wave_interval: float = 1.8
@export var minimum_ascent: float = 180.0
@export var gap_below_player: float = 190.0
@export var tentacle_thickness: float = 144.0
@export var half_row_height: float = 60.0
@export var charge_seconds: float = .6
@export var strike_seconds: float = .18
@export var aim_lock_seconds: float = .25
@export var prediction_seconds: float = .05
@export var maximum_rows: int = 6
var rows: Array[Dictionary] = []
var target: CharacterBody2D
var boss: Node2D
var edge_provider: Node2D
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
        row.node.visible = row.node.position.y-fish_y<650
        var center: Vector2 = target.get_node("Collision").global_position
        for tendril in row.arms:
            if not row.aim_frozen and row.age-tendril.delay<charge_seconds-aim_lock_seconds:
                _aim_tendril(tendril)
            tendril.sample(row.age)
            var local_center: Vector2 = tendril.to_local(center)
            var nearby: bool = local_center.y>=minf(tendril.start.y,tendril.finish.y)-tentacle_thickness and local_center.y<=maxf(tendril.start.y,tendril.finish.y)+tentacle_thickness
            var teleport := target.get_node_or_null("Teleport")
            if nearby and not _hit and (teleport==null or not teleport.is_invulnerable()) and tendril.touches(center,24):
                _hit = true
                player_hit.emit(Vector2(float(-_side),-.5))
        if row.node.position.y-fish_y>1900: remove.append(row)
    for row in remove:
        row.node.queue_free()
        rows.erase(row)

func _spawn_row() -> void:
    _elapsed = 0
    var point := to_local(target.global_position)
    _last_row_y = point.y
    var bounds: Vector2 = edge_provider._bounds_at(point.y+gap_below_player)
    var root := Node2D.new()
    add_child(root)
    root.position.y = point.y+gap_below_player
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
        tendril.sample(0)
        arms.append(tendril)
    rows.append({"node":root,"arms":arms,"age":0.0,"aim_frozen":false})
    _side = -_side
    if rows.size()>maximum_rows:
        var old: Dictionary = rows.pop_front()
        old.node.queue_free()
    row_started.emit(point.y+gap_below_player)

func _aim_tendril(tendril: Node2D) -> void:
    # 锁定前只调整方向，不移动墙内根部；出手后不再追踪玩家。
    var aim: Vector2 = tendril.to_local(target.get_node("Collision").global_position+target.velocity*prediction_seconds)
    var dx: float = aim.x-tendril.start.x
    if absf(dx)<80: dx = 80.0 if tendril.finish.x>tendril.start.x else -80.0
    var slope := clampf((aim.y-tendril.start.y)/dx,-1.5,1.5)
    tendril.finish.y = tendril.start.y+slope*(tendril.finish.x-tendril.start.x)

func _on_teleported(_from: Vector2, _destination: Vector2) -> void:
    # 瞬移骗过正在蓄力的整组触手，延迟的第二根也不能重新锁定落点。
    for row in rows: row.aim_frozen = true
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
