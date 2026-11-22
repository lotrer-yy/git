extends Node2D
## 只拉长下半段脖子；头部整体平移不拉伸，颈根固定在原注册点。
var mesh: Polygon2D
const SEGMENTS: int = 32
func _ready() -> void:
    mesh=Polygon2D.new()
    add_child(mesh)
func update_pose(texture: AtlasTexture,base: Vector2,extension: float) -> void:
    var width: float = texture.region.size.x
    var height: float = texture.region.size.y
    var vertices:=PackedVector2Array()
    var uv:=PackedVector2Array()
    vertices.resize((SEGMENTS+1)*2)
    uv.resize(vertices.size())
    for i in range(SEGMENTS+1):
        var y: float = height*float(i)/SEGMENTS
        var shift: float = extension*(1-smoothstep(310,base.y,y))
        vertices[i*2]=Vector2(0,y-shift)
        vertices[i*2+1]=Vector2(width,y-shift)
        uv[i*2]=texture.region.position+Vector2(0,y)
        uv[i*2+1]=texture.region.position+Vector2(width,y)
    if mesh.polygons.is_empty():
        var triangles: Array[PackedInt32Array] = []
        for i in SEGMENTS:
            var a: int = i*2
            triangles.append(PackedInt32Array([a,a+1,a+3]))
            triangles.append(PackedInt32Array([a,a+3,a+2]))
        mesh.polygons=triangles
    mesh.texture=texture.atlas
    mesh.uv=uv
    mesh.polygon=vertices
