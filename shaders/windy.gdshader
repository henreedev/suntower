shader_type canvas_item;

uniform float windiness : hint_range(0.0, 1.0);
uniform sampler2D windy_noise : repeat_enable, filter_nearest;
uniform vec2 scroll_speed;



varying flat vec4 modulate;
void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float a = color.a;
	vec4 windy_color = texture(windy_noise, UV + scroll_speed * TIME);
	color = mix(color, windy_color, windiness * windiness);

	COLOR = vec4((color * modulate).rgb, a);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
