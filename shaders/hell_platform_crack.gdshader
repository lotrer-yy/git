shader_type canvas_item;

uniform float fracture_amount : hint_range(0.0, 1.0) = 0.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	float seam = 0.5 + sin(UV.y * 18.0) * 0.045 + sin(UV.y * 39.0) * 0.018;
	float side = sign(UV.x - seam);
	vec2 sample_uv = UV - vec2(side * fracture_amount * 0.012, 0.0);
	COLOR = texture(TEXTURE, sample_uv) * tint;
	if (abs(UV.x - seam) < fracture_amount * 0.015 || sample_uv.x < 0.0 || sample_uv.x > 1.0) {
		COLOR.a = 0.0;
	}
}
