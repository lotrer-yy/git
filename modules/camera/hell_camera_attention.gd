extends Node
## 机关只提供关注点，构图偏移与瞬移衔接在这里处理，不移动玩家或机关。
@export var enabled: bool = true
@export var maximum_peek_pixels: Vector2 = Vector2(160, 250)
@export_range(0.0, 0.5) var interest_weight: float = 0.34
@export var interest_radius: float = 650.0
@export var bias_response: float = 4.5
@export var exchange_blend_seconds: float = 0.28
const SURFACE = preload("res://modules/environment/hell_surface.gd")
@export var screen_margin_pixels: float = 150.0
var _platform_interest: Node2D
@onready var level: Node2D = get_parent()
@onready var camera: FollowCamera = get_node("../Camera")
@onready var fork: Node2D = get_node("../Fork")
@onready var demon: CharacterBody2D = get_node("../Demon")

func _ready() -> void:
	process_priority = 5
	fork.exchanged.connect(_on_exchanged)
	fork.interaction_reset.connect(clear)
	level.died.connect(clear)

func _process(delta: float) -> void:
	var desired := Vector2.ZERO
	if enabled and not level.dead and demon.get_node("Host").claimed and camera.target == demon:
		var interest: Node2D = fork.camera_interest()
		if not is_instance_valid(interest): interest = _nearby_platform()
		if is_instance_valid(interest):
			var point := interest.global_position
			if interest.is_in_group("hell_platforms"):
				var landing: Vector2 = SURFACE.landing_on(interest)
				if is_finite(landing.y): point = landing
			var base := demon.global_position + camera.framing_offset
			var center := base.lerp(point, interest_weight)
			var half_view := camera.get_viewport_rect().size * 0.5 / camera.zoom
			var margin := Vector2.ONE * screen_margin_pixels / camera.zoom
			# 把上方机关从屏幕边缘带入安全区，同时保留主角下方的空间。
			# 补偿跟随死区，否则静止时机关仍会被留在画面外。
			if point.y < demon.global_position.y:
				center.y = minf(center.y, point.y + half_view.y - margin.y - camera.dead_zone.y)
				center.y = maxf(center.y, demon.global_position.y - half_view.y + margin.y)
			var pixels := (center - base) * camera.zoom
			pixels = pixels.clamp(-maximum_peek_pixels, maximum_peek_pixels)
			desired = pixels / camera.zoom
	camera.framing_bias = camera.framing_bias.lerp(desired, 1.0 - exp(-bias_response * delta))

func _nearby_platform() -> Node2D:
	var nearest: Node2D
	var best := interest_radius * interest_radius
	for platform in get_tree().get_nodes_in_group("hell_platforms"):
		if platform.kind not in ["moving", "floating", "breakable"] or platform.broken:
			continue
		var delta_position: Vector2 = platform.global_position - demon.global_position
		if delta_position.y > -50.0 or delta_position.y < -interest_radius or absf(delta_position.x) > interest_radius:
			continue
		var distance := delta_position.length_squared()
		if distance < best:
			nearest = platform
			best = distance
	# 接近两个机关时保持原关注点，只有明显更近才切换，避免左右来回摆。
	if is_instance_valid(_platform_interest) and not _platform_interest.broken:
		var old_delta: Vector2 = _platform_interest.global_position - demon.global_position
		var old_distance := old_delta.length_squared()
		if old_delta.y < -25.0 and old_distance < pow(interest_radius * 1.15, 2.0) and (nearest == null or best > old_distance * 0.65):
			return _platform_interest
	_platform_interest = nearest
	return nearest

func _on_exchanged(body: Node2D) -> void:
	camera.blend_to_target(body, exchange_blend_seconds)

func clear() -> void:
	_platform_interest = null
	camera.framing_bias = Vector2.ZERO
