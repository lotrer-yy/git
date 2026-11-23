uniform sampler2D map_above : filter_linear, repeat_disable;
uniform sampler2D map_current : filter_linear, repeat_disable;
uniform sampler2D map_below : filter_linear, repeat_disable;
uniform float map_band = 8.0;
uniform vec2 map_origin;
uniform vec2 map_scale = vec2(1.0);
vec4 sky_pixel(vec2 p){
    float y=p.y-map_band*2048.0;
    float x=clamp(p.x/1920.0,0.0001,.9999);
    if(y<0.0) return texture(map_above,vec2(x,(y+2049.0)/2050.0));
    if(y>=2048.0) return texture(map_below,vec2(x,(y-2047.0)/2050.0));
    return texture(map_current,vec2(x,(y+1.0)/2050.0));
}
