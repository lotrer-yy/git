extends Node
## 跨场景保留播放进度；切歌时先淡出，再从静音淡入下一首。
enum Track { MENU, HELL, OCEAN, JUNGLE, SKY, HEAVEN }
const TRACK_PATHS = [
	"res://assets/audio/bgm/01升天.mp3",
	"res://assets/audio/bgm/02地狱1.mp3",
	"res://assets/audio/bgm/03海底1.mp3",
	"res://assets/audio/bgm/04丛林1.mp3",
	"res://assets/audio/bgm/05天空.mp3",
	"res://assets/audio/bgm/06天堂.mp3",
]
@export_range(0.0, 5.0) var fade_out_seconds: float = 1.5
@export_range(0.0, 5.0) var fade_in_seconds: float = 1.5
@export_range(-40.0, 0.0) var volume_db: float = 0.0
var current_track: int = -1
var _player: AudioStreamPlayer
var _fade: Tween
var _speed_change: Tween
var _pitch_shift: AudioEffectPitchShift
var _bus_name: StringName

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus_index := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus_index, "BgmMusic")
	_bus_name = AudioServer.get_bus_name(bus_index)
	_pitch_shift = AudioEffectPitchShift.new()
	_pitch_shift.fft_size = AudioEffectPitchShift.FFT_SIZE_2048
	AudioServer.add_bus_effect(bus_index, _pitch_shift)
	_player = AudioStreamPlayer.new()
	_player.bus = _bus_name
	add_child(_player)

func _exit_tree() -> void:
	AudioServer.remove_bus(AudioServer.get_bus_index(_bus_name))

func play_track(track: int) -> void:
	if current_track == track:
		return
	current_track = track
	if _speed_change != null:
		_speed_change.kill()
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	if _player.playing:
		_fade.tween_property(_player, "volume_linear", 0.0, fade_out_seconds)
	_fade.tween_callback(_start_track.bind(track))
	_fade.tween_property(_player, "volume_linear", db_to_linear(volume_db), fade_in_seconds)

func _start_track(track: int) -> void:
	var stream := load(TRACK_PATHS[track]).duplicate() as AudioStreamMP3
	stream.loop = true
	_player.stop()
	_player.stream = stream
	_set_playback_speed(1.2 if track == Track.HELL else 1.0)
	_player.volume_linear = 0.0
	_player.play()
	if track == Track.HELL:
		_speed_change = create_tween()
		_speed_change.tween_interval(10.0)
		_speed_change.tween_method(_set_playback_speed, 1.2, 1.1, 1.0)

func _set_playback_speed(speed: float) -> void:
	_player.pitch_scale = speed
	# 播放器改变速度和音高，专用音乐总线用倒数同步抵消音高变化。
	_pitch_shift.pitch_scale = 1.0 / speed
