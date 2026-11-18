shader_type canvas_item;

uniform bool fill_left = false;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 pixel = UV * size;
	vec4 result = texture(TEXTURE, UV);
	bool join_band = fill_left ? pixel.x < 70.0 : pixel.x > size.x - 65.0;
	if (join_band && pixel.y > 30.0 && pixel.y < size.y - 30.0) {
		vec2 sample_uv = vec2((fill_left ? 90.0 : size.x - 110.0) / size.x, UV.y);
		vec4 inside = texture(TEXTURE, sample_uv);
		if (inside.a > 0.9 && inside.r > 0.3) {
			result = inside;
		}
	}
	COLOR = result * tint;
}
