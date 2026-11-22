extends RefCounted
## 顺着摆动速度逐渐借力；接近目标摆幅后收力，避免无限加速和绕顶。
var held_seconds: float = 0
var direction: float = 1
func reset() -> void:
    held_seconds = 0
    direction = 1
func pump(rope: SwingVine, velocity: Vector2, delta: float, bias: float, max_angle_degrees: float) -> float:
    held_seconds += delta
    var radius: Vector2 = rope.to_global(rope.rope.sample(rope.grip_length))-rope.global_position
    var length: float = maxf(radius.length(),35)
    var tangent := Vector2(radius.y,-radius.x).normalized()
    var tangential_speed := velocity.dot(tangent)
    if absf(tangential_speed)>8: direction = signf(tangential_speed)
    elif held_seconds<.15 and absf(bias)>.1: direction = signf(bias)
    var energy: float = .5*tangential_speed*tangential_speed+rope.gravity*maxf(0,length-radius.y)
    var target: float = rope.gravity*length*(1-cos(deg_to_rad(max_angle_degrees)))
    var reserve: float = clampf((target-energy)/maxf(target*.35,1),0,1)
    var ramp: float = smoothstep(0,.6,held_seconds)
    return clampf(direction+bias*.15,-1,1)*ramp*reserve
