extends PossessionController
func _ready() -> void:
    # 单独打开丛林排版场景时没有共用幽灵和相机，仍可预览鸟的巡飞。
    if not has_node(soul_path):
        enabled=false
        set_physics_process(false)
        set_process_unhandled_input(false)
        return
    super._ready()
func reset() -> void:
    if is_instance_valid(soul): super.reset()
