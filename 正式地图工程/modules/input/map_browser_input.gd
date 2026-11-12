extends Node
## 只读取浏览输入，不访问地图和相机。
signal scroll_requested(pixels: float)
signal edge_requested(to_top: bool)
@export var wheel_step: float = 650.0
@export var keyboard_speed: float = 1800.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var direction := 0.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			direction = -1.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			direction = 1.0
		if direction != 0.0:
			var factor: float = event.factor if event.factor > 0.0 else 1.0
			scroll_requested.emit(direction * wheel_step * factor)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_HOME:
			edge_requested.emit(true)
		elif event.physical_keycode == KEY_END:
			edge_requested.emit(false)

func _process(delta: float) -> void:
	var direction := float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
	if direction != 0.0:
		scroll_requested.emit(direction * keyboard_speed * delta)
