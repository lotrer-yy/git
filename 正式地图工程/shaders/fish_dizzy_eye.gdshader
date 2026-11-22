shader_type canvas_item;
uniform float phase=0.0;
void fragment() {
    vec4 c=texture(TEXTURE,UV);
    vec2 p=UV/TEXTURE_PIXEL_SIZE-vec2(47.0,48.0);
    float patch=1.0-smoothstep(.9,1.0,length(p/vec2(8.5,11.0)));
    if(patch>0.0) {
        c.rgb=mix(c.rgb,vec3(1.0,196.0/255.0,156.0/255.0),patch);
        float distance_to_ink=100.0;
        for(int i=0;i<40;i++) {
            float a=float(i)/40.0;
            float b=float(i+1)/40.0;
            vec2 start=vec2(cos(a*10.5+phase),sin(a*10.5+phase))*mix(.5,6.7,a);
            vec2 end=vec2(cos(b*10.5+phase),sin(b*10.5+phase))*mix(.5,6.7,b);
            vec2 segment=end-start;
            float u=clamp(dot(p-start,segment)/max(dot(segment,segment),.001),0.0,1.0);
            distance_to_ink=min(distance_to_ink,length(p-start-segment*u));
        }
        float ink=1.0-smoothstep(.8,1.5,distance_to_ink);
        c.rgb=mix(c.rgb,vec3(0),ink*patch);
    }
    COLOR=c;
}
