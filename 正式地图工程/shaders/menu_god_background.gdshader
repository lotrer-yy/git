shader_type canvas_item;
#include "res://shaders/menu_cloud_shape.gdshaderinc"
uniform sampler2D god_art;
void fragment() {
 COLOR=clean_menu_background(texture(TEXTURE,UV),texture(god_art,UV).a,
  texture(TEXTURE,vec2(1250.0/1920.0,UV.y)),UV*vec2(1920.0,1080.0));
}
