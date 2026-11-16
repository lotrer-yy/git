extends Node2D
## 有限三页循环，不累积世界坐标；整页离开屏幕后才回收化石。
@export var loop_origin: float = 2909.090909
@export var page_height: float = 1745.454545
@export var random_seed: int = 0
var phase: float = 0.0
var cycles: int = 0
var _pages: Array[Node] = []
var _seed: int

func _ready() -> void:
	_pages = $Pages.get_children()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_seed = random_seed if random_seed != 0 else rng.randi_range(1, 1000000000)
	for i in range(_pages.size()):
		_pages[i].randomize_layout(_seed + i * 7919)
	_place_pages()

func advance(pixels: float) -> void:
	phase += maxf(pixels, 0.0)
	while phase >= page_height:
		phase -= page_height
		cycles += 1
		var recycled: Node = _pages.pop_front()
		_pages.push_back(recycled)
		recycled.randomize_layout(_seed + (cycles + _pages.size() - 1) * 7919)
	_place_pages()

func _place_pages() -> void:
	for i in range(_pages.size()):
		_pages[i].position.y = loop_origin + i * page_height - phase
