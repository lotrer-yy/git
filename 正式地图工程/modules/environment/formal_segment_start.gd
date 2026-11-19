extends Node
## 快捷入口只组装正式场景已有的洞口弹出与海底喷出，不加载旧原型地图。
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
        var link = level.get_node("OceanLink")
        link._capture(level.demon)
        link.transition.cancel()
        camera.adopt_view(link.ocean_mouth.global_position+Vector2(0,-300),Vector2.ONE)
        camera.set_process(false)
        camera.make_current()
        link._arrive()
