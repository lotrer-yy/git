extends Node
## 只负责首页元素退场，不切场景，不移动镜头。
@export var logo_path: NodePath = ^"../Logo"
@export var start_path: NodePath = ^"../Start"
@export var settings_path: NodePath = ^"../Settings"
var _tween: Tween

func play() -> void:
	var logo: Node2D = get_node(logo_path)
	var start_button: Control = get_node(start_path)
	var settings_button: Control = get_node(settings_path)
	for item in [logo, start_button, settings_button]:
		item.get_node("Pulse").set_process(false)
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(logo, "position", logo.position + Vector2(-1550, -1000), 0.7)
	_tween.tween_property(logo, "rotation", -0.24, 0.7)
	_tween.tween_property(start_button, "position:x", 2400.0, 0.64)
	_tween.tween_property(settings_button, "position:x", 2650.0, 0.66).set_delay(0.06)
