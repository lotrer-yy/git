shader_type canvas_item;
uniform vec2 source_size = vec2(1839.0,2574.0);
uniform float phase = 0.0;
uniform float bell_squeeze = 0.075;
uniform float sway_pixels = 30.0;
uniform vec2 left_offset = vec2(0.0);
uniform vec2 right_offset = vec2(0.0);
void vertex() {
    vec2 uv_pixel = VERTEX+source_size*vec2(0.5,0.19);
    float tail = smoothstep(0.39,1.0,uv_pixel.y/source_size.y);
    float contract = max(0.0,sin(6.28318530718*phase));
    float release = max(0.0,sin(6.28318530718*(phase-0.3)));
    vec2 point = VERTEX;
    point.x *= 1.0-bell_squeeze*contract*(1.0-tail)+bell_squeeze*0.55*release*(1.0-tail);
    point.y *= 1.0+0.05*contract*(1.0-tail)-0.035*release*(1.0-tail);
    point.x += sin(6.28318530718*phase-tail*4.0+uv_pixel.x/source_size.x*2.0)*sway_pixels*tail*tail;
    point.y += sin(6.28318530718*phase-tail*3.0)*16.0*tail*tail;
    float vertical = smoothstep(480.0,530.0,uv_pixel.y)*(1.0-smoothstep(865.0,930.0,uv_pixel.y));
    float left = smoothstep(410.0,505.0,uv_pixel.x)*(1.0-smoothstep(658.0,750.0,uv_pixel.x));
    float right = smoothstep(1045.0,1141.0,uv_pixel.x)*(1.0-smoothstep(1296.0,1390.0,uv_pixel.x));
    VERTEX = point+vertical*(left_offset*left+right_offset*right);
}
