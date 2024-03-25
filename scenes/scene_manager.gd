extends Node2D

class_name SceneManager

@export var game_scene : PackedScene
@export var sound_volume_offset1 = -12.0
@export var sound_volume_offset2 = -10.0
@onready var bgmusic = $CurrentScene/Menu/BGMusic
var sound_volume = 0.0
static var skip_cutscene = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_menu_game_started():
	$TransitionOverlay/AnimationPlayer.play("fade_to_black")
	create_tween().tween_property($CurrentScene/Menu/BGMusic, "pitch_scale", 0.1, 1.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)

func _on_transition_overlay_transitioned():
	$CurrentScene.get_child(0).queue_free()
	if skip_cutscene:
		var game = game_scene.instantiate()
		game.get_node("FlowerHead").play_animation_on_start = false
		$CurrentScene.add_child(game)
	else:
		$CurrentScene.add_child(game_scene.instantiate())
		skip_cutscene = true
