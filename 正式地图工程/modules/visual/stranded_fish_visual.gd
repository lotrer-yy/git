extends RefCounted
## 以接地点补偿旋转和形变：蓄力压扁、拍起、落地，后段逐渐无力。
var visual: Node2D
var sprite: Sprite2D
var rest_position := Vector2.ZERO
var critical_color := Color(1,.48,.44,1)
func configure(node: Node2D, art: Sprite2D) -> void:
    visual = node
    sprite = art
    rest_position = visual.position
func sample(seconds: float, duration: float) -> void:
    var progress := clampf(seconds/maxf(duration,.01),0,1)
    var phase := TAU*(seconds/0.68-.035*seconds*seconds)
    var u := fposmod(phase,TAU)/TAU
    var strength := lerpf(1,.35,progress)
    var hop := sin(clampf(u/.72,0,1)*PI)*18*strength
    var slap := sin(clampf((u-.72)/.28,0,1)*PI)*strength
    visual.scale = Vector2(1+slap*.14-hop*.003,1-slap*.18+hop*.004)
    visual.rotation = sin(phase)*.20*strength
    # 根据实际旋转后的包围盒，保持鱼腹在岸线上方，避免拍打时穿地。
    var half := sprite.texture.get_size()*.5
    var angle := visual.rotation
    var bottom := sin(angle)*sprite.position.x*visual.scale.x+cos(angle)*sprite.position.y*visual.scale.y
    bottom += absf(sin(angle))*half.x*visual.scale.x+absf(cos(angle))*half.y*visual.scale.y
    visual.position = rest_position+Vector2(0,31-bottom-hop)
    visual.modulate = Color.WHITE.lerp(critical_color,smoothstep(0,1,progress))
func settle_dead() -> void:
    visual.position = rest_position
    visual.scale = Vector2.ONE
    visual.rotation = 0
    visual.modulate = critical_color
func reset() -> void:
    visual.position = rest_position
    visual.scale = Vector2.ONE
    visual.rotation = 0
    visual.modulate = Color.WHITE
