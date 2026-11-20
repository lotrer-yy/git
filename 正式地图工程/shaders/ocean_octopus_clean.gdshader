shader_type canvas_item;
varying vec4 tint;
void vertex() {
    tint = COLOR;
}
void fragment() {
    vec4 color = texture(TEXTURE,UV);
    // 原图不改动，仅去掉低透明度杂点及轮廓外的纯蓝色噪点。
    if (color.a < 0.1 || (color.b-color.r > 0.45 && color.b-color.g > 0.45)) {
        color = vec4(0.0);
    }
    COLOR = color*tint;
}
