shader_type canvas_item;
void fragment(){
    vec4 c=texture(TEXTURE,UV);
    float leaves=(1.0-smoothstep(.27,.32,c.r))*(1.0-smoothstep(.27,.32,c.g))*(1.0-smoothstep(.10,.15,c.b));
    COLOR=vec4(c.rgb,c.a*leaves);
}
