extends RefCounted
## 离线生成短音效；同一组种子可重复生成相同 PCM。运行时只播放缓存 WAV。
const Wave = preload("res://modules/audio/audio_synth.gd")
const RATE := 22050
# 时长、起始频率、结束频率、气流比例、音量上限。
const PROFILES = {
 "hover": [0.075,720.0,520.0,0.02,0.35],
 "click": [0.15,330.0,135.0,0.08,0.58],
 "duang": [0.23,310.0,90.0,0.03,0.54],
 "mini_pop": [0.12,470.0,210.0,0.02,0.40],
 "charge": [0.28,110.0,440.0,0.15,0.46],
 "whoosh": [0.40,190.0,70.0,0.85,0.54],
 "jump": [0.20,185.0,530.0,0.12,0.52],
 "land": [0.17,155.0,52.0,0.35,0.60],
 "step": [0.065,125.0,55.0,0.38,0.40],
 "select": [0.22,540.0,860.0,0.02,0.48],
 "possess_in": [0.48,160.0,680.0,0.42,0.53],
 "possess_out": [0.38,740.0,270.0,0.12,0.57],
 "arrow_fly": [0.13,520.0,230.0,0.95,0.46],
 "arrow_hit": [0.16,480.0,155.0,0.48,0.61],
 "wall_enter": [0.32,245.0,62.0,0.60,0.55],
 "wall_pop": [0.30,470.0,110.0,0.12,0.60],
 "flap": [0.12,210.0,95.0,0.82,0.38],
 "bubble": [0.28,820.0,210.0,0.10,0.48],
 "eruption": [0.72,85.0,36.0,0.74,0.65],
 "chime": [0.65,660.0,660.0,0.00,0.46],
 "rustle": [0.22,340.0,120.0,0.80,0.46],
 "wind_loop": [1.0,80.0,80.0,1.0,0.50],
}
static func render(event: String, variant: int = 0) -> AudioStreamWAV:
 var profile: Array = PROFILES[event]
 var duration: float = profile[0]
 var count := int(duration * RATE)
 var pcm := PackedByteArray()
 pcm.resize(count * 2)
 var rng := RandomNumberGenerator.new()
 rng.seed = hash(event) + variant * 109
 var phase := 0.0
 var low_noise := 0.0
 var detune := 1.0 + variant * 0.027
 var values := PackedFloat32Array()
 values.resize(count)
 for i in count:
  var t := float(i) / RATE
  var u := t / duration
  var freq := lerpf(float(profile[1]),float(profile[2]),pow(u,0.65)) * detune
  if event in ["duang","click","land","wall_pop","mini_pop"]:
   freq += 45.0 * sin(t * 45.0) * exp(-t * 12.0)
  phase += freq / RATE
  var n := Wave.noise(rng)
  low_noise = lerpf(low_noise,n,0.13 if event != "arrow_fly" else 0.42)
  var tone := Wave.sine(phase) * 0.85 + Wave.sine(phase*2.01) * 0.15
  if event == "arrow_hit":
   tone = Wave.sine(phase)*0.7 + sin(TAU*1280.0*t)*exp(-t*36.0)*0.3
  elif event == "select":
   tone = Wave.sine(phase) * 0.7 + Wave.sine(phase*1.5) * 0.3
  elif event == "possess_in":
   tone *= 0.7 + 0.3*sin(TAU*t*18.0)
  elif event == "chime":
   tone = sin(TAU*660*t)*exp(-t*5.0)*0.55 + sin(TAU*880*t)*exp(-t*6.0)*0.3 + sin(TAU*1320*t)*exp(-t*8.0)*0.15
  var env := Wave.sfx_envelope(t,duration,0.06,0.72)
  if event in ["whoosh","arrow_fly","flap","possess_in","rustle"]:
   env = pow(sin(PI*u),1.3)
  elif event == "charge":
   env = pow(u,0.7) * smoothstep(1.0,0.92,u)
  else:
   env *= exp(-u*2.4)
  var v := lerpf(tone,low_noise*2.2,float(profile[3])) * env
  if event == "wind_loop":
   # 整数频率正弦叠加的周期噪声；首尾连续，循环不出现点击。
   v=0.0
   for j in 18:
    var f:float=43.0+j*37.0+(j*j)%19
    v+=sin(TAU*f*t+float(j)*2.398)/18.0
  values[i]=v
 var peak := 0.001
 for value in values: peak=maxf(peak,absf(value))
 for i in count:
  pcm.encode_s16(i*2,int(clampf(values[i]/peak*float(profile[4]),-0.95,0.95)*32767.0))
 var stream := AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=RATE
 stream.data=pcm
 if event == "wind_loop":
  stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
  stream.loop_end=count
 return stream
