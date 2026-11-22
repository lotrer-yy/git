class_name VineRibbon
extends Node2D
## 一个带固定 UV 与三角拓扑的网格，整条藤蔓每帧只提交一次顶点。
var _mesh: Polygon2D
var _vertices := PackedVector2Array()
var _count: int
var _left: float
var _right: float
func configure(source: Sprite2D,count: int) -> void:
    z_index = -1
    var atlas := source.texture as AtlasTexture
    if atlas==null: return
    _count = count
    _left = source.position.x
    _right = _left+atlas.region.size.x
    _mesh = Polygon2D.new()
    _mesh.texture = atlas.atlas
    _mesh.material = source.material
    _vertices.resize((count+1)*2)
    var uv := PackedVector2Array()
    uv.resize(_vertices.size())
    var triangles: Array[PackedInt32Array] = []
    for i in range(count+1):
        var y: float = atlas.region.position.y+atlas.region.size.y*float(i)/count
        uv[i*2] = Vector2(atlas.region.position.x,y)
        uv[i*2+1] = Vector2(atlas.region.end.x,y)
        if i<count:
            var a: int = i*2
            triangles.append(PackedInt32Array([a,a+1,a+3]))
            triangles.append(PackedInt32Array([a,a+3,a+2]))
    _mesh.uv = uv
    _mesh.polygons = triangles
    add_child(_mesh)
    source.hide()
func update_points(points: PackedVector2Array) -> void:
    if _mesh==null or points.size()!=_count+1: return
    for i in range(points.size()):
        var tangent: Vector2 = (points[mini(i+1,_count)]-points[maxi(i-1,0)]).normalized()
        var normal := Vector2(tangent.y,-tangent.x)
        _vertices[i*2] = points[i]+normal*_left
        _vertices[i*2+1] = points[i]+normal*_right
    _mesh.polygon = _vertices
