extends CanvasLayer
## 粗柱子遮挡时换镜头，露出正式地图后从墙里弹出原来的小幽灵。
signal covered
signal finished
@export var gameplay_scene: PackedScene
@export var old_world_path: NodePath = ^"../DescentWorld"
@export var old_camera_path: NodePath = ^"../DescentCamera"
@export var chase_camera_path: NodePath = ^"../ChaseCamera"
@export var duration: float = 1.2
var gameplay: Node2D
var playing: bool = false
var elapsed: float = 0.0
var switched: bool = false
var revealed: bool = false
@onready var wipe: Sprite2D = $Wall

func _ready() -> void:
	visible = false
	process_priority = 300

func prepare() -> void:
	if is_instance_valid(gameplay):
		return
	gameplay = gameplay_scene.instantiate()
	gameplay.name = "Gameplay"
	gameplay.visible = false
	get_parent().add_child(gameplay)

func play() -> void:
	if playing or switched:
		return
	prepare()
	visible = true
	playing = true
	wipe.position = Vector2(1920,-700)

func _process(delta: float) -> void:
	if not playing:
		return
	elapsed = minf(elapsed + delta, duration)
	var u: float = elapsed / duration
	wipe.position.x = lerpf(1920.0,-3000.0,u)
	if not switched and wipe.position.x <= -160.0:
		# 两侧都在实际不透明柱身之内，切换不会露出一帧旧画面。
		switched = true
		get_node(chase_camera_path).active = false
		get_node(old_world_path).visible = false
		get_node(old_camera_path).enabled = false
		gameplay.visible = true
		gameplay.get_node("Camera").enabled = true
		gameplay.get_node("Camera").make_current()
		covered.emit()
	if switched and not revealed and u >= 0.88:
		revealed = true
		gameplay.get_node("WallEntry").play()
	if u >= 1.0:
		playing = false
		visible = false
		finished.emit()
