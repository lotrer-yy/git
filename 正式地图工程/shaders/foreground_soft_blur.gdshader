shader_type canvas_item;
render_mode unshaded;
// 只模糊柱子自身；透明区域使用预乘加权，防止白边和暗色光晕。
uniform float blur_radius : hint_range(0.0, 16.0, 0.5) = 8.0;
varying vec4 tint;
void vertex() {
    tint = COLOR;
}
void fragment() {
    vec4 total = vec4(0.0);
    const float weights[7] = float[7](1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0);
    for (int y = 0; y < 7; y++) {
        for (int x = 0; x < 7; x++) {
            vec2 offset = vec2(float(x - 3), float(y - 3)) * TEXTURE_PIXEL_SIZE * blur_radius * 0.3;
            vec4 sample_color = texture(TEXTURE, UV + offset);
            float weight = weights[x] * weights[y] / 4096.0;
            total += vec4(sample_color.rgb * sample_color.a, sample_color.a) * weight;
        }
    }
    COLOR = vec4(total.rgb / max(total.a, 0.00001), total.a) * tint;
}
