shader_type canvas_item;
uniform sampler2D crown : filter_linear, repeat_disable;
uniform vec2 crown_origin = vec2(0.0,16384.0);
uniform vec2 map_scale = vec2(1.0);
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
    vec4 c=texture(TEXTURE,UV);
    vec2 p=(world_position-crown_origin)/map_scale;
    if(p.x>=0.0 && p.x<1920.0 && p.y>=0.0 && p.y<2048.0){
        vec3 leaf=texture(crown,vec2(p.x/1920.0,(p.y+1.0)/2050.0)).rgb;
        float mask=(1.0-smoothstep(.27,.32,leaf.r))*(1.0-smoothstep(.27,.32,leaf.g))*(1.0-smoothstep(.10,.15,leaf.b));
        c.a*=1.0-mask;
    }
    COLOR=c;
}
