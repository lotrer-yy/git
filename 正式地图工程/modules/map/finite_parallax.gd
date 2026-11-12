extends Node2D
## 有限长地图视差：每个区域独立锚定，避免整张五万像素地图累计漂移。
## 和 Parallax2D 的 scroll_scale 相同：小于 1 表示背景移动更慢。
@export var camera_path: NodePath
@export_range(0.5, 1.0, 0.01) var scroll_ratio: float = 0.94
@export var region_top: float = 0.0
@export var region_bottom: float = 52000.0
@export var boundary_blend: float = 1400.0
@export var maximum_offset: float = 320.0
@export var enabled: bool = true
var camera: Camera2D

func _ready() -> void:
	process_priority = -10
	camera = get_node_or_null(camera_path) as Camera2D

func offset_at(camera_y: float) -> float:
	if not enabled:
		return 0.0
	var anchor := (region_top + region_bottom) * 0.5
	var blend := minf(boundary_blend, (region_bottom - region_top) * 0.25)
	var weight := smoothstep(region_top, region_top + blend, camera_y)
	weight *= 1.0 - smoothstep(region_bottom - blend, region_bottom, camera_y)
	return clampf((camera_y - anchor) * (1.0 - scroll_ratio), -maximum_offset, maximum_offset) * weight

func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		position.y = offset_at(camera.global_position.y)
