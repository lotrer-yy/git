extends Node
## 快捷入口只定位到正式地图原有入口，不加载旧原型地图。
const SURFACE = preload("res://modules/environment/hell_surface.gd")
@onready var level: Node2D = get_parent()

func start_segment(index: int) -> void:
    var entry = level.get_node("WallEntry")
    var camera: FollowCamera = level.camera
    # 对齐正常开场完成后的 1.35 倍视野；先设缩放，再计算入口构图和边界。
    camera.zoom = Vector2.ONE * 1.35
    if index == 1:
        entry.reset_for_replay()
        camera.set_follow_target(level.soul,true)
        camera.set_process(true)
        camera.make_current()
        Bgm.play_track(Bgm.Track.HELL)
        entry.play()
    elif index == 2:
        entry.reset_for_replay()
        entry.completed = true
        level.soul.hide()
        level.awake = true
        level.sleeping.hide()
        level.zzz.hide()
        level.demon.get_node("Visual").show()
        level.demon.get_node("Host").take_control()
        level.player = level.demon
        level.possession.state = PossessionController.State.POSSESSED
        level.possession.enabled = false
        level.demon.global_position = SURFACE.landing_on(level.get_node("Platforms/Breakable09"))+Vector2(0,-3)
        level.demon.velocity = Vector2.ZERO
        level.demon.reset_physics_interpolation()
        level.get_node("RisingLava").start_at_checkpoint(level.demon)
        camera.set_follow_target(level.demon,true)
        camera.set_process(true)
        camera.make_current()
        Bgm.play_track(Bgm.Track.HELL)

    elif index == 3:
        entry.reset_for_replay()
        entry.completed = true
        level.soul.hide()
        level.demon.hide()
        level.sleeping.hide()
        level.zzz.hide()
        level.awake = true
        level.possession.enabled = false
        level.get_node("CameraAttention").enabled = false
        level.get_node("FlyingEnemies").enabled = false
        level.get_node("FlyingEnemies").reset()
        level.get_node("Fork").set_physics_process(false)
        level.get_node("Fork").set_process_unhandled_input(false)
        var link := level.get_node("OceanLink")
        link.stage = link.Stage.OCEAN
        var stage := link.get_node("FishStage")
        stage.activate()
        stage.fish.position = Vector2(960,32400)
        stage.fish.reset_physics_interpolation()
        stage.host.take_control()
        stage.possession.state = PossessionController.State.POSSESSED
        stage.possession.enabled = false
        stage._on_transfer_finished(stage.host)
        var boss := stage.get_node("JellyfishBoss")
        boss.enabled = true
        boss._start_y = stage.fish.global_position.y+boss.ascent_before_entrance
        boss._has_baseline = true
        camera.set_follow_target(stage.fish,true)
        camera.set_process(true)
        camera.make_current()
        boss._begin_entrance()
        Bgm.play_track(Bgm.Track.OCEAN)
