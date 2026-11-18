# oh my god：互动与动画音效

## 声音设计
作者的平涂卡通和弹性形变，映射为柔和正弦滑音、短促气流和触地噪声。软弹、吸入、石头触地、箭的掠过与钉入各有固定音色。22类事件，每类两个轻微变化版本，共44个WAV，由固定种子的Godot脚本生成，不含外部录音，不改变美术，不添加画面文字。

## 事件覆盖
按钮悬停、点击与开始蓄力；Logo弹性回弹；小鸟抓起和放开；加载角色弹入、波浪和退场；下潜速度驱动风声；追逐脚步和甩镜；箭掠过、钉柱与钉墙；进墙与出墙；角色起跳落地和脚步；宿主被选中；附身吸入与完成；扇翅、火山喷发、上岸与溺水、树冠和天堂到达。后台预载和画外事件静音。

## 独立模块
- modules/audio/cartoon_sfx_synth.gd：包络、音高、噪声和16位PCM生成。
- modules/audio/sfx.gd：自动加载服务、固定8个场景声部与4个界面声部、限频、混音和风声起停。
- modules/audio/scene_audio_hooks.gd：按模块公开信号接线，玩法脚本不调用音频实现。
- modules/audio/actor_footsteps.gd：按实际地面位移发声，区分幽灵与实体宿主。
- modules/audio/audio_synth.gd：复用abagames的MIT基础波形；许可保存在third_party/abagames-MIT.txt。

## 混音
UI与SFX独立总线；在BgmMusic前插入MusicDuck，保留-4dB余量，重要进出墙、附身、喷发时短暂再避让3dB。原曲与变速逻辑保持不变。箭飞行声间隔至少0.13秒，箭击中声至少0.095秒；每帧最多3个事件，声部数不会随箭数增长。音高变化仅±3%，落地音量随速度变化。R重播停止所有短音与风声。

## 重新生成与替换
Godot --headless --path 工程 --script res://tools/generate_sfx.gd 重新生成assets/audio/sfx中的文件，再运行Godot导入。可直接换同名WAV，无需改玩法代码。无界面运行仅计数事件和验证混音结构；实际声音在本机播放并录制后验收。

## GitHub学习来源
- https://github.com/abagames/agentic-gamedev-skills/tree/main/.agents/skills/creating-godot-procedural-audio
- https://github.com/gamedev-skills/awesome-gamedev-agent-skills/tree/main/skills/godot/godot-audio
- https://github.com/gamedev-skills/awesome-gamedev-agent-skills/tree/main/skills/disciplines/audio-design
