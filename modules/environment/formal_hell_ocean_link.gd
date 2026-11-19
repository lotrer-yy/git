extends Node2D
## 正式地狱只负责触发；复用旧版吸入、地层运镜与海底火山喷出。
signal ocean_entered
signal eruption_finished
enum Stage { HELL, CAPTURING, TRAVELLING, OCEAN }
const OCEAN_PATH = "res://scenes/levels/ocean_prototype.tscn"
@export var ocean_origin: Vector2 = Vector2(0, -5619)
var stage: Stage = Stage.HELL
var ocean: Node2D
var _requested: bool = false
@onready var level: Node2D = get_parent()
@onready var camera: FollowCamera = get_node("../Camera")
@onready var output: Node = get_node("../CameraOutput")
@onready var vortex: VortexExit = $Exit
@onready var transition: VerticalSceneTransition = $VerticalTransition
@onready var impact: CameraImpact = $CameraImpact

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 25
    vortex.capture_started.connect(_capture)
    vortex.capture_finished.connect(_travel)
    transition.finished.connect(_arrive)
    var status := ResourceLoader.load_threaded_get_status(OCEAN_PATH)
    _requested = status in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED] or ResourceLoader.load_threaded_request(OCEAN_PATH, "PackedScene") == OK

func _process(_delta: float) -> void:
    if ocean == null and _requested and ResourceLoader.load_threaded_get_status(OCEAN_PATH) == ResourceLoader.THREAD_LOAD_LOADED:
        _prepare_ocean(ResourceLoader.load_threaded_get(OCEAN_PATH))
    if stage == Stage.HELL:
        vortex.eligible_body = level.demon if is_instance_valid(ocean) and not level.dead and level.demon.get_node("Host").claimed else null

func _prepare_ocean(scene: PackedScene) -> void:
    ocean = scene.instantiate()
    ocean.name = "Ocean"
    ocean.position = ocean_origin
    ocean.process_mode = Node.PROCESS_MODE_DISABLED
    var settings: FollowCamera = ocean.get_node("FollowCamera")
    settings.enabled = false
    settings.world_bounds.position += to_global(ocean_origin)
    ocean.get_node("Fish").process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(ocean)
    ocean.camera = camera
    ocean.possession.camera = camera
    ocean.possession.shot._camera = camera
    for name in ["Background", "Foreground"]:
        var layer = ocean.get_node(name)
        layer._camera = camera
        layer.align_vertical_edges = true
        layer.reset_reference()
    ocean.jungle.set_camera(camera)
    impact.camera = camera
    ocean.launch.erupted.connect(impact.kick_up)
    ocean.launch.finished.connect(func(): eruption_finished.emit())
    ocean.round_restarted.connect(impact.reset)
    ocean.round_restarted.connect(func(): Bgm.play_track(Bgm.Track.OCEAN))
    ocean.shore.landed_on_shore.connect(func(): Bgm.play_track(Bgm.Track.JUNGLE))
    ocean.jungle.sky_exit.arrived.connect(func(): Bgm.play_track(Bgm.Track.SKY))
    ocean.jungle.sky_exit.sky.heaven_exit.arrived.connect(func(_ghost): Bgm.play_track(Bgm.Track.HEAVEN))

func _capture(body: CharacterBody2D) -> void:
    stage = Stage.CAPTURING
    level.exit_in_progress = true
    var zoom_before := camera.zoom
    level.possession.shot.cancel()
    camera.zoom = zoom_before
    level.get_node("Fork").reset()
    level.get_node("Fork").set_physics_process(false)
    level.get_node("Fork").set_process_unhandled_input(false)
    level.possession.enabled = false
    level.get_node("CameraAttention").enabled = false
    body.get_node("Movement").enabled = false
    body.get_node("Input").enabled = false
    body.get_node("Input").clear()
    body.velocity = Vector2.ZERO
    camera.clear_impulse()
    camera.adopt_view(camera.global_position, zoom_before)
    camera.set_follow_target(body)
    transition.prepare(camera, zoom_before)

func _travel(_body: CharacterBody2D) -> void:
    stage = Stage.TRAVELLING
    level.process_mode = Node.PROCESS_MODE_DISABLED
    output.process_mode = Node.PROCESS_MODE_ALWAYS
    level.get_node("TextureStreamer").process_mode = Node.PROCESS_MODE_ALWAYS
    level.get_node("MusicRegions").enabled = false
    var half_view := camera.get_viewport_rect().size * 0.5 / transition.rest_zoom
    var destination := ocean.to_global(Vector2(960,3240)) - Vector2(0,half_view.y)
    transition.travel(camera, destination)

func _arrive() -> void:
    stage = Stage.OCEAN
    var settings: FollowCamera = ocean.get_node("FollowCamera")
    for property in [&"framing_offset", &"dead_zone", &"follow_speed", &"horizontal_look_ahead", &"upward_look_ahead", &"max_impulse_pixels", &"impulse_decay"]:
        camera.set(property, settings.get(property))
    camera.world_bounds = settings.world_bounds
    camera.process_mode = Node.PROCESS_MODE_ALWAYS
    camera.resume_follow_from_current_position(ocean.demon)
    camera.set_process(true)
    for name in ["Background", "Foreground"]: ocean.get_node(name).reset_reference()
    ocean.process_mode = Node.PROCESS_MODE_INHERIT
    ocean.fish.process_mode = Node.PROCESS_MODE_INHERIT
    Bgm.play_track(Bgm.Track.OCEAN)
    ocean_entered.emit()

func _input(event: InputEvent) -> void:
    if stage == Stage.HELL: return
    if event.is_action_pressed(&"restart") and not event.is_echo():
        if stage == Stage.OCEAN: ocean.restart()
        get_viewport().set_input_as_handled()
