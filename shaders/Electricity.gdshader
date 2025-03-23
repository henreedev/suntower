shader_type canvas_item;

uniform float electricity : hint_range(0.0, 3.0);
uniform float scroll_speed : hint_range(0.0, 1.0);
uniform vec4 electric_color : source_color;
uniform sampler2D noise : repeat_enable;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (electricity > 0.0) {
		vec4 orig_color = texture(TEXTURE, UV);
		vec4 noise_color = texture(noise, UV + vec2(0, TIME * scroll_speed));
		if (orig_color.a > 0.0) {
			vec4 new_color = mix(orig_color, electric_color + 0.4 * noise_color, (electricity * ((orig_color.r * 0.6 + orig_color.g * 1.4) / 2.0)));
			new_color.a = orig_color.a;
			COLOR = new_color;
		}
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
