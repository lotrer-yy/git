extends Node
## 机关只提供关注点，构图偏移与瞬移衔接在这里处理，不移动玩家或机关。
@export var enabled: bool = true
@export var maximum_peek_pixels: Vector2 = Vector2(160, 250)
@export_range(0.0, 0.5) var interest_weight: float = 0.34
@export var interest_radius: float = 1000.0
@export_range(0.0,0.5) var incoming_interest_weight: float = 0.16
@export var bias_response: float = 4.5
@export var exchange_blend_seconds: float = 0.28
const SURFACE = preload("res://modules/environment/hell_surface.gd")
@export var screen_margin_pixels: float = 90.0
var _incoming: Node2D
var _incoming_seconds: float = 0.0
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
	_incoming_seconds=maxf(0.0,_incoming_seconds-delta)
	var desired := Vector2.ZERO
	camera.precise_framing = false
	if enabled and not level.dead and demon.get_node("Host").claimed and camera.target == demon:
		var interest: Node2D = fork.camera_interest()
		if _incoming_seconds>0 and is_instance_valid(_incoming) and not _incoming.is_defeated() and not fork.flying and not fork.launching and not fork.swapping:
			interest=_incoming
		# 已经在脚下的锁定球不是下一步；投出、插中和弹射中的主动目标仍优先。
		var active_action: bool = fork.flying or fork.swapping or fork.launching or is_instance_valid(fork.lodged)
		if not active_action and is_instance_valid(interest) and not interest.is_in_group("hell_flying_enemies") and interest.global_position.y > demon.global_position.y - 80.0:
			interest = null
		if not is_instance_valid(interest): interest = _nearby_platform()
		if is_instance_valid(interest):
			camera.precise_framing = true
			var point := interest.global_position
			if interest.is_in_group("hell_platforms"):
				var landing: Vector2 = SURFACE.landing_on(interest)
				if is_finite(landing.y): point = landing
			var base := demon.global_position + camera.framing_offset
			var arriving := interest==_incoming and _incoming_seconds>0 and not active_action
			var center := base.lerp(point, incoming_interest_weight if arriving else interest_weight)
			var half_view := camera.get_viewport_rect().size * 0.5 / camera.zoom
			var margin := Vector2.ONE * screen_margin_pixels / camera.zoom
			# 把上方机关从屏幕边缘带入安全区，同时保留主角下方的空间。
			# 关注时由跟随模块平滑对准精确构图，不额外遗留一段死区。
			if point.y < demon.global_position.y:
				center.y = minf(center.y, point.y + half_view.y - margin.y)
				center.y = maxf(center.y, demon.global_position.y - half_view.y + margin.y)
			var pixels := (center - base) * camera.zoom
			pixels = pixels.clamp(-maximum_peek_pixels, maximum_peek_pixels)
			desired = pixels / camera.zoom
	camera.framing_bias = camera.framing_bias.lerp(desired, 1.0 - exp(-bias_response * delta))

func _platform_point(platform: Node2D) -> Vector2:
	return SURFACE.landing_on(platform)

func _fits_preview(point: Vector2) -> bool:
	var half := camera.get_viewport_rect().size * 0.5 / camera.zoom
	var margin := Vector2.ONE * screen_margin_pixels / camera.zoom
	var distance := demon.global_position - point
	return is_finite(point.y) and distance.y > 70.0 and distance.y < minf(interest_radius, 2.0 * (half.y - margin.y)) and absf(distance.x) < minf(interest_radius, 2.0 * (half.x - margin.x))

func _nearby_platform() -> Node2D:
	var next: Node2D
	var highest := INF
	# 预览能够同屏展示的下一段路线，也包含静态落脚平台。
	# 不能只按最近距离选，否则低处的移动平台会一直挡住更上方的机关指引。
	for platform in get_tree().get_nodes_in_group("hell_platforms"):
		if platform.broken: continue
		var point := _platform_point(platform)
		if _fits_preview(point) and point.y < highest:
			next = platform
			highest = point.y
	if is_instance_valid(_platform_interest) and not _platform_interest.broken:
		var old_point := _platform_point(_platform_interest)
		if _fits_preview(old_point) and (next == null or old_point.y - highest < 60.0):
			return _platform_interest
	_platform_interest = next
	return next

func _on_exchanged(body: Node2D) -> void:
	camera.blend_to_target(body, exchange_blend_seconds)

func notify_incoming(enemy: Node2D) -> void:
	_incoming=enemy
	_incoming_seconds=1.25

func clear() -> void:
	_incoming=null
	_incoming_seconds=0.0
	_platform_interest = null
	camera.precise_framing = false
	camera.framing_bias = Vector2.ZERO
