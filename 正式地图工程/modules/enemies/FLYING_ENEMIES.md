# 飞行敌对恶魔

入口：正式地图 `FlyingEnemies` 节点，独立场景 `scenes/enemies/flying_encounter.tscn`。

- 主角附身完成后计时，每 5 秒轮流从地图左、右边界外生成一只，平滑飞入后才允许锁定和攻击。默认同时最多 6 只；离玩家超过 1900 世界单位释放。死亡重来清空敌人与叉子，重新计时；出口过场开始时清空敌人。
- `flying_motion.gd`：带上下弧度的左右往返航点、限加速度转向、避墙及同伴分离；常规速度 245，入场速度 480，不要求额外烘焙导航网格。实体仍与场景地形碰撞。
- `flying_demon.gd`：入场、飞行、举叉蓄势、投出恢复、死亡五个状态。原图交替拍翅，举叉约 0.48 秒后投向蓄势时记录的玩家胸口位置，不追踪已经移开的玩家。墙后和屏幕外不发动攻击；举叉过程中飞出镜头会取消攻击，投射物发射口再检查一次可见性。
- `enemy_fork.gd`：带轻微重力的飞行轨迹，逐帧扫射检测玩家及地形；碰到地形短暂插住后释放。命中调用已有死亡流程。
- `hell_fork.gd`：在 850 世界单位内优先锁定已经入场、当前镜头内且视线可见的飞行敌人，瞄准图标在距屏幕边缘 24 世界单位处即可出现；敌人攻击仍保留原先的屏幕安全边距。仍使用同一个 Shift 投叉操作。默认 80% 命中、20% 落空，均自动回到主角手里，回收时主角弹一下；不会把玩家瞬移到敌人身上。团团仍使用 610 单位锁定范围，原投叉与瞬移逻辑保留。
- `visual/aim_indicator.gd`：复用独立透明 `lock.png`，图标从中心等比例缩到 8%，0.09 秒弹到 116%，再用 0.16 秒回稳。只在新锁定时播放，取消或死亡立即清理，不缩放敌人本体。
- 命中后换作者死亡图，压扁回弹，在空中完整旋转 360°，再下落消失。锁定图标隐藏、停止攻击，并立即从可锁定目标中移除。
- 敌人出现发送方向提示，镜头轻偏向来向；投叉及已有团团动作不因敌人出现而改变物理位置。

## 可调参数

- 场景 `FlyingEnemies`：`spawn_interval`、`max_alive`、`enabled`。
- 敌人场景 `FlyingDemon`：`attack_interval`、`windup_seconds`、`sight_radius`、`death_spin_seconds`、`death_jump_speed`、`death_gravity`。
- `Flight`：`max_speed`、`acceleration`、`orbit_radius`、`sweep_frequency`、`entry_speed`、`entry_acceleration`。
- 主角 `Fork`：`enemy_hit_chance`、`enemy_lock_distance`、`enemy_lock_screen_inset`。
- 敌人 `Lock`：`initial_scale`、`overshoot_scale`、`grow_seconds`、`settle_seconds`。
- `CameraAttention`：`incoming_interest_weight`。

## 美术与参考

六张 PNG 原样复制自作者素材目录，未重绘，也未修改粗黑边。举叉姿势与投射物使用 AtlasTexture 显示相应区域，原 PNG 保留。两张飞行帧统一以身体同一坐标对齐，避免拍翅时角色横跳。

参考：[game-ai 技能](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-ai/SKILL.md) 的状态分离、感知反应延迟、优先避障与转向预算；直接适配现有 Godot 项目，未安装额外插件。

验证：`tests/flying_enemies.gd` 覆盖生成节奏、左右边界外入场、动态入场后锁定、屏幕外禁止攻击、锁定优先级、强制命中/落空、自动回收、完整旋转、敌方投叉和躲避、上限与重置。原团团和死亡重来检查使用关闭定时敌人的固定环境，避免随机敌人干扰单项检查。
