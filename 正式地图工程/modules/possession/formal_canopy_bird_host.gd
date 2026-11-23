extends PossessableHost
func _ready() -> void:
    super._ready()
    remove_from_group("possessable_hosts")
    remove_from_group("sky_hosts")
    add_to_group("formal_canopy_birds")
