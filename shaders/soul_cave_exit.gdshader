shader_type canvas_item;
uniform float cave_edge_x = 0.0;
varying float world_x;

void vertex() {
	world_x = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x;
}

void fragment() {
	float value = max(COLOR.r, max(COLOR.g, COLOR.b));
	COLOR.rgb = vec3(value);
	// 洞壁左侧的部分被遮住，随着身体移出洞口自然露出来。
	COLOR.a *= step(cave_edge_x, world_x);
}
