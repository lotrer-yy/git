extends Node
## 独立短音效服务：固定声部池、音效限频、分组混音与转场风声。
signal event_played(event: StringName)
const EVENTS = preload("res://modules/audio/cartoon_sfx_synth.gd").PROFILES
const Hook = preload("res://modules/audio/scene_audio_hooks.gd")
@export var enabled: bool = true
@export_range(-24.0,0.0) var music_headroom_db: float = -4.0
var event_counts: Dictionary = {}
var _cache: Dictionary = {}
var _last: Dictionary = {}
var _clock: float = 0.0
var _frame_count: int = 0
var _world: Array[AudioStreamPlayer2D] = []
var _ui: Array[AudioStreamPlayer] = []
var _wind: AudioStreamPlayer
var _wind_owner: WeakRef
var _wind_active: bool = false
var _wind_gain: float = 0.0
var _descent_speed: float = 0.0
var _duck_left: float = 0.0
var _created_buses: Array[StringName] = []
var _old_music_send: StringName
var _music_bus: StringName = &"BgmMusic"
var _output: bool = false

func _ready() -> void:
 if get_tree().root.has_meta("generating_sfx"): return
 process_mode=Node.PROCESS_MODE_ALWAYS
 process_priority=-100
 _output=DisplayServer.get_name()!="headless"
 for event in EVENTS:
  _cache[event]=[load("res://assets/audio/sfx/%s_0.wav"%event),load("res://assets/audio/sfx/%s_1.wav"%event)]
 for name in [&"MusicDuck",&"SFX",&"UI"]:
  if AudioServer.get_bus_index(name)<0:
   var insert_at:=1 if name==&"MusicDuck" else AudioServer.bus_count
   AudioServer.add_bus(insert_at)
   AudioServer.set_bus_name(insert_at,name)
   _created_buses.append(name)
 var music_index:=AudioServer.get_bus_index(_music_bus)
 if music_index>=0:
  _old_music_send=AudioServer.get_bus_send(music_index)
  AudioServer.set_bus_send(music_index,&"MusicDuck")
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"MusicDuck"),music_headroom_db)
 if _output:
  for i in 8:
   var voice:=AudioStreamPlayer2D.new()
   voice.bus=&"SFX"
   voice.max_distance=2600.0
   voice.attenuation=0.65
   voice.panning_strength=0.65
   add_child(voice)
   _world.append(voice)
  for i in 4:
   var voice:=AudioStreamPlayer.new()
   voice.bus=&"UI"
   add_child(voice)
   _ui.append(voice)
  _wind=AudioStreamPlayer.new()
  _wind.bus=&"SFX"
  _wind.stream=_cache["wind_loop"][0].duplicate()
  _wind.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
  _wind.stream.loop_end=_wind.stream.data.size()/2
  add_child(_wind)
 add_child(Hook.new())

func _process(delta: float) -> void:
 var dt:=delta/maxf(Engine.time_scale,0.001)
 _clock+=dt
 _frame_count=0
 _duck_left=maxf(0.0,_duck_left-dt)
 var bus:=AudioServer.get_bus_index(&"MusicDuck")
 if bus>=0:
  var target:=music_headroom_db-3.0 if _duck_left>0.0 else music_headroom_db
  AudioServer.set_bus_volume_db(bus,lerpf(AudioServer.get_bus_volume_db(bus),target,1.0-exp(-dt*10.0)))
 var speed:=0.0
 if _wind_active and _wind_owner!=null and is_instance_valid(_wind_owner.get_ref()):
  update_descent(_wind_owner.get_ref().current_speed)
  speed=_descent_speed
 var target_gain:=clampf(speed/3200.0,0.0,1.0)*0.22 if _wind_active and enabled else 0.0
 _wind_gain=lerpf(_wind_gain,target_gain,1.0-exp(-dt*7.0))
 if is_instance_valid(_wind):
  _wind.volume_linear=_wind_gain
  _wind.pitch_scale=0.8+speed/6400.0
  if not _wind_active and _wind_gain<0.001: _wind.stop()

func play(event: StringName, position: Vector2 = Vector2.ZERO, strength: float = 1.0, ui: bool = false) -> bool:
 if not enabled or not _cache.has(event): return false
 var cooldown:float={"hover":0.09,"step":0.12,"arrow_fly":0.13,"arrow_hit":0.095,"flap":0.25,"mini_pop":0.06,"duang":0.35}.get(event,0.06)
 if _clock-float(_last.get(event,-100.0))<cooldown or _frame_count>=3: return false
 _last[event]=_clock
 _frame_count+=1
 event_counts[event]=int(event_counts.get(event,0))+1
 event_played.emit(event)
 if event in [&"possess_out",&"wall_pop",&"eruption",&"wall_enter"]: _duck_left=0.45
 if not _output: return true
 var voice: Node
 var pool: Array=[]
 pool.assign(_ui if ui else _world)
 for candidate in pool:
  if not candidate.playing:
   voice=candidate
   break
 if voice==null:
  voice=pool[0]
  for candidate in pool:
   if float(candidate.get_meta("started",0.0))<float(voice.get_meta("started",0.0)): voice=candidate
 var gain:float={"hover":-13.0,"mini_pop":-11.0,"step":-16.0,"arrow_fly":-12.0,"arrow_hit":-9.0,"flap":-17.0,"duang":-13.0}.get(event,-5.0)
 voice.stream=_cache[event][randi()%2]
 voice.pitch_scale=randf_range(0.97,1.03)
 voice.volume_db=gain+linear_to_db(clampf(strength,0.08,1.15))
 voice.set_meta("started",_clock)
 if voice is AudioStreamPlayer2D: voice.global_position=position
 voice.play()
 return true

func start_descent(owner_node: Node) -> void:
 _wind_owner=weakref(owner_node)
 _wind_active=true
 if is_instance_valid(_wind): _wind.play()
 play(&"whoosh",Vector2.ZERO,0.8,true)

func update_descent(speed: float) -> void:
 _descent_speed=maxf(speed,0.0)

func release_descent() -> void:
 _wind_active=false

func stop_descent() -> void:
 _wind_active=false
 _wind_gain=0.0
 _descent_speed=0.0
 _wind_owner=null
 if is_instance_valid(_wind): _wind.stop()

func reset() -> void:
 _last.clear()
 _frame_count=0
 stop_descent()
 _duck_left=0.0
 for voice in _world: voice.stop()
 for voice in _ui: voice.stop()
 if is_instance_valid(_wind): _wind.stop()

func _exit_tree() -> void:
 var music_index:=AudioServer.get_bus_index(_music_bus)
 if music_index>=0 and not _old_music_send.is_empty(): AudioServer.set_bus_send(music_index,_old_music_send)
 for bus_name in _created_buses:
  var index:=AudioServer.get_bus_index(bus_name)
  if index>=0: AudioServer.remove_bus(index)
