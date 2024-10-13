extends CanvasLayer

@onready var scene_manager : SceneManager = get_tree().get_first_node_in_group("scenemanager")
@onready var player : FlowerHead = get_tree().get_first_node_in_group("flowerhead")


func unpause_game():
	get_tree().paused = false
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		unpause_game()

func _on_resume_button_pressed():
	unpause_game()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_reset_button_pressed():
	get_tree().paused = false
	SceneManager.instance.restart_game()


func _on_menu_button_pressed():
	SceneManager.instance.game_to_menu()
