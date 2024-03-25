extends CanvasLayer

@onready var _vol_slider : HSlider = $VBoxContainer/VolumeSlider
@onready var scene_manager : SceneManager = get_tree().get_first_node_in_group("scenemanager")
@onready var player : FlowerHead = get_tree().get_first_node_in_group("flowerhead")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

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

func _on_volume_slider_value_changed(value):
	scene_manager.sound_volume = linear_to_db(_vol_slider.value * 1.5 / _vol_slider.max_value)
	player.set_volume()

func _on_reset_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
