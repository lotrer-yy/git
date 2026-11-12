extends Node
## 编辑器保存真实地图节点与轻量预览；运行时后台载入相机附近的原分辨率切片。
## 高清尚未完成载入时保留预览，避免黑块；离开后释放高清纹理。
@export var camera_path: NodePath = ^"../Camera"
@export var map_root_path: NodePath = ^"../Map"
@export var preload_margin: float = 1800.0
var _camera: Camera2D
var _chunks: Array[Sprite2D] = []
var _preview: Dictionary = {}
var _resident: Dictionary = {}
var _pending: Dictionary = {}

func _ready() -> void:
	_camera = get_node(camera_path)
	_collect(get_node(map_root_path))

func _collect(node: Node) -> void:
	if node is Sprite2D and node.has_meta("full_texture"):
		_chunks.append(node)
		_preview[node] = {"texture": node.texture, "scale": node.scale}
	for child in node.get_children():
		_collect(child)

func _near(chunk: Sprite2D) -> bool:
	var half := _camera.get_viewport_rect().size.y * 0.5 / _camera.zoom.y
	var top := chunk.global_position.y
	var height := float(chunk.get_meta("pixel_height"))
	return top < _camera.global_position.y + half + preload_margin and top + height > _camera.global_position.y - half - preload_margin

func _process(_delta: float) -> void:
	for chunk in _chunks:
		if _near(chunk):
			if not _resident.has(chunk) and not _pending.has(chunk):
				var path: String = chunk.get_meta("full_texture")
				var error := ResourceLoader.load_threaded_request(path, "Texture2D")
				if error == OK:
					_pending[chunk] = path
		elif _resident.has(chunk):
			chunk.texture = _preview[chunk].texture
			chunk.scale = _preview[chunk].scale
			chunk.region_enabled = false
			_resident.erase(chunk)
	for chunk in _pending.keys():
		var path: String = _pending[chunk]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var texture := ResourceLoader.load_threaded_get(path) as Texture2D
			if _near(chunk):
				chunk.texture = texture
				chunk.scale = Vector2.ONE
				chunk.region_enabled = true
				chunk.region_rect = Rect2(0, 1, 1920, float(chunk.get_meta("pixel_height")))
				chunk.region_filter_clip_enabled = true
				_resident[chunk] = true
			_pending.erase(chunk)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("地图高清切片载入失败：" + path)
			_pending.erase(chunk)
