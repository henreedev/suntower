shader_type canvas_item;
render_mode unshaded;

uniform sampler2D noise : repeat_enable;
const float str = 0.4;
const float hoz_offset = -0.1;

void fragment() {
	vec4 noise_color = texture(noise, UV + vec2(TIME * hoz_offset, 0));
	vec4 orig_color = texture(TEXTURE, UV);
	float noise_str = noise_color.r;
	if (noise_str < 0.4) noise_str = 0.0;
	COLOR = orig_color + noise_str * str;
	COLOR.a = orig_color.a;
	//COLOR = noise_color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
