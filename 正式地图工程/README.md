# 借身登天 · 正式地图工程

独立于旧原型的新 Godot 4.7.2 工程。本版只包含作者的完整地图、浏览镜头与背景视差，没有角色、机关或游戏画面文字。

## 打开与浏览

在 Godot 项目管理器导入本目录的 project.godot，打开后按 F5。

- 鼠标滚轮向上：向天堂方向浏览；向下：返回地狱。
- 上下方向键：连续移动镜头。
- Home：前往地图最顶端；End：返回最底端。
- 默认从地狱底部开始，边界以 1920×52000 的实际地图为准。

## 一个模块负责一件事

| 文件 | 职责 |
| --- | --- |
| modules/input/map_browser_input.gd | 读滚轮和按键，发出滚动信号 |
| modules/camera/map_browser_camera.gd | 接收信号，平滑移动镜头并限制边界 |
| modules/map/finite_parallax.gd | 单独控制一层背景的有限范围视差 |
| modules/map/map_texture_streamer.gd | 后台载入附近高清切片，释放远处高清切片 |
| scenes/map/world_map.tscn | 保存真实地图节点、背景层和固定前景的位置 |
| scenes/map_browser.tscn | 组装地图、输入、镜头和纹理载入模块 |

未来角色可以组装到 CharacterMount，不需要改输入浏览和地图绘制代码。浏览输入到时可以整体禁用或替换。

## 编辑地图与视差

主场景展开 Map，再展开 Base、Backgrounds、Foreground，就能在编辑器看到完整地图与各个独立切片。编辑器使用轻量预览，切片位置与游戏原图一致；运行时相机附近自动换成原分辨率。

Backgrounds 下有 Hell、Ocean、Jungle、Sky 四层。分别选中后可调：

- Scroll Ratio：默认 0.94，背景相对镜头稍慢；1 表示没有视差。
- Maximum Offset：限制错位幅度，避免长地图累计偏移。
- Boundary Blend：在场景交界平滑归零，保留水面、树冠和地层衔接。
- Enabled：单独开关该层视差。

每层使用区域中央作为锚点。前景直接使用作者提供的“游戏总地图-前景.png”，墙壁、地层、水面边缘、云沿等保留在这张固定前景上，不再从总图猜测轮廓。底层只包含独立背景的合成，不包含第二套前景，避免背景移动时出现重复墙壁与残影。没有拉伸作者原画，也没有修改作者原文件。

地狱背景导出中还带有旧侧墙。导入副本对左右各 280 像素做相邻背景纹理延展，移除旧墙与黑线，侧墙只使用作者最新前景。视差不会再带出第二套墙壁。

天空、丛林和前景导出包含白色底和蓝色参考线，仅在生成的副本里清除。前景白底使用总图与背景对照恢复透明度，保留真正的白云，并清理抗锯齿边缘的白底毛边。背景中已绘制的细节保持原样。上帝和场景装饰只是地图像素，本工程不添加它们的角色或动画模块。

## 重新导入作者地图

安装 Python 依赖 Pillow、NumPy 后，运行：

```powershell
python tools/build_map_assets.py "D:/systemDir/Desktop/总的图片"
```

输入是游戏总地图.png、游戏总地图-前景.png 与四张“游戏总地图-区域背景.png”。生成的 assets/map/manifest.json 记录原图校验值、区域范围和各块坐标。整张 52000 高的图片不作为单张 GPU 纹理使用；所有高清纹理块最长约 2050 像素，分块边缘有一像素延展。

## GitHub 参考

参考 Godot 官方仓库的 [2D Parallax](https://github.com/godotengine/godot-docs/blob/master/tutorials/2d/2d_parallax.rst) 与 [Parallax2D 属性说明](https://github.com/godotengine/godot-docs/blob/master/classes/class_parallax2d.rst)。

官方节点适合分层滚动；此工程沿用其滚动倍率原理，单独实现区域锚点、有限位移及交界归零，适配作者这张不循环的超长连续地图。没有安装不必要的第三方插件。
