shader_type canvas_item;

uniform sampler2D body_texture : source_color, filter_linear, repeat_disable;
uniform vec2 body_offset = vec2(0.0);
uniform vec4 ball_bounds = vec4(0.0);
uniform bool hide_ball = false;
uniform bool fill_wall_edge = false;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	vec4 result = texture(TEXTURE, UV);
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	if (fill_wall_edge && pixel.x > size.x - 65.0 && pixel.y > 30.0 && pixel.y < size.y - 30.0) {
		vec4 inside = texture(TEXTURE, vec2((size.x - 110.0) / size.x, UV.y));
		if (inside.a > 0.9 && inside.r > 0.3) {
			result = inside;
		}
	}
	if (hide_ball && pixel.x >= ball_bounds.x && pixel.y >= ball_bounds.y
		&& pixel.x < ball_bounds.x + ball_bounds.z && pixel.y < ball_bounds.y + ball_bounds.w) {
		vec2 body_uv = (pixel - body_offset) / vec2(textureSize(body_texture, 0));
		if (body_uv.x < 0.0 || body_uv.y < 0.0 || body_uv.x >= 1.0 || body_uv.y >= 1.0) {
			result = vec4(0.0);
		} else {
			result = texture(body_texture, body_uv);
		}
	}
	COLOR = result * tint;
}
