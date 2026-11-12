extends Camera2D
## 相机只管理位置、平滑和边界，由输入模块的信号驱动。
signal view_moved(center: Vector2)
@export var input_path: NodePath = ^"../Input"
@export var map_bounds := Rect2(0, 0, 1920, 52000)
@export var response: float = 9.0
@export var start_at_bottom: bool = true
var target_y: float

func _ready() -> void:
	process_priority = -20
	position_smoothing_enabled = false
	var reader := get_node_or_null(input_path)
	if reader:
		reader.scroll_requested.connect(scroll_by)
		reader.edge_requested.connect(go_to_edge)
	position.x = map_bounds.get_center().x
	target_y = _bottom() if start_at_bottom else _top()
	position.y = target_y
	make_current()
	force_update_scroll()

func _half_height() -> float:
	return get_viewport_rect().size.y * 0.5 / zoom.y

func _top() -> float:
	return map_bounds.position.y + _half_height()

func _bottom() -> float:
	return maxf(_top(), map_bounds.end.y - _half_height())

func scroll_by(pixels: float) -> void:
	target_y = clampf(target_y + pixels, _top(), _bottom())

func go_to_edge(to_top: bool) -> void:
	target_y = _top() if to_top else _bottom()

func jump_to(y: float) -> void:
	target_y = clampf(y, _top(), _bottom())
	position.y = target_y
	force_update_scroll()

func _process(delta: float) -> void:
	target_y = clampf(target_y, _top(), _bottom())
	position.y = lerpf(position.y, target_y, 1.0 - exp(-response * delta))
	if absf(position.y - target_y) < 0.01:
		position.y = target_y
	view_moved.emit(position)
