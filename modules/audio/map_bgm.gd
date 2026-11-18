extends Node
## 按正式地图的相机高度切歌；后台预载地图期间不抢占开场音乐。
@export var camera_path: NodePath = ^"../Camera"
@export var map_path: NodePath = ^"../Map"
@export var heaven_bottom: float = 4942.0
@export var sky_bottom: float = 18174.5
@export var jungle_bottom: float = 29820.0
@export var ocean_bottom: float = 40268.0
var enabled: bool = false
@onready var camera: Camera2D = get_node(camera_path)
@onready var map: Node2D = get_node(map_path)

func _ready() -> void:
	enabled = get_parent().get_parent() == get_tree().root

func _process(_delta: float) -> void:
	if not enabled:
		return
	var y := map.to_local(camera.global_position).y
	var track := Bgm.Track.HELL
	if y < heaven_bottom:
		track = Bgm.Track.HEAVEN
	elif y < sky_bottom:
		track = Bgm.Track.SKY
	elif y < jungle_bottom:
		track = Bgm.Track.JUNGLE
	elif y < ocean_bottom:
		track = Bgm.Track.OCEAN
	Bgm.play_track(track)
