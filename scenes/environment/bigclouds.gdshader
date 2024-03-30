shader_type canvas_item;

uniform float hoz_offset = -0.05;
uniform float speed_mult = 1.0;
uniform float darken = 0.0;

void fragment() {
	COLOR = texture(TEXTURE, UV + vec2(mod(TIME * hoz_offset * speed_mult, 1.0f), 0.0f));
	COLOR = COLOR - vec4(darken, darken, darken, 0.0);
	if (COLOR.r < 0.0) COLOR.r = 0.0;
	if (COLOR.g < 0.0) COLOR.g = 0.0;
	if (COLOR.b < 0.0) COLOR.b = 0.0; 
}