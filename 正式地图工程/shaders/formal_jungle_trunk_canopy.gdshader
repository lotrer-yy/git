shader_type canvas_item;
// 复用正式地图树冠的深色叶片轮廓遮挡首根主藤蔓，不盖住原来的背景。
uniform sampler2D canopy_upper : filter_linear, repeat_disable;
uniform sampler2D canopy_lower : filter_linear, repeat_disable;
void fragment() {
    float map_y = 20143.0 + UV.y * 9146.0;
    if (map_y < 21166.0) {
        vec4 canopy;
        if (map_y < 20480.0) {
            canopy = texture(canopy_upper, vec2(UV.x,(map_y-18432.0+1.0)/2050.0));
        } else {
            canopy = texture(canopy_lower, vec2(UV.x,(map_y-20480.0+1.0)/2050.0));
        }
        COLOR.a *= smoothstep(0.185,0.225,canopy.g);
    }
}
