# 碎裂平台

场景：`scenes/levels/formal_hell_entry.tscn`。

- `Platforms/Breakable09..18/Art` 使用作者提供的 `游戏画面-碎裂平台.png`。
- `Piece1`、`Piece2` 使用作者提供的两张碎片，保留原始透明通道；节点位置和 offset 已分别校准，旋转中心设在碎片图案内部。
- 九个现存承重多边形按完整单体的可见轮廓向内收约 2 像素保存，移除了旧碰撞节点上的纵向缩放。各平台原来编辑的落脚高度保持不变，贴图与碰撞一起对齐。仍可在 Godot 中逐点编辑，运行及重开不覆盖顶点。
- `Breakable12` 原先已被移除碰撞，继续保持停用，不自动恢复。
- `Breakable18` 下原来属于旁边岩壁的额外碰撞移入 `Terrain/Breakable18FixedTerrain`，形状和世界坐标不变，不随平台断裂消失。
- 该固定碰撞上的 `SpikeArt06` 侧向尖刺由 `Hazards/SideSpike06` 检测致死接触；检测区沿原轮廓向外留约 4 单位，避免实体碰撞先挡住角色而无法触发。安全石面不属于死亡区，检测区也不随碎裂平台消失。

`modules/environment/hell_breakable.gd` 独立处理踩踏碎裂。踩踏后图案小幅松动，并逐渐张开裂缝；承重碰撞保持不动。满 `break_seconds`（默认 1.5 秒）同时隐藏完整图、撤掉承重碰撞、释放两张不透明碎片。之后各自累计重力、位移和旋转，最后淡出。完整图不会与两张碎片长时间交叉淡化。

平台断裂后开始计算 `respawn_seconds`（默认 5 秒），时间到后在原位自动恢复图案及承重碰撞，并播放 0.35 秒的弹性复原。图案缩放固定上沿，碰撞本身不缩放。复原动画结束后可以再次踩碎。

可在检查器调整 `break_seconds`、`separation_speed`、`spin_speed`、`debris_gravity`、`debris_seconds`、`respawn_seconds`。每个平台的裂缝材质状态相互独立，重开会取消复原动画，并复原图案、碰撞、位置、旋转、透明度和计时。

运动与生命周期设计参考 [Godot Polygon2D Fracture / FractureShard.gd](https://github.com/SoloByte/godot-polygon2d-fracture/blob/main/demo/src/FractureShard.gd)。此处使用手绘碎片和独立的本工程脚本，未引入随机切割、对象池或示例中的全局慢动作。

验证脚本：`tests/breakable_platforms.gd`，检查九个平台各三个落脚点、1.5 秒承重、独立开裂、连续加速下落和重开复原。
