shader_type canvas_item;
// This file relies on a quantize shader include file, listed further down.
// The paths must match your file's location.
#include "res://shaders/quantize.gdshaderinc"
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

uniform float electricity : hint_range(0.0, 3.0);
uniform float scroll_speed : hint_range(0.0, 1.0);
uniform vec4 electric_color : source_color;
uniform sampler2D noise : repeat_enable;


void vertex() {
    g_q_size = getQuantizeSize(CANVAS_MATRIX);
    g_model_matrix = MODEL_MATRIX;
    g_world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;
    g_vertex = VERTEX;
}

void fragment() {
	COLOR = quantizeScreen(SCREEN_TEXTURE, SCREEN_UV, g_vertex);
	if (electricity > 0.0) {
		if (COLOR.a > 0.0) {
			vec4 new_color = mix(COLOR, electric_color, (electricity * ((COLOR.r * 0.6 + COLOR.g * 1.4) / 2.0)));
			//vec4 noise_color = texture(noise, UV + vec2(0, -TIME * scroll_speed));
			//new_color.b += noise_color.b * electricity;
			new_color.a = COLOR.a;
			COLOR = new_color;
		}
	}
}