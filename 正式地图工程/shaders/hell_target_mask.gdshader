shader_type canvas_item;
uniform sampler2D visibility_mask : filter_nearest;
uniform bool clip_normal = true;
void fragment() {
	if (clip_normal) {
		COLOR.a *= texture(visibility_mask, UV).r;
	}
}
