shader_type canvas_item;

uniform bool clean_edges = false;
uniform float outline_pixels = 4.0;
uniform vec2 source_texel = vec2(1.0);
uniform vec4 frame_bounds = vec4(0.0, 0.0, 1.0, 1.0);
varying vec4 tint;

void vertex() {
    tint = COLOR;
    // 扩大绘制边缘，尾鳍贴近原图边界时也能画出完整描边。
    vec2 corner = (UV-frame_bounds.xy)/(frame_bounds.zw-frame_bounds.xy)*2.0-1.0;
    VERTEX += corner*outline_pixels;
    UV += corner*source_texel*outline_pixels;
}

vec4 artwork(vec4 color, vec2 uv) {
    // 采样只限当前帧，不能把相邻帧的鲨鱼带进描边。
    if (any(lessThan(uv,frame_bounds.xy)) || any(greaterThan(uv,frame_bounds.zw))) {
        return vec4(0.0);
    }
    if (clean_edges && (color.a < 0.1 || (color.g-color.r > 0.35 && color.b-color.r > 0.35))) {
        return vec4(0.0);
    }
    return color;
}

void fragment() {
    vec4 color = artwork(texture(TEXTURE,UV),UV);
    float alpha = color.a;
    for (int i = 0; i < 16; i++) {
        float angle = float(i)*6.28318530718/16.0;
        vec2 offset = vec2(cos(angle),sin(angle))*source_texel*outline_pixels;
        alpha = max(alpha,artwork(texture(TEXTURE,UV+offset),UV+offset).a);
    }
    COLOR = vec4(color.rgb*color.a/max(alpha,0.0001),alpha)*tint;
}
