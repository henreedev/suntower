shader_type canvas_item;
render_mode unshaded;

uniform sampler2D noise;
const float str = 1.0;
const float hoz_offset = 1.0;

void fragment() {
	vec4 noise_color = texture(noise, UV + TIME * hoz_offset);
	vec4 orig_color = texture(TEXTURE, UV);
	COLOR = orig_color + noise_color.r * str;
	COLOR.a = orig_color.a;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
