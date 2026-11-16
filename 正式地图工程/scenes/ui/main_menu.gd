extends Node2D
var _starting := false
func _ready() -> void:
	$Start.pressed.connect(_start_game)
	$Settings.pressed.connect(_settings_pressed)
	$Start.mouse_entered.connect($Start/Pulse.pulse)
	$Settings.mouse_entered.connect($Settings/Pulse.pulse)
	$DescentTransition.descent_started.connect($ExitMotion.play)
	$DescentTransition.descent_started.connect($LoadingOverlay.begin_loading)
	$ArrivalMotion.arrived.connect($LoadingOverlay.finish_loading)
	$LoadingOverlay.finished.connect($OpeningChase.start)
	$LoadingOverlay.finished.connect($GameHandoff.prepare)
	$OpeningChase.finished.connect($GameHandoff.play)
	$OpeningChase.ghost_returned.connect($DescentWorld/ArrivalMap/NearMissArrows.start)
	$OpeningChase.ghost_returned.connect($DescentWorld/ArrivalMap/PillarArrows.start)
	$OpeningChase.ghost_exiting.connect($DescentWorld/ArrivalMap/ExitArrows.start)
func _settings_pressed() -> void:
	$Settings/Pulse.pulse()
func _start_game() -> void:
	if _starting:
		return
	_starting = true
	$Start/Pulse.pulse()
	$Start.disabled = true
	$Settings.disabled = true
	if $Bird/MouseDrag.dragging:
		$Bird/MouseDrag.end_drag()
	$Bird/MouseDrag.set_process_input(false)
	$DescentTransition.start()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or (_starting and event.physical_keycode == KEY_ESCAPE):
			get_viewport().set_input_as_handled()
			get_tree().reload_current_scene()
