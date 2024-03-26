extends ParallaxBackground
class_name Background

const storm_modulate := Color(0.4, 0.4, 0.4, 0.5)
const default_modulate := Color(1.0, 1.0, 1.0, 1.0)
const dark = 0.6
@onready var small_clouds : Sprite2D = $SmallClouds/Sprite2D
@onready var big_clouds : Sprite2D = $BigClouds/Sprite2D
@onready var bg : Sprite2D = $Background/Sprite2D
@onready var forest : Sprite2D = $Forest/Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func enter_storm(tween : Tween, duration : float):
	tween.tween_property(bg, "modulate", storm_modulate, duration)
	tween.tween_property(forest, "modulate", storm_modulate, duration)
	
	tween.tween_property(big_clouds, "scale", Vector2(4.0, 4.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_speed_mult.bind(true), 1.0, 1.5, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_darken.bind(true), 0.0, dark, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "scale", Vector2(5.0, 5.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_speed_mult.bind(false), 1.0, 1.5, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_darken.bind(false), 0.0, dark, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
func exit_storm(tween : Tween, duration : float):
	tween.tween_property(bg, "modulate", default_modulate, duration)
	tween.tween_property(forest, "modulate", default_modulate, duration)
	
	tween.tween_property(big_clouds, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_speed_mult.bind(true), 1.5, 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_darken.bind(true), dark, 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_speed_mult.bind(false), 1.5, 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_darken.bind(false), dark, 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func do_lightning(duration):
	var tween = create_tween().set_parallel()
	#tween.tween_property()
	pass

func set_cloud_brightness(val):
	big_clouds.material.set_shader_parameter("darken", val)
	small_clouds.material.set_shader_parameter("darken", val)

func set_speed_mult(val, is_big):
	if is_big:
		big_clouds.material.set_shader_parameter("speed_mult", val)
	else:
		small_clouds.material.set_shader_parameter("speed_mult", val)

func set_darken(val, is_big):
	if is_big:
		big_clouds.material.set_shader_parameter("darken", val)
	else:
		small_clouds.material.set_shader_parameter("darken", val)
