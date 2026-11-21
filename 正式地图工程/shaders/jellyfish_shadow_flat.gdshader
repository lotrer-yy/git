shader_type canvas_item;
varying vec4 tint;
varying vec2 local_point;
uniform sampler2D atlas : filter_linear, repeat_disable;
uniform vec2 atlas_size;
uniform vec4 from_region;
uniform vec4 to_region;
uniform vec2 from_anchor;
uniform vec2 to_anchor;
uniform float pose_blend = 0.0;
void vertex() { tint = COLOR; local_point = VERTEX; }
float pose_alpha(vec4 region, vec2 anchor) {
    vec2 point = local_point+anchor;
    if (point.x<0.0 || point.y<0.0 || point.x>=region.z || point.y>=region.w) return 0.0;
    return texture(atlas,(region.xy+point)/atlas_size).a;
}
void fragment() {
    float amount = smoothstep(0.0,1.0,pose_blend);
    float alpha = mix(pose_alpha(from_region,from_anchor),pose_alpha(to_region,to_anchor),amount);
    COLOR = vec4(16.0/255.0,27.0/255.0,45.0/255.0,alpha)*tint;
}
