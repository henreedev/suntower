extends Sprite2D
class_name ScrollingSprite2D

@export var scroll_speed := 1.0
const BASE_SCROLL_SPEED := -0.05
var scroll_offset := 0.0
var scroll_tween : Tween

@export var brightness := 1.0
var brightness_tween : Tween

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	material.set_shader_parameter("scroll_offset", scroll_offset)
	material.set_shader_parameter("brightness", brightness)
	scroll_offset += scroll_speed * BASE_SCROLL_SPEED * delta

func set_brightness(new_brightness : float):
	if brightness_tween: brightness_tween.kill()
	brightness = new_brightness

func switch_scroll_speed(new_speed : float, transition_speed := new_speed):
	if scroll_tween: scroll_tween.kill()
	scroll_tween = create_tween()
	
	if transition_speed != new_speed: # Tween to transition speed first if it exists
		scroll_tween.tween_property(self, "scroll_speed", transition_speed, 1.5).set_ease(Tween.EASE_OUT)
	scroll_tween.tween_property(self, "scroll_speed", new_speed, 1.5).set_ease(Tween.EASE_IN_OUT)

func switch_brightness(new_brightness : float, transition_brightness := new_brightness):
	if brightness_tween: brightness_tween.kill()
	brightness_tween = create_tween()
	
	if transition_brightness != new_brightness: # Tween to transition speed first if it exists
		brightness_tween.tween_property(self, "scroll_speed", transition_brightness, 1.5).set_ease(Tween.EASE_OUT)
	brightness_tween.tween_property(self, "scroll_speed", new_brightness, 1.5).set_ease(Tween.EASE_IN_OUT)
