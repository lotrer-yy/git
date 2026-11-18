extends RefCounted
## 从编辑器保存的多边形求上表面，不修改多边形或碰撞节点。
static func top_at(polygon: CollisionPolygon2D, world_x: float) -> Vector2:
	var points := polygon.polygon
	var top := INF
	var left := INF
	var right := -INF
	for point in points:
		var world := polygon.to_global(point)
		left = minf(left, world.x)
		right = maxf(right, world.x)
	var x := clampf(world_x, left + 0.1, right - 0.1)
	for index in range(points.size()):
		var a := polygon.to_global(points[index])
		var b := polygon.to_global(points[(index + 1) % points.size()])
		if is_equal_approx(a.x, b.x) or x < minf(a.x,b.x) or x > maxf(a.x,b.x):
			continue
		top = minf(top, lerpf(a.y,b.y,(x-a.x)/(b.x-a.x)))
	return Vector2(world_x, top)

static func landing_on(body: Node2D) -> Vector2:
	var best := Vector2(INF, INF)
	for child in body.get_children():
		if not child is CollisionPolygon2D or child.disabled:
			continue
		var bounds := Rect2(child.to_global(child.polygon[0]), Vector2.ZERO)
		for point in child.polygon:
			bounds = bounds.expand(child.to_global(point))
		if bounds.size.x < 90 or bounds.size.y > 1500:
			continue
		var point := top_at(child, bounds.get_center().x)
		if point.y < best.y:
			best = point + Vector2(0,-3)
	return best

static func local_top_at(polygon: CollisionPolygon2D, level: Node2D, x: float) -> Vector2:
	# 拼接准备阶段场景尚未入树，使用节点的局部变换链读取编辑后的地面。
	var transform := Transform2D.IDENTITY
	var node: Node = polygon
	while node != level:
		if node is Node2D:
			transform = node.transform * transform
		node = node.get_parent()
	var top := INF
	for index in range(polygon.polygon.size()):
		var a: Vector2 = transform * polygon.polygon[index]
		var b: Vector2 = transform * polygon.polygon[(index+1)%polygon.polygon.size()]
		if is_equal_approx(a.x,b.x) or x < minf(a.x,b.x) or x > maxf(a.x,b.x):
			continue
		top = minf(top,lerpf(a.y,b.y,(x-a.x)/(b.x-a.x)))
	return Vector2(x,top)
