shader_type canvas_item;
uniform sampler2D edge_profile : filter_linear, repeat_disable;
uniform vec2 lip_origin;
uniform vec2 lip_size = vec2(221.0,184.0);
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
    vec4 c=texture(TEXTURE,UV);
    vec2 p=(world_position-lip_origin)/max(lip_size,vec2(.01));
    float edge=texture(edge_profile,vec2(clamp(p.x+.5,0.0,1.0),.5)).r;
    // The moving lip, including its spring scale, is the squirrel's occlusion boundary.
    c.a*=1.0-smoothstep(edge-.5/lip_size.y,edge+.5/lip_size.y,p.y);
    COLOR=c;
}
