shader_type canvas_item;

uniform vec4 VINE_COLOR : source_color;

uniform vec4 sun_color : source_color;
uniform float sun_multiplier : hint_range(0.0, 3.0);
uniform float delta : hint_range(0.0, 1.0);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (abs(color.r - VINE_COLOR.r) < delta && abs(color.g - VINE_COLOR.g) < delta && abs(color.b - VINE_COLOR.b) < delta) {
		COLOR = sun_color;
		
	}
	
	if (texture(TEXTURE, UV) == VINE_COLOR) {
		COLOR = sun_color;
	}
	
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
