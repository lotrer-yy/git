shader_type canvas_item;
// 白纸上的黑边恢复为透明抗锯齿，避免保留灰白色溢边；彩色区域保持原色。
void fragment() {
    vec4 c=texture(TEXTURE,UV);
    float lo=min(c.r,min(c.g,c.b));
    float hi=max(c.r,max(c.g,c.b));
    float neutral=1.0-smoothstep(0.02,0.12,hi-lo);
    c.a*=mix(1.0,1.0-lo,neutral);
    c.rgb=mix(c.rgb,vec3(0.0),neutral);
    COLOR=c;
}
