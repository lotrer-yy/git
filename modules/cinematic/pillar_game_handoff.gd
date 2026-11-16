extends Node
## 追逐时预加载；幽灵进墙后停顿，再用同一台相机向右平移揭示正式地图。
signal pan_started
signal finished
@export var gameplay_scene: PackedScene
@export var map_path: NodePath = ^"../DescentWorld/ArrivalMap"
@export var old_camera_path: NodePath = ^"../DescentCamera"
@export var chase_camera_path: NodePath = ^"../ChaseCamera"
@export var hold_time: float = 0.65
@export var pan_duration: float = 1.35
@export var gameplay_origin_x: float = 4876.0
@export var connected_floor_y: float = 1100.0
var gameplay: Node2D
var playing: bool = false
var elapsed: float = 0.0
var switched: bool = false
var revealed: bool = false
var panning: bool = false
var _pan_from: Vector2
var _pan_to: Vector2
var _pan_elapsed: float = 0.0
@onready var camera: Camera2D = get_node(old_camera_path)
@onready var chase_motion: Node = get_node(chase_camera_path)

func _ready() -> void:
	process_priority = 300

func prepare() -> void:
	if is_instance_valid(gameplay):
		return
	var map: Node2D = get_node(map_path)
	gameplay = gameplay_scene.instantiate()
	gameplay.name = "Gameplay"
	gameplay.z_index = -60
	gameplay.position = Vector2(gameplay_origin_x, map.global_position.y + connected_floor_y - 51870.0)
	gameplay.visible = false
	var game_camera: Camera2D = gameplay.get_node("Camera")
	game_camera.world_bounds = Rect2(gameplay.position,Vector2(1920,52000))
	game_camera.zoom = Vector2.ONE * 1.35
	get_parent().add_child(gameplay)
	# 隐藏时仍让流式加载器预载附近高清切片，但禁止隐藏相机移动。
	game_camera.set_process(false)
	gameplay.get_node("WallEntry").control_ready.connect(_enable_follow)

func play() -> void:
	if playing or switched:
		return
	prepare()
	playing = true
	chase_motion.lock_frame()

func _process(delta: float) -> void:
	if not playing:
		return
	elapsed += delta
	if not panning:
		# 停在原来的动画镜头；高清尚未准备好就继续等，不露出正式地图。
		if elapsed < hold_time or not gameplay.get_node("TextureStreamer").is_view_ready():
			return
		panning = true
		chase_motion.active = false
		_pan_from = camera.global_position
		var half_width: float = get_viewport().get_visible_rect().size.x / (2.0 * camera.zoom.x)
		_pan_to = Vector2(gameplay.position.x + half_width, _pan_from.y)
		gameplay.visible = true
		pan_started.emit()
	_pan_elapsed = minf(_pan_elapsed + delta, pan_duration)
	var u: float = _pan_elapsed / pan_duration
	var eased: float = u * u * (3.0 - 2.0 * u)
	camera.global_position = _pan_from.lerp(_pan_to,eased)
	if not revealed and u >= 0.52:
		revealed = true
		gameplay.get_node("WallEntry").play()
	if u >= 1.0:
		playing = false
		switched = true
		var game_camera: Camera2D = gameplay.get_node("Camera")
		game_camera.adopt_view(camera.global_position,camera.zoom)
		camera.enabled = false
		game_camera.enabled = true
		game_camera.make_current()
		# 交接只是相机所有权变化，位置和缩放完全相同。
		if gameplay.get_node("WallEntry").completed:
			_enable_follow()
		finished.emit()

func _enable_follow() -> void:
	if switched:
		gameplay.get_node("Camera").set_process(true)
