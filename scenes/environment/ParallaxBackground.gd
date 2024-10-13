extends ParallaxBackground
class_name Background

const storm_modulate := Color(0.4, 0.4, 0.4, 0.5)
const default_modulate := Color(1.0, 1.0, 1.0, 1.0)
const brightness = 0.4
@onready var small_clouds : ScrollingSprite2D = $SmallClouds/Sprite2D
@onready var big_clouds : ScrollingSprite2D = $BigClouds/Sprite2D
@onready var bg : Sprite2D = $Background/Sprite2D
@onready var forest : Sprite2D = $Forest/Sprite2D


func enter_storm(tween : Tween, duration : float):
	tween.tween_property(bg, "modulate", storm_modulate, duration)
	tween.tween_property(forest, "modulate", storm_modulate, duration)
	
	tween.tween_property(big_clouds, "scale", Vector2(4.0, 4.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(set_speed_mult.bind(1.5).bind(true))
	tween.tween_property(big_clouds, "brightness", brightness, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "scale", Vector2(5.0, 5.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(set_speed_mult.bind(1.5).bind(false))
	tween.tween_property(small_clouds, "brightness", brightness, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func exit_storm(tween : Tween, duration : float):
	tween.tween_property(bg, "modulate", default_modulate, duration)
	tween.tween_property(forest, "modulate", default_modulate, duration)
	
	tween.tween_property(big_clouds, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(set_speed_mult.bind(1.0).bind(true))
	tween.tween_property(big_clouds, "brightness", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(set_speed_mult.bind(1.0).bind(false))
	tween.tween_property(small_clouds, "brightness", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)



func set_cloud_brightness(val):
	big_clouds.switch_brightness(val)
	small_clouds.switch_brightness(val)

func set_speed_mult(val, is_big):
	if is_big:
		big_clouds.switch_scroll_speed(val)
	else:
		small_clouds.switch_scroll_speed(val)

func set_darken(val, is_big):
	if is_big:
		big_clouds.switch_brightness(val)
	else:
		small_clouds.switch_brightness(val)
