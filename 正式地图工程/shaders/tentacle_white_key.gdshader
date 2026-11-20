shader_type canvas_item;
// 只在显示时去掉图集的白底，保留原 PNG 与橙色、奶油色吸盘。
void fragment() {
    vec4 texel = texture(TEXTURE, UV);
    float paper = min(texel.r, min(texel.g, texel.b));
    float chroma = max(texel.r, max(texel.g, texel.b)) - paper;
    if (chroma < 0.07) {
        // 白底上的灰色抗锯齿恢复为半透明黑边，避免海底深色背景出现白圈。
        COLOR.rgb = vec3(0.0);
        COLOR.a *= 1.0 - paper;
    } else {
        COLOR.a *= 1.0 - smoothstep(0.90, 0.98, paper);
    }
}
