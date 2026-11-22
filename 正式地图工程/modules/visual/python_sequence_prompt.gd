extends CanvasLayer
## 只使用作者提供的 WASD/SHIFT 图块；已完成变绿，当前键弹动，底线显示总剩余时间。
const ART = preload("res://assets/art/jungle/python/wasdshift.png")
const REGIONS = [Rect2(0,0,156,159),Rect2(162,0,152,156),Rect2(317,1,145,155),Rect2(466,1,142,155),Rect2(119,165,355,146)]
var keys: Array[Sprite2D] = []
var shade: ColorRect
var rail: ColorRect
var progress: ColorRect
var elapsed: float = 0
var error_flash: float = 0
func _ready() -> void:
    layer=50
    shade=ColorRect.new()
    shade.color=Color(0,0,0,0) # World-space shade sits behind actors.
    shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    for region in REGIONS:
        var texture := AtlasTexture.new()
        texture.atlas=ART
        texture.region=region
        texture.filter_clip=true
        var key := Sprite2D.new()
        key.texture=texture
        add_child(key)
        keys.append(key)
    rail=ColorRect.new()
    rail.color=Color(.06,.07,.04,.8)
    rail.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(rail)
    progress=ColorRect.new()
    progress.color=Color(1,.7,.16,1)
    progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(progress)
    hide()
func begin() -> void:
    elapsed=0
    error_flash=0
    show()
func flash_wrong() -> void:
    error_flash=.22
func sample(index: int,remaining: float,duration: float,delta: float) -> void:
    elapsed+=delta
    error_flash=maxf(0,error_flash-delta)
    var size: Vector2 = get_viewport().get_visible_rect().size
    shade.size=size
    var height: float = clampf(size.x/11,44,100)
    var gap: float = height*.16
    var total: float = gap*4
    for key in keys: total+=height*key.texture.get_width()/key.texture.get_height()
    var x: float = (size.x-total)*.5
    var y: float = maxf(height*.75,size.y*.16)
    for i in keys.size():
        var width: float = height*keys[i].texture.get_width()/keys[i].texture.get_height()
        keys[i].position=Vector2(x+width*.5,y)
        var pulse: float = 1+.07*sin(elapsed*22) if i==index else 1
        pulse+=.22*exp(-elapsed*12)
        keys[i].scale=Vector2.ONE*height/keys[i].texture.get_height()*pulse
        keys[i].modulate=Color(.48,1,.55) if i<index else (Color.WHITE if i==index else Color(.52,.55,.52,.85))
        if i==index and error_flash>0: keys[i].modulate=Color(1,.35,.3)
        x+=width+gap
    rail.position=Vector2((size.x-total)*.5,y+height*.7)
    rail.size=Vector2(total,8)
    progress.position=rail.position
    progress.size=Vector2(total*clampf(remaining/duration,0,1),8)
