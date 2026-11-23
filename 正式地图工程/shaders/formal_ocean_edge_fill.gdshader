shader_type canvas_item;
#include "res://shaders/formal_sky_reference.gdshaderinc"
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
    vec2 p=(world_position-map_origin)/map_scale;
    COLOR=sky_pixel(vec2(clamp(p.x,1.0,1918.0),p.y));
}
