/*
 * This should be your main shader file if using with a ColorRect.
*/

//shader_type canvas_item;
//render_mode unshaded;
// This file relies on a quantize shader include file, listed further down.
// The paths must match your file's location.
//#include "res://shaders/quantize.gdshaderinc"
//uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest  ;

//void vertex() {
    //g_q_size = getQuantizeSize(CANVAS_MATRIX);
    //g_model_matrix = MODEL_MATRIX;
    //g_world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;
    //g_vertex = VERTEX;
//}
//
//void fragment() {
	//COLOR = quantizeScreen(SCREEN_TEXTURE, SCREEN_UV, g_vertex);
//}

/*
 * This should be your main shader file if using with a Sprite2D.
*/

shader_type canvas_item;
// This file relies on a quantize shader include file, listed further down.
// The paths must match your file's location.
#include "res://shaders/quantize.gdshaderinc"

void vertex() {
    g_q_size = getQuantizeSize(CANVAS_MATRIX);
    g_model_matrix = MODEL_MATRIX;
    g_texture_size = 1. / TEXTURE_PIXEL_SIZE;
    g_vertex = VERTEX;
    g_flat_vertex = VERTEX;
}

void fragment() {
	COLOR = quantizeTexture(TEXTURE, UV);
}

// Don't draw lights on the ColorRect
//void light() {
	//
//}
