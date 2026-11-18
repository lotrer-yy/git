extends SceneTree
const Synth=preload("res://modules/audio/cartoon_sfx_synth.gd")
func _initialize() -> void:
 root.set_meta("generating_sfx",true)
 var directory:="res://assets/audio/sfx"
 DirAccess.make_dir_recursive_absolute(directory)
 for event in Synth.PROFILES:
  for variant in 2:
   var stream:=Synth.render(event,variant)
   var path:="%s/%s_%d.wav"%[directory,event,variant]
   assert(stream.save_to_wav(path)==OK)
 print("已生成 ",Synth.PROFILES.size()*2," 个原创程序化音效 WAV。")
 quit()
