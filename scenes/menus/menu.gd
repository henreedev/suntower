extends Control

signal game_started
var alternate := false
var rate = 0.652 * 2

@onready var title_blur = $Background/TitleBlur


# Called when the node enters the scene tree for the first time.
func _ready():
	animate_title()

func animate_title():
	const STR = 1.5
	var tween = create_tween().set_loops()
	tween.tween_property(title_blur, "modulate", Color.WHITE * STR, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_blur, "modulate", Color.WHITE, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(title_blur, "modulate", Color.GRAY, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_blur, "modulate", Color.WHITE, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_start_button_pressed():
	SceneManager.instance.menu_to_game()

func _on_options_button_pressed():
	pass # Replace with function body.

func _on_quit_button_pressed():
	get_tree().quit()
