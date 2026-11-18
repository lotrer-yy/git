extends Node2D
## 单个角色只管理弹入、波浪位移和弹出；身体形变复用 ElasticPulse。
signal leaving
signal entered
signal exited
enum Pose { HIDDEN, ENTERING, READY, EXITING }
@export var entry_duration: float = 0.50
@export var exit_duration: float = 0.32
@export var hidden_distance: float = 240.0
@export var hop_height: float = 18.0
@export var hop_duration: float = 0.44
var pose: Pose = Pose.HIDDEN
var _rest := Vector2.ZERO
var _tween: Tween
var _hopping: bool = false

func _ready() -> void:
	_rest = position
	visible = false
	position.y = _rest.y + hidden_distance

func enter(delay: float) -> void:
	_kill_motion()
	pose = Pose.ENTERING
	visible = true
	position = _rest + Vector2(0, hidden_distance)
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_property(self, "position", _rest, entry_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_entered)

func _entered() -> void:
	pose = Pose.READY
	$Visual/Pulse.pulse()
	entered.emit()

func wave(time: float, period: float) -> void:
	if pose != Pose.READY:
		return
	if time < 0.0:
		position = _rest
		return
	var phase := fposmod(time, period)
	var hopping := phase < hop_duration
	if hopping:
		position.y = _rest.y - sin(PI * phase / hop_duration) * hop_height
	else:
		position.y = _rest.y
	if _hopping and not hopping:
		$Visual/Pulse.pulse()
	_hopping = hopping

func leave(delay: float) -> void:
	_kill_motion()
	pose = Pose.EXITING
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_callback(func():
		$Visual/Pulse.pulse()
		leaving.emit())
	_tween.tween_property(self, "position:y", _rest.y - 16.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", _rest.y + hidden_distance, exit_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_exited)

func _exited() -> void:
	pose = Pose.HIDDEN
	visible = false
	_hopping = false
	exited.emit()

func _kill_motion() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
