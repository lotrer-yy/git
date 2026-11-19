extends Node2D
## 一个团团只有一个逻辑位置；换图只调整美术原点，不移动目标。
enum State { NORMAL, LOCKED, HIT }
const TEXTURES = [preload("res://assets/art/hell/new/target.png"), preload("res://assets/art/hell/new/locked.png"), preload("res://assets/art/hell/new/hit.png")]
const PIVOTS = [Vector2(67,66.5), Vector2(81,82.5), Vector2(113,66.5)]
@export var visual_z_index: int = -10
@export var platform_art_path: NodePath
@export var selection_pop_scale: Vector2 = Vector2(1.25, 0.80)
@export var selection_pop_seconds: float = 0.32
@export var hit_pop_scale: Vector2 = Vector2(1.32, 0.72)
@export var teleport_pop_scale: Vector2 = Vector2(1.35, 0.70)
@export var impact_pop_seconds: float = 0.32
var _selection_tween: Tween
var state: State = State.NORMAL
var hit_angle: float = 0.0
@onready var art: Sprite2D = $Art
@onready var _platform_art: Sprite2D = get_node_or_null(platform_art_path) if not platform_art_path.is_empty() else null

func _ready() -> void:
	add_to_group("fork_targets")
	# Fork 层为 16，固定 -10 后团团在第 6 层，始终由平台和墙壁遮挡。
	art.z_index = visual_z_index
	set_state(State.NORMAL)

func set_state(value: State) -> void:
	var entering_selection := value == State.LOCKED and state != State.LOCKED
	var entering_hit := value == State.HIT and state != State.HIT
	if _selection_tween != null:
		_selection_tween.kill()
		_selection_tween = null
	state = value
	art.texture = TEXTURES[value]
	art.offset = art.texture.get_size() * 0.5 - PIVOTS[value]
	art.scale = Vector2.ONE
	art.rotation = hit_angle if value == State.HIT else 0.0
	# 前景独立后由真正的岩壁和平台遮挡，不再使用旧合成图的裁切遮罩。
	art.material.set_shader_parameter("clip_normal", false)
	if _platform_art != null:
		# 正常球已画在作者组合图中；换状态时用原单体平台还原遮挡区。
		_platform_art.material.set_shader_parameter("hide_ball", value != State.NORMAL)
		art.visible = value != State.NORMAL
	else:
		art.show()
	if entering_selection:
		play_bounce(selection_pop_scale, selection_pop_seconds)
	elif entering_hit:
		play_bounce(hit_pop_scale, impact_pop_seconds)

func play_bounce(shape: Vector2, seconds: float) -> void:
	if _selection_tween != null: _selection_tween.kill()
	# 组合图中的球暂时隐藏，独立球才能真的产生弹性；结束后还原原遮挡。
	if _platform_art != null: _platform_art.material.set_shader_parameter("hide_ball", true)
	art.show()
	art.scale = shape
	_selection_tween = create_tween()
	_selection_tween.tween_property(art, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_selection_tween.tween_callback(func():
		art.scale = Vector2.ONE
		if state == State.NORMAL:
			if _platform_art != null:
				_platform_art.material.set_shader_parameter("hide_ball", false)
				art.hide())

func bounce_on_teleport() -> void:
	set_state(State.NORMAL)
	play_bounce(teleport_pop_scale, impact_pop_seconds)
