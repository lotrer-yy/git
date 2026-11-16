# 借身登天 · 正式 Godot 项目

在 Godot 项目管理器导入本目录的 project.godot，按 F5 从游戏首页开始。

当前完整流程：首页 Start → 下潜加载 → 幽灵逃跑与恶魔追逐 → 幽灵进墙、停顿 → 同一镜头右移进入正式地狱地图 → 原白色小幽灵从墙后弹出 → 落地后 WASD 操作。R 随时从首页重播。Settings 保留弹性反馈，不添加设置页或新文字。

动画和正式地图处在同一连续世界。作者大柱子的右边缘与正式地图左墙直接贴边，颜色一致，不叠重复墙；地图在动画期间后台预载，镜头走到右边才自然进入游戏。

## 在 Godot 中编辑

- scenes/ui/main_menu.tscn：主入口与开场模块组装。
- scenes/ui/opening_cinematic_map.tscn：追逐背景、中前景、虚化柱子与最后厚墙。
- scenes/levels/formal_hell_entry.tscn：正式地图、原小幽灵、初始地面和左右墙碰撞、WallSpawn 与 LandingPoint。
- scenes/map/formal_world_map.tscn：游戏使用的完整四区地图与分层节点。
- scenes/map_browser.tscn：保留原来的独立长地图浏览。打开后按 F6，鼠标滚轮和上下方向键浏览，Home/End 到地图顶部/底部。

## 独立模块

功能按 modules 下的职责目录拆分，场景只负责组装。modules/功能模块目录.md 与 docs/粗柱子衔接正式地图.md 记录模块入口和衔接方式。视差、虚化、弹跑、推镜、追逐分镜、地图加载、侧墙弹出、输入和移动均为独立脚本或材质。

assets/map 保留原来的地图浏览资产；assets/formal_map 是完整游戏中使用的正式地图分块。原始作者文件没有修改。地图高清切片按镜头位置后台加载，不把整张五万像素高的图一次上传为单张纹理。

当前正式地狱已接入开场、小幽灵和初始移动，其他正式关卡机关、敌人和附身玩法仍按后续布置继续制作。
