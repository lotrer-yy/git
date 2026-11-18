extends Node2D
## 一个团团只有一个逻辑位置；换图只调整美术原点，不移动目标。
enum State { NORMAL, LOCKED, HIT }
const TEXTURES = [preload("res://assets/art/hell/new/target.png"), preload("res://assets/art/hell/new/locked.png"), preload("res://assets/art/hell/new/hit.png")]
const PIVOTS = [Vector2(67,66.5), Vector2(81,82.5), Vector2(113,66.5)]
@export var platform_art_path: NodePath
var state: State = State.NORMAL
var hit_angle: float = 0.0
@onready var art: Sprite2D = $Art
@onready var _platform_art: Sprite2D = get_node_or_null(platform_art_path) if not platform_art_path.is_empty() else null

func _ready() -> void:
	add_to_group("fork_targets")
	set_state(State.NORMAL)

func set_state(value: State) -> void:
	state = value
	art.texture = TEXTURES[value]
	art.offset = art.texture.get_size() * 0.5 - PIVOTS[value]
	art.scale = Vector2.ONE
	art.rotation = hit_angle if value == State.HIT else 0.0
	# 前景独立后由真正的岩壁和平台遮挡，不再使用旧合成图的裁切遮罩。
	art.material.set_shader_parameter("clip_normal", false)
	art.z_index = -10 if value == State.NORMAL else 0
	if _platform_art != null:
		# 正常球已画在作者组合图中；换状态时用原单体平台还原遮挡区。
		_platform_art.material.set_shader_parameter("hide_ball", value != State.NORMAL)
		art.visible = value != State.NORMAL
	else:
		art.show()
