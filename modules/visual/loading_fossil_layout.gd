extends Node2D
## 化石只负责每页的排列，不管理镜头或循环回收。
@export var variants: Array[Texture2D] = []
@export var page_size := Vector2(1920, 1745.454545)
var layout_seed: int = 0

func randomize_layout(seed_value: int) -> void:
	layout_seed = seed_value
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var order: Array[int] = [0, 1, 2]
	for i in range(2, 0, -1):
		var j := rng.randi_range(0, i)
		var saved := order[i]
		order[i] = order[j]
		order[j] = saved
	var slots := $Fossils.get_children()
	for i in range(slots.size()):
		var fossil: Sprite2D = slots[i]
		fossil.texture = variants[order[i % order.size()]]
		var size := rng.randf_range(0.58, 0.92) * 1920.0 / 1980.0
		fossil.scale = Vector2.ONE * size
		fossil.rotation = rng.randf_range(-0.16, 0.16)
		fossil.flip_h = rng.randf() > 0.5
		var margin := fossil.texture.get_width() * size * 0.5 + 100.0
		fossil.position = Vector2(rng.randf_range(margin, page_size.x - margin),
			(i + 0.5) * page_size.y / slots.size() + rng.randf_range(-60.0, 60.0))
