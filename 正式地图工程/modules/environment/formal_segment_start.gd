extends Node
## 快捷入口只定位到正式地图原有入口，不加载旧原型地图。
const SURFACE = preload("res://modules/environment/hell_surface.gd")
@onready var level: Node2D = get_parent()

func start_segment(index: int) -> void:
    var entry = level.get_node("WallEntry")
    var camera: FollowCamera = level.camera
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
        camera.zoom = Vector2.ONE
        camera.set_follow_target(level.demon,true)
        camera.set_process(true)
        camera.make_current()
        Bgm.play_track(Bgm.Track.HELL)
