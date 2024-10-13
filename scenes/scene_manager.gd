extends Node2D

class_name SceneManager

@export var game_scene : PackedScene
#static var sound_volume_offset_menu = -12.0
#static var sound_volume_offset_sun = -10.0
#static var sound_volume_offset_sfx = -8.0
#static var sound_volume_offset_storm = -10.0
#static var sound_volume_offset_unnormalized = 10.0
#static var sfx_bighit_adj = 5.0
#@onready var bgmusic = $CurrentScene/Menu/BGMusic
#static var sound_volume = -10.0
static var skip_cutscene = false

var base_volume : float
var player_volume_offset := 0.0
var tween_volume_offset := 0.0
var volume_tween : Tween

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
var playback : AudioStreamPlaybackInteractive
var stream : AudioStreamInteractive

# Called when the node enters the scene tree for the first time.
func _ready():
	playback = audio_stream_player.get_stream_playback()
	stream = audio_stream_player.stream
	base_volume = audio_stream_player.volume_db


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			

func _on_menu_game_started():
	$TransitionOverlay/AnimationPlayer.play("fade_to_black")
	create_tween().tween_property($CurrentScene/Menu/BGMusic, "pitch_scale", 0.1, 1.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)

func _on_transition_overlay_transitioned():
	# store volume
	start_game()

func start_game():
	var child = $CurrentScene.get_child(0)
	child.queue_free()
	$CurrentScene.remove_child(child)
	#await get_tree().create_timer(0.2).timeout
	if skip_cutscene:
		var game = game_scene.instantiate()
		game.get_node("FlowerHead").play_animation_on_start = false
		$CurrentScene.add_child(game)
	else:
		var game = game_scene.instantiate()
		game.get_node("FlowerHead").play_animation_on_start = true
		$CurrentScene.add_child(game)
		skip_cutscene = true
