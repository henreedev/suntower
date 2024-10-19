extends ParallaxBackground
class_name Background

const storm_modulate := Color(0.4, 0.4, 0.4, 0.2)
const default_modulate := Color.WHITE
const brightness = 0.4
@onready var small_clouds : ScrollingSprite2D = $SmallClouds/Sprite2D
@onready var big_clouds : ScrollingSprite2D = $BigClouds/Sprite2D
@onready var bg : Sprite2D = $Background/Sprite2D
@onready var forest : Sprite2D = $Forest/Sprite2D


func enter_storm(tween : Tween, duration : float):
	tween.tween_property(bg, "modulate", storm_modulate, duration)
	tween.tween_property(forest, "modulate", storm_modulate, duration)
	
	set_speed_mult(4, true, 10)
	set_speed_mult(3, false, 8)
	
	tween.tween_property(big_clouds, "scale", Vector2(4.0, 4.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(big_clouds, "brightness", brightness, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "scale", Vector2(5.0, 5.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "brightness", brightness, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func enter_sunny(tween : Tween, duration : float):
	tween.tween_property(bg, "modulate", default_modulate, duration)
	tween.tween_property(forest, "modulate", default_modulate, duration)
	set_speed_mult(1, true, -0.8)
	set_speed_mult(0.8, false, -0.5)
	tween.tween_property(big_clouds, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(big_clouds, "brightness", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "brightness", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func enter_windy(tween : Tween, duration : float):
	const wind_cloud_modulate = Color.WEB_GRAY
	tween.tween_property(bg, "modulate", Color(0.4, 0.4, 0.4, 0.1), duration)
	tween.tween_property(forest, "modulate", Color.TRANSPARENT, duration)
	set_speed_mult(1.0, true, -5.8)
	set_speed_mult(-2.5, false, -20.5)
	tween.tween_property(big_clouds, "scale", Vector2(1.8, 1.8), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(big_clouds, "brightness", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(big_clouds, "modulate", wind_cloud_modulate, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "scale", Vector2(3.5, 3.5), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "brightness", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(small_clouds, "modulate", wind_cloud_modulate, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	


func set_cloud_brightness(val):
	big_clouds.set_brightness(val)
	small_clouds.set_brightness(val)

func set_speed_mult(val : float, is_big, trans_val := val):
	if is_big:
		big_clouds.switch_scroll_speed(val, trans_val)
	else:
		small_clouds.switch_scroll_speed(val, trans_val)

func set_darken(val, is_big):
	if is_big:
		big_clouds.switch_brightness(val)
	else:
		small_clouds.switch_brightness(val)
