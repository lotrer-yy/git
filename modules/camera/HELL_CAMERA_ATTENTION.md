# 地狱机关构图与交换镜头

`hell_camera_attention.gd` 独立负责构图，挂在正式地狱的 `CameraAttention` 节点。

- 投叉模块通过 `exchanged` 信号通知镜头；不再在交换瞬间直接把镜头吸到恶魔身上。
- `FollowCamera.blend_to_target()` 从当前画面中心开始，用短缓动衔接新的角色位置，保留原有跟随平滑和边界限制。
- 优先关注当前选中或插中的球球，弹射中关注落脚平台；没有球球目标时，关注附近上方的移动、漂浮或碎裂平台。
- 偏移限制在屏幕像素范围内，目标变化与离开机关都平滑收回。相近平台之间保留原关注点，减少来回摆动。
- 不改变视野缩放、角色位置、机关碰撞、投叉锁定范围或弹射轨迹。仍由同一台开场显示相机输出。
- 死亡及重来清除旧关注点，洞口入场和未附身时不启用机关偏移。

在 Godot 的 `CameraAttention` 节点调整 `maximum_peek_pixels`、`interest_weight`、`interest_radius`、`bias_response` 和 `exchange_blend_seconds`。`enabled` 控制机关偏移开关，交换时的平滑衔接仍保留。

上方机关按屏幕安全边距构图，平台关注真实碰撞顶面而非节点原点；不会为了展示机关把角色挤出画面。`screen_margin_pixels` 控制安全边距。叉子飞行按原图尖头角度校正，插中图绕球心保持来向，恢复球球状态时清除旋转。
