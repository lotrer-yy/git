# 平台单体素材

以下文件直接复制作者提供的 PNG，像素和透明通道保持原样：

| 工程素材 | 作者素材（D:/YU/PS/素材/素材/） |
| --- | --- |
| moving.png | 游戏画面-升降平台.png |
| support_vertical.png | 游戏画面-升降平台支架.png |
| support_horizontal.png | 游戏画面-水平移动平台支架.png |
| spiked_platform.png | 游戏画面-浮空平台带刺的.png |
| platform.png | 游戏画面-浮空平台4.png |

在 `formal_hell_entry.tscn` 中编辑：

- `Platforms/Moving19..23`：移动平台本体、可编辑的承重多边形、运动方向及距离。
- `Platforms/Static04/UpperArt`：为该节点上方已有的第二块承重碰撞补齐普通平台原图；保持现有多边形、世界位置和落脚高度不变。
- `PlatformSupports/Support19..23`：固定支架，独立于移动平台。
- `Terrain/Rock09/ThornArt1`、`Terrain/Rock10/ThornArt2`、`Terrain/Rock11/ThornArt3..4`、`Platforms/Static06..07/Art`：六处带刺平台单体。
- `Hazards/Thorn01..06/Left` 和 `Right`：左右尖刺各一个缩小的三角形触发区。
- 原 Hazard01..06 中对应的旧宽触发区保留顶点、禁用；Hazard02 下不属于带刺平台的岩壁尖刺仍启用。

带刺平台保留原先手调的承重上沿，贴图顶部比碰撞上沿高 12 像素，避免角色站在图案上方。承重多边形的底部截到平台本体，尖刺另行判定。

`platform_runtime/` 是去掉重复移动平台、支架及带刺平台图案后的游戏底图。原始 `reference_map/` 和之前的 `ball_free_runtime/` 保留，不用其内嵌图案代替单体节点。
