extends Node2D

class_name SceneManager


const GAME_SCENE = preload("res://scenes/main.tscn")

static var instance : SceneManager
@export var should_play_cutscene = false

var base_volume : float
var player_volume_offset := 0.0
var tween_volume_offset := 0.0
var volume_tween : Tween

var playback : AudioStreamPlaybackInteractive
var stream : AudioStreamInteractive

var level_switch_tween : Tween

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var game : Main = $Main
@onready var start_menu = $Menu
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().set_auto_accept_quit(false)
	Values.load_user_data()
	instance = self
	playback = audio_stream_player.get_stream_playback()
	stream = audio_stream_player.stream
	base_volume = audio_stream_player.volume_db
	_setup_game()


func _setup_game():
	remove_child(game)
	game.flower_head.play_animation_on_start = should_play_cutscene
	should_play_cutscene = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	audio_stream_player.volume_db = base_volume + player_volume_offset + tween_volume_offset
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func menu_to_game():
	tween_transition([remove_child.bind(start_menu), add_child.bind(game), \
		switch_bgm.bind("Sun"), reduce_if_paused, game.pause_menu.options_menu.refresh])

func game_to_menu():
	tween_transition([remove_child.bind(game), add_child.bind(start_menu), \
	 switch_bgm.bind("Menu"), reset_music_volume, start_menu.options_menu.refresh])

func restart_game():
	tween_transition([switch_bgm.bind("Sun"), _set_game_to_new_copy, Values.reset])

func _set_game_to_new_copy():
	game.queue_free()
	remove_child(game)
	game = GAME_SCENE.instantiate()
	add_child(game)
	game.flower_head.play_animation_on_start = should_play_cutscene

func switch_bgm(clip_name : String):
	playback.switch_to_clip_by_name(clip_name)


func tween_transition(method_calls : Array[Callable]):
	if level_switch_tween:
		level_switch_tween.kill()
	level_switch_tween = create_tween()
	level_switch_tween.tween_property(color_rect, "modulate:a", 1.0, 0.75)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	level_switch_tween.parallel().tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.75)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for callable : Callable in method_calls:
		level_switch_tween.tween_callback(callable)
	level_switch_tween.tween_property(color_rect, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)\
		.set_delay(0.25)
	level_switch_tween.parallel().tween_property(animated_sprite_2d, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)\
		.set_delay(0.25)

func reduce_music_volume(duration := 0.75):
	if volume_tween:
		volume_tween.kill()
	volume_tween = create_tween()
	volume_tween.tween_property(self, "tween_volume_offset", -18.0, duration).set_ease(Tween.EASE_IN_OUT)

func reset_music_volume():
	if volume_tween:
		volume_tween.kill()
	volume_tween = create_tween()
	volume_tween.tween_property(self, "tween_volume_offset", 0.0, 0.75).set_ease(Tween.EASE_OUT)

func reduce_if_paused():
	if get_tree().paused:
		reduce_music_volume()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game():
	reduce_music_volume(0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.BLACK, 0.3).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Values.save_user_data)
	tween.tween_callback(get_tree().quit)
