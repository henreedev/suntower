extends Control

signal game_started
var alternate := false
var alternate2 := false
var rate = 0.658
var rate2 = rate * 0.5


# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween().set_loops()
	animate_title()
	tween.tween_callback(animate_title).set_delay(rate)
	var tween2 = create_tween().set_loops()
	animate_title2()
	tween2.tween_callback(animate_title2).set_delay(rate2)

func animate_title():
	if alternate:
		create_tween().tween_property($Title, "label_settings:font_color", Color(1.0,  1.0, 0.8), rate)
		create_tween().tween_property($Title, "rotation", PI / 16, rate ).set_trans(Tween.TRANS_QUAD)
	else:
		create_tween().tween_property($Title, "label_settings:font_color", Color(1.5, 1.3, 0.3), rate)
		create_tween().tween_property($Title, "rotation", -PI / 16, rate ).set_trans(Tween.TRANS_QUAD)
	alternate = !alternate


func animate_title2():
	if alternate2:
		create_tween().tween_property($Title, "scale", Vector2(1.2, 1.2), rate2 ).set_trans(Tween.TRANS_LINEAR)
	else:
		create_tween().tween_property($Title, "scale", Vector2(1.0, 1.0), rate2 ).set_trans(Tween.TRANS_LINEAR)
	alternate2 = !alternate2

func _on_start_button_pressed():
	SceneManager.instance.menu_to_game()

func _on_options_button_pressed():
	pass # Replace with function body.

func _on_quit_button_pressed():
	get_tree().quit()
