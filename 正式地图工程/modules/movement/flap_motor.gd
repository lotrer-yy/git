extends Node
## 单次按键拍翅；可配置玩家长按连续拍翅，AI 仍由巡飞指令驱动。
@export var flap_while_held: bool = false
@export_range(.1,1.0) var held_flap_interval: float = .28
var _flap_cooldown: float = 0.0
@export var gravity: float = 1150.0
@export var flap_speed: float = 540.0
@export var move_speed: float = 430.0
@export var acceleration: float = 1500.0
@export var top_limit: float = -520.0
var enabled := true
var body: CharacterBody2D
var reader: PlatformerInput
signal flapped
func _ready() -> void:
	process_physics_priority=-10
	body=get_parent()
	reader=body.get_node("Input")
func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_flap_cooldown=maxf(0,_flap_cooldown-delta)
	body.velocity.x=move_toward(body.velocity.x,reader.move_axis*move_speed,acceleration*delta)
	body.velocity.y=minf(body.velocity.y+gravity*delta,850)
	var held_flap: bool=flap_while_held and not reader.external_control and reader.jump_held and _flap_cooldown<=0
	if reader.jump_pressed or held_flap:
		_flap_cooldown=held_flap_interval
		body.velocity.y=-flap_speed
		flapped.emit()
		reader.jump_pressed=false
	body.move_and_slide()
	body.position.y=maxf(body.position.y,top_limit)
func reset() -> void:
	_flap_cooldown=0
	if body!=null:
		body.velocity=Vector2.ZERO
