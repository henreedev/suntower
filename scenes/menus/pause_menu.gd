extends CanvasLayer

var just_unpaused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		unpause()

func unpause():
	if get_tree().paused:
		SceneManager.instance.reset_music_volume()
		just_unpaused = true
		get_tree().paused = false
		hide()
		await Timing.create_timer(self, 0.01, true)
		just_unpaused = false

func _on_resume_button_pressed():
	unpause()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_restart_button_pressed():
	unpause()
	SceneManager.instance.restart_game()


func _on_menu_button_pressed():
	SceneManager.instance.game_to_menu()


func _on_options_button_pressed():
	pass # Replace with function body.
