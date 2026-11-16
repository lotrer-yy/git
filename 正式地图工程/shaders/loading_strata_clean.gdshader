shader_type canvas_item;
uniform sampler2D fossils_art;
void fragment() {
 vec4 c=texture(TEXTURE,UV);
 vec2 p=UV/TEXTURE_PIXEL_SIZE;
 // 原循环图已有固定化石；只在这些装饰范围恢复其所在的平涂地层色。
 // 化石用独立素材重新排列，作者原图保持不变。
 bool first=p.x>280.0 && p.x<640.0 && p.y>1610.0 && p.y<1870.0;
 bool skull=p.x>1210.0 && p.x<1840.0 && p.y>1980.0 && p.y<2330.0;
 bool third=p.x>620.0 && p.x<985.0 && p.y>2400.0 && p.y<2680.0;
 float mask=texture(fossils_art,UV).a;
 bool pigment=c.r<109.0/255.0 || c.g>80.0/255.0;
 if ((first || skull || third) && (mask>0.001 || pigment)) {
  c.rgb=skull ? vec3(110.0,59.0,59.0)/255.0 : vec3(117.0,60.0,60.0)/255.0;
 }
 COLOR=c;
}
