extends Node2D

class_name SceneManager

signal initialized

const GAME_SCENE = preload("res://scenes/main_scenes/Game.tscn")

static var instance : SceneManager

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
@onready var victory_sequence : VictorySequence = $VictorySequence
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D
@onready var victory_color_rect: ColorRect = $CanvasLayer/VictoryColorRect
@onready var sprite_2d: Sprite2D = $CanvasLayer/Sprite2D

var can_transition := true
var is_initialized := false

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().set_auto_accept_quit(false)
	Values.load_user_data()
	instance = self
	playback = audio_stream_player.get_stream_playback()
	stream = audio_stream_player.stream
	base_volume = audio_stream_player.volume_db
	_setup()
	initialized.emit()
	is_initialized = true


func _setup():
	remove_child(victory_sequence)
	_set_game_to_new_copy()
	add_child(game)
	remove_child(game)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	audio_stream_player.volume_db = base_volume + player_volume_offset + tween_volume_offset
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func menu_to_game():
	if Values.won:
		tween_transition([remove_child.bind(start_menu), add_child.bind(game), _set_game_to_new_copy, \
			switch_bgm.bind("Sun"), reduce_if_paused, game.pause_menu.options_menu.refresh])
	else:
		tween_transition([remove_child.bind(start_menu), add_child.bind(game), \
			switch_bgm.bind("Sun"), reduce_if_paused, _call_game_options_refresh])

func game_to_menu():
	tween_transition([remove_child.bind(game), add_child.bind(start_menu), \
	 switch_bgm.bind("Menu"), reset_music_volume, start_menu.options_menu.refresh])

func game_to_victory():
	tween_transition([remove_child.bind(game), _set_game_to_new_copy, add_child.bind(victory_sequence), \
		switch_bgm.bind("VictoryLeadIn"), victory_sequence.play_sequence], 0)

func victory_to_menu():
	tween_transition([remove_child.bind(victory_sequence), add_child.bind(start_menu), \
	 switch_bgm.bind("Menu"), start_menu.options_menu.refresh], 1.0, true)

func restart_game():
	tween_transition([switch_bgm.bind("Sun"), _set_game_to_new_copy, _add_game_as_child])

func _add_game_as_child():
	add_child(game)

func _call_game_options_refresh():
	game.pause_menu.options_menu.refresh()

func _set_game_to_new_copy():
	Values.reset()
	game.queue_free()
	if game.get_parent() == self:
		remove_child(game)
	game = GAME_SCENE.instantiate()
	

func switch_bgm(clip_name : String):
	playback.switch_to_clip_by_name(clip_name)


func tween_transition(method_calls : Array[Callable], dur := 0.75, victory_to_menu := false):
	if can_transition:
		can_transition = false
		if level_switch_tween:
			level_switch_tween.kill()
		level_switch_tween = create_tween()
		
		var fade_rect := color_rect
		var sprite = animated_sprite_2d
		if victory_to_menu:
			fade_rect = victory_color_rect
			sprite = sprite_2d
		
		level_switch_tween.tween_property(fade_rect, "modulate:a", 1.0, dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		level_switch_tween.parallel().tween_property(sprite, "modulate:a", 1.0, dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		for callable : Callable in method_calls:
			level_switch_tween.tween_callback(callable)
			
		level_switch_tween.tween_property(fade_rect, "modulate:a", 0.0, dur * 0.67)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)\
			.set_delay(dur * 0.33)
		level_switch_tween.parallel().tween_property(sprite, "modulate:a", 0.0, dur * 0.67)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)\
			.set_delay(dur * 0.33)
		
		level_switch_tween.tween_property(self, "can_transition", true, 0.0)

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
