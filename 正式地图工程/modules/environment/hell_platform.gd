extends AnimatableBody2D
## 平台仅处理承重、移动与碎裂；角色运动仍由原有模块负责。
@export_enum("static", "floating", "moving", "breakable") var kind: String = "static"
@export var travel: Vector2 = Vector2(0, 650)
@export var middle_speed: float = 180.0
@export var break_seconds: float = 1.5
var origin: Vector2
var elapsed: float = 0.0
var progress: float = 0.0
var direction: float = 1.0
var loaded: bool = false
var broken: bool = false
var sprite: Sprite2D
var collision: CollisionPolygon2D

func _ready() -> void:
	origin = position
	add_to_group("hell_platforms")
	sprite = $Art
	collision = get_node_or_null("Collision")
	broken = collision == null
	if broken:
		set_physics_process(false)
	sprite.visible = not broken

func _physics_process(delta: float) -> void:
	elapsed += delta
	var standing := false
	for body in get_tree().get_nodes_in_group("hell_players"):
		if not body.is_on_floor():
			continue
		for index in range(body.get_slide_collision_count()):
			if body.get_slide_collision(index).get_collider() == self:
				standing = true
	if kind == "floating":
		position.y = lerpf(position.y, origin.y + (5.0 if standing else 0.0) + sin(elapsed * 1.7) * 2.0, 1.0 - exp(-5.0 * delta))
		rotation = lerp_angle(rotation, sin(elapsed * 1.4) * (0.012 if standing else 0.005), 1.0 - exp(-4.0 * delta))
	elif kind == "moving":
		# 有限端部区间内减速，端部最低速度为中段的 0.9 倍。
		var edge := minf(progress, 1.0 - progress)
		var speed := middle_speed * lerpf(0.9, 1.0, smoothstep(0.0, 0.15, edge))
		progress = clampf(progress + direction * speed * delta / travel.length(), 0.0, 1.0)
		if progress >= 1.0 or progress <= 0.0:
			direction *= -1.0
		position = origin + travel * progress

func reset() -> void:
	position = origin
	rotation = 0.0
	elapsed = 0.0
	progress = 0.0
	direction = 1.0
	loaded = false
	broken = collision == null
	modulate.a = 1.0
	sprite.modulate.a = 1.0
	if collision != null:
		collision.set_deferred("disabled", false)
