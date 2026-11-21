shader_type canvas_item;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
    // 统一为作者剪影的深海蓝，保留逐帧轮廓透明度。
    COLOR = vec4(16.0/255.0,27.0/255.0,45.0/255.0,texture(TEXTURE,UV).a)*tint;
}
