extends Node2D
## 路径移动与脚底弹跳分离；美术通过 Visual 子节点保持脚底轴心。
@export var speed: float = 460.0
@export var cadence: float = 3.3
@export var hop_height: float = 30.0
@export var squash: float = 0.13
var running: bool = false
var elapsed: float = 0.0
@onready var visual: Node2D = $Visual

func start() -> void:
	running = true
	visible = true

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	position.x += speed * delta
	var phase: float = fmod(elapsed * cadence, 1.0)
	var hop: float = sin(phase * PI)
	var contact: float = exp(-phase * 22.0)
	visual.position.y = -hop_height * hop
	visual.scale = Vector2(1.0 + squash * contact - squash * 0.35 * hop, 1.0 - squash * contact + squash * 0.35 * hop)
	visual.rotation = -0.025 * sin(phase * TAU)
