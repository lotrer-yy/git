shader_type canvas_item;
#include "res://shaders/formal_sky_reference.gdshaderinc"
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
    // Extend only the original outer cloud color into the newly revealed screen margins.
    vec2 p=(world_position-map_origin)/map_scale;
    float outside=max(max(-p.x,p.x-1920.0),0.0);
    // Continue the cloud's outer contour diagonally instead of stretching its black edge into a horizontal bar.
    COLOR=sky_pixel(vec2(clamp(p.x,1.0,1918.0),p.y-outside*.65));
}
