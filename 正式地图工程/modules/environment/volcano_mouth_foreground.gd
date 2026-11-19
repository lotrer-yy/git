extends Polygon2D
## 从原地图纹理的黑色口沿提取前景轮廓，复用原像素遮挡主角，不添加新美术。
@export_node_path("Sprite2D") var source_path: NodePath = ^"../../Map/ImageTiles/Tile20"
@export var mouth_bounds: Rect2i = Rect2i(600,550,650,350)

func _ready() -> void:
    var source := get_node(source_path) as Sprite2D
    texture = load(source.get_meta("runtime_texture",source.get_meta("full_texture")))
    var image := texture.get_image()
    var region_offset := source.region_rect.position if source.region_enabled else Vector2.ZERO
    position = get_parent().to_local(source.global_position)
    var outline := PackedVector2Array([
        Vector2(mouth_bounds.position),
        Vector2(mouth_bounds.end.x,mouth_bounds.position.y)])
    # 每列下沿贴着原画黑边，范围仅覆盖火山口，不覆盖下方平台和通行区。
    for x in range(mouth_bounds.end.x,mouth_bounds.position.x-1,-2):
        var edge := mouth_bounds.position.y
        for y in range(mouth_bounds.position.y,mouth_bounds.end.y):
            var color := image.get_pixel(x+int(region_offset.x),y+int(region_offset.y))
            if maxf(color.r,maxf(color.g,color.b)) < 0.13:
                edge = y+1
        outline.append(Vector2(x,edge))
    polygon = outline
    var coordinates := PackedVector2Array()
    for point in outline:
        coordinates.append(point+region_offset)
    uv = coordinates
