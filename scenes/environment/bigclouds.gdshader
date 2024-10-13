shader_type canvas_item;

uniform float scroll_offset = 0.0 ;
uniform float brightness = 1.0;

void fragment() {
	COLOR = texture(TEXTURE, UV + vec2(scroll_offset, 0.0f));
	float darken = 1.0 - brightness;
	COLOR = COLOR - vec4(darken, darken, darken, 0.0);
	if (COLOR.r < 0.0) COLOR.r = 0.0;
	if (COLOR.g < 0.0) COLOR.g = 0.0;
	if (COLOR.b < 0.0) COLOR.b = 0.0;
}