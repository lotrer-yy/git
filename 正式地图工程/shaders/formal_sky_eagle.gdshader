shader_type canvas_item;
#include "res://shaders/formal_sky_reference.gdshaderinc"
uniform float reveal_alpha = 0.0;
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
float cloud(vec2 p){vec3 c=sky_pixel(p).rgb;return smoothstep(.82,.9,min(c.r,min(c.g,c.b)));}
void fragment(){
    vec2 p=(world_position-map_origin)/map_scale;
    // Sample the original painted cloud banks so the eagle stays behind their outlines.
    float cover=max(cloud(p),max(cloud(p+vec2(-14.0,0.0)),cloud(p+vec2(14.0,0.0))));
    cover=max(cover,max(cloud(p+vec2(0.0,-14.0)),cloud(p+vec2(0.0,14.0))));
    vec4 c=texture(TEXTURE,UV);
    c.a*=(1.0-cover)*reveal_alpha;
    if(p.x<0.0 || p.x>1920.0 || p.y<0.0) c.a=0.0;
    COLOR=c;
}
