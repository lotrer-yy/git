extends Node2D
## 地面离开镜头后巨蛇从下方追赶；玩家碰松果自动投向蛇头，无慢动作或按键序列。
signal countered
signal player_struck
const BITE = preload("res://scenes/enemies/python_bite_animation.tscn")
const IMPACT = preload("res://modules/visual/python_counter_impact.gd")
enum State { WAITING, ENTERING, PURSUING, WINDUP, LUNGING, RECOVERING, STAGGERED }
@export var shore_art_y: float = 29420.0
@export var warning_seconds: float = 1.0
@export var lunge_seconds: float = .28
@export var attack_rest: float = 5.0
@export var chase_speed: float = 900.0
@export var knockback_seconds: float = 3.0
var state: State = State.WAITING
var elapsed: float = 0
var lifetime: float = 0
var attacks_started: int = 0
var counters: int = 0
var pivot: Node2D
var snake: Node2D
var impact: Node2D
var _facing: float = 1
var _velocity := Vector2.ZERO
var _attack_clock: float = 0
var _lock_rotation: float = 0
var _aim := Vector2.ZERO
var _strike_start := Vector2.ZERO
var _previous_mouth := Vector2.ZERO
var _hit_this_attack: bool = false
var _ground_hidden_seconds: float = 0
@onready var stage: Node = get_node("../..")
@onready var body: CharacterBody2D = get_node("../Squirrel")
func _ready() -> void:
    z_index=9
    pivot=Node2D.new()
    pivot.scale=Vector2.ONE*1.8
    add_child(pivot)
    snake=BITE.instantiate()
    snake.position=Vector2.ZERO
    pivot.add_child(snake)
    snake.set_process(false)
    snake.enable_neck_extension()
    impact=Node2D.new()
    impact.set_script(IMPACT)
    impact.z_index=4
    add_child(impact)
    impact.hide()
    pivot.hide()
    if stage.has_node("ShoreExit") and stage.get_parent().get_parent().has_signal("died"):
        stage.get_parent().get_parent().died.connect(reset)
func can_play() -> bool:
    if not stage.has_node("ShoreExit"): return false
    return stage.active and not stage.level.dead and stage.level.player==body and body.get_node("Host").claimed
func view_rect() -> Rect2:
    var camera: Camera2D = stage.level.camera
    var size: Vector2 = camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)
func ground_hidden() -> bool:
    var ground: float = get_parent().to_global(Vector2(960,shore_art_y)).y
    return view_rect().end.y<ground-40
func is_targetable() -> bool:
    return can_play() and state!=State.WAITING and pivot.visible
func target_position() -> Vector2:
    const CENTERS = [Vector2(215,112),Vector2(225,190),Vector2(240,140),Vector2(250,110),Vector2(330,185),Vector2(330,170),Vector2(220,180),Vector2(205,120)]
    var frame: int = snake.frames.find(snake.layers[0].texture)
    return snake.layers[0].to_global(snake.deformed_point(maxi(0,frame),CENTERS[maxi(0,frame)]))
func _physics_process(delta: float) -> void:
    if not can_play():
        if state!=State.WAITING: reset()
        return
    elapsed+=delta
    lifetime+=delta
    if state!=State.WAITING: _keep_base_below_frame()
    if state==State.WAITING:
        _ground_hidden_seconds=_ground_hidden_seconds+delta if ground_hidden() else 0.0
        if _ground_hidden_seconds>=.4: _begin_entrance()
        return
    # 玩家落回岸上时蛇重新潜下，不在出水或附身阶段袭击。
    if not ground_hidden() and body.global_position.y>get_parent().to_global(Vector2(960,shore_art_y-120)).y:
        reset()
        return
    if state in [State.ENTERING,State.PURSUING]:
        _chase(delta)
        _look_at_player(delta)
        snake.neck_extension=0
        snake.sample(-1)
        _attack_clock+=delta
        if state==State.ENTERING and elapsed>1.2:
            state=State.PURSUING
            elapsed=0
        elif state==State.PURSUING and _attack_clock>=attack_rest and _on_screen():
            _begin_windup()
    elif state==State.WINDUP:
        # 先跟随瞄准，最后300毫秒锁死，扑出后不随相机或玩家修正。
        if elapsed<warning_seconds-.3:
            _look_at_player(delta)
            _aim=_predicted_aim()
            _lock_rotation=pivot.rotation
        snake.sample(.08+.36*clampf(elapsed/warning_seconds,0,1))
        if elapsed>=warning_seconds:
            state=State.LUNGING
            elapsed=0
            _strike_start=pivot.global_position
            _previous_mouth=_mouth_position()
    elif state==State.LUNGING:
        var u: float = clampf(elapsed/lunge_seconds,0,1)
        # 根部只在画面以下横移，咬向锁定目标靠脖子伸长。
        pivot.rotation=_lock_rotation
        pivot.scale=Vector2(_facing*1.8,1.8)
        snake.neck_extension=0
        snake.sample(.44+.245*u)
        var rest_mouth: Vector2 = _mouth_position()
        var extension: float = clampf((rest_mouth.y-_aim.y)/maxf(1.8*snake.scale.y*cos(pivot.rotation),.5),0,440)
        snake.neck_extension=extension*smoothstep(0,1,u)
        snake.sample(.44+.245*u)
        var offset: Vector2 = _mouth_position()-pivot.global_position
        pivot.global_position.x=lerpf(_strike_start.x,_aim.x-offset.x,smoothstep(0,1,u))
        _keep_base_below_frame()
        var mouth: Vector2 = _mouth_position()
        var center: Vector2 = body.global_position+Vector2(0,-50)
        var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(center,_previous_mouth,mouth)
        if not _hit_this_attack and nearest.distance_to(center)<95 and view_rect().grow(60).has_point(mouth):
            _hit_player()
        _previous_mouth=mouth
        if u>=1:
            state=State.RECOVERING
            elapsed=0
    elif state==State.RECOVERING:
        snake.neck_extension=move_toward(snake.neck_extension,0,delta*800)
        snake.sample(.685+elapsed)
        pivot.global_position+=Vector2(0,200)*delta
        _look_at_player(delta*.5)
        if elapsed>=.6:
            state=State.PURSUING
            elapsed=0
            _attack_clock=0
    elif state==State.STAGGERED:
        snake.neck_extension=move_toward(snake.neck_extension,0,delta*900)
        _velocity=_velocity.move_toward(Vector2(0,110),delta*300)
        pivot.global_position+=_velocity*delta
        pivot.rotation=lerp_angle(pivot.rotation,0,1-exp(-delta*3))
        snake.sample(.685+elapsed)
        pivot.modulate=Color(1.8,1.6,1.2).lerp(Color.WHITE,smoothstep(0,.25,elapsed))
        if elapsed>=knockback_seconds:
            state=State.PURSUING
            elapsed=0
            _attack_clock=0
func _begin_entrance() -> void:
    var view: Rect2 = view_rect()
    _facing=1 if body.global_position.x<960 else -1
    pivot.scale=Vector2(_facing*1.8,1.8)
    pivot.rotation=0
    snake.neck_extension=0
    pivot.global_position=Vector2(clampf(body.global_position.x-_facing*280,80,1840),view.end.y+920)
    _velocity=Vector2.ZERO
    state=State.ENTERING
    elapsed=0
    _attack_clock=attack_rest-1.8
    pivot.modulate=Color.WHITE
    pivot.show()
    _look_at_player(1)
func _chase(delta: float) -> void:
    var desired:=Vector2(clampf(body.global_position.x-_facing*260+sin(lifetime*.8)*180,80,1840),body.global_position.y+800+sin(lifetime*1.35)*65)
    var goal_velocity: Vector2 = ((desired-pivot.global_position)*2.8).limit_length(chase_speed)
    _velocity=_velocity.move_toward(goal_velocity,delta*950)
    pivot.global_position+=_velocity*delta
    _keep_base_below_frame()
func _keep_base_below_frame() -> void:
    pivot.global_position.y=maxf(pivot.global_position.y,view_rect().end.y+300)
func _look_at_player(delta: float) -> void:
    var direction: Vector2 = body.global_position+Vector2(0,-50)-target_position()
    var angle: float = clampf(wrapf(direction.angle()-(PI if _facing<0 else 0),-PI,PI),-.14,.14)
    pivot.scale=Vector2(_facing*1.8,1.8)
    pivot.rotation=lerp_angle(pivot.rotation,wrapf(angle,-PI,PI),1-exp(-delta*4))
func _mouth_position() -> Vector2:
    const POINTS = [Vector2(302,149),Vector2(337,215),Vector2(300,218),Vector2(310,244),Vector2(380,220),Vector2(420,190),Vector2(350,200),Vector2(303,150)]
    var frame: int = maxi(0,snake.frames.find(snake.layers[0].texture))
    return snake.layers[0].to_global(snake.deformed_point(frame,POINTS[frame]))
func _on_screen() -> bool:
    return view_rect().grow(80).has_point(target_position())
func _predicted_aim() -> Vector2:
    var predicted: Vector2 = body.global_position+Vector2(0,-50)+(body.velocity*.18).limit_length(150)
    return predicted
func _begin_windup() -> void:
    attacks_started+=1
    state=State.WINDUP
    elapsed=0
    _hit_this_attack=false
    _aim=_predicted_aim()
    _lock_rotation=pivot.rotation
func _hit_player() -> void:
    _hit_this_attack=true
    var climber = body.get_node("VineClimber")
    if is_instance_valid(climber.vine): climber.detach(false)
    var away: float = signf(body.global_position.x-pivot.global_position.x)
    if away==0: away=1
    body.get_node("Movement").launch_with_momentum(Vector2(away*500,380))
    body.get_node("Visual").play_selection_pulse()
    player_struck.emit()
func hit_by_pinecone(world_hit: Vector2,incoming: Vector2) -> bool:
    if not is_targetable(): return false
    counters+=1
    state=State.STAGGERED
    elapsed=0
    _attack_clock=0
    _velocity=Vector2(incoming.x*.2,500)
    impact.play_at(world_hit)
    pivot.modulate=Color(1.8,1.6,1.2)
    countered.emit()
    return true
func reset() -> void:
    state=State.WAITING
    elapsed=0
    lifetime=0
    attacks_started=0
    counters=0
    _attack_clock=0
    _ground_hidden_seconds=0
    _velocity=Vector2.ZERO
    if is_instance_valid(snake): snake.neck_extension=0
    if is_instance_valid(pivot):
        pivot.hide()
        pivot.modulate=Color.WHITE
    if is_instance_valid(impact): impact.hide()
